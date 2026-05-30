import AppKit
import AVFoundation
import Foundation
import UniformTypeIdentifiers

@MainActor
final class DictationCoordinator {
    private let model: AppModel
    private let permissionsService: PermissionsService
    private let audioCaptureService: AudioCaptureService
    private let voiceActivityService: VoiceActivityService
    private let modelStore: ModelStore
    private let modelDownloadService: ModelDownloadService
    private let transcriptionEngine: TranscriptionEngine
    private let outputService: TextOutputService
    private let fileTranscriptionService: FileTranscriptionService

    private var isSessionActive = false
    private var isModelOperationActive = false
    private var permissionPollTask: Task<Void, Never>?
    private var fileTranscriptionTask: Task<Void, Never>?
    private var popupDismissTask: Task<Void, Never>?
    private var activePasteTarget: OutputTargetSnapshot?

    init(
        model: AppModel,
        permissionsService: PermissionsService,
        audioCaptureService: AudioCaptureService,
        voiceActivityService: VoiceActivityService,
        modelStore: ModelStore,
        modelDownloadService: ModelDownloadService,
        transcriptionEngine: TranscriptionEngine,
        outputService: TextOutputService,
        fileTranscriptionService: FileTranscriptionService = FileTranscriptionService()
    ) {
        self.model = model
        self.permissionsService = permissionsService
        self.audioCaptureService = audioCaptureService
        self.voiceActivityService = voiceActivityService
        self.modelStore = modelStore
        self.modelDownloadService = modelDownloadService
        self.transcriptionEngine = transcriptionEngine
        self.outputService = outputService
        self.fileTranscriptionService = fileTranscriptionService
    }

    func toggleDictation() {
        if isSessionActive {
            stopDictation()
        } else {
            startDictation()
        }
    }

    func startDictation() {
        guard model.canRecord else { return }
        guard !isSessionActive else { return }
        refreshModels()
        let selectedModel = model.selectedCatalogModel
        guard selectedModel.status.isUsable else {
            model.modelStatus = selectedModel.status
            model.statusMessage = "No model installed"
            return
        }
        guard model.selectedModelIsLoaded else {
            model.statusMessage = "Load \(selectedModel.displayName) before dictating"
            return
        }

        model.recordingOverlayAnchor = RecordingOverlayAnchorResolver.resolve()
        activePasteTarget = outputService.capturePasteTarget()

        Task { @MainActor in
            model.statusMessage = "Checking microphone"
            let permission = await permissionsService.requestMicrophonePermission()
            model.microphonePermission = permission
            guard permission == .granted else {
                activePasteTarget = nil
                model.setError("Microphone access is required")
                return
            }

            do {
                try audioCaptureService.start { [weak model] level in
                    Task { @MainActor in
                        model?.inputLevel = level
                    }
                }
                isSessionActive = true
                model.phase = .listening
                model.statusMessage = "Listening"
            } catch {
                activePasteTarget = nil
                model.setError(error.localizedDescription)
            }
        }
    }

    func stopDictation() {
        guard isSessionActive else { return }
        isSessionActive = false

        let recording = audioCaptureService.stop()
        model.inputLevel = 0
        guard recording.duration >= 0.2 else {
            activePasteTarget = nil
            model.resetStatus()
            return
        }

        Task { @MainActor in
            do {
                model.phase = .transcribing
                model.statusMessage = "Transcribing locally"

                let trimmed = voiceActivityService.trim(
                    recording,
                    sensitivity: model.settings.silenceSensitivity
                )
                guard trimmed.duration >= 0.35 else {
                    activePasteTarget = nil
                    model.resetStatus()
                    return
                }

                refreshModels()
                let selectedModel = model.selectedModel
                model.modelStatus = modelStore.status(for: selectedModel)
                guard model.modelStatus.isUsable else {
                    throw TranscriptionError.engineUnavailable("\(selectedModel.displayName) is missing. Install or download a local model in Settings.")
                }
                guard model.selectedModelIsLoaded else {
                    throw TranscriptionError.engineUnavailable("\(selectedModel.displayName) is installed but not loaded. Load it in Settings before dictating.")
                }
                try await transcriptionEngine.prepare(model: selectedModel)
                let result = try await transcriptionEngine.transcribe(
                    TranscriptionRequest(
                        samples16k: trimmed.samples16k,
                        duration: trimmed.duration,
                        punctuationEnabled: model.settings.punctuationEnabled
                    )
                )

                let transcript = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !transcript.isEmpty else {
                    activePasteTarget = nil
                    model.resetStatus()
                    return
                }

                model.lastTranscript = transcript
                let delivery = try await outputService.deliver(
                    transcript,
                    mode: model.settings.outputMode,
                    pasteTarget: activePasteTarget
                )
                presentResultPopup(with: transcript)
                activePasteTarget = nil
                completeWithStatus(delivery.statusMessage)
            } catch {
                activePasteTarget = nil
                model.setError(error.localizedDescription)
            }
        }
    }

