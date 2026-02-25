// Views/SettingsView.swift
// App settings: privacy info, preferences, and data management.

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var sessions: [WorkoutSession]
    @Environment(\.modelContext) private var modelContext

    @AppStorage("defaultRestDuration") var defaultRest: Int = 60
    @AppStorage("hapticFeedbackEnabled") var hapticsEnabled: Bool = true
    @AppStorage("voiceFeedbackEnabled") var voiceEnabled: Bool = false
    @AppStorage("useFrontCamera") var useFrontCamera: Bool = false

    @State private var showDeleteAllAlert = false

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    header
                        .padding(.top, 20)
                        .padding(.horizontal, 20)

                    privacySection
                        .padding(.horizontal, 20)

                    preferencesSection
                        .padding(.horizontal, 20)

                    dataSection
                        .padding(.horizontal, 20)

                    aboutSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
        }
        .alert("Delete all data?", isPresented: $showDeleteAllAlert) {
            Button("Delete All", role: .destructive) { deleteAllSessions() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(sessions.count) workout sessions. This cannot be undone.")
        }
    }

    // MARK: - Header

    var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Settings")
                .font(.custom("Georgia-Bold", size: 28))
                .foregroundColor(.white)
            Text("Preferences & privacy")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "555570"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Privacy Section

    var privacySection: some View {
        SettingsSection(title: "Privacy", icon: "lock.shield.fill", iconColor: "00C896") {
            VStack(spacing: 0) {
                PrivacyRow(
                    icon: "camera.slash",
                    title: "Video never stored",
                    detail: "Frames are processed in memory only and immediately discarded."
                )
                Divider().background(Color(hex: "1E1E2E"))
                PrivacyRow(
                    icon: "wifi.slash",
                    title: "Zero network requests",
                    detail: "The app makes no internet connections. No analytics, no tracking."
                )
                Divider().background(Color(hex: "1E1E2E"))
                PrivacyRow(
                    icon: "iphone.badge.play",
                    title: "On-device AI only",
                    detail: "Pose detection uses Apple's Vision framework, running on your device's Neural Engine."
                )
                Divider().background(Color(hex: "1E1E2E"))
                PrivacyRow(
                    icon: "lock.doc",
                    title: "Encrypted local storage",
                    detail: "Workout history is stored in iOS's encrypted app sandbox. Deleted when you uninstall."
                )
            }
            .background(Color(hex: "14141E"))
            .cornerRadius(14)
        }
    }

    // MARK: - Preferences Section

    var preferencesSection: some View {
        SettingsSection(title: "Preferences", icon: "slider.horizontal.3", iconColor: "5BC8FF") {
            VStack(spacing: 0) {
                ToggleRow(title: "Haptic Feedback", subtitle: "Vibrate on each rep", isOn: $hapticsEnabled)
                Divider().background(Color(hex: "1E1E2E"))
                ToggleRow(title: "Voice Cues", subtitle: "Speak posture feedback aloud", isOn: $voiceEnabled)
                Divider().background(Color(hex: "1E1E2E"))

                // Default rest duration
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Default Rest Duration")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        Text("\(defaultRest) seconds between sets")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "666680"))
                    }
                    Spacer()
                    Stepper("", value: $defaultRest, in: 10...180, step: 10)
                        .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(hex: "14141E"))
                .cornerRadius(14)
            }
        }
    }

    // MARK: - Data Section

    var dataSection: some View {
        SettingsSection(title: "Data", icon: "internaldrive", iconColor: "FFB740") {
            VStack(spacing: 0) {
                // Storage info
                HStack {
                    Text("Workout sessions stored")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "AAAACC"))
                    Spacer()
                    Text("\(sessions.count)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(hex: "14141E"))

                Divider().background(Color(hex: "1E1E2E"))

                // Delete all
                Button(action: { showDeleteAllAlert = true }) {
                    HStack {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                        Text("Delete all workout data")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "FF5A5A"))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 14)
                }
                .background(Color(hex: "14141E"))
            }
            .cornerRadius(14)
        }
    }

    // MARK: - About Section

    var aboutSection: some View {
        SettingsSection(title: "About", icon: "info.circle", iconColor: "8888AA") {
            VStack(spacing: 0) {
                InfoRow(label: "Version", value: "1.0.0")
                Divider().background(Color(hex: "1E1E2E"))
                InfoRow(label: "Pose Detection", value: "Apple Vision (on-device)")
                Divider().background(Color(hex: "1E1E2E"))
                InfoRow(label: "Storage", value: "SwiftData (local, encrypted)")
                Divider().background(Color(hex: "1E1E2E"))
                InfoRow(label: "License", value: "MIT (Open Source)")
                Divider().background(Color(hex: "1E1E2E"))
                InfoRow(label: "Minimum iOS", value: "iOS 17.0")
            }
            .background(Color(hex: "14141E"))
            .cornerRadius(14)
        }
    }

    // MARK: - Actions

    func deleteAllSessions() {
        sessions.forEach { modelContext.delete($0) }
        try? modelContext.save()
    }
}

// MARK: - Component Views

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: iconColor))
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "444460"))
                    .kerning(2)
            }
            content
        }
    }
}

struct PrivacyRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "00C896"))
                .frame(width: 24)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "666680"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "666680"))
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(hex: "00C896"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "14141E"))
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "AAAACC"))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "666680"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "14141E"))
    }
}
