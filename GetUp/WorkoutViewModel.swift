// ViewModels/WorkoutViewModel.swift
// The brain of the workout screen. Connects CameraManager → PoseDetector → ExerciseLibrary → RepCounter.
// Saves results to SwiftData when workout completes.

import SwiftUI
import Vision
import Combine
import SwiftData

// MARK: - WorkoutState

enum WorkoutState {
    case setup          // choosing exercise and reps
    case countdown      // 3-2-1 before starting
    case active         // workout in progress
    case resting        // between sets
    case complete       // all sets done
}

// MARK: - WorkoutViewModel

@MainActor
final class WorkoutViewModel: ObservableObject {

    // MARK: Published
    @Published var state: WorkoutState = .setup
    @Published var currentFeedback: PostureFeedback = .waiting
    @Published var poseResult: PoseDetectionResult = PoseDetectionResult(joints: [:], confidence: 0, timestamp: 0)
    @Published var countdown: Int = 3
    @Published var formScores: [Double] = []    // running form scores this set
    @Published var sessionFormScore: Double = 0

    // Exercise Config (bound from SetupView)
    @Published var selectedExercise: ExerciseDefinition = ExerciseLibrary.bicepCurl
    @Published var targetSets: Int = 3
    @Published var targetReps: Int = 12
    @Published var restDuration: Int = 60

    // MARK: Services
    let camera: CameraManager
    let repCounter: RepCounter
    private let poseDetector = PoseDetector()

    // MARK: Private
    private var countdownTimer: AnyCancellable?
    private var workoutStartTime: Date?
    private var cancellables = Set<AnyCancellable>()
    private var completedSets: [ExerciseSet] = []

    // SwiftData context — injected from view
    var modelContext: ModelContext?

    init() {
        camera = CameraManager()
        repCounter = RepCounter()
        setupPipeline()
    }

    // MARK: - Pipeline Setup

    private func setupPipeline() {
        // Camera → Pose Detector
        camera.onFrame = { [weak self] pixelBuffer in
            self?.poseDetector.process(pixelBuffer: pixelBuffer)
        }

        // Pose Detector → Analysis
        poseDetector.onResult = { [weak self] result in
            guard let self else { return }
            Task { @MainActor in
                self.handlePoseResult(result)
            }
        }

        // Rep Counter callbacks
        repCounter.onRepCompleted = { [weak self] in
            Task { @MainActor in
                self?.handleRepCompleted()
            }
        }

        repCounter.onSetCompleted = { [weak self] setNumber in
            Task { @MainActor in
                self?.handleSetCompleted(setNumber: setNumber)
            }
        }

        // BUG 3 FIX: wire rest-completed so state auto-transitions to .active
        repCounter.onRestCompleted = { [weak self] in
            Task { @MainActor in
                self?.resumeAfterRest()
            }
        }

        repCounter.onWorkoutComplete = { [weak self] in
            Task { @MainActor in
                self?.handleWorkoutComplete()
            }
        }
    }

    // MARK: - Pose Handling

    private func handlePoseResult(_ result: PoseDetectionResult) {
        poseResult = result
        guard state == .active, !result.isEmpty else { return }

        // Run exercise analysis
        let (feedback, _) = selectedExercise.analyse(result.joints)
        currentFeedback = feedback

        // Track form score
        let score: Double = {
            switch feedback.quality {
            case .excellent: return 1.0
            case .good:      return 0.8
            case .needsWork: return 0.5
            case .incorrect: return 0.2
            }
        }()
        formScores.append(score)

        // Feed primary angle to rep counter
        feedPrimaryAngle(joints: result.joints)
    }

