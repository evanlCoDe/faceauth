//
//  GlanceTheme.swift
//  glance
//
//  Color and type tokens, kept here so OnboardingStepViews/OnboardingControls don't
//  repeat the same hex literals everywhere.
//

import SwiftUI
import AppKit

enum GlanceTheme {
    private static var currentRGB: (r: Double, g: Double, b: Double) {
        let col = GlanceSettings.shared.faceIDColor.color
        if let nsCol = NSColor(col).usingColorSpace(.sRGB) {
            return (r: Double(nsCol.redComponent), g: Double(nsCol.greenComponent), b: Double(nsCol.blueComponent))
        }
        return (r: 0x34 / 255.0, g: 0x99 / 255.0, b: 0xFF / 255.0)
    }

    static var accent: Color {
        GlanceSettings.shared.faceIDColor.color
    }

    /// White at 0, `accent` at 1.
    static func whiteToAccent(_ t: Double) -> Color {
        let t = min(max(t, 0), 1)
        let rgb = currentRGB
        return Color(
            red: 1 + (rgb.r - 1) * t,
            green: 1 + (rgb.g - 1) * t,
            blue: 1 + (rgb.b - 1) * t
        )
    }
    /// Accent-derived shades for the enrollment sweep, shifted so layered streaks read
    /// as one body of light rather than several flat shapes.
    static var accentPale: Color   { accent.opacity(0.4) }
    static var accentBright: Color { accent.opacity(0.85) }
    static var accentDeep: Color   { accent }
    static let surface = Color(red: 0x1E / 255, green: 0x1E / 255, blue: 0x1E / 255)
    static let surfaceRaised = Color(red: 0x32 / 255, green: 0x32 / 255, blue: 0x32 / 255)
    static let panel = Color.black
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0x94 / 255, green: 0x94 / 255, blue: 0x94 / 255)
    static let textDetail = Color(red: 0xBD / 255, green: 0xBD / 255, blue: 0xBD / 255)
    static let placeholder = Color(red: 0x2F / 255, green: 0x2F / 255, blue: 0x2F / 255)
    static let statusGranted = Color(red: 0x30 / 255, green: 0xD1 / 255, blue: 0x58 / 255)
    static let statusDenied = Color(red: 0xFF / 255, green: 0x45 / 255, blue: 0x3A / 255)

    enum Font {
        /// Scaled up so content reads clearly at the wider `OnboardingMetrics.panelWidth`.
        static let title = SwiftUI.Font.system(size: 26, weight: .bold)
        static let button = SwiftUI.Font.system(size: 13, weight: .medium)
        static let rowTitle = SwiftUI.Font.system(size: 13, weight: .medium)
        static let grantLabel = SwiftUI.Font.system(size: 12, weight: .semibold)
        static let rowDetail = SwiftUI.Font.system(size: 11, weight: .regular)
        static let passwordCaption = SwiftUI.Font.system(size: 12, weight: .medium)
        static let passwordPlaceholder = SwiftUI.Font.system(size: 12, weight: .regular)
        static let instruction = SwiftUI.Font.system(size: 15, weight: .medium)
    }
}
