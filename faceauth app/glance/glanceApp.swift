//
//
//
//
//  Created by Evan Lin on 2026-09-18.
//

import SwiftUI

@main
struct glanceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    /// Only reliable way to reopen a `Window` scene once its `NSWindow` has fully closed.
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        settingsWindow
    }

    /// Suppressed so Settings doesn't appear on launch/restore. `openWindow` is captured here, not in `onAppear`, since the
    /// window may never have appeared before the menu bar needs to open it.
    private var settingsWindow: some Scene {
        let open = openWindow
        let delegate = appDelegate
        DispatchQueue.main.async {
            delegate.bindOpenWindowAction { open(id: "settings") }
        }
        return Window("FaceAuth Settings", id: "settings") {
            SettingsWindowView(environment: appDelegate.environment)
                .onAppear {
                    delegate.bindOpenWindowAction { open(id: "settings") }
                }
        }
        .defaultSize(SettingsMetrics.windowSize)
        .windowStyle(.hiddenTitleBar)
        .defaultPosition(.center)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    /// Owns the long-lived controllers so every Settings page and the menu bar's session row share the same instances instead of
    /// each spinning up its own camera/lock-monitor (see AppEnvironment.swift). Lives here rather than as `@State` because
    /// `@NSApplicationDelegateAdaptor` constructs this delegate before the scene body runs, so it's always safe to read.
    let environment = AppEnvironment()

    /// Kept alive for the app's lifetime — a local variable would vanish (and the icon with it) once `applicationDidFinishLaunching` returns.
    private var statusItem: NSStatusItem?
    /// Held so `menuNeedsUpdate` can refresh this row in place rather than rebuilding the whole menu.
    private var sessionMenuItem: NSMenuItem?
    /// Bridges SwiftUI's `openWindow(\.settings)` action in from `glanceApp.body`, since this plain `NSObject` has no
    /// `@Environment` of its own. Bound from the scene body (not `onAppear`) so it's ready before Settings has ever shown —
    /// `NSApp.windows` stops containing the window once fully closed, so only `openWindow(id:)` can reliably re-create it.
    var openSettingsWindowAction: (() -> Void)?

    /// Reassigned on every scene rebuild so the (cheap) action never goes stale.
    func bindOpenWindowAction(_ action: @escaping () -> Void) {
        openSettingsWindowAction = action
    }

    /// Guards `environment.updater.start()` against running twice — reachable from two call sites, and Sparkle doesn't promise
    /// starting an already-started `SPUUpdater` is a safe no-op.
    private var hasStartedUpdater = false

    /// Accessory before the Dock binds this launch to a persistent tile — starting `.regular` made the pinned icon bounce and
    /// get replaced by a Recents tile the moment the Dock icon was later hidden/shown.
    func applicationWillFinishLaunching(_ notification: Notification) {
        #if DEBUG
        GlanceSettings.shared.resetToDefaults()
        #endif
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let icon = NSImage(named: "MenuBarIcon")
        icon?.isTemplate = true
        if let iconSize = icon?.size, iconSize.height > 0 {
            let menuBarHeight: CGFloat = 16
            icon?.size = NSSize(width: menuBarHeight * iconSize.width / iconSize.height, height: menuBarHeight)
        }
        item.button?.image = icon

        let menu = NSMenu()
        menu.delegate = self

        let sessionItem = NSMenuItem(title: "", action: #selector(toggleSession), keyEquivalent: "")
        sessionItem.target = self
        menu.addItem(sessionItem)
        sessionMenuItem = sessionItem

        let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettingsWindow), keyEquivalent: ",")
        settingsItem.target = self
        settingsItem.image = NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription: nil)
        menu.addItem(settingsItem)

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: nil)
        menu.addItem(quitItem)

        item.menu = menu
        statusItem = item

        updateSessionMenuItem()

        NSApp.setActivationPolicy(.accessory)

        NotificationCenter.default.addObserver(
            self, selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification, object: nil
        )

        if GlanceSettings.shared.hasCompletedOnboarding {
            if GlanceSettings.shared.hasAcknowledgedSecurityNotice {
                startUpdaterIfNeeded()
            } else {
                presentPostUpdateSecurityNotice()
            }
        } else {
            presentOnboardingGate()
        }
    }

    private func presentOnboardingGate() {
        for window in NSApp.windows where window.canBecomeMain {
            window.close()
        }
        NSApp.setActivationPolicy(.accessory)
        OnboardingController.startFlow(
            resumingAt: GlanceSettings.shared.onboardingResumeStep,
            onFirstRunComplete: { [weak self] in
                self?.revealSettingsWindow()
                self?.startUpdaterIfNeeded()
            }
        )
    }

    private func presentPostUpdateSecurityNotice() {
        for window in NSApp.windows where window.canBecomeMain {
            window.close()
        }
        NSApp.setActivationPolicy(.accessory)
        guard NotchOverlayController.shared.phase != .onboarding else { return }
        OnboardingController.startPostUpdateNotice { [weak self] in
            self?.startUpdaterIfNeeded()
        }
    }

    private func startUpdaterIfNeeded() {
        guard !hasStartedUpdater else { return }
        hasStartedUpdater = true
        environment.updater.start()
    }

    @objc private func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow, closingWindow.canBecomeMain else { return }
        guard !environment.updater.isPresentingUpdateUI else { return }
        let stillOpen = NSApp.windows.contains { $0 !== closingWindow && $0.canBecomeMain && $0.isVisible }
        guard !stillOpen else { return }
        NSApp.setActivationPolicy(.accessory)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        updateSessionMenuItem()
    }

    private func updateSessionMenuItem() {
        guard let sessionMenuItem else { return }
        let isUnlocked = environment.pocController.isSessionUnlocked
        sessionMenuItem.title = isUnlocked ? "Session Unlocked" : "Session Locked"
        sessionMenuItem.image = NSImage(
            systemSymbolName: isUnlocked ? "lock.open.fill" : "lock.fill",
            accessibilityDescription: nil
        )
    }

    @objc private func toggleSession() {
        guard !isBlockedByPostUpdateNotice else {
            presentPostUpdateSecurityNotice()
            return
        }
        if environment.pocController.isSessionUnlocked {
            environment.pocController.lockSession()
        } else {
            Task { await environment.pocController.unlockSession() }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return flag
    }

    @objc private func openSettingsWindow() {
        revealSettingsWindow()
        NSApp.activate(ignoringOtherApps: true)
    }

    private var isBlockedByPostUpdateNotice: Bool {
        GlanceSettings.shared.hasCompletedOnboarding && !GlanceSettings.shared.hasAcknowledgedSecurityNotice
    }

    private func revealSettingsWindow() {
        if isBlockedByPostUpdateNotice {
            presentPostUpdateSecurityNotice()
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        guard GlanceSettings.shared.hasCompletedOnboarding else {
            if NotchOverlayController.shared.phase != .onboarding {
                presentOnboardingGate()
            }
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        NSApp.setActivationPolicy(.regular)
        if let openSettingsWindowAction {
            openSettingsWindowAction()
        } else {
            for window in NSApp.windows where window.canBecomeMain {
                window.makeKeyAndOrderFront(nil)
            }
        }
        makeSettingsKeyAndActive()
    }

    private func makeSettingsKeyAndActive() {
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async { [weak self] in
            self?.orderSettingsFront()
            DispatchQueue.main.async {
                self?.orderSettingsFront()
            }
        }
    }

    private func orderSettingsFront() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
