import AppKit
import Foundation
import YoingCore

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var phase: DictationPhase = .starting
    @Published private(set) var permissions = PermissionHealth(
        microphone: .unknown,
        accessibilityTrusted: false
    )
    @Published private(set) var hasXAIAPIKey = false
    @Published private(set) var providerMessage = "xAI key not saved"
    @Published var apiKeyInput = ""

    let hotKey = HotKey.defaultDictation

    private let permissionManager: PermissionManager
    private let credentialStore: CredentialStoring
    private let recorder: AudioRecorder
    private let transcriber: XAITranscriptionClient
    private let inserter: TextInsertionService
    private let hotkeyMonitor: GlobalHotkeyMonitor

    private var hasStarted = false
    private var resetTask: Task<Void, Never>?

    init(
        permissionManager: PermissionManager = PermissionManager(),
        credentialStore: CredentialStoring = KeychainCredentialStore(),
        recorder: AudioRecorder = AudioRecorder(),
        transcriber: XAITranscriptionClient = XAITranscriptionClient(),
        inserter: TextInsertionService = TextInsertionService(),
        hotkeyMonitor: GlobalHotkeyMonitor = GlobalHotkeyMonitor()
    ) {
        self.permissionManager = permissionManager
        self.credentialStore = credentialStore
        self.recorder = recorder
        self.transcriber = transcriber
        self.inserter = inserter
        self.hotkeyMonitor = hotkeyMonitor

        hotkeyMonitor.onPress = { [weak self] in
            Task { @MainActor in
                self?.beginDictation()
            }
        }

        hotkeyMonitor.onRelease = { [weak self] in
            Task { @MainActor in
                self?.finishDictation()
            }
        }

        refreshSetupState()
    }

    deinit {
        hotkeyMonitor.stop()
    }

    var menuBarSystemImage: String {
        switch phase {
        case .recording:
            return "waveform.circle.fill"
        case .transcribing:
            return "arrow.triangle.2.circlepath.circle.fill"
        case .success:
            return "checkmark.circle.fill"
        case .failed, .blocked:
            return "exclamationmark.circle.fill"
        case .starting, .ready:
            return "mic.circle.fill"
        }
    }

    var statusTintName: String {
        switch phase {
        case .ready, .success:
            return "green"
        case .recording:
            return "red"
        case .transcribing:
            return "cyan"
        case .blocked:
            return "orange"
        case .failed:
            return "red"
        case .starting:
            return "secondary"
        }
    }

    func start() {
        guard !hasStarted else {
            return
        }

        hasStarted = true
        refreshSetupState()
        startHotkeyMonitorIfPossible()
    }

    func refreshSetupState() {
        permissions = permissionManager.currentHealth()
        hasXAIAPIKey = ((try? credentialStore.readXAIAPIKey()) ?? nil) != nil
        providerMessage = hasXAIAPIKey ? "xAI key saved locally" : "Add your xAI API key"

        if !isBusy {
            updateIdlePhase()
        }

        if permissions.accessibilityTrusted {
            startHotkeyMonitorIfPossible()
        }
    }

    func requestMicrophonePermission() async {
        _ = await permissionManager.requestMicrophonePermission()
        refreshSetupState()
    }

    func promptAccessibilityPermission() {
        permissionManager.promptForAccessibilityPermission()

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            refreshSetupState()
        }
    }

    func openMicrophoneSettings() {
        permissionManager.openMicrophoneSettings()
    }

    func openAccessibilitySettings() {
        permissionManager.openAccessibilitySettings()
    }

    func saveAPIKey() {
        do {
            try credentialStore.saveXAIAPIKey(apiKeyInput)
            apiKeyInput = ""
            refreshSetupState()
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func deleteAPIKey() {
        do {
            try credentialStore.deleteXAIAPIKey()
            refreshSetupState()
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func beginDictation() {
        resetTask?.cancel()
        refreshSetupState()

        guard permissions.microphone.isGranted else {
            phase = .blocked("Microphone permission needed")
            return
        }

        guard permissions.accessibilityTrusted else {
            phase = .blocked("Accessibility permission needed")
            return
        }

        guard hasXAIAPIKey else {
            phase = .blocked("Add an xAI API key in Settings")
            return
        }

        do {
            try recorder.start()
            phase = .recording(Date())
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func finishDictation() {
        guard case .recording = phase else {
            return
        }

        phase = .transcribing

        Task { @MainActor in
            do {
                let audio = try recorder.stop()
                guard let apiKey = try credentialStore.readXAIAPIKey() else {
                    throw TranscriptionError.missingAPIKey
                }

                let transcript = try await transcriber.transcribe(audio, apiKey: apiKey)
                try inserter.insert(transcript)

                phase = .success("Inserted \(transcript.count) characters")
                scheduleIdleReset()
            } catch {
                recorder.discard()
                phase = .failed(error.localizedDescription)
            }
        }
    }

    private var isBusy: Bool {
        if case .recording = phase {
            return true
        }

        if case .transcribing = phase {
            return true
        }

        return false
    }

    private func updateIdlePhase() {
        if !permissions.microphone.isGranted {
            phase = .blocked("Microphone permission needed")
        } else if !permissions.accessibilityTrusted {
            phase = .blocked("Accessibility permission needed")
        } else if !hasXAIAPIKey {
            phase = .blocked("Add an xAI API key in Settings")
        } else {
            phase = .ready
        }
    }

    private func startHotkeyMonitorIfPossible() {
        guard permissions.accessibilityTrusted else {
            return
        }

        do {
            try hotkeyMonitor.start()
        } catch {
            phase = .blocked(error.localizedDescription)
        }
    }

    private func scheduleIdleReset() {
        resetTask?.cancel()
        resetTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            refreshSetupState()
        }
    }
}