    func setPaused(_ isPaused: Bool) {
        model.settings.isPaused = isPaused
        popupDismissTask?.cancel()
        popupDismissTask = nil
        model.popupResultVisible = false
        model.popupResultFading = false
        model.popupResultText = ""
        if isPaused, isSessionActive {
            _ = audioCaptureService.stop()
            isSessionActive = false
            activePasteTarget = nil
        }
        model.recordingOverlayAnchor = nil
        model.resetStatus()
    }

    func refreshModels() {
        model.modelCatalog = modelStore.scannedCatalog()
        model.modelStatus = modelStore.status(for: model.selectedModel)
    }

    func refreshPermissions() {
        model.microphonePermission = permissionsService.microphonePermission
        model.accessibilityTrusted = permissionsService.isAccessibilityTrusted(prompt: false)
        model.statusMessage = "Permissions refreshed"
    }

    func openMicrophonePrivacySettings() {
        SystemSettingsOpener.openMicrophonePrivacy()
        pollPermissionStatus()
    }

    func requestAccessibilityPermission() {
        _ = permissionsService.requestAccessibilityPermission()
        SystemSettingsOpener.openAccessibilityPrivacy()
        pollPermissionStatus()
    }

    func selectModel(_ descriptor: LocalModelDescriptor) {
        model.settings.selectedEngine = descriptor.engine
        model.settings.selectedModelID = descriptor.id
        if model.modelLoadState.loadedModelID != descriptor.id {
            model.modelLoadState = .notLoaded
        }
        refreshModels()
    }

    func loadSelectedModel() {
        loadModel(model.selectedModel, successMessage: "Ready to dictate")
    }

    func useModel(_ descriptor: LocalModelDescriptor) {
        selectModel(descriptor)
        loadModel(descriptor, successMessage: "Ready to dictate")
    }

    func loadBestAvailableModelOnLaunch() {
        refreshModels()
        let selected = model.selectedCatalogModel
        if selected.status.isUsable {
            loadModel(selected, successMessage: "Ready to dictate")
            return
        }

        guard let descriptor = ModelCatalog.bestAvailable(from: model.modelCatalog) else {
            model.modelStatus = .missing
            model.modelLoadState = .notLoaded
            model.statusMessage = "No local model found"
            return
        }

        model.settings.selectedEngine = descriptor.engine
        model.settings.selectedModelID = descriptor.id
        loadModel(descriptor, successMessage: "Ready to dictate using \(descriptor.displayName)")
    }

    private func loadModel(_ descriptor: LocalModelDescriptor, successMessage: String) {
        guard !isModelOperationActive else {
            model.statusMessage = "Model operation already in progress"
            return
        }
        isModelOperationActive = true
        Task { @MainActor in
            defer { isModelOperationActive = false }
            do {
                model.phase = .transcribing
                model.statusMessage = "Loading \(descriptor.displayName)"
                model.modelStatus = .loading
                model.modelLoadState = .loading(
                    modelID: descriptor.id,
                    displayName: descriptor.displayName,
                    startedAt: Date()
                )
                setStatus(.loading, for: descriptor)
                try await transcriptionEngine.prepare(model: descriptor)
                model.modelStatus = .ready
                model.modelLoadState = .loaded(
                    modelID: descriptor.id,
                    displayName: descriptor.displayName,
                    engine: descriptor.engine,
                    loadedAt: Date()
                )
                setStatus(.ready, for: descriptor)
                completeWithStatus(successMessage)
            } catch {
                let status = ModelStatus.error(error.localizedDescription)
                model.modelStatus = status
                model.modelLoadState = .failed(
                    modelID: descriptor.id,
                    message: error.localizedDescription,
                    failedAt: Date()
                )
                setStatus(status, for: descriptor)
                model.setError(error.localizedDescription)
            }
        }
    }

