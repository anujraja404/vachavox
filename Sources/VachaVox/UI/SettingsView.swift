import AppKit
import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel
    let coordinator: DictationCoordinator

    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $model.selectedSettingsTab) { tab in
                Label(tab.title, systemImage: tab.symbol)
                    .tag(tab)
            }
            .navigationSplitViewColumnWidth(190)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    tabContent
                }
                .padding(28)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(model.selectedSettingsTab.title)
                .font(.largeTitle.weight(.semibold))
            Text(model.selectedSettingsTab.subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var tabContent: some View {
        switch model.selectedSettingsTab {
        case .general:
            GeneralSettings(
                model: model,
                coordinator: coordinator,
                openTab: { model.selectedSettingsTab = $0 }
            )
        case .models:
            ModelsSettings(model: model, coordinator: coordinator)
        case .dictation:
            DictationSettings(model: model, coordinator: coordinator)
        case .fileTranscription:
            FileTranscriptionSettings(model: model, coordinator: coordinator)
        case .hotkeys:
            HotkeysSettings(model: model)
        case .permissions:
            PermissionsSettings(model: model, coordinator: coordinator)
        case .privacy:
            PrivacySettings(model: model)
        }
    }
}

private extension SettingsTab {
    var title: String {
        switch self {
        case .general: return "General"
        case .models: return "Models"
        case .dictation: return "Dictation"
        case .fileTranscription: return "File Transcription"
        case .hotkeys: return "Hotkeys"
        case .permissions: return "Permissions"
        case .privacy: return "Privacy"
        }
    }

    var subtitle: String {
        switch self {
        case .general:
            return "Readiness, defaults, and app behavior."
        case .models:
            return "Local transcription models stored on this Mac."
        case .dictation:
            return "Output, formatting, speech-end, and performance settings."
        case .fileTranscription:
            return "Generate local Markdown transcripts from audio files."
        case .hotkeys:
            return "Shortcut behavior for starting and stopping dictation."
        case .permissions:
            return "Access needed for recording and Paste output."
        case .privacy:
            return "Local-first data handling, storage, and diagnostics."
        }
    }

    var symbol: String {
        switch self {
        case .general: return "circle.badge.checkmark"
        case .models: return "square.stack.3d.up"
        case .dictation: return "mic"
        case .fileTranscription: return "waveform.badge.doc"
        case .hotkeys: return "keyboard"
        case .permissions: return "hand.raised"
        case .privacy: return "lock.shield"
        }
    }
}

private struct GeneralSettings: View {
    @ObservedObject var model: AppModel
    let coordinator: DictationCoordinator
    let openTab: (SettingsTab) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsSection("Readiness", systemImage: "checklist") {
                StatusSummary(state: model.readinessState)
                VStack(alignment: .leading, spacing: 10) {
                    modelRow
                    microphoneRow
                    accessibilityRow
                    ReadinessChecklistRow(
                        title: "Output mode",
                        value: model.settings.outputMode.label,
                        detail: outputDetail,
                        symbolName: "arrowshape.turn.up.right",
                        state: .neutral,
                        actionTitle: "Change",
                        action: { openTab(.dictation) }
                    )
                    ReadinessChecklistRow(
                        title: "Shortcut",
                        value: effectiveShortcut,
                        detail: shortcutDetail,
                        symbolName: "keyboard",
                        state: .neutral,
                        actionTitle: "Change",
                        action: { openTab(.hotkeys) }
                    )
                }
            }

            SettingsSection("Defaults", systemImage: "slider.horizontal.3") {
                InfoLine("Model", model.selectedCatalogModel.displayName)
                InfoLine("Output", model.settings.outputMode.label)
                InfoLine("Hotkey", "\(effectiveShortcut), \(model.settings.hotkeyMode.label)")
            }

