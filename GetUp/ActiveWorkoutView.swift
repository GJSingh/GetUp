// Views/ActiveWorkoutView.swift
// Live workout screen: camera feed, skeleton overlay, rep counter, posture feedback.
// Features: pinch-to-zoom, green form glow, portrait+landscape layout, live rest countdown.

import SwiftUI
import Vision
import AVFoundation
import Combine

struct ActiveWorkoutView: View {
    @EnvironmentObject var vm: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showEndConfirmation = false
    @State private var committedZoom: CGFloat = 1.0

    // Orientation: tracked separately so layout only switches AFTER rotation settles.
    // GeometryReader alone switches layout mid-animation causing the stutter/hang.
    @State private var isLandscape = false

    // Form glow: builds up over consecutive excellent/good frames
    @State private var excellentStreak  = 0
    @State private var glowActive       = false
    private let glowThreshold = 4   // frames before glow lights up

    // Rep flash: brief green pulse each time a rep is counted
    @State private var repFlashOpacity: Double = 0

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            GeometryReader { geo in
                if isLandscape {
                    // ── Landscape: 60/40 side-by-side ──────────────────────
                    HStack(spacing: 0) {
                        cameraPanel(size: CGSize(width: geo.size.width * 0.6,
                                                height: geo.size.height))
                        feedbackPanel
                            .frame(width: geo.size.width * 0.4)
                    }
                    .animation(nil, value: isLandscape)   // never animate structural layout
                } else {
                    // ── Portrait: camera top 65%, stats bottom 35% ─────────
                    VStack(spacing: 0) {
                        cameraPanel(size: CGSize(width: geo.size.width,
                                                height: geo.size.height * 0.65))
                        feedbackPanel
                    }
                    .animation(nil, value: isLandscape)
                }
            }

            // ── Form glow — luminous green border with real bloom ─────────
            // Uses layered shadows to create a visible glow; opacity animates in/out.
            Rectangle()
                .fill(Color.clear)
                .overlay(
                    Rectangle()
                        .stroke(Color(hex: "00C896"), lineWidth: 4)
                        .blur(radius: 2)
                        .shadow(color: Color(hex: "00C896").opacity(0.9), radius: 10)
                        .shadow(color: Color(hex: "00C896").opacity(0.6), radius: 20)
                        .shadow(color: Color(hex: "00C896").opacity(0.3), radius: 40)
                )
                .opacity(glowActive ? 1 : 0)
                .animation(.easeInOut(duration: 0.45), value: glowActive)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // ── Rep flash — quick green wash when a rep is counted ────────────
            Color(hex: "00C896")
                .opacity(repFlashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // ── Rest Overlay ───────────────────────────────────────────────
            if vm.state == .resting {
                RestOverlay(secondsRemaining: vm.repCounter.restSecondsRemaining) {
                    vm.resumeAfterRest()
                }
            }

            // ── Completion Overlay ─────────────────────────────────────────
            if vm.state == .complete {
                WorkoutCompleteOverlay {
                    vm.resetToSetup()
                    dismiss()
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: vm.currentFeedback) { _, feedback in
            updateGlow(feedback: feedback)
        }
        .onChange(of: vm.repCounter.currentReps) { _, _ in
            flashRep()
        }
        .onAppear { AppOrientationHelper.unlock() }
        .onDisappear {
            AppOrientationHelper.lockPortrait()
            vm.camera.stop()
            AudioManager.shared.stop()
        }
        // onGeometryChange fires AFTER layout completes with settled geometry —
        // more reliable than UIDevice.orientationDidChangeNotification on iOS 26.
        .onGeometryChange(for: Bool.self) { proxy in
            proxy.size.width > proxy.size.height
        } action: { newIsLandscape in
            guard newIsLandscape != isLandscape else { return }
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) { isLandscape = newIsLandscape }
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

    // MARK: - Glow + Flash Logic

    private func updateGlow(feedback: PostureFeedback) {
        switch feedback.quality {
        case .excellent:
            excellentStreak += 2   // excellent builds streak quickly
        case .good:
            excellentStreak += 1   // good also builds, just slower
        case .needsWork:
            excellentStreak  = max(0, excellentStreak - 1)
        case .incorrect:
            excellentStreak  = 0
        }
        let shouldGlow = excellentStreak >= glowThreshold
        if shouldGlow != glowActive {
            withAnimation(.easeInOut(duration: 0.45)) { glowActive = shouldGlow }
        }
    }

    private func flashRep() {
        // Quick green pulse: fade in to 15% opacity, then fade out
        withAnimation(.easeOut(duration: 0.08)) { repFlashOpacity = 0.15 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeIn(duration: 0.25)) { repFlashOpacity = 0 }
        }
    }

    // MARK: - Camera Panel

    private func cameraPanel(size: CGSize) -> some View {
        ZStack {
            // Camera preview — CameraPreviewView(session:) is declared in CameraPreviewView.swift
            CameraPreviewView(session: vm.camera.captureSession)
                .frame(width: size.width, height: size.height)
                .clipped()

            // Skeleton overlay
            if !vm.poseResult.isEmpty {
                SkeletonCanvas(poseResult: vm.poseResult, feedback: vm.currentFeedback)
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

            // Pinch-to-zoom
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    MagnificationGesture()
                        .onChanged { scale in
                            vm.camera.setZoom(committedZoom * scale)
                        }
                        .onEnded { _ in
                            committedZoom = vm.camera.zoomFactor
                        }
                )

            // Zoom HUD
            ZoomHUD(camera: vm.camera, committedZoom: $committedZoom)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 56)

            // Top controls
            HStack {
                Button { showEndConfirmation = true } label: {
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

            Divider().background(Color(hex: "1E1E2E")).padding(.vertical, 10)

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

            RepProgressDots(current: vm.repCounter.currentReps, target: vm.targetReps)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

            Divider().background(Color(hex: "1E1E2E"))

            PostureFeedbackCard(feedback: vm.currentFeedback)
                .padding(16)

            Spacer()
        }
        .background(Color(hex: "0D0D17"))
    }
}

// MARK: - Skeleton Canvas

private struct SkeletonCanvas: View {
    let poseResult: PoseDetectionResult
    let feedback: PostureFeedback

    private var jointColor: Color {
        Color(hex: feedback.color)
    }

    var body: some View {
        Canvas { ctx, size in
            for bone in SkeletonModel.bones {
                guard let a = poseResult.joint(bone.from),
                      let b = poseResult.joint(bone.to) else { continue }
                var path = Path()
                path.move(to:    visionPt(a, size))
                path.addLine(to: visionPt(b, size))
                ctx.stroke(path, with: .color(.white.opacity(0.55)), lineWidth: 2.5)
            }
            for (_, joint) in poseResult.joints {
                guard joint.confidence >= 0.3 else { continue }
                let pt = visionPt(joint, size)
                let r: CGFloat = 5
                ctx.fill(Circle().path(in: CGRect(x: pt.x-r, y: pt.y-r, width: r*2, height: r*2)),
                         with: .color(jointColor))
            }
        }
    }

    private func visionPt(_ p: VNRecognizedPoint, _ size: CGSize) -> CGPoint {
        CGPoint(x: p.x * size.width, y: (1 - p.y) * size.height)
    }
}

// MARK: - Posture Feedback Card

private struct PostureFeedbackCard: View {
    let feedback: PostureFeedback
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName)
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
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.35), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.3), value: feedback.message)
    }

    private var color: Color { Color(hex: feedback.color) }

    private var iconName: String {
        switch feedback.quality {
        case .excellent: return "checkmark.circle.fill"
        case .good:      return "checkmark.circle"
        case .needsWork: return "exclamationmark.triangle.fill"
        case .incorrect: return "xmark.circle.fill"
        }
    }
}

