// Views/ExerciseSetupView.swift
// Exercise picker with Strength / Yoga category tabs.

import SwiftUI

struct ExerciseSetupView: View {
    @EnvironmentObject var vm: WorkoutViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var selectedCategory: ExerciseCategory = .strength

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.top, 20)
                        .padding(.bottom, 24)

                    categoryPicker
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                    exerciseGrid
                        .padding(.horizontal, 20)

                    configSection
                        .padding(.horizontal, 20)
                        .padding(.top, 28)

                    cameraHint
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

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
            Text("GetUp")
                .font(.custom("Georgia-Bold", size: 32))
                .foregroundColor(.white)
            Text("Real-time posture monitoring")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "666680"))
        }
    }

    // MARK: - Category Picker

    var categoryPicker: some View {
        HStack(spacing: 8) {
            ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedCategory = cat
                        // Auto-select first exercise in category
                        if let first = ExerciseLibrary.exercises(for: cat).first {
                            vm.selectedExercise = first
                            vm.targetSets = first.defaultSets
                            vm.targetReps = first.defaultReps
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(cat.emoji)
                            .font(.system(size: 14))
                        Text(cat.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedCategory == cat ? .black : Color(hex: "888899"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selectedCategory == cat
                            ? (cat == .yoga ? Color(hex: "B57BFF") : Color(hex: "00C896"))
                            : Color(hex: "14141E")
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                selectedCategory == cat ? Color.clear : Color(hex: "1E1E2E"),
                                lineWidth: 1
                            )
                    )
                }
            }
        }
    }

    // MARK: - Exercise Grid

    var exerciseGrid: some View {
        let exercises = ExerciseLibrary.exercises(for: selectedCategory)
        let accentColor = selectedCategory == .yoga ? "B57BFF" : "00C896"

        return VStack(alignment: .leading, spacing: 14) {
            Text("EXERCISE")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "444460"))
                .kerning(2)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(exercises) { exercise in
                    ExerciseCard(
                        exercise: exercise,
                        isSelected: vm.selectedExercise.id == exercise.id,
                        accentColor: accentColor
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
        let isYoga = vm.selectedExercise.isHoldPose
        let repLabel = isYoga ? "Hold (s)" : "Reps"
        let repIcon  = isYoga ? "timer" : "arrow.clockwise"

        return VStack(spacing: 12) {
            Text("CONFIGURATION")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "444460"))
                .kerning(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                ConfigStepper(label: "Sets",    value: $vm.targetSets, range: 1...10, icon: "square.stack.3d.up")
                ConfigStepper(label: repLabel,  value: $vm.targetReps, range: 1...120, step: isYoga ? 5 : 1, icon: repIcon)
                ConfigStepper(label: "Rest (s)", value: $vm.restDuration, range: 10...180, step: 10, icon: "bed.double")
            }

            if isYoga {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "B57BFF"))
                    Text("For yoga poses, 'Reps' is how many seconds to hold the pose each set.")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "666680"))
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Camera Hint

    var cameraHint: some View {
        let isYoga = vm.selectedExercise.isHoldPose
        let iconColor = isYoga ? "B57BFF" : "5BC8FF"
        let bgColor   = isYoga ? "B57BFF" : "5BC8FF"

        return HStack(spacing: 12) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: iconColor))
            Text(vm.selectedExercise.cameraSetup)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "8888AA"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(hex: bgColor).opacity(0.07))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: bgColor).opacity(0.2), lineWidth: 1))
        .cornerRadius(12)
    }

    // MARK: - Start Button

    var startButton: some View {
        let isYoga    = vm.selectedExercise.isHoldPose
        let gradient  = isYoga
            ? [Color(hex: "B57BFF"), Color(hex: "8A4FD8")]
            : [Color(hex: "00C896"), Color(hex: "00A876")]
        let glowColor = isYoga ? Color(hex: "B57BFF") : Color(hex: "00C896")

        return Button(action: {
            vm.modelContext = modelContext
            vm.startCountdown()
        }) {
            HStack(spacing: 10) {
                Image(systemName: isYoga ? "figure.mind.and.body" : "play.fill")
                    .font(.system(size: 16, weight: .bold))
                Text(isYoga ? "START PRACTICE" : "START WORKOUT")
                    .font(.system(size: 16, weight: .bold))
                    .kerning(1)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
            .cornerRadius(16)
            .shadow(color: glowColor.opacity(0.4), radius: 20, y: 8)
        }
    }
}

// MARK: - Exercise Card (updated with accentColor param)

struct ExerciseCard: View {
    let exercise: ExerciseDefinition
    let isSelected: Bool
    let accentColor: String
    let action: () -> Void

    init(exercise: ExerciseDefinition, isSelected: Bool, accentColor: String = "00C896", action: @escaping () -> Void) {
        self.exercise = exercise
        self.isSelected = isSelected
        self.accentColor = accentColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(exercise.emoji)
                        .font(.system(size: 26))
                    if exercise.isHoldPose {
                        Text("HOLD")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Color(hex: accentColor))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(hex: accentColor).opacity(0.15))
                            .cornerRadius(4)
                    }
                }
                Text(exercise.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? .white : Color(hex: "AAAACC"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                HStack(spacing: 4) {
                    ForEach(exercise.muscleGroups.prefix(2), id: \.self) { muscle in
                        Text(muscle)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(isSelected ? Color(hex: accentColor) : Color(hex: "555570"))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background((isSelected ? Color(hex: accentColor) : Color(hex: "555570")).opacity(0.15))
                            .cornerRadius(4)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(isSelected ? Color(hex: accentColor).opacity(0.12) : Color(hex: "14141E"))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color(hex: accentColor).opacity(0.6) : Color(hex: "1E1E2E"), lineWidth: isSelected ? 1.5 : 1)
            )
            .cornerRadius(14)
        }
    }
}

// MARK: - Config Stepper (unchanged — keep your existing one)

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
