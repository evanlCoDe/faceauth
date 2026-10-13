//
//  OnboardingController.swift
//  glance
//
//  State machine behind the notch-hosted guided onboarding flow: permissions, selected
//  face/voice enrollment, and password setup. Reuses the same camera/detection/embedding/
//  storage pieces as the Face Lab debug tab rather than reimplementing them.
//
//  Still not milestone G: finishing onboarding stores the selected authentication data
//  and an encrypted password, but nothing here triggers an unlock.
//

import Foundation
import Observation
import AVFoundation
import AppKit
import SwiftUI
import Speech

/// `String`-backed so `GlanceSettings.onboardingResumeStep` can persist it directly by name.
enum OnboardingStep: String, CaseIterable {
    case eula
    case selectUnlockMethod
    case intro
    case permissions
    case securityNotice
    case preSetup
    case selectCamera
    case enroll
    case enrollVoice
    case name
    case password
    case complete

    var previous: OnboardingStep? {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self), index > 0 else { return nil }
        return all[index - 1]
    }

    /// Whether this step shows the Back/primary button pair; enroll is close-control
    /// only, and complete/intro have just one side.
    var showsBackButton: Bool {
        switch self {
        case .selectUnlockMethod, .securityNotice, .permissions, .preSetup, .selectCamera, .name, .password: return true
        case .eula, .intro, .enroll, .enrollVoice, .complete: return false
        }
    }

    /// Where a first-run flow should resume if the app quit on this step. `.enroll`,
    /// `.name`, and `.password` all depend on in-memory state a fresh launch doesn't
    /// have, so they collapse back to `.preSetup` rather than resuming into a step
    /// whose prerequisites no longer exist.
    var resumeTarget: OnboardingStep {
        switch self {
        case .enroll, .enrollVoice, .name, .password: return .preSetup
        case .eula, .selectUnlockMethod, .intro, .securityNotice, .permissions, .preSetup, .selectCamera, .complete: return self
        }
    }
}

/// A single guided head pose captured during enrollment — center plus the
/// 8 compass directions, in the exact order presented to the user.
enum EnrollmentPose: Int, CaseIterable {
    case center, left, topLeft, top, topRight, right, bottomRight, bottom, bottomLeft

    enum YawBand { case left, none, right }
    enum PitchBand { case up, none, down }

    var yawBand: YawBand {
        switch self {
        case .left, .topLeft, .bottomLeft: return .left
        case .right, .topRight, .bottomRight: return .right
        case .center, .top, .bottom: return .none
        }
    }

    var pitchBand: PitchBand {
        switch self {
        case .top, .topLeft, .topRight: return .up
        case .bottom, .bottomLeft, .bottomRight: return .down
        case .center, .left, .right: return .none
        }
    }

    /// Compass angle (0 = up, clockwise) this pose's ring sector is centered
    /// on. `nil` for center, which pulses the whole ring instead of
    /// claiming a sector.
    var compassAngle: Double? {
        switch self {
        case .center: return nil
        case .left: return 270
        case .topLeft: return 315
        case .top: return 0
        case .topRight: return 45
        case .right: return 90
        case .bottomRight: return 135
        case .bottom: return 180
        case .bottomLeft: return 225
        }
    }

    var instruction: String {
        switch self {
        case .center: return "Look straight at the camera"
        case .left: return "Turn your head slightly left"
        case .topLeft: return "Turn your head to the top left"
        case .top: return "Turn your head slightly up"
        case .topRight: return "Turn your head to the top right"
        case .right: return "Turn your head slightly right"
        case .bottomRight: return "Turn your head to the bottom right"
        case .bottom: return "Turn your head slightly down"
        case .bottomLeft: return "Turn your head to the bottom left"
        }
    }

    /// Relaxes this pose's yaw/pitch bands — same knob as `stallWidenFactor`, so >1 is easier.
    var matchLeniency: Float {
        switch self {
        case .bottomLeft, .bottomRight: return 1.5
        case .bottom: return 1.2
        default: return 1
        }
    }

    /// Persisted alongside each sample so a saved identity records which
    /// pose each embedding came from.
    var name: String {
        switch self {
        case .center: return "center"
        case .left: return "left"
        case .topLeft: return "top_left"
        case .top: return "top"
        case .topRight: return "top_right"
        case .right: return "right"
        case .bottomRight: return "bottom_right"
        case .bottom: return "bottom"
        case .bottomLeft: return "bottom_left"
        }
    }
}

enum CameraPermissionState {
    case notDetermined
    case granted
    case denied
}

@Observable
@MainActor
final class OnboardingController {
    let camera = CameraManager()
    let pipeline = FaceRecognitionPipeline()
    let voicePipeline = VoiceIDPipeline()
    private let store = FaceEnrollmentStore.shared
    private let sweepWindow = EnrollmentSweepWindowController()

    /// Persists the resume point for a true first-run flow on every step change, so
    /// `AppDelegate` can drop a relaunched, mid-onboarding user back where they left off.
    /// Settings-triggered flows never touch this.
    private(set) var step: OnboardingStep = .intro {
        didSet {
            guard isFirstRunFlow else { return }
            if step == .complete {
                GlanceSettings.shared.hasCompletedOnboarding = true
                // Normal onboarding now passes through `.securityNotice` on its own —
                // completing it here means the standalone post-update notice never needs to.
                GlanceSettings.shared.hasAcknowledgedSecurityNotice = true
                GlanceSettings.shared.onboardingResumeStep = nil
            } else {
                GlanceSettings.shared.onboardingResumeStep = step.resumeTarget
            }
        }
    }

    /// Fires exactly once, after the "You're all set" screen dismisses — either the true
    /// first-run flow (so `AppDelegate` can open Settings only once onboarding UI is gone)
    /// or the standalone post-update notice (so it can resume startup). `nil` otherwise.
    var onFirstRunComplete: (() -> Void)?

    /// True when started by `startEnrollmentOnly()` — shows only the guided pose-capture
    /// step and saves samples directly instead of continuing to the password step.
    private let isEnrollmentOnly: Bool
    private let isVoiceEnrollmentOnly: Bool

    /// True when started by `startPasswordOnly()` — jumps straight to `.password` and
    /// treats Back as "cancel" rather than a setup flow that isn't running.
    private let isPasswordOnly: Bool

