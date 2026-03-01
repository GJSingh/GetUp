// Views/CameraPreviewView.swift
// Orientation-aware AVCaptureVideoPreviewLayer.
//
// Design:
// - Listens to UIDevice.orientationDidChangeNotification (fires once per rotation, on main thread)
// - Reads UIWindowScene.interfaceOrientation — already settled when notification arrives
// - Does NOT use traitCollectionDidChange — on iPhone, size class stays .compact in both
//   portrait and landscape, so that callback never fires for orientation changes
// - Frame updates use CATransaction.setDisableActions(true) to prevent fighting iOS animation

import SwiftUI
import AVFoundation
import UIKit

// MARK: - SwiftUI Wrapper

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        return PreviewView(session: session)
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.syncFrame()
    }
}

// MARK: - PreviewView

final class PreviewView: UIView {

    private let previewLayer: AVCaptureVideoPreviewLayer

    init(session: AVCaptureSession) {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        super.init(frame: .zero)
        backgroundColor = .black
        layer.addSublayer(previewLayer)
        applyRotation(angle: 90)   // default portrait

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceOrientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Frame

    func syncFrame() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.frame = bounds
        CATransaction.commit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        syncFrame()
    }

    // MARK: - Orientation

    @objc private func deviceOrientationChanged() {
        // UIDevice.orientationDidChangeNotification fires on the main thread.
        // UIWindowScene.interfaceOrientation is already the final settled value here.
        applyRotation(angle: currentAngle())
    }

    private func applyRotation(angle: CGFloat) {
        guard let connection = previewLayer.connection,
              connection.isVideoRotationAngleSupported(angle) else { return }
        connection.videoRotationAngle = angle
    }

    /// Maps interface orientation to videoRotationAngle.
    ///
    ///  Portrait            →  90°   (sensor is landscape, rotate 90° to stand upright)
    ///  LandscapeLeft       →   0°   (home/USB on right — matches sensor natural orientation)
    ///  LandscapeRight      → 180°   (home/USB on left  — sensor 180° from display)
    ///  PortraitUpsideDown  → 270°
    ///
    /// Note: UIInterfaceOrientation.landscapeLeft means the device was rotated
    /// clockwise so the home button is on the LEFT side of the screen — confusingly
    /// named. The sensor faces landscapeLeft naturally, so 0° = no rotation needed.
    private func currentAngle() -> CGFloat {
        // Prefer windowScene (settled final value) over UIDevice (can be mid-rotation)
        guard let scene = window?.windowScene else {
            return angleFor(UIDevice.current.orientation)
        }
        return angleFor(scene.interfaceOrientation)
    }

    private func angleFor(_ orientation: UIInterfaceOrientation) -> CGFloat {
        switch orientation {
        case .portrait:            return 90
        case .portraitUpsideDown:  return 270
        case .landscapeLeft:       return 0     // home/USB on right
        case .landscapeRight:      return 180   // home/USB on left
        @unknown default:          return 90
        }
    }

    /// Fallback: convert UIDevice orientation to an angle when window scene unavailable
    private func angleFor(_ orientation: UIDeviceOrientation) -> CGFloat {
        switch orientation {
        case .portrait:            return 90
        case .portraitUpsideDown:  return 270
        case .landscapeLeft:       return 180   // device rotated CW → interface is landscapeRight
        case .landscapeRight:      return 0     // device rotated CCW → interface is landscapeLeft
        default:                   return 90
        }
    }
}
