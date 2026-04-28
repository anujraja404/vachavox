import Foundation

enum LinearResampler {
    static func resample(samples: [Float], from sourceRate: Double, to targetRate: Double) -> [Float] {
        guard !samples.isEmpty else { return [] }
        guard sourceRate > 0, targetRate > 0, abs(sourceRate - targetRate) > 0.1 else {
            return samples
        }

        let outputCount = max(1, Int((Double(samples.count) / sourceRate) * targetRate))
        guard outputCount > 1 else { return [samples[0]] }

        let step = sourceRate / targetRate
        var output = Array(repeating: Float(0), count: outputCount)

        for index in 0..<outputCount {
            let sourcePosition = Double(index) * step
            let lower = min(Int(sourcePosition), samples.count - 1)
            let upper = min(lower + 1, samples.count - 1)
            let fraction = Float(sourcePosition - Double(lower))
            output[index] = samples[lower] + (samples[upper] - samples[lower]) * fraction
        }
        return output
    }
}
