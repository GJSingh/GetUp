// Models/ExerciseLibrary.swift
// Defines all supported exercises with their posture rules and rep detection logic.
// To add a new exercise: create a new ExerciseDefinition and add it to ExerciseLibrary.all

import Foundation
import Vision

// MARK: - PostureFeedback
// What the app shows the user during a workout

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
// Tracks where in the rep cycle the user is

enum RepPhase {
    case start          // resting position
    case midMovement    // transitioning
    case peak           // full contraction / end range
}

// MARK: - ExerciseDefinition
// All data needed to analyse one exercise

struct ExerciseDefinition: Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
    let description: String
    let muscleGroups: [String]
    let defaultSets: Int
    let defaultReps: Int
    let cameraSetup: String           // instruction for how to position phone

    // The analyser function — receives joint positions, returns feedback + rep event
    typealias Analyser = (_ joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> (PostureFeedback, repCompleted: Bool)

    let analyse: Analyser

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: ExerciseDefinition, rhs: ExerciseDefinition) -> Bool { lhs.id == rhs.id }
}

// MARK: - ExerciseLibrary

enum ExerciseLibrary {

    static let all: [ExerciseDefinition] = [
        bicepCurl,
        shoulderPress,
        lateralRaise,
        squat,
        overheadTricepExtension
    ]

    static func exercise(id: String) -> ExerciseDefinition? {
        all.first { $0.id == id }
    }

    // ── Bicep Curl ────────────────────────────────────────────────────────

    static let bicepCurl = ExerciseDefinition(
        id: "bicep_curl",
        name: "Bicep Curl",
        emoji: "💪",
        description: "Stand tall, curl the dumbbell toward your shoulder, then lower under control.",
        muscleGroups: ["Biceps", "Forearms"],
        defaultSets: 3,
        defaultReps: 12,
        cameraSetup: "Place your phone to the side so your full arm is visible from wrist to shoulder."
    ) { joints in
        return ExerciseAnalysers.bicepCurl(joints: joints)
    }

    // ── Shoulder Press ────────────────────────────────────────────────────

    static let shoulderPress = ExerciseDefinition(
        id: "shoulder_press",
        name: "Shoulder Press",
        emoji: "🏋️",
        description: "Start with dumbbells at ear height, press overhead until arms are fully extended.",
        muscleGroups: ["Shoulders", "Triceps", "Upper Chest"],
        defaultSets: 3,
        defaultReps: 10,
        cameraSetup: "Place your phone in front of you so your full upper body is visible."
    ) { joints in
        return ExerciseAnalysers.shoulderPress(joints: joints)
    }

    // ── Lateral Raise ─────────────────────────────────────────────────────

    static let lateralRaise = ExerciseDefinition(
        id: "lateral_raise",
        name: "Lateral Raise",
        emoji: "✈️",
        description: "Raise dumbbells out to the sides until arms are parallel to the floor.",
        muscleGroups: ["Side Delts"],
        defaultSets: 3,
        defaultReps: 15,
        cameraSetup: "Place your phone in front of you so both arms are fully visible."
    ) { joints in
        return ExerciseAnalysers.lateralRaise(joints: joints)
    }

    // ── Squat ─────────────────────────────────────────────────────────────

    static let squat = ExerciseDefinition(
        id: "squat",
        name: "Dumbbell Squat",
        emoji: "🦵",
        description: "Hold dumbbells at your sides, squat until thighs are parallel to the floor.",
        muscleGroups: ["Quads", "Glutes", "Hamstrings"],
        defaultSets: 3,
        defaultReps: 12,
        cameraSetup: "Place your phone to the side so your full body from head to ankle is visible."
    ) { joints in
        return ExerciseAnalysers.squat(joints: joints)
    }

    // ── Overhead Tricep Extension ─────────────────────────────────────────

    static let overheadTricepExtension = ExerciseDefinition(
        id: "tricep_extension",
        name: "Tricep Extension",
        emoji: "🔱",
        description: "Hold one dumbbell overhead with both hands, lower behind head, then extend.",
        muscleGroups: ["Triceps"],
        defaultSets: 3,
        defaultReps: 12,
        cameraSetup: "Place your phone to the side so your full arm from elbow to wrist is visible."
    ) { joints in
        return ExerciseAnalysers.tricepExtension(joints: joints)
    }
}

