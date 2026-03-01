// Utils/AppOrientationHelper.swift
// Unlocks landscape rotation for the active workout screen.
// All other screens stay portrait.
//
// ─────────────────────────────────────────────────────────────────────────────
// SETUP — add ONE property to your existing App struct in GetUpApp.swift:
//
//   @UIApplicationDelegateAdaptor(GetUpAppDelegate.self) var appDelegate
//
// It must go INSIDE the App struct body, like this:
//
//   @main
//   struct GetUpApp: App {
//       @UIApplicationDelegateAdaptor(GetUpAppDelegate.self) var appDelegate
//       // ... rest of your existing code unchanged
//   }
//
// GetUpAppDelegate is defined in this file — no other changes needed.
// ─────────────────────────────────────────────────────────────────────────────

import UIKit
import SwiftUI

// MARK: - GetUpAppDelegate

class GetUpAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        AppOrientationHelper.orientationLock
    }
}

// MARK: - AppOrientationHelper

enum AppOrientationHelper {

    static var orientationLock: UIInterfaceOrientationMask = .portrait

    /// Call from ActiveWorkoutView .onAppear
    static func unlock() {
        orientationLock = [.portrait, .landscapeLeft, .landscapeRight]
        requestUpdate()
    }

    /// Call from ActiveWorkoutView .onDisappear
    static func lockPortrait() {
        orientationLock = .portrait
        requestUpdate()
    }

    private static func requestUpdate() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first else { return }
        if #available(iOS 16.0, *) {
            scene.requestGeometryUpdate(
                UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientationLock)
            ) { _ in }
        }
    }
}
