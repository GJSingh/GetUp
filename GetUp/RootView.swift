// Views/RootView.swift
// Navigation root — tabs for Workout, History, and Settings.

import SwiftUI

struct RootView: View {
    @StateObject private var workoutVM = WorkoutViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            WorkoutRootView()
                .environmentObject(workoutVM)
                .tabItem {
                    Label("Workout", systemImage: "figure.strengthtraining.traditional")
                }
                .tag(0)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.bar.fill")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(Color(hex: "00C896"))
        .background(Color(hex: "0A0A0F"))
    }
}

// MARK: - Workout Root (handles setup vs active workout)

struct WorkoutRootView: View {
    @EnvironmentObject var vm: WorkoutViewModel

    var body: some View {
        switch vm.state {
        case .setup:
            ExerciseSetupView()
        case .countdown:
            CountdownView()
        case .active, .resting:
            ActiveWorkoutView()
        case .complete:
            WorkoutCompleteView()
        }
    }
}
