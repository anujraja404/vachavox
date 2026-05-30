import Foundation

struct AudioChunk: Sendable, Equatable {
    var samples: [Float]
    var sampleRate: Double
    var timestamp: TimeInterval

    var duration: TimeInterval {
        guard sampleRate > 0 else { return 0 }
        return TimeInterval(samples.count) / sampleRate
    }

    var rms: Double {
        guard !samples.isEmpty else { return 0 }
        let sum = samples.reduce(0.0) { partial, sample in
            partial + Double(sample * sample)
        }
        return sqrt(sum / Double(samples.count))
    }
}

struct AudioRecording: Sendable, Equatable {
    var chunks: [AudioChunk]

    var duration: TimeInterval {
        chunks.reduce(0) { $0 + $1.duration }
    }

    var sampleRate: Double {
        chunks.first?.sampleRate ?? 16_000
    }

    var samples: [Float] {
        chunks.flatMap(\.samples)
    }

    var samples16k: [Float] {
        LinearResampler.resample(samples: samples, from: sampleRate, to: 16_000)
    }
}