    /// True when started by `startPostUpdateNotice()` — a standalone replay of just the
    /// security-notice step for users who completed onboarding before it existed. Skips
    /// straight to `.complete` on acknowledgment; every other step is unreachable. Read by
    /// `SecurityNoticeStepView` to swap its Back button for "No thanks."
    let isPostUpdateNotice: Bool

    /// True only for the genuine first-run flow (also true when replayed via Face Lab's
    /// "Start Onboarding" debug button). Gates whether `step`'s `didSet` persists a resume point.
    private var isFirstRunFlow: Bool { !isEnrollmentOnly && !isVoiceEnrollmentOnly && !isPasswordOnly && !isPostUpdateNotice }

    var isFaceUnlockSelected = GlanceSettings.shared.isFaceUnlockEnabled
    var isVoiceUnlockSelected = GlanceSettings.shared.isVoiceUnlockEnabled

    /// Whether the intro's one-time light sweep already played this session. Lives here
    /// rather than as `@State` on `IntroStepView` because that view is torn down and
    /// recreated whenever navigation leaves and returns to `.intro`.
    private var hasPlayedIntroSweep = false

    /// Plays the intro screen's one-time top-to-bottom light sweep full-screen via the
    /// same `sweepWindow` guided enrollment uses. No-op after the first call this session.
    func playIntroSweepIfNeeded() {
        guard !hasPlayedIntroSweep else { return }
        hasPlayedIntroSweep = true
        sweepWindow.presentOnce(direction: .down)
    }

    /// Who this run is enrolling. Recapture is keyed by `id` rather than name so the
    /// naming step can rename an identity without orphaning it under its old name.
    enum EnrollmentTarget: Equatable {
        case newIdentity
        case replacing(UUID)

        var identityID: UUID? {
            if case .replacing(let id) = self { return id }
            return nil
        }
    }

    private let enrollmentTarget: EnrollmentTarget

    enum NavDirection { case forward, backward }
    /// Which way the step just changed — read by OnboardingNotchView to
    /// pick the scroll direction for the blur transition.
    private(set) var navDirection: NavDirection = .forward

    /// Entry point used by Face Lab's "Start Onboarding" button, and by `AppDelegate` at
    /// first launch and whenever the user tries to reach Settings before onboarding is done.
    ///
    /// - Parameter resumingAt: where a previously-quit first-run flow left off, or `nil`
    ///   to start fresh at `.intro`. `.permissions` is the one resumable step with a side
    ///   effect (live polling) that jumping straight past `advance()` would otherwise skip.
    /// - Parameter onFirstRunComplete: see the property of the same name.
    static func startFlow(resumingAt step: OnboardingStep? = nil, onFirstRunComplete: (() -> Void)? = nil) {
        let controller = OnboardingController()
        controller.pendingName = defaultName
        controller.onFirstRunComplete = onFirstRunComplete
        let initialStep = GlanceSettings.shared.hasAcceptedEULA ? (step ?? .intro) : .eula
        if initialStep != .intro {
            controller.step = initialStep
        }
        if initialStep == .permissions {
            controller.startPermissionsPolling()
        }
        NotchOverlayController.shared.presentOnboarding(controller)
    }

    func acceptEULA() {
        GlanceSettings.shared.hasAcceptedEULA = true
        navDirection = .forward
        withAnimation(OnboardingMetrics.stepAnimation) {
            step = .selectUnlockMethod
        }
    }

    /// Entry point used by Settings' "Set up Face Unlock" / "Redo Face Enrollment" — presents
    /// the guided pose-capture plus naming step and saves directly once done.
    ///
    /// The Your Face page is still single-identity, so this keeps targeting
    /// `identities.first`: "redo" replaces it in place, or enrolls someone new.
    static func startEnrollmentOnly() {
        Task { @MainActor in
            guard await unlockForEnrollment(reason: "Authenticate to re-enroll your face") else { return }
            let store = FaceEnrollmentStore.shared
            store.reloadIfUnlocked()
            let existing = store.identities.first
            present(
                target: existing.map { .replacing($0.id) } ?? .newIdentity,
                prefillName: existing?.name ?? defaultName
            )
        }

    }

    static func startVoiceEnrollmentOnly(passphrase: String? = nil) {
        Task { @MainActor in
            guard await unlockForEnrollment(reason: "Authenticate to enroll your voice profile") else { return }
            let controller = OnboardingController(isVoiceEnrollmentOnly: true)
            controller.voicePassphrase = passphrase ?? ""
            controller.step = .enrollVoice
            NotchOverlayController.shared.presentOnboarding(controller)
        }
    }

    /// Entry point used by Face Lab's "Add Identity" — always enrolls a *new* person
    /// alongside whoever is already enrolled; name starts empty rather than `defaultName`.
    static func startAddIdentity() {
        Task { @MainActor in
            guard await unlockForEnrollment(reason: "Authenticate to enroll another face") else { return }
            FaceEnrollmentStore.shared.reloadIfUnlocked()
            present(target: .newIdentity, prefillName: "")
        }
    }

    /// Entry point used by Face Lab's per-identity "Recapture" — replaces that identity's
    /// samples wholesale, keeping its id and enrollment date.
    static func startRecapture(of identity: FaceIdentity) {
        Task { @MainActor in
            guard await unlockForEnrollment(reason: "Authenticate to re-enroll this face") else { return }
            FaceEnrollmentStore.shared.reloadIfUnlocked()
            present(target: .replacing(identity.id), prefillName: identity.name)
        }
    }

    /// Enrollment-only flows persist as soon as naming is confirmed, so Touch ID has to
    /// happen up front — there's no later password step to unlock the session.
    private static func unlockForEnrollment(reason: String) async -> Bool {
        guard !SecureCredentialManager.isSessionUnlocked else { return true }
        do {
            try await Task.detached(priority: .userInitiated) {
                try SecureCredentialManager.unlockSession(reason: reason)
            }.value
            return true
        } catch {
            return false
        }
    }

    private static func present(target: EnrollmentTarget, prefillName: String) {
        let controller = OnboardingController(isEnrollmentOnly: true, enrollmentTarget: target)
        controller.pendingName = prefillName
        NotchOverlayController.shared.presentOnboarding(controller)
    }

    /// Entry point used by Settings' "Change password" — presents only the password step,
    /// reusing the same field, validation and save path as first-run setup.
    ///
    /// No Touch ID prompt here: the only caller already has a live session, and
    /// `finish(password:)` re-asserts that anyway.
    static func startPasswordOnly() {
        Task { @MainActor in
            let controller = OnboardingController(isPasswordOnly: true)
            NotchOverlayController.shared.presentOnboarding(controller)
        }
    }

