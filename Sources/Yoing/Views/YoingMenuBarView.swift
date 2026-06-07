import AppKit
import SwiftUI
import YoingCore

struct YoingMenuBarView: View {
    @ObservedObject var appState: AppState
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()
                .overlay(Color.white.opacity(0.12))
                .padding(.vertical, 12)

            statusPanel

            Divider()
                .overlay(Color.white.opacity(0.12))
                .padding(.vertical, 12)

            setupRows

            Divider()
                .overlay(Color.white.opacity(0.12))
                .padding(.vertical, 10)

            actionRows
        }
        .padding(14)
        .background(Color(red: 0.04, green: 0.04, blue: 0.045))
        .foregroundStyle(.white)
        .onAppear {
            appState.refreshSetupState()
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Yoing")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(appState.hotKey.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("MVP")
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.cyan.opacity(0.18), in: Capsule())
                .foregroundStyle(.cyan)
        }
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: appState.menuBarSystemImage)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(statusColor)

                Text(appState.phase.title)
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()
            }

            Text(appState.phase.detail)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var setupRows: some View {
        VStack(spacing: 8) {
            HealthRow(
                title: "Microphone",
                detail: microphoneDetail,
                systemImage: "mic.fill",
                isHealthy: appState.permissions.microphone.isGranted
            )

            HealthRow(
                title: "Accessibility",
                detail: appState.permissions.accessibilityTrusted ? "Ready to type" : "Needed for hotkey and typing",
                systemImage: "keyboard.fill",
                isHealthy: appState.permissions.accessibilityTrusted
            )

            HealthRow(
                title: "xAI Provider",
                detail: appState.providerMessage,
                systemImage: "key.fill",
                isHealthy: appState.hasXAIAPIKey
            )
        }
    }

    private var actionRows: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                openSettings()
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("Settings", systemImage: "gearshape")
            }

            Button {
                appState.refreshSetupState()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit", systemImage: "xmark.circle")
            }
        }
        .buttonStyle(.plain)
        .labelStyle(.titleAndIcon)
        .font(.callout)
    }

    private var microphoneDetail: String {
        switch appState.permissions.microphone {
        case .granted:
            return "Ready to record"
        case .unknown:
            return "Permission not requested"
        case .denied:
            return "Permission denied"
        case .restricted:
            return "Permission restricted"
        }
    }

    private var statusColor: Color {
        switch appState.statusTintName {
        case "green":
            return .green
        case "red":
            return .red
        case "cyan":
            return .cyan
        case "orange":
            return .orange
        default:
            return .secondary
        }
    }
}

private struct HealthRow: View {
    var title: String
    var detail: String
    var systemImage: String
    var isHealthy: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .frame(width: 18)
                .foregroundStyle(isHealthy ? .green : .orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                    .fontWeight(.medium)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: isHealthy ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(isHealthy ? .green : .orange)
        }
    }
}
