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
            return "Hold Option Space to dictate"
        case .blocked(let message), .success(let message), .failed(let message):
            return message
        case .recording:
            return "Release the hotkey to finish"
        case .transcribing:
            return "Sending audio to xAI"
        }
    }
}

public struct HotKey: Equatable {
    public var keyCode: CGKeyCode
    public var modifiers: CGEventFlags

    public init(keyCode: CGKeyCode, modifiers: CGEventFlags) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    public static let defaultDictation = HotKey(keyCode: 49, modifiers: .maskAlternate)

    public var displayName: String {
        if keyCode == 49 && modifiers.contains(.maskAlternate) {
            return "Option Space"
        }

        return "Custom Hotkey"
    }
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
