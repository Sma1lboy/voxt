import SwiftUI
import AppKit

extension AppDelegate {
    private var feedbackURL: URL {
        URL(string: "https://github.com/hehehai/voxt/issues/new/choose")!
    }

    func buildMenu() {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(title: AppLocalization.localizedString("Settings…"), action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let reportItem = NSMenuItem(title: AppLocalization.localizedString("Report"), action: #selector(openReportSettings), keyEquivalent: "")
        reportItem.target = self
        menu.addItem(reportItem)

        let dictionaryItem = NSMenuItem(
            title: AppLocalization.localizedString("Dictionary"),
            action: #selector(openDictionarySettings),
            keyEquivalent: ""
        )
        dictionaryItem.target = self
        menu.addItem(dictionaryItem)

        let checkUpdatesItem = NSMenuItem(
            title: AppLocalization.localizedString("Check for Updates…"),
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        checkUpdatesItem.target = self
        menu.addItem(checkUpdatesItem)

        let feedbackItem = NSMenuItem(
            title: AppLocalization.localizedString("Feedback"),
            action: #selector(openFeedbackPage),
            keyEquivalent: ""
        )
        feedbackItem.target = self
        menu.addItem(feedbackItem)

        if appUpdateManager.hasUpdate, let latestVersion = appUpdateManager.latestVersion {
            let updateInfoItem = NSMenuItem(
                title: "New version: \(latestVersion)",
                action: nil,
                keyEquivalent: ""
            )
            updateInfoItem.isEnabled = false
            menu.addItem(updateInfoItem)
        }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: AppLocalization.localizedString("Quit Voxt"), action: #selector(quit), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc private func checkForUpdates() {
        performAfterStatusMenuDismissal {
            VoxtLog.info("Manual update check triggered from menu.")
            self.appUpdateManager.checkForUpdates(source: .manual)
        }
    }

    @objc private func openFeedbackPage() {
        performAfterStatusMenuDismissal {
            VoxtLog.info("Feedback page opened from menu.")
            NSWorkspace.shared.open(self.feedbackURL)
        }
    }

    @objc private func openSettings() {
        performAfterStatusMenuDismissal {
            self.openSettingsWindow(selectTab: nil)
        }
    }

    @objc private func openReportSettings() {
        performAfterStatusMenuDismissal {
            self.openSettingsWindow(selectTab: .report)
        }
    }

    @objc private func openDictionarySettings() {
        performAfterStatusMenuDismissal {
            self.openSettingsWindow(selectTab: .dictionary)
        }
    }

    func openSettingsWindow(selectTab: SettingsTab?) {
        if let window = settingsWindowController?.window {
            if let selectTab {
                NotificationCenter.default.post(
                    name: .voxtSettingsSelectTab,
                    object: nil,
                    userInfo: ["tab": selectTab.rawValue]
                )
            }
            bringWindowToFront(window)
            return
        }

        let contentView = SettingsView(
            onIngestDictionarySuggestionsFromHistory: {
                self.startDictionaryHistorySuggestionScan()
            },
            mlxModelManager: mlxModelManager,
            customLLMManager: customLLMManager,
            historyStore: historyStore,
            dictionaryStore: dictionaryStore,
            dictionarySuggestionStore: dictionarySuggestionStore,
            appUpdateManager: appUpdateManager,
            initialTab: selectTab ?? .general
        )
        .frame(width: 760, height: 560)

        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = ""
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.toolbar = nil
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = false
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.level = .normal
        positionWindowTrafficLightButtons(window)

        let controller = NSWindowController(window: window)
        controller.shouldCascadeWindows = false
        settingsWindowController = controller
        controller.showWindow(nil)

        DispatchQueue.main.async { [weak self, weak window] in
            guard let self, let window else { return }
            window.center()
            self.positionWindowTrafficLightButtons(window)
            self.bringWindowToFront(window)
        }
    }

    private func bringWindowToFront(_ window: NSWindow) {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        positionWindowTrafficLightButtons(window)
    }

    private func performAfterStatusMenuDismissal(_ action: @escaping @MainActor () -> Void) {
        DispatchQueue.main.async {
            Task { @MainActor in
                action()
            }
        }
    }

    private func positionWindowTrafficLightButtons(_ window: NSWindow) {
        guard let closeButton = window.standardWindowButton(.closeButton),
              let miniaturizeButton = window.standardWindowButton(.miniaturizeButton),
              let zoomButton = window.standardWindowButton(.zoomButton),
              let container = closeButton.superview
        else {
            return
        }

        let leftInset: CGFloat = 22
        let topInset: CGFloat = 21
        let spacing: CGFloat = 6

        let buttonSize = closeButton.frame.size
        let y = container.bounds.height - topInset - buttonSize.height
        let closeX = leftInset
        let miniaturizeX = closeX + buttonSize.width + spacing
        let zoomX = miniaturizeX + buttonSize.width + spacing

        closeButton.translatesAutoresizingMaskIntoConstraints = true
        miniaturizeButton.translatesAutoresizingMaskIntoConstraints = true
        zoomButton.translatesAutoresizingMaskIntoConstraints = true

        closeButton.setFrameOrigin(CGPoint(x: closeX, y: y))
        miniaturizeButton.setFrameOrigin(CGPoint(x: miniaturizeX, y: y))
        zoomButton.setFrameOrigin(CGPoint(x: zoomX, y: y))
    }

    @objc private func quit() {
        VoxtLog.info("Quit requested from menu.")
        hotkeyManager.stop()
        NSApp.terminate(nil)
    }

    func prepareSettingsWindowForUpdatePresentation() {
        guard let window = settingsWindowController?.window else {
            settingsWindowPresentationState = SettingsWindowPresentationState()
            return
        }

        let shouldRestore = window.isVisible && !window.isMiniaturized
        settingsWindowPresentationState.shouldRestoreAfterUpdate = shouldRestore
        guard shouldRestore else { return }

        VoxtLog.info("Temporarily hiding settings window before presenting update UI.")
        window.orderOut(nil)
    }

    func restoreSettingsWindowAfterUpdateSessionIfNeeded() {
        guard settingsWindowPresentationState.shouldRestoreAfterUpdate else { return }
        settingsWindowPresentationState = SettingsWindowPresentationState()

        guard let window = settingsWindowController?.window else { return }
        VoxtLog.info("Restoring settings window after update UI finished.")
        bringWindowToFront(window)
    }

    func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = String(localized: "Permissions Required")
        alert.informativeText = String(localized: "Voxt needs Microphone access. If you use Direct Dictation, enable Speech Recognition in System Settings → Privacy & Security.")
        alert.addButton(withTitle: String(localized: "Open System Settings"))
        alert.addButton(withTitle: String(localized: "Quit"))
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition")!)
        }
        NSApp.terminate(nil)
    }
}
