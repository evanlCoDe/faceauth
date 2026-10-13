//
//  FaceUnlockCoordinator.swift
//  glance
//
//  Connects face recognition and Voice ID to the actual unlock path. Off by default; user opts in after validating accuracy in Face Lab.
//

import Foundation
import CoreGraphics
import Observation

@Observable
@MainActor
final class FaceUnlockCoordinator {
    private let pocController: POCController
    let lockMonitor = LockMonitor()
    let camera = CameraManager()
    let pipeline = FaceRecognitionPipeline()
    let voicePipeline = VoiceIDPipeline()

    /// Persisted via GlanceSettings. Setting to false cancels any in-flight scan and disarms the overlay immediately.
    var isEnabled: Bool {
        didSet {
            GlanceSettings.shared.isFaceUnlockEnabled = isEnabled
            if !isEnabled { disarmOverlay() }
        }
    }

    /// Kept independent from Face Lab's own `threshold` so tuning the debug tool never silently changes the real unlock gate.
    var matchThreshold: Float {
        didSet { GlanceSettings.shared.matchThreshold = matchThreshold }
    }
    /// Shares its setting with NotchOverlayController's scanning timeout, so the background loop stops in step with the UI collapsing.
    private var scanWindowDuration: TimeInterval {
        TimeInterval(GlanceSettings.shared.faceDetectionSeconds)
    }
    /// Requires several consecutive below-threshold frames so a single bad-angle read doesn't trigger the failure animation.
    private let wrongFaceStreakThreshold = 6
    private let voiceSilenceTimeout: TimeInterval = 5

    private(set) var statusMessage = "Idle"
    private(set) var lastOutcome: String?

    private var hasArmedForCurrentLock = false
    private var hasAutoRetriedForCurrentLock = false
    private var scanTask: Task<Void, Never>?
    private var scanGeneration = 0
    private var lastArmedAt: ContinuousClock.Instant?
    private let rearmDebounce: Duration = .seconds(2)
    private var autoRetryTask: Task<Void, Never>?
    private let headlessRetryDelay: Duration = .seconds(1)

    private var showsUI: Bool { GlanceSettings.shared.showUnlockAnimation }

    private let spaceKeyMonitor = SpaceKeyMonitor()

    init(pocController: POCController) {
        self.pocController = pocController
        self.isEnabled = GlanceSettings.shared.isFaceUnlockEnabled || GlanceSettings.shared.isVoiceUnlockEnabled
        self.matchThreshold = GlanceSettings.shared.matchThreshold
        spaceKeyMonitor.onSpaceKeyDown = { [weak self] in self?.handleSpaceKeyPress() }
        observeLockAndWakeEvents()
    }

