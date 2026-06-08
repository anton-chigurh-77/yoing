import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSPopoverDelegate {
    private static let popoverWidth: CGFloat = 410

    private let appState: AppState
    private let openSettingsAction: () -> Void
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private lazy var hostingController: NSHostingController<AnyView> = NSHostingController(rootView: makeRootView())

    private var appStateCancellable: AnyCancellable?
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?
    private var appDeactivationObserver: NSObjectProtocol?

    init(appState: AppState, openSettingsAction: @escaping () -> Void) {
        self.appState = appState
        self.openSettingsAction = openSettingsAction
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        super.init()

        configureStatusItem()
        configurePopover()
        observeAppState()
    }

    func closePopover() {
        guard popover.isShown else {
            return
        }

        popover.performClose(nil)
    }

    private func configureStatusItem() {
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover(_:))
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem.button?.imagePosition = .imageOnly
        updateStatusItemImage()
    }

    private func configurePopover() {
        popover.behavior = .applicationDefined
        popover.animates = true
        popover.delegate = self
        popover.contentViewController = hostingController
    }

    private func observeAppState() {
        appStateCancellable = appState.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusItemImage()
            }
        }
    }

    private func updateStatusItemImage() {
        guard let button = statusItem.button else {
            return
        }

        let image = NSImage(
            systemSymbolName: appState.menuBarSystemImage,
            accessibilityDescription: "Yoing"
        )
        image?.isTemplate = true
        button.image = image
    }

    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else {
            return
        }

        appState.refreshSetupState()
        hostingController.rootView = makeRootView()
        hostingController.view.layoutSubtreeIfNeeded()

        let fittingSize = hostingController.view.fittingSize
        popover.contentSize = NSSize(
            width: Self.popoverWidth,
            height: max(1, fittingSize.height)
        )

        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        installEventMonitors()
    }

    private func makeRootView() -> AnyView {
        AnyView(
            YoingMenuBarView(
                appState: appState,
                openSettingsAction: { [weak self] in
                    self?.openSettingsAction()
                },
                closeAction: { [weak self] in
                    self?.closePopover()
                }
            )
            .frame(width: Self.popoverWidth)
            .fixedSize(horizontal: false, vertical: true)
        )
    }

    private func installEventMonitors() {
        removeEventMonitors()

        let mouseMask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        let eventMask = mouseMask.union(.keyDown)
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
            guard let self else {
                return event
            }

            if event.type == .keyDown, event.keyCode == 53 {
                self.closePopover()
                return nil
            }

            if event.type.isMouseDown, self.shouldClosePopover(for: event) {
                self.closePopover()
            }

            return event
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] event in
            guard event.type.isMouseDown || (event.type == .keyDown && event.keyCode == 53) else {
                return
            }

            self?.closePopover()
        }

        appDeactivationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: NSApp,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.closePopover()
            }
        }
    }

    private func removeEventMonitors() {
        if let localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
            self.localEventMonitor = nil
        }

        if let globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            self.globalEventMonitor = nil
        }

        if let appDeactivationObserver {
            NotificationCenter.default.removeObserver(appDeactivationObserver)
            self.appDeactivationObserver = nil
        }
    }

    private func shouldClosePopover(for event: NSEvent) -> Bool {
        if event.window === popover.contentViewController?.view.window {
            return false
        }

        if event.window === statusItem.button?.window {
            return false
        }

        return true
    }

    nonisolated func popoverDidClose(_ notification: Notification) {
        Task { @MainActor in
            removeEventMonitors()
        }
    }
}

private extension NSEvent.EventType {
    var isMouseDown: Bool {
        self == .leftMouseDown || self == .rightMouseDown || self == .otherMouseDown
    }
}
