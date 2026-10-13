//
//  YourVoiceSettingsPage.swift
//  glance
//
//  The Your Voice page in Settings. Shows voice profile status, enable toggle,
//  re-enroll action, and security details.
//

import SwiftUI

struct YourVoiceSettingsPage: View {
    let environment: AppEnvironment

    @State private var profiles: [VoiceProfile] = []
    @State private var isLocked = false
    @State private var sessionError: String?
    @State private var isUnlocking = false
    @State private var profilePendingDeletion: VoiceProfile?
    @State private var writeError: String?
    @State private var newPassphrase = ""
    @State private var loginPassword = ""
    @State private var isChangingPassphrase = false
    @State private var isAuthenticatingPassphraseChange = false
    @State private var showPassphrasePasswordPrompt = false
    @State private var passphraseChangeError: String?

    private var enrollmentFlowIsRunning: Bool {
        NotchOverlayController.shared.phase == .onboarding
    }

    private var isVoiceEnabled: Binding<Bool> {
        Binding(
            get: { GlanceSettings.shared.isVoiceUnlockEnabled },
            set: { GlanceSettings.shared.isVoiceUnlockEnabled = $0 }
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            if isLocked {
                lockedState
            } else if profiles.isEmpty {
                notEnrolledState
            } else {
                enrolledState
            }
        }
        .animation(SettingsMetrics.stateTransitionAnimation, value: isLocked)
        .onAppear { loadData() }
        .onChange(of: NotchOverlayController.shared.phase) { _, newPhase in
            guard newPhase == .closed else { return }
            loadData()
            isChangingPassphrase = false
        }
        .confirmationDialog(
            "Delete this voice profile?",
            isPresented: Binding(
                get: { profilePendingDeletion != nil },
                set: { if !$0 { profilePendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: profilePendingDeletion
        ) { profile in
            Button("Delete", role: .destructive) { delete(profile) }
            Button("Cancel", role: .cancel) { profilePendingDeletion = nil }
        } message: { profile in
            Text("\"\(profile.name)\" will stop being recognized until you enroll again.")
        }
    }

    private func loadData() {
        guard SecureCredentialManager.isSessionUnlocked else {
            isLocked = true
            profiles = []
            return
        }
        isLocked = false
        do {
            profiles = try SecureVoiceStore.load()
        } catch {
            profiles = []
        }
    }

    // MARK: - Locked State

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

    // MARK: - Not Enrolled State

    private var notEnrolledState: some View {
        SettingsEmptyStateView(
            icon: "mic.fill",
            message: "Voice enrollment",
            buttonTitle: "Set up Voice ID",
            isButtonEnabled: !enrollmentFlowIsRunning,
            action: { OnboardingController.startVoiceEnrollmentOnly() }
        )
    }

    // MARK: - Enrolled State

    private var enrolledState: some View {
        VStack(alignment: .leading, spacing: SettingsMetrics.rowSpacing) {
            voiceEncryptedCard

            passphraseChangeCard

            SettingsSectionTitle(text: "Enrolled Voice Profile")
                .padding(.bottom, -8)

            ForEach(profiles) { profile in
                VoiceProfileCard(
                    profile: profile,
                    isVoiceEnabled: isVoiceEnabled,
                    canStartFlow: !enrollmentFlowIsRunning,
                    reEnroll: { OnboardingController.startVoiceEnrollmentOnly() },
                    delete: { profilePendingDeletion = profile }
                )
            }

            if let writeError {
                SettingsCaption(text: writeError)
            }
        }
    }

    private var voiceEncryptedCard: some View {
        SettingsGroup {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("Voice encrypted")
                        .font(SettingsMetrics.rowFont)
                        .foregroundStyle(SettingsMetrics.textPrimary)
                    Spacer(minLength: 8)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(SettingsMetrics.textSecondary)
                }

                Text("Voice ID checks your encrypted voice profile and passphrase using on-device processing. Your passphrase and voice profile are encrypted under your session key.")
                    .font(.system(size: 12))
                    .foregroundStyle(SettingsMetrics.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, SettingsMetrics.rowHorizontalInset)
            .padding(.vertical, 12)
        }
    }

    private var passphraseChangeCard: some View {
        SettingsGroup {
            VStack(alignment: .leading, spacing: 10) {
                Text("Change Voice Passphrase")
                    .font(SettingsMetrics.rowFont)
                    .foregroundStyle(SettingsMetrics.textPrimary)

                TextField("New voice passphrase", text: $newPassphrase)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isChangingPassphrase || enrollmentFlowIsRunning)

                if showPassphrasePasswordPrompt {
                    SecureField("Mac login password", text: $loginPassword)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isAuthenticatingPassphraseChange)

                    HStack(spacing: 8) {
                        SettingsPrimaryButton(
                            title: isAuthenticatingPassphraseChange ? "Checking..." : "Verify & continue",
                            isEnabled: !loginPassword.isEmpty && !isAuthenticatingPassphraseChange,
                            compact: true,
                            action: authenticatePassphraseChange
                        )
                        SettingsPrimaryButton(
                            title: "Cancel",
                            isEnabled: !isAuthenticatingPassphraseChange,
                            compact: true,
                            action: cancelPassphraseChange
                        )
                    }
                } else {
                    SettingsPrimaryButton(
                        title: "Change passphrase",
                        isEnabled: !newPassphrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            && !enrollmentFlowIsRunning,
                        compact: true,
                        action: { showPassphrasePasswordPrompt = true }
                    )
                }

                if let passphraseChangeError {
                    SettingsCaption(text: passphraseChangeError)
                        .foregroundStyle(GlanceTheme.statusDenied)
                }
            }
            .padding(.horizontal, SettingsMetrics.rowHorizontalInset)
            .padding(.vertical, 12)
        }
    }

