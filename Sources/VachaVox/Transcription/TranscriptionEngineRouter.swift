import Foundation

actor TranscriptionEngineRouter: TranscriptionEngine {
    private let parakeet: FluidAudioParakeetTranscriptionEngine
    private let whisperKit: WhisperKitTranscriptionEngine
    private var active: (any TranscriptionEngine)?

    init(modelStore: ModelStore = ModelStore()) {
        self.parakeet = FluidAudioParakeetTranscriptionEngine(modelStore: modelStore)
        self.whisperKit = WhisperKitTranscriptionEngine(modelStore: modelStore)
    }

    func prepare(model: LocalModelDescriptor) async throws {
        let engine: any TranscriptionEngine
        switch model.engine {
        case .parakeet:
            engine = parakeet
        case .whisperKit:
            engine = whisperKit
        }
        try await engine.prepare(model: model)
        active = engine
    }

    func transcribe(_ request: TranscriptionRequest) async throws -> TranscriptionResult {
        guard let active else {
            throw TranscriptionError.engineUnavailable("No transcription engine is loaded")
        }
        return try await active.transcribe(request)
    }

    func transcribeFile(
        _ url: URL,
        punctuationEnabled: Bool,
        progress: @escaping @Sendable (Double, String) -> Void
    ) async throws -> TranscriptionResult {
        guard let active else {
            throw TranscriptionError.engineUnavailable("No transcription engine is loaded")
        }
        return try await active.transcribeFile(url, punctuationEnabled: punctuationEnabled, progress: progress)
    }

    func cancel() async {
        await active?.cancel()
    }
}
