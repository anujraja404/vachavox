import Foundation
import FluidAudio

actor FluidAudioParakeetTranscriptionEngine: TranscriptionEngine {
    private var manager: AsrManager?
    private var loadedModelID: String?
    private let modelStore: ModelStore

    init(modelStore: ModelStore = ModelStore()) {
        self.modelStore = modelStore
    }

    func prepare(model: LocalModelDescriptor) async throws {
        guard model.engine == .parakeet else {
            throw TranscriptionError.engineUnavailable("Selected model is not a Parakeet model")
        }
        guard loadedModelID != model.id else { return }
        guard modelStore.status(for: model).isUsable else {
            throw TranscriptionError.engineUnavailable("\(model.displayName) is not installed in \(modelStore.modelURL(for: model).path)")
        }
        guard let spec = model.parakeetSpec else {
            throw TranscriptionError.engineUnavailable("Unsupported Parakeet model \(model.id)")
        }

        let models = try await AsrModels.load(
            from: modelStore.modelURL(for: model),
            version: spec.version
        )
        let asrManager = AsrManager(config: .default)
        try await asrManager.loadModels(models)
        manager = asrManager
        loadedModelID = model.id
    }

    func transcribe(_ request: TranscriptionRequest) async throws -> TranscriptionResult {
        guard !request.samples16k.isEmpty else {
            throw TranscriptionError.emptyAudio
        }
        guard let manager else {
            throw TranscriptionError.engineUnavailable("Transcription model is not loaded")
        }

        var decoderState = TdtDecoderState.make(decoderLayers: await manager.decoderLayerCount)
        let result = try await manager.transcribe(request.samples16k, decoderState: &decoderState)
        return TranscriptionResult(text: result.text)
    }

    func transcribeFile(
        _ url: URL,
        punctuationEnabled: Bool,
        progress: @escaping @Sendable (Double, String) -> Void
    ) async throws -> TranscriptionResult {
        guard let manager else {
            throw TranscriptionError.engineUnavailable("Transcription model is not loaded")
        }

        progress(0.05, "Preparing audio file")
        var decoderState = TdtDecoderState.make(decoderLayers: await manager.decoderLayerCount)
        progress(0.15, "Transcribing locally")
        let result = try await manager.transcribe(url, decoderState: &decoderState)
        progress(0.9, "Formatting transcript")
        return TranscriptionResult(text: result.text)
    }

    func cancel() async {}
}
