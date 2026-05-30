import XCTest
@testable import VachaVox

final class ModelStoreTests: XCTestCase {
    private var tempRoot: URL!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("VachaVoxTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let tempRoot {
            try? FileManager.default.removeItem(at: tempRoot)
        }
    }

    func testValidParakeetFolderScansInstalled() throws {
        let descriptor = ModelCatalog.descriptor(for: "parakeet-tdt-0.6b-v3-coreml")
        let store = ModelStore(rootURL: tempRoot)
        let folder = store.modelURL(for: descriptor)
        XCTAssertEqual(folder.lastPathComponent, "parakeet-tdt-0.6b-v3")
        try create(folder, files: [
            "Preprocessor.mlmodelc",
            "Encoder.mlmodelc",
            "Decoder.mlmodelc",
            "JointDecisionv3.mlmodelc",
            "parakeet_vocab.json",
        ])

        XCTAssertEqual(store.status(for: descriptor), .installed)
    }

    func testInvalidParakeetFolderReportsMissingFile() throws {
        let descriptor = ModelCatalog.descriptor(for: "parakeet-tdt-0.6b-v2-coreml")
        let store = ModelStore(rootURL: tempRoot)
        try create(store.modelURL(for: descriptor), files: ["Preprocessor.mlmodelc"])

        guard case .error(let message) = store.status(for: descriptor) else {
            XCTFail("Expected missing encoder error")
            return
        }
        XCTAssertTrue(message.contains("Missing Encoder.mlmodelc"))
        XCTAssertTrue(message.contains("parakeet-tdt-0.6b-v2"))
    }

    func testParakeetFolderNamesMatchFluidAudioDownloadLayout() {
        let store = ModelStore(rootURL: tempRoot)

        XCTAssertEqual(
            store.modelURL(for: ModelCatalog.descriptor(for: "parakeet-tdt-0.6b-v3-coreml")).lastPathComponent,
            "parakeet-tdt-0.6b-v3"
        )
        XCTAssertEqual(
            store.modelURL(for: ModelCatalog.descriptor(for: "parakeet-tdt-0.6b-v2-coreml")).lastPathComponent,
            "parakeet-tdt-0.6b-v2"
        )
        XCTAssertEqual(
            store.modelURL(for: ModelCatalog.descriptor(for: "parakeet-tdt-ctc-110m-coreml")).lastPathComponent,
            "parakeet-tdt-ctc-110m"
        )
    }

    func testLegacyParakeetCoreMLFolderReportsMoveInstruction() throws {
        let descriptor = ModelCatalog.descriptor(for: "parakeet-tdt-0.6b-v3-coreml")
        let store = ModelStore(rootURL: tempRoot)
        let legacy = try XCTUnwrap(store.legacyModelURL(for: descriptor))
        try create(legacy, files: [
            "Preprocessor.mlmodelc",
            "Encoder.mlmodelc",
            "Decoder.mlmodelc",
            "JointDecisionv3.mlmodelc",
            "parakeet_vocab.json",
        ])

        guard case .error(let message) = store.status(for: descriptor) else {
            XCTFail("Expected legacy folder error")
            return
        }
        XCTAssertTrue(message.contains("Found legacy Parakeet folder"))
        XCTAssertTrue(message.contains(legacy.path))
        XCTAssertTrue(message.contains(store.modelURL(for: descriptor).path))
    }

    func testBestAvailableModelUsesLaunchPriority() {
        let catalog = ModelCatalog.descriptors.map { descriptor in
            var copy = descriptor
            copy.status = ["openai_whisper-tiny", "parakeet-tdt-ctc-110m-coreml"].contains(copy.id) ? .installed : .missing
            return copy
        }

        XCTAssertEqual(ModelCatalog.bestAvailable(from: catalog)?.id, "parakeet-tdt-ctc-110m-coreml")
    }

    func testValidWhisperKitFolderScansInstalled() throws {
        let descriptor = ModelCatalog.descriptor(for: "openai_whisper-base")
        let store = ModelStore(rootURL: tempRoot)
        try create(store.modelURL(for: descriptor), files: [
            "config.json",
            "generation_config.json",
            "MelSpectrogram.mlmodelc",
            "AudioEncoder.mlmodelc",
            "TextDecoder.mlmodelc",
        ])

        XCTAssertEqual(store.status(for: descriptor), .installed)
    }

    func testInvalidWhisperKitFolderReportsMissingModel() throws {
        let descriptor = ModelCatalog.descriptor(for: "openai_whisper-base")
        let store = ModelStore(rootURL: tempRoot)
        try create(store.modelURL(for: descriptor), files: [
            "config.json",
            "generation_config.json",
            "MelSpectrogram.mlmodelc",
        ])

        XCTAssertEqual(store.status(for: descriptor), .error("Missing AudioEncoder"))
    }

    func testSelectedMissingModelProducesUserFacingMissingStatus() {
        let descriptor = ModelCatalog.descriptor(for: "openai_whisper-small")
        let store = ModelStore(rootURL: tempRoot)

        XCTAssertEqual(store.status(for: descriptor), .missing)
        XCTAssertEqual(store.status(for: descriptor).label, "Missing")
    }

    func testNoModelInstalledProducesAllMissingCatalog() {
        let store = ModelStore(rootURL: tempRoot)

        XCTAssertTrue(store.scannedCatalog().allSatisfy { $0.status == .missing })
    }

    func testMigratesLegacyModelRootWhenNewRootIsMissing() throws {
        let legacyRoot = tempRoot.appendingPathComponent("old-models", isDirectory: true)
        let newRoot = tempRoot.appendingPathComponent("new-models", isDirectory: true)
        let descriptor = ModelCatalog.descriptor(for: "openai_whisper-base")
        try create(
            legacyRoot
                .appendingPathComponent(descriptor.engine.folderName, isDirectory: true)
                .appendingPathComponent(descriptor.folderName, isDirectory: true),
            files: [
                "config.json",
                "generation_config.json",
                "MelSpectrogram.mlmodelc",
                "AudioEncoder.mlmodelc",
                "TextDecoder.mlmodelc",
            ]
        )

        let store = ModelStore(rootURL: newRoot, legacyRootURL: legacyRoot)

        XCTAssertEqual(store.rootURL, newRoot)
        XCTAssertEqual(store.status(for: descriptor), .installed)
    }

    private func create(_ folder: URL, files: [String]) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for file in files {
            let url = folder.appendingPathComponent(file)
            if file.hasSuffix(".mlmodelc") || file.hasSuffix(".mlpackage") {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            } else {
                try Data("{}".utf8).write(to: url)
            }
        }
    }
}
