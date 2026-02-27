// CameraZoomView.swift
// Pinch-to-zoom + tap +/- buttons for the active workout camera.
// Usage: overlay ZoomGestureOverlay on top of your CameraPreviewView in ActiveWorkoutView.

import SwiftUI
import AVFoundation

// MARK: - ZoomGestureOverlay

struct ZoomGestureOverlay: View {
    @Binding var zoomFactor: CGFloat
    var maxZoom: CGFloat = 5.0
    var minZoom: CGFloat = 1.0
    var accentColor: Color = Color(hex: "00C896")

    @State private var lastZoom: CGFloat = 1.0
    @State private var showIndicator = false
    @State private var hideTask: Task<Void, Never>? = nil

    var body: some View {
        ZStack(alignment: .top) {
            // Full-screen transparent layer that captures pinch gesture
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    MagnificationGesture()
                        .onChanged { scale in
                            let newZoom = (lastZoom * scale).clamped(to: minZoom...maxZoom)
                            zoomFactor = newZoom
                            showIndicatorBriefly()
                        }
                        .onEnded { _ in
                            lastZoom = zoomFactor
                        }
                )

            // Floating indicator — appears on zoom change, auto-hides after 2s
            if showIndicator {
                zoomIndicator
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear { lastZoom = zoomFactor }
    }

    // MARK: - Zoom Indicator HUD

    private var zoomIndicator: some View {
        HStack(spacing: 10) {
            // Zoom out button
            circleButton(icon: "minus") {
                zoomFactor = max(minZoom, zoomFactor - 0.5)
                lastZoom   = zoomFactor
                showIndicatorBriefly()
            }

            VStack(spacing: 4) {
                Text(String(format: "%.1f×", zoomFactor))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.2))
                        Capsule()
                            .fill(accentColor)
                            .frame(width: geo.size.width *
                                   CGFloat((zoomFactor - minZoom) / (maxZoom - minZoom)))
                    }
                }
                .frame(width: 80, height: 4)
            }

            // Zoom in button
            circleButton(icon: "plus") {
                zoomFactor = min(maxZoom, zoomFactor + 0.5)
                lastZoom   = zoomFactor
                showIndicatorBriefly()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
    }

    private func circleButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: { withAnimation(.spring(response: 0.2)) { action() } }) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.18))
                .clipShape(Circle())
        }
    }

    private func showIndicatorBriefly() {
        hideTask?.cancel()
        withAnimation(.easeOut(duration: 0.15)) { showIndicator = true }
        hideTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.3)) { showIndicator = false }
            }
        }
    }
}

// MARK: - AVCaptureDevice zoom helper

extension AVCaptureDevice {
    func setZoomSafe(_ factor: CGFloat) {
        let clamped = factor.clamped(to: 1.0...activeFormat.videoMaxZoomFactor)
        guard abs(videoZoomFactor - clamped) > 0.01 else { return }
        do {
            try lockForConfiguration()
            videoZoomFactor = clamped
            unlockForConfiguration()
        } catch {
            print("Zoom config error: \(error)")
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

/*
 ──────────────────────────────────────────────────────────────
 INTEGRATION — paste into ActiveWorkoutView.swift
 ──────────────────────────────────────────────────────────────

 1. Add state:
     @State private var zoomFactor: CGFloat = 1.0

 2. In your ZStack, overlay on CameraPreviewView:

     ZStack {
         CameraPreviewView(session: cameraManager.session)
             .ignoresSafeArea()

         // ← add this:
         ZoomGestureOverlay(
             zoomFactor: $zoomFactor,
             accentColor: Color(hex: "00C896")   // change per category
         )
         .ignoresSafeArea()

         // ... rest of your skeleton overlay, rep counter, etc.
     }
     .onChange(of: zoomFactor) { _, newValue in
         cameraManager.captureDevice?.setZoomSafe(newValue)
     }

 3. In CameraManager, expose the capture device:
     var captureDevice: AVCaptureDevice?

    Then assign it when you configure the session:
     captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                             for: .video, position: .front)
 ──────────────────────────────────────────────────────────────
*/
