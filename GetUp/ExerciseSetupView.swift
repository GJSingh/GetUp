// Views/ExerciseSetupView.swift
// The first screen — choose an exercise, configure sets and reps, then start.

import SwiftUI

struct ExerciseSetupView: View {
    @EnvironmentObject var vm: WorkoutViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            // Background
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.top, 20)
                        .padding(.bottom, 32)

                    // Exercise Grid
                    exerciseGrid
                        .padding(.horizontal, 20)

                    // Configuration
                    configSection
                        .padding(.horizontal, 20)
                        .padding(.top, 28)

                    // Camera Setup Hint
                    cameraHint
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    // Start Button
                    startButton
                        .padding(.horizontal, 20)
                        .padding(.top, 28)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            vm.modelContext = modelContext
        }
    }

    // MARK: - Header

    var headerSection: some View {
        VStack(spacing: 6) {
            Text("FitCoach AI")
                .font(.custom("Georgia-Bold", size: 32))
                .foregroundColor(.white)
            Text("Real-time posture monitoring")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "666680"))
        }
    }

    // MARK: - Exercise Grid

    var exerciseGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("EXERCISE")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "444460"))
                .kerning(2)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ExerciseLibrary.all) { exercise in
                    ExerciseCard(
                        exercise: exercise,
                        isSelected: vm.selectedExercise.id == exercise.id
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            vm.selectedExercise = exercise
                            vm.targetSets = exercise.defaultSets
                            vm.targetReps = exercise.defaultReps
                        }
                    }
                }
            }
        }
    }

    // MARK: - Configuration

    var configSection: some View {
        VStack(spacing: 12) {
            Text("CONFIGURATION")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "444460"))
                .kerning(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                ConfigStepper(
                    label: "Sets",
                    value: $vm.targetSets,
                    range: 1...10,
                    icon: "square.stack.3d.up"
                )
                ConfigStepper(
                    label: "Reps",
                    value: $vm.targetReps,
                    range: 1...30,
                    icon: "arrow.clockwise"
                )
                ConfigStepper(
                    label: "Rest (s)",
                    value: $vm.restDuration,
                    range: 10...180,
                    step: 10,
                    icon: "timer"
                )
            }
        }
    }

    // MARK: - Camera Hint

    var cameraHint: some View {
        HStack(spacing: 12) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "5BC8FF"))
            Text(vm.selectedExercise.cameraSetup)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "8888AA"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(hex: "5BC8FF").opacity(0.07))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "5BC8FF").opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    // MARK: - Start Button

    var startButton: some View {
        Button(action: {
            vm.modelContext = modelContext
            vm.startCountdown()
        }) {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("START WORKOUT")
                    .font(.system(size: 16, weight: .bold))
                    .kerning(1)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color(hex: "00C896"), Color(hex: "00A876")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color(hex: "00C896").opacity(0.4), radius: 20, y: 8)
        }
    }
}

// MARK: - Exercise Card

struct ExerciseCard: View {
    let exercise: ExerciseDefinition
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(exercise.emoji)
                    .font(.system(size: 28))
                Text(exercise.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? .white : Color(hex: "AAAACC"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                HStack(spacing: 4) {
                    ForEach(exercise.muscleGroups.prefix(2), id: \.self) { muscle in
                        Text(muscle)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(isSelected ? Color(hex: "00C896") : Color(hex: "555570"))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                (isSelected ? Color(hex: "00C896") : Color(hex: "555570")).opacity(0.15)
                            )
                            .cornerRadius(4)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                isSelected
                    ? Color(hex: "00C896").opacity(0.12)
                    : Color(hex: "14141E")
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? Color(hex: "00C896").opacity(0.6) : Color(hex: "1E1E2E"),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .cornerRadius(14)
        }
    }
}

// MARK: - Config Stepper

struct ConfigStepper: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1
    let icon: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "5BC8FF"))

            Text("\(value)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(hex: "555570"))
                .kerning(0.5)

            HStack(spacing: 8) {
                Button(action: { if value - step >= range.lowerBound { value -= step } }) {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "1E1E2E"))
                        .cornerRadius(8)
                }
                Button(action: { if value + step <= range.upperBound { value += step } }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "1E1E2E"))
                        .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(hex: "14141E"))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "1E1E2E"), lineWidth: 1))
    }
}
