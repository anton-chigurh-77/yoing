import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState

        let hostingController = NSHostingController(rootView: SettingsView(appState: appState))
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Yoing Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 560, height: 360))
        window.center()

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showSettings() {
        appState.refreshSetupState()

        guard let window else {
            return
        }

        if window.isMiniaturized {
            window.deminiaturize(nil)
        }

        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }
}
