// Services/CameraManager.swift
// Manages the AVCaptureSession, delivers pixel buffers for pose analysis.
// Privacy: Video frames are processed in memory only. Never written to disk or sent over network.

import AVFoundation
//import UIKit
import Combine

// MARK: - CameraManager

final class CameraManager: NSObject, ObservableObject {

    // MARK: Published State
    @Published var isRunning = false
    @Published var isCameraAuthorised = false
    @Published var errorMessage: String?

    // MARK: Capture Session
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.GetUp.camera.session", qos: .userInteractive)

    // MARK: Frame Delivery
    /// Called on a background thread with each new camera frame.
    var onFrame: ((CVPixelBuffer) -> Void)?

    // MARK: Camera Position
    private(set) var position: AVCaptureDevice.Position = .back

    override init() {
        super.init()
        checkAuthorisation()
    }

    // MARK: - Authorisation

    func checkAuthorisation() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async { self.isCameraAuthorised = true }
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isCameraAuthorised = granted
                    if granted { self?.setupSession() }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.isCameraAuthorised = false
                self.errorMessage = "Camera access denied. Go to Settings > FitCoach AI to enable."
            }
        @unknown default:
            break
        }
    }

    // MARK: - Session Setup

    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .hd1280x720

            // Add camera input
            guard let device = self.camera(for: self.position),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.captureSession.canAddInput(input) else {
                self.captureSession.commitConfiguration()
                DispatchQueue.main.async {
                    self.errorMessage = "Could not access camera device."
                }
                return
            }
            self.captureSession.addInput(input)

            // Add video output
            self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            ]

            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
            }

            // Set video orientation
            if let connection = self.videoOutput.connection(with: .video) {
                connection.videoRotationAngle = 90
                connection.isVideoMirrored = (self.position == .front)
            }

            self.captureSession.commitConfiguration()
        }
    }

    // MARK: - Start / Stop

    func start() {
        sessionQueue.async { [weak self] in
            guard let self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
            DispatchQueue.main.async { self.isRunning = true }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            DispatchQueue.main.async { self.isRunning = false }
        }
    }

    // MARK: - Camera Switch

    func flipCamera() {
        position = (position == .back) ? .front : .back
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.captureSession.beginConfiguration()

            // Remove existing inputs
            self.captureSession.inputs.forEach { self.captureSession.removeInput($0) }

            // Add new input
            guard let device = self.camera(for: self.position),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.captureSession.canAddInput(input) else {
                self.captureSession.commitConfiguration()
                return
            }
            self.captureSession.addInput(input)

            // Update mirroring
            if let connection = self.videoOutput.connection(with: .video) {
                connection.isVideoMirrored = (self.position == .front)
            }

            self.captureSession.commitConfiguration()
        }
    }

    // MARK: - Helpers

    private func camera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: position
        )
        return session.devices.first
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        onFrame?(pixelBuffer)
    }
}