    /// Entry point used by `AppDelegate` at launch for users who completed onboarding
    /// before the security-notice step existed — a standalone replay of just that step, so
    /// they still see it once. Everything else is already done, so acknowledging it jumps
    /// straight to `.complete` (see `advance()`) rather than resuming the full flow.
    static func startPostUpdateNotice(onComplete: (() -> Void)? = nil) {
        let controller = OnboardingController(isPostUpdateNotice: true)
        controller.onFirstRunComplete = onComplete
        NotchOverlayController.shared.presentOnboarding(controller)
    }

    // MARK: - Panel sizing (read by NotchOverlayView)

    /// Read fresh off the preferred screen each time rather than cached, so it stays
    /// correct across a display change mid-flow.
    private var currentPanelStyle: NotchPanelStyle {
        NotchGeometry.preferredScreen().map(NotchGeometry.forScreen)?.style ?? .notch
    }

    var panelSize: CGSize { OnboardingMetrics.panelSize(for: step, style: currentPanelStyle) }
    var panelBottomRadius: CGFloat { OnboardingMetrics.panelBottomRadius(for: step) }

    // MARK: - Permissions

    private(set) var accessibilityGranted = false
    private(set) var cameraPermission: CameraPermissionState = .notDetermined
    private(set) var microphonePermission: CameraPermissionState = .notDetermined
    var bothPermissionsGranted: Bool { accessibilityGranted && cameraPermission == .granted }
    var allPermissionsGranted: Bool {
        accessibilityGranted
            && (!isFaceUnlockSelected || cameraPermission == .granted)
            && (!isVoiceUnlockSelected || microphonePermission == .granted)
    }

    private var permissionsPollTask: Task<Void, Never>?

    // MARK: - Enrollment

    /// 9 poses x 2 samples = 18 total, enough for a stable template without overlong holds.
    private let samplesPerPose = 2
    /// Consecutive matching frames required before a capture fires — debounces a lucky
    /// frame near a pose boundary.
    private let requiredMatchStreak = 3
    /// Wait this long after yaw/pitch matches before samples count, so the user has
    /// settled into the turn rather than being captured mid-motion.
    private let poseHoldDuration: Duration = .milliseconds(500)
    /// Permissive floor for Vision's capture-quality score (no fixed universal cutoff) —
    /// better to accept a mediocre sample than stall the whole flow.
    private let qualityFloor: Float = 0.2
    /// Hold off accepting captures this long once the camera comes up, so the first
    /// samples aren't taken mid-blink. Detection still runs during this window.
    private let initialCaptureDelay: Duration = .seconds(1.5)
    /// Enrollment wants a closer face than unlock's bystander cutoff
    private var enrollmentMinimumFaceWidth: Float {
        max(FaceRecognitionPipeline.minimumProminentFaceWidth, 0.2)
    }

    // Pose-matching bands, in radians. Yaw: left turn is positive, matching the mirrored
    // preview. Pitch's sign is the opposite of the initial guess — see `pitchMatches` below.
    private let yawInnerThreshold: Float = 0.24
    private let yawCenterTolerance: Float = 0.18
    private let yawOuterCap: Float = 0.51
    private let pitchInnerThreshold: Float = 0.17
    private let pitchCenterTolerance: Float = 0.15
    private let pitchOuterCap: Float = 0.37
    /// If a pose takes longer than this, matching bands widen by `stallWidenFactor` so an
    /// unusual camera angle can't permanently strand the user.
    private let stallTimeout: Duration = .seconds(12)
    private let stallWidenFactor: Float = 1.25

    private(set) var currentPoseIndex = 0
    private(set) var capturedForCurrentPose = 0
    private(set) var faceDetected = false
    private(set) var currentYaw: Float?
    private(set) var currentPitch: Float?
    /// Whether the last-seen face read as too small to enroll reliably — swaps the pose
    /// instruction for a "move closer" prompt while true.
    private(set) var isTooFar = false
    /// An extreme head turn is not useful enrollment data. Keep this separate from
    /// `isTooFar`, which describes face distance rather than pose.
    private(set) var excessiveTurn: ExcessiveTurn?
    private(set) var enrollmentComplete = false

    enum ExcessiveTurn: Equatable {
        case left, topLeft, up, topRight, right, bottomRight, down, bottomLeft

        var instruction: String {
            switch self {
            case .left: return "Too far left"
            case .topLeft: return "Too far toward the top left"
            case .up: return "Too far up"
            case .topRight: return "Too far toward the top right"
            case .right: return "Too far right"
            case .bottomRight: return "Too far toward the bottom right"
            case .down: return "Too far down"
            case .bottomLeft: return "Too far toward the bottom left"
            }
        }
    }

    /// Sectors already captured — read by EnrollmentRingView to decide which
    /// ticks are lit.
    private(set) var capturedPoses: Set<EnrollmentPose> = []
    /// Bumped every time `.center` is captured; EnrollmentRingView observes
    /// this to trigger the whole-ring pulse (center has no sector of its
    /// own to light).
    private(set) var centerPulseTick = 0

    /// Whether pose instructions should be visible in the enroll panel —
    /// false once enrollment completes, ahead of the checkmark sequence.
    private(set) var guideVisible = false
    /// Whether the camera preview should be visible — faded out as part of
    /// the camera-complete sequence.
    private(set) var cameraPreviewVisible = true
    /// Whether the completion checkmark should be drawing/shown.
    private(set) var showCheckmark = false

    private struct CollectedSample {
        let embedding: [Float]
        let pose: EnrollmentPose
        /// Carried through so an enrolled identity can report how good its samples were.
        let quality: Float?
        /// Stamped at capture, not at save — samples sit in memory across the naming
        /// (and, on first run, password) step, so a save-time stamp would be wrong.
        let capturedAt: Date
    }
    /// Held in memory (not persisted) until the identity has a name; in first-run setup
    /// saving additionally requires the session `finish(password:)` unlocks.
    private var collectedSamples: [CollectedSample] = []
    private var matchStreak = 0
    private var isProcessingFrame = false
    private var poseStartedAt: ContinuousClock.Instant = .now
    /// Set once in `beginEnrollment()` — not per-pose — so it only holds back the first
    /// pose rather than pausing again after every later pose change.
    private var captureReadyAt: ContinuousClock.Instant = .now
    /// When the current pose first started matching continuously; `nil` while out of band.
    /// Capture waits `poseHoldDuration` past this instant.
    private var poseHoldStartedAt: ContinuousClock.Instant?

