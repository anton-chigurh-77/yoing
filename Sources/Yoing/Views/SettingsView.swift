import AppKit
import SwiftUI
import YoingCore

struct SettingsView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        TabView {
            setupTab
                .tabItem {
                    Label("Setup", systemImage: "checklist")
                }

            providerTab
                .tabItem {
                    Label("Provider", systemImage: "key")
                }

            privacyTab
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised")
                }
        }
        .frame(width: 560, height: 420)
        .scenePadding()
        .onAppear {
            appState.refreshSetupState()
        }
    }

    private var setupTab: some View {
        Form {
            Section("Dictation") {
                HStack {
                    Text("Hotkey")

                    Spacer()

                    HotKeyRecorderView(
                        hotKey: Binding(
                            get: { appState.draftHotKey },
                            set: { appState.setDraftHotKey($0) }
                        ),
                        isEnabled: appState.canEditHotKey
                    )
                    .frame(width: 180, height: 28)
                }

                Text(appState.hotKeyMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Button("Use Default") {
                        appState.useDefaultHotKey()
                    }
                    .disabled(!appState.canEditHotKey || appState.draftHotKey == .defaultDictation)

                    Button("Revert") {
                        appState.revertHotKeyChanges()
                    }
                    .disabled(!appState.hasUnsavedHotKeyChange)

                    Spacer()

                    Button("Save") {
                        appState.saveHotKey()
                    }
                    .disabled(!appState.canSaveHotKey)
                }

                LabeledContent("Status", value: appState.phase.title)
                Text(appState.phaseDetail)
                    .foregroundStyle(.secondary)
            }

            Section("Permissions") {
                permissionRow(
                    title: "Microphone",
                    value: microphoneValue,
                    isReady: appState.permissions.microphone.isGranted,
                    requestTitle: "Request",
                    requestAction: {
                        Task {
                            await appState.requestMicrophonePermission()
                        }
                    },
                    settingsAction: appState.openMicrophoneSettings
                )

                permissionRow(
                    title: "Accessibility",
                    value: appState.permissions.accessibilityTrusted ? "Ready" : "Needed",
                    isReady: appState.permissions.accessibilityTrusted,
                    requestTitle: "Prompt",
                    requestAction: appState.promptAccessibilityPermission,
                    settingsAction: appState.openAccessibilitySettings
                )
            }

            Section {
                Button("Refresh Setup") {
                    appState.refreshSetupState()
                }
            }
        }
        .formStyle(.grouped)
    }

    private var providerTab: some View {
        Form {
            Section("xAI") {
                LabeledContent("Key", value: appState.hasXAIAPIKey ? "Saved locally" : "Not saved")

                SecureField("xAI API key", text: $appState.apiKeyInput)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Save Key") {
                        appState.saveAPIKey()
                    }
                    .keyboardShortcut(.defaultAction)

                    Button("Delete Key", role: .destructive) {
                        appState.deleteAPIKey()
                    }
                    .disabled(!appState.hasXAIAPIKey)

                    Spacer()
                }
            }

            Section("Model Path") {
                Text("Yoing sends each completed hold-to-dictate recording to xAI speech-to-text and types only the final returned text.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
    }

    private var privacyTab: some View {
        Form {
            Section("MVP Boundaries") {
                BoundaryRow(title: "No account", detail: "Provider keys stay under your local control.")
                BoundaryRow(title: "No default history", detail: "Dictation text is not saved after insertion.")
                BoundaryRow(title: "No clipboard path", detail: "Yoing types directly into the focused app.")
            }

            Section("Local Storage") {
                LabeledContent("Provider key", value: "macOS Keychain")
                LabeledContent("Preferences", value: "UserDefaults")
                LabeledContent("Audio", value: "Temporary during transcription")
            }
        }
        .formStyle(.grouped)
    }

    private var microphoneValue: String {
        switch appState.permissions.microphone {
        case .granted:
            return "Ready"
        case .unknown:
            return "Not requested"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        }
    }

    private func permissionRow(
        title: String,
        value: String,
        isReady: Bool,
        requestTitle: String,
        requestAction: @escaping () -> Void,
        settingsAction: @escaping () -> Void
    ) -> some View {
        HStack {
            LabeledContent(title, value: value)

            Spacer()

            Image(systemName: isReady ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(isReady ? .green : .orange)

            Button(requestTitle, action: requestAction)
                .disabled(isReady)

            Button("Open Settings", action: settingsAction)
        }
    }
}

private struct BoundaryRow: View {
    var title: String
    var detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .fontWeight(.medium)

            Text(detail)
                .foregroundStyle(.secondary)
        }
    }
}
