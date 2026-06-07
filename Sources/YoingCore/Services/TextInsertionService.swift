import ApplicationServices
import CoreGraphics
import Foundation

public enum TextInsertionError: LocalizedError {
    case emptyText
    case accessibilityNotTrusted
    case eventCreationFailed

    public var errorDescription: String? {
        switch self {
        case .emptyText:
            return "The transcription was empty."
        case .accessibilityNotTrusted:
            return "Accessibility permission is required before Yoing can type."
        case .eventCreationFailed:
            return "Yoing could not create keyboard events for insertion."
        }
    }
}

public final class TextInsertionService {
    public init() {}

    public func insert(_ text: String) throws {
        guard !text.isEmpty else {
            throw TextInsertionError.emptyText
        }

        guard AXIsProcessTrusted() else {
            throw TextInsertionError.accessibilityNotTrusted
        }

        let codeUnits = Array(text.utf16)
        guard !codeUnits.isEmpty else {
            throw TextInsertionError.emptyText
        }

        let source = CGEventSource(stateID: .combinedSessionState)
        source?.localEventsSuppressionInterval = 0

        for start in stride(from: 0, to: codeUnits.count, by: 20) {
            let end = min(start + 20, codeUnits.count)
            let chunk = Array(codeUnits[start..<end])

            guard
                let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
            else {
                throw TextInsertionError.eventCreationFailed
            }

            chunk.withUnsafeBufferPointer { pointer in
                keyDown.keyboardSetUnicodeString(
                    stringLength: chunk.count,
                    unicodeString: pointer.baseAddress
                )
                keyUp.keyboardSetUnicodeString(
                    stringLength: chunk.count,
                    unicodeString: pointer.baseAddress
                )
            }

            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
            usleep(1_000)
        }
    }
}
