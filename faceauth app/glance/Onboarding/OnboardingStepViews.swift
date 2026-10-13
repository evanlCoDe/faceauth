//
//  OnboardingStepViews.swift
//  glance
//
//  The screens of the notch-hosted onboarding flow. Each fills whatever panel size
//  OnboardingController reports for its step — sizing itself is the notch window's job.
//

import SwiftUI
import AppKit

// MARK: - 0. EULA

struct EULAStepView: View {
    let controller: OnboardingController
    @State private var hasDeclinedEULA = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("End User License Agreement")
                .font(GlanceTheme.Font.title)
                .foregroundStyle(GlanceTheme.textPrimary)

            Text("By selecting Accept, you agree to the FaceAuth End User License Agreement and may continue with setup.")
                .font(GlanceTheme.Font.passwordCaption)
                .foregroundStyle(GlanceTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 6)

            if hasDeclinedEULA {
                EULADeclinedState(
                    onQuit: { NSApp.terminate(nil) },
                    onAgree: { controller.acceptEULA() }
                )
            } else {
                HStack(spacing: 10) {
                    PillButton(title: "Decline", style: .secondary) {
                        hasDeclinedEULA = true
                    }
                    PillButton(title: "Accept", isDefault: true) {
                        controller.acceptEULA()
                    }
                }
            }
        }
        .onboardingContentPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(GlanceTheme.panel)
    }
}

private struct EULADeclinedState: View {
    let onQuit: () -> Void
    let onAgree: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(GlanceTheme.statusDenied)
                    Text("FaceAuth can’t continue")
                        .font(GlanceTheme.Font.rowTitle)
                        .foregroundStyle(GlanceTheme.statusDenied)
                }

                Text("You need to agree to the End User License Agreement to use FaceAuth.")
                    .font(GlanceTheme.Font.rowDetail)
                    .foregroundStyle(GlanceTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(GlanceTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(GlanceTheme.statusDenied.opacity(0.3), lineWidth: 1)
            )

            HStack(spacing: 10) {
                PillButton(title: "Quit", style: .secondary, action: onQuit)
                PillButton(title: "Agree", isDefault: true, action: onAgree)
            }
        }
    }
}

// MARK: - 0.5 Select Unlock Method

struct SelectUnlockMethodStepView: View {
    @Bindable var controller: OnboardingController

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Choose Unlock Method")
                .font(GlanceTheme.Font.title)
                .foregroundStyle(GlanceTheme.textPrimary)
                .padding(.leading, 4)

            Text("Select how you'd like to unlock your Mac:")
                .font(GlanceTheme.Font.passwordCaption)
                .foregroundStyle(GlanceTheme.textSecondary)
                .padding(.leading, 4)

            Spacer(minLength: 2)

            VStack(spacing: 8) {
                UnlockMethodRow(
                    icon: "person.fill.viewfinder",
                    title: "Face ID",
                    subtitle: "Unlock using your camera and face recognition",
                    isSelected: controller.isFaceUnlockSelected
                ) {
                    controller.isFaceUnlockSelected.toggle()
                }

                UnlockMethodRow(
                    icon: "waveform",
                    title: "Voice ID",
                    subtitle: "Unlock using your microphone and voice profile",
                    isSelected: controller.isVoiceUnlockSelected
                ) {
                    controller.isVoiceUnlockSelected.toggle()
                }
            }

            if !controller.isFaceUnlockSelected && !controller.isVoiceUnlockSelected {
                Text("Select at least one unlock method to continue.")
                    .font(GlanceTheme.Font.rowDetail)
                    .foregroundStyle(GlanceTheme.statusDenied)
                    .padding(.leading, 4)
            }

            Spacer(minLength: 2)

            HStack(spacing: 10) {
                PillButton(title: "Back", style: .secondary) {
                    controller.back()
                }
                PillButton(
                    title: "Next",
                    isEnabled: controller.isFaceUnlockSelected || controller.isVoiceUnlockSelected,
                    isDefault: true
                ) {
                    controller.advance()
                }
            }
        }
        .onboardingContentPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(GlanceTheme.panel)
    }
}

