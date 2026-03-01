// Views/ActiveWorkoutView.swift
// Live workout screen: camera feed, skeleton overlay, rep counter, posture feedback.

import SwiftUI
import Vision
import AVFoundation

struct ActiveWorkoutView: View {
    @EnvironmentObject var vm: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showEndConfirmation = false
    // Pinch zoom: capture the zoom at gesture START so cumulative scale multiplies correctly.
    @State private var committedZoom: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            GeometryReader { geo in
                if geo.size.width > geo.size.height {
                    HStack(spacing: 0) {
                        cameraPanel(size: CGSize(width: geo.size.width * 0.6, height: geo.size.height))
                        feedbackPanel
                            .frame(width: geo.size.width * 0.4)
                    }
                } else {
                    VStack(spacing: 0) {
                        cameraPanel(size: CGSize(width: geo.size.width, height: geo.size.height * 0.65))
                        feedbackPanel
                    }
                }
            }

            // ── Rest Overlay ─────────────────────────────────────────────
            if vm.state == .resting {
                RestOverlay {
                    vm.resumeAfterRest()
                }
            }

            // ── Completion Overlay ────────────────────────────────────────
            if vm.state == .complete {
                WorkoutCompleteOverlay {
                    vm.resetToSetup()
                    dismiss()
                }
            }
        }
        .navigationBarHidden(true)
        .onDisappear {
            vm.camera.stop()
            AudioManager.shared.stop()
        }
        .alert("End Workout?", isPresented: $showEndConfirmation) {
            Button("End & Save", role: .destructive) {
                vm.endWorkout()
                dismiss()
            }
            Button("Continue", role: .cancel) {}
        } message: {
            Text("Your progress will be saved.")
        }
    }

    // MARK: - Camera Panel

    private func cameraPanel(size: CGSize) -> some View {
        ZStack {
            // Camera preview
            CameraPreviewView(session: vm.camera.captureSession)
                .frame(width: size.width, height: size.height)
                .clipped()

            // Skeleton overlay — draws bones from poseResult using SkeletonModel
            if !vm.poseResult.isEmpty {
                SkeletonCanvas(poseResult: vm.poseResult,
                               feedback: vm.currentFeedback)
                    .frame(width: size.width, height: size.height)
                    .allowsHitTesting(false)
            }

            // No-person hint
            if vm.poseResult.isEmpty && vm.camera.isRunning {
                VStack(spacing: 8) {
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.8))
                    Text("Stand in frame")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(12)
                .background(.black.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Camera not authorised
            if !vm.camera.isCameraAuthorised {
                CameraPermissionDeniedView()
            }

            // ── Pinch-to-zoom ─────────────────────────────────────────────
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    MagnificationGesture()
                        .onChanged { scale in
                            // committedZoom = zoom at gesture start
                            // scale is cumulative from 1.0 — multiply against start value
                            vm.camera.setZoom(committedZoom * scale)
                        }
                        .onEnded { _ in
                            committedZoom = vm.camera.zoomFactor
                        }
                )

            // ── Zoom HUD ──────────────────────────────────────────────────
            ZoomHUD(camera: vm.camera, committedZoom: $committedZoom)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 56)

            // ── Top controls ──────────────────────────────────────────────
            HStack {
                Button {
                    showEndConfirmation = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.black.opacity(0.5))
                        .clipShape(Circle())
                }

                Spacer()

                Button {
                    vm.camera.flipCamera()
                    committedZoom = 1.0
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.black.opacity(0.5))
                        .clipShape(Circle())
                }
            }
            .padding(16)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(width: size.width, height: size.height)
        .onAppear { committedZoom = vm.camera.zoomFactor }
    }

    // MARK: - Feedback Panel

    private var feedbackPanel: some View {
        VStack(spacing: 0) {
            // Exercise + set
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.selectedExercise.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Set \(vm.repCounter.currentSet) of \(vm.targetSets)")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "666680"))
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Divider()
                .background(Color(hex: "1E1E2E"))
                .padding(.vertical, 10)

            // Rep counter
            VStack(spacing: 4) {
                Text("\(vm.repCounter.currentReps)")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(countsDown: false))
                    .animation(.spring(response: 0.3), value: vm.repCounter.currentReps)

                Text("of \(vm.targetReps) reps")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "666680"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)

            // Rep progress dots
            RepProgressDots(
                current: vm.repCounter.currentReps,
                target: vm.targetReps
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            Divider()
                .background(Color(hex: "1E1E2E"))

            // Posture feedback card
            PostureFeedbackCard(feedback: vm.currentFeedback)
                .padding(16)

            Spacer()
        }
        .background(Color(hex: "0D0D17"))
    }
}

// MARK: - Skeleton Canvas
// Draws skeleton bones from PoseDetectionResult using SkeletonModel.
// Vision coords: origin bottom-left, 0–1 normalized.
// Canvas coords: origin top-left.

private struct SkeletonCanvas: View {
    let poseResult: PoseDetectionResult
    let feedback: PostureFeedback

    private var boneColor: Color {
        Color.white.opacity(0.55)
    }

