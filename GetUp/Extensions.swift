// Utils/Extensions.swift
// Shared utility extensions used throughout the app.

import SwiftUI

// MARK: - Color from Hex String

extension Color {
    /// Initialise a Color from a hex string like "00C896" or "#00C896"
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Date Formatting

extension Date {
    /// "Mon, 3 Feb" style short date
    var shortDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, d MMM"
        return f.string(from: self)
    }

    /// "09:45 AM"
    var shortTime: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: self)
    }
}

// MARK: - Duration Formatting

extension Int {
    /// Format seconds as "1m 23s" or "45s"
    var formattedDuration: String {
        if self >= 60 {
            let m = self / 60
            let s = self % 60
            return s > 0 ? "\(m)m \(s)s" : "\(m)m"
        }
        return "\(self)s"
    }
}

// MARK: - Double Clamping

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        max(range.lowerBound, min(range.upperBound, self))
    }
}
