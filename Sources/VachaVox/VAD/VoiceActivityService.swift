import Foundation

struct VoiceActivityService {
    var minimumDuration: TimeInterval = 0.35
    var prerollDuration: TimeInterval = 0.25

    func trim(_ recording: AudioRecording, sensitivity: Double) -> AudioRecording {
        let source = recording.samples
        let sampleRate = recording.sampleRate
        guard !source.isEmpty, sampleRate > 0 else {
            return recording
        }

        let threshold = Float(max(0.001, sensitivity))
        let prerollSamples = Int(prerollDuration * sampleRate)
        let minimumSamples = Int(minimumDuration * sampleRate)

        guard let firstVoice = source.firstIndex(where: { abs($0) >= threshold }),
              let lastVoice = source.lastIndex(where: { abs($0) >= threshold }) else {
            return AudioRecording(chunks: [])
        }

        let start = max(0, firstVoice - prerollSamples)
        let end = min(source.count - 1, lastVoice + prerollSamples)
        guard end > start, end - start >= minimumSamples else {
            return AudioRecording(chunks: [])
        }

        let trimmed = Array(source[start...end])
        return AudioRecording(chunks: [
            AudioChunk(
                samples: trimmed,
                sampleRate: sampleRate,
                timestamp: recording.chunks.first?.timestamp ?? Date().timeIntervalSince1970
            )
        ])
    }
}
