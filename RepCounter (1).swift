// RepCounter.swift
// Tracks rep completion using a simple two-phase state machine.
// Phase A (bottom) → Phase B (top) = 1 rep.
// Publishes rep count, set count, and rest timer state.

import Foundation
import Combine
import Vision

// MARK: - RepCounter
// Note: RepPhase is declared in ExerciseLibrary.swift
// Note: WorkoutState is declared in its own file

@MainActor
final class RepCounter: ObservableObject {

    // ── Published State ────────────────────────────────────────────────────
    @Published var currentReps: Int = 0
    @Published var currentSet: Int = 1
    @Published var workoutState: WorkoutState = .idle

    // Per-rep quality tracking
    @Published var currentRepWarningFrames: Int = 0
    @Published var currentRepTotalFrames: Int = 0

    // ── Configuration ──────────────────────────────────────────────────────
    var targetReps: Int = 12
    var targetSets: Int = 3
    var restDuration: Int = 60   // seconds between sets

    private var exercise: ExerciseDefinition?
    private var repPhase: RepPhase = .waitingForBottom
    private var restTimer: Timer?
    private var restSecondsRemaining: Int = 0

    // Haptic feedback
    private let haptics = UINotificationFeedbackGenerator()

    // ── Rep Completion Callback ────────────────────────────────────────────
    /// Called with the form score (0–1) each time a rep is completed.
    var onRepCompleted: ((Double) -> Void)?
    /// Called when a set is completed.
    var onSetCompleted: ((Int) -> Void)?
    /// Called when the full workout is done.
    var onWorkoutCompleted: (() -> Void)?

    // ── Initialise ─────────────────────────────────────────────────────────

    func configure(exercise: ExerciseDefinition, sets: Int, reps: Int) {
        self.exercise = exercise
        self.targetSets = sets
        self.targetReps = reps
        self.restDuration = exercise.restSeconds
        reset()
    }

    func reset() {
        currentReps = 0
        currentSet = 1
        workoutState = .idle
        repPhase = .waitingForBottom
        currentRepWarningFrames = 0
        currentRepTotalFrames = 0
        restTimer?.invalidate()
    }

    func startWorkout() {
        workoutState = .inProgress
        haptics.prepare()
    }

    // ── Frame Update ────────────────────────────────────────────────────────

    /// Call with each detected body frame. Extracts the relevant angle and
    /// advances the rep state machine.
    func processFrame(body: DetectedBody, feedback: FeedbackResult) {
        guard case .inProgress = workoutState, let exercise else { return }

        // Accumulate form quality data for this rep
        currentRepTotalFrames += 1
        if feedback.quality != .great {
            currentRepWarningFrames += 1
        }

        // Get the primary angle for rep detection
        guard
            let jointA   = body.joint(exercise.angleJointA),
            let vertex   = body.joint(exercise.primaryJoint),
            let jointB   = body.joint(exercise.angleJointB)
        else { return }

        let angle = PoseDetector.angle(
            a: jointA.location,
            vertex: vertex.location,
            b: jointB.location
        )

        advanceStateMachine(angle: angle, exercise: exercise)
    }

    // ── State Machine ────────────────────────────────────────────────────────

    private func advanceStateMachine(angle: Double, exercise: ExerciseDefinition) {
        let bottomThreshold = exercise.repBottomAngle - exercise.repHysteresis
        let topThreshold    = exercise.repTopAngle    + exercise.repHysteresis

        // Determine if movement is curl-style (bottom > top) or press-style (bottom < top)
        let invertedMovement = exercise.repBottomAngle > exercise.repTopAngle

        switch repPhase {
        case .waitingForBottom, .movingToBottom:
            if invertedMovement {
                if angle >= exercise.repBottomAngle - exercise.repHysteresis {
                    repPhase = .atBottom
                }
            } else {
                if angle <= exercise.repBottomAngle + exercise.repHysteresis {
                    repPhase = .atBottom
                }
            }

        case .atBottom:
            repPhase = .movingToTop

        case .movingToTop:
            if invertedMovement {
                // e.g. bicep curl: angle decreases as you curl
                if angle <= exercise.repTopAngle + exercise.repHysteresis {
                    repCompleted()
                    repPhase = .atTop
                }
            } else {
                // e.g. shoulder press: angle increases as you press
                if angle >= exercise.repTopAngle - exercise.repHysteresis {
                    repCompleted()
                    repPhase = .atTop
                }
            }

        case .atTop:
            repPhase = .movingToBottom

        case .movingToBottom:
            if invertedMovement {
                if angle >= exercise.repBottomAngle - exercise.repHysteresis {
                    repPhase = .atBottom
                }
            } else {
                if angle <= exercise.repBottomAngle + exercise.repHysteresis {
                    repPhase = .atBottom
                }
            }
        }
    }

    // ── Rep / Set Completion ────────────────────────────────────────────────

    private func repCompleted() {
        let score = formScoreForCurrentRep()
        currentReps += 1
        haptics.notificationOccurred(.success)
        onRepCompleted?(score)

        // Reset per-rep tracking
        currentRepWarningFrames = 0
        currentRepTotalFrames = 0

        if currentReps >= targetReps {
            setCompleted()
        }
    }

    private func setCompleted() {
        let completedSet = currentSet
        haptics.notificationOccurred(.success)
        onSetCompleted?(completedSet)

        if currentSet >= targetSets {
            workoutCompleted()
        } else {
            currentSet += 1
            currentReps = 0
            // CRITICAL: reset rep phase so the next set starts fresh.
            // Without this, repPhase stays at .atTop/.movingToBottom from
            // the last rep — the state machine can never detect a new bottom
            // position, so set 3 never counts any reps.
            repPhase = .waitingForBottom
            currentRepWarningFrames = 0
            currentRepTotalFrames = 0
            startRestTimer()
        }
    }

    private func workoutCompleted() {
        workoutState = .complete
        haptics.notificationOccurred(.success)
        onWorkoutCompleted?()
    }

    // ── Rest Timer ───────────────────────────────────────────────────────────

    private func startRestTimer() {
        restSecondsRemaining = restDuration
        workoutState = .resting(secondsRemaining: restSecondsRemaining)

        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.restSecondsRemaining -= 1
                if self.restSecondsRemaining <= 0 {
                    self.restTimer?.invalidate()
                    self.repPhase = .waitingForBottom   // clean phase for new set
                    self.workoutState = .inProgress
                } else {
                    self.workoutState = .resting(secondsRemaining: self.restSecondsRemaining)
                }
            }
        }
    }

    func skipRest() {
        restTimer?.invalidate()
        repPhase = .waitingForBottom   // ensure phase is clean after rest skip
        workoutState = .inProgress
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private func formScoreForCurrentRep() -> Double {
        guard currentRepTotalFrames > 0 else { return 1.0 }
        let badFraction = Double(currentRepWarningFrames) / Double(currentRepTotalFrames)
        return max(0.0, 1.0 - badFraction * 1.5)
    }
}
