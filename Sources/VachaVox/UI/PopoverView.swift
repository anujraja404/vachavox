import SwiftUI

struct PopoverView: View {
    @EnvironmentObject private var model: AppModel

    let startStop: () -> Void
    let pauseResume: (Bool) -> Void
    let openSettings: () -> Void
    let openFileTranscriptionSettings: () -> Void
    let quit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            primaryAction
            summaryRows
            contextualMessage
            transcriptCard
            fileTranscriptionShortcut
            Divider()
            footer
        }
        .padding(16)
        .frame(width: 360)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: model.readinessState.symbolName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(model.readinessState.tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text("VachaVox")
                    .font(.headline)
                Text(model.readinessState.title)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            StatusPill(
                title: model.selectedCatalogModel.status.shortLabel,
                symbolName: model.selectedCatalogModel.status.symbolName,
                tint: model.selectedCatalogModel.status.tint
            )
        }
        .accessibilityElement(children: .combine)
    }

    private var primaryAction: some View {
        Button(action: performPrimaryAction) {
            Label(primaryActionTitle, systemImage: primaryActionIcon)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(primaryActionDisabled)
        .help(primaryActionTitle)
    }

    private var summaryRows: some View {
        VStack(alignment: .leading, spacing: 8) {
            InfoRow(title: "Model", value: model.selectedCatalogModel.displayName)
            InfoRow(title: "Output", value: model.settings.outputMode.label)
            InfoRow(title: "Shortcut", value: "\(model.settings.hotkeyPreset.label) · \(model.settings.hotkeyMode.label)")
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder private var contextualMessage: some View {
        switch model.readinessState {
        case .ready:
            EmptyView()
        case .listening:
            VStack(alignment: .leading, spacing: 8) {
                LevelMeter(level: model.inputLevel)
                Text(listeningHelperText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        default:
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: model.readinessState.symbolName)
                    .foregroundStyle(model.readinessState.tint)
                    .frame(width: 22)
                Text(model.readinessState.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(model.readinessState.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder private var transcriptCard: some View {
        if !model.lastTranscript.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last transcript")
                            .font(.caption.weight(.semibold))
                        Text("In this session")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(model.lastTranscript, forType: .string)
                    } label: {
                        Label("Copy Again", systemImage: "doc.on.doc")
                    }
                    .controlSize(.small)
                    Button {
                        model.lastTranscript = ""
                    } label: {
                        Image(systemName: "xmark.circle")
                    }
                    .buttonStyle(.borderless)
                    .help("Clear last transcript")
                    .accessibilityLabel("Clear last transcript")
                }
                Text(model.lastTranscript)
                    .font(.callout)
                    .lineLimit(3)
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var fileTranscriptionShortcut: some View {
        Button(action: openFileTranscriptionSettings) {
            Label("File Transcription", systemImage: "waveform.badge.doc")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .help("Open File Transcription settings")
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Toggle("Paused", isOn: Binding(
                get: { model.settings.isPaused },
                set: { pauseResume($0) }
            ))
            .toggleStyle(.switch)

            Spacer()

            Button(action: openSettings) {
                Image(systemName: "gearshape")
            }
            .help("Open VachaVox settings")
            .accessibilityLabel("Open VachaVox settings")

            Button(action: quit) {
                Image(systemName: "power")
            }
            .help("Quit VachaVox")
            .accessibilityLabel("Quit VachaVox")
        }
    }

    private var primaryActionTitle: String {
        switch model.readinessState {
        case .ready:
            return "Start Dictation"
        case .paused:
            return "Resume Dictation"
        case .listening:
            return "Stop Dictation"
        case .transcribing, .loadingModel:
            return model.readinessState.title
        case .needsModel:
            return "Open Models"
        case .needsModelLoad, .modelLoadFailed:
            return "Open Models"
        case .needsMicrophone, .needsAccessibilityForPaste:
            return "Open Permissions"
        case .error:
            return "Open Settings"
        }
    }

    private var primaryActionIcon: String {
        switch model.readinessState {
        case .ready:
            return "mic.fill"
        case .paused:
            return "play.fill"
        case .listening:
            return "stop.fill"
        case .transcribing, .loadingModel:
            return "ellipsis"
        case .needsModel:
            return "square.stack.3d.up"
        case .needsModelLoad:
            return "square.stack.3d.up.badge.play"
        case .needsMicrophone:
            return "mic.badge.plus"
        case .needsAccessibilityForPaste:
            return "hand.raised"
        case .modelLoadFailed:
            return "exclamationmark.triangle"
        case .error:
            return "gearshape"
        }
    }

    private var primaryActionDisabled: Bool {
        switch model.readinessState {
        case .transcribing, .loadingModel:
            return true
        default:
            return false
        }
    }

    private var listeningHelperText: String {
        switch model.settings.hotkeyMode {
        case .pushToTalk:
            return "Release the shortcut to stop."
        case .toggle:
            return "Press the shortcut again to stop."
        }
    }

    private func performPrimaryAction() {
        switch model.readinessState {
        case .ready, .listening:
            startStop()
        case .paused:
            pauseResume(false)
        case .needsModel, .needsModelLoad, .modelLoadFailed, .needsMicrophone, .needsAccessibilityForPaste, .error:
            openSettings()
        case .transcribing, .loadingModel:
            break
        }
    }
}

private struct InfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 14)
            Text(value)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .font(.callout)
        .accessibilityElement(children: .combine)
    }
}

private struct LevelMeter: View {
    let level: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(.tint)
                    .frame(width: max(4, proxy.size.width * min(level, 1)))
            }
        }
        .frame(height: 8)
        .accessibilityLabel("Input level")
    }
}

private struct StatusPill: View {
    let title: String
    let symbolName: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: symbolName)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.14), in: Capsule())
            .foregroundStyle(tint)
    }
}

private extension ReadinessState {
    var tint: Color {
        switch self {
        case .ready:
            return .green
        case .paused, .needsModel, .needsModelLoad, .needsMicrophone, .needsAccessibilityForPaste:
            return .orange
        case .listening:
            return .red
        case .transcribing, .loadingModel:
            return .blue
        case .modelLoadFailed, .error:
            return .red
        }
    }
}

private extension ModelStatus {
    var shortLabel: String {
        switch self {
        case .error:
            return "Attention"
        default:
            return label
        }
    }

    var symbolName: String {
        switch self {
        case .ready:
            return "checkmark.circle.fill"
        case .installed:
            return "checkmark.circle"
        case .downloading:
            return "arrow.down.circle"
        case .loading:
            return "arrow.triangle.2.circlepath"
        case .missing:
            return "tray"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .ready:
            return .green
        case .installed:
            return .accentColor
        case .downloading, .loading:
            return .blue
        case .missing:
            return Color(nsColor: .secondaryLabelColor)
        case .error:
            return .red
        }
    }
}