    var currentPose: EnrollmentPose? {
        EnrollmentPose(rawValue: currentPoseIndex)
    }

    /// Copy shown under the camera: pose guidance, a closer-up prompt, or the
    /// completion line.
    var enrollmentInstruction: String {
        if enrollmentComplete { return "Face captured" }
        if let excessiveTurn { return excessiveTurn.instruction }
        if isTooFar { return "Bring your face closer" }
        return currentPose?.instruction ?? ""
    }

    /// Where the head is currently turned, for the ring's live indicator.
    struct HeadTurn: Equatable {
        /// Compass angle (0 = up, clockwise) — same frame as `EnrollmentPose.compassAngle`.
        let angle: Double
        /// How far the turn has gone toward the current pose's threshold, 0...1.
        let progress: Double
    }

    /// Below this fraction of the threshold the direction is mostly sensor noise.
    private let headTurnDeadzone: Double = 0.15

    /// Live head direction, or `nil` when there's nothing to point at. Axes are normalized
    /// against the current pose's thresholds, so `progress` hits 1 as the pose starts matching.
    var headTurn: HeadTurn? {
        guard step == .enroll, !enrollmentComplete, faceDetected, !isTooFar, excessiveTurn == nil,
              let pose = currentPose, pose != .center,
              let yaw = currentYaw, let pitch = currentPitch else { return nil }

        // Vision inverts both axes vs. the screen: +yaw turns left, +pitch looks down.
        let x = Double(-yaw / (yawInnerThreshold / pose.matchLeniency))
        let y = Double(-pitch / (pitchInnerThreshold / pose.matchLeniency))

        let magnitude = (x * x + y * y).squareRoot()
        guard magnitude > headTurnDeadzone else { return nil }

        let degrees = atan2(x, y) * 180 / .pi
        return HeadTurn(angle: degrees < 0 ? degrees + 360 : degrees, progress: min(magnitude, 1))
    }

    private enum EnrollFrameOutcome: Sendable {
        case noFace
        case tooFar
        case ready(FaceRecognitionResult)
    }

    var overallEnrollmentProgress: Double {
        let total = Double(EnrollmentPose.allCases.count * samplesPerPose)
        let done = Double(currentPoseIndex * samplesPerPose + capturedForCurrentPose)
        return min(done / total, 1.0)
    }

    // MARK: - Naming

    /// Bound directly by `NameStepView`; pre-filled by whichever entry point started the flow.
    var pendingName: String = ""
    private(set) var nameError: String?

    /// Naming is the last input in an add/recapture flow, but only the
    /// halfway point of first-run setup, where the password still follows.
    var nameStepPrimaryTitle: String { isEnrollmentOnly ? "Save" : "Continue" }

    // MARK: - Password

    private(set) var passwordError: String?
    private(set) var isSavingPassword = false

    init(
        isEnrollmentOnly: Bool = false,
        isVoiceEnrollmentOnly: Bool = false,
        isPasswordOnly: Bool = false,
        isPostUpdateNotice: Bool = false,
        enrollmentTarget: EnrollmentTarget = .newIdentity
    ) {
        self.isEnrollmentOnly = isEnrollmentOnly
        self.isVoiceEnrollmentOnly = isVoiceEnrollmentOnly
        self.isPasswordOnly = isPasswordOnly
        self.isPostUpdateNotice = isPostUpdateNotice
        self.enrollmentTarget = enrollmentTarget
        observeFrames()
        if isEnrollmentOnly {
            step = .enroll
            // Deferred a tick for the same reason `advance()` defers it — see comment there.
            Task { @MainActor [weak self] in self?.beginEnrollment() }
        } else if isVoiceEnrollmentOnly {
            step = .enrollVoice
        } else if isPasswordOnly {
            // No deferral needed: the password step starts nothing heavy.
            step = .password
        } else if isPostUpdateNotice {
            step = .securityNotice
        }
    }

    // MARK: - Navigation

    func advance() {
        navDirection = .forward
        let leavingStep = step
        withAnimation(OnboardingMetrics.stepAnimation) {
            if isPostUpdateNotice {
                // The only transition this flow has: notice seen, done.
                step = .complete
            } else {
                switch step {
                case .eula: break // advances only after explicit acceptance
                case .selectUnlockMethod:
                    GlanceSettings.shared.isFaceUnlockEnabled = isFaceUnlockSelected
                    GlanceSettings.shared.isVoiceUnlockEnabled = isVoiceUnlockSelected
                    step = .intro
                case .intro: step = .permissions
                case .permissions: step = .securityNotice
                case .securityNotice: step = .preSetup
                case .preSetup: step = isFaceUnlockSelected ? .selectCamera : .enrollVoice
                case .selectCamera: step = .enroll
                case .enroll: break // advances automatically on completion
                case .enrollVoice: break // standalone voice enrollment completes automatically
                case .name: break // handled by confirmName()
                case .password: break // handled by finish(password:)
                case .complete: break
                }
            }
        }
        if leavingStep == .permissions { stopPermissionsPolling() }
        switch step {
        case .permissions: startPermissionsPolling()
        case .enroll:
            // Deferred a tick so the heavy camera start doesn't land in the same runloop
            // turn as the panel-resize transition, stealing frames from the spring animation.
            Task { @MainActor [weak self] in self?.beginEnrollment() }
        case .complete where isPostUpdateNotice:
            GlanceSettings.shared.hasAcknowledgedSecurityNotice = true
            scheduleCompletionDismiss()
        default: break
        }
    }

    /// "No thanks" on the post-update notice. Declining isn't a real option — the app
    /// requires acknowledgment before it'll run — so this quits rather than dismissing back
    /// into use.
    func declinePostUpdateNotice() {
        NSApp.terminate(nil)
    }

