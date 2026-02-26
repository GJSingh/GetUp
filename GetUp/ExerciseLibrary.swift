// Models/ExerciseLibrary.swift
// Defines all supported exercises with their posture rules and rep detection logic.
// Includes strength exercises and yoga poses.

import Foundation
import Vision

// MARK: - PostureFeedback

struct PostureFeedback: Equatable {
    enum Quality { case excellent, good, needsWork, incorrect }
    let quality: Quality
    let message: String
    let detail: String

    var color: String {
        switch quality {
        case .excellent: return "00C896"
        case .good:      return "5BC8FF"
        case .needsWork: return "FFB740"
        case .incorrect: return "FF5A5A"
        }
    }

    static let waiting = PostureFeedback(
        quality: .good,
        message: "Get into position",
        detail: "Stand so your full body is visible"
    )
}

// MARK: - RepPhase

enum RepPhase {
    case start
    case midMovement
    case peak
}

// MARK: - ExerciseCategory

enum ExerciseCategory: String, CaseIterable {
    case strength = "Strength"
    case yoga     = "Yoga"

    var emoji: String {
        switch self {
        case .strength: return "🏋️"
        case .yoga:     return "🧘"
        }
    }
}

// MARK: - ExerciseDefinition

struct ExerciseDefinition: Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
    let description: String
    let muscleGroups: [String]
    let defaultSets: Int
    let defaultReps: Int
    let cameraSetup: String
    let category: ExerciseCategory
    let isHoldPose: Bool          // true for yoga — hold duration instead of reps

    typealias Analyser = (_ joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> (PostureFeedback, repCompleted: Bool)
    let analyse: Analyser

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: ExerciseDefinition, rhs: ExerciseDefinition) -> Bool { lhs.id == rhs.id }
}

// MARK: - ExerciseLibrary

enum ExerciseLibrary {

    static let all: [ExerciseDefinition] = [
        // Strength
        bicepCurl,
        shoulderPress,
        lateralRaise,
        squat,
        overheadTricepExtension,
        // Yoga
        warriorOne,
        warriorTwo,
        treePose,
        downwardDog,
        chairPose,
    ]

    static func exercise(id: String) -> ExerciseDefinition? {
        all.first { $0.id == id }
    }

    static func exercises(for category: ExerciseCategory) -> [ExerciseDefinition] {
        all.filter { $0.category == category }
    }

    // ── STRENGTH ──────────────────────────────────────────────────────────

    static let bicepCurl = ExerciseDefinition(
        id: "bicep_curl",
        name: "Bicep Curl",
        emoji: "💪",
        description: "Stand tall, curl the dumbbell toward your shoulder, then lower under control.",
        muscleGroups: ["Biceps", "Forearms"],
        defaultSets: 3,
        defaultReps: 12,
        cameraSetup: "Prop your phone sideways against a wall at hip height — your full arm should be visible.",
        category: .strength,
        isHoldPose: false
    ) { joints in ExerciseAnalysers.bicepCurl(joints: joints) }

    static let shoulderPress = ExerciseDefinition(
        id: "shoulder_press",
        name: "Shoulder Press",
        emoji: "🏋️",
        description: "Start with dumbbells at ear height, press overhead until arms are fully extended.",
        muscleGroups: ["Shoulders", "Triceps", "Upper Chest"],
        defaultSets: 3,
        defaultReps: 10,
        cameraSetup: "Prop your phone in front of you at chest height — both arms should be fully visible.",
        category: .strength,
        isHoldPose: false
    ) { joints in ExerciseAnalysers.shoulderPress(joints: joints) }

    static let lateralRaise = ExerciseDefinition(
        id: "lateral_raise",
        name: "Lateral Raise",
        emoji: "✈️",
        description: "Raise dumbbells out to the sides until arms are parallel to the floor.",
        muscleGroups: ["Side Delts"],
        defaultSets: 3,
        defaultReps: 15,
        cameraSetup: "Prop your phone in front of you at chest height — stand 5-6 feet away.",
        category: .strength,
        isHoldPose: false
    ) { joints in ExerciseAnalysers.lateralRaise(joints: joints) }

