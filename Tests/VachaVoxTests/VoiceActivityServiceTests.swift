import XCTest
@testable import VachaVox

final class VoiceActivityServiceTests: XCTestCase {
    func testTrimDropsLeadingAndTrailingSilenceWithPreroll() {
        let sampleRate = 1_000.0
        let silence = Array(repeating: Float(0), count: 500)
        let speech = Array(repeating: Float(0.2), count: 700)
        let recording = AudioRecording(chunks: [
            AudioChunk(samples: silence + speech + silence, sampleRate: sampleRate, timestamp: 0)
        ])
        let service = VoiceActivityService(minimumDuration: 0.2, prerollDuration: 0.1)

        let trimmed = service.trim(recording, sensitivity: 0.05)

        XCTAssertEqual(trimmed.samples.count, 900)
        XCTAssertEqual(trimmed.samples.first, 0)
        XCTAssertEqual(trimmed.samples[100], 0.2)
    }

    func testTrimRejectsSilenceOnlyRecording() {
        let recording = AudioRecording(chunks: [
            AudioChunk(samples: Array(repeating: Float(0), count: 1_000), sampleRate: 1_000, timestamp: 0)
        ])

        let trimmed = VoiceActivityService().trim(recording, sensitivity: 0.05)

        XCTAssertTrue(trimmed.samples.isEmpty)
    }
}
