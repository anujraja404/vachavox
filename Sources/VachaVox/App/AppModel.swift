import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var phase: DictationPhase = .idle
    @Published var statusMessage = "Ready"
    @Published var inputLevel: Double = 0
    @Published var microphonePermission: PermissionState = .unknown
    @Published var accessibilityTrusted = false
    @Published var modelCatalog = ModelCatalog.descriptors
    @Published var modelStatus: ModelStatus = .missing
    @Published var modelLoadState: ModelLoadState = .notLoaded
    @Published var lastTranscript = ""
    @Published var popupResultText = ""
    @Published var popupResultVisible = false
    @Published var popupResultFading = false
    @Published var recordingOverlayAnchor: RecordingOverlayAnchor?
    @Published var selectedSettingsTab: SettingsTab = .general
    @Published var fileTranscription = FileTranscriptionState()
    @Published var settings: AppSettings {
        didSet {
            settingsStore.save(settings)
        }
    }

    private let settingsStore: SettingsStore

    init(settingsStore: SettingsStore = SettingsStore()) {
        self.settingsStore = settingsStore
        self.settings = settingsStore.load()
        resetStatus()
    }

    var canRecord: Bool {
        phase != .listening && phase != .transcribing && !settings.isPaused
    }

    var selectedModel: LocalModelDescriptor {
        ModelCatalog.descriptor(for: settings.selectedModelID)
    }

    var selectedCatalogModel: LocalModelDescriptor {
        var descriptor = modelCatalog.first { $0.id == settings.selectedModelID } ?? selectedModel
        if let loadStatus = modelLoadState.status(for: descriptor) {
            descriptor.status = loadStatus
        } else if modelStatus != .missing {
            descriptor.status = modelStatus
        }
        return descriptor
    }

    var selectedModelIsLoaded: Bool {
        modelLoadState.loadedModelID == settings.selectedModelID
    }

    var loadedModelDescription: String {
        guard case .loaded(let id, let displayName, let engine, let loadedAt) = modelLoadState else {
            return "No model loaded"
        }
        let time = loadedAt.formatted(date: .omitted, time: .shortened)
        return "\(displayName) (\(engine.label)) loaded at \(time) [\(id)]"
    }

    var pasteModeNeedsAccessibility: Bool {
        settings.outputMode == .paste && !accessibilityTrusted
    }

    var readinessState: ReadinessState {
        switch phase {
        case .listening:
            return .listening
        case .transcribing:
            return .transcribing
        case .paused:
            return .paused
        case .error:
            return .error(statusMessage)
        case .idle:
            break
        }

        if microphonePermission == .denied {
            return .needsMicrophone
        }

        let selectedInstallStatus = modelCatalog.first { $0.id == settings.selectedModelID }?.status ?? modelStatus
        switch selectedInstallStatus {
        case .loading, .downloading:
            return .loadingModel
        case .installed, .ready:
            break
        case .missing, .error:
            return .needsModel
        }

        switch modelLoadState {
        case .loaded(let id, _, _, _):
            if id != settings.selectedModelID {
                return .needsModelLoad
            }
        case .loading:
            return .loadingModel
        case .failed(let id, let message, _):
            if id == settings.selectedModelID {
                return .modelLoadFailed(message)
            }
            return .needsModelLoad
        case .notLoaded:
            return .needsModelLoad
        }

        if pasteModeNeedsAccessibility {
            return .needsAccessibilityForPaste
        }

        return .ready
    }

    func resetStatus() {
        phase = settings.isPaused ? .paused : .idle
        statusMessage = settings.isPaused ? "Paused" : "Ready to dictate"
        inputLevel = 0
        recordingOverlayAnchor = nil
        popupResultText = ""
        popupResultVisible = false
        popupResultFading = false
    }

    func setError(_ message: String) {
        phase = .error
        statusMessage = message
        inputLevel = 0
        recordingOverlayAnchor = nil
        popupResultText = ""
        popupResultVisible = false
        popupResultFading = false
    }
}

enum DictationPhase: String {
    case idle
    case listening
    case transcribing
    case paused
    case error
}

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case models
    case dictation
    case fileTranscription
    case hotkeys
    case permissions
    case privacy

    var id: String { rawValue }
}