private struct UnlockMethodRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isSelected ? GlanceTheme.textPrimary : GlanceTheme.textSecondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(GlanceTheme.Font.rowTitle)
                        .foregroundStyle(GlanceTheme.textPrimary)
                    Text(subtitle)
                        .font(GlanceTheme.Font.rowDetail)
                        .foregroundStyle(GlanceTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? GlanceTheme.accent : GlanceTheme.textSecondary.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(GlanceTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? GlanceTheme.accent.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 1. Intro

struct IntroStepView: View {
    let controller: OnboardingController

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Text("FaceAuth")
                .font(GlanceTheme.Font.title)
                .foregroundStyle(GlanceTheme.textPrimary)
            Text("Face & Voice Unlock for Mac")
                .font(GlanceTheme.Font.button)
                .foregroundStyle(GlanceTheme.textSecondary)

            Spacer(minLength: 12)

            HStack {
                Spacer()
                PillButton(title: "Next") {
                    controller.advance()
                }
                Spacer()
            }
        }
        .onboardingContentPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(GlanceTheme.panel)
        .onAppear {
            controller.playIntroSweepIfNeeded()
        }
    }
}

// MARK: - 2. Permissions

struct PermissionsStepView: View {
    let controller: OnboardingController

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Permissions")
                .font(GlanceTheme.Font.title)
                .foregroundStyle(GlanceTheme.textPrimary)
                .padding(.leading, 4)

            PermissionRow(
                title: "Accessibility",
                detail: "Allow FaceAuth to unlock your Mac",
                granted: controller.accessibilityGranted
            ) { controller.grantAccessibility() }

            if controller.isFaceUnlockSelected {
                PermissionRow(
                    title: "Camera",
                    detail: "Allow FaceAuth to recognize your face",
                    granted: controller.cameraPermission == .granted
                ) { controller.grantCamera() }
            }

            if controller.isVoiceUnlockSelected {
                PermissionRow(
                    title: "Microphone",
                    detail: "Allow FaceAuth to verify your voice",
                    granted: controller.microphonePermission == .granted
                ) { controller.grantMicrophone() }
            }

            if !controller.accessibilityGranted {
                Text("If Accessibility still shows as ungranted after switching it on, quit and reopen FaceAuth. Setup will resume here.")
                    .font(.system(size: 11))
                    .foregroundStyle(GlanceTheme.textDetail)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                PillButton(title: "Back", style: .secondary) {
                    controller.back()
                }
                PillButton(title: "Next", isEnabled: controller.allPermissionsGranted) {
                    controller.advance()
                }
            }
        }
        .onboardingContentPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(GlanceTheme.panel)
    }
}

// MARK: - 3. Security notice

struct SecurityNoticeStepView: View {
    let controller: OnboardingController

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(GlanceTheme.textPrimary)
                .padding(.leading, 4)

            Text("FaceAuth is not as secure as Apple's FaceID or TouchID.")
                .font(GlanceTheme.Font.title)
                .foregroundStyle(GlanceTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 4)

            Text("It uses your Mac's standard hardware and is designed for convenience, not high-security authentication.")
                .font(GlanceTheme.Font.passwordCaption)
                .foregroundStyle(GlanceTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 4)

            Spacer(minLength: 6)

            HStack(spacing: 10) {
                if controller.isPostUpdateNotice {
                    PillButton(title: "No thanks", style: .secondary) {
                        controller.declinePostUpdateNotice()
                    }
                } else {
                    PillButton(title: "Back", style: .secondary) {
                        controller.back()
                    }
                }
                PillButton(title: "I understand", isDefault: true) {
                    controller.advance()
                }
            }
        }
        .onboardingContentPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(GlanceTheme.panel)
    }
}

// MARK: - 4. Pre set-up