// MARK: - Math Helpers

enum JointMath {

    /// Calculates the angle in degrees at the vertex joint, given three points.
    /// vertex is the middle joint (e.g. elbow when measuring elbow flexion).
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

    /// Returns true if a point has sufficient confidence to be used.
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

        // We use the RIGHT arm by default.
        // If right side not visible, fall back to left.
        let shoulder = joints[.rightShoulder] ?? joints[.leftShoulder]
        let elbow    = joints[.rightElbow]    ?? joints[.leftElbow]
        let wrist    = joints[.rightWrist]    ?? joints[.leftWrist]
        let hip      = joints[.rightHip]      ?? joints[.leftHip]

        guard
            let s = shoulder, let e = elbow, let w = wrist, let h = hip,
            JointMath.isReliable(s), JointMath.isReliable(e),
            JointMath.isReliable(w), JointMath.isReliable(h)
        else {
            return (.waiting, false)
        }

        let elbowAngle = JointMath.angle(from: s, vertex: e, to: w)

        // Back straightness: shoulder should stay over hip (no swinging)
        let hipToShoulder = abs(s.location.x - h.location.x)
        let isBackStraight = hipToShoulder < 0.08

        // Rep detection: full rep = angle goes below 60° then back above 140°
        // This is handled by RepCounter using angle history.
        // Here we just return the current feedback.
        let repCompleted = false  // RepCounter handles this

        if !isBackStraight {
            return (PostureFeedback(
                quality: .incorrect,
                message: "Stop swinging!",
                detail: "Keep your upper body still. Only your forearm should move."
            ), repCompleted)
        }

