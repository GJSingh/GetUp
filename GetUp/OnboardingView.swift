// Views/OnboardingView.swift
// First-launch onboarding. Explains what the app does, asks for camera permission
// and HealthKit permission BEFORE iOS shows its system dialogs — improving grant rates.
// Shown once. Stored via @AppStorage("hasSeenOnboarding").

import SwiftUI
import AVFoundation

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0
    @State private var cameraGranted   = false
    @State private var healthGranted   = false
    @State private var isRequestingCam = false
    @State private var isRequestingHK  = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            icon: "figure.strengthtraining.traditional",
            iconColor: "00C896",
            title: "Welcome to GetUp",
            subtitle: "Your AI-powered workout coach",
            body: "GetUp uses your iPhone camera to watch your form in real time — counting reps, scoring your posture, and coaching you through every set.",
            action: nil
        ),
        OnboardingPage(
            id: 1,
            icon: "camera.fill",
            iconColor: "5BC8FF",
            title: "Camera Access",
            subtitle: "How it works",
            body: "GetUp needs your camera to detect body position using Apple's on-device Vision framework. No video is ever recorded, saved, or sent anywhere.",
            action: .camera
        ),
        OnboardingPage(
            id: 2,
            icon: "heart.fill",
            iconColor: "FF6B81",
            title: "Apple Health",
            subtitle: "Optional but recommended",
            body: "GetUp can write your workout duration and calories burned to Apple Health. This is entirely optional — the app works perfectly without it.",
            action: .health
        ),
        OnboardingPage(
            id: 3,
            icon: "bolt.fill",
            iconColor: "FFB347",
            title: "You're Ready",
            subtitle: "Let's go",
            body: "Pick an exercise, set your reps and sets, and GetUp will coach you through the whole workout.",
            action: .finish
        )
    ]

    var body: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()

            VStack(spacing: 0) {
                // Page dots
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage
                                  ? Color(hex: "00C896")
                                  : Color(hex: "222235"))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4), value: currentPage)
                    }
                }
                .padding(.top, 64)

                Spacer()

                // Sliding page content
                TabView(selection: $currentPage) {
                    ForEach(pages) { page in
                        PageView(
                            page: page,
                            cameraGranted: cameraGranted,
                            healthGranted: healthGranted,
                            isRequestingCam: isRequestingCam,
                            isRequestingHK: isRequestingHK,
                            onAction: { handleAction(page.action) }
                        )
                        .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                Spacer()

                // Bottom navigation
                bottomBar
                    .padding(.horizontal, 32)
                    .padding(.bottom, 52)
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            // Skip (hidden on last page)
            if currentPage < pages.count - 1 {
                Button("Skip") {
                    withAnimation { currentPage = pages.count - 1 }
                }
                .font(.system(size: 15))
                .foregroundStyle(Color(hex: "444460"))
            } else {
                Color.clear.frame(width: 44)
            }

            Spacer()

            // Next / Get Started
            Button {
                if currentPage == pages.count - 1 {
                    hasSeenOnboarding = true
                } else {
                    withAnimation { currentPage += 1 }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                        .font(.system(size: 16, weight: .semibold))
                    if currentPage < pages.count - 1 {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color(hex: "00C896"))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Action Handling

    private func handleAction(_ action: OnboardingAction?) {
        switch action {
        case .camera:
            requestCamera()
        case .health:
            requestHealth()
        case .finish:
            hasSeenOnboarding = true
        case nil:
            break
        }
    }

    private func requestCamera() {
        // Guard: don't re-request if already granted or requesting
        guard !cameraGranted, !isRequestingCam else { return }
        isRequestingCam = true
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.cameraGranted   = granted
                self.isRequestingCam = false
                // Show checkmark — user taps Next to continue (navigation decoupled from permission)
            }
        }
    }

    private func requestHealth() {
        // Guard: don't re-request if already granted or currently requesting
        guard !healthGranted, !isRequestingHK else { return }
        guard HealthKitManager.shared.isAvailable else { return }

        isRequestingHK = true

        // Timeout: if HealthKit capability is missing from Xcode entitlements,
        // requestAuthorization never calls back. Reset after 8 seconds so the
        // page never gets permanently stuck.
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            if self.isRequestingHK {
                self.isRequestingHK = false   // unblock UI silently
            }
        }

        HealthKitManager.shared.requestAuthorisation { granted in
            // Navigation is decoupled — just show checkmark. User taps Next to continue.
            self.healthGranted  = granted
            self.isRequestingHK = false
        }
    }
}

// MARK: - PageView

private struct PageView: View {
    let page: OnboardingPage
    let cameraGranted: Bool
    let healthGranted: Bool
    let isRequestingCam: Bool
    let isRequestingHK: Bool
    let onAction: () -> Void

    private var showPermissionButton: Bool { page.action == .camera || page.action == .health }

    private var permissionAlreadyGranted: Bool {
        (page.action == .camera && cameraGranted) ||
        (page.action == .health && healthGranted)
    }

    private var isRequesting: Bool {
        (page.action == .camera && isRequestingCam) ||
        (page.action == .health && isRequestingHK)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: page.iconColor).opacity(0.12))
                    .frame(width: 120, height: 120)
                Circle()
                    .stroke(Color(hex: page.iconColor).opacity(0.2), lineWidth: 1)
                    .frame(width: 120, height: 120)
                Image(systemName: page.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(Color(hex: page.iconColor))
            }
            .padding(.bottom, 40)

            // Text
            VStack(spacing: 12) {
                Text(page.subtitle.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: page.iconColor))
                    .kerning(2)

                Text(page.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "888899"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 32)

            // Permission button (camera / health pages only)
            if showPermissionButton {
                permissionButton
                    .padding(.top, 40)
                    .padding(.horizontal, 32)
            }
        }
    }

    @ViewBuilder
    private var permissionButton: some View {
        if permissionAlreadyGranted {
            // Granted state
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(hex: "00C896"))
                Text(page.action == .camera ? "Camera Access Granted" : "Health Access Granted")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "00C896"))
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color(hex: "00C896").opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "00C896").opacity(0.3), lineWidth: 1))

        } else {
            // Request button
            Button(action: onAction) {
                HStack(spacing: 10) {
                    if isRequesting {
                        ProgressView().tint(.black).scaleEffect(0.8)
                    } else {
                        Image(systemName: page.action == .camera ? "camera.fill" : "heart.fill")
                            .font(.system(size: 14))
                    }
                    Text(isRequesting
                         ? "Requesting..."
                         : (page.action == .camera ? "Allow Camera Access" : "Connect Apple Health"))
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.black)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(Color(hex: page.iconColor))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isRequesting)

            if page.action == .health {
                Text("You can also connect later in Settings → Health")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "444460"))
                    .padding(.top, 8)
            }
        }
    }
}

// MARK: - Models

private struct OnboardingPage: Identifiable {
    let id: Int
    let icon: String
    let iconColor: String
    let title: String
    let subtitle: String
    let body: String
    let action: OnboardingAction?
}

private enum OnboardingAction {
    case camera, health, finish
}