struct PreSetupStepView: View {
    let controller: OnboardingController

    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .top, spacing: 2) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Set up\nAuthentication")
                        .font(GlanceTheme.Font.title)
                        .foregroundStyle(GlanceTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Follow the directions\nshown on the screen")
                        .font(GlanceTheme.Font.button)
                        .foregroundStyle(GlanceTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 4)
                Spacer(minLength: 0)
                UnlockGlyphView()
                    .frame(width: 120, height: 120)
            }
            Spacer(minLength: 4)

            HStack(spacing: 10) {
                PillButton(title: "Back", style: .secondary) {
                    controller.back()
                }
                PillButton(title: "Next") {
                    controller.advance()
                }
            }
        }
        .onboardingContentPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(GlanceTheme.panel)
    }
}

private struct UnlockGlyphView: View {
    var body: some View {
        LoopingVideoView(resourceName: "idleanimation")
    }
}

// MARK: - 5. Select camera

struct SelectCameraStepView: View {
    let controller: OnboardingController

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select camera")
                .font(GlanceTheme.Font.title)
                .foregroundStyle(GlanceTheme.textPrimary)
                .padding(.leading, 4)

            Text("Used for Face enrollment and for unlocking your Mac")
                .font(GlanceTheme.Font.passwordCaption)
                .foregroundStyle(GlanceTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 4)

            Spacer(minLength: 2)

            CameraSelectionPill(
                label: controller.cameraSelectionLabel,
                devices: controller.cameraDevices
            ) { id in
                controller.selectCamera(id: id)
            }

            Spacer(minLength: 4)

            HStack(spacing: 10) {
                PillButton(title: "Back", style: .secondary) {
                    controller.back()
                }
                PillButton(title: "Next") {
                    controller.advance()
                }
            }
        }
        .onboardingContentPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(GlanceTheme.panel)
        .onAppear {
            controller.refreshCameraDevices()
            controller.applyDisplayPinForCameraSelection()
        }
    }
}

// MARK: - 6-8. Guided enrollment (camera + tick ring + camera-complete)

struct EnrollStepView: View {
    let controller: OnboardingController
    @Environment(\.notchPanelStyle) private var style

    var body: some View {
        VStack(spacing: 0) {
            cameraCluster
                .padding(.top, cameraTopPadding)
            Spacer(minLength: 8)
            instructionLabel
                .padding(.horizontal, OnboardingMetrics.enrollInstructionHorizontalPadding)
                .padding(.bottom, OnboardingMetrics.enrollInstructionBottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            if showsCloseButton {
                EnrollmentCloseButton {
                    controller.back()
                }
                .padding(OnboardingMetrics.enrollCloseButtonEdgePadding)
            }
        }
        .background(GlanceTheme.panel)
    }

    private var showsCloseButton: Bool {
        !controller.enrollmentComplete && !controller.showCheckmark
    }

    private var cameraTopPadding: CGFloat {
        style == .pill
            ? OnboardingMetrics.enrollCameraTopPaddingPill
            : OnboardingMetrics.enrollCameraTopPaddingNotch
    }

    private var cameraCluster: some View {
        ZStack {
            EnrollmentRingView(controller: controller)

            CameraPreviewView(session: controller.camera.session, faces: [])
                .frame(
                    width: OnboardingMetrics.cameraCircleDiameter,
                    height: OnboardingMetrics.cameraCircleDiameter
                )
                .clipShape(Circle())
                .opacity(controller.cameraPreviewVisible ? 1 : 0)
                .animation(
                    .easeInOut(duration: OnboardingMetrics.previewFadeOut),
                    value: controller.cameraPreviewVisible
                )
                .overlay {
                    if controller.isTooFar && controller.cameraPreviewVisible && !controller.showCheckmark {
                        EnrollmentTooFarChevron()
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: controller.isTooFar)

            if controller.showCheckmark {
                AnimatedCheckmark(color: GlanceTheme.accent, lineWidth: 8)
                    .frame(width: 70, height: 59)
                    .transition(.opacity)
                    .padding(.top, 4)
            }
        }
        .frame(
            width: OnboardingMetrics.enrollCameraClusterDiameter,
            height: OnboardingMetrics.enrollCameraClusterDiameter
        )
    }

    private var instructionLabel: some View {
        Text(controller.enrollmentInstruction)
            .font(GlanceTheme.Font.instruction)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .id(controller.enrollmentInstruction)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: controller.enrollmentInstruction)
            .opacity(controller.guideVisible ? 1 : 0)
            .animation(
                .easeInOut(
                    duration: controller.guideVisible
                        ? OnboardingMetrics.enrollInstructionFadeIn
                        : OnboardingMetrics.enrollInstructionFadeOut
                ),
                value: controller.guideVisible
            )
    }
}

// MARK: - Voice Enrollment Step

struct VoiceEnrollStepView: View {
    @Bindable var controller: OnboardingController

