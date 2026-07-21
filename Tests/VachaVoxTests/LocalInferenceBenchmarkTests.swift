import AVFoundation
import Foundation
import XCTest
@testable import VachaVox

final class LocalInferenceBenchmarkTests: XCTestCase {
    func testConfiguredLocalInferenceMeasurement() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard let modelID = environment["VACHAVOX_BENCHMARK_MODEL_ID"],
              let audioPath = environment["VACHAVOX_BENCHMARK_AUDIO_FILE"],
              let outputPath = environment["VACHAVOX_BENCHMARK_OUTPUT"] else {
            throw XCTSkip("Run through Scripts/measure_local_inference.sh to collect a machine-specific measurement.")
        }

        let warmSampleCount = max(Int(environment["VACHAVOX_BENCHMARK_WARM_SAMPLES"] ?? "3") ?? 3, 1)
        let modelStore = ModelStore()
        let descriptor = ModelCatalog.descriptor(for: modelID)
        guard descriptor.id == modelID else {
            XCTFail("Unknown model ID: \(modelID)")
            return
        }
        guard modelStore.status(for: descriptor).isUsable else {
            throw XCTSkip("\(descriptor.displayName) is not installed at \(modelStore.modelURL(for: descriptor).path).")
        }

        let audioURL = URL(fileURLWithPath: audioPath)
        let inputDuration = try audioDuration(for: audioURL)
        let engine = TranscriptionEngineRouter(modelStore: modelStore)

        let freshPrepareSeconds = try await measure {
            try await engine.prepare(model: descriptor)
        }
        let warmPrepareSeconds = try await measure {
            try await engine.prepare(model: descriptor)
        }

        let firstTranscription = try await measureResult {
            try await engine.transcribeFile(audioURL, punctuationEnabled: true) { _, _ in }
        }
        var warmTranscriptionSeconds: [TimeInterval] = []
        var transcriptWasProduced = !firstTranscription.result.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        for _ in 0..<warmSampleCount {
            let measurement = try await measureResult {
                try await engine.transcribeFile(audioURL, punctuationEnabled: true) { _, _ in }
            }
            warmTranscriptionSeconds.append(measurement.seconds)
            transcriptWasProduced = transcriptWasProduced || !measurement.result.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        let report = LocalInferenceBenchmarkReport(
            capturedAtUTC: ISO8601DateFormatter().string(from: Date()),
            model: .init(
                id: descriptor.id,
                displayName: descriptor.displayName,
                engine: descriptor.engine.label,
                configuredRecommendedRAM: descriptor.recommendedRAM,
                localModelPath: modelStore.modelURL(for: descriptor).path,
                localModelBytes: directorySize(at: modelStore.modelURL(for: descriptor))
            ),
            input: .init(
                fileName: audioURL.lastPathComponent,
                durationSeconds: inputDuration,
                source: environment["VACHAVOX_BENCHMARK_INPUT_SOURCE"] ?? "unspecified",
                retention: "Temporary fixture deleted by Scripts/measure_local_inference.sh after the run.",
                warmSampleCount: warmSampleCount
            ),
            measurements: [
                .init(
                    name: "fresh_engine_prepare",
                    state: "Fresh TranscriptionEngineRouter in this test process; operating-system caches are not cleared.",
                    sampleCount: 1,
                    seconds: [freshPrepareSeconds]
                ),
                .init(
                    name: "same_process_warm_prepare",
                    state: "Same engine after a successful prepare call.",
                    sampleCount: 1,
                    seconds: [warmPrepareSeconds]
                ),
                .init(
                    name: "first_transcribe_file",
                    state: "First file transcription after fresh-engine preparation.",
                    sampleCount: 1,
                    seconds: [firstTranscription.seconds]
                ),
                .init(
                    name: "warm_transcribe_file",
                    state: "Repeated file transcription with the same prepared engine and input.",
                    sampleCount: warmSampleCount,
                    seconds: warmTranscriptionSeconds
                ),
            ],
            transcriptWasProduced: transcriptWasProduced,
            resourceMetrics: .init(
                status: "not recorded",
                reason: "CPU and memory are intentionally omitted because this XCTest process is not isolated from Core ML, framework, and test-runner allocation."
            )
        )

        let outputURL = URL(fileURLWithPath: outputPath)
        try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(report).write(to: outputURL, options: .atomic)
    }

    private func audioDuration(for url: URL) throws -> TimeInterval {
        let file = try AVAudioFile(forReading: url)
        return Double(file.length) / file.processingFormat.sampleRate
    }

    private func measure(_ operation: () async throws -> Void) async throws -> TimeInterval {
        let start = Date()
        try await operation()
        return Date().timeIntervalSince(start)
    }

    private func measureResult(_ operation: () async throws -> TranscriptionResult) async throws -> (result: TranscriptionResult, seconds: TimeInterval) {
        let start = Date()
        let result = try await operation()
        return (result, Date().timeIntervalSince(start))
    }

    private func directorySize(at url: URL) -> UInt64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey]
        ) else {
            return 0
        }

        var total: UInt64 = 0
        for case let fileURL as URL in enumerator {
            let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
            guard values?.isRegularFile == true else { continue }
            total += UInt64(values?.fileSize ?? 0)
        }
        return total
    }
}

private struct LocalInferenceBenchmarkReport: Encodable {
    struct Model: Encodable {
        let id: String
        let displayName: String
        let engine: String
        let configuredRecommendedRAM: String
        let localModelPath: String
        let localModelBytes: UInt64
    }

    struct Input: Encodable {
        let fileName: String
        let durationSeconds: TimeInterval
        let source: String
        let retention: String
        let warmSampleCount: Int
    }

    struct Measurement: Encodable {
        let name: String
        let state: String
        let sampleCount: Int
        let seconds: [TimeInterval]

        var medianSeconds: TimeInterval {
            let sorted = seconds.sorted()
            let middle = sorted.count / 2
            if sorted.count.isMultiple(of: 2) {
                return (sorted[middle - 1] + sorted[middle]) / 2
            }
            return sorted[middle]
        }
    }

    struct ResourceMetrics: Encodable {
        let status: String
        let reason: String
    }

    let capturedAtUTC: String
    let model: Model
    let input: Input
    let measurements: [Measurement]
    let transcriptWasProduced: Bool
    let resourceMetrics: ResourceMetrics
}