    private func authenticatePassphraseChange() {
        guard SecureCredentialManager.hasStoredPassword() else {
            passphraseChangeError = "No Mac login password is stored in FaceAuth to verify."
            return
        }

        isAuthenticatingPassphraseChange = true
        passphraseChangeError = nil
        let enteredPassword = loginPassword
        Task {
            do {
                let matches = try await Task.detached(priority: .userInitiated) {
                    var storedPassword = try SecureCredentialManager.readPassword()
                    defer { storedPassword.resetBytes(in: 0..<storedPassword.count) }

                    guard var enteredBytes = enteredPassword.data(using: .utf8) else { return false }
                    defer { enteredBytes.resetBytes(in: 0..<enteredBytes.count) }
                    guard storedPassword.count == enteredBytes.count else { return false }

                    var difference: UInt8 = 0
                    for (storedByte, enteredByte) in zip(storedPassword, enteredBytes) {
                        difference |= storedByte ^ enteredByte
                    }
                    return difference == 0
                }.value

                loginPassword = ""
                guard matches else {
                    passphraseChangeError = "That doesn't match the Mac login password stored in FaceAuth."
                    return
                }

                let passphrase = newPassphrase.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !passphrase.isEmpty else {
                    passphraseChangeError = "Enter a new voice passphrase."
                    return
                }
                isChangingPassphrase = true
                showPassphrasePasswordPrompt = false
                newPassphrase = ""
                passphraseChangeError = nil
                OnboardingController.startVoiceEnrollmentOnly(passphrase: passphrase)
            } catch {
                loginPassword = ""
                passphraseChangeError = "Couldn't verify the stored Mac login password: \(error.localizedDescription)"
            }
            isAuthenticatingPassphraseChange = false
        }
    }

    private func cancelPassphraseChange() {
        loginPassword = ""
        showPassphrasePasswordPrompt = false
        passphraseChangeError = nil
    }

    private func delete(_ profile: VoiceProfile) {
        SecureVoiceStore.deleteAll()
        profiles = []
        profilePendingDeletion = nil
    }

    private func unlock() {
        isUnlocking = true
        sessionError = nil
        Task {
            do {
                try await Task.detached(priority: .userInitiated) {
                    try SecureCredentialManager.unlockSession(reason: "Authenticate to view your enrolled voice profile")
                }.value
                loadData()
            } catch {
                sessionError = error.localizedDescription
            }
            isUnlocking = false
        }
    }
}

private struct VoiceProfileCard: View {
    let profile: VoiceProfile
    @Binding var isVoiceEnabled: Bool
    let canStartFlow: Bool
    let reEnroll: () -> Void
    let delete: () -> Void

    var body: some View {
        SettingsGroup {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Text(profile.name)
                        .font(SettingsMetrics.rowFont)
                        .foregroundStyle(SettingsMetrics.textPrimary)
                        .lineLimit(1)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(SettingsMetrics.neutralButtonFill)
                        .overlay(
                            Capsule().strokeBorder(SettingsMetrics.rowBorder, lineWidth: SettingsMetrics.rowBorderWidth)
                        )
                        .clipShape(Capsule())

                    Spacer(minLength: 8)
                    GlanceToggle(isOn: $isVoiceEnabled)
                }

                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Audio Feature Vector • 512-dim FFT")
                            .font(.system(size: 12))
                            .foregroundStyle(SettingsMetrics.textTertiary)
                        Text("Enrolled \(profile.createdAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.system(size: 11))
                            .foregroundStyle(SettingsMetrics.textTertiary)
                    }
                    Spacer(minLength: 12)
                    PillActionButton(title: "Re-enroll", action: reEnroll)
                        .disabled(!canStartFlow)
                        .opacity(canStartFlow ? 1 : 0.4)
                    PillIconButton(systemImage: "trash", action: delete)
                }
            }
            .padding(.horizontal, SettingsMetrics.rowHorizontalInset)
            .padding(.vertical, 12)
        }
    }
}

private struct PillActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SettingsMetrics.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(SettingsMetrics.neutralButtonFill)
                .overlay(
                    Capsule().strokeBorder(SettingsMetrics.rowBorder, lineWidth: SettingsMetrics.rowBorderWidth)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct PillIconButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12))
                .foregroundStyle(SettingsMetrics.textPrimary)
                .frame(width: 28, height: 28)
                .background(SettingsMetrics.neutralButtonFill)
                .overlay(
                    Circle().strokeBorder(SettingsMetrics.rowBorder, lineWidth: SettingsMetrics.rowBorderWidth)
                )
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
