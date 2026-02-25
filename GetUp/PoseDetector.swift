// Services/PoseDetector.swift
// Wraps Apple's Vision framework to detect human body pose from camera frames.
// All processing is on-device. No data leaves the phone.

import Vision
import CoreImage
import QuartzCore

//import UIKit

// MARK: - PoseDetectionResult

struct PoseDetectionResult {
    let joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    let confidence: Float         // overall detection confidence
    let timestamp: TimeInterval

    var isEmpty: Bool { joints.isEmpty }

    /// Returns a reliable joint or nil if not detected / low confidence
    func joint(_ name: VNHumanBodyPoseObservation.JointName, minConfidence: Float = 0.3) -> VNRecognizedPoint? {
        guard let point = joints[name], point.confidence >= minConfidence else { return nil }
        return point
    }
}

// MARK: - PoseDetector

final class PoseDetector {

    private let requestQueue = DispatchQueue(label: "com.GetUp.pose", qos: .userInteractive)
    private var request: VNDetectHumanBodyPoseRequest

    /// Called on background thread with each new result
    var onResult: ((PoseDetectionResult) -> Void)?

    init() {
        request = VNDetectHumanBodyPoseRequest()
        // request.maximumHandCount = 1     we only care about one person
    }

    // MARK: - Process Frame

    /// Call this with each CVPixelBuffer from CameraManager
    func process(pixelBuffer: CVPixelBuffer) {
        requestQueue.async { [weak self] in
            guard let self else { return }

            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: .up,
                options: [:]
            )

            do {
                try handler.perform([self.request])
            } catch {
                // Vision errors are non-fatal — we simply skip this frame
                return
            }

            guard let observation = self.request.results?.first else {
                // No person detected this frame — emit empty result
                let empty = PoseDetectionResult(joints: [:], confidence: 0, timestamp: CACurrentMediaTime())
                self.onResult?(empty)
                return
            }

            guard let joints = try? observation.recognizedPoints(.all) else { return }

            let result = PoseDetectionResult(
                joints: joints,
                confidence: observation.confidence,
                timestamp: CACurrentMediaTime()
            )
            self.onResult?(result)
        }
    }
}

// MARK: - Skeleton Model
// Defines the lines (bones) to draw connecting joints

enum SkeletonModel {

    struct Bone {
        let from: VNHumanBodyPoseObservation.JointName
        let to: VNHumanBodyPoseObservation.JointName
    }

    static let bones: [Bone] = [
        // Torso
        Bone(from: .leftShoulder,  to: .rightShoulder),
        Bone(from: .leftShoulder,  to: .leftHip),
        Bone(from: .rightShoulder, to: .rightHip),
        Bone(from: .leftHip,       to: .rightHip),
        Bone(from: .leftShoulder,  to: .neck),
        Bone(from: .rightShoulder, to: .neck),
        Bone(from: .neck,          to: .root),     // spine center

        // Left arm
        Bone(from: .leftShoulder, to: .leftElbow),
        Bone(from: .leftElbow,    to: .leftWrist),

        // Right arm
        Bone(from: .rightShoulder, to: .rightElbow),
        Bone(from: .rightElbow,    to: .rightWrist),

        // Left leg
        Bone(from: .leftHip,   to: .leftKnee),
        Bone(from: .leftKnee,  to: .leftAnkle),

        // Right leg
        Bone(from: .rightHip,   to: .rightKnee),
        Bone(from: .rightKnee,  to: .rightAnkle),
    ]
}
