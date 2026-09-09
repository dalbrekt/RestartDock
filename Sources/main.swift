import AppKit
import ServiceManagement

/// Menu bar app: left-click restarts the Dock (`killall Dock`), right-click shows a menu.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let menu = NSMenu()
    private var hud: NSPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "repeat.circle", accessibilityDescription: "Restart Dock")
            image?.isTemplate = true
            button.image = image
            button.toolTip = "Restart Dock (right-click for menu)"
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        let restartItem = menu.addItem(withTitle: "Restart Dock", action: #selector(restartDock), keyEquivalent: "r")
        restartItem.target = self
        menu.addItem(.separator())
        let loginItem = menu.addItem(withTitle: "Start at Login", action: #selector(toggleLoginItem(_:)), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(.separator())
        let quitItem = menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp

        registerLoginItemIfFirstLaunch()
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            statusItem.menu = menu
            sender.performClick(nil)
            statusItem.menu = nil   // detach so the next left-click fires the action again
        } else {
            restartDock()
        }
    }

    @objc private func restartDock() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["Dock"]
        do {
            try process.run()
            showConfirmation("Dock restarted")
        } catch {
            NSLog("RestartDock: failed to run killall Dock: \(error)")
            showConfirmation("Failed to restart Dock")
        }
    }

    /// Shows a small HUD under the status item that fades out after ~1 second.
    private func showConfirmation(_ text: String) {
        hud?.orderOut(nil)

        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .labelColor
        label.alignment = .center
        label.sizeToFit()

        let padding = NSSize(width: 16, height: 10)
        let size = NSSize(width: label.frame.width + padding.width * 2,
                          height: label.frame.height + padding.height * 2)

        let effect = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
        effect.material = .hudWindow
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 8
        effect.layer?.masksToBounds = true
        label.frame.origin = NSPoint(x: padding.width, y: padding.height)
        effect.addSubview(label)

        let panel = NSPanel(contentRect: NSRect(origin: .zero, size: size),
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        panel.contentView = effect

        // Position centred under the status item, or top-right of the main screen as a fallback.
        var origin: NSPoint
        if let buttonWindow = statusItem.button?.window {
            let f = buttonWindow.frame
            origin = NSPoint(x: f.midX - size.width / 2, y: f.minY - size.height - 6)
        } else if let screen = NSScreen.main {
            let v = screen.visibleFrame
            origin = NSPoint(x: v.maxX - size.width - 12, y: v.maxY - size.height - 12)
        } else {
            origin = .zero
        }
        panel.setFrameOrigin(origin)
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        hud = panel

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            panel.animator().alphaValue = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self, weak panel] in
            guard let panel, self?.hud === panel else { return }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.25
                panel.animator().alphaValue = 0
            }, completionHandler: {
                panel.orderOut(nil)
                if self?.hud === panel { self?.hud = nil }
            })
        }
    }

    @objc private func toggleLoginItem(_ sender: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("RestartDock: login item change failed: \(error)")
        }
        sender.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    /// Register as a login item once, on first launch. The user can turn it off from the menu.
    private func registerLoginItemIfFirstLaunch() {
        let key = "didRegisterLoginItem"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        if SMAppService.mainApp.status != .enabled {
            try? SMAppService.mainApp.register()
            menu.items.first { $0.title == "Start at Login" }?.state =
                SMAppService.mainApp.status == .enabled ? .on : .off
        }
    }
}

// `RestartDock --unregister` removes the login item and exits (used by uninstall.sh).
if CommandLine.arguments.contains("--unregister") {
    do {
        if SMAppService.mainApp.status != .notRegistered {
            try SMAppService.mainApp.unregister()
        }
        print("Login item unregistered")
        exit(0)
    } catch {
        FileHandle.standardError.write("Failed to unregister login item: \(error)\n".data(using: .utf8)!)
        exit(1)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
