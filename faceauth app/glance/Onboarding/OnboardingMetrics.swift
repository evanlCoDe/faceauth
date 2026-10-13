//
//  OnboardingMetrics.swift
//  glance
//
//  Onboarding's layout numbers, centralized so panel-fit tuning happens in
//  one place instead of being scattered across the step views.
//

import SwiftUI

enum OnboardingMetrics {
    /// Shared spring for both the notch panel's resize and the step content's
    /// scroll+blur transition, so the two always move together.
    static let stepAnimation = Animation.spring(response: 0.42, dampingFraction: 0.8)
    /// Wait for `stepAnimation` to settle before focusing a text field — focusing during
    /// the spring is a no-op since the field isn't in a key window yet.
    static let fieldAutofocusDelay: Double = 0.48

    // MARK: - Panel size — EDIT HERE
    //
    // `panelWidth` is shared by every step except `.enroll`; widths are not split per
    // style, but height is fully independent per step and per style.

    /// Width used by every step except `.enroll`.
    static let panelWidth: CGFloat = 380

    /// The camera/enrollment step's width — deliberately independent of `panelWidth`.
    static let enrollPanelWidth: CGFloat = 320

    static let notchEULAHeight: CGFloat = 338
    static let pillEULAHeight: CGFloat = 320
    static let notchSelectUnlockMethodHeight: CGFloat = 298
    static let pillSelectUnlockMethodHeight: CGFloat = 275
    static let notchIntroHeight: CGFloat = 195
    static let pillIntroHeight: CGFloat = 185
    static let notchPermissionsHeight: CGFloat = 350
    static let pillPermissionsHeight: CGFloat = 327
    static let notchSecurityNoticeHeight: CGFloat = 325
    static let pillSecurityNoticeHeight: CGFloat = 305
    static let notchPreSetupHeight: CGFloat = 250
    static let pillPreSetupHeight: CGFloat = 230
    static let notchSelectCameraHeight: CGFloat = 258
    static let pillSelectCameraHeight: CGFloat = 238
    static let notchEnrollHeight: CGFloat = 375
    static let pillEnrollHeight: CGFloat = 360
    static let notchEnrollVoiceHeight: CGFloat = 440
    static let pillEnrollVoiceHeight: CGFloat = 420
    static let notchNameHeight: CGFloat = 260
    static let pillNameHeight: CGFloat = 240
    static let notchPasswordHeight: CGFloat = 290
    static let pillPasswordHeight: CGFloat = 270
    static let notchCompleteHeight: CGFloat = 115
    static let pillCompleteHeight: CGFloat = 105

    static func panelHeight(for step: OnboardingStep, style: NotchPanelStyle) -> CGFloat {
        switch (step, style) {
        case (.eula, .notch): return notchEULAHeight
        case (.eula, .pill): return pillEULAHeight
        case (.selectUnlockMethod, .notch): return notchSelectUnlockMethodHeight
        case (.selectUnlockMethod, .pill): return pillSelectUnlockMethodHeight
        case (.intro, .notch): return notchIntroHeight
        case (.intro, .pill): return pillIntroHeight
        case (.permissions, .notch): return notchPermissionsHeight
        case (.permissions, .pill): return pillPermissionsHeight
        case (.securityNotice, .notch): return notchSecurityNoticeHeight
        case (.securityNotice, .pill): return pillSecurityNoticeHeight
        case (.preSetup, .notch): return notchPreSetupHeight
        case (.preSetup, .pill): return pillPreSetupHeight
        case (.selectCamera, .notch): return notchSelectCameraHeight
        case (.selectCamera, .pill): return pillSelectCameraHeight
        case (.enroll, .notch): return notchEnrollHeight
        case (.enroll, .pill): return pillEnrollHeight
        case (.enrollVoice, .notch): return notchEnrollVoiceHeight
        case (.enrollVoice, .pill): return pillEnrollVoiceHeight
        case (.name, .notch): return notchNameHeight
        case (.name, .pill): return pillNameHeight
        case (.password, .notch): return notchPasswordHeight
        case (.password, .pill): return pillPasswordHeight
        case (.complete, .notch): return notchCompleteHeight
        case (.complete, .pill): return pillCompleteHeight
        }
    }

    static func panelSize(for step: OnboardingStep, style: NotchPanelStyle) -> CGSize {
        let width = (step == .enroll || step == .enrollVoice) ? enrollPanelWidth : panelWidth
        return CGSize(width: width, height: panelHeight(for: step, style: style))
    }

    static func panelBottomRadius(for step: OnboardingStep) -> CGFloat {
        switch step {
        case .enroll, .enrollVoice: return 51.5
        default: return 55
        }
    }

    /// The envelope the fixed notch window itself must be sized to fit — see
    /// `NotchGeometry.windowSize(for:)`.
    static let maxPanelWidth: CGFloat = max(panelWidth, enrollPanelWidth)

    static func maxPanelHeight(for style: NotchPanelStyle) -> CGFloat {
        switch style {
        case .notch:
            return [
                notchEULAHeight, notchSelectUnlockMethodHeight, notchIntroHeight, notchPermissionsHeight, notchSecurityNoticeHeight, notchPreSetupHeight,
                notchSelectCameraHeight, notchEnrollHeight, notchEnrollVoiceHeight, notchNameHeight, notchPasswordHeight, notchCompleteHeight,
            ].max() ?? notchEnrollHeight
        case .pill:
            return [
                pillEULAHeight, pillSelectUnlockMethodHeight, pillIntroHeight, pillPermissionsHeight, pillSecurityNoticeHeight, pillPreSetupHeight,
                pillSelectCameraHeight, pillEnrollHeight, pillEnrollVoiceHeight, pillNameHeight, pillPasswordHeight, pillCompleteHeight,
            ].max() ?? pillEnrollHeight
        }
    }

