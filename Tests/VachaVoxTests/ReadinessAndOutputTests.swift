import XCTest
@testable import VachaVox

@MainActor
final class ReadinessAndOutputTests: XCTestCase {
    func testInstalledSelectedModelStillNeedsLoadBeforeDictation() {
        let model = AppModel(settingsStore: isolatedSettingsStore())
        model.settings.outputMode = .copy
        model.modelCatalog = catalogWithInstalledModels(["parakeet-tdt-0.6b-v3-coreml"])
        model.modelStatus = .installed
        model.modelLoadState = .notLoaded

        XCTAssertEqual(model.readinessState, .needsModelLoad)
    }

    func testLoadedSelectedModelCanReachReadyState() {
        let model = AppModel(settingsStore: isolatedSettingsStore())
        model.settings.outputMode = .copy
        model.modelCatalog = catalogWithInstalledModels(["parakeet-tdt-0.6b-v3-coreml"])
        model.modelStatus = .installed
        model.modelLoadState = .loaded(
            modelID: "parakeet-tdt-0.6b-v3-coreml",
            displayName: "Parakeet TDT 0.6B v3",
            engine: .parakeet,
            loadedAt: Date()
        )

        XCTAssertEqual(model.readinessState, .ready)
        XCTAssertTrue(model.selectedModelIsLoaded)
    }

    func testModelLoadFailureUsesDedicatedReadinessState() {
        let model = AppModel(settingsStore: isolatedSettingsStore())
        model.settings.outputMode = .copy
        model.modelCatalog = catalogWithInstalledModels(["parakeet-tdt-0.6b-v3-coreml"])
        model.modelStatus = .installed
        model.modelLoadState = .failed(
            modelID: "parakeet-tdt-0.6b-v3-coreml",
            message: "Could not load model",
            failedAt: Date()
        )

        XCTAssertEqual(model.readinessState, .modelLoadFailed("Could not load model"))
    }

    func testLaunchFallsBackToBestInstalledModelWhenSavedSelectionIsMissing() throws {
        let tempRoot = try makeTempRoot()
        defer { try? FileManager.default.removeItem(at: tempRoot) }

        let settingsStore = isolatedSettingsStore()
        var settings = AppSettings()
        settings.selectedEngine = .whisperKit
        settings.selectedModelID = "openai_whisper-small"
        settingsStore.save(settings)

        let model = AppModel(settingsStore: settingsStore)
        let modelStore = ModelStore(rootURL: tempRoot)
        let fallback = ModelCatalog.descriptor(for: "parakeet-tdt-ctc-110m-coreml")
        try createParakeetModel(fallback, in: modelStore)

        let coordinator = DictationCoordinator(
            model: model,
            permissionsService: PermissionsService(),
            audioCaptureService: AudioCaptureService(),
            voiceActivityService: VoiceActivityService(),
            modelStore: modelStore,
            modelDownloadService: ModelDownloadService(modelStore: modelStore),
            transcriptionEngine: MockTranscriptionEngine(),
            outputService: TextOutputService(
                permissionsService: MockPermissions(accessibilityTrusted: true),
                previewController: PreviewWindowController(),
                outputTargetController: MockOutputTargetController()
            )
        )

        coordinator.loadBestAvailableModelOnLaunch()
        waitForLoadedModel(model, expectedID: fallback.id)

        XCTAssertEqual(model.settings.selectedModelID, fallback.id)
        XCTAssertTrue(model.selectedModelIsLoaded)
    }

    func testPasteFallsBackToClipboardWhenAccessibilityIsMissing() async throws {
        let targetController = MockOutputTargetController()
        let service = TextOutputService(
            permissionsService: MockPermissions(accessibilityTrusted: false),
            previewController: PreviewWindowController(),
            outputTargetController: targetController
        )

        let result = try await service.deliver(
            "hello",
            mode: .paste,
            pasteTarget: OutputTargetSnapshot(processIdentifier: 42, bundleIdentifier: "example.app", localizedName: "Example")
        )

        XCTAssertEqual(result, .copiedAccessibilityMissing)
        XCTAssertEqual(targetController.postPasteCount, 0)
        XCTAssertEqual(NSPasteboard.general.string(forType: .string), "hello")
    }

    func testPasteRestoresCapturedTargetBeforePostingShortcut() async throws {
        let target = OutputTargetSnapshot(processIdentifier: 42, bundleIdentifier: "example.app", localizedName: "Example")
        let targetController = MockOutputTargetController(restoreResult: true)
        let service = TextOutputService(
            permissionsService: MockPermissions(accessibilityTrusted: true),
            previewController: PreviewWindowController(),
            outputTargetController: targetController
        )

        let result = try await service.deliver("hello", mode: .paste, pasteTarget: target)

        XCTAssertEqual(result, .pasted(targetName: "Example"))
        XCTAssertEqual(targetController.restoredTargets, [target])
        XCTAssertEqual(targetController.postPasteCount, 1)
    }

