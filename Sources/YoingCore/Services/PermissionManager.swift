import AppKit
import ApplicationServices
import AVFoundation
import Foundation

public final class PermissionManager {
    public init() {}

    public func currentHealth() -> PermissionHealth {
        PermissionHealth(
            microphone: microphonePermission(),
            accessibilityTrusted: AXIsProcessTrusted()
        )
    }

    public func requestMicrophonePermission() async -> MicrophonePermission {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { _ in
                continuation.resume(returning: self.microphonePermission())
            }
        }
    }

    public func promptForAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    public func openMicrophoneSettings() {
        openSettingsPane("x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
    }

    public func openAccessibilitySettings() {
        openSettingsPane("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    private func microphonePermission() -> MicrophonePermission {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return .granted
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .unknown
        @unknown default:
            return .unknown
        }
    }

    private func openSettingsPane(_ value: String) {
        guard let url = URL(string: value) else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}
