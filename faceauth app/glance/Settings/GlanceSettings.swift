//
//  GlanceSettings.swift
//  glance
//
//  Backed directly by `UserDefaults.standard` — each property's `didSet`
//  writes through immediately, so there's no explicit "save" step.
//

import Foundation
import SwiftUI
import Observation

/// How long the Touch-ID-unlocked session may sit idle before it re-locks.
enum AutoLockInterval: Int, CaseIterable, Identifiable {
    case oneDay = 1
    case sevenDays = 7
    case fourteenDays = 14
    case thirtyDays = 30
    case never = 0

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .oneDay: return "1 day"
        case .sevenDays: return "7 days"
        case .fourteenDays: return "14 days"
        case .thirtyDays: return "30 days"
        case .never: return "Never"
        }
    }

    var duration: TimeInterval? {
        guard self != .never else { return nil }
        return TimeInterval(rawValue) * 24 * 60 * 60
    }

    /// Position in `allCases`, used to drive the discrete slider.
    var sliderIndex: Double {
        Double(Self.allCases.firstIndex(of: self) ?? 0)
    }

    static func from(sliderIndex: Double) -> AutoLockInterval {
        let clamped = Int(sliderIndex.rounded())
        return allCases.indices.contains(clamped) ? allCases[clamped] : .sevenDays
    }
}

/// Unlock success/failure animation style shown in the notch overlay.
enum UnlockAnimationStyle: String, CaseIterable, Identifiable {
    case none
    case minimal
    case original

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "None"
        case .minimal: return "Minimal"
        case .original: return "Original"
        }
    }

    /// The styles the picker offers; `.none` is still a valid stored value but is now produced by the "Show animation" toggle, not a tile.
    static let selectableCases: [UnlockAnimationStyle] = [.minimal, .original]
}

/// Color choice for the Face ID animation and accents.
enum FaceIDColor: String, CaseIterable, Identifiable {
    case blue
    case yellow
    case green
    case red

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blue: return "Blue"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .red: return "Red"
        }
    }

    var color: Color {
        switch self {
        case .blue: return Color(red: 0x34 / 255.0, green: 0x99 / 255.0, blue: 0xFF / 255.0)
        case .yellow: return Color(red: 1.0, green: 0.82, blue: 0.1)
        case .green: return Color(red: 0.2, green: 0.85, blue: 0.4)
        case .red: return Color(red: 1.0, green: 0.27, blue: 0.27)
        }
    }
}

/// What can prompt Face Unlock. Multi-select; at least one is always kept
/// selected, since a Mac with none armed would never show the notch.
enum UnlockTrigger: String, CaseIterable, Identifiable {
    /// The display turned back on (see `LockEventKind.wake`).
    case onWake
    /// The screen just became locked, no wake involved.
    case onLock
    /// Pressing space on the lock screen starts a scan. The lock screen's
    /// Secure Event Input blocks normal event taps, so this is detected via
    /// IOKit HID instead (see `SpaceKeyMonitor`), requiring Input Monitoring.
    case onSpace

    var id: String { rawValue }

    var title: String {
        switch self {
        case .onWake: return "On wake"
        case .onLock: return "On lock"
        case .onSpace: return "On space"
        }
    }

    var iconName: String {
        switch self {
        case .onWake: return "moon.fill"
        case .onLock: return "lock.laptopcomputer"
        case .onSpace: return "space"
        }
    }
}

@Observable
@MainActor
final class GlanceSettings {
    static let shared = GlanceSettings()

    private enum Key {
        static let isFaceUnlockEnabled = "GlanceSettings.isFaceUnlockEnabled"
        static let isVoiceUnlockEnabled = "GlanceSettings.isVoiceUnlockEnabled"
        static let matchThreshold = "GlanceSettings.matchThreshold"
        static let livenessChecksEnabled = "GlanceSettings.livenessChecksEnabled"
        static let livenessMode = "GlanceSettings.livenessMode"
        static let minimumFaceWidth = "GlanceSettings.minimumFaceWidth"
        static let unlockAnimationStyle = "GlanceSettings.unlockAnimationStyle"
        static let showUnlockAnimation = "GlanceSettings.showUnlockAnimation"
        /// Legacy bool key — read once during migration, then ignored.
        static let playUnlockAnimation = "GlanceSettings.playUnlockAnimation"
        static let unlockTriggers = "GlanceSettings.unlockTriggers"
        static let retryOnHover = "GlanceSettings.retryOnHover"
        static let faceDetectionSeconds = "GlanceSettings.faceDetectionSeconds"
        static let autoRetryOnce = "GlanceSettings.autoRetryOnce"
        static let hapticFeedbackEnabled = "GlanceSettings.hapticFeedbackEnabled"
        static let faceIDColor = "GlanceSettings.faceIDColor"
        static let preferredDisplayID = "GlanceSettings.preferredDisplayID"
        static let preferredDisplayName = "GlanceSettings.preferredDisplayName"
        static let autoLockIntervalDays = "GlanceSettings.autoLockIntervalDays"
        static let trustedNetworksEnabled = "GlanceSettings.trustedNetworksEnabled"
        static let trustedNetworks = "GlanceSettings.trustedNetworks"
        static let defaultCameraID = "GlanceSettings.defaultCameraID"
        static let builtInDisplayCameraID = "GlanceSettings.builtInDisplayCameraID"
        static let externalDisplayCameraID = "GlanceSettings.externalDisplayCameraID"
        static let hasCompletedOnboarding = "GlanceSettings.hasCompletedOnboarding"
        static let hasAcceptedEULA = "GlanceSettings.hasAcceptedEULA"
        static let onboardingResumeStep = "GlanceSettings.onboardingResumeStep"
        static let hasAcknowledgedSecurityNotice = "GlanceSettings.hasAcknowledgedSecurityNotice"
    }