    static let squat = ExerciseDefinition(
        id: "squat",
        name: "Dumbbell Squat",
        emoji: "🦵",
        description: "Hold dumbbells at your sides, squat until thighs are parallel to the floor.",
        muscleGroups: ["Quads", "Glutes", "Hamstrings"],
        defaultSets: 3,
        defaultReps: 12,
        cameraSetup: "Prop your phone sideways at hip height, 6 feet away — full body head to ankle.",
        category: .strength,
        isHoldPose: false
    ) { joints in ExerciseAnalysers.squat(joints: joints) }

    static let overheadTricepExtension = ExerciseDefinition(
        id: "tricep_extension",
        name: "Tricep Extension",
        emoji: "🔱",
        description: "Hold one dumbbell overhead with both hands, lower behind head, then extend.",
        muscleGroups: ["Triceps"],
        defaultSets: 3,
        defaultReps: 12,
        cameraSetup: "Prop your phone to your side at shoulder height — your arm from elbow to wrist visible.",
        category: .strength,
        isHoldPose: false
    ) { joints in ExerciseAnalysers.tricepExtension(joints: joints) }

    // ── YOGA ──────────────────────────────────────────────────────────────

    static let warriorOne = ExerciseDefinition(
        id: "warrior_one",
        name: "Warrior I",
        emoji: "🥷",
        description: "Step one foot back, bend front knee to 90°, raise arms overhead with palms together.",
        muscleGroups: ["Hip Flexors", "Quads", "Shoulders"],
        defaultSets: 2,
        defaultReps: 30,      // seconds to hold
        cameraSetup: "Prop your phone to your side so your full body from head to feet is visible.",
        category: .yoga,
        isHoldPose: true
    ) { joints in ExerciseAnalysers.warriorOne(joints: joints) }

    static let warriorTwo = ExerciseDefinition(
        id: "warrior_two",
        name: "Warrior II",
        emoji: "⚔️",
        description: "Wide stance, bend front knee, extend arms parallel to floor and gaze over front hand.",
        muscleGroups: ["Quads", "Glutes", "Shoulders"],
        defaultSets: 2,
        defaultReps: 30,
        cameraSetup: "Prop your phone in front of you so both arms and legs are fully visible.",
        category: .yoga,
        isHoldPose: true
    ) { joints in ExerciseAnalysers.warriorTwo(joints: joints) }

    static let treePose = ExerciseDefinition(
        id: "tree_pose",
        name: "Tree Pose",
        emoji: "🌳",
        description: "Stand on one leg, place the other foot on your inner thigh, raise arms overhead.",
        muscleGroups: ["Balance", "Core", "Glutes"],
        defaultSets: 2,
        defaultReps: 30,
        cameraSetup: "Prop your phone in front of you so your full body from head to standing foot is visible.",
        category: .yoga,
        isHoldPose: true
    ) { joints in ExerciseAnalysers.treePose(joints: joints) }

    static let downwardDog = ExerciseDefinition(
        id: "downward_dog",
        name: "Downward Dog",
        emoji: "🐕",
        description: "Hands and feet on floor, hips raised high, forming an inverted V shape.",
        muscleGroups: ["Hamstrings", "Shoulders", "Calves", "Core"],
        defaultSets: 3,
        defaultReps: 20,
        cameraSetup: "Prop your phone to your side at floor level so your full body is visible.",
        category: .yoga,
        isHoldPose: true
    ) { joints in ExerciseAnalysers.downwardDog(joints: joints) }