    /// Steps backward. The enroll close control also lands here: a retreat to pre-setup
    /// in the full setup flow, a cancel in add/recapture.
    func back() {
        navDirection = .backward
        // No earlier step to return to in the password-only flow — Back is a plain cancel.
        if isPasswordOnly {
            teardown()
            NotchOverlayController.shared.dismissOnboarding()
            return
        }
        switch step {
        case .enrollVoice where isVoiceEnrollmentOnly:
            teardown()
            NotchOverlayController.shared.dismissOnboarding()
        case .enrollVoice:
            voiceEnrollmentGeneration &+= 1
            isPreparingVoiceCapture = false
            voicePipeline.stopEnrollmentCapture()
            pendingVoiceFeatureVector = nil
            pendingVoicePassphrase = nil
            voiceCaptureStarted = false
            voiceProgress = 0
            voiceShowCheckmark = false
            voiceError = nil
            if isFaceUnlockSelected {
                resetEnrollmentState()
                withAnimation(OnboardingMetrics.stepAnimation) { step = .selectCamera }
            } else {
                withAnimation(OnboardingMetrics.stepAnimation) { step = .preSetup }
            }
        case .enroll where isEnrollmentOnly:
            // Nothing precedes enrollment in add/recapture flows — Close is a cancel.
            teardown()
            NotchOverlayController.shared.dismissOnboarding()
        case .enroll:
            // Camera has to stop here; `.enroll` is the only step that owns it.
            resetEnrollmentState()
            camera.stop()
            sweepWindow.dismiss()
            withAnimation(OnboardingMetrics.stepAnimation) { step = .selectCamera }
        case .password:
            // Keep completed captures so password corrections don't require re-enrollment.
            nameError = nil
            if isFaceUnlockSelected {
                withAnimation(OnboardingMetrics.stepAnimation) { step = .name }
            } else {
                pendingVoiceFeatureVector = nil
                pendingVoicePassphrase = nil
                voiceCaptureStarted = false
                voiceProgress = 0
                voiceShowCheckmark = false
                voiceError = nil
                withAnimation(OnboardingMetrics.stepAnimation) { step = .enrollVoice }
            }
        case .name where isEnrollmentOnly:
            // Nothing precedes naming in add/recapture flows — Back is a cancel.
            teardown()
            NotchOverlayController.shared.dismissOnboarding()
        case .name:
            // `.enroll` can't be resumed halfway, so backing past it discards both captures.
            resetEnrollmentState()
            pendingVoiceFeatureVector = nil
            voiceProgress = 0
            voiceShowCheckmark = false
            withAnimation(OnboardingMetrics.stepAnimation) { step = .selectCamera }
        default:
            guard let previous = step.previous else { return }
            withAnimation(OnboardingMetrics.stepAnimation) { step = previous }
            if step == .permissions {
                startPermissionsPolling()
            }
        }
    }

    /// Note `pendingName` deliberately survives — no reason to make the user retype it.
    private func resetEnrollmentState() {
        collectedSamples = []
        nameError = nil
        currentPoseIndex = 0
        capturedForCurrentPose = 0
        capturedPoses = []
        matchStreak = 0
        poseHoldStartedAt = nil
        isTooFar = false
        excessiveTurn = nil
        enrollmentComplete = false
        guideVisible = false
        cameraPreviewVisible = true
        showCheckmark = false
        passwordError = nil
    }

    private func beginEnrollment() {
        guard step == .enroll else { return }
        guideVisible = true
        cameraPreviewVisible = true
        showCheckmark = false
        poseStartedAt = .now
        captureReadyAt = .now + initialCaptureDelay
        poseHoldStartedAt = nil
        excessiveTurn = nil
        sweepWindow.present(for: self)
        Task { await camera.start() }
    }

    /// Tears down everything onboarding spun up: camera, sweep overlay,
    /// and permissions polling. Idempotent.
    func teardown() {
        stopPermissionsPolling()
        camera.stop()
        voicePipeline.stopEnrollmentCapture()
        sweepWindow.dismiss()
    }

    private(set) var voiceProgress = 0.0
    private(set) var voiceShowCheckmark = false
    private(set) var voiceError: String?
    private var pendingVoiceFeatureVector: [Float]?
    private var pendingVoicePassphrase: String?
    var voicePassphrase = ""
    private(set) var voiceCaptureStarted = false
    private(set) var isPreparingVoiceCapture = false
    private var voiceEnrollmentGeneration = 0

    // MARK: - Permissions

