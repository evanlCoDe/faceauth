//
//  PasswordSettingsPage.swift
//  glance
//

import SwiftUI

struct PasswordSettingsPage: View {
    @Bindable var pocController: POCController
    @Bindable private var settings = GlanceSettings.shared

    @State private var isUnlocking = false
    @State private var sessionError: String?
    @State private var statusMessage: String?

    /// Read from `POCController`, not a local copy — `SessionAutoLocker` can
    /// lock the session from outside this view.
    private var isSessionUnlocked: Bool { pocController.isSessionUnlocked }

    /// "No password stored" takes priority over lock state entirely, so
    /// removal doesn't fall back to an "unlock session" prompt for a
    /// session that no longer protects anything.
    private enum PageState: Equatable {
        case noPassword
        case locked
        case unlocked
    }

    private struct TrustedNetworksEditor: View {
        @Bindable var settings: GlanceSettings

        @State private var availableNetworks: [TrustedWiFiNetwork] = []
        @State private var isScanning = false
        @State private var manualSSID = ""
        @State private var currentNetwork: TrustedWiFiNetwork?
        @State private var message: String?
        @State private var messageIsError = false

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text("Only a matching Wi-Fi name and access point address can pass this check. These identifiers can be spoofed; this is not cryptographic network authentication.")
                    .font(.system(size: 11))
                    .foregroundStyle(SettingsMetrics.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)