    static let chairPose = ExerciseDefinition(
        id: "chair_pose",
        name: "Chair Pose",
        emoji: "🪑",
        description: "Feet together, bend knees as if sitting in a chair, raise arms overhead.",
        muscleGroups: ["Quads", "Glutes", "Core", "Shoulders"],
        defaultSets: 3,
        defaultReps: 30,
        cameraSetup: "Prop your phone to your side so your full body from head to feet is visible.",
        category: .yoga,
        isHoldPose: true
    ) { joints in ExerciseAnalysers.chairPose(joints: joints) }
}

// MARK: - Math Helpers

enum JointMath {

    static func angle(
        from a: VNRecognizedPoint,
        vertex b: VNRecognizedPoint,
        to c: VNRecognizedPoint
    ) -> Double {
        let ax = a.location.x - b.location.x
        let ay = a.location.y - b.location.y
        let cx = c.location.x - b.location.x
        let cy = c.location.y - b.location.y

        let dot = ax * cx + ay * cy
        let magA = sqrt(ax * ax + ay * ay)
        let magC = sqrt(cx * cx + cy * cy)
        guard magA > 0, magC > 0 else { return 0 }

        let cosAngle = max(-1.0, min(1.0, dot / (magA * magC)))
        return acos(cosAngle) * 180.0 / .pi
    }

    static func isReliable(_ point: VNRecognizedPoint, threshold: Float = 0.3) -> Bool {
        point.confidence >= threshold
    }
}

// MARK: - Exercise Analysers

enum ExerciseAnalysers {

