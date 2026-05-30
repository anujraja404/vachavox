import XCTest
@testable import VachaVox

@MainActor
final class FileTranscriptionCoordinatorTests: XCTestCase {
    func testGenerateShowsErrorWhenSelectedModelIsNotLoaded() throws {
        let fixture = try makeFixture(engine: MockFileTranscriptionEngine())
        fixture.model.modelLoadState = .notLoaded
        fixture.model.fileTranscription.selectedAudioFileURL = fixture.sourceURL
        fixture.model.fileTranscription.selectedAudioFileName = fixture.sourceURL.lastPathComponent

        fixture.coordinator.generateFileTranscript()

        XCTAssertEqual(fixture.model.fileTranscription.phase, .failed)
        XCTAssertEqual(
            fixture.model.fileTranscription.errorMessage,
            "Load the selected model before generating a file transcript"
        )
    }

    func testSuccessfulGenerationWritesOneMarkdownFile() throws {
        let engine = MockFileTranscriptionEngine(fileText: "Hello there. This is local.")
        let fixture = try makeFixture(engine: engine)
        fixture.model.fileTranscription.selectedAudioFileURL = fixture.sourceURL
        fixture.model.fileTranscription.selectedAudioFileName = fixture.sourceURL.lastPathComponent

        fixture.coordinator.generateFileTranscript()
        waitForFilePhase(fixture.model, .completed)

        let files = try FileManager.default.contentsOfDirectory(at: fixture.outputRoot, includingPropertiesForKeys: nil)
        XCTAssertEqual(files.count, 1)
        XCTAssertEqual(files.first?.pathExtension, "md")
        XCTAssertEqual(
            fixture.model.fileTranscription.completedOutputURL?.standardizedFileURL,
            files.first?.standardizedFileURL
        )
        let contents = try String(contentsOf: files[0])
        XCTAssertTrue(contents.contains("Hello there."))
        XCTAssertTrue(contents.contains("This is local."))
    }

    func testFileTranscriptionDoesNotRequireMicrophoneOrAccessibilityReadiness() throws {
        let fixture = try makeFixture(engine: MockFileTranscriptionEngine(fileText: "Local file transcript."))
        fixture.model.microphonePermission = .denied
        fixture.model.accessibilityTrusted = false
        fixture.model.settings.outputMode = .paste
        fixture.model.fileTranscription.selectedAudioFileURL = fixture.sourceURL
        fixture.model.fileTranscription.selectedAudioFileName = fixture.sourceURL.lastPathComponent

        fixture.coordinator.generateFileTranscript()
        waitForFilePhase(fixture.model, .completed)

        XCTAssertEqual(fixture.model.fileTranscription.phase, .completed)
    }

    func testEmptyTranscriptFailsWithoutCompletedOutput() throws {
        let fixture = try makeFixture(engine: MockFileTranscriptionEngine(fileText: "   "))
        fixture.model.fileTranscription.selectedAudioFileURL = fixture.sourceURL
        fixture.model.fileTranscription.selectedAudioFileName = fixture.sourceURL.lastPathComponent

        fixture.coordinator.generateFileTranscript()
        waitForFilePhase(fixture.model, .failed)

        XCTAssertNil(fixture.model.fileTranscription.completedOutputURL)
        let files = (try? FileManager.default.contentsOfDirectory(
            at: fixture.outputRoot,
            includingPropertiesForKeys: nil
        )) ?? []
        XCTAssertTrue(files.isEmpty)
    }

    func testCancellationUpdatesState() throws {
        let engine = MockFileTranscriptionEngine(fileText: "late transcript", delayNanoseconds: 1_000_000_000)
        let fixture = try makeFixture(engine: engine)
        fixture.model.fileTranscription.selectedAudioFileURL = fixture.sourceURL
        fixture.model.fileTranscription.selectedAudioFileName = fixture.sourceURL.lastPathComponent

        fixture.coordinator.generateFileTranscript()
        fixture.coordinator.cancelFileTranscript()
        waitForFilePhase(fixture.model, .cancelled)

        XCTAssertEqual(fixture.model.fileTranscription.phase, .cancelled)
    }

