import Cocoa

private let kWarningKey = "sensitivityWarningThreshold"
private let kPrivacyOffsetKey = "sensitivityPrivacyOffset"

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let detector = PersonDetector()
    private let stateMachine = PrivacyStateMachine()
    private lazy var overlay = WarningOverlayController(session: detector.session)
    private let desktopSwitcher = DesktopSwitcher()
    private let settingsController = SettingsWindowController()
    private var statusItem: NSStatusItem!
    private var pauseMenuItem: NSMenuItem!
    private var isPaused = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        loadSettings()
        setupStatusItem()
        desktopSwitcher.requestAccessibilityPermissionIfNeeded()
        wireStateMachine()

        detector.onDetection = { [weak self] result in
            DispatchQueue.main.async {
                self?.stateMachine.update(with: result)
            }
        }
        detector.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        detector.stop()
    }

    private func loadSettings() {
        let warning = UserDefaults.standard.double(forKey: kWarningKey)
        let offset = UserDefaults.standard.double(forKey: kPrivacyOffsetKey)
        stateMachine.warningThreshold = warning > 0 ? warning : SettingsWindowController.defaultWarning
        stateMachine.privacyOffset   = offset  > 0 ? offset  : SettingsWindowController.defaultPrivacyOffset
    }

    private func wireStateMachine() {
        stateMachine.onStateChanged = { [weak self] state in
            guard let self else { return }
            switch state {
            case .safe:
                overlay.fadeOut()
            case .warning:
                break
            case .privacyMode:
                overlay.fadeOut()
                desktopSwitcher.activateSafeScreen()
            }
        }

        stateMachine.onDirectionUpdate = { [weak self] direction in
            guard let direction else { return }
            self?.overlay.showImmediately(direction: direction)
        }

        settingsController.onUpdate = { [weak self] warning, offset in
            guard let self else { return }
            stateMachine.warningThreshold = warning
            stateMachine.privacyOffset = offset
            UserDefaults.standard.set(warning, forKey: kWarningKey)
            UserDefaults.standard.set(offset, forKey: kPrivacyOffsetKey)
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        setStatusIcon(symbol: "camera.fill", tint: nil)

        pauseMenuItem = NSMenuItem(title: "일시정지", action: #selector(togglePause), keyEquivalent: "p")

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Side Mirror", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "설정...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(pauseMenuItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "종료", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func setStatusIcon(symbol: String, tint: NSColor?) {
        guard let button = statusItem.button else { return }
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(config)
        image?.isTemplate = true
        button.image = image
        button.contentTintColor = tint
        button.title = ""
        button.alphaValue = 1.0
    }

    @objc private func openSettings() {
        settingsController.show(
            warningThreshold: stateMachine.warningThreshold,
            privacyOffset: stateMachine.privacyOffset
        )
    }

    @objc private func togglePause() {
        isPaused.toggle()
        if isPaused {
            detector.stop()
            stateMachine.reset()
            overlay.fadeOut()
            pauseMenuItem.title = "다시시작"
        } else {
            detector.start()
            pauseMenuItem.title = "일시정지"
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