    var body: some View {
        VStack(spacing: 12) {
            Text(controller.voiceShowCheckmark ? "Voice Enrolled!" : "Set up Voice ID")
                .font(GlanceTheme.Font.title)
                .foregroundStyle(GlanceTheme.textPrimary)

            ZStack {
                Circle()
                    .stroke(GlanceTheme.surface, lineWidth: 6)
                    .frame(width: 76, height: 76)

                Circle()
                    .trim(from: 0, to: CGFloat(controller.voiceProgress))
                    .stroke(GlanceTheme.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 76, height: 76)
                    .rotationEffect(.degrees(-90))

                if controller.voiceShowCheckmark {
                    AnimatedCheckmark(color: GlanceTheme.accent, lineWidth: 6)
                        .frame(width: 40, height: 32)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(GlanceTheme.textPrimary)
                        .scaleEffect(1.0 + CGFloat(controller.voicePipeline.currentAudioLevel) * 0.25)
                        .animation(.easeInOut(duration: 0.1), value: controller.voicePipeline.currentAudioLevel)
                }
            }

            Text(controller.voiceCaptureStarted
                ? "Say this passphrase clearly into your microphone."
                : (controller.isPreparingVoiceCapture
                    ? "Requesting microphone and speech recognition access..."
                    : "Choose a passphrase you'll say each time you unlock."))
                .font(GlanceTheme.Font.passwordCaption)
                .foregroundStyle(GlanceTheme.textSecondary)
                .multilineTextAlignment(.center)

            TextField("Voice passphrase", text: $controller.voicePassphrase)
                .textFieldStyle(.roundedBorder)
                .disabled(controller.isPreparingVoiceCapture || controller.voiceCaptureStarted || controller.voiceShowCheckmark)

            if !controller.voiceCaptureStarted && !controller.voiceShowCheckmark {
                PillButton(
                    title: controller.isPreparingVoiceCapture ? "Preparing..." : "Start voice capture",
                    isEnabled: !controller.isPreparingVoiceCapture
                        && !controller.voicePassphrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    isDefault: true
                ) {
                    controller.beginVoiceEnrollment()
                }
            } else {
                Text(controller.voiceShowCheckmark
                    ? "Your voice profile and passphrase are saved."
                    : (controller.voicePipeline.didRecognizePassphrase
                        ? "Passphrase recognized. Keep speaking to finish voice enrollment."
                        : "Read the passphrase shown above."))
                    .font(GlanceTheme.Font.passwordCaption)
                    .foregroundStyle(GlanceTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let voiceError = controller.voiceError {
                Text(voiceError)
                    .font(GlanceTheme.Font.passwordCaption)
                    .foregroundStyle(GlanceTheme.statusDenied)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onboardingContentPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GlanceTheme.panel)
        .overlay(alignment: .topTrailing) {
            if !controller.voiceShowCheckmark {
                EnrollmentCloseButton {
                    controller.back()
                }
                .padding(OnboardingMetrics.enrollCloseButtonEdgePadding)
            }
        }
    }
}

private struct EnrollmentCloseButton: View {
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(isHovering ? 1 : 0.8))
                .frame(
                    width: OnboardingMetrics.enrollCloseButtonSize,
                    height: OnboardingMetrics.enrollCloseButtonSize
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel("Close")
    }
}

private struct EnrollmentTooFarChevron: View {
    var body: some View {
        Image(systemName: "chevron.up.2")
            .font(.system(size: OnboardingMetrics.enrollTooFarChevronSize, weight: .semibold))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.45), radius: 6, y: 1)
            .symbolEffect(.bounce.up.byLayer, options: .repeating)
            .accessibilityHidden(true)
    }
}

// MARK: - 9. Name

struct NameStepView: View {
    @Bindable var controller: OnboardingController

