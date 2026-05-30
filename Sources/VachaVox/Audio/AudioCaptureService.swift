import AVFoundation
import Foundation

@MainActor
final class AudioCaptureService {
    private let engine = AVAudioEngine()
    private var chunks: [AudioChunk] = []
    private var isRecording = false

    func start(levelHandler: @escaping (Double) -> Void) throws {
        guard !isRecording else { return }
        chunks.removeAll(keepingCapacity: true)

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        guard format.channelCount > 0 else {
            throw AudioCaptureError.noInputDevice
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let samples = Self.extractMonoSamples(from: buffer)
            guard !samples.isEmpty else { return }
            let chunk = AudioChunk(
                samples: samples,
                sampleRate: buffer.format.sampleRate,
                timestamp: Date().timeIntervalSince1970
            )
            Task { @MainActor in
                self.chunks.append(chunk)
                levelHandler(min(1, chunk.rms * 20))
            }
        }

        engine.prepare()
        try engine.start()
        isRecording = true
    }

    func stop() -> AudioRecording {
        guard isRecording else {
            return AudioRecording(chunks: chunks)
        }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRecording = false
        return AudioRecording(chunks: chunks)
    }

    private static func extractMonoSamples(from buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData else { return [] }
        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        guard frameCount > 0, channelCount > 0 else { return [] }

        if channelCount == 1 {
            return Array(UnsafeBufferPointer(start: channelData[0], count: frameCount))
        }

        var samples = Array(repeating: Float(0), count: frameCount)
        for channel in 0..<channelCount {
            let pointer = channelData[channel]
            for frame in 0..<frameCount {
                samples[frame] += pointer[frame] / Float(channelCount)
            }
        }
        return samples
    }
}

enum AudioCaptureError: LocalizedError {
    case noInputDevice

    var errorDescription: String? {
        switch self {
        case .noInputDevice:
            return "No microphone input device is available"
        }
    }
}