    private func startPermissionsPolling() {
        refreshPermissions()
        permissionsPollTask?.cancel()
        permissionsPollTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self.refreshPermissions()
            }
        }
    }

    private func stopPermissionsPolling() {
        permissionsPollTask?.cancel()
        permissionsPollTask = nil
    }

    private func refreshPermissions() {
        accessibilityGranted = KeystrokeInjector.isAccessibilityTrusted()
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: cameraPermission = .granted
        case .notDetermined: cameraPermission = .notDetermined
        default: cameraPermission = .denied
        }
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: microphonePermission = .granted
        case .notDetermined: microphonePermission = .notDetermined
        default: microphonePermission = .denied
        }
    }

    private var hasPromptedAccessibility = false

    func grantAccessibility() {
        guard !hasPromptedAccessibility else {
            openSystemSettings(pane: "Privacy_Accessibility")
            return
        }
        hasPromptedAccessibility = true
        KeystrokeInjector.promptForAccessibility()
        refreshPermissions()
    }

    func grantCamera() {
        Task {
            if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
                _ = await AVCaptureDevice.requestAccess(for: .video)
                refreshPermissions()
            } else {
                openSystemSettings(pane: "Privacy_Camera")
            }
        }
    }

    func grantMicrophone() {
        Task {
            if AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined {
                _ = await AVCaptureDevice.requestAccess(for: .audio)
                refreshPermissions()
            } else {
                openSystemSettings(pane: "Privacy_Microphone")
            }
        }
    }

    func beginVoiceEnrollment() {
        let passphrase = voicePassphrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard step == .enrollVoice, !voiceCaptureStarted, !isPreparingVoiceCapture else { return }
        guard !passphrase.isEmpty else {
            voiceError = "Enter a voice passphrase before recording."
            return
        }

        voiceEnrollmentGeneration &+= 1
        let generation = voiceEnrollmentGeneration
        isPreparingVoiceCapture = true
        voiceError = nil
        voiceProgress = 0
        voiceShowCheckmark = false
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer {
                if self.voiceEnrollmentGeneration == generation {
                    self.isPreparingVoiceCapture = false
                }
            }
            guard self.voiceEnrollmentGeneration == generation,
                  self.step == .enrollVoice
            else { return }
            var granted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
            if AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined {
                granted = await AVCaptureDevice.requestAccess(for: .audio)
            }
            guard self.voiceEnrollmentGeneration == generation,
                  self.step == .enrollVoice
            else { return }
            self.refreshPermissions()
            guard granted else {
                self.voiceError = "Microphone access is required. Enable it in System Settings > Privacy & Security > Microphone."
                return
            }

            let speechStatus: SFSpeechRecognizerAuthorizationStatus
            switch SFSpeechRecognizer.authorizationStatus() {
            case .authorized:
                speechStatus = .authorized
            case .notDetermined:
                speechStatus = await VoiceIDPipeline.requestSpeechRecognitionAuthorization()
            case .denied:
                speechStatus = .denied
            case .restricted:
                speechStatus = .restricted
            @unknown default:
                speechStatus = .denied
            }
            guard self.voiceEnrollmentGeneration == generation,
                  self.step == .enrollVoice
            else { return }
            guard speechStatus == .authorized else {
                self.voiceError = "Speech Recognition access is required to verify your passphrase. Enable it in System Settings > Privacy & Security > Speech Recognition."
                return
            }
            guard self.voiceEnrollmentGeneration == generation,
                  self.step == .enrollVoice
            else { return }

            do {
                try self.voicePipeline.startEnrollmentCapture(
                    passphrase: passphrase,
                    onProgress: { [weak self] progress in self?.voiceProgress = progress },
                    onComplete: { [weak self] vector in self?.completeVoiceEnrollment(vector) }
                )
                self.voicePassphrase = passphrase
                self.voiceCaptureStarted = true
            } catch {
                self.voiceError = "Couldn't start voice capture: \(error.localizedDescription)"
            }
        }
    }

    private func completeVoiceEnrollment(_ featureVector: [Float]) {
        if isVoiceEnrollmentOnly {
            do {
                try saveVoiceEnrollment(featureVector, name: nil, passphrase: voicePassphrase)
                GlanceSettings.shared.isVoiceUnlockEnabled = true
            } catch {
                voiceError = "Couldn't save voice profile: \(error.localizedDescription)"
                voiceCaptureStarted = false
                voiceProgress = 0
                return
            }
        } else {
            pendingVoiceFeatureVector = featureVector
            pendingVoicePassphrase = voicePassphrase
        }

        voicePipeline.stopEnrollmentCapture()
        voiceCaptureStarted = false
        voiceProgress = 1
        voiceShowCheckmark = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            guard let self, self.step == .enrollVoice else { return }
            if self.isVoiceEnrollmentOnly {
                self.teardown()
                NotchOverlayController.shared.dismissOnboarding()
            } else {
                self.navDirection = .forward
                withAnimation(OnboardingMetrics.stepAnimation) {
                    self.step = self.isFaceUnlockSelected ? .name : .password
                }
            }
        }
    }

    private func saveVoiceEnrollment(_ featureVector: [Float], name: String?, passphrase: String) throws {
        var profiles = try SecureVoiceStore.load()
        if let firstProfile = profiles.first {
            profiles[0] = VoiceProfile(
                id: firstProfile.id,
                name: name ?? firstProfile.name,
                featureVector: featureVector,
                passphrase: passphrase,
                createdAt: firstProfile.createdAt
            )
        } else {
            profiles.append(VoiceProfile(
                name: name ?? Self.defaultName,
                featureVector: featureVector,
                passphrase: passphrase
            ))
        }
        try SecureVoiceStore.save(profiles)
    }

    private func openSystemSettings(pane: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Camera selection

    /// Devices offered by the picker — refreshed when the step appears, since a camera
    /// can be plugged in after the app launched.
    private(set) var cameraDevices: [CameraDevice] = []

    func refreshCameraDevices() {
        cameraDevices = CameraDeviceCatalog.availableDevices()
    }

    /// Text shown inside the pill: the explicitly chosen device's name, or the resolved
    /// system default's name suffixed "(Default)" when nothing's been picked yet.
    var cameraSelectionLabel: String {
        if let id = GlanceSettings.shared.defaultCameraID,
           let device = cameraDevices.first(where: { $0.id == id }) {
            return device.name
        }
        guard let name = resolveDefaultCameraDevice()?.localizedName else { return "System default" }
        return "\(name) (Default)"
    }

    /// Writes the pick straight into Settings — the same `defaultCameraID` the Camera
    /// settings page and `CameraDeviceCatalog.resolvedDevice()` read — then re-checks
    /// whether the panel should follow the built-in display.
    func selectCamera(id: String?) {
        GlanceSettings.shared.defaultCameraID = id
        applyDisplayPinForCameraSelection()
    }

    /// Pins the Face Unlock panel to the MacBook's own screen while the built-in camera
    /// is selected (auto-resolved or explicitly chosen), and releases that pin otherwise
    /// so the panel returns to the user's normal (often external-monitor) screen. Only
    /// meaningful with more than one screen connected — nothing to move on just one.
    /// Called whenever the pick changes and again when the step first appears, so an
    /// untouched system-default choice that happens to resolve to the built-in camera
    /// still moves the panel.
    func applyDisplayPinForCameraSelection() {
        guard NSScreen.screens.count > 1 else { return }
        let isBuiltIn = resolveSelectedCameraDevice()?.deviceType == .builtInWideAngleCamera
        if isBuiltIn {
            guard let builtInScreen = NSScreen.screens.first(where: { $0.isBuiltIn }) else { return }
            GlanceSettings.shared.preferredDisplayID = builtInScreen.stableDisplayID
            GlanceSettings.shared.preferredDisplayName = builtInScreen.localizedName
        } else {
            GlanceSettings.shared.preferredDisplayID = nil
            GlanceSettings.shared.preferredDisplayName = nil
        }
    }

    private func resolveSelectedCameraDevice() -> AVCaptureDevice? {
        if let id = GlanceSettings.shared.defaultCameraID {
            return AVCaptureDevice(uniqueID: id)
        }
        return resolveDefaultCameraDevice()
    }

    /// Same fallback `CameraDeviceCatalog.resolvedDevice()` uses once no override applies.
    private func resolveDefaultCameraDevice() -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            ?? AVCaptureDevice.default(for: .video)
    }

    // MARK: - Guided enrollment

    private func observeFrames() {
        withObservationTracking {
            _ = camera.currentFrame
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.observeFrames()
                await self?.processEnrollFrame()
            }
        }
    }

    private func processEnrollFrame() async {
        guard step == .enroll, !enrollmentComplete, !isProcessingFrame,
              let cameraFrame = camera.currentFrame, let pose = currentPose else { return }
        isProcessingFrame = true
        defer { isProcessingFrame = false }

        let pipeline = self.pipeline
        let minimumWidth = enrollmentMinimumFaceWidth
        let image = cameraFrame.image
        let outcome = await Task.detached(priority: .userInitiated) {
            do {
                let faces = try FaceDetector.detectFaces(in: image)
                guard let face = FaceRecognitionPipeline.largestFace(in: faces) else {
                    return EnrollFrameOutcome.noFace
                }
                if Float(face.normalizedBoundingBox.width) < minimumWidth {
                    return EnrollFrameOutcome.tooFar
                }
                return EnrollFrameOutcome.ready(try pipeline.recognize(face, in: image))
            } catch {
                return EnrollFrameOutcome.noFace
            }
        }.value

        switch outcome {
        case .noFace:
            faceDetected = false
            currentYaw = nil
            currentPitch = nil
            matchStreak = 0
            poseHoldStartedAt = nil
            isTooFar = false
            excessiveTurn = nil
            return
        case .tooFar:
            faceDetected = true
            currentYaw = nil
            currentPitch = nil
            matchStreak = 0
            poseHoldStartedAt = nil
            isTooFar = true
            excessiveTurn = nil
            return
        case .ready(let result):
            guard let yaw = result.face.yaw, let pitch = result.face.pitch else {
                faceDetected = true
                currentYaw = nil
                currentPitch = nil
                matchStreak = 0
                poseHoldStartedAt = nil
                isTooFar = false
                excessiveTurn = nil
                return
            }
            faceDetected = true
            currentYaw = yaw
            currentPitch = pitch
            isTooFar = false
            excessiveTurn = excessiveTurnDirection(yaw: yaw, pitch: pitch)
            guard excessiveTurn == nil else {
                matchStreak = 0
                poseHoldStartedAt = nil
                return
            }
            await processMatchedEnrollFrame(result, yaw: yaw, pitch: pitch, pose: pose)
        }
    }

    private func processMatchedEnrollFrame(
        _ result: FaceRecognitionResult,
        yaw: Float,
        pitch: Float,
        pose: EnrollmentPose
    ) async {

        // Detection above still ran; only capture is held back until settled.
        guard ContinuousClock.now >= captureReadyAt else {
            matchStreak = 0
            poseHoldStartedAt = nil
            return
        }

        let qualityOK = result.quality.map { $0 >= qualityFloor } ?? true
        // Only a 5-point alignment is reliably canonical; a 2-point/padded-crop fallback
        // isn't accepted toward enrollment.
        let alignmentOK = result.alignmentTier == .fivePoint
        let widened = ContinuousClock.now - poseStartedAt > stallTimeout
        let poseOK = poseMatches(yaw: yaw, pitch: pitch, pose: pose, widened: widened)
        guard qualityOK, alignmentOK, !isTooFar,
              excessiveTurnDirection(yaw: yaw, pitch: pitch) == nil, poseOK else {
            matchStreak = 0
            poseHoldStartedAt = nil
            return
        }

        if poseHoldStartedAt == nil {
            poseHoldStartedAt = .now
        }
        guard ContinuousClock.now - poseHoldStartedAt! >= poseHoldDuration else { return }

        matchStreak += 1
        guard matchStreak >= requiredMatchStreak else { return }
        matchStreak = 0

        collectedSamples.append(CollectedSample(
            embedding: result.embedding,
            pose: pose,
            quality: result.quality,
            capturedAt: Date()
        ))
        capturedForCurrentPose += 1

        if capturedForCurrentPose >= samplesPerPose {
            if pose == .center {
                centerPulseTick += 1
            } else {
                capturedPoses.insert(pose)
            }
            currentPoseIndex += 1
            capturedForCurrentPose = 0
            poseStartedAt = .now
            poseHoldStartedAt = nil
            if currentPoseIndex >= EnrollmentPose.allCases.count {
                await finishEnrollment()
            }
        }
    }

    private func poseMatches(yaw: Float, pitch: Float, pose: EnrollmentPose, widened: Bool) -> Bool {
        let factor = (widened ? stallWidenFactor : 1.0) * pose.matchLeniency
        return yawMatches(yaw, band: pose.yawBand, factor: factor)
            && pitchMatches(pitch, band: pose.pitchBand, factor: factor)
    }

    private func yawMatches(_ yaw: Float, band: EnrollmentPose.YawBand, factor: Float) -> Bool {
        switch band {
        case .none: return abs(yaw) < yawCenterTolerance * factor
        case .left: return yaw > yawInnerThreshold / factor && yaw < yawOuterCap
        case .right: return yaw < -yawInnerThreshold / factor && yaw > -yawOuterCap
        }
    }

    /// Reports the dominant axis when a user has gone beyond enrollment's safe pose
    /// envelope. At these angles, Vision's embedding is unlikely to be a useful,
    /// repeatable sample, so capture is explicitly rejected before the hold timer runs.
    private func excessiveTurnDirection(yaw: Float, pitch: Float) -> ExcessiveTurn? {
        let yawOvershoot = abs(yaw) / yawOuterCap
        let pitchOvershoot = abs(pitch) / pitchOuterCap
        guard max(yawOvershoot, pitchOvershoot) >= 1 else { return nil }

        let yawExceeded = yawOvershoot >= 1
        let pitchExceeded = pitchOvershoot >= 1
        if yawExceeded, pitchExceeded {
            // Vision uses positive yaw for a left turn and negative pitch for an upward turn.
            switch (yaw > 0, pitch < 0) {
            case (true, true): return .topLeft
            case (false, true): return .topRight
            case (false, false): return .bottomRight
            case (true, false): return .bottomLeft
            }
        }

        if yawOvershoot >= pitchOvershoot {
            return yaw > 0 ? .left : .right
        }
        return pitch < 0 ? .up : .down
    }

    /// Confirmed empirically: Vision reports negative pitch for "looking up" and positive
    /// for "looking down" — the opposite of the initial guess.
    private func pitchMatches(_ pitch: Float, band: EnrollmentPose.PitchBand, factor: Float) -> Bool {
        switch band {
        case .none: return abs(pitch) < pitchCenterTolerance * factor
        case .up: return pitch < -pitchInnerThreshold / factor && pitch > -pitchOuterCap
        case .down: return pitch > pitchInnerThreshold / factor && pitch < pitchOuterCap
        }
    }

    /// Runs the camera-complete sequence (instructions fade, preview fades, checkmark
    /// draws) then auto-advances to voice capture or naming. Samples stay in memory here.
    private func finishEnrollment() async {
        enrollmentComplete = true
        sweepWindow.dismiss()
        try? await Task.sleep(for: .seconds(OnboardingMetrics.guideOverlayFadeOut))

        cameraPreviewVisible = false
        try? await Task.sleep(for: .seconds(OnboardingMetrics.previewFadeOut))

        try? await Task.sleep(for: .seconds(OnboardingMetrics.checkmarkDelay))
        showCheckmark = true

        let elapsed = OnboardingMetrics.guideOverlayFadeOut + OnboardingMetrics.previewFadeOut + OnboardingMetrics.checkmarkDelay
        let remaining = max(OnboardingMetrics.cameraCompleteToNameDelay - elapsed, 0)
        try? await Task.sleep(for: .seconds(remaining))

        camera.stop()

        navDirection = .forward
        withAnimation(OnboardingMetrics.stepAnimation) { step = .name }
    }

    // MARK: - Naming

    /// Confirms the naming step. In an enrollment-only flow the session is already
    /// unlocked, so this is also the commit point. In the full setup flow nothing can be
    /// written yet — see `finish(password:)`.
    func confirmName() {
        let trimmed = pendingName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            nameError = "Enter a name."
            return
        }
        // Skipped silently in the full setup flow, where the store is still locked and
        // `identities` is unreadable, not empty. `finish(password:)` re-checks once open.
        guard !store.nameIsTaken(trimmed, excluding: enrollmentTarget.identityID) else {
            nameError = "A face named \"\(trimmed)\" is already enrolled."
            return
        }
        nameError = nil

        guard isEnrollmentOnly else {
            navDirection = .forward
            withAnimation(OnboardingMetrics.stepAnimation) { step = .password }
            return
        }

        store.reloadIfUnlocked()
        do {
            try commitEnrollment(name: trimmed)
        } catch {
            // Realistically a session that lapsed between the entry point's Touch ID
            // prompt and now. Stay on this step rather than showing "You're all set"
            // over a save that didn't happen.
            nameError = error.localizedDescription
            return
        }
        navDirection = .forward
        withAnimation(OnboardingMetrics.stepAnimation) { step = .complete }
        scheduleCompletionDismiss()
    }

    /// The single place guided-enrollment samples are persisted. Requires an
    /// unlocked session; in the full setup flow that only exists once
    /// `finish(password:)` has called `SecureCredentialManager.unlockSession`.
    private func commitEnrollment(name: String) throws {
        let samples = collectedSamples.map {
            FaceSample(embedding: $0.embedding, pose: $0.pose.name, capturedAt: $0.capturedAt, quality: $0.quality)
        }
        try store.commitEnrollment(
            replacing: enrollmentTarget.identityID,
            name: name,
            samples: samples,
            embedder: pipeline.embedder
        )
    }

    /// Only a pre-fill for the first-run flow's naming step — never the
    /// stored name, which the user now always chooses themselves.
    static let defaultName: String = {
        let name = NSFullUserName()
        return name.isEmpty ? "Owner" : name
    }()

    // MARK: - Password

    func finish(password: String) async -> Bool {
        // The default Confirm button and the SecureField's Return handler can
        // arrive back-to-back. Keep password replacement and any enrollment
        // commit single-flight even before SwiftUI has redrawn the disabled UI.
        guard !isSavingPassword else { return false }
        let trimmed = password
        guard !trimmed.isEmpty else {
            passwordError = "Enter a password."
            return false
        }
        isSavingPassword = true
        defer { isSavingPassword = false }

        do {
            try await Task.detached(priority: .userInitiated) {
                try SecureCredentialManager.unlockSession(reason: "Set up Glance")
            }.value

            // Only now that the session key exists can samples be encrypted and saved.
            // Empty in the password-only flow, which shares this method.
            store.reloadIfUnlocked()
            if !collectedSamples.isEmpty {
                let name = pendingName.trimmingCharacters(in: .whitespacesAndNewlines)
                // The naming step couldn't run this check while the store was locked.
                guard !store.nameIsTaken(name, excluding: enrollmentTarget.identityID) else {
                    nameError = "A face named \"\(name)\" is already enrolled."
                    navDirection = .backward
                    withAnimation(OnboardingMetrics.stepAnimation) { step = .name }
                    return false
                }
                try commitEnrollment(name: name)
            }
            if let pendingVoiceFeatureVector {
                let voiceName = isFaceUnlockSelected
                    ? pendingName.trimmingCharacters(in: .whitespacesAndNewlines)
                    : nil
                guard let pendingVoicePassphrase else {
                    throw NSError(
                        domain: "OnboardingController",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "The voice passphrase is missing. Re-enroll Voice ID before finishing setup."]
                    )
                }
                try saveVoiceEnrollment(pendingVoiceFeatureVector, name: voiceName, passphrase: pendingVoicePassphrase)
                GlanceSettings.shared.isVoiceUnlockEnabled = true
            }

            try await Task.detached(priority: .userInitiated) {
                guard var bytes = trimmed.data(using: .utf8) else {
                    throw SecureCredentialError.emptyPassword
                }
                defer { bytes.resetBytes(in: 0..<bytes.count) }
                try SecureCredentialManager.savePassword(bytes)
            }.value
            passwordError = nil
            navDirection = .forward
            withAnimation(OnboardingMetrics.stepAnimation) { step = .complete }
            scheduleCompletionDismiss()
            return true
        } catch {
            passwordError = error.localizedDescription
            return false
        }
    }

    /// The "You're all set" screen has no controls — it dismisses itself, then hands off
    /// to `onFirstRunComplete` once the notch is gone, for first-run and the post-update
    /// notice alike.
    private func scheduleCompletionDismiss() {
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(OnboardingMetrics.completeScreenDismissDelay))
            guard let self else { return }
            let shouldFireCompletion = self.isFirstRunFlow || self.isPostUpdateNotice
            let onComplete = self.onFirstRunComplete
            self.teardown()
            NotchOverlayController.shared.dismissOnboarding()
            if shouldFireCompletion {
                onComplete?()
            }
        }
    }
}
