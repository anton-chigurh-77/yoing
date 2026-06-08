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
    @Published private(set) var usageStats = UsageStatsSnapshot(days: [])
    @Published private(set) var hotKey: HotKey
    @Published private(set) var hotKeyMessage: String
    @Published var draftHotKey: HotKey
    @Published var apiKeyInput = ""

    private let permissionManager: PermissionManager
    private let credentialStore: CredentialStoring
    private let hotKeyStore: HotKeyStoring
    private let recorder: AudioRecorder
    private let transcriber: XAITranscriptionClient
    private let inserter: TextInsertionService
    private let hotkeyMonitor: GlobalHotkeyMonitor
    private let usageStatsStore: UsageStatsStoring

    private var hasStarted = false
    private var resetTask: Task<Void, Never>?
    private static let usageStatsDayCount = 182

    init(
        permissionManager: PermissionManager = PermissionManager(),
        credentialStore: CredentialStoring = KeychainCredentialStore(),
        hotKeyStore: HotKeyStoring = UserDefaultsHotKeyStore(),
        recorder: AudioRecorder = AudioRecorder(),
        transcriber: XAITranscriptionClient = XAITranscriptionClient(),
        inserter: TextInsertionService = TextInsertionService(),
        hotkeyMonitor: GlobalHotkeyMonitor = GlobalHotkeyMonitor(),
        usageStatsStore: UsageStatsStoring = UserDefaultsUsageStatsStore()
    ) {
        let storedHotKey = hotKeyStore.loadDictationHotKey()

        hotKey = storedHotKey
        draftHotKey = storedHotKey
        hotKeyMessage = "Active hotkey: \(storedHotKey.displayName)"
        self.permissionManager = permissionManager
        self.credentialStore = credentialStore
        self.hotKeyStore = hotKeyStore
        self.recorder = recorder
        self.transcriber = transcriber
        self.inserter = inserter
        self.hotkeyMonitor = hotkeyMonitor
        self.usageStatsStore = usageStatsStore

        try? hotkeyMonitor.updateHotKey(storedHotKey)

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

    var phaseDetail: String {
        switch phase {
        case .ready:
            return "Hold \(hotKey.displayName) to dictate"
        case .recording:
            return "Release \(hotKey.displayName) to finish"
        default:
            return phase.detail
        }
    }

    var hasUnsavedHotKeyChange: Bool {
        draftHotKey != hotKey
    }

    var canEditHotKey: Bool {
        !isBusy
    }

    var canSaveHotKey: Bool {
        canEditHotKey && hasUnsavedHotKeyChange && draftHotKey.isValid
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

    func setDraftHotKey(_ newHotKey: HotKey) {
        guard canEditHotKey else {
            hotKeyMessage = "Hotkey cannot change while dictation is active"
            return
        }

        guard newHotKey.isValid else {
            hotKeyMessage = "That hotkey is not supported"
            return
        }

        draftHotKey = newHotKey
        hotKeyMessage = newHotKey == hotKey ? "Active hotkey: \(newHotKey.displayName)" : "Unsaved hotkey: \(newHotKey.displayName)"
    }

    func saveHotKey() {
        guard canEditHotKey else {
            hotKeyMessage = "Hotkey cannot change while dictation is active"
            return
        }

        guard draftHotKey.isValid else {
            hotKeyMessage = "That hotkey is not supported"
            return
        }

        let previousHotKey = hotKey
        let newHotKey = draftHotKey

        do {
            try hotkeyMonitor.updateHotKey(newHotKey)
            if newHotKey == .defaultDictation {
                hotKeyStore.resetDictationHotKey()
            } else {
                try hotKeyStore.saveDictationHotKey(newHotKey)
            }
            hotKey = newHotKey
            draftHotKey = newHotKey
            hotKeyMessage = "Saved hotkey: \(newHotKey.displayName)"
            refreshSetupState()
        } catch {
            try? hotkeyMonitor.updateHotKey(previousHotKey)
            draftHotKey = previousHotKey
            hotKeyMessage = "Could not save hotkey"
            phase = .failed(error.localizedDescription)
        }
    }

    func revertHotKeyChanges() {
        draftHotKey = hotKey
        hotKeyMessage = "Active hotkey: \(hotKey.displayName)"
    }

    func useDefaultHotKey() {
        setDraftHotKey(.defaultDictation)
    }

    func start() {
        guard !hasStarted else {
            return
        }

        hasStarted = true
        refreshSetupState()
    }

    func refreshSetupState() {
        refreshUsageStats()
        permissions = permissionManager.currentHealth()
        hasXAIAPIKey = ((try? credentialStore.readXAIAPIKey()) ?? nil) != nil
        providerMessage = hasXAIAPIKey ? "xAI key saved locally" : "Add your xAI API key"

        if !isBusy {
            updateIdlePhase()
            syncHotkeyMonitorAvailability()
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

                let usageEvent = DictationUsageEvent(
                    transcript: transcript,
                    dictatedSeconds: audio.duration,
                    provider: "xAI"
                )
                try? usageStatsStore.record(usageEvent)
                refreshUsageStats()

                phase = .success(successMessage(for: usageEvent))
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

    private var canRunHotkeyMonitor: Bool {
        permissions.microphone.isGranted && permissions.accessibilityTrusted && hasXAIAPIKey
    }

    private func syncHotkeyMonitorAvailability() {
        guard canRunHotkeyMonitor else {
            hotkeyMonitor.stop()
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

    private func refreshUsageStats() {
        usageStats = usageStatsStore.snapshot(dayCount: Self.usageStatsDayCount, now: Date())
    }

    private func successMessage(for event: DictationUsageEvent) -> String {
        if event.wordCount > 0 {
            let noun = event.wordCount == 1 ? "word" : "words"
            return "Inserted \(event.wordCount) \(noun)"
        }

        let noun = event.characterCount == 1 ? "character" : "characters"
        return "Inserted \(event.characterCount) \(noun)"
    }
}
