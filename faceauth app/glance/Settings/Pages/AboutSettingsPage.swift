//
//  AboutSettingsPage.swift
//  glance
//

import SwiftUI
import AppKit

struct AboutSettingsPage: View {
    @Bindable var updater: UpdaterController
    let environment: AppEnvironment

    /// Secret-tap state for revealing the Debug/Face Lab sidebar section —
    /// see `AppEnvironment.isDebugSectionRevealed`. A pause over a second
    /// resets the count, so this requires 5 *consecutive* taps.
    @State private var iconTapCount = 0
    @State private var lastTapDate: Date?
    private let requiredTapCount = 5
    private let tapResetInterval: TimeInterval = 1.0

    private var versionString: String {
        "Version 1.0 Beta 1"
    }

    var body: some View {
        VStack(spacing: 2) {
            Text("FaceAuth")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(SettingsMetrics.textPrimary)
                .padding(.top, 16)
                .contentShape(Rectangle())
                .onTapGesture(perform: handleIconTap)

            Text(versionString)
                .font(.system(size: 12))
                .foregroundStyle(SettingsMetrics.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 16)

        SettingsGroup {
            SettingsActionRowContent(
                title: "Check for Updates",
                buttonTitle: "Check",
                isEnabled: updater.canCheckForUpdates
            ) {
                updater.checkForUpdates()
            }

            SettingsGroupDivider()

            SettingsRowContent(title: "Automatically check for updates") {
                GlanceToggle(isOn: $updater.automaticallyChecksForUpdates)
            }
        }
    }

    private func handleIconTap() {
        let now = Date()
        if let lastTapDate, now.timeIntervalSince(lastTapDate) > tapResetInterval {
            iconTapCount = 0
        }
        lastTapDate = now
        iconTapCount += 1

        if iconTapCount >= requiredTapCount {
            iconTapCount = 0
            environment.isDebugSectionRevealed.toggle()
        }
    }
}
