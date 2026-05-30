import XCTest
@testable import VachaVox

final class FileTranscriptWriterTests: XCTestCase {
    func testCreatesOutputDirectoryAndTimestampedSanitizedFilename() throws {
        let tempRoot = try makeTempRoot().appendingPathComponent("nested/output", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempRoot.deletingLastPathComponent().deletingLastPathComponent()) }
        let generatedAt = fixedDate()
        let service = FileTranscriptionService(outputRoot: tempRoot, dateProvider: { generatedAt })
        let sourceURL = URL(fileURLWithPath: "/tmp/Team Meeting #1.m4a")

        let result = try service.writeTranscript(
            sourceURL: sourceURL,
            transcript: "Hello world.",
            model: ModelCatalog.descriptor(for: "parakeet-tdt-0.6b-v3-coreml")
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: tempRoot.path))
        XCTAssertEqual(result.outputURL.lastPathComponent, "Team_Meeting_1_2026-04-28_14-35-09.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.outputURL.path))
    }

    func testMarkdownIncludesMetadataAndReadableTranscriptSection() {
        let markdown = FileTranscriptionService.markdown(
            metadata: FileTranscriptMetadata(
                sourceFileName: "meeting.wav",
                sourcePath: "/tmp/meeting.wav",
                generatedAt: fixedDate(),
                modelDisplayName: "Parakeet TDT 0.6B v3",
                engineLabel: "Parakeet"
            ),
            transcript: "First sentence. Second sentence?"
        )

        XCTAssertTrue(markdown.contains("# Transcript: meeting.wav"))
        XCTAssertTrue(markdown.contains("Model: Parakeet TDT 0.6B v3"))
        XCTAssertTrue(markdown.contains("Engine: Parakeet"))
        XCTAssertTrue(markdown.contains("Source: /tmp/meeting.wav"))
        XCTAssertTrue(markdown.contains("## Transcript"))
        XCTAssertTrue(markdown.contains("First sentence.\n\nSecond sentence?"))
    }

    func testReadableLinesSplitSparsePunctuationByWordCount() {
        let words = (1...70).map { "word\($0)" }.joined(separator: " ")

        let lines = FileTranscriptionService.readableLines(from: words, fallbackWordLimit: 30)

        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0].split(separator: " ").count, 30)
        XCTAssertEqual(lines[1].split(separator: " ").count, 30)
        XCTAssertEqual(lines[2].split(separator: " ").count, 10)
    }

    func testDefaultOutputRootUsesVachaVoxOutputFolder() {
        let root = FileTranscriptionService.defaultOutputRoot

        XCTAssertEqual(root.lastPathComponent, "output")
        XCTAssertEqual(root.deletingLastPathComponent().lastPathComponent, "vachavox")
    }

    private func makeTempRoot() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("VachaVoxFileWriterTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func fixedDate() -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone.current
        components.year = 2026
        components.month = 4
        components.day = 28
        components.hour = 14
        components.minute = 35
        components.second = 9
        return components.date!
    }
}