                if settings.trustedNetworks.isEmpty {
                    Text("No trusted networks added")
                        .font(.system(size: 12))
                        .foregroundStyle(SettingsMetrics.textSecondary)
                    Text("FaceAuth will not enter your saved password until a network is added.")
                        .font(.system(size: 11))
                        .foregroundStyle(SettingsMetrics.textTertiary)
                } else {
                    VStack(spacing: 0) {
                        ForEach(settings.trustedNetworks) { network in
                            HStack(spacing: 10) {
                                Image(systemName: "wifi")
                                    .font(.system(size: 12))
                                    .foregroundStyle(SettingsMetrics.textSecondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(network.ssid)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(SettingsMetrics.textPrimary)
                                    Text(network.bssid)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(SettingsMetrics.textTertiary)
                                }
                                Spacer(minLength: 6)
                                Button {
                                    settings.trustedNetworks.removeAll { $0.id == network.id }
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .foregroundStyle(SettingsMetrics.textSecondary)
                                }
                                .buttonStyle(.plain)
                                .help("Remove \(network.ssid)")
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }

                HStack(spacing: 8) {
                    SettingsPrimaryButton(
                        title: isScanning ? "Scanning..." : "Find Wi-Fi networks",
                        isEnabled: !isScanning,
                        compact: true,
                        action: scanForNetworks
                    )
                    if let currentNetwork {
                        SettingsPrimaryButton(
                            title: "Add current",
                            isEnabled: !isConfigured(currentNetwork),
                            compact: true,
                            action: { add(currentNetwork) }
                        )
                    }
                }

                if !availableNetworks.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Available Wi-Fi")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(SettingsMetrics.textSecondary)
                        ForEach(availableNetworks) { network in
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(network.ssid)
                                        .font(.system(size: 12))
                                        .foregroundStyle(SettingsMetrics.textPrimary)
                                    Text(network.bssid)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(SettingsMetrics.textTertiary)
                                }
                                Spacer(minLength: 6)
                                Button(isConfigured(network) ? "Added" : "Add") {
                                    add(network)
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(GlanceTheme.accent)
                                .disabled(isConfigured(network))
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }

                HStack(spacing: 8) {
                    TextField("Wi-Fi network name (SSID)", text: $manualSSID)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") {
                        addManuallyEnteredSSID()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GlanceTheme.accent)
                    .disabled(manualSSID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if let message {
                    Text(message)
                        .font(.system(size: 11))
                        .foregroundStyle(messageIsError ? GlanceTheme.statusDenied : SettingsMetrics.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .onAppear {
                do {
                    currentNetwork = try TrustedNetworkManager.currentNetwork()
                } catch {
                    message = error.localizedDescription
                    messageIsError = true
                }
            }
        }

        private func scanForNetworks() {
            isScanning = true
            message = nil
            Task {
                do {
                    let networks = try await Task.detached(priority: .userInitiated) {
                        try TrustedNetworkManager.availableNetworks()
                    }.value
                    availableNetworks = networks
                    currentNetwork = try TrustedNetworkManager.currentNetwork()
                    if networks.isEmpty {
                        message = "No Wi-Fi networks were returned. You can add the connected network or enter its name while connected."
                        messageIsError = false
                    }
                } catch {
                    availableNetworks = []
                    message = "Couldn't scan Wi-Fi networks: \(error.localizedDescription). You can add the connected network manually while connected to it."
                    messageIsError = true
                }
                isScanning = false
            }
        }

        private func addManuallyEnteredSSID() {
            let enteredSSID = manualSSID.trimmingCharacters(in: .whitespacesAndNewlines)
            do {
                let current = try TrustedNetworkManager.currentNetwork()
                guard current.normalizedSSID == enteredSSID else {
                    message = "Connect to “\(enteredSSID)” first so FaceAuth can record its Wi-Fi access point address."
                    messageIsError = true
                    return
                }
                add(current)
                manualSSID = ""
            } catch {
                message = "Couldn't verify the connected Wi-Fi network: \(error.localizedDescription)"
                messageIsError = true
            }
        }

        private func add(_ network: TrustedWiFiNetwork) {
            guard !isConfigured(network) else { return }
            settings.trustedNetworks.append(network)
            message = "Added \(network.ssid)."
            messageIsError = false
        }

        private func isConfigured(_ network: TrustedWiFiNetwork) -> Bool {
            settings.trustedNetworks.contains(network)
        }
    }

    private var pageState: PageState {
        guard pocController.hasStoredPassword else { return .noPassword }
        return isSessionUnlocked ? .unlocked : .locked
    }

    var body: some View {
        ZStack(alignment: .top) {
            noPasswordState
                .opacity(pageState == .noPassword ? 1 : 0)
                // Hidden from hit-testing and accessibility while faded out.
                .allowsHitTesting(pageState == .noPassword)
                .accessibilityHidden(pageState != .noPassword)

            lockedState
                .opacity(pageState == .locked ? 1 : 0)
                .allowsHitTesting(pageState == .locked)
                .accessibilityHidden(pageState != .locked)

            unlockedState
                .opacity(pageState == .unlocked ? 1 : 0)
                .allowsHitTesting(pageState == .unlocked)
                .accessibilityHidden(pageState != .unlocked)
        }
        .animation(SettingsMetrics.stateTransitionAnimation, value: pageState)
        .onAppear { pocController.refreshCredentialStatus() }
        // The onboarding password step runs in the notch, outside this
        // view's hierarchy, so nothing else prompts a re-check once it closes.
        .onChange(of: NotchOverlayController.shared.phase) { _, newPhase in
            guard newPhase == .closed else { return }
            pocController.refreshCredentialStatus()
            FaceEnrollmentStore.shared.reloadIfUnlocked()
        }
    }

    // MARK: - No password stored

    private var noPasswordState: some View {
        SettingsEmptyStateView(
            icon: "lock.fill",
            message: "Set up a password",
            buttonTitle: "Set password",
            caption: statusMessage,
            action: { OnboardingController.startPasswordOnly() }
        )
    }

    // MARK: - Locked

    private var lockedState: some View {
        SettingsEmptyStateView(
            icon: "lock.fill",
            message: "Session locked",
            buttonTitle: isUnlocking ? "Authenticating…" : "Unlock session",
            isButtonEnabled: !isUnlocking,
            caption: sessionError,
            action: unlock
        )
    }

    // MARK: - Unlocked

    private var unlockedState: some View {
        VStack(alignment: .leading, spacing: SettingsMetrics.rowSpacing) {
            SettingsGroup {
                SettingsRowContent(title: "Password encrypted") {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(SettingsMetrics.textSecondary)
                }

                SettingsGroupDivider()

                SettingsSteppedSliderRowContent(
                    title: "Auto lock session",
                    valueLabel: settings.autoLockInterval.title,
                    index: Binding(
                        get: { settings.autoLockInterval.sliderIndex },
                        set: { settings.autoLockInterval = .from(sliderIndex: $0) }
                    ),
                    stopCount: AutoLockInterval.allCases.count
                )

                SettingsGroupDivider()

                SettingsRowContent(title: "Change password") {
                    SettingsPrimaryButton(title: "Change", compact: true) {
                        OnboardingController.startPasswordOnly()
                    }
                }

                SettingsGroupDivider()

                SettingsRowContent(title: "Remove password") {
                    HoldToConfirmButton(title: "Remove", action: removePassword)
                }
            }

            trustedNetworksCard

            if let statusMessage {
                SettingsCaption(text: statusMessage)
            }
        }
    }

    private var trustedNetworksCard: some View {
        SettingsGroup {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Trusted Networks")
                            .font(SettingsMetrics.rowFont)
                            .foregroundStyle(SettingsMetrics.textPrimary)
                        Text("Choose which Wi-Fi networks allow FaceAuth to unlock your Mac. On other networks, use Touch ID or your Mac password.")
                            .font(.system(size: 12))
                            .foregroundStyle(SettingsMetrics.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    GlanceToggle(isOn: $settings.trustedNetworksEnabled)
                }
                .padding(.horizontal, SettingsMetrics.rowHorizontalInset)
                .padding(.vertical, 12)

                if settings.trustedNetworksEnabled {
                    SettingsGroupDivider()
                    TrustedNetworksEditor(settings: settings)
                        .padding(.horizontal, SettingsMetrics.rowHorizontalInset)
                        .padding(.vertical, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(SettingsMetrics.stateTransitionAnimation, value: settings.trustedNetworksEnabled)
        }
    }

    // MARK: - Actions

    private func unlock() {
        isUnlocking = true
        sessionError = nil
        Task {
            await pocController.unlockSession()
            sessionError = pocController.sessionError
            // Face store is encrypted under the same session key, so reload
            // it now rather than leaving Your Face stuck showing "locked".
            FaceEnrollmentStore.shared.reloadIfUnlocked()
            isUnlocking = false
        }
    }

    /// Face samples must be deleted before the password/session key —
    /// `deletePassword()` clears the cached session key, and deleting the
    /// face store requires an unlocked session.
    private func removePassword() {
        do {
            FaceEnrollmentStore.shared.deleteAll()
            try SecureCredentialManager.deletePassword()
            pocController.refreshCredentialStatus()
            statusMessage = "Password and face enrollment removed."
        } catch {
            statusMessage = "Couldn't remove: \(error.localizedDescription)"
        }
    }
}