    @ObservationIgnored private let defaults = UserDefaults.standard

    var isFaceUnlockEnabled: Bool {
        didSet { defaults.set(isFaceUnlockEnabled, forKey: Key.isFaceUnlockEnabled) }
    }
    var isVoiceUnlockEnabled: Bool {
        didSet { defaults.set(isVoiceUnlockEnabled, forKey: Key.isVoiceUnlockEnabled) }
    }
    var matchThreshold: Float {
        didSet { defaults.set(matchThreshold, forKey: Key.matchThreshold) }
    }
    /// Master switch for liveness checking. Off means face recognition
    /// alone decides an unlock — a photo of the enrolled user would pass.
    var livenessChecksEnabled: Bool {
        didSet { defaults.set(livenessChecksEnabled, forKey: Key.livenessChecksEnabled) }
    }
    /// Light (deny-only) vs Heavy (deny plus a required proof of life) —
    /// see `LivenessMode`.
    var livenessMode: LivenessMode {
        didSet { defaults.set(livenessMode.rawValue, forKey: Key.livenessMode) }
    }
    /// Mirrored into `FaceRecognitionPipeline.minimumProminentFaceWidth` on
    /// every change, since that's read from a background `nonisolated` context.
    var minimumFaceWidth: Float {
        didSet {
            defaults.set(minimumFaceWidth, forKey: Key.minimumFaceWidth)
            FaceRecognitionPipeline.minimumProminentFaceWidth = minimumFaceWidth
        }
    }
    /// The remembered choice (`.minimal`/`.original` only); `showUnlockAnimation`
    /// tracks on/off separately so toggling back on restores the prior pick.
    /// Read `effectiveUnlockAnimationStyle`, not this, to decide what to show.
    var unlockAnimationStyle: UnlockAnimationStyle {
        didSet { defaults.set(unlockAnimationStyle.rawValue, forKey: Key.unlockAnimationStyle) }
    }
    var showUnlockAnimation: Bool {
        didSet { defaults.set(showUnlockAnimation, forKey: Key.showUnlockAnimation) }
    }

    /// What the overlay should actually render — the pick, or `.none` when
    /// animations are switched off entirely.
    var effectiveUnlockAnimationStyle: UnlockAnimationStyle {
        showUnlockAnimation ? unlockAnimationStyle : .none
    }

    /// Selected Face ID color theme.
    var faceIDColor: FaceIDColor {
        didSet { defaults.set(faceIDColor.rawValue, forKey: Key.faceIDColor) }
    }

    /// Which signals arm Face Unlock. Persisted as raw-value strings; the
    /// setter refuses to store an empty set (see `UnlockTrigger`).
    var unlockTriggers: Set<UnlockTrigger> {
        didSet {
            if unlockTriggers.isEmpty {
                unlockTriggers = oldValue.isEmpty ? Set(UnlockTrigger.allCases) : oldValue
            }
            defaults.set(unlockTriggers.map(\.rawValue), forKey: Key.unlockTriggers)
        }
    }
    var retryOnHover: Bool {
        didSet { defaults.set(retryOnHover, forKey: Key.retryOnHover) }
    }
    /// How long each scan cycle looks for a face before giving up. Must stay
    /// equal to `FaceUnlockCoordinator.scanWindowDuration` and
    /// `NotchOverlayController.scanTimeoutDuration`.
    var faceDetectionSeconds: Int {
        didSet {
            let clamped = min(max(faceDetectionSeconds, Self.faceDetectionRange.lowerBound),
                               Self.faceDetectionRange.upperBound)
            guard clamped == faceDetectionSeconds else {
                faceDetectionSeconds = clamped
                return
            }
            defaults.set(faceDetectionSeconds, forKey: Key.faceDetectionSeconds)
        }
    }
    var autoRetryOnce: Bool {
        didSet { defaults.set(autoRetryOnce, forKey: Key.autoRetryOnce) }
    }
    /// Trackpad haptic on hovering the notch/pill and on a successful unlock —
    /// see `NotchOverlayView`'s hover handler and `.onChange(of: controller.phase)`.
    var hapticFeedbackEnabled: Bool {
        didSet { defaults.set(hapticFeedbackEnabled, forKey: Key.hapticFeedbackEnabled) }
    }

