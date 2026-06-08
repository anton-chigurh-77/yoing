import CoreGraphics
import Foundation

public enum GlobalHotkeyMonitorError: LocalizedError {
    case eventTapUnavailable
    case invalidHotKey

    public var errorDescription: String? {
        switch self {
        case .eventTapUnavailable:
            return "The global hotkey monitor could not start. Grant Accessibility permission and try again."
        case .invalidHotKey:
            return "The selected hotkey is not supported."
        }
    }
}

public final class GlobalHotkeyMonitor {
    public var onPress: (() -> Void)?
    public var onRelease: (() -> Void)?

    public private(set) var hotKey: HotKey
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var hotKeyIsDown = false
    private var lastModifierFlags: CGEventFlags = []

    public init(hotKey: HotKey = .defaultDictation) {
        self.hotKey = hotKey
    }

    deinit {
        stop()
    }

    public var isRunning: Bool {
        eventTap != nil
    }

    public func updateHotKey(_ newHotKey: HotKey) throws {
        guard newHotKey.isValid else {
            throw GlobalHotkeyMonitorError.invalidHotKey
        }

        let previousHotKey = hotKey
        let wasRunning = isRunning

        if wasRunning {
            stop()
        }

        hotKey = newHotKey

        do {
            if wasRunning {
                try start()
            }
        } catch {
            hotKey = previousHotKey

            if wasRunning {
                try? start()
            }

            throw error
        }
    }

    public func start() throws {
        if isRunning {
            return
        }

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue) |
            CGEventMask(1 << CGEventType.keyUp.rawValue) |
            CGEventMask(1 << CGEventType.flagsChanged.rawValue)

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
        lastModifierFlags = []
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
        case .flagsChanged:
            return handleFlagsChanged(keyCode: keyCode, flags: event.flags, event: event)

        case .keyDown where hotKey.matchesKeyDown(keyCode: keyCode, flags: event.flags):
            if !hotKeyIsDown {
                hotKeyIsDown = true
                DispatchQueue.main.async { [weak self] in
                    self?.onPress?()
                }
            }
            return nil

        case .keyUp where hotKeyIsDown && hotKey.matchesKeyUp(keyCode: keyCode):
            hotKeyIsDown = false
            DispatchQueue.main.async { [weak self] in
                self?.onRelease?()
            }
            return nil

        default:
            return Unmanaged.passUnretained(event)
        }
    }

    private func handleFlagsChanged(
        keyCode: CGKeyCode,
        flags: CGEventFlags,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        let previousFlags = lastModifierFlags
        let currentFlags = HotKey.normalizedModifiers(flags)
        lastModifierFlags = currentFlags

        if hotKey.matchesFunctionPress(
            keyCode: keyCode,
            previousFlags: previousFlags,
            currentFlags: currentFlags
        ) {
            if !hotKeyIsDown {
                hotKeyIsDown = true
                DispatchQueue.main.async { [weak self] in
                    self?.onPress?()
                }
            }

            return nil
        }

        if hotKeyIsDown && hotKey.matchesFunctionRelease(
            keyCode: keyCode,
            previousFlags: previousFlags,
            currentFlags: currentFlags
        ) {
            hotKeyIsDown = false
            DispatchQueue.main.async { [weak self] in
                self?.onRelease?()
            }

            return nil
        }

        return Unmanaged.passUnretained(event)
    }
}
