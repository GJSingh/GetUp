// Services/RepCounter.swift
// Counts reps by tracking joint angle crossing two thresholds.
// Uses RepPhase from ExerciseLibrary.swift — do NOT redeclare it here.
// WorkoutState lives in WorkoutViewModel.swift — do NOT redeclare it here.

import Foundation
import Combine   // required for @Published and ObservableObject
import UIKit

// MARK: - RepCounter

@MainActor
final class RepCounter: ObservableObject {

    // MARK: - Published State

    @Published var currentReps: Int = 0
    @Published var currentSet:  Int = 1

    // MARK: - Configuration

    /// Angle (degrees) the joint must reach to count as "at peak" (e.g. 40° for bicep curl).
    var peakAngleThreshold:  Double = 40
    /// Angle (degrees) the joint must return to before another rep can start (e.g. 150° for bicep curl).
    var startAngleThreshold: Double = 150
    /// How many seconds to rest between sets.
    var restDurationSeconds: Int = 60

    private(set) var targetReps: Int = 12
    private(set) var targetSets: Int = 3

    // MARK: - Callbacks

    /// Fires on the main thread when a single rep is completed.
    var onRepCompleted: (() -> Void)?
    /// Fires on the main thread when a full set is completed. Passes the set number that just finished.
    var onSetCompleted: ((Int) -> Void)?
    /// Fires on the main thread when the rest timer reaches zero.
    var onRestCompleted: (() -> Void)?
    /// Fires on the main thread when all sets are done.
    var onWorkoutComplete: (() -> Void)?

    // MARK: - Private

    // RepPhase is declared in ExerciseLibrary.swift: .start / .midMovement / .peak
    private var repPhase: RepPhase = .start
    private var restTimer: Timer?
    private let hysteresis: Double = 10   // degrees — prevents edge-case double-counting

    // MARK: - Setup / Reset

    /// Configure before starting a workout.
    func reset(targetReps: Int, targetSets: Int) {
        self.targetReps = targetReps
        self.targetSets = targetSets
        reset()
    }

    /// Reset counters without changing targets (used by endWorkout / resetToSetup).
    func reset() {
        currentReps = 0
        currentSet  = 1
        repPhase    = .start
        restTimer?.invalidate()
        restTimer   = nil
    }

    // MARK: - Angle Feed

    /// Call on every camera frame with the computed joint angle (degrees).
    /// Thread-safe: marshals to main actor internally.
    nonisolated func feedAngle(_ angle: Double) {
        Task { @MainActor [weak self] in
            self?.advanceStateMachine(angle: angle)
        }
    }

    // MARK: - State Machine

    private func advanceStateMachine(angle: Double) {
        // All exercises use inverted movement: start at large angle (arm extended),
        // peak at small angle (arm contracted / squat depth / etc.)
        switch repPhase {

        case .start:
            // User is at starting position. Rep begins when they move away.
            if angle < startAngleThreshold - hysteresis {
                repPhase = .midMovement
            }

        case .midMovement:
            if angle <= peakAngleThreshold {
                // Reached the peak — count the rep
                repPhase = .peak
                repCompleted()
            } else if angle >= startAngleThreshold {
                // Returned to start without reaching peak — reset, don't count
                repPhase = .start
            }

        case .peak:
            // Wait for them to return toward the start position
            if angle >= startAngleThreshold - hysteresis {
                repPhase = .start
            }
        }
    }

    // MARK: - Rep / Set Completion

    private func repCompleted() {
        currentReps += 1

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        onRepCompleted?()

        if currentReps >= targetReps {
            setCompleted()
        }
    }

    private func setCompleted() {
        let finishedSet = currentSet   // capture BEFORE incrementing

        let notify = UINotificationFeedbackGenerator()
        notify.notificationOccurred(.success)

        onSetCompleted?(finishedSet)   // tell VM which set just finished

        if finishedSet >= targetSets {
            // All sets done
            onWorkoutComplete?()
        } else {
            // More sets to go — increment set counter, reset reps, start rest
            currentSet  += 1
            currentReps  = 0
            repPhase     = .start   // CRITICAL: reset phase so the new set detects correctly
            startRestTimer()
        }
    }

    // MARK: - Rest Timer

    private func startRestTimer() {
        var remaining = restDurationSeconds
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self else { timer.invalidate(); return }
                remaining -= 1
                if remaining <= 0 {
                    timer.invalidate()
                    self.restTimer = nil
                    self.repPhase = .start   // ensure clean phase on rest-end auto-resume
                    self.onRestCompleted?()  // VM will set state = .active
                }
            }
        }
    }

    /// Called when user taps "Skip Rest".
    func skipRest() {
        restTimer?.invalidate()
        restTimer = nil
        repPhase  = .start   // clean phase
        // Caller (WorkoutViewModel.resumeAfterRest) sets state = .active
    }
}
