// Services/RepCounter.swift
// Counts reps by tracking joint angle crossing two thresholds.
// Uses RepPhase from ExerciseLibrary.swift — do NOT redeclare it here.
// WorkoutState lives in WorkoutViewModel.swift — do NOT redeclare it here.

import Foundation
import Combine
import UIKit

// MARK: - RepCounter

@MainActor
final class RepCounter: ObservableObject {

    // MARK: - Published State

    @Published var currentReps: Int = 0
    @Published var currentSet:  Int = 1
    @Published var restSecondsRemaining: Int = 0   // drives live countdown in RestOverlay

    // MARK: - Configuration

    var peakAngleThreshold:  Double = 40
    var startAngleThreshold: Double = 150
    var restDurationSeconds: Int = 60

    private(set) var targetReps: Int = 12
    private(set) var targetSets: Int = 3

    // MARK: - Callbacks

    var onRepCompleted:   (() -> Void)?
    var onSetCompleted:   ((Int) -> Void)?
    var onRestCompleted:  (() -> Void)?
    var onWorkoutComplete: (() -> Void)?

    // MARK: - Private

    private var repPhase: RepPhase = .start
    private var restTimer: Timer?
    private let hysteresis: Double = 10

    // MARK: - Setup / Reset

    func reset(targetReps: Int, targetSets: Int) {
        self.targetReps = targetReps
        self.targetSets = targetSets
        reset()
    }

    func reset() {
        currentReps           = 0
        currentSet            = 1
        restSecondsRemaining  = 0
        repPhase              = .start
        restTimer?.invalidate()
        restTimer             = nil
    }

    // MARK: - Angle Feed

    nonisolated func feedAngle(_ angle: Double) {
        Task { @MainActor [weak self] in
            self?.advanceStateMachine(angle: angle)
        }
    }

    // MARK: - State Machine

    private func advanceStateMachine(angle: Double) {
        switch repPhase {
        case .start:
            if angle < startAngleThreshold - hysteresis {
                repPhase = .midMovement
            }
        case .midMovement:
            if angle <= peakAngleThreshold {
                repPhase = .peak
                repCompleted()
            } else if angle >= startAngleThreshold {
                repPhase = .start
            }
        case .peak:
            if angle >= startAngleThreshold - hysteresis {
                repPhase = .start
            }
        }
    }

    // MARK: - Rep / Set Completion

    private func repCompleted() {
        currentReps += 1
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onRepCompleted?()
        if currentReps >= targetReps { setCompleted() }
    }

    private func setCompleted() {
        let finishedSet = currentSet
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onSetCompleted?(finishedSet)

        if finishedSet >= targetSets {
            onWorkoutComplete?()
        } else {
            currentSet  += 1
            currentReps  = 0
            repPhase     = .start
            startRestTimer()
        }
    }

    // MARK: - Rest Timer

    private func startRestTimer() {
        restSecondsRemaining = restDurationSeconds
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self else { timer.invalidate(); return }
                self.restSecondsRemaining -= 1
                if self.restSecondsRemaining <= 0 {
                    timer.invalidate()
                    self.restTimer            = nil
                    self.restSecondsRemaining = 0
                    self.repPhase             = .start
                    self.onRestCompleted?()
                }
            }
        }
    }

    func skipRest() {
        restTimer?.invalidate()
        restTimer            = nil
        restSecondsRemaining = 0
        repPhase             = .start
    }
}
