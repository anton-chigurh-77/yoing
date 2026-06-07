import CoreGraphics
import Foundation

public enum GlobalHotkeyMonitorError: LocalizedError {
    case eventTapUnavailable

    public var errorDescription: String? {
        switch self {
        case .eventTapUnavailable:
            return "The global hotkey monitor could not start. Grant Accessibility permission and try again."
        }
    }
}

public final class GlobalHotkeyMonitor {
    public var onPress: (() -> Void)?
    public var onRelease: (() -> Void)?

    private let hotKey: HotKey
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var hotKeyIsDown = false

    public init(hotKey: HotKey = .defaultDictation) {
        self.hotKey = hotKey
    }

    deinit {
        stop()
    }

    public var isRunning: Bool {
        eventTap != nil
    }

    public func start() throws {
        if isRunning {
            return
        }

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue) |
            CGEventMask(1 << CGEventType.keyUp.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: Self.eventTapCallback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            throw GlobalHotkeyMonitorError.eventTapUnavailable
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            throw GlobalHotkeyMonitorError.eventTapUnavailable
        }

        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    public func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        runLoopSource = nil
        eventTap = nil
        hotKeyIsDown = false
    }

    private static let eventTapCallback: CGEventTapCallBack = { _, type, event, refcon in
        guard let refcon else {
            return Unmanaged.passUnretained(event)
        }

        let monitor = Unmanaged<GlobalHotkeyMonitor>
            .fromOpaque(refcon)
            .takeUnretainedValue()

        return monitor.handle(type: type, event: event)
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

        switch type {
        case .keyDown where matchesHotKeyDown(keyCode: keyCode, flags: event.flags):
            if !hotKeyIsDown {
                hotKeyIsDown = true
                DispatchQueue.main.async { [weak self] in
                    self?.onPress?()
                }
            }
            return nil

        case .keyUp where hotKeyIsDown && keyCode == hotKey.keyCode:
            hotKeyIsDown = false
            DispatchQueue.main.async { [weak self] in
                self?.onRelease?()
            }
            return nil

        default:
            return Unmanaged.passUnretained(event)
        }
    }

    private func matchesHotKeyDown(keyCode: CGKeyCode, flags: CGEventFlags) -> Bool {
        guard keyCode == hotKey.keyCode else {
            return false
        }

        let activeModifiers = flags.intersection(Self.modifierMask)
        return activeModifiers.intersection(hotKey.modifiers) == hotKey.modifiers
    }

    private static let modifierMask: CGEventFlags = [
        .maskAlphaShift,
        .maskShift,
        .maskControl,
        .maskAlternate,
        .maskCommand,
        .maskHelp,
        .maskSecondaryFn
    ]
}