struct FileTranscriptionState: Equatable {
    var selectedAudioFileURL: URL?
    var selectedAudioFileName = ""
    var selectedAudioFileDuration: TimeInterval?
    var phase: FileTranscriptionPhase = .idle
    var progressFraction: Double?
    var statusMessage = "Choose an audio file to generate a Markdown transcript."
    var completedOutputURL: URL?
    var errorMessage: String?

    var hasSelectedFile: Bool {
        selectedAudioFileURL != nil
    }

    var isGenerating: Bool {
        phase == .generating
    }
}

enum FileTranscriptionPhase: Equatable {
    case idle
    case generating
    case completed
    case cancelled
    case failed
}

enum ModelLoadState: Equatable {
    case notLoaded
    case loading(modelID: String, displayName: String, startedAt: Date)
    case loaded(modelID: String, displayName: String, engine: TranscriptionEngineKind, loadedAt: Date)
    case failed(modelID: String, message: String, failedAt: Date)

    var loadedModelID: String? {
        if case .loaded(let modelID, _, _, _) = self {
            return modelID
        }
        return nil
    }

    var label: String {
        switch self {
        case .notLoaded:
            return "Not loaded"
        case .loading(_, let displayName, _):
            return "Loading \(displayName)"
        case .loaded(_, let displayName, let engine, let loadedAt):
            let time = loadedAt.formatted(date: .omitted, time: .shortened)
            return "\(displayName) loaded with \(engine.label) at \(time)"
        case .failed(_, let message, _):
            return "Load failed: \(message)"
        }
    }

    func status(for descriptor: LocalModelDescriptor) -> ModelStatus? {
        switch self {
        case .loading(let modelID, _, _) where modelID == descriptor.id:
            return .loading
        case .loaded(let modelID, _, _, _) where modelID == descriptor.id:
            return .ready
        case .failed(let modelID, let message, _) where modelID == descriptor.id:
            return .error(message)
        default:
            return nil
        }
    }
}

enum PermissionState: String {
    case unknown
    case granted
    case denied
}

enum ReadinessState: Equatable {
    case ready
    case paused
    case listening
    case transcribing
    case needsModel
    case needsMicrophone
    case needsAccessibilityForPaste
    case needsModelLoad
    case loadingModel
    case modelLoadFailed(String)
    case error(String)

    var title: String {
        switch self {
        case .ready:
            return "Ready to dictate"
        case .paused:
            return "Paused"
        case .listening:
            return "Listening"
        case .transcribing:
            return "Transcribing locally"
        case .needsModel:
            return "No model installed"
        case .needsMicrophone:
            return "Microphone access required"
        case .needsAccessibilityForPaste:
            return "Paste mode needs Accessibility access"
        case .needsModelLoad:
            return "Model is not loaded"
        case .loadingModel:
            return "Preparing model"
        case .modelLoadFailed:
            return "Model load failed"
        case .error:
            return "Error"
        }
    }

    var detail: String {
        switch self {
        case .ready:
            return "Local dictation can start from the menu bar or shortcut."
        case .paused:
            return "Hotkeys and menu bar start are disabled while paused."
        case .listening:
            return "Speak now. VachaVox is recording locally."
        case .transcribing:
            return "Audio is being transcribed on this Mac."
        case .needsModel:
            return "Install or select a local model before dictating."
        case .needsMicrophone:
            return "Allow microphone access so VachaVox can record speech."
        case .needsAccessibilityForPaste:
            return "Paste output needs Accessibility permission. Copy and Preview can work without it."
        case .needsModelLoad:
            return "Load the selected local model before starting dictation."
        case .loadingModel:
            return "The selected model is loading or downloading."
        case .modelLoadFailed(let message):
            return message
        case .error(let message):
            return message
        }
    }

    var symbolName: String {
        switch self {
        case .ready:
            return "checkmark.circle.fill"
        case .paused:
            return "pause.circle"
        case .listening:
            return "waveform"
        case .transcribing:
            return "ellipsis.circle"
        case .needsModel:
            return "square.stack.3d.up"
        case .needsMicrophone:
            return "mic.slash"
        case .needsAccessibilityForPaste:
            return "hand.raised"
        case .needsModelLoad:
            return "square.stack.3d.up.badge.play"
        case .loadingModel:
            return "arrow.triangle.2.circlepath"
        case .modelLoadFailed:
            return "exclamationmark.triangle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
}