            SettingsSection("App Behavior", systemImage: "gearshape") {
                Toggle("Start VachaVox at login", isOn: Binding(
                    get: { model.settings.launchAtLogin },
                    set: { value in
                        model.settings.launchAtLogin = value
                        try? LoginItemService().setEnabled(value)
                    }
                ))
                .toggleStyle(.switch)

                HStack {
                    Button("Test Dictation") {
                        coordinator.toggleDictation()
                    }
                    .disabled(model.phase == .transcribing || model.readinessState.isBlocking)
                    Button(model.settings.isPaused ? "Resume Dictation" : "Pause Dictation") {
                        coordinator.setPaused(!model.settings.isPaused)
                    }
                }
            }
        }
    }

    private var modelRow: some View {
        let descriptor = model.selectedCatalogModel
        let loaded = model.selectedModelIsLoaded
        return ReadinessChecklistRow(
            title: "Model",
            value: modelValue(for: descriptor, loaded: loaded),
            detail: modelDetail(for: descriptor, loaded: loaded),
            symbolName: "square.stack.3d.up",
            state: descriptor.status.isUsable && loaded ? .ok : .warning,
            actionTitle: descriptor.status.isUsable && !loaded ? "Load" : (descriptor.status.isUsable ? "Open Models" : "Install"),
            action: { openTab(.models) }
        )
    }

    private func modelValue(for descriptor: LocalModelDescriptor, loaded: Bool) -> String {
        if loaded {
            return "Loaded"
        }
        if descriptor.status.isUsable {
            return "Installed, not loaded"
        }
        return "No model installed"
    }

    private func modelDetail(for descriptor: LocalModelDescriptor, loaded: Bool) -> String {
        if loaded {
            return "\(descriptor.displayName) is active and ready."
        }
        if descriptor.status.isUsable {
            return "Load \(descriptor.displayName) before dictating."
        }
        return "Install a local model to dictate on this Mac."
    }

    private var microphoneRow: some View {
        ReadinessChecklistRow(
            title: "Microphone",
            value: microphoneValue,
            detail: "Required to record speech for dictation.",
            symbolName: model.microphonePermission == .granted ? "mic" : "mic.slash",
            state: model.microphonePermission == .denied ? .warning : .ok,
            actionTitle: model.microphonePermission == .granted ? nil : "Open Settings",
            action: model.microphonePermission == .granted ? nil : {
                coordinator.openMicrophonePrivacySettings()
            }
        )
    }

    private var accessibilityRow: some View {
        let required = model.settings.outputMode == .paste
        return ReadinessChecklistRow(
            title: "Accessibility",
            value: model.accessibilityTrusted ? "Trusted" : (required ? "Needs access" : "Not needed"),
            detail: required ? "Required only for Paste output mode." : "Copy and Preview work without Accessibility trust.",
            symbolName: model.accessibilityTrusted ? "hand.raised.fill" : "hand.raised",
            state: model.accessibilityTrusted ? .ok : (required ? .warning : .neutral),
            actionTitle: model.accessibilityTrusted ? nil : "Open Settings",
            action: model.accessibilityTrusted ? nil : {
                coordinator.requestAccessibilityPermission()
            }
        )
    }

    private var microphoneValue: String {
        switch model.microphonePermission {
        case .granted:
            return "Granted"
        case .denied:
            return "Denied"
        case .unknown:
            return "Will ask when needed"
        }
    }

    private var outputDetail: String {
        switch model.settings.outputMode {
        case .copy:
            return "Copy the transcript to the clipboard."
        case .paste:
            return "Paste into the focused app after transcription."
        case .preview:
            return "Open an editable preview before copying."
        }
    }

    private var shortcutDetail: String {
        switch model.settings.hotkeyMode {
        case .pushToTalk:
            return "Hold the shortcut while speaking."
        case .toggle:
            return "Press once to start and again to stop."
        }
    }

    private var effectiveShortcut: String {
        if model.settings.hotkeyPreset == .custom {
            return KeyboardShortcuts.Name.dictation.shortcut?.description ?? model.settings.hotKeyDescription
        }
        return model.settings.hotkeyPreset.label
    }
}

