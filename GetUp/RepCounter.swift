// Services/RepCounter.swift
// Detects completed reps by watching the angle of the primary joint over time.
// Uses a simple state machine: start → mid → peak → start = 1 rep

import Foundation
import Combine

// MARK: - RepCounter

final class RepCounter: ObservableObject {

    // MARK: State
    @Published private(set) var currentReps: Int = 0
    @Published private(set) var currentSet: Int = 1
    @Published private(set) var isResting: Bool = false
    @Published private(set) var restSecondsRemaining: Int = 0
    @Published private(set) var isWorkoutComplete: Bool = false

    var targetReps: Int
    var targetSets: Int
    var restDurationSeconds: Int

    // Rep detection thresholds (angles in degrees)
    // These are tuned for bicep curl — WorkoutViewModel overrides per-exercise
    var peakAngleThreshold: Double = 65.0      // angle below this = "top of rep"
    var startAngleThreshold: Double = 140.0    // angle above this = "bottom of rep"

    private enum Phase { case atStart, movingToPeak, atPeak, movingToStart }
    private var phase: Phase = .atStart
    private var angleHistory: [Double] = []
    private var restTimer: AnyCancellable?

    // MARK: Callbacks
    var onRepCompleted: (() -> Void)?
    var onSetCompleted: ((Int) -> Void)?       // passes the completed set number
    var onWorkoutComplete: (() -> Void)?

    init(targetReps: Int = 12, targetSets: Int = 3, restDuration: Int = 60) {
        self.targetReps = targetReps
        self.targetSets = targetSets
        self.restDurationSeconds = restDuration
    }

    // MARK: - Feed Angle
    // Called every frame with the primary joint angle

    func feedAngle(_ angle: Double) {
        guard !isResting, !isWorkoutComplete else { return }

        // Smooth the angle with a simple moving average to reduce noise
        angleHistory.append(angle)
        if angleHistory.count > 5 { angleHistory.removeFirst() }
        let smoothed = angleHistory.reduce(0, +) / Double(angleHistory.count)

        switch phase {
        case .atStart:
            if smoothed < peakAngleThreshold - 10 {
                phase = .movingToPeak
            }

        case .movingToPeak:
            if smoothed < peakAngleThreshold {
                phase = .atPeak
            } else if smoothed > startAngleThreshold {
                // Went back without completing — reset
                phase = .atStart
            }

        case .atPeak:
            if smoothed > startAngleThreshold - 10 {
                phase = .movingToStart
            }

        case .movingToStart:
            if smoothed > startAngleThreshold {
                // Rep complete!
                phase = .atStart
                angleHistory.removeAll()
                registerRep()
            }
        }
    }

    // MARK: - Register Rep

    private func registerRep() {
        currentReps += 1
        onRepCompleted?()

        if currentReps >= targetReps {
            completeSet()
        }
    }

    // MARK: - Set Management

    private func completeSet() {
        let justCompleted = currentSet
        onSetCompleted?(justCompleted)

        if currentSet >= targetSets {
            isWorkoutComplete = true
            onWorkoutComplete?()
        } else {
            startRest()
        }
    }

    private func startRest() {
        isResting = true
        restSecondsRemaining = restDurationSeconds

        restTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.restSecondsRemaining -= 1
                if self.restSecondsRemaining <= 0 {
                    self.endRest()
                }
            }
    }

    func skipRest() {
        restTimer?.cancel()
        endRest()
    }

    private func endRest() {
        restTimer?.cancel()
        isResting = false
        restSecondsRemaining = 0
        currentSet += 1
        currentReps = 0
        phase = .atStart
        angleHistory.removeAll()
    }

    // MARK: - Reset

    func reset(targetReps: Int? = nil, targetSets: Int? = nil) {
        restTimer?.cancel()
        currentReps = 0
        currentSet = 1
        isResting = false
        restSecondsRemaining = 0
        isWorkoutComplete = false
        phase = .atStart
        angleHistory.removeAll()
        if let r = targetReps { self.targetReps = r }
        if let s = targetSets { self.targetSets = s }
    }

    // MARK: - Progress

    var setProgress: Double {
        guard targetSets > 0 else { return 0 }
        let completedSets = Double(currentSet - 1)
        let currentSetFraction = Double(currentReps) / Double(targetReps)
        return (completedSets + currentSetFraction) / Double(targetSets)
    }

    var statusText: String {
        if isWorkoutComplete { return "Workout Complete! 🎉" }
        if isResting { return "Rest — next set in \(restSecondsRemaining)s" }
        return "Set \(currentSet) of \(targetSets)"
    }
}
