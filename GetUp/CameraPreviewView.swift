// Views/CameraPreviewView.swift
// Orientation-aware AVCaptureVideoPreviewLayer.
//
// WHY layoutSubviews instead of notifications:
//   UIDevice.orientationDidChangeNotification fires BEFORE windowScene.interfaceOrientation
//   updates — so reading the scene in the notification callback returns the OLD orientation.
//   layoutSubviews is called AFTER iOS finishes its rotation animation and the view has
//   its final bounds + the window scene has its correct interfaceOrientation.
//   This eliminates all timing races.

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
        // Called on every SwiftUI render pass — keeps frame + rotation in sync
        uiView.syncFrameAndRotation()
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
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        syncFrameAndRotation()
    }

    /// Updates both the layer frame and the video rotation angle.
    /// Safe to call from layoutSubviews or updateUIView — both run on the main thread
    /// after the view hierarchy has settled into its final state.
    func syncFrameAndRotation() {
        // Resize layer without implicit CA animation (prevents fighting iOS rotation animation)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.frame = bounds
        CATransaction.commit()

        // Apply correct video rotation based on current interface orientation
        setVideoRotation()

        // On fullScreenCover presentation the view lays out before the window scene
        // is attached, so window?.windowScene returns nil and we fall back to the
        // aspect-ratio guess (which can't distinguish landscapeLeft from landscapeRight).
        // Schedule a follow-up correction once the scene is guaranteed to be available.
        if window?.windowScene == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.setVideoRotation()
            }
        }
    }

    // MARK: - Rotation

    private func setVideoRotation() {
        guard let connection = previewLayer.connection else { return }
        let angle = currentRotationAngle()
        guard connection.isVideoRotationAngleSupported(angle) else { return }
        connection.videoRotationAngle = angle
    }

    /// Derives the correct videoRotationAngle from the current interface orientation.
    ///
    /// videoRotationAngle tells AVFoundation how much to rotate the sensor output
    /// so it appears upright on screen:
    ///
    ///   Portrait              →  90°  (sensor is naturally landscape; rotate CW to stand upright)
    ///   LandscapeRight        →   0°  (home/USB-C on RIGHT — sensor natural orientation, no rotation)
    ///   LandscapeLeft         → 180°  (home/USB-C on LEFT  — sensor is upside-down, rotate 180°)
    ///   PortraitUpsideDown    → 270°
    ///
    /// UIInterfaceOrientation.landscapeRight = home button on the RIGHT side of the screen.
    /// UIInterfaceOrientation.landscapeLeft  = home button on the LEFT  side of the screen.
    /// (Confusingly, UIDeviceOrientation has the OPPOSITE naming for landscape.)
    private func currentRotationAngle() -> CGFloat {
        // Use effectiveGeometry.interfaceOrientation (iOS 26+, replaces deprecated .interfaceOrientation)
        if let scene = window?.windowScene {
            let orientation = scene.effectiveGeometry.interfaceOrientation
            switch orientation {
            case .portrait:            return 90
            case .portraitUpsideDown:  return 270
            case .landscapeRight:      return 0    // home on RIGHT → sensor natural, no rotation needed
            case .landscapeLeft:       return 180  // home on LEFT  → sensor is flipped, rotate 180°
            case .unknown:             break        // exhaustive — treat unknown as portrait
            @unknown default:          break
            }
        }

        // Fallback: derive from view bounds aspect ratio.
        // Cannot determine left-vs-right landscape from bounds alone, so use 0° for both
        // (person will appear upright; left/right flip is acceptable as fallback)
        if bounds.width > bounds.height {
            return 0    // landscape frame → landscape rotation
        } else {
            return 90   // portrait frame → portrait rotation
        }
    }
}