    // ── Bicep Curl ────────────────────────────────────────────────────────
    static func bicepCurl(
        joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> (PostureFeedback, repCompleted: Bool) {

        let shoulder = joints[.rightShoulder] ?? joints[.leftShoulder]
        let elbow    = joints[.rightElbow]    ?? joints[.leftElbow]
        let wrist    = joints[.rightWrist]    ?? joints[.leftWrist]
        let hip      = joints[.rightHip]      ?? joints[.leftHip]

        guard let s = shoulder, let e = elbow, let w = wrist, let h = hip,
              JointMath.isReliable(s), JointMath.isReliable(e),
              JointMath.isReliable(w), JointMath.isReliable(h)
        else { return (.waiting, false) }

        let elbowAngle = JointMath.angle(from: s, vertex: e, to: w)
        let hipToShoulder = abs(s.location.x - h.location.x)
        let isBackStraight = hipToShoulder < 0.08

        if !isBackStraight {
            return (PostureFeedback(quality: .incorrect, message: "Stop swinging!", detail: "Keep your upper body still. Only your forearm should move."), false)
        }

        switch elbowAngle {
        case 0..<50:
            return (PostureFeedback(quality: .excellent, message: "Perfect curl! 💪", detail: "Great contraction at the top. Now lower slowly."), false)
        case 50..<80:
            return (PostureFeedback(quality: .good, message: "Good — curl higher", detail: "Squeeze the bicep and bring the weight a little closer."), false)
        case 80..<130:
            return (PostureFeedback(quality: .needsWork, message: "Keep going...", detail: "Halfway there. Keep curling upward."), false)
        case 130..<160:
            return (PostureFeedback(quality: .good, message: "Good start position", detail: "Curl the weight up toward your shoulder."), false)
        default:
            return (PostureFeedback(quality: .excellent, message: "Full extension ✓", detail: "Arms fully lowered. Start the next rep."), false)
        }
    }

    // ── Shoulder Press ────────────────────────────────────────────────────
    static func shoulderPress(
        joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> (PostureFeedback, repCompleted: Bool) {

        let ls = joints[.leftShoulder];  let le = joints[.leftElbow];  let lw = joints[.leftWrist]
        let rs = joints[.rightShoulder]; let re = joints[.rightElbow]; let rw = joints[.rightWrist]
        let lh = joints[.leftHip];       let rh = joints[.rightHip]

        guard let ls, let rs, let le, let re, let lw, let rw, let lh, let rh,
              JointMath.isReliable(ls), JointMath.isReliable(rs),
              JointMath.isReliable(le), JointMath.isReliable(re)
        else { return (.waiting, false) }

        let leftAngle  = JointMath.angle(from: ls, vertex: le, to: lw)
        let rightAngle = JointMath.angle(from: rs, vertex: re, to: rw)
        let avgAngle   = (leftAngle + rightAngle) / 2.0

        let hipMidX      = (lh.location.x + rh.location.x) / 2
        let shoulderMidX = (ls.location.x + rs.location.x) / 2
        if abs(hipMidX - shoulderMidX) > 0.12 {
            return (PostureFeedback(quality: .incorrect, message: "Straighten your back", detail: "Avoid arching. Engage your core throughout the press."), false)
        }

        switch avgAngle {
        case 0..<30:  return (PostureFeedback(quality: .excellent, message: "Arms fully extended! 🙌", detail: "Excellent lockout. Lower with control."), false)
        case 30..<80: return (PostureFeedback(quality: .good, message: "Nearly there!", detail: "Press all the way up until arms are straight."), false)
        case 80..<120:return (PostureFeedback(quality: .needsWork, message: "Keep pressing up", detail: "Drive through the top, don't stop halfway."), false)
        default:      return (PostureFeedback(quality: .good, message: "Start position ✓", detail: "Elbows at 90°. Press the dumbbells overhead."), false)
        }
    }

    // ── Lateral Raise ─────────────────────────────────────────────────────
    static func lateralRaise(
        joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> (PostureFeedback, repCompleted: Bool) {

        let ls = joints[.leftShoulder]; let rs = joints[.rightShoulder]
        let lw = joints[.leftWrist];    let rw = joints[.rightWrist]
        let le = joints[.leftElbow];    let re = joints[.rightElbow]

        guard let ls, let rs, let lw, let rw, let le, let re,
              JointMath.isReliable(ls), JointMath.isReliable(rs)
        else { return (.waiting, false) }

        let leftElev  = lw.location.y - ls.location.y
        let rightElev = rw.location.y - rs.location.y
        let avgElev   = (leftElev + rightElev) / 2.0

        let leftAngle  = JointMath.angle(from: ls, vertex: le, to: lw)
        let rightAngle = JointMath.angle(from: rs, vertex: re, to: rw)
        if leftAngle > 170 || rightAngle > 170 {
            return (PostureFeedback(quality: .needsWork, message: "Soften your elbows", detail: "Keep a slight bend in the elbows throughout."), false)
        }

        switch avgElev {
        case 0.05...:       return (PostureFeedback(quality: .excellent, message: "Parallel! Great raise 🎯", detail: "Arms at shoulder height. Lower slowly with control."), false)
        case -0.02..<0.05:  return (PostureFeedback(quality: .good, message: "Raise a little higher", detail: "Aim for shoulder height — about parallel to the floor."), false)
        default:            return (PostureFeedback(quality: .good, message: "Starting position ✓", detail: "Lift both arms out to your sides simultaneously."), false)
        }
    }

    // ── Squat ─────────────────────────────────────────────────────────────
    static func squat(
        joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> (PostureFeedback, repCompleted: Bool) {

        let lh = joints[.leftHip];    let rh = joints[.rightHip]
        let lk = joints[.leftKnee];   let rk = joints[.rightKnee]
        let la = joints[.leftAnkle];  let ra = joints[.rightAnkle]
        let ls = joints[.leftShoulder]; let rs = joints[.rightShoulder]

        guard let lh, let rh, let lk, let rk, let la, let ra,
              JointMath.isReliable(lh), JointMath.isReliable(rh),
              JointMath.isReliable(lk), JointMath.isReliable(rk)
        else { return (.waiting, false) }

        let leftAngle  = JointMath.angle(from: lh, vertex: lk, to: la)
        let rightAngle = JointMath.angle(from: rh, vertex: rk, to: ra)
        let avgAngle   = (leftAngle + rightAngle) / 2.0

        let kneeWidth  = abs(lk.location.x - rk.location.x)
        let ankleWidth = abs(la.location.x - ra.location.x)
        if kneeWidth < ankleWidth * 0.8 {
            return (PostureFeedback(quality: .incorrect, message: "Push knees out!", detail: "Your knees are caving inward. Drive them out over your toes."), false)
        }

        if let ls, let rs, JointMath.isReliable(ls), JointMath.isReliable(rs) {
            let sMidX = (ls.location.x + rs.location.x) / 2
            let hMidX = (lh.location.x + rh.location.x) / 2
            if abs(sMidX - hMidX) > 0.15 {
                return (PostureFeedback(quality: .incorrect, message: "Keep chest up", detail: "You're leaning too far forward. Lift your chest."), false)
            }
        }

        switch avgAngle {
        case 0..<100:   return (PostureFeedback(quality: .excellent, message: "Depth achieved! 🦵", detail: "Thighs parallel or below. Drive through heels to stand."), false)
        case 100..<130: return (PostureFeedback(quality: .good, message: "Go a little deeper", detail: "Try to get thighs parallel to the floor."), false)
        case 130..<160: return (PostureFeedback(quality: .needsWork, message: "Squat lower", detail: "You're only part way down. Continue descending with control."), false)
        default:        return (PostureFeedback(quality: .excellent, message: "Standing tall ✓", detail: "Feet hip-width. Toes slightly out. Begin your squat."), false)
        }
    }

    // ── Tricep Extension ──────────────────────────────────────────────────
    static func tricepExtension(
        joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> (PostureFeedback, repCompleted: Bool) {

        let s = joints[.rightShoulder] ?? joints[.leftShoulder]
        let e = joints[.rightElbow]    ?? joints[.leftElbow]
        let w = joints[.rightWrist]    ?? joints[.leftWrist]

        guard let s, let e, let w,
              JointMath.isReliable(s), JointMath.isReliable(e), JointMath.isReliable(w)
        else { return (.waiting, false) }

        let elbowAngle = JointMath.angle(from: s, vertex: e, to: w)
        let elbowAboveShoulder = e.location.y > s.location.y - 0.05

        if !elbowAboveShoulder {
            return (PostureFeedback(quality: .needsWork, message: "Elbow drifting down", detail: "Keep your elbows high and pointing toward the ceiling."), false)
        }

        switch elbowAngle {
        case 0..<50:    return (PostureFeedback(quality: .needsWork, message: "Lower the weight more", detail: "Let the dumbbell descend behind your head before pressing up."), false)
        case 50..<100:  return (PostureFeedback(quality: .good, message: "Good stretch", detail: "Now press upward to extend the arms."), false)
        case 150..<180: return (PostureFeedback(quality: .excellent, message: "Full extension! 🔱", detail: "Arms locked out. Lower slowly behind the head."), false)
        default:        return (PostureFeedback(quality: .good, message: "Keep extending", detail: "Press all the way up until arms are straight."), false)
        }
    }

    // ── YOGA ANALYSERS ────────────────────────────────────────────────────

    // ── Warrior I ─────────────────────────────────────────────────────────
    static func warriorOne(
        joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> (PostureFeedback, repCompleted: Bool) {

        let ls = joints[.leftShoulder]; let rs = joints[.rightShoulder]
        let lh = joints[.leftHip];      let rh = joints[.rightHip]
        let lk = joints[.leftKnee];     let rk = joints[.rightKnee]
        let la = joints[.leftAnkle];    let ra = joints[.rightAnkle]
        let lw = joints[.leftWrist];    let rw = joints[.rightWrist]

        guard let ls, let rs, let lh, let rh,
              JointMath.isReliable(ls), JointMath.isReliable(rs),
              JointMath.isReliable(lh), JointMath.isReliable(rh)
        else { return (.waiting, false) }

        // Check front knee is bent ~90°
        let frontKneeAngle: Double? = {
            if let lk, let la, JointMath.isReliable(lk) {
                return JointMath.angle(from: lh, vertex: lk, to: la)
            } else if let rk, let ra, JointMath.isReliable(rk) {
                return JointMath.angle(from: rh, vertex: rk, to: ra)
            }
            return nil
        }()

        // Check arms are raised overhead — wrists above shoulders
        let armsRaised: Bool = {
            guard let lw, let rw else { return false }
            return lw.location.y > ls.location.y + 0.1 &&
                   rw.location.y > rs.location.y + 0.1
        }()

        // Check hips are square — both hips at similar height
        let hipsSquare = abs(lh.location.y - rh.location.y) < 0.06

        if !armsRaised {
            return (PostureFeedback(quality: .needsWork, message: "Raise your arms higher", detail: "Reach both arms straight up, palms facing each other."), false)
        }

        if !hipsSquare {
            return (PostureFeedback(quality: .needsWork, message: "Square your hips", detail: "Rotate your back hip forward so both hips face the front."), false)
        }

        if let angle = frontKneeAngle {
            switch angle {
            case 0..<80:
                return (PostureFeedback(quality: .needsWork, message: "Knee too far forward", detail: "Your front knee should be directly over your ankle."), false)
            case 80..<100:
                return (PostureFeedback(quality: .excellent, message: "Warrior I ✓ Hold strong!", detail: "Perfect 90° bend. Arms high, hips square. Breathe deeply."), false)
            case 100..<130:
                return (PostureFeedback(quality: .good, message: "Bend front knee deeper", detail: "Lower your hips until front knee reaches 90°."), false)
            default:
                return (PostureFeedback(quality: .good, message: "Great stance width", detail: "Now bend your front knee toward 90°."), false)
            }
        }

        return (PostureFeedback(quality: .good, message: "Hold the pose", detail: "Keep arms raised, hips square, breathe steadily."), false)
    }

    // ── Warrior II ────────────────────────────────────────────────────────
    static func warriorTwo(
        joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> (PostureFeedback, repCompleted: Bool) {

        let ls = joints[.leftShoulder]; let rs = joints[.rightShoulder]
        let lh = joints[.leftHip];      let rh = joints[.rightHip]
        let lk = joints[.leftKnee];     let rk = joints[.rightKnee]
        let la = joints[.leftAnkle];    let ra = joints[.rightAnkle]
        let lw = joints[.leftWrist];    let rw = joints[.rightWrist]

        guard let ls, let rs, let lh, let rh, let lw, let rw,
              JointMath.isReliable(ls), JointMath.isReliable(rs)
        else { return (.waiting, false) }

        // Arms should be parallel to floor — wrists at shoulder height
        let leftArmLevel  = abs(lw.location.y - ls.location.y) < 0.08
        let rightArmLevel = abs(rw.location.y - rs.location.y) < 0.08
        let armsParallel  = leftArmLevel && rightArmLevel

        // Shoulders should be stacked over hips (torso upright, not leaning)
        let shoulderMidX = (ls.location.x + rs.location.x) / 2
        let hipMidX      = (lh.location.x + rh.location.x) / 2
        let torsoUpright = abs(shoulderMidX - hipMidX) < 0.08

        // Front knee bend
        let frontKneeAngle: Double? = {
            if let lk, let la, JointMath.isReliable(lk) {
                return JointMath.angle(from: lh, vertex: lk, to: la)
            } else if let rk, let ra, JointMath.isReliable(rk) {
                return JointMath.angle(from: rh, vertex: rk, to: ra)
            }
            return nil
        }()

        if !torsoUpright {
            return (PostureFeedback(quality: .incorrect, message: "Torso is leaning", detail: "Keep your torso upright directly over your hips. Don't lean forward."), false)
        }

        if !armsParallel {
            return (PostureFeedback(quality: .needsWork, message: "Arms parallel to floor", detail: "Extend both arms out at shoulder height, palms facing down."), false)
        }

        if let angle = frontKneeAngle {
            if angle < 80 {
                return (PostureFeedback(quality: .needsWork, message: "Knee past ankle", detail: "Stack your front knee directly over your ankle, not beyond."), false)
            } else if angle < 100 {
                return (PostureFeedback(quality: .excellent, message: "Warrior II ✓ Beautiful!", detail: "Strong 90° bend, arms parallel, torso tall. Hold and breathe."), false)
            } else {
                return (PostureFeedback(quality: .good, message: "Sink lower into the pose", detail: "Bend your front knee deeper toward 90°."), false)
            }
        }

        return (PostureFeedback(quality: .good, message: "Hold Warrior II", detail: "Arms wide, gaze over front fingertips, breathe."), false)
    }

    // ── Tree Pose ─────────────────────────────────────────────────────────
    static func treePose(
        joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> (PostureFeedback, repCompleted: Bool) {

        let ls = joints[.leftShoulder]; let rs = joints[.rightShoulder]
        let lh = joints[.leftHip];      let rh = joints[.rightHip]
        let lw = joints[.leftWrist];    let rw = joints[.rightWrist]
        let lk = joints[.leftKnee];     let rk = joints[.rightKnee]

        guard let ls, let rs, let lh, let rh,
              JointMath.isReliable(ls), JointMath.isReliable(rh)
        else { return (.waiting, false) }

        // One knee should be significantly bent outward (raised leg)
        let leftKneeBent  = lk.map { JointMath.isReliable($0) && $0.location.x < lh.location.x - 0.05 } ?? false
        let rightKneeBent = rk.map { JointMath.isReliable($0) && $0.location.x > rh.location.x + 0.05 } ?? false
        let isBalancing   = leftKneeBent || rightKneeBent

        // Arms should be raised overhead
        let armsRaised: Bool = {
            guard let lw, let rw else { return false }
            return lw.location.y > ls.location.y + 0.15 &&
                   rw.location.y > rs.location.y + 0.15
        }()

        // Torso upright — shoulders level
        let shouldersLevel = abs(ls.location.y - rs.location.y) < 0.05

        if !isBalancing {
            return (PostureFeedback(quality: .needsWork, message: "Lift one foot", detail: "Place the sole of one foot on your inner calf or thigh. Avoid the knee."), false)
        }

        if !shouldersLevel {
            return (PostureFeedback(quality: .needsWork, message: "Level your shoulders", detail: "Keep both shoulders even. Engage your core to stay balanced."), false)
        }

        if !armsRaised {
            return (PostureFeedback(quality: .good, message: "Raise your arms", detail: "Bring both arms overhead, palms together or shoulder-width."), false)
        }

        return (PostureFeedback(quality: .excellent, message: "Tree Pose 🌳 Rooted!", detail: "Balanced, arms high, shoulders level. Breathe and hold steady."), false)
    }

    // ── Downward Dog ──────────────────────────────────────────────────────
    static func downwardDog(
        joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> (PostureFeedback, repCompleted: Bool) {

        let ls = joints[.leftShoulder]; let rs = joints[.rightShoulder]
        let lh = joints[.leftHip];      let rh = joints[.rightHip]
        let lw = joints[.leftWrist];    let rw = joints[.rightWrist]
        let la = joints[.leftAnkle];    let ra = joints[.rightAnkle]
        let lk = joints[.leftKnee];     let rk = joints[.rightKnee]

        guard let ls, let rs, let lh, let rh,
              JointMath.isReliable(ls), JointMath.isReliable(lh)
        else { return (.waiting, false) }

        // Hips should be the highest point — above shoulders and ankles
        let hipMidY      = (lh.location.y + rh.location.y) / 2
        let shoulderMidY = (ls.location.y + rs.location.y) / 2

        let hipsHigh = hipMidY > shoulderMidY + 0.1

        // Knees should be relatively straight
        let kneesStr: Bool = {
            guard let lk, let rk, let la, let ra,
                  JointMath.isReliable(lk), JointMath.isReliable(rk) else { return true }
            let leftAngle  = JointMath.angle(from: lh, vertex: lk, to: la)
            let rightAngle = JointMath.angle(from: rh, vertex: rk, to: ra)
            return leftAngle > 140 && rightAngle > 140
        }()

        // Back should be flat — check shoulder-hip-ankle alignment
        let wristsMidY = {
            guard let lw, let rw else { return shoulderMidY }
            return (lw.location.y + rw.location.y) / 2
        }()
        let backFlat = wristsMidY < shoulderMidY  // wrists lower than shoulders

        if !hipsHigh {
            return (PostureFeedback(quality: .needsWork, message: "Push hips up higher", detail: "Drive your tailbone toward the ceiling to form an inverted V."), false)
        }

        if !kneesStr {
            return (PostureFeedback(quality: .good, message: "Straighten your legs", detail: "Try to straighten the knees. Bend slightly if hamstrings are tight."), false)
        }

        if !backFlat {
            return (PostureFeedback(quality: .needsWork, message: "Lengthen your spine", detail: "Press hands into floor and pull chest toward thighs."), false)
        }

        return (PostureFeedback(quality: .excellent, message: "Downward Dog 🐕 Perfect!", detail: "Hips high, spine long, heels reaching down. Hold and breathe."), false)
    }

    // ── Chair Pose ────────────────────────────────────────────────────────
    static func chairPose(
        joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> (PostureFeedback, repCompleted: Bool) {

        let ls = joints[.leftShoulder]; let rs = joints[.rightShoulder]
        let lh = joints[.leftHip];      let rh = joints[.rightHip]
        let lk = joints[.leftKnee];     let rk = joints[.rightKnee]
        let la = joints[.leftAnkle];    let ra = joints[.rightAnkle]
        let lw = joints[.leftWrist];    let rw = joints[.rightWrist]

        guard let ls, let rs, let lh, let rh,
              JointMath.isReliable(ls), JointMath.isReliable(lh)
        else { return (.waiting, false) }

        // Knee angle — should be 90–120°
        let avgKneeAngle: Double? = {
            guard let lk, let rk, let la, let ra,
                  JointMath.isReliable(lk), JointMath.isReliable(rk) else { return nil }
            let l = JointMath.angle(from: lh, vertex: lk, to: la)
            let r = JointMath.angle(from: rh, vertex: rk, to: ra)
            return (l + r) / 2
        }()

        // Arms overhead
        let armsUp: Bool = {
            guard let lw, let rw else { return false }
            return lw.location.y > ls.location.y + 0.1 &&
                   rw.location.y > rs.location.y + 0.1
        }()

        // Torso should lean slightly forward but not collapse
        let shoulderMidX = (ls.location.x + rs.location.x) / 2
        let hipMidX      = (lh.location.x + rh.location.x) / 2
        let excessiveLean = abs(shoulderMidX - hipMidX) > 0.18

        if excessiveLean {
            return (PostureFeedback(quality: .incorrect, message: "Too much forward lean", detail: "Keep your torso relatively upright, weight in your heels."), false)
        }

        if !armsUp {
            return (PostureFeedback(quality: .needsWork, message: "Raise your arms", detail: "Reach both arms straight overhead, biceps beside your ears."), false)
        }

        if let angle = avgKneeAngle {
            switch angle {
            case 0..<80:
                return (PostureFeedback(quality: .needsWork, message: "Knees past toes", detail: "Sit back more — keep knees over ankles, not beyond."), false)
            case 80..<130:
                return (PostureFeedback(quality: .excellent, message: "Chair Pose 🪑 Strong!", detail: "Sitting low, arms high, weight in heels. Hold and breathe."), false)
            default:
                return (PostureFeedback(quality: .good, message: "Sit lower", detail: "Bend knees deeper as if sitting in an invisible chair."), false)
            }
        }

        return (PostureFeedback(quality: .good, message: "Bend your knees", detail: "Lower your hips as if sitting back into a chair."), false)
    }
}
