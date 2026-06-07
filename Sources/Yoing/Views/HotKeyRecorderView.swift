import AppKit
import SwiftUI
import YoingCore

struct HotKeyRecorderView: NSViewRepresentable {
    @Binding var hotKey: HotKey
    var isEnabled: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> HotKeyRecorderButton {
        let button = HotKeyRecorderButton()
        button.onHotKeyChange = { hotKey in
            context.coordinator.record(hotKey)
        }
        return button
    }

    func updateNSView(_ button: HotKeyRecorderButton, context: Context) {
        context.coordinator.parent = self
        button.hotKey = hotKey
        button.isEnabled = isEnabled
    }

    final class Coordinator {
        var parent: HotKeyRecorderView

        init(_ parent: HotKeyRecorderView) {
            self.parent = parent
        }

        func record(_ hotKey: HotKey) {
            parent.hotKey = hotKey
        }
    }
}

final class HotKeyRecorderButton: NSButton {
    var hotKey = HotKey.defaultDictation {
        didSet {
            updateTitle()
        }
    }

    var onHotKeyChange: ((HotKey) -> Void)?

    private var isRecording = false {
        didSet {
            updateTitle()
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        guard isEnabled else {
            return
        }

        beginRecording()
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        let keyCode = CGKeyCode(event.keyCode)

        if isFunctionEvent(event, flags: Self.cgFlags(from: event)) {
            record(.functionOnly)
            return
        }

        guard !HotKey.isModifierKeyCode(keyCode) else {
            NSSound.beep()
            return
        }

        let hotKey = HotKey(keyCode: keyCode, modifiers: Self.cgFlags(from: event))
        guard hotKey.isValid else {
            NSSound.beep()
            return
        }

        record(hotKey)
    }

    override func flagsChanged(with event: NSEvent) {
        guard isRecording else {
            super.flagsChanged(with: event)
            return
        }

        let flags = Self.cgFlags(from: event)

        guard isFunctionEvent(event, flags: flags), flags.contains(.maskSecondaryFn) else {
            return
        }

        record(.functionOnly)
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        return super.resignFirstResponder()
    }

    private func configure() {
        bezelStyle = .rounded
        controlSize = .regular
        font = .systemFont(ofSize: NSFont.systemFontSize)
        lineBreakMode = .byTruncatingMiddle
        focusRingType = .default
        imagePosition = .noImage
        alignment = .center
        setButtonType(.momentaryPushIn)
        updateTitle()
    }

    private func beginRecording() {
        isRecording = true
        window?.makeFirstResponder(self)
    }

    private func record(_ newHotKey: HotKey) {
        isRecording = false
        hotKey = newHotKey
        onHotKeyChange?(newHotKey)
    }

    private func updateTitle() {
        title = isRecording ? "Press hotkey" : hotKey.displayName
        toolTip = isRecording ? "Press the new dictation hotkey" : "Click to record a new dictation hotkey"
    }

    private func isFunctionEvent(_ event: NSEvent, flags: CGEventFlags) -> Bool {
        CGKeyCode(event.keyCode) == HotKey.functionKeyCode || flags.contains(.maskSecondaryFn)
    }

    private static func cgFlags(from event: NSEvent) -> CGEventFlags {
        if let flags = event.cgEvent?.flags {
            return HotKey.normalizedModifiers(flags)
        }

        var flags: CGEventFlags = []
        let modifierFlags = event.modifierFlags

        if modifierFlags.contains(.capsLock) {
            flags.insert(.maskAlphaShift)
        }

        if modifierFlags.contains(.shift) {
            flags.insert(.maskShift)
        }

        if modifierFlags.contains(.control) {
            flags.insert(.maskControl)
        }

        if modifierFlags.contains(.option) {
            flags.insert(.maskAlternate)
        }

        if modifierFlags.contains(.command) {
            flags.insert(.maskCommand)
        }

        if modifierFlags.contains(.help) {
            flags.insert(.maskHelp)
        }

        if modifierFlags.contains(.function) {
            flags.insert(.maskSecondaryFn)
        }

        return HotKey.normalizedModifiers(flags)
    }
}