    private var trimmedName: String {
        controller.pendingName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name this profile")
                .font(GlanceTheme.Font.title)
                .foregroundStyle(GlanceTheme.textPrimary)
                .padding(.leading, 4)

            Text("Used to tell enrolled profiles apart when more than one person is set up on this Mac.")
                .font(GlanceTheme.Font.passwordCaption)
                .foregroundStyle(GlanceTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 4)

            Spacer(minLength: 2)

            PillTextField(placeholder: "Enter a name...", text: $controller.pendingName, autofocus: true) {
                controller.confirmName()
            }

            if let error = controller.nameError {
                Text(error)
                    .font(GlanceTheme.Font.rowDetail)
                    .foregroundStyle(GlanceTheme.statusDenied)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                PillButton(title: "Back", style: .secondary) {
                    controller.back()
                }
                PillButton(title: controller.nameStepPrimaryTitle, isEnabled: !trimmedName.isEmpty, isDefault: true) {
                    controller.confirmName()
                }
            }
        }
        .onboardingContentPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(GlanceTheme.panel)
    }
}

// MARK: - 10. Password

struct PasswordStepView: View {
    let controller: OnboardingController

    @State private var password = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enter your password")
                .font(GlanceTheme.Font.title)
                .foregroundStyle(GlanceTheme.textPrimary)
                .padding(.leading, 4)

            Text("Your password is required to unlock your Mac. It is encrypted and securely stored on your device. FaceAuth works entirely offline, so your password never leaves your Mac.")
                .font(GlanceTheme.Font.passwordCaption)
                .foregroundStyle(GlanceTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 4)

            Spacer(minLength: 2)

            PillSecureField(placeholder: "Enter password...", text: $password, autofocus: true) {
                guard !password.isEmpty, !controller.isSavingPassword else { return }
                Task { _ = await controller.finish(password: password) }
            }

            if let error = controller.passwordError {
                Text(error)
                    .font(GlanceTheme.Font.rowDetail)
                    .foregroundStyle(GlanceTheme.statusDenied)
            }

            Spacer(minLength: 2)

            HStack(spacing: 10) {
                PillButton(title: "Back", style: .secondary) {
                    controller.back()
                }
                PillButton(
                    title: "Finish",
                    isEnabled: !password.isEmpty && !controller.isSavingPassword,
                    isDefault: true
                ) {
                    Task { _ = await controller.finish(password: password) }
                }
            }
        }
        .onboardingContentPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(GlanceTheme.panel)
    }
}

// MARK: - 11. Complete

struct CompleteStepView: View {
    var body: some View {
        HStack(spacing: 12) {
            AnimatedCheckmark(color: GlanceTheme.accent, lineWidth: 5)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text("Setup Complete")
                    .font(GlanceTheme.Font.rowTitle)
                    .foregroundStyle(GlanceTheme.textPrimary)
                Text("FaceAuth is now active")
                    .font(GlanceTheme.Font.rowDetail)
                    .foregroundStyle(GlanceTheme.textSecondary)
            }
        }
        .onboardingContentPadding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(GlanceTheme.panel)
    }
}