    static let faceDetectionRange = 3...10

    /// Which display Face Unlock shows on. `nil` means `NotchGeometry.preferredScreen()`'s
    /// default, re-evaluated live; a pinned display has deliberately no
    /// fallback if disconnected (see `FaceUnlockCoordinator.evaluateTrigger()`).
    var preferredDisplayID: String? {
        didSet { defaults.set(preferredDisplayID, forKey: Key.preferredDisplayID) }
    }
    /// The chosen display's name at pick time — cosmetic only, so the row can
    /// show something recognizable when that display is disconnected.
    var preferredDisplayName: String? {
        didSet { defaults.set(preferredDisplayName, forKey: Key.preferredDisplayName) }
    }
    /// Enforced by `SessionAutoLocker`, not here — this is only the stored
    /// preference.
    var autoLockInterval: AutoLockInterval {
        didSet { defaults.set(autoLockInterval.rawValue, forKey: Key.autoLockIntervalDays) }
    }
    var trustedNetworksEnabled: Bool {
        didSet { defaults.set(trustedNetworksEnabled, forKey: Key.trustedNetworksEnabled) }
    }
    var trustedNetworks: [TrustedWiFiNetwork] {
        didSet {
            guard let data = try? JSONEncoder().encode(trustedNetworks) else {
                assertionFailure("Couldn't encode trusted Wi-Fi networks.")
                return
            }
            defaults.set(data, forKey: Key.trustedNetworks)
        }
    }
    /// Device `uniqueID`s, not device objects — devices can disconnect/
    /// reconnect between launches, but their unique ID is stable.
    var defaultCameraID: String? {
        didSet { defaults.set(defaultCameraID, forKey: Key.defaultCameraID) }
    }
    var builtInDisplayCameraID: String? {
        didSet { defaults.set(builtInDisplayCameraID, forKey: Key.builtInDisplayCameraID) }
    }
    var externalDisplayCameraID: String? {
        didSet { defaults.set(externalDisplayCameraID, forKey: Key.externalDisplayCameraID) }
    }

