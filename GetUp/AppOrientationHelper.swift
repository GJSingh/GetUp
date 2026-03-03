// Utils/AppOrientationHelper.swift
// Unlocks landscape rotation for the active workout screen only.
// All other screens stay portrait.
//
// ─────────────────────────────────────────────────────────────────────────────
// SETUP — add this one method to your existing AppDelegate.swift:
//
//   func application(
//       _ application: UIApplication,
//       supportedInterfaceOrientationsFor window: UIWindow?
//   ) -> UIInterfaceOrientationMask {
//       return AppOrientationHelper.orientationLock
//   }
//
// Your GetUpApp.swift already has @UIApplicationDelegateAdaptor(AppDelegate.self)
// so no other changes are needed anywhere.
// ─────────────────────────────────────────────────────────────────────────────

import UIKit
import SwiftUI

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
