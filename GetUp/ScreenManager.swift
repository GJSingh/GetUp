// Utils/ScreenManager.swift
// Keeps the screen awake while a workout is active.
// Uses UIApplication.shared.isIdleTimerDisabled — no special permissions needed.

import UIKit
import Combine

final class ScreenManager {

    static let shared = ScreenManager()
    private init() {}

    /// Call this when workout becomes active — screen will stay on
    func keepAwake() {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }

    /// Call this when workout ends or app goes to background — restore normal behaviour
    func allowSleep() {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}