    // MARK: - Content insets, per style — EDIT HERE

    static let titleTopInset: CGFloat = 78
    static let pillTitleTopInset: CGFloat = 42

    static let notchContentLeadingInset: CGFloat = 28
    static let notchContentTrailingInset: CGFloat = 28
    static let notchContentBottomInset: CGFloat = 40

    static let pillContentLeadingInset: CGFloat = 30
    static let pillContentTrailingInset: CGFloat = 30
    static let pillContentBottomInset: CGFloat = 36

    static func titleTopInset(for style: NotchPanelStyle) -> CGFloat {
        style == .pill ? pillTitleTopInset : titleTopInset
    }

    static func contentLeadingInset(for style: NotchPanelStyle) -> CGFloat {
        style == .pill ? pillContentLeadingInset : notchContentLeadingInset
    }

    static func contentTrailingInset(for style: NotchPanelStyle) -> CGFloat {
        style == .pill ? pillContentTrailingInset : notchContentTrailingInset
    }

    static func contentBottomInset(for style: NotchPanelStyle) -> CGFloat {
        style == .pill ? pillContentBottomInset : notchContentBottomInset
    }

    // MARK: - Shared control geometry

    static let controlHorizontalPadding: CGFloat = 24

    static let pillButtonHeight: CGFloat = 38
    static let pillButtonRadius: CGFloat = 17
    static let primaryButtonWidth: CGFloat = 160

    static let permissionRowHeight: CGFloat = 44
    static let grantButtonSize = CGSize(width: 60, height: 26)
    static let statusDotSize: CGFloat = 16

    // MARK: - Camera / tick ring

    static let cameraCircleDiameter: CGFloat = 185
    static let tickRingOuterDiameter: CGFloat = 200

    static let tickCount = 80
    static let ticksPerSector = 10
    static let turnIndicatorTickSpan = 6
    static let turnIndicatorLengthBoost: CGFloat = 5
    static let tickLengthUnlit: CGFloat = 12
    static let tickLengthLit: CGFloat = 20
    static let tickWidth: CGFloat = 2.4
    static let completionRingWidth: CGFloat = 14
    static let completionRingRadiusInset: CGFloat = 8
    static var tickWidthComplete: CGFloat {
        2 * .pi * (tickRingOuterDiameter / 2) / CGFloat(tickCount) * 1.2
    }
    static let tickStagger: Double = 0.008

    static var enrollCameraClusterDiameter: CGFloat {
        tickRingOuterDiameter + tickLengthLit * 2
    }

    // MARK: - Enrollment camera-complete sequence timings (seconds)

    static let guideOverlayFadeOut: Double = 0.35
    static let previewFadeOut: Double = 0.4
    static let checkmarkDelay: Double = 0.2
    static let checkmarkDrawDuration: Double = 0.28
    static let cameraCompleteToNameDelay: Double = 3.0
    static let completeScreenDismissDelay: Double = 3.0

    // MARK: - In-panel enrollment chrome

    static let enrollInstructionBottomPadding: CGFloat = 30
    static let enrollInstructionHorizontalPadding: CGFloat = 20
    static let enrollCameraTopPaddingNotch: CGFloat = 68
    static let enrollCameraTopPaddingPill: CGFloat = 40

    static let enrollCloseButtonSize: CGFloat = 28
    static let enrollCloseButtonEdgePadding: CGFloat = 18

    static let enrollTooFarChevronSize: CGFloat = 32
    static let enrollInstructionFadeIn: Double = 0.3
    static let enrollInstructionFadeOut: Double = 0.35

    // MARK: - Enrollment direction sweep

    static let sweepLoopGap: Double = 1
    static let sweepMasterOpacity: Double = 0.6
    static let sweepFadeIn: Double = 0.5
    static let sweepFadeOut: Double = 0.35
    static let sweepDirectionCrossfade: Double = 0.25
    static let sweepPoseDelay: Double = 0.36

    static let introSweepAutoDismissDelay: Double = 1.6
}

extension View {
    func onboardingContentPadding() -> some View {
        modifier(OnboardingContentPadding())
    }

    func onboardingContentHorizontalPadding() -> some View {
        modifier(OnboardingContentHorizontalPadding())
    }
}

private struct OnboardingContentHorizontalPadding: ViewModifier {
    @Environment(\.notchPanelStyle) private var style

    func body(content: Content) -> some View {
        content
            .padding(.leading, OnboardingMetrics.contentLeadingInset(for: style))
            .padding(.trailing, OnboardingMetrics.contentTrailingInset(for: style))
    }
}

private struct OnboardingContentPadding: ViewModifier {
    @Environment(\.notchPanelStyle) private var style

    func body(content: Content) -> some View {
        content
            .onboardingContentHorizontalPadding()
            .padding(.top, OnboardingMetrics.titleTopInset(for: style))
            .padding(.bottom, OnboardingMetrics.contentBottomInset(for: style))
    }
}
