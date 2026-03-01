// Views/CameraPreviewView.swift
// UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer.
// Automatically updates the preview layer rotation when the device orientation changes,
// so the video looks correct in both portrait AND landscape.

import SwiftUI
import AVFoundation
import UIKit

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> OrientationAwarePreviewView {
        let view = OrientationAwarePreviewView(session: session)
        // Start receiving orientation change notifications
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        return view
    }

    func updateUIView(_ uiView: OrientationAwarePreviewView, context: Context) {
        // Called when SwiftUI re-renders — update frame + orientation
        uiView.updateOrientation()
    }
}

// MARK: - OrientationAwarePreviewView

final class OrientationAwarePreviewView: UIView {

    // MARK: Layer

    private let previewLayer: AVCaptureVideoPreviewLayer

    // MARK: Init

    init(session: AVCaptureSession) {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        super.init(frame: .zero)
        backgroundColor = .black
        layer.addSublayer(previewLayer)

        // Listen for device rotation
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        // Keep layer filling the view on every layout pass (rotation, split-view, etc.)
        CATransaction.begin()
        CATransaction.setDisableActions(true)   // no implicit animation on frame change
        previewLayer.frame = bounds
        CATransaction.commit()
        updateOrientation()
    }

    // MARK: Orientation

    @objc func orientationDidChange() {
        updateOrientation()
    }

    /// Maps UIDevice orientation → AVCaptureConnection videoRotationAngle.
    ///
    /// The camera sensor is physically landscape. videoRotationAngle rotates
    /// the rendered content so it appears upright for the current device orientation:
    ///   Portrait              →  90°
    ///   Landscape left        →   0°   (home/USB-C button on right)
    ///   Landscape right       → 180°   (home/USB-C button on left)
    ///   Portrait upside-down  → 270°
    func updateOrientation() {
        guard let connection = previewLayer.connection else { return }

        let deviceOrientation = UIDevice.current.orientation
        let angle: CGFloat

        switch deviceOrientation {
        case .portrait:           angle = 90
        case .portraitUpsideDown: angle = 270
        case .landscapeLeft:      angle = 0     // device rotated left → home button on right
        case .landscapeRight:     angle = 180   // device rotated right → home button on left
        default:
            // Flat / unknown — keep current angle, don't snap to wrong orientation
            return
        }

        // isVideoRotationAngleSupported is available iOS 17+
        // The app targets iOS 17, so this is always available
        if connection.isVideoRotationAngleSupported(angle) {
            connection.videoRotationAngle = angle
        }
    }
}
