// Views/RootView.swift
// Root navigation container.
// Shows OnboardingView on first launch, then the main TabView.
// Owns WorkoutViewModel as a StateObject and injects it into the view hierarchy.

import SwiftUI

struct RootView: View {

    // Persisted across launches — flipped to true when onboarding finishes
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    // Single source of truth for the workout session — shared across all tabs
    @StateObject private var workoutVM = WorkoutViewModel()

    @State private var selectedTab: Tab = .workout

    enum Tab { case workout, history, settings }

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                    .transition(.opacity)
            } else {
                mainTabs
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: hasSeenOnboarding)
    }

    // MARK: - Main Tabs

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            ExerciseSetupView()
                .tabItem {
                    Label("Workout", systemImage: "figure.strengthtraining.traditional")
                }
                .tag(Tab.workout)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.bar.fill")
                }
                .tag(Tab.history)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(Color(hex: "00C896"))
        .environmentObject(workoutVM)   // injects vm into ExerciseSetupView, ActiveWorkoutView, and all descendants
    }
}
