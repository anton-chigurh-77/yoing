import CoreGraphics
import Foundation

public enum MicrophonePermission: String, Equatable {
    case unknown
    case granted
    case denied
    case restricted

    public var isGranted: Bool {
        self == .granted
    }
}

public struct PermissionHealth: Equatable {
    public var microphone: MicrophonePermission
    public var accessibilityTrusted: Bool

    public init(microphone: MicrophonePermission, accessibilityTrusted: Bool) {
        self.microphone = microphone
        self.accessibilityTrusted = accessibilityTrusted
    }

    public var isReady: Bool {
        microphone.isGranted && accessibilityTrusted
    }
}

public enum DictationPhase: Equatable {
    case starting
    case ready
    case blocked(String)
    case recording(Date)
    case transcribing
    case success(String)
    case failed(String)

    public var title: String {
        switch self {
        case .starting:
            return "Starting"
        case .ready:
            return "Ready"
        case .blocked:
            return "Blocked"
        case .recording:
            return "Recording"
        case .transcribing:
            return "Transcribing"
        case .success:
            return "Success"
        case .failed:
            return "Error"
        }
    }

    public var detail: String {
        switch self {
        case .starting:
            return "Checking setup"
        case .ready:
            return "Hold the hotkey to dictate"
        case .blocked(let message), .success(let message), .failed(let message):
            return message
        case .recording:
            return "Release the hotkey to finish"
        case .transcribing:
            return "Sending audio to xAI"
        }
    }
}

public struct HotKey: Equatable, Codable {
    public enum Kind: String, Codable {
        case functionOnly
        case keyCombination
    }

    public static let functionKeyCode = CGKeyCode(0x3F)

    public static let modifierMask: CGEventFlags = [
        .maskAlphaShift,
        .maskShift,
        .maskControl,
        .maskAlternate,
        .maskCommand,
        .maskHelp,
        .maskSecondaryFn
    ]

    public var kind: Kind
    public var keyCode: CGKeyCode
    public var modifiers: CGEventFlags

    public init(keyCode: CGKeyCode, modifiers: CGEventFlags) {
        kind = .keyCombination
        self.keyCode = keyCode
        self.modifiers = Self.normalizedModifiers(modifiers)
    }

    public static let functionOnly = HotKey(
        kind: .functionOnly,
        keyCode: functionKeyCode,
        modifiers: .maskSecondaryFn
    )
    public static let defaultDictation = HotKey.functionOnly

    public var isValid: Bool {
        switch kind {
        case .functionOnly:
            return keyCode == Self.functionKeyCode && modifiers.contains(.maskSecondaryFn)
        case .keyCombination:
            return !Self.isModifierKeyCode(keyCode)
        }
    }

    public var displayName: String {
        switch kind {
        case .functionOnly:
            return "Fn / Globe"
        case .keyCombination:
            let parts = Self.modifierDisplayNames(for: modifiers) + [Self.keyDisplayName(for: keyCode)]
            return parts.joined(separator: " ")
        }
    }

    public static func normalizedModifiers(_ flags: CGEventFlags) -> CGEventFlags {
        flags.intersection(modifierMask)
    }

    public static func isModifierKeyCode(_ keyCode: CGKeyCode) -> Bool {
        switch keyCode {
        case 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, functionKeyCode:
            return true
        default:
            return false
        }
    }

    public func matchesKeyDown(keyCode: CGKeyCode, flags: CGEventFlags) -> Bool {
        guard kind == .keyCombination, self.keyCode == keyCode else {
            return false
        }

        return Self.normalizedModifiers(flags) == modifiers
    }

    public func matchesKeyUp(keyCode: CGKeyCode) -> Bool {
        kind == .keyCombination && self.keyCode == keyCode
    }

    public func matchesFunctionPress(
        keyCode: CGKeyCode,
        previousFlags: CGEventFlags,
        currentFlags: CGEventFlags
    ) -> Bool {
        guard kind == .functionOnly else {
            return false
        }

        let wasDown = previousFlags.contains(.maskSecondaryFn)
        let isDown = currentFlags.contains(.maskSecondaryFn)
        return (keyCode == Self.functionKeyCode || wasDown != isDown) && !wasDown && isDown
    }

    public func matchesFunctionRelease(
        keyCode: CGKeyCode,
        previousFlags: CGEventFlags,
        currentFlags: CGEventFlags
    ) -> Bool {
        guard kind == .functionOnly else {
            return false
        }

        let wasDown = previousFlags.contains(.maskSecondaryFn)
        let isDown = currentFlags.contains(.maskSecondaryFn)
        return (keyCode == Self.functionKeyCode || wasDown != isDown) && wasDown && !isDown
    }

