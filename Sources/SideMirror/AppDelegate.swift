import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let detector = PersonDetector()
    private let stateMachine = PrivacyStateMachine()
    private let overlay = WarningOverlayController()
    private let desktopSwitcher = DesktopSwitcher()
    private var statusItem: NSStatusItem!
    private var pauseMenuItem: NSMenuItem!
    private var isPaused = false

    func applicationDidFinishLaunching(_ notification: Notification) {
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

    private func wireStateMachine() {
        stateMachine.onStateChanged = { [weak self] state in
            guard let self else { return }
            switch state {
            case .safe:
                overlay.fadeOut()
                setStatusIcon(symbol: "camera.fill", tint: nil)
            case .warning:
                setStatusIcon(symbol: "camera.fill", tint: .systemYellow)
            case .privacyMode:
                setStatusIcon(symbol: "camera.fill", tint: .systemRed)
                desktopSwitcher.showDesktop()
            }
        }

        stateMachine.onDirectionUpdate = { [weak self] direction in
            self?.overlay.showImmediately(direction: direction ?? .center)
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        setStatusIcon(symbol: "camera.fill", tint: nil)

        pauseMenuItem = NSMenuItem(title: "일시정지", action: #selector(togglePause), keyEquivalent: "p")

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Side Mirror", action: nil, keyEquivalent: ""))
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
        button.contentTintColor = isPaused ? NSColor.secondaryLabelColor : tint
        button.title = ""
        button.alphaValue = 1.0
    }

    @objc private func togglePause() {
        isPaused.toggle()
        if isPaused {
            detector.stop()
            stateMachine.reset()
            overlay.fadeOut()
            setStatusIcon(symbol: "camera.slash.fill", tint: nil)
            pauseMenuItem.title = "다시시작"
        } else {
            detector.start()
            setStatusIcon(symbol: "camera.fill", tint: nil)
            pauseMenuItem.title = "일시정지"
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