    private func makeFixture(engine: MockFileTranscriptionEngine) throws -> Fixture {
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("VachaVoxFileCoordinatorTests-\(UUID().uuidString)", isDirectory: true)
        let outputRoot = tempRoot.appendingPathComponent("output", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        let sourceURL = tempRoot.appendingPathComponent("meeting.wav")
        try Data("audio".utf8).write(to: sourceURL)

        let settingsStore = isolatedSettingsStore()
        let model = AppModel(settingsStore: settingsStore)
        let descriptor = ModelCatalog.descriptor(for: "parakeet-tdt-0.6b-v3-coreml")
        model.settings.outputMode = .copy
        model.modelCatalog = ModelCatalog.descriptors.map { item in
            var copy = item
            copy.status = item.id == descriptor.id ? .installed : .missing
            return copy
        }
        model.modelStatus = .installed
        model.modelLoadState = .loaded(
            modelID: descriptor.id,
            displayName: descriptor.displayName,
            engine: descriptor.engine,
            loadedAt: Date()
        )

        let coordinator = DictationCoordinator(
            model: model,
            permissionsService: PermissionsService(),
            audioCaptureService: AudioCaptureService(),
            voiceActivityService: VoiceActivityService(),
            modelStore: ModelStore(rootURL: tempRoot.appendingPathComponent("models", isDirectory: true)),
            modelDownloadService: ModelDownloadService(
                modelStore: ModelStore(rootURL: tempRoot.appendingPathComponent("models", isDirectory: true))
            ),
            transcriptionEngine: engine,
            outputService: TextOutputService(
                permissionsService: MockFilePermissions(),
                previewController: PreviewWindowController(),
                outputTargetController: MockFileOutputTargetController()
            ),
            fileTranscriptionService: FileTranscriptionService(
                outputRoot: outputRoot,
                dateProvider: { Date(timeIntervalSince1970: 1_777_398_909) }
            )
        )

        return Fixture(
            model: model,
            coordinator: coordinator,
            outputRoot: outputRoot,
            tempRoot: tempRoot,
            sourceURL: sourceURL
        )
    }

    private func isolatedSettingsStore() -> SettingsStore {
        let suiteName = "VachaVoxFileCoordinatorTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return SettingsStore(defaults: defaults)
    }

    private func waitForFilePhase(_ model: AppModel, _ phase: FileTranscriptionPhase) {
        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            if model.fileTranscription.phase == phase {
                return
            }
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.02))
        }
        XCTFail("Timed out waiting for file transcription phase \(phase)")
    }
}

@MainActor
private struct Fixture {
    let model: AppModel
    let coordinator: DictationCoordinator
    let outputRoot: URL
    let tempRoot: URL
    let sourceURL: URL
}

private final class MockFileTranscriptionEngine: TranscriptionEngine {
    var fileText: String
    var delayNanoseconds: UInt64

    init(fileText: String = "hello", delayNanoseconds: UInt64 = 0) {
        self.fileText = fileText
        self.delayNanoseconds = delayNanoseconds
    }

    func prepare(model: LocalModelDescriptor) async throws {}

    func transcribe(_ request: TranscriptionRequest) async throws -> TranscriptionResult {
        TranscriptionResult(text: fileText)
    }

    func transcribeFile(
        _ url: URL,
        punctuationEnabled: Bool,
        progress: @escaping @Sendable (Double, String) -> Void
    ) async throws -> TranscriptionResult {
        progress(0.5, "Transcribing locally")
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        return TranscriptionResult(text: fileText)
    }

    func cancel() async {}
}

@MainActor
private final class MockFilePermissions: PermissionAuthorizing {
    var microphonePermission: PermissionState = .denied

    func requestMicrophonePermission() async -> PermissionState {
        XCTFail("File transcription should not request microphone permission")
        return .denied
    }

    func isAccessibilityTrusted(prompt: Bool) -> Bool {
        XCTFail("File transcription should not request Accessibility status")
        return false
    }

    func requestAccessibilityPermission() -> Bool {
        XCTFail("File transcription should not request Accessibility permission")
        return false
    }
}

@MainActor
private final class MockFileOutputTargetController: OutputTargetControlling {
    func captureFocusedTarget(excludingBundleIdentifier: String?) -> OutputTargetSnapshot? {
        XCTFail("File transcription should not capture an output target")
        return nil
    }

    func restore(_ target: OutputTargetSnapshot) async -> Bool {
        XCTFail("File transcription should not restore an output target")
        return false
    }

    func postPasteShortcut() {
        XCTFail("File transcription should not paste output")
    }
}