// MARK: - Rep Progress Dots

private struct RepProgressDots: View {
    let current: Int
    let target: Int
    private var display: Int { min(target, 15) }
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 4),
                           count: min(display, 10)),
            spacing: 4
        ) {
            ForEach(0..<display, id: \.self) { i in
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
    let secondsRemaining: Int
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.80).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Rest")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))

                // Live countdown
                Text("\(secondsRemaining)s")
                    .font(.system(size: 80, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.easeInOut(duration: 0.4), value: secondsRemaining)
                    .monospacedDigit()

                Text("Next set starts automatically")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.4))

                Button("Skip Rest") { onSkip() }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "00C896"))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(Color(hex: "00C896").opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color(hex: "00C896").opacity(0.3), lineWidth: 1))
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
                Button("Done") { onDone() }
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
            Image(systemName: "camera.slash").font(.system(size: 44)).foregroundStyle(.white)
            Text("Camera Access Required").font(.system(size: 18, weight: .semibold)).foregroundStyle(.white)
            Text("Go to Settings > GetUp > Camera to enable.")
                .font(.system(size: 14)).foregroundStyle(.white.opacity(0.7)).multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .padding(.horizontal, 24).padding(.vertical, 12)
            .background(.white.opacity(0.15)).foregroundStyle(.white).clipShape(Capsule())
        }
        .padding(28).background(.black.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 20)).padding(28)
    }
}

// MARK: - Zoom HUD

struct ZoomHUD: View {
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
                            .font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                            .frame(width: 30, height: 30).background(.white.opacity(0.18)).clipShape(Circle())
                    }
                    VStack(spacing: 3) {
                        Text(String(format: "%.1f×", camera.zoomFactor))
                            .font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(.white)
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(.white.opacity(0.25))
                                Capsule().fill(Color(hex: "00C896"))
                                    .frame(width: g.size.width * min(1, (camera.zoomFactor - 1.0) / 7.0))
                            }
                        }.frame(width: 70, height: 3)
                    }
                    Button(action: { camera.zoomIn(); committedZoom = camera.zoomFactor; bump() }) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                            .frame(width: 30, height: 30).background(.white.opacity(0.18)).clipShape(Circle())
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(.ultraThinMaterial).clipShape(Capsule())
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