        switch elbowAngle {
        case 0..<50:
            return (PostureFeedback(
                quality: .excellent,
                message: "Perfect curl! 💪",
                detail: "Great contraction at the top. Now lower slowly."
            ), repCompleted)
        case 50..<80:
            return (PostureFeedback(
                quality: .good,
                message: "Good — curl higher",
                detail: "Squeeze the bicep and bring the weight a little closer."
            ), repCompleted)
        case 80..<130:
            return (PostureFeedback(
                quality: .needsWork,
                message: "Keep going...",
                detail: "Halfway there. Keep curling upward."
            ), repCompleted)
        case 130..<160:
            return (PostureFeedback(
                quality: .good,
                message: "Good start position",
                detail: "Curl the weight up toward your shoulder."
            ), repCompleted)
        default:
            return (PostureFeedback(
                quality: .excellent,
                message: "Full extension ✓",
                detail: "Arms fully lowered. Start the next rep."
            ), repCompleted)
        }
    }

    // ── Shoulder Press ────────────────────────────────────────────────────
    static func shoulderPress(
        joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> (PostureFeedback, repCompleted: Bool) {

        let leftShoulder  = joints[.leftShoulder]
        let rightShoulder = joints[.rightShoulder]
        let leftElbow     = joints[.leftElbow]
        let rightElbow    = joints[.rightElbow]
        let leftWrist     = joints[.leftWrist]
        let rightWrist    = joints[.rightWrist]
        let leftHip       = joints[.leftHip]
        let rightHip      = joints[.rightHip]

        guard
            let ls = leftShoulder, let rs = rightShoulder,
            let le = leftElbow,   let re = rightElbow,
            let lw = leftWrist,   let rw = rightWrist,
            let lh = leftHip,     let rh = rightHip,
            JointMath.isReliable(ls), JointMath.isReliable(rs),
            JointMath.isReliable(le), JointMath.isReliable(re)
        else {
            return (.waiting, false)
        }

        let leftElbowAngle  = JointMath.angle(from: ls, vertex: le, to: lw)
        let rightElbowAngle = JointMath.angle(from: rs, vertex: re, to: rw)
        let avgElbowAngle   = (leftElbowAngle + rightElbowAngle) / 2.0

        // Check for back arch: hips should not drift forward relative to shoulders
        let hipMidX = (lh.location.x + rh.location.x) / 2
        let shoulderMidX = (ls.location.x + rs.location.x) / 2
        let backArch = abs(hipMidX - shoulderMidX) > 0.12

        if backArch {
            return (PostureFeedback(
                quality: .incorrect,
                message: "Straighten your back",
                detail: "Avoid arching. Engage your core throughout the press."
            ), false)
        }

        switch avgElbowAngle {
        case 0..<30:
            return (PostureFeedback(
                quality: .excellent,
                message: "Arms fully extended! 🙌",
                detail: "Excellent lockout. Lower with control."
            ), false)
        case 30..<80:
            return (PostureFeedback(
                quality: .good,
                message: "Nearly there!",
                detail: "Press all the way up until arms are straight."
            ), false)
        case 80..<120:
            return (PostureFeedback(
                quality: .needsWork,
                message: "Keep pressing up",
                detail: "Drive through the top, don't stop halfway."
            ), false)
        default:
            return (PostureFeedback(
                quality: .good,
                message: "Start position ✓",
                detail: "Elbows at 90°. Press the dumbbells overhead."
            ), false)
        }
    }

    // ── Lateral Raise ─────────────────────────────────────────────────────
    static func lateralRaise(
        joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> (PostureFeedback, repCompleted: Bool) {

        let leftShoulder  = joints[.leftShoulder]
        let rightShoulder = joints[.rightShoulder]
        let leftWrist     = joints[.leftWrist]
        let rightWrist    = joints[.rightWrist]
        let leftElbow     = joints[.leftElbow]
        let rightElbow    = joints[.rightElbow]

        guard
            let ls = leftShoulder, let rs = rightShoulder,
            let lw = leftWrist,   let rw = rightWrist,
            let le = leftElbow,   let re = rightElbow,
            JointMath.isReliable(ls), JointMath.isReliable(rs)
        else {
            return (.waiting, false)
        }

        // Arm elevation: how high are the wrists relative to shoulders?
        let leftElevation  = lw.location.y - ls.location.y
        let rightElevation = rw.location.y - rs.location.y
        let avgElevation   = (leftElevation + rightElevation) / 2.0

        // Elbow should stay slightly bent (avoid locked elbows)
        let leftElbowAngle  = JointMath.angle(from: ls, vertex: le, to: lw)
        let rightElbowAngle = JointMath.angle(from: rs, vertex: re, to: rw)
        let elbowsTooStraight = leftElbowAngle > 170 || rightElbowAngle > 170

        if elbowsTooStraight {
            return (PostureFeedback(
                quality: .needsWork,
                message: "Soften your elbows",
                detail: "Keep a slight bend in the elbows throughout the movement."
            ), false)
        }

        switch avgElevation {
        case 0.05...:
            return (PostureFeedback(
                quality: .excellent,
                message: "Parallel! Great raise 🎯",
                detail: "Arms at shoulder height. Lower slowly with control."
            ), false)
        case -0.02..<0.05:
            return (PostureFeedback(
                quality: .good,
                message: "Raise a little higher",
                detail: "Aim for shoulder height — about parallel to the floor."
            ), false)
        default:
            return (PostureFeedback(
                quality: .good,
                message: "Starting position ✓",
                detail: "Lift both arms out to your sides simultaneously."
            ), false)
        }
    }

    // ── Squat ─────────────────────────────────────────────────────────────
    static func squat(
        joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> (PostureFeedback, repCompleted: Bool) {

        let leftHip   = joints[.leftHip]
        let rightHip  = joints[.rightHip]
        let leftKnee  = joints[.leftKnee]
        let rightKnee = joints[.rightKnee]
        let leftAnkle = joints[.leftAnkle]
        let rightAnkle = joints[.rightAnkle]
        let leftShoulder  = joints[.leftShoulder]
        let rightShoulder = joints[.rightShoulder]

        guard
            let lh = leftHip,   let rh = rightHip,
            let lk = leftKnee,  let rk = rightKnee,
            let la = leftAnkle, let ra = rightAnkle,
            JointMath.isReliable(lh), JointMath.isReliable(rh),
            JointMath.isReliable(lk), JointMath.isReliable(rk)
        else {
            return (.waiting, false)
        }

        let leftKneeAngle  = JointMath.angle(from: lh, vertex: lk, to: la)
        let rightKneeAngle = JointMath.angle(from: rh, vertex: rk, to: ra)
        let avgKneeAngle   = (leftKneeAngle + rightKneeAngle) / 2.0

        // Knee caving: knees should stay outside of ankle width
        let kneeWidth   = abs(lk.location.x - rk.location.x)
        let ankleWidth  = abs(la.location.x - ra.location.x)
        let kneesCaving = kneeWidth < ankleWidth * 0.8

        // Back lean: shoulders should stay roughly over hips
        if let ls = leftShoulder, let rs = rightShoulder,
           JointMath.isReliable(ls), JointMath.isReliable(rs) {
            let shoulderMidX = (ls.location.x + rs.location.x) / 2
            let hipMidX = (lh.location.x + rh.location.x) / 2
            let excessiveLean = abs(shoulderMidX - hipMidX) > 0.15
            if excessiveLean {
                return (PostureFeedback(
                    quality: .incorrect,
                    message: "Keep chest up",
                    detail: "You're leaning too far forward. Lift your chest and keep your torso upright."
                ), false)
            }
        }

        if kneesCaving {
            return (PostureFeedback(
                quality: .incorrect,
                message: "Push knees out!",
                detail: "Your knees are caving inward. Drive them out over your toes."
            ), false)
        }

        switch avgKneeAngle {
        case 0..<100:
            return (PostureFeedback(
                quality: .excellent,
                message: "Depth achieved! 🦵",
                detail: "Thighs parallel or below. Drive through heels to stand."
            ), false)
        case 100..<130:
            return (PostureFeedback(
                quality: .good,
                message: "Go a little deeper",
                detail: "Try to get thighs parallel to the floor."
            ), false)
        case 130..<160:
            return (PostureFeedback(
                quality: .needsWork,
                message: "Squat lower",
                detail: "You're only part way down. Continue descending with control."
            ), false)
        default:
            return (PostureFeedback(
                quality: .excellent,
                message: "Standing tall ✓",
                detail: "Feet hip-width. Toes slightly out. Begin your squat."
            ), false)
        }
    }

    // ── Overhead Tricep Extension ─────────────────────────────────────────
    static func tricepExtension(
        joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> (PostureFeedback, repCompleted: Bool) {

        let shoulder = joints[.rightShoulder] ?? joints[.leftShoulder]
        let elbow    = joints[.rightElbow]    ?? joints[.leftElbow]
        let wrist    = joints[.rightWrist]    ?? joints[.leftWrist]

        guard
            let s = shoulder, let e = elbow, let w = wrist,
            JointMath.isReliable(s), JointMath.isReliable(e), JointMath.isReliable(w)
        else {
            return (.waiting, false)
        }

        let elbowAngle = JointMath.angle(from: s, vertex: e, to: w)

        // Upper arm should stay vertical (elbow pointing up)
        // We check if the elbow is above the shoulder
        let elbowAboveShoulder = e.location.y > s.location.y - 0.05

        if !elbowAboveShoulder {
            return (PostureFeedback(
                quality: .needsWork,
                message: "Elbow drifting down",
                detail: "Keep your elbows high and pointing toward the ceiling."
            ), false)
        }

        switch elbowAngle {
        case 0..<50:
            return (PostureFeedback(
                quality: .needsWork,
                message: "Lower the weight more",
                detail: "Let the dumbbell descend behind your head before pressing up."
            ), false)
        case 50..<100:
            return (PostureFeedback(
                quality: .good,
                message: "Good stretch",
                detail: "Now press upward to extend the arms."
            ), false)
        case 150..<180:
            return (PostureFeedback(
                quality: .excellent,
                message: "Full extension! 🔱",
                detail: "Arms locked out. Lower slowly behind the head."
            ), false)
        default:
            return (PostureFeedback(
                quality: .good,
                message: "Keep extending",
                detail: "Press all the way up until arms are straight."
            ), false)
        }
    }
}
