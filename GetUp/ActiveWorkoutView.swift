// Views/ActiveWorkoutView.swift
// The main workout screen: camera feed on top with skeleton overlay,
// feedback and rep counter panel below.

import SwiftUI

struct ActiveWorkoutView: View {
    @EnvironmentObject var vm: WorkoutViewModel
    @State private var showEndAlert = false

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // Camera + Skeleton (top 55% of screen)
                GeometryReader { geo in
                    ZStack(alignment: .topTrailing) {
                        // Camera feed
                        CameraPreviewView(session: vm.camera.captureSession)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(feedbackBorderColor, lineWidth: 2)
                                    .animation(.easeInOut(duration: 0.4), value: vm.currentFeedback.color)
                            )

                        // Skeleton overlay
                        SkeletonOverlayView(
                            poseResult: vm.poseResult,
                            size: geo.size
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                        // Camera flip button
                        Button(action: { vm.camera.flipCamera() }) {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                        }
                        .padding(12)

                        // No person detected warning
                        if vm.poseResult.isEmpty && vm.state == .active {
                            VStack {
                                Spacer()
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(Color(hex: "FFB740"))
                                        .font(.system(size: 12))
                                    Text("Move into frame")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color(hex: "FFB740"))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .cornerRadius(20)
                                .padding(.bottom, 12)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Bottom panel
                if vm.state == .resting {
                    restPanel
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                } else {
                    feedbackPanel
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                }
            }
        }
        .alert("End workout?", isPresented: $showEndAlert) {
            Button("End & Save", role: .destructive) { vm.endWorkout() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your progress so far will be saved.")
        }
    }

    // MARK: - Top Bar

    var topBar: some View {
        HStack {
            // Exercise name
            HStack(spacing: 8) {
                Text(vm.selectedExercise.emoji)
                    .font(.system(size: 20))
                Text(vm.selectedExercise.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }

            Spacer()

            // Set indicator
            HStack(spacing: 4) {
                ForEach(1...max(1, vm.targetSets), id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(i < vm.repCounter.currentSet
                              ? Color(hex: "00C896")
                              : i == vm.repCounter.currentSet
                                ? Color(hex: "00C896").opacity(0.5)
                                : Color(hex: "1E1E2E"))
                        .frame(width: 20, height: 6)
                }
            }

            // End button
            Button(action: { showEndAlert = true }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "666680"))
                    .padding(8)
                    .background(Color(hex: "14141E"))
                    .cornerRadius(8)
            }
            .padding(.leading, 12)
        }
    }

    // MARK: - Feedback Panel

    var feedbackPanel: some View {
        VStack(spacing: 12) {
            // Rep counter row
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("REPS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "444460"))
                        .kerning(2)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(vm.repCounter.currentReps)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3), value: vm.repCounter.currentReps)
                        Text("/ \(vm.targetReps)")
                            .font(.system(size: 22, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "444460"))
                    }
                }

                Spacer()

                // Form score ring
                FormScoreRing(score: vm.currentSetFormScore)
            }

            // Rep dots
            RepDotsView(
                current: vm.repCounter.currentReps,
                target: vm.targetReps
            )

            // Feedback message
            FeedbackBanner(feedback: vm.currentFeedback)
        }
        .padding(18)
        .background(Color(hex: "14141E"))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "1E1E2E"), lineWidth: 1))
    }

    // MARK: - Rest Panel

    var restPanel: some View {
        VStack(spacing: 16) {
            Text("REST")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "5BC8FF"))
                .kerning(3)

            Text("\(vm.repCounter.restSecondsRemaining)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText(countsDown: true))
                .animation(.spring(response: 0.3), value: vm.repCounter.restSecondsRemaining)

            Text("Set \(vm.repCounter.currentSet - 1) complete — next set starts soon")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "666680"))

            Button(action: { vm.resumeAfterRest() }) {
                Text("Skip Rest")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "5BC8FF"))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color(hex: "5BC8FF").opacity(0.12))
                    .cornerRadius(20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(hex: "14141E"))
        .cornerRadius(20)
    }

    // MARK: - Helpers

    var feedbackBorderColor: Color {
        Color(hex: vm.currentFeedback.color).opacity(0.5)
    }
}

// MARK: - Form Score Ring

struct FormScoreRing: View {
    let score: Double  // 0.0 – 1.0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "1E1E2E"), lineWidth: 5)
                .frame(width: 64, height: 64)

            Circle()
                .trim(from: 0, to: score)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 64, height: 64)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.5), value: score)

            VStack(spacing: 0) {
                Text("\(Int(score * 100))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("FORM")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(Color(hex: "444460"))
                    .kerning(0.5)
            }
        }
    }

    var ringColor: Color {
        switch score {
        case 0.8...: return Color(hex: "00C896")
        case 0.6..<0.8: return Color(hex: "5BC8FF")
        case 0.4..<0.6: return Color(hex: "FFB740")
        default: return Color(hex: "FF5A5A")
        }
    }
}

// MARK: - Rep Dots

struct RepDotsView: View {
    let current: Int
    let target: Int

    var body: some View {
        let cols = min(target, 15)
        HStack(spacing: 5) {
            ForEach(0..<cols, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(i < current ? Color(hex: "00C896") : Color(hex: "1E1E2E"))
                    .frame(height: 8)
                    .animation(.spring(response: 0.3).delay(Double(i) * 0.03), value: current)
            }
            if target > 15 {
                Text("+\(target - 15)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "444460"))
            }
        }
    }
}

// MARK: - Feedback Banner

struct FeedbackBanner: View {
    let feedback: PostureFeedback

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: feedback.color))
                .frame(width: 10, height: 10)
                .shadow(color: Color(hex: feedback.color).opacity(0.8), radius: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(feedback.message)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(feedback.detail)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8888AA"))
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(hex: feedback.color).opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: feedback.color).opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.3), value: feedback.message)
    }
}