    func download(_ descriptor: LocalModelDescriptor) {
        guard !isModelOperationActive else {
            model.statusMessage = "Model operation already in progress"
            return
        }
        isModelOperationActive = true
        Task { @MainActor in
            defer { isModelOperationActive = false }
            do {
                model.statusMessage = "Downloading \(descriptor.displayName)"
                try await modelDownloadService.download(descriptor) { [weak model] progress in
                    Task { @MainActor in
                        guard let model else { return }
                        model.modelCatalog = model.modelCatalog.map { item in
                            guard item.id == descriptor.id else { return item }
                            var copy = item
                            copy.status = .downloading(progress)
                            return copy
                        }
                    }
                }
                refreshModels()
                model.statusMessage = "Downloaded \(descriptor.displayName)"
            } catch {
                let status = ModelStatus.error(error.localizedDescription)
                model.modelStatus = status
                setStatus(status, for: descriptor)
                model.setError(error.localizedDescription)
                refreshModels()
            }
        }
    }

    func delete(_ descriptor: LocalModelDescriptor) {
        guard !isModelOperationActive else {
            model.statusMessage = "Model operation already in progress"
            return
        }
        do {
            let urls = [modelStore.modelURL(for: descriptor), modelStore.legacyModelURL(for: descriptor)].compactMap { $0 }
            for url in urls where FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            let deletedSelectedModel = descriptor.id == model.settings.selectedModelID
            refreshModels()
            if deletedSelectedModel {
                if let fallback = ModelCatalog.bestAvailable(from: model.modelCatalog) {
                    model.settings.selectedEngine = fallback.engine
                    model.settings.selectedModelID = fallback.id
                    model.modelStatus = fallback.status
                    model.modelLoadState = .notLoaded
                    model.statusMessage = "Deleted \(descriptor.displayName). Switched to \(fallback.displayName)."
                } else {
                    model.modelStatus = .missing
                    model.modelLoadState = .notLoaded
                    model.statusMessage = "Deleted \(descriptor.displayName). No local model installed."
                }
            } else {
                if model.modelLoadState.loadedModelID == descriptor.id {
                    model.modelLoadState = .notLoaded
                }
                model.statusMessage = "Deleted \(descriptor.displayName)"
            }
        } catch {
            model.setError(error.localizedDescription)
        }
    }

    func reveal(_ descriptor: LocalModelDescriptor) {
        let url = modelStore.modelURL(for: descriptor)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func chooseAudioFileForTranscription() {
        let panel = NSOpenPanel()
        panel.title = "Choose Audio File"
        panel.prompt = "Choose"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.audio]

        guard panel.runModal() == .OK, let url = panel.url else { return }
        model.fileTranscription.selectedAudioFileURL = url
        model.fileTranscription.selectedAudioFileName = url.lastPathComponent
        model.fileTranscription.selectedAudioFileDuration = nil
        model.fileTranscription.phase = .idle
        model.fileTranscription.progressFraction = nil
        model.fileTranscription.completedOutputURL = nil
        model.fileTranscription.errorMessage = nil
        model.fileTranscription.statusMessage = "Ready to generate a Markdown transcript."

        Task { @MainActor in
            model.fileTranscription.selectedAudioFileDuration = await Self.audioDuration(for: url)
        }
    }