    private var jointColor: Color {
        switch feedback.quality {
        case .excellent: return Color(hex: "00C896")
        case .good:      return Color(hex: "5BC8FF")
        case .needsWork: return Color(hex: "FFB347")
        case .incorrect: return Color(hex: "FF5F5F")
        }
    }

    var body: some View {
        Canvas { ctx, size in
            // Draw bones
            for bone in SkeletonModel.bones {
                guard
                    let a = poseResult.joint(bone.from),
                    let b = poseResult.joint(bone.to)
                else { continue }
                let ptA = visionToCanvas(a, in: size)
                let ptB = visionToCanvas(b, in: size)
                var path = Path()
                path.move(to: ptA)
                path.addLine(to: ptB)
                ctx.stroke(path, with: .color(boneColor), lineWidth: 2.5)
            }
            // Draw joint circles
            for (_, joint) in poseResult.joints {
                guard joint.confidence >= 0.3 else { continue }
                let pt = visionToCanvas(joint, in: size)
                let r: CGFloat = 5
                ctx.fill(
                    Circle().path(in: CGRect(x: pt.x - r, y: pt.y - r, width: r*2, height: r*2)),
                    with: .color(jointColor)
                )
            }
        }
    }

    private func visionToCanvas(_ point: VNRecognizedPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: point.x * size.width, y: (1 - point.y) * size.height)
    }
}

// MARK: - Posture Feedback Card

private struct PostureFeedbackCard: View {
    let feedback: PostureFeedback

    private var color: Color {
        switch feedback.quality {
        case .excellent: return Color(hex: "00C896")
        case .good:      return Color(hex: "5BC8FF")
        case .needsWork: return Color(hex: "FFB347")
        case .incorrect: return Color(hex: "FF5F5F")
        }
    }

    private var icon: String {
        switch feedback.quality {
        case .excellent: return "checkmark.circle.fill"
        case .good:      return "checkmark.circle"
        case .needsWork: return "exclamationmark.triangle.fill"
        case .incorrect: return "xmark.circle.fill"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(feedback.message)
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(14)
        .background(color.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.3), value: feedback.message)
    }
}

// MARK: - Rep Progress Dots

private struct RepProgressDots: View {
    let current: Int
    let target: Int

    private var displayTarget: Int { min(target, 15) }

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: min(displayTarget, 10)),
            spacing: 4
        ) {
            ForEach(0..<displayTarget, id: \.self) { i in
                Circle()
                    .fill(i < current ? Color(hex: "00C896") : Color(hex: "1E1E2E"))
                    .frame(height: 10)
                    .animation(.spring(response: 0.3).delay(Double(i) * 0.02), value: current)
            }
        }
    }
}

// MARK: - Rest Overlay

private struct RestOverlay: View {
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.78).ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Rest")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("Take a breath")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.6))

                Button("Skip Rest") {
                    onSkip()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: "00C896"))
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(.white.opacity(0.08))
                .clipShape(Capsule())
            }
        }
        .transition(.opacity)
    }
}

// MARK: - Workout Complete Overlay

private struct WorkoutCompleteOverlay: View {
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.yellow)

                Text("Workout Complete!")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)

                Text("Great work. Results saved.")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.7))

                Button("Done") {
                    onDone()
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 200)
                .padding(.vertical, 14)
                .background(Color(hex: "00C896"))
                .clipShape(Capsule())
            }
            .padding(32)
        }
    }
}

// MARK: - Camera Permission Denied

private struct CameraPermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.slash")
                .font(.system(size: 44))
                .foregroundStyle(.white)
            Text("Camera Access Required")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
            Text("Go to Settings > GetUp > Camera to enable.")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .padding(.horizontal, 24).padding(.vertical, 12)
            .background(.white.opacity(0.15))
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
        .padding(28)
        .background(.black.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(28)
    }
}

// MARK: - Zoom HUD

private struct ZoomHUD: View {
    @ObservedObject var camera: CameraManager
    @Binding var committedZoom: CGFloat

    @State private var showHUD  = false
    @State private var hideTask: Task<Void, Never>? = nil

    var body: some View {
        Group {
            if showHUD {
                HStack(spacing: 10) {
                    Button(action: { camera.zoomOut(); committedZoom = camera.zoomFactor; bump() }) {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(.white.opacity(0.18))
                            .clipShape(Circle())
                    }

                    VStack(spacing: 3) {
                        Text(String(format: "%.1f×", camera.zoomFactor))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(.white.opacity(0.25))
                                Capsule().fill(Color(hex: "00C896"))
                                    .frame(width: g.size.width * min(1, (camera.zoomFactor - 1.0) / 7.0))
                            }
                        }
                        .frame(width: 70, height: 3)
                    }

                    Button(action: { camera.zoomIn(); committedZoom = camera.zoomFactor; bump() }) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(.white.opacity(0.18))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showHUD)
        .onChange(of: camera.zoomFactor) { _, _ in bump() }
        .padding(.horizontal, 16)
    }

    private func bump() {
        hideTask?.cancel()
        showHUD = true
        hideTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { showHUD = false }
        }
    }
}