    private func observeLockAndWakeEvents() {
        withObservationTracking {
            _ = lockMonitor.isScreenLocked
            _ = lockMonitor.wakeEventCount
            _ = lockMonitor.isSleeping
            _ = lockMonitor.eventCount
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.observeLockAndWakeEvents()
                try? await Task.sleep(nanoseconds: 300_000_000)
                self?.evaluateTrigger()
            }
        }
    }

    private func evaluateTrigger() {
        guard LockMonitor.isScreenActuallyLocked() else {
            hasArmedForCurrentLock = false
            hasAutoRetriedForCurrentLock = false
            disarmOverlay()
            return
        }
        guard !lockMonitor.isSleeping else { return }

        if lockMonitor.lastEvent == .wake, !isWithinRecentArmBurst {
            hasArmedForCurrentLock = false
        }

        updateSpaceMonitor()

        let unlockEnabled = GlanceSettings.shared.isFaceUnlockEnabled || GlanceSettings.shared.isVoiceUnlockEnabled
        guard unlockEnabled, !hasArmedForCurrentLock else { return }
        guard let signal = requiredTrigger(for: lockMonitor.lastEvent) else { return }
        guard NotchGeometry.preferredScreen() != nil else { return }

        guard SecureCredentialManager.isSessionUnlocked else {
            statusMessage = "Unlock is on, but the session is locked — authenticate once from Password settings first."
            return
        }
        guard SecureCredentialManager.hasStoredPassword() else {
            statusMessage = "Unlock is on, but no password is stored yet."
            return
        }

        let shouldAutoScan = GlanceSettings.shared.unlockTriggers.contains(signal)
        guard showsUI || shouldAutoScan else { return }

        hasArmedForCurrentLock = true
        lastArmedAt = .now
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            await self?.arm(autoScan: shouldAutoScan)
        }
    }

    private var isWithinRecentArmBurst: Bool {
        guard let lastArmedAt else { return false }
        return ContinuousClock.now - lastArmedAt < rearmDebounce
    }

    private func requiredTrigger(for event: LockEventKind?) -> UnlockTrigger? {
        switch event {
        case .wake: return .onWake
        case .screenLocked: return .onLock
        case .screenUnlocked, .willSleep, nil: return nil
        }
    }

    private func disarmOverlay() {
        scanTask?.cancel()
        scanTask = nil
        scanGeneration &+= 1
        autoRetryTask?.cancel()
        autoRetryTask = nil
        camera.stop()
        voicePipeline.stopListening()
        NotchOverlayController.shared.disarm()
        spaceKeyMonitor.stop()
    }

    private func updateSpaceMonitor() {
        let unlockEnabled = GlanceSettings.shared.isFaceUnlockEnabled || GlanceSettings.shared.isVoiceUnlockEnabled
        let shouldListen = unlockEnabled
            && GlanceSettings.shared.unlockTriggers.contains(.onSpace)
            && LockMonitor.isScreenActuallyLocked()
            && SpaceKeyMonitor.hasInputMonitoringAccess()
        if shouldListen {
            spaceKeyMonitor.start()
        } else {
            spaceKeyMonitor.stop()
        }
    }

    private func handleSpaceKeyPress() {
        let unlockEnabled = GlanceSettings.shared.isFaceUnlockEnabled || GlanceSettings.shared.isVoiceUnlockEnabled
        guard unlockEnabled,
              GlanceSettings.shared.unlockTriggers.contains(.onSpace),
              LockMonitor.isScreenActuallyLocked(),
              NotchGeometry.preferredScreen() != nil,
              SecureCredentialManager.isSessionUnlocked,
              SecureCredentialManager.hasStoredPassword()
        else { return }

        guard NotchOverlayController.shared.phase != .scanning else { return }

        guard showsUI else {
            startScanCycle()
            return
        }
        if NotchOverlayController.shared.isArmed {
            startScanCycle()
        } else {
            Task { [weak self] in await self?.arm(autoScan: true) }
        }
    }

    private func arm(autoScan: Bool) async {
        guard LockMonitor.isScreenActuallyLocked() else { return }
        guard showsUI else {
            startScanCycle()
            return
        }
        NotchOverlayController.shared.arm { [weak self] in
            self?.startScanCycle()
        }
        if autoScan {
            startScanCycle()
        }
    }

    private func startScanCycle() {
        scanTask?.cancel()
        scanGeneration &+= 1
        let generation = scanGeneration
        scanTask = Task { [weak self] in
            await self?.runScanCycle(generation: generation)
        }
    }

    private func runScanCycle(generation: Int) async {
        guard LockMonitor.isScreenActuallyLocked() else { return }

        if GlanceSettings.shared.isFaceUnlockEnabled {
            await camera.start()
        }

        defer {
            camera.stop()
            voicePipeline.stopListening()
        }

        guard generation == scanGeneration else { return }

        if GlanceSettings.shared.isVoiceUnlockEnabled {
            do {
                guard let profile = try SecureVoiceStore.load().first else {
                    throw NSError(
                        domain: "FaceUnlockCoordinator",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "No Voice ID profile is enrolled."]
                    )
                }
                guard let passphrase = profile.passphrase, !passphrase.isEmpty else {
                    throw NSError(
                        domain: "FaceUnlockCoordinator",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Re-enroll Voice ID and set a voice passphrase before using voice unlock."]
                    )
                }
                try voicePipeline.startListening(
                    passphrase: passphrase,
                    enrolledFeatureVector: profile.featureVector
                )
            } catch {
                statusMessage = error.localizedDescription
                return
            }
        }

        if GlanceSettings.shared.isFaceUnlockEnabled, let error = camera.errorMessage {
            statusMessage = error
            return
        }

        let showsUI = self.showsUI
        if showsUI {
            NotchOverlayController.shared.beginScanning(timeout: GlanceSettings.shared.isVoiceUnlockEnabled
                ? nil
                : .seconds(GlanceSettings.shared.faceDetectionSeconds),
                media: GlanceSettings.shared.isVoiceUnlockEnabled && !GlanceSettings.shared.isFaceUnlockEnabled
                    ? .voiceListening
                    : .idle)
        }
        statusMessage = GlanceSettings.shared.isVoiceUnlockEnabled ? "Listening for voice / face..." : "Looking for your face…"

        let outcome = await observeScanWindow(
            deadline: GlanceSettings.shared.isVoiceUnlockEnabled
                ? nil
                : Date().addingTimeInterval(scanWindowDuration),
            requireOverlayScanning: showsUI
        )

        guard generation == scanGeneration else { return }

        switch outcome {
        case .matched:
            if showsUI {
                NotchOverlayController.shared.finish(success: true)
            }
        case .consistentlyWrongFace:
            statusMessage = "Authentication failed."
            if showsUI {
                NotchOverlayController.shared.finish(success: false)
                statusMessage = "Authentication failed — hover the notch to try again."
                scheduleAutoRetryIfEnabled(after: NotchOverlayController.shared.failureHoldDuration)
            } else {
                scheduleAutoRetryIfEnabled(after: headlessRetryDelay)
            }
        case .spoofSuspected:
            statusMessage = "Couldn't confirm identity."
            if showsUI {
                NotchOverlayController.shared.finish(success: false)
                statusMessage = "Couldn't confirm identity — hover the notch to try again."
                scheduleAutoRetryIfEnabled(after: NotchOverlayController.shared.failureHoldDuration)
            } else {
                scheduleAutoRetryIfEnabled(after: headlessRetryDelay)
            }
        case .unlockFailed:
            if showsUI {
                NotchOverlayController.shared.finish(success: false)
                statusMessage += " — hover the notch to try again."
            }
        case .voiceRejected:
            statusMessage = "Voice passphrase or voice profile didn't match — hover the notch to try again."
            if showsUI {
                NotchOverlayController.shared.finish(success: false)
            }
        case .noResolution:
            statusMessage = "No match detected."
            if showsUI {
                if GlanceSettings.shared.isVoiceUnlockEnabled {
                    statusMessage = "Listening stopped after five seconds of silence — hover the notch to try again."
                    await NotchOverlayController.shared.collapse()
                } else {
                    statusMessage = "No match detected — hover the notch to try again."
                }
                scheduleAutoRetryIfEnabled(after: NotchOverlayController.shared.collapseAnimationDuration)
            } else {
                scheduleAutoRetryIfEnabled(after: headlessRetryDelay)
            }
        }
    }

    private func scheduleAutoRetryIfEnabled(after delay: Duration) {
        guard GlanceSettings.shared.autoRetryOnce, !hasAutoRetriedForCurrentLock else { return }
        hasAutoRetriedForCurrentLock = true
        autoRetryTask?.cancel()
        autoRetryTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self else { return }
            let unlockEnabled = GlanceSettings.shared.isFaceUnlockEnabled || GlanceSettings.shared.isVoiceUnlockEnabled
            guard LockMonitor.isScreenActuallyLocked(), unlockEnabled else { return }
            if self.showsUI {
                guard NotchOverlayController.shared.phase == .closed else { return }
            }
            self.startScanCycle()
        }
    }

    private enum ScanOutcome {
        case matched
        case unlockFailed
        case voiceRejected
        case consistentlyWrongFace
        case spoofSuspected
        case noResolution
    }

    private func submitPasswordAndConfirmUnlock() async -> Bool {
        guard await pocController.injectStoredPassword(requireAuthoritativeLock: true) else {
            statusMessage = pocController.statusMessage
            return false
        }

        for _ in 0..<30 {
            if !LockMonitor.isScreenActuallyLocked() {
                return true
            }
            try? await Task.sleep(for: .milliseconds(100))
        }

        statusMessage = "Password was submitted, but the Mac stayed locked. Check the saved login password."
        return false
    }

    private func observeScanWindow(deadline: Date?, requireOverlayScanning: Bool) async -> ScanOutcome {
        let livenessEnabled = GlanceSettings.shared.livenessChecksEnabled
        let faceEnabled = GlanceSettings.shared.isFaceUnlockEnabled
        let voiceEnabled = GlanceSettings.shared.isVoiceUnlockEnabled

        let liveness = LivenessAnalyzer()
        liveness.modeProvider = { GlanceSettings.shared.livenessMode }
        var consecutiveWrongFaceFrames = 0
        var readyMatch: ScoredIdentity?
        var livenessConfirmed = !livenessEnabled
        var lastFaceBoundingBox: CGRect?
        var lastProcessedFrameID: UInt64?

        while (deadline.map { Date() < $0 } ?? true), !Task.isCancelled,
              !requireOverlayScanning || NotchOverlayController.shared.phase == .scanning {
            guard LockMonitor.isScreenActuallyLocked() else { return .noResolution }

            if voiceEnabled,
               Date().timeIntervalSince(voicePipeline.lastSoundAt) >= voiceSilenceTimeout {
                return voicePipeline.didDetectSpeech ? .voiceRejected : .noResolution
            }

            // Check Voice ID match
            if voiceEnabled && voicePipeline.isVoiceVerified {
                statusMessage = "Voice ID Verified — unlocking…"
                lastOutcome = "Voice ID Verified"
                return await submitPasswordAndConfirmUnlock() ? .matched : .unlockFailed
            }

            if faceEnabled {
                guard let frame = camera.currentFrame, frame.id != lastProcessedFrameID else {
                    try? await Task.sleep(nanoseconds: 20_000_000)
                    continue
                }
                lastProcessedFrameID = frame.id

                let pipeline = self.pipeline
                let previousBoundingBox = lastFaceBoundingBox
                let outcome = await Task.detached(priority: .userInitiated) { () -> (FaceRecognitionResult, LivenessFrame)? in
                    guard let result = try? pipeline.recognize(in: frame.image, preferNear: previousBoundingBox) else { return nil }
                    let faceCrop = CameraManager.renderCrop(from: frame, imageRect: result.face.boundingBox)
                    return (result, LivenessFeatureExtractor.extract(from: result, frame: frame.image, faceCrop: faceCrop))
                }.value

                guard let (result, livenessFrame) = outcome else {
                    consecutiveWrongFaceFrames = 0
                    lastFaceBoundingBox = nil
                    try? await Task.sleep(nanoseconds: 20_000_000)
                    continue
                }
                lastFaceBoundingBox = result.face.normalizedBoundingBox

                var confirmingCue: LivenessCue?
                if livenessEnabled {
                    let snapshot = liveness.observe(livenessFrame)
                    switch snapshot.decision {
                    case .denied:
                        lastOutcome = snapshot.decision.denialReason
                        if !voiceEnabled {
                            return .spoofSuspected
                        }
                    case .confirmed(let cue):
                        livenessConfirmed = true
                        confirmingCue = cue
                    case .pending:
                        break
                    }
                }

                let scored = pipeline.score(result.embedding, against: FaceEnrollmentStore.shared.activeIdentities)
                let matched = pipeline.bestMatch(in: scored, threshold: matchThreshold)

                if let matched {
                    consecutiveWrongFaceFrames = 0
                    readyMatch = matched
                } else {
                    readyMatch = nil
                    consecutiveWrongFaceFrames += 1
                    if consecutiveWrongFaceFrames >= wrongFaceStreakThreshold && !voiceEnabled {
                        return .consistentlyWrongFace
                    }
                }

                if let readyMatch, livenessConfirmed {
                    statusMessage = "Recognized — unlocking…"
                    let livenessNote = livenessEnabled
                        ? (confirmingCue.map { "live via \($0.title)" } ?? "liveness clear")
                        : "liveness off"
                    lastOutcome = "Matched \(readyMatch.identity.name) at \(String(format: "%.3f", readyMatch.centroidSimilarity)), \(livenessNote)."
                    return await submitPasswordAndConfirmUnlock() ? .matched : .unlockFailed
                }
            } else {
                try? await Task.sleep(nanoseconds: 30_000_000)
            }
        }

        return .noResolution
    }
}
