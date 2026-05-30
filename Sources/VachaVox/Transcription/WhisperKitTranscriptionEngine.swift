import Foundation
@preconcurrency import AVFoundation
import WhisperKit

actor WhisperKitTranscriptionEngine: TranscriptionEngine {
    private var kit: WhisperKit?
    private var loadedModelID: String?
    private let modelStore: ModelStore

    init(modelStore: ModelStore = ModelStore()) {
        self.modelStore = modelStore
    }

    func prepare(model: LocalModelDescriptor) async throws {
        guard model.engine == .whisperKit else {
            throw TranscriptionError.engineUnavailable("Selected model is not a WhisperKit model")
        }
        guard loadedModelID != model.id else { return }
        guard modelStore.status(for: model).isUsable else {
            throw TranscriptionError.engineUnavailable("\(model.displayName) is not installed in \(modelStore.modelURL(for: model).path)")
        }

        let configuration = WhisperKitConfig(
            model: model.id,
            modelFolder: modelStore.modelURL(for: model).path,
            verbose: false,
            prewarm: false,
            load: false,
            download: false
        )
        let newKit = try await WhisperKit(configuration)
        try await newKit.loadModels()
        try await newKit.prewarmModels()
        kit = newKit
        loadedModelID = model.id
    }

    func transcribe(_ request: TranscriptionRequest) async throws -> TranscriptionResult {
        guard !request.samples16k.isEmpty else {
            throw TranscriptionError.emptyAudio
        }
        guard let kit else {
            throw TranscriptionError.engineUnavailable("WhisperKit model is not loaded")
        }

        let results = await kit.transcribe(
            audioArrays: [request.samples16k],
            decodeOptions: DecodingOptions(skipSpecialTokens: true, withoutTimestamps: true)
        )
        let text = results.first??.map { $0.text }.joined(separator: " ") ?? ""
        return TranscriptionResult(text: text)
    }

    func transcribeFile(
        _ url: URL,
        punctuationEnabled: Bool,
        progress: @escaping @Sendable (Double, String) -> Void
    ) async throws -> TranscriptionResult {
        progress(0.05, "Reading audio file")
        let samples = try Self.samples16kMono(from: url)
        progress(0.25, "Transcribing locally")
        let result = try await transcribe(
            TranscriptionRequest(
                samples16k: samples,
                duration: Double(samples.count) / 16_000,
                punctuationEnabled: punctuationEnabled
            )
        )
        progress(0.9, "Formatting transcript")
        return result
    }

    func cancel() async {}

    private static func samples16kMono(from url: URL) throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        let inputFormat = file.processingFormat
        guard let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16_000,
            channels: 1,
            interleaved: false
        ) else {
            throw TranscriptionError.engineUnavailable("Could not create an audio conversion format")
        }
        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            throw TranscriptionError.engineUnavailable("Could not prepare audio conversion")
        }

        let inputCapacity = AVAudioFrameCount(file.length)
        guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: inputCapacity) else {
            throw TranscriptionError.engineUnavailable("Could not read the audio file")
        }
        try file.read(into: inputBuffer)

        let ratio = outputFormat.sampleRate / inputFormat.sampleRate
        let outputCapacity = AVAudioFrameCount(Double(inputBuffer.frameLength) * ratio) + 1024
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputCapacity) else {
            throw TranscriptionError.engineUnavailable("Could not convert the audio file")
        }

        var didProvideInput = false
        var conversionError: NSError?
        converter.convert(to: outputBuffer, error: &conversionError) { _, outStatus in
            if didProvideInput {
                outStatus.pointee = .noDataNow
                return nil
            }
            didProvideInput = true
            outStatus.pointee = .haveData
            return inputBuffer
        }
        if let conversionError {
            throw conversionError
        }
        guard let channel = outputBuffer.floatChannelData?[0], outputBuffer.frameLength > 0 else {
            throw TranscriptionError.emptyAudio
        }
        return Array(UnsafeBufferPointer(start: channel, count: Int(outputBuffer.frameLength)))
    }
}