    func testFormattedPopupTextTrimsWhitespaceWithoutClipping() {
        let long = String(repeating: "a", count: 280)
        let formatted = DictationCoordinator.formattedPopupText(from: "  \(long)   ")
        XCTAssertNotNil(formatted)
        XCTAssertEqual(formatted?.count, 280)
    }

    func testFormattedPopupTextReturnsNilWhenEmptyAfterTrim() {
        XCTAssertNil(DictationCoordinator.formattedPopupText(from: "   \n\t "))
    }

    func testPopupDisplayDurationScalesWithCharacterCountAndClamps() {
        let shortDuration = DictationCoordinator.popupDisplayDuration(forCharacterCount: 10)
        let mediumDuration = DictationCoordinator.popupDisplayDuration(forCharacterCount: 140)
        let longDuration = DictationCoordinator.popupDisplayDuration(forCharacterCount: 2_000)

        XCTAssertLessThan(shortDuration, mediumDuration)
        XCTAssertEqual(shortDuration, 3_000_000_000)
        XCTAssertEqual(longDuration, 12_000_000_000)
    }

    private func isolatedSettingsStore() -> SettingsStore {
        let suiteName = "VachaVoxTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return SettingsStore(defaults: defaults)
    }

    private func catalogWithInstalledModels(_ ids: Set<String>) -> [LocalModelDescriptor] {
        ModelCatalog.descriptors.map { descriptor in
            var copy = descriptor
            copy.status = ids.contains(copy.id) ? .installed : .missing
            return copy
        }
    }

    private func makeTempRoot() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("VachaVoxTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func createParakeetModel(_ descriptor: LocalModelDescriptor, in store: ModelStore) throws {
        guard let spec = descriptor.parakeetSpec else {
            XCTFail("Expected Parakeet descriptor")
            return
        }
        let folder = store.modelURL(for: descriptor)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for file in spec.requiredFiles {
            let url = folder.appendingPathComponent(file)
            if file.hasSuffix(".mlmodelc") {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            } else {
                try Data("{}".utf8).write(to: url)
            }
        }
    }

    private func waitForLoadedModel(_ model: AppModel, expectedID: String) {
        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            if model.modelLoadState.loadedModelID == expectedID {
                return
            }
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.02))
        }
        XCTFail("Timed out waiting for \(expectedID) to load")
    }
}

private final class MockTranscriptionEngine: TranscriptionEngine {
    private(set) var preparedModelIDs: [String] = []

    func prepare(model: LocalModelDescriptor) async throws {
        preparedModelIDs.append(model.id)
    }

    func transcribe(_ request: TranscriptionRequest) async throws -> TranscriptionResult {
        TranscriptionResult(text: "hello")
    }

    func transcribeFile(
        _ url: URL,
        punctuationEnabled: Bool,
        progress: @escaping @Sendable (Double, String) -> Void
    ) async throws -> TranscriptionResult {
        progress(0.5, "Transcribing locally")
        return TranscriptionResult(text: "hello")
    }

    func cancel() async {}
}

@MainActor
private final class MockPermissions: PermissionAuthorizing {
    var microphonePermission: PermissionState = .granted
    var accessibilityTrusted: Bool

    init(accessibilityTrusted: Bool) {
        self.accessibilityTrusted = accessibilityTrusted
    }

    func requestMicrophonePermission() async -> PermissionState {
        microphonePermission
    }

    func isAccessibilityTrusted(prompt: Bool) -> Bool {
        accessibilityTrusted
    }

    func requestAccessibilityPermission() -> Bool {
        accessibilityTrusted
    }
}

@MainActor
private final class MockOutputTargetController: OutputTargetControlling {
    var capturedTarget: OutputTargetSnapshot?
    var restoreResult: Bool
    private(set) var restoredTargets: [OutputTargetSnapshot] = []
    private(set) var postPasteCount = 0

    init(capturedTarget: OutputTargetSnapshot? = nil, restoreResult: Bool = true) {
        self.capturedTarget = capturedTarget
        self.restoreResult = restoreResult
    }

    func captureFocusedTarget(excludingBundleIdentifier: String?) -> OutputTargetSnapshot? {
        capturedTarget
    }

    func restore(_ target: OutputTargetSnapshot) async -> Bool {
        restoredTargets.append(target)
        return restoreResult
    }

    func postPasteShortcut() {
        postPasteCount += 1
    }
}