    /// Extract the key angle for the current exercise and pass to rep counter
    private func feedPrimaryAngle(joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        switch selectedExercise.id {

        case "bicep_curl":
            let s = joints[.rightShoulder] ?? joints[.leftShoulder]
            let e = joints[.rightElbow]    ?? joints[.leftElbow]
            let w = joints[.rightWrist]    ?? joints[.leftWrist]
            if let s, let e, let w,
               JointMath.isReliable(s), JointMath.isReliable(e), JointMath.isReliable(w) {
                let angle = JointMath.angle(from: s, vertex: e, to: w)
                repCounter.feedAngle(angle)
            }

        case "shoulder_press":
            let ls = joints[.leftShoulder]; let le = joints[.leftElbow]; let lw = joints[.leftWrist]
            let rs = joints[.rightShoulder]; let re = joints[.rightElbow]; let rw = joints[.rightWrist]
            if let ls, let le, let lw, JointMath.isReliable(le) {
                let angle = JointMath.angle(from: ls, vertex: le, to: lw)
                repCounter.feedAngle(angle)
            } else if let rs, let re, let rw, JointMath.isReliable(re) {
                let angle = JointMath.angle(from: rs, vertex: re, to: rw)
                repCounter.feedAngle(angle)
            }
            repCounter.peakAngleThreshold = 30
            repCounter.startAngleThreshold = 120

        case "squat":
            let h = joints[.rightHip]  ?? joints[.leftHip]
            let k = joints[.rightKnee] ?? joints[.leftKnee]
            let a = joints[.rightAnkle] ?? joints[.leftAnkle]
            if let h, let k, let a,
               JointMath.isReliable(k) {
                let angle = JointMath.angle(from: h, vertex: k, to: a)
                repCounter.feedAngle(angle)
            }
            repCounter.peakAngleThreshold = 100
            repCounter.startAngleThreshold = 165

        default:
            // For other exercises use elbow angle with default thresholds
            let s = joints[.rightShoulder] ?? joints[.leftShoulder]
            let e = joints[.rightElbow]    ?? joints[.leftElbow]
            let w = joints[.rightWrist]    ?? joints[.leftWrist]
            if let s, let e, let w, JointMath.isReliable(e) {
                repCounter.feedAngle(JointMath.angle(from: s, vertex: e, to: w))
            }
        }
    }

    // MARK: - Rep / Set / Complete Handlers

    private func handleRepCompleted() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    private func handleSetCompleted(setNumber: Int) {
        let avgScore = formScores.isEmpty ? 0.0 : formScores.reduce(0, +) / Double(formScores.count)
        let set = ExerciseSet(
            setNumber: setNumber,
            repsCompleted: repCounter.targetReps,
            formScore: avgScore
        )
        completedSets.append(set)
        formScores.removeAll()

        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)

        // BUG 2 FIX: was `<= targetSets` which sent the LAST set to .resting too,
        // racing with handleWorkoutComplete. Use `<` so only intermediate sets rest.
        if setNumber < targetSets {
            state = .resting
        }
        // The final set is handled by handleWorkoutComplete via repCounter.onWorkoutComplete
    }

    private func handleWorkoutComplete() {
        state = .complete
        saveSession()
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }

    // MARK: - Workflow Control

    func startCountdown() {
        guard state == .setup else { return }
        repCounter.reset(targetReps: targetReps, targetSets: targetSets)
        repCounter.restDurationSeconds = restDuration
        completedSets.removeAll()
        formScores.removeAll()
        countdown = 3
        state = .countdown

        countdownTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.countdown > 1 {
                    self.countdown -= 1
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                } else {
                    self.countdownTimer?.cancel()
                    self.beginWorkout()
                }
            }
    }

    private func beginWorkout() {
        workoutStartTime = Date()
        state = .active
        camera.start()
        ScreenManager.shared.keepAwake()
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
    }

    func resumeAfterRest() {
        repCounter.skipRest()
        state = .active
    }

    func endWorkout() {
        countdownTimer?.cancel()
        camera.stop()
        ScreenManager.shared.allowSleep()
        if state == .active || state == .resting {
            saveSession()
        }
        state = .setup
        repCounter.reset()
    }

    func resetToSetup() {
        countdownTimer?.cancel()
        camera.stop()
        ScreenManager.shared.allowSleep()
        state = .setup
        repCounter.reset()
        completedSets.removeAll()
        formScores.removeAll()
        currentFeedback = .waiting
    }

    // MARK: - Persist Session

    private func saveSession() {
        guard let context = modelContext else { return }

        let allScores = completedSets.map(\.formScore)
        let avg = allScores.isEmpty ? 0.0 : allScores.reduce(0, +) / Double(allScores.count)

        let duration: Int = {
            guard let start = workoutStartTime else { return 0 }
            return Int(Date().timeIntervalSince(start))
        }()

        let session = WorkoutSession(
            exerciseName: selectedExercise.name,
            targetSets: targetSets,
            targetReps: targetReps
        )
        session.durationSeconds = duration
        session.averageFormScore = avg
        session.completedSets = completedSets.count
        session.totalRepsCompleted = completedSets.map(\.repsCompleted).reduce(0, +)
        session.sets = completedSets

        context.insert(session)
        try? context.save()
    }

    // MARK: - Computed

    var currentSetFormScore: Double {
        guard !formScores.isEmpty else { return 0 }
        return formScores.suffix(30).reduce(0, +) / Double(min(formScores.count, 30))
    }
}