private struct ModelsSettings: View {
    @ObservedObject var model: AppModel
    let coordinator: DictationCoordinator
    @State private var pendingDelete: LocalModelDescriptor?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            currentModelSection
            installedModelsSection
            availableModelsSection
        }
        .confirmationDialog(
            "Delete local model?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { descriptor in
            Button("Delete \(descriptor.displayName)", role: .destructive) {
                coordinator.delete(descriptor)
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDelete = nil
            }
        } message: { descriptor in
            Text(deleteConsequence(for: descriptor))
        }
    }

    private var selectedDescriptor: LocalModelDescriptor {
        model.selectedCatalogModel
    }

    private var installedModels: [LocalModelDescriptor] {
        model.modelCatalog.filter { descriptor in
            if case .missing = descriptor.status {
                return false
            }
            return true
        }
    }

    private var availableModels: [LocalModelDescriptor] {
        model.modelCatalog.filter { $0.status == .missing && $0.isDownloadable }
    }

    private var currentModelSection: some View {
        SettingsSection("Current Model", systemImage: "checkmark.circle") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: selectedDescriptor.engine == .parakeet ? "waveform.path.ecg" : "text.bubble")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.tint)
                        .frame(width: 34)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(selectedDescriptor.displayName)
                                .font(.title3.weight(.semibold))
                            Spacer()
                            StatusBadge(status: selectedDescriptor.status)
                        }
                        InfoLine("Engine", selectedDescriptor.engine.label)
                        InfoLine("Languages", selectedDescriptor.languageDescription)
                        InfoLine("Memory", selectedDescriptor.recommendedRAM)
                        InfoLine("Load state", model.modelLoadState.label)
                        Text(ModelStore().modelURL(for: selectedDescriptor).path)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .textSelection(.enabled)
                    }
                }
                HStack {
                    Button {
                        coordinator.loadSelectedModel()
                    } label: {
                        Label(loadSelectedTitle, systemImage: "play.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!selectedDescriptor.status.isUsable || selectedDescriptor.status == .loading)

                    if !selectedDescriptor.status.isUsable {
                        Text("Install or repair this model before loading it.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var loadSelectedTitle: String {
        if model.selectedModelIsLoaded {
            return "Reload Selected Model"
        }
        return "Load Selected Model"
    }

    private var installedModelsSection: some View {
        SettingsSection("Installed Models", systemImage: "internaldrive") {
            if installedModels.isEmpty {
                EmptyState(
                    symbolName: "square.stack.3d.up",
                    title: "No local models installed",
                    detail: "Download a model below or add one under \(ModelStore().rootURL.path)."
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(installedModels) { descriptor in
                        ModelRowView(
                            descriptor: descriptor,
                            isSelected: descriptor.id == model.settings.selectedModelID,
                            primaryTitle: primaryTitle(for: descriptor),
                            primarySystemImage: primarySystemImage(for: descriptor),
                            primaryDisabled: primaryDisabled(for: descriptor),
                            primaryProminent: primaryProminent(for: descriptor),
                            primaryAction: { performPrimaryAction(for: descriptor) },
                            reveal: { coordinator.reveal(descriptor) },
                            openSource: { openSource(for: descriptor) },
                            delete: { pendingDelete = descriptor }
                        )
                    }
                }
            }
        }
    }

    private var availableModelsSection: some View {
        SettingsSection("Available Models", systemImage: "arrow.down.circle") {
            if availableModels.isEmpty {
                EmptyState(
                    symbolName: "checkmark.circle",
                    title: "No additional downloads",
                    detail: "All downloadable models are installed or in progress."
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(availableModels) { descriptor in
                        ModelRowView(
                            descriptor: descriptor,
                            isSelected: false,
                            primaryTitle: "Download",
                            primarySystemImage: "arrow.down",
                            primaryDisabled: !descriptor.isDownloadable,
                            primaryProminent: true,
                            primaryAction: { coordinator.download(descriptor) },
                            reveal: nil,
                            openSource: { openSource(for: descriptor) },
                            delete: nil
                        )
                    }
                }
            }
        }
    }

    private func primaryTitle(for descriptor: LocalModelDescriptor) -> String {
        let isSelected = descriptor.id == model.settings.selectedModelID
        if isSelected && model.selectedModelIsLoaded {
            return "Loaded"
        }
        switch descriptor.status {
        case .installed, .ready:
            return isSelected ? "Load Model" : "Select & Load"
        case .downloading:
            return "Downloading"
        case .loading:
            return "Loading"
        case .error:
            return descriptor.id == model.settings.selectedModelID ? "Retry Load" : "Repair"
        case .missing:
            return "Download"
        }
    }

    private func primarySystemImage(for descriptor: LocalModelDescriptor) -> String {
        switch descriptor.status {
        case .installed, .ready:
            return descriptor.id == model.settings.selectedModelID && model.selectedModelIsLoaded ? "checkmark" : "play"
        case .downloading, .loading:
            return "arrow.triangle.2.circlepath"
        case .error:
            return "arrow.clockwise"
        case .missing:
            return "arrow.down"
        }
    }

    private func primaryDisabled(for descriptor: LocalModelDescriptor) -> Bool {
        if descriptor.id == model.settings.selectedModelID && model.selectedModelIsLoaded {
            return true
        }
        switch descriptor.status {
        case .downloading, .loading:
            return true
        case .missing:
            return !descriptor.isDownloadable
        default:
            return false
        }
    }

    private func primaryProminent(for descriptor: LocalModelDescriptor) -> Bool {
        switch descriptor.status {
        case .installed, .ready, .missing, .error:
            return descriptor.id != model.settings.selectedModelID || !model.selectedModelIsLoaded
        case .downloading, .loading:
            return false
        }
    }

    private func performPrimaryAction(for descriptor: LocalModelDescriptor) {
        switch descriptor.status {
        case .installed, .ready:
            coordinator.useModel(descriptor)
        case .error where descriptor.id == model.settings.selectedModelID:
            coordinator.loadSelectedModel()
        case .missing, .error:
            coordinator.download(descriptor)
        case .downloading, .loading:
            break
        }
    }

    private func deleteConsequence(for descriptor: LocalModelDescriptor) -> String {
        guard descriptor.id == model.settings.selectedModelID else {
            return "\(descriptor.displayName) will be removed from this Mac."
        }

        let remainingCatalog = model.modelCatalog.filter { $0.id != descriptor.id }
        if let fallback = ModelCatalog.bestAvailable(from: remainingCatalog) {
            return "\(descriptor.displayName) will be removed from this Mac. VachaVox will switch to \(fallback.displayName)."
        }
        return "\(descriptor.displayName) will be removed from this Mac. Dictation will be unavailable until another model is installed."
    }

    private func openSource(for descriptor: LocalModelDescriptor) {
        guard let url = descriptor.downloadURL else { return }
        NSWorkspace.shared.open(url)
    }
}

private struct DictationSettings: View {
    @ObservedObject var model: AppModel
    let coordinator: DictationCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsSection("Output", systemImage: "arrowshape.turn.up.right") {
                Picker("Output mode", selection: binding(\.outputMode)) {
                    ForEach(OutputMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 340)

                Text(outputDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if model.pasteModeNeedsAccessibility {
                    InlineNote(
                        symbolName: "hand.raised",
                        title: "Paste mode needs Accessibility access",
                        detail: "Open Permissions to enable direct paste. Copy and Preview work without it.",
                        tint: .orange,
                        actionTitle: "Open Accessibility Settings",
                        action: { coordinator.requestAccessibilityPermission() }
                    )
                }
            }

            SettingsSection("Formatting", systemImage: "textformat") {
                Toggle("Add punctuation automatically", isOn: binding(\.punctuationEnabled))
                    .toggleStyle(.switch)
            }

            SettingsSection("Speech End", systemImage: "waveform") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("End dictation after silence")
                        .font(.callout.weight(.medium))
                    HStack {
                        Text("Wait longer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: binding(\.silenceSensitivity), in: 0.005...0.08)
                            .frame(width: 320)
                            .accessibilityLabel("End dictation after silence")
                            .accessibilityValue("\(Int(model.settings.silenceSensitivity * 1000)) milliseconds sensitivity")
                        Text("Stop sooner")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("Move left to wait longer before finishing; move right to stop sooner after speech ends.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            SettingsSection("Performance", systemImage: "speedometer") {
                Picker("Performance", selection: binding(\.performanceMode)) {
                    ForEach(PerformanceMode.allCases) { mode in
                        Text(mode.settingsLabel).tag(mode)
                    }
                }
                .frame(width: 360)
                Text("Higher accuracy may use more memory. Speed favors faster local processing.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var outputDescription: String {
        switch model.settings.outputMode {
        case .copy:
            return "Copy the transcript to the clipboard."
        case .paste:
            return "Paste into the focused app after transcription."
        case .preview:
            return "Open an editable preview before copying."
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        Binding(
            get: { model.settings[keyPath: keyPath] },
            set: { model.settings[keyPath: keyPath] = $0 }
        )
    }
}

private struct FileTranscriptionSettings: View {
    @ObservedObject var model: AppModel
    let coordinator: DictationCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsSection("Audio File", systemImage: "waveform.badge.doc") {
                VStack(alignment: .leading, spacing: 12) {
                    if let url = model.fileTranscription.selectedAudioFileURL {
                        InfoLine("Name", model.fileTranscription.selectedAudioFileName)
                        InfoLine("Path", url.path)
                        if let duration = model.fileTranscription.selectedAudioFileDuration {
                            InfoLine("Duration", Self.durationFormatter.string(from: duration) ?? "\(Int(duration)) sec")
                        }
                    } else {
                        EmptyState(
                            symbolName: "doc.badge.plus",
                            title: "No audio file selected",
                            detail: "Choose a local audio file to generate a Markdown transcript."
                        )
                    }

                    HStack {
                        Button {
                            coordinator.chooseAudioFileForTranscription()
                        } label: {
                            Label("Choose Audio File", systemImage: "folder")
                        }

                        Button {
                            coordinator.generateFileTranscript()
                        } label: {
                            Label("Generate", systemImage: "doc.text")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!model.fileTranscription.hasSelectedFile || model.fileTranscription.isGenerating)

                        if model.fileTranscription.isGenerating {
                            Button {
                                coordinator.cancelFileTranscript()
                            } label: {
                                Label("Cancel", systemImage: "xmark.circle")
                            }
                        }
                    }
                }
            }

            SettingsSection("Progress", systemImage: "clock") {
                VStack(alignment: .leading, spacing: 10) {
                    if model.fileTranscription.isGenerating {
                        if let progress = model.fileTranscription.progressFraction {
                            ProgressView(value: progress)
                                .progressViewStyle(.linear)
                                .accessibilityLabel("File transcription progress")
                                .accessibilityValue("\(Int(progress * 100)) percent")
                        } else {
                            ProgressView()
                                .controlSize(.small)
                                .accessibilityLabel("File transcription progress")
                        }
                    }

                    Label(
                        model.fileTranscription.statusMessage,
                        systemImage: statusSymbol
                    )
                    .font(.callout)
                    .foregroundStyle(statusTint)
                    .textSelection(.enabled)

                    if let error = model.fileTranscription.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .textSelection(.enabled)
                    }
                }
            }

            SettingsSection("Output", systemImage: "internaldrive") {
                VStack(alignment: .leading, spacing: 12) {
                    InfoLine("Folder", FileTranscriptionService.defaultOutputRoot.path)
                    if let outputURL = model.fileTranscription.completedOutputURL {
                        InfoLine("Markdown file", outputURL.path)
                        Button {
                            coordinator.revealFileTranscriptOutput()
                        } label: {
                            Label("Reveal Output", systemImage: "arrow.up.forward.app")
                        }
                    }
                    Text("Transcription runs locally. Markdown files are stored in ~/vachavox/output and are only created when you generate them.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var statusSymbol: String {
        switch model.fileTranscription.phase {
        case .idle:
            return "doc"
        case .generating:
            return "ellipsis.circle"
        case .completed:
            return "checkmark.circle.fill"
        case .cancelled:
            return "xmark.circle"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    private var statusTint: Color {
        switch model.fileTranscription.phase {
        case .idle:
            return .secondary
        case .generating:
            return .blue
        case .completed:
            return .green
        case .cancelled:
            return .orange
        case .failed:
            return .red
        }
    }

    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropLeading
        return formatter
    }()
}

private struct HotkeysSettings: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsSection("Trigger Mode", systemImage: "switch.2") {
                Picker("Trigger mode", selection: binding(\.hotkeyMode)) {
                    Text("Hold to dictate").tag(HotkeyMode.pushToTalk)
                    Text("Press to toggle").tag(HotkeyMode.toggle)
                }
                .pickerStyle(.segmented)
                .frame(width: 340)
            }

            SettingsSection("Shortcut", systemImage: "keyboard") {
                Picker("Preset", selection: Binding(
                    get: { model.settings.hotkeyPreset },
                    set: { preset in
                        model.settings.hotkeyPreset = preset
                        model.settings.hotKeyDescription = preset.label
                    }
                )) {
                    ForEach(HotkeyPreset.allCases) { preset in
                        Text(preset.label).tag(preset)
                    }
                }
                .frame(width: 360)

                InfoLine("Current shortcut", effectiveShortcut)

                if model.settings.hotkeyPreset == .custom {
                    KeyboardShortcuts.Recorder("Custom shortcut", name: .dictation)
                        .onAppear {
                            model.settings.hotKeyDescription = KeyboardShortcuts.Name.dictation.shortcut?.description ?? "Custom shortcut"
                        }
                        .accessibilityLabel("Custom dictation shortcut")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended macOS settings for Fn")
                        .font(.callout.weight(.semibold))
                    Text("In macOS Keyboard settings, set Dictation shortcut to Press Mic / F5 and set Press Globe key to Do Nothing. This frees Fn for VachaVox and is the tested setup for hold-to-dictate and toggle mode.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        SystemSettingsOpener.openKeyboardSettings()
                    } label: {
                        Label("Open Keyboard Settings", systemImage: "keyboard")
                    }
                    .accessibilityLabel("Open Keyboard Settings")
                }
                .padding(.top, 2)
            }

            SettingsSection("Behavior Summary", systemImage: "text.alignleft") {
                Text(behaviorSummary)
                    .font(.callout)
                    .foregroundStyle(.primary)
            }
        }
    }

    private var effectiveShortcut: String {
        if model.settings.hotkeyPreset == .custom {
            return KeyboardShortcuts.Name.dictation.shortcut?.description ?? model.settings.hotKeyDescription
        }
        return model.settings.hotkeyPreset.label
    }

    private var behaviorSummary: String {
        switch model.settings.hotkeyMode {
        case .pushToTalk:
            return "Hold \(effectiveShortcut) while speaking. Release it to stop."
        case .toggle:
            return "Press \(effectiveShortcut) once to start and again to stop."
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        Binding(
            get: { model.settings[keyPath: keyPath] },
            set: { model.settings[keyPath: keyPath] = $0 }
        )
    }
}

private struct PermissionsSettings: View {
    @ObservedObject var model: AppModel
    let coordinator: DictationCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsSection("Required Access", systemImage: "hand.raised") {
                PermissionRow(
                    title: "Microphone",
                    status: microphoneStatus,
                    detail: "Required to record speech for dictation.",
                    symbolName: model.microphonePermission == .granted ? "mic" : "mic.slash",
                    tint: model.microphonePermission == .granted ? .green : .orange,
                    primaryActionTitle: "Open Settings",
                    primaryAction: { coordinator.openMicrophonePrivacySettings() },
                    secondaryActionTitle: "Re-check",
                    secondaryAction: { coordinator.refreshPermissions() }
                )

                Divider()

                PermissionRow(
                    title: "Accessibility",
                    status: accessibilityStatus,
                    detail: accessibilityDetail,
                    symbolName: model.accessibilityTrusted ? "hand.raised.fill" : "hand.raised",
                    tint: accessibilityTint,
                    primaryActionTitle: model.accessibilityTrusted ? "Open Settings" : "Request Access",
                    primaryAction: { coordinator.requestAccessibilityPermission() },
                    secondaryActionTitle: "Re-check",
                    secondaryAction: { coordinator.refreshPermissions() }
                )

                if !model.accessibilityTrusted && model.settings.outputMode == .paste {
                    InlineNote(
                        symbolName: "hand.raised",
                        title: "Paste mode needs Accessibility trust",
                        detail: "After enabling VachaVox in System Settings, return here and re-check. Copy and Preview remain available without this access.",
                        tint: .orange
                    )
                }
            }
        }
    }

    private var microphoneStatus: String {
        switch model.microphonePermission {
        case .granted:
            return "Granted"
        case .denied:
            return "Denied"
        case .unknown:
            return "Will ask when needed"
        }
    }

    private var accessibilityStatus: String {
        if model.accessibilityTrusted {
            return "Trusted"
        }
        if model.settings.outputMode == .paste {
            return "Needs access for Paste"
        }
        return "Not needed for \(model.settings.outputMode.label)"
    }

    private var accessibilityTint: Color {
        if model.accessibilityTrusted {
            return .green
        }
        return model.settings.outputMode == .paste ? .orange : Color(nsColor: .secondaryLabelColor)
    }

    private var accessibilityDetail: String {
        if model.settings.outputMode == .paste {
            return "Required only to paste directly into the previous focused app."
        }
        return "Copy and Preview do not require Accessibility. Paste mode will ask when selected."
    }
}

private struct PrivacySettings: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsSection("Your Data", systemImage: "lock.shield") {
                PrivacyPromiseRow(symbolName: "mic", text: "Audio is recorded only while dictation is active.")
                PrivacyPromiseRow(symbolName: "desktopcomputer", text: "Transcription runs locally on this Mac.")
                PrivacyPromiseRow(symbolName: "text.quote", text: "Dictation transcripts are not stored unless you explicitly generate a file transcript.")
            }

            SettingsSection("Local Storage", systemImage: "internaldrive") {
                InfoLine("Models folder", ModelStore.defaultRootURL.path)
                Button("Reveal Models Folder") {
                    revealModelsFolder()
                }
            }

            SettingsSection("About", systemImage: "info.circle") {
                InfoLine("Version", "\(bundleVersion) (\(bundleBuild))")
                InfoLine("Selected engine", model.selectedCatalogModel.engine.label)
                InfoLine("License", "AGPLv3")
                Text("Dependencies: WhisperKit, KeyboardShortcuts, and FluidAudio.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            SettingsSection("Diagnostics", systemImage: "doc.on.clipboard") {
                Text("Diagnostics exclude transcript content and audio.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Copy Diagnostics") {
                    copyDiagnostics()
                }
            }
        }
    }

    private var bundleVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.6.3"
    }

    private var bundleBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "23"
    }

    private func revealModelsFolder() {
        let url = ModelStore.defaultRootURL
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func copyDiagnostics() {
        let diagnostics = [
            "VachaVox \(bundleVersion) (\(bundleBuild))",
            "Readiness: \(model.readinessState.title)",
            "Selected model: \(model.selectedCatalogModel.displayName)",
            "Model status: \(model.selectedCatalogModel.status.label)",
            "Output mode: \(model.settings.outputMode.label)",
            "Hotkey mode: \(model.settings.hotkeyMode.label)",
            "Microphone: \(model.microphonePermission.rawValue)",
            "Accessibility trusted: \(model.accessibilityTrusted)",
            "Models folder: \(ModelStore.defaultRootURL.path)",
        ].joined(separator: "\n")

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(diagnostics, forType: .string)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content

    init(_ title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(2)
        }
        .groupBoxStyle(.automatic)
    }
}

private struct StatusSummary: View {
    let state: ReadinessState

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: state.symbolName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(state.tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(state.title)
                    .font(.title3.weight(.semibold))
                Text(state.detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

private enum ChecklistState {
    case ok
    case warning
    case neutral

    var tint: Color {
        switch self {
        case .ok:
            return .green
        case .warning:
            return .orange
        case .neutral:
            return Color(nsColor: .secondaryLabelColor)
        }
    }
}

private struct ReadinessChecklistRow: View {
    let title: String
    let value: String
    let detail: String
    let symbolName: String
    let state: ChecklistState
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        title: String,
        value: String,
        detail: String,
        symbolName: String,
        state: ChecklistState,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.detail = detail
        self.symbolName = symbolName
        self.state = state
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(state.tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.callout.weight(.medium))
                    Text(value)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .controlSize(.small)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ModelRowView: View {
    let descriptor: LocalModelDescriptor
    let isSelected: Bool
    let primaryTitle: String
    let primarySystemImage: String
    let primaryDisabled: Bool
    let primaryProminent: Bool
    let primaryAction: () -> Void
    let reveal: (() -> Void)?
    let openSource: () -> Void
    let delete: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: descriptor.engine == .parakeet ? "waveform.path.ecg" : "text.bubble")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.tint)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(descriptor.displayName)
                        .font(.headline)
                    if isSelected {
                        Text("Selected")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.tint)
                    }
                    Spacer()
                    StatusBadge(status: descriptor.status)
                }
                Text("\(descriptor.sizeDescription) · \(descriptor.languageDescription) · \(descriptor.recommendedRAM) RAM")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                if case .error(let message) = descriptor.status {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }
                if let progress = descriptor.status.downloadProgress {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .accessibilityLabel("Download progress")
                        .accessibilityValue("\(Int(progress * 100)) percent")
                } else if descriptor.status == .loading {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel("Loading model")
                }
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 8) {
                primaryButton
                secondaryMenu
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color(nsColor: .separatorColor).opacity(0.35), lineWidth: isSelected ? 1.5 : 1)
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var primaryButton: some View {
        if primaryProminent {
            Button(action: primaryAction) {
                Label(primaryTitle, systemImage: primarySystemImage)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(primaryDisabled)
        } else {
            Button(action: primaryAction) {
                Label(primaryTitle, systemImage: primarySystemImage)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(primaryDisabled)
        }
    }

    private var secondaryMenu: some View {
        Menu {
            if let reveal {
                Button("Reveal \(descriptor.displayName) in Finder", action: reveal)
            }
            Button("Open Source", action: openSource)
                .disabled(descriptor.downloadURL == nil)
            if let delete {
                Divider()
                Button("Delete \(descriptor.displayName)", role: .destructive, action: delete)
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .help("More actions for \(descriptor.displayName)")
        .accessibilityLabel("More actions for \(descriptor.displayName)")
    }
}

private struct PermissionRow: View {
    let title: String
    let status: String
    let detail: String
    let symbolName: String
    let tint: Color
    let primaryActionTitle: String
    let primaryAction: () -> Void
    let secondaryActionTitle: String?
    let secondaryAction: (() -> Void)?

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                    StatusPill(title: status, symbolName: symbolName, tint: tint)
                }
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                if let secondaryActionTitle, let secondaryAction {
                    Button(secondaryActionTitle, action: secondaryAction)
                }
                Button(primaryActionTitle, action: primaryAction)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct InlineNote: View {
    let symbolName: String
    let title: String
    let detail: String
    let tint: Color
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        symbolName: String,
        title: String,
        detail: String,
        tint: Color,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.symbolName = symbolName
        self.title = title
        self.detail = detail
        self.tint = tint
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbolName)
                .foregroundStyle(tint)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.callout.weight(.medium))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .controlSize(.small)
                }
            }
        }
        .padding(10)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct EmptyState: View {
    let symbolName: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct PrivacyPromiseRow: View {
    let symbolName: String
    let text: String

    var body: some View {
        Label(text, systemImage: symbolName)
            .font(.callout)
    }
}

private struct StatusBadge: View {
    let status: ModelStatus

    var body: some View {
        StatusPill(title: status.shortLabel, symbolName: status.symbolName, tint: status.tint)
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

private struct InfoLine: View {
    let title: String
    let value: String

    init(_ title: String, _ value: String) {
        self.title = title
        self.value = value
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(value)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
        .font(.callout)
        .accessibilityElement(children: .combine)
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

    var isBlocking: Bool {
        switch self {
        case .needsModel, .needsModelLoad, .needsMicrophone, .needsAccessibilityForPaste, .loadingModel, .transcribing, .modelLoadFailed, .error:
            return true
        case .ready, .paused, .listening:
            return false
        }
    }
}

private extension ModelStatus {
    var shortLabel: String {
        switch self {
        case .error:
            return "Needs attention"
        default:
            return label
        }
    }

    var downloadProgress: Double? {
        if case .downloading(let progress) = self {
            return progress
        }
        return nil
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

private extension PerformanceMode {
    var settingsLabel: String {
        switch self {
        case .fastest:
            return "Speed"
        case .balanced:
            return "Balanced"
        case .highestAccuracy:
            return "Accuracy"
        }
    }
}

@MainActor
final class SettingsWindowController {
    private let model: AppModel
    private let coordinator: DictationCoordinator
    private var window: NSWindow?

    init(model: AppModel, coordinator: DictationCoordinator) {
        self.model = model
        self.coordinator = coordinator
        self.window = Self.makeWindow(model: model, coordinator: coordinator)
    }

    private static func makeWindow(model: AppModel, coordinator: DictationCoordinator) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 950, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.title = "VachaVox Settings"
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .preference
        window.minSize = NSSize(width: 980, height: 640)
        window.center()
        window.contentViewController = NSHostingController(
            rootView: SettingsView(model: model, coordinator: coordinator)
        )
        return window
    }

    func show() {
        if window == nil {
            window = Self.makeWindow(model: model, coordinator: coordinator)
        }
        guard let window else { return }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