    /// Gates first-run onboarding — `AppDelegate` shows it instead of the
    /// Settings window until this is `true`. Set once, by `OnboardingController`
    /// on the true first-run flow reaching `.complete`.
    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Key.hasCompletedOnboarding) }
    }
    /// Gates first-run onboarding until the person explicitly accepts the EULA.
    /// Declining leaves this false and closes the app without starting setup.
    var hasAcceptedEULA: Bool {
        didSet { defaults.set(hasAcceptedEULA, forKey: Key.hasAcceptedEULA) }
    }
    /// Where to resume first-run onboarding if the app quit mid-flow; `nil`
    /// starts fresh at `.intro`. Steps depending on in-memory capture state
    /// collapse to `.preSetup` before storing, since that state doesn't
    /// survive a relaunch — see `OnboardingStep.resumeTarget`.
    var onboardingResumeStep: OnboardingStep? {
        didSet { defaults.set(onboardingResumeStep?.rawValue, forKey: Key.onboardingResumeStep) }
    }
    var hasAcknowledgedSecurityNotice: Bool {
        didSet { defaults.set(hasAcknowledgedSecurityNotice, forKey: Key.hasAcknowledgedSecurityNotice) }
    }

    private init() {
        isFaceUnlockEnabled = defaults.object(forKey: Key.isFaceUnlockEnabled) as? Bool ?? true
        isVoiceUnlockEnabled = defaults.object(forKey: Key.isVoiceUnlockEnabled) as? Bool ?? false
        matchThreshold = defaults.object(forKey: Key.matchThreshold) as? Float ?? 0.66
        livenessChecksEnabled = defaults.object(forKey: Key.livenessChecksEnabled) as? Bool ?? true
        livenessMode = defaults.string(forKey: Key.livenessMode)
            .flatMap(LivenessMode.init(rawValue:)) ?? .light
        let storedMinimumFaceWidth = defaults.object(forKey: Key.minimumFaceWidth) as? Float
        if storedMinimumFaceWidth == 0.21 {
            // Migrate the former default to the wider detection distance.
            defaults.set(0.14, forKey: Key.minimumFaceWidth)
        }
        minimumFaceWidth = storedMinimumFaceWidth == 0.21 ? 0.14 : storedMinimumFaceWidth ?? 0.14

        let storedStyle: UnlockAnimationStyle
        if let raw = defaults.string(forKey: Key.unlockAnimationStyle),
           let style = UnlockAnimationStyle(rawValue: raw) {
            storedStyle = style
        } else if let legacy = defaults.object(forKey: Key.playUnlockAnimation) as? Bool {
            storedStyle = legacy ? .original : .none
        } else {
            storedStyle = .original
        }
        unlockAnimationStyle = storedStyle == .none ? .original : storedStyle
        showUnlockAnimation = defaults.object(forKey: Key.showUnlockAnimation) as? Bool
            ?? (storedStyle != .none)

        faceIDColor = defaults.string(forKey: Key.faceIDColor)
            .flatMap(FaceIDColor.init(rawValue:)) ?? .blue

        let storedTriggers = (defaults.array(forKey: Key.unlockTriggers) as? [String])?
            .compactMap { raw -> UnlockTrigger? in
                if raw == "onActivity" { return .onWake }
                return UnlockTrigger(rawValue: raw)
            }
        unlockTriggers = storedTriggers.map(Set.init).flatMap { $0.isEmpty ? nil : $0 }
            ?? [.onWake, .onLock]
        retryOnHover = defaults.object(forKey: Key.retryOnHover) as? Bool ?? true
        faceDetectionSeconds = (defaults.object(forKey: Key.faceDetectionSeconds) as? Int)
            .map { min(max($0, Self.faceDetectionRange.lowerBound), Self.faceDetectionRange.upperBound) }
            ?? 5
        autoRetryOnce = defaults.object(forKey: Key.autoRetryOnce) as? Bool ?? false
        hapticFeedbackEnabled = defaults.object(forKey: Key.hapticFeedbackEnabled) as? Bool ?? true
        preferredDisplayID = defaults.string(forKey: Key.preferredDisplayID)
        preferredDisplayName = defaults.string(forKey: Key.preferredDisplayName)

        autoLockInterval = (defaults.object(forKey: Key.autoLockIntervalDays) as? Int)
            .flatMap(AutoLockInterval.init(rawValue:)) ?? .sevenDays
        trustedNetworksEnabled = defaults.object(forKey: Key.trustedNetworksEnabled) as? Bool ?? false
        if let data = defaults.data(forKey: Key.trustedNetworks),
           let networks = try? JSONDecoder().decode([TrustedWiFiNetwork].self, from: data) {
            trustedNetworks = networks
        } else {
            trustedNetworks = []
        }
        defaultCameraID = defaults.string(forKey: Key.defaultCameraID)
        builtInDisplayCameraID = defaults.string(forKey: Key.builtInDisplayCameraID)
        externalDisplayCameraID = defaults.string(forKey: Key.externalDisplayCameraID)

        hasCompletedOnboarding = defaults.object(forKey: Key.hasCompletedOnboarding) as? Bool ?? false
        hasAcceptedEULA = defaults.object(forKey: Key.hasAcceptedEULA) as? Bool ?? false
        onboardingResumeStep = defaults.string(forKey: Key.onboardingResumeStep)
            .flatMap(OnboardingStep.init(rawValue:))
        hasAcknowledgedSecurityNotice = defaults.object(forKey: Key.hasAcknowledgedSecurityNotice) as? Bool ?? false

        FaceRecognitionPipeline.minimumProminentFaceWidth = minimumFaceWidth
    }

    /// Resets all settings, stored credentials, face profiles, and voice profiles to a clean slate.
    func resetToDefaults() {
        if let bundleID = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleID)
        }
        defaults.synchronize()

        isFaceUnlockEnabled = true
        isVoiceUnlockEnabled = false
        matchThreshold = 0.66
        livenessChecksEnabled = true
        livenessMode = .light
        minimumFaceWidth = 0.14
        unlockAnimationStyle = .original
        showUnlockAnimation = true
        faceIDColor = .blue
        unlockTriggers = [.onWake, .onLock]
        retryOnHover = true
        faceDetectionSeconds = 5
        autoRetryOnce = false
        hapticFeedbackEnabled = true
        preferredDisplayID = nil
        preferredDisplayName = nil
        autoLockInterval = .sevenDays
        trustedNetworksEnabled = false
        trustedNetworks = []
        defaultCameraID = nil
        builtInDisplayCameraID = nil
        externalDisplayCameraID = nil
        hasCompletedOnboarding = false
        hasAcceptedEULA = false
        onboardingResumeStep = nil
        hasAcknowledgedSecurityNotice = false

        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = appSupport.appendingPathComponent("glance", isDirectory: true)
        try? FileManager.default.removeItem(at: directory)

        SecureFaceStore.deleteAll()
        SecureVoiceStore.deleteAll()
        KeychainManager.deleteAll()
        SecureCredentialManager.lockSession()
        FaceEnrollmentStore.shared.reloadIfUnlocked()
    }
}
