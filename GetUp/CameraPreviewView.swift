// Views/CameraPreviewView.swift
// Wraps AVCaptureVideoPreviewLayer in a SwiftUI view.
// The skeleton overlay is drawn on top in SkeletonOverlayView.

import SwiftUI
import UIKit
import AVFoundation
import Vision



// MARK: - CameraPreviewView

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

// MARK: - CameraPreviewUIView

final class CameraPreviewUIView: UIView {

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}

// MARK: - SkeletonOverlayView
// Draws the skeleton on top of the camera feed using SwiftUI Canvas

struct SkeletonOverlayView: View {
    let poseResult: PoseDetectionResult
    let size: CGSize

    var body: some View {
        Canvas { context, canvasSize in
            guard !poseResult.isEmpty else { return }

            let joints = poseResult.joints

            // Draw bones (lines between joints)
            for bone in SkeletonModel.bones {
                guard
                    let fromPoint = joints[bone.from],
                    let toPoint   = joints[bone.to],
                    fromPoint.confidence >= 0.3,
                    toPoint.confidence >= 0.3
                else { continue }

                let from = convertPoint(fromPoint.location, in: canvasSize)
                let to   = convertPoint(toPoint.location,   in: canvasSize)

                var path = Path()
                path.move(to: from)
                path.addLine(to: to)

                context.stroke(
                    path,
                    with: .color(.white.opacity(0.55)),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
            }

            // Draw joint dots
            for (name, point) in joints {
                guard point.confidence >= 0.3 else { continue }

                let screenPoint = convertPoint(point.location, in: canvasSize)
                let radius: CGFloat = isKeyJoint(name) ? 6 : 4

                let dotRect = CGRect(
                    x: screenPoint.x - radius,
                    y: screenPoint.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )

                // Outer ring
                context.stroke(
                    Circle().path(in: dotRect.insetBy(dx: -1, dy: -1)),
                    with: .color(.white.opacity(0.4)),
                    lineWidth: 1
                )

                // Filled dot — colour by confidence
                let dotColor = colorForConfidence(Double(point.confidence))
                context.fill(Circle().path(in: dotRect), with: .color(dotColor))
            }
        }
    }

    // MARK: - Helpers

    /// Vision coordinates: (0,0) = bottom-left. Convert to screen: (0,0) = top-left.
    private func convertPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: point.x * size.width,
            y: (1.0 - point.y) * size.height
        )
    }

    private func isKeyJoint(_ name: VNHumanBodyPoseObservation.JointName) -> Bool {
        switch name {
        case .leftElbow, .rightElbow, .leftKnee, .rightKnee,
             .leftShoulder, .rightShoulder, .leftHip, .rightHip:
            return true
        default:
            return false
        }
    }

    private func colorForConfidence(_ confidence: Double) -> Color {
        switch confidence {
        case 0.8...: return Color(hex: "00C896")   // green — high confidence
        case 0.5..<0.8: return Color(hex: "FFB740") // amber — medium
        default: return Color(hex: "FF5A5A")         // red — low
        }
    }
}
