//
//  SettingsTab.swift
//  glance
//
//  The tab bar's tab list. Debug-only Face Lab — the remaining live test
//  harness, kept for ongoing tuning — is appended only once revealed.
//

import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable, Hashable {
    case general
    case yourFace
    case yourVoice
    case password
    case camera
    case recognition
    case about
    case debugFaceLab

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .yourFace: return "Face"
        case .yourVoice: return "Voice"
        case .password: return "Password"
        case .camera: return "Camera"
        case .recognition: return "Recognition"
        case .about: return "About"
        case .debugFaceLab: return "Face Lab"
        }
    }

    /// Every tab uses an SF Symbol; see `SettingsTabIcon`.
    var icon: SettingsTabIcon {
        switch self {
        case .general: return .system("gearshape.fill")
        case .yourFace: return .system("faceid")
        case .yourVoice: return .system("mic.fill")
        case .password: return .system("lock.fill")
        case .camera: return .system("video.fill")
        case .recognition: return .system("sparkle")
        case .about: return .system("info.circle.fill")
        case .debugFaceLab: return .system("flask")
        }
    }

    /// Tabs in tab bar order, minus `.debugFaceLab` unless it's been
    /// unlocked this launch — see `AppEnvironment.isDebugSectionRevealed`.
    static func visibleTabs(includingDebug: Bool) -> [SettingsTab] {
        includingDebug ? allCases : allCases.filter { $0 != .debugFaceLab }
    }
}
