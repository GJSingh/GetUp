// Views/WorkoutCompleteView.swift
// Shown after all sets are done. Displays session summary and form score.

import SwiftUI

struct WorkoutCompleteView: View {
    @EnvironmentObject var vm: WorkoutViewModel

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            // Subtle radial glow
            RadialGradient(
                colors: [Color(hex: "00C896").opacity(0.08), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Badge
                ZStack {
                    Circle()
                        .fill(Color(hex: "00C896").opacity(0.1))
                        .frame(width: 120, height: 120)
                    Circle()
                        .stroke(Color(hex: "00C896").opacity(0.3), lineWidth: 1.5)
                        .frame(width: 120, height: 120)
                    Text("🏆")
                        .font(.system(size: 56))
                }

                VStack(spacing: 8) {
                    Text("Workout Complete!")
                        .font(.custom("Georgia-Bold", size: 28))
                        .foregroundColor(.white)
                    Text("\(vm.selectedExercise.name) · \(vm.targetSets) sets of \(vm.targetReps)")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "666680"))
                }

                // Stats row
                HStack(spacing: 16) {
                    StatCard(value: "\(vm.targetSets)", label: "Sets", icon: "square.stack.3d.up")
                    StatCard(value: "\(vm.targetSets * vm.targetReps)", label: "Total Reps", icon: "arrow.clockwise")
                    StatCard(value: "\(Int(vm.sessionFormScore * 100))%", label: "Avg Form", icon: "star.fill")
                }
                .padding(.horizontal, 24)

                // Form quality message
                formMessage
                    .padding(.horizontal, 24)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        vm.selectedExercise = vm.selectedExercise  // keep exercise
                        vm.resetToSetup()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Do it again")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(hex: "00C896"))
                        .cornerRadius(14)
                    }

                    Button(action: { vm.resetToSetup() }) {
                        Text("Choose different exercise")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "5BC8FF"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(hex: "5BC8FF").opacity(0.1))
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    var formMessage: some View {
        let score = vm.sessionFormScore
        let (emoji, title, detail): (String, String, String) = {
            switch score {
            case 0.85...: return ("⭐️", "Excellent form!", "Keep up this quality — your joints will thank you.")
            case 0.7..<0.85: return ("✅", "Good form overall", "A few small adjustments can make you even better.")
            case 0.5..<0.7: return ("⚠️", "Form needs work", "Focus on the feedback cues during your next session.")
            default: return ("🔴", "Significant form issues", "Consider reducing weight and focusing on technique first.")
            }
        }()

        return HStack(spacing: 14) {
            Text(emoji).font(.system(size: 28))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8888AA"))
            }
            Spacer()
        }
        .padding(16)
        .background(Color(hex: "14141E"))
        .cornerRadius(14)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "00C896"))
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(hex: "555570"))
                .kerning(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(hex: "14141E"))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "1E1E2E"), lineWidth: 1))
    }
}