    func generateFileTranscript() {
        guard fileTranscriptionTask == nil else { return }
        guard let sourceURL = model.fileTranscription.selectedAudioFileURL else {
            setFileTranscriptionError("Choose an audio file before generating a transcript")
            return
        }

        refreshModels()
        let selectedModel = model.selectedCatalogModel
        guard selectedModel.status.isUsable, model.selectedModelIsLoaded else {
            setFileTranscriptionError("Load the selected model before generating a file transcript")
            return
        }

        model.fileTranscription.phase = .generating
        model.fileTranscription.progressFraction = 0
        model.fileTranscription.completedOutputURL = nil
        model.fileTranscription.errorMessage = nil
        model.fileTranscription.statusMessage = "Preparing audio file"

        fileTranscriptionTask = Task { @MainActor in
            defer { fileTranscriptionTask = nil }
            do {
                try await transcriptionEngine.prepare(model: selectedModel)
                let result = try await transcriptionEngine.transcribeFile(
                    sourceURL,
                    punctuationEnabled: model.settings.punctuationEnabled
                ) { [weak model] fraction, message in
                    Task { @MainActor in
                        guard let model, model.fileTranscription.isGenerating else { return }
                        model.fileTranscription.progressFraction = min(max(fraction, 0), 1)
                        model.fileTranscription.statusMessage = message
                    }
                }
                try Task.checkCancellation()
                let transcript = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !transcript.isEmpty else {
                    throw TranscriptionError.emptyAudio
                }
                let writeResult = try fileTranscriptionService.writeTranscript(
                    sourceURL: sourceURL,
                    transcript: transcript,
                    model: selectedModel
                )
                try Task.checkCancellation()
                model.fileTranscription.phase = .completed
                model.fileTranscription.progressFraction = 1
                model.fileTranscription.completedOutputURL = writeResult.outputURL
                model.fileTranscription.errorMessage = nil
                model.fileTranscription.statusMessage = "Saved Markdown transcript"
            } catch is CancellationError {
                model.fileTranscription.phase = .cancelled
                model.fileTranscription.progressFraction = nil
                model.fileTranscription.statusMessage = "File transcription cancelled"
            } catch {
                setFileTranscriptionError(error.localizedDescription)
            }
        }
    }

    func cancelFileTranscript() {
        fileTranscriptionTask?.cancel()
        Task {
            await transcriptionEngine.cancel()
        }
        model.fileTranscription.phase = .cancelled
        model.fileTranscription.progressFraction = nil
        model.fileTranscription.statusMessage = "File transcription cancelled"
    }

    func revealFileTranscriptOutput() {
        guard let url = model.fileTranscription.completedOutputURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func openFileTranscriptionSettings() {
        model.selectedSettingsTab = .fileTranscription
    }

    private func setStatus(_ status: ModelStatus, for descriptor: LocalModelDescriptor) {
        model.modelCatalog = model.modelCatalog.map { item in
            guard item.id == descriptor.id else { return item }
            var copy = item
            copy.status = status
            return copy
        }
    }

    private func completeWithStatus(_ message: String) {
        model.recordingOverlayAnchor = nil
        if model.settings.isPaused {
            model.phase = .paused
            model.statusMessage = "Paused"
        } else {
            model.phase = .idle
            model.statusMessage = message
        }
    }

    private func presentResultPopup(with transcript: String) {
        guard let clipped = Self.formattedPopupText(from: transcript) else { return }

        popupDismissTask?.cancel()
        model.popupResultText = clipped
        model.popupResultFading = false
        model.popupResultVisible = true

        popupDismissTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            self.model.popupResultFading = true
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            self.model.popupResultVisible = false
            self.model.popupResultFading = false
            self.model.popupResultText = ""
        }
    }

    static func formattedPopupText(from transcript: String) -> String? {
        let normalized = transcript
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }

        let maxCharacters = 250
        if normalized.count > maxCharacters {
            return String(normalized.prefix(maxCharacters - 1)) + "…"
        }
        return normalized
    }

    private func pollPermissionStatus() {
        permissionPollTask?.cancel()
        permissionPollTask = Task { [weak self] in
            for _ in 0..<30 {
                if Task.isCancelled { return }

                self?.updatePermissionStatusFromPoll()

                if self?.hasCurrentPermissions == true {
                    return
                }

                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    private func updatePermissionStatusFromPoll() {
        model.microphonePermission = permissionsService.microphonePermission
        model.accessibilityTrusted = permissionsService.isAccessibilityTrusted(prompt: false)
    }

    private var hasCurrentPermissions: Bool {
        model.microphonePermission == .granted &&
            (model.settings.outputMode != .paste || model.accessibilityTrusted)
    }

    private func setFileTranscriptionError(_ message: String) {
        model.fileTranscription.phase = .failed
        model.fileTranscription.progressFraction = nil
        model.fileTranscription.completedOutputURL = nil
        model.fileTranscription.errorMessage = message
        model.fileTranscription.statusMessage = message
    }

    private static func audioDuration(for url: URL) async -> TimeInterval? {
        let asset = AVURLAsset(url: url)
        guard let duration = try? await asset.load(.duration) else { return nil }
        let seconds = CMTimeGetSeconds(duration)
        guard seconds.isFinite, seconds > 0 else { return nil }
        return seconds
    }
}