    public static func keyDisplayName(for keyCode: CGKeyCode) -> String {
        keyDisplayNames[keyCode] ?? "Key \(keyCode)"
    }

    private enum CodingKeys: String, CodingKey {
        case kind
        case keyCode
        case modifiers
    }

    private init(kind: Kind, keyCode: CGKeyCode, modifiers: CGEventFlags) {
        self.kind = kind
        self.keyCode = keyCode
        self.modifiers = Self.normalizedModifiers(modifiers)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)

        switch kind {
        case .functionOnly:
            self = .functionOnly
        case .keyCombination:
            let decodedKeyCode = try container.decode(UInt16.self, forKey: .keyCode)
            let decodedModifiers = try container.decode(UInt64.self, forKey: .modifiers)
            self.init(
                keyCode: CGKeyCode(decodedKeyCode),
                modifiers: CGEventFlags(rawValue: decodedModifiers)
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .kind)

        switch kind {
        case .functionOnly:
            break
        case .keyCombination:
            try container.encode(UInt16(keyCode), forKey: .keyCode)
            try container.encode(modifiers.rawValue, forKey: .modifiers)
        }
    }

    private static func modifierDisplayNames(for modifiers: CGEventFlags) -> [String] {
        let normalized = normalizedModifiers(modifiers)
        var names: [String] = []

        if normalized.contains(.maskCommand) {
            names.append("Command")
        }

        if normalized.contains(.maskControl) {
            names.append("Control")
        }

        if normalized.contains(.maskAlternate) {
            names.append("Option")
        }

        if normalized.contains(.maskShift) {
            names.append("Shift")
        }

        if normalized.contains(.maskSecondaryFn) {
            names.append("Fn")
        }

        if normalized.contains(.maskAlphaShift) {
            names.append("Caps")
        }

        if normalized.contains(.maskHelp) {
            names.append("Help")
        }

        return names
    }

    private static let keyDisplayNames: [CGKeyCode: String] = [
        0x00: "A",
        0x01: "S",
        0x02: "D",
        0x03: "F",
        0x04: "H",
        0x05: "G",
        0x06: "Z",
        0x07: "X",
        0x08: "C",
        0x09: "V",
        0x0B: "B",
        0x0C: "Q",
        0x0D: "W",
        0x0E: "E",
        0x0F: "R",
        0x10: "Y",
        0x11: "T",
        0x12: "1",
        0x13: "2",
        0x14: "3",
        0x15: "4",
        0x16: "6",
        0x17: "5",
        0x18: "=",
        0x19: "9",
        0x1A: "7",
        0x1B: "-",
        0x1C: "8",
        0x1D: "0",
        0x1E: "]",
        0x1F: "O",
        0x20: "U",
        0x21: "[",
        0x22: "I",
        0x23: "P",
        0x24: "Return",
        0x25: "L",
        0x26: "J",
        0x27: "'",
        0x28: "K",
        0x29: ";",
        0x2A: "\\",
        0x2B: ",",
        0x2C: "/",
        0x2D: "N",
        0x2E: "M",
        0x2F: ".",
        0x30: "Tab",
        0x31: "Space",
        0x32: "`",
        0x33: "Delete",
        0x35: "Escape",
        0x40: "F17",
        0x48: "Volume Up",
        0x49: "Volume Down",
        0x4A: "Mute",
        0x4F: "F18",
        0x50: "F19",
        0x5A: "F20",
        0x60: "F5",
        0x61: "F6",
        0x62: "F7",
        0x63: "F3",
        0x64: "F8",
        0x65: "F9",
        0x67: "F11",
        0x69: "F13",
        0x6A: "F16",
        0x6B: "F14",
        0x6D: "F10",
        0x6F: "F12",
        0x71: "F15",
        0x72: "Help",
        0x73: "Home",
        0x74: "Page Up",
        0x75: "Forward Delete",
        0x76: "F4",
        0x77: "End",
        0x78: "F2",
        0x79: "Page Down",
        0x7A: "F1",
        0x7B: "Left Arrow",
        0x7C: "Right Arrow",
        0x7D: "Down Arrow",
        0x7E: "Up Arrow"
    ]
}

public struct RecordedAudio: Equatable {
    public var data: Data
    public var filename: String
    public var mimeType: String
    public var duration: TimeInterval

    public init(data: Data, filename: String, mimeType: String, duration: TimeInterval) {
        self.data = data
        self.filename = filename
        self.mimeType = mimeType
        self.duration = duration
    }
}
