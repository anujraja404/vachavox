import Foundation
import FluidAudio

enum TranscriptionEngineKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case parakeet
    case whisperKit

    var id: String { rawValue }

    var label: String {
        switch self {
        case .parakeet:
            return "Parakeet"
        case .whisperKit:
            return "WhisperKit"
        }
    }
}

struct LocalModelDescriptor: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var engine: TranscriptionEngineKind
    var displayName: String
    var sizeDescription: String
    var languageDescription: String
    var recommendedRAM: String
    var folderName: String
    var downloadURL: URL?
    var isDownloadable: Bool
    var status: ModelStatus = .missing

    var relativeFolder: String {
        "\(engine.folderName)/\(folderName)"
    }

    var parakeetSpec: ParakeetModelSpec? {
        ParakeetModelSpec.catalog[id]
    }
}

enum ModelStatus: Codable, Equatable, Sendable {
    case missing
    case installed
    case downloading(Double)
    case loading
    case ready
    case error(String)

    var label: String {
        switch self {
        case .missing:
            return "Missing"
        case .installed:
            return "Installed"
        case .downloading(let progress):
            return "Downloading \(Int(progress * 100))%"
        case .loading:
            return "Loading"
        case .ready:
            return "Ready"
        case .error(let message):
            return message
        }
    }

    var isUsable: Bool {
        switch self {
        case .installed, .ready:
            return true
        case .missing, .downloading, .loading, .error:
            return false
        }
    }
}

struct ModelCatalog {
    static let defaultModelID = "parakeet-tdt-0.6b-v3-coreml"

    static let descriptors: [LocalModelDescriptor] = [
        LocalModelDescriptor(
            id: "parakeet-tdt-0.6b-v3-coreml",
            engine: .parakeet,
            displayName: "Parakeet TDT 0.6B v3",
            sizeDescription: "Large Core ML",
            languageDescription: "25 European languages",
            recommendedRAM: "16 GB",
            folderName: "parakeet-tdt-0.6b-v3",
            downloadURL: URL(string: "https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml"),
            isDownloadable: true
        ),
        LocalModelDescriptor(
            id: "parakeet-tdt-0.6b-v2-coreml",
            engine: .parakeet,
            displayName: "Parakeet TDT 0.6B v2",
            sizeDescription: "Large Core ML",
            languageDescription: "English",
            recommendedRAM: "16 GB",
            folderName: "parakeet-tdt-0.6b-v2",
            downloadURL: URL(string: "https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v2-coreml"),
            isDownloadable: true
        ),
        LocalModelDescriptor(
            id: "parakeet-tdt-ctc-110m-coreml",
            engine: .parakeet,
            displayName: "Parakeet TDT-CTC 110M",
            sizeDescription: "Small Core ML",
            languageDescription: "English",
            recommendedRAM: "8 GB",
            folderName: "parakeet-tdt-ctc-110m",
            downloadURL: URL(string: "https://huggingface.co/FluidInference/parakeet-tdt-ctc-110m-coreml"),
            isDownloadable: true
        ),
        whisper("openai_whisper-tiny", "Whisper Tiny", "Tiny", "Multilingual", "8 GB"),
        whisper("openai_whisper-base", "Whisper Base", "Base", "Multilingual", "8 GB"),
        whisper("openai_whisper-small", "Whisper Small", "Small", "Multilingual", "8 GB"),
        whisper("openai_whisper-medium", "Whisper Medium", "Medium", "Multilingual", "16 GB"),
        whisper("openai_whisper-large-v3", "Whisper Large v3", "Large", "Multilingual", "24 GB"),
        whisper("openai_whisper-large-v3_turbo", "Whisper Large v3 Turbo", "Large turbo", "Multilingual", "16 GB"),
        whisper("distil-whisper_distil-large-v3", "Distil-Whisper Large v3", "Distilled large", "English", "16 GB"),
    ]

    static func descriptor(for id: String) -> LocalModelDescriptor {
        descriptors.first { $0.id == id } ?? descriptors[0]
    }

    static func bestAvailable(from catalog: [LocalModelDescriptor]) -> LocalModelDescriptor? {
        let priority = [
            "parakeet-tdt-0.6b-v3-coreml",
            "parakeet-tdt-0.6b-v2-coreml",
            "parakeet-tdt-ctc-110m-coreml",
            "openai_whisper-large-v3_turbo",
            "openai_whisper-large-v3",
            "openai_whisper-medium",
            "distil-whisper_distil-large-v3",
            "openai_whisper-small",
            "openai_whisper-base",
            "openai_whisper-tiny",
        ]

        for id in priority {
            if let descriptor = catalog.first(where: { $0.id == id && $0.status.isUsable }) {
                return descriptor
            }
        }
        return nil
    }

    private static func whisper(
        _ id: String,
        _ displayName: String,
        _ size: String,
        _ language: String,
        _ ram: String
    ) -> LocalModelDescriptor {
        LocalModelDescriptor(
            id: id,
            engine: .whisperKit,
            displayName: displayName,
            sizeDescription: size,
            languageDescription: language,
            recommendedRAM: ram,
            folderName: id,
            downloadURL: URL(string: "https://huggingface.co/argmaxinc/whisperkit-coreml/tree/main/\(id)"),
            isDownloadable: true
        )
    }
}

struct ParakeetModelSpec: Sendable {
    let id: String
    let version: AsrModelVersion
    let folderName: String
    let legacyFolderName: String
    let requiredFiles: [String]

    static let catalog: [String: ParakeetModelSpec] = {
        let specs = [
            ParakeetModelSpec(
                id: "parakeet-tdt-0.6b-v3-coreml",
                version: .v3,
                folderName: "parakeet-tdt-0.6b-v3",
                legacyFolderName: "parakeet-tdt-0.6b-v3-coreml",
                requiredFiles: [
                    "Preprocessor.mlmodelc",
                    "Encoder.mlmodelc",
                    "Decoder.mlmodelc",
                    "JointDecisionv3.mlmodelc",
                    "parakeet_vocab.json",
                ]
            ),
            ParakeetModelSpec(
                id: "parakeet-tdt-0.6b-v2-coreml",
                version: .v2,
                folderName: "parakeet-tdt-0.6b-v2",
                legacyFolderName: "parakeet-tdt-0.6b-v2-coreml",
                requiredFiles: [
                    "Preprocessor.mlmodelc",
                    "Encoder.mlmodelc",
                    "Decoder.mlmodelc",
                    "JointDecision.mlmodelc",
                    "parakeet_vocab.json",
                ]
            ),
            ParakeetModelSpec(
                id: "parakeet-tdt-ctc-110m-coreml",
                version: .tdtCtc110m,
                folderName: "parakeet-tdt-ctc-110m",
                legacyFolderName: "parakeet-tdt-ctc-110m-coreml",
                requiredFiles: [
                    "Preprocessor.mlmodelc",
                    "Decoder.mlmodelc",
                    "JointDecision.mlmodelc",
                    "parakeet_vocab.json",
                ]
            ),
        ]
        return Dictionary(uniqueKeysWithValues: specs.map { ($0.id, $0) })
    }()
}

struct ModelStore {
    var rootURL: URL
    private let fileManager: FileManager
    private static let legacyModelContainerName = ["cha", "pad"].joined()
    static let defaultRootURL = URL(fileURLWithPath: "/Users/macbookpro/local_ai_models/voice_models")
        // `modelURL(for:)` appends engine folder (for example, "parakeet") after this root.
        .standardizedFileURL
    static let legacyRootURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(legacyModelContainerName, isDirectory: true)
        .appendingPathComponent("models", isDirectory: true)

    init(
        rootURL: URL = ModelStore.defaultRootURL,
        legacyRootURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        let migrationRootURL = legacyRootURL ?? (rootURL == ModelStore.defaultRootURL ? ModelStore.legacyRootURL : nil)
        self.rootURL = ModelStore.migratedRootURL(
            rootURL: rootURL,
            legacyRootURL: migrationRootURL,
            fileManager: fileManager
        )
    }

    func modelURL(for descriptor: LocalModelDescriptor) -> URL {
        rootURL
            .appendingPathComponent(descriptor.engine.folderName, isDirectory: true)
            .appendingPathComponent(descriptor.folderName, isDirectory: true)
    }

    func legacyModelURL(for descriptor: LocalModelDescriptor) -> URL? {
        guard let spec = descriptor.parakeetSpec else { return nil }
        return rootURL
            .appendingPathComponent(descriptor.engine.folderName, isDirectory: true)
            .appendingPathComponent(spec.legacyFolderName, isDirectory: true)
    }

    func status(for descriptor: LocalModelDescriptor) -> ModelStatus {
        validate(descriptor: descriptor, at: modelURL(for: descriptor))
    }

    func scannedCatalog() -> [LocalModelDescriptor] {
        ModelCatalog.descriptors.map { descriptor in
            var copy = descriptor
            copy.status = status(for: descriptor)
            return copy
        }
    }

    func validate(descriptor: LocalModelDescriptor, at url: URL) -> ModelStatus {
        guard fileManager.fileExists(atPath: url.path) else {
            if let legacyURL = legacyModelURL(for: descriptor),
               fileManager.fileExists(atPath: legacyURL.path) {
                return .error("Found legacy Parakeet folder at \(legacyURL.path). Move or redownload it to \(url.path).")
            }
            return .missing
        }

        switch descriptor.engine {
        case .parakeet:
            return validateParakeet(descriptor: descriptor, at: url)
        case .whisperKit:
            return validateWhisperKit(at: url)
        }
    }

    private func validateParakeet(descriptor: LocalModelDescriptor, at url: URL) -> ModelStatus {
        guard let spec = descriptor.parakeetSpec else {
            return .error("Unsupported Parakeet model \(descriptor.id)")
        }
        guard AsrModels.modelsExist(at: url, version: spec.version) else {
            return requiredFilesExist(spec.requiredFiles, in: url)
        }
        return .installed
    }

    private func validateWhisperKit(at url: URL) -> ModelStatus {
        let requiredFiles = ["config.json", "generation_config.json"]
        guard requiredFiles.allSatisfy({ fileManager.fileExists(atPath: url.appendingPathComponent($0).path) }) else {
            return .error("Missing WhisperKit config files")
        }

        for name in ["MelSpectrogram", "AudioEncoder", "TextDecoder"] {
            let compiled = url.appendingPathComponent("\(name).mlmodelc")
            let package = url.appendingPathComponent("\(name).mlpackage")
            guard fileManager.fileExists(atPath: compiled.path) || fileManager.fileExists(atPath: package.path) else {
                return .error("Missing \(name)")
            }
        }

        return .installed
    }

    private func requiredFilesExist(_ files: [String], in url: URL) -> ModelStatus {
        for file in files {
            let fileURL = url.appendingPathComponent(file)
            guard fileManager.fileExists(atPath: fileURL.path) else {
                return .error("Missing \(file) at \(fileURL.path)")
            }
        }
        return .installed
    }

    private static func migratedRootURL(
        rootURL: URL,
        legacyRootURL: URL?,
        fileManager: FileManager
    ) -> URL {
        guard let legacyRootURL else { return rootURL }
        var isLegacyDirectory = ObjCBool(false)
        guard fileManager.fileExists(atPath: legacyRootURL.path, isDirectory: &isLegacyDirectory),
              isLegacyDirectory.boolValue else {
            return rootURL
        }
        guard !fileManager.fileExists(atPath: rootURL.path) else { return rootURL }

        do {
            try fileManager.createDirectory(
                at: rootURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try fileManager.moveItem(at: legacyRootURL, to: rootURL)
        } catch {
            try? fileManager.copyItem(at: legacyRootURL, to: rootURL)
        }
        return rootURL
    }
}

extension TranscriptionEngineKind {
    var folderName: String {
        switch self {
        case .parakeet:
            return "parakeet"
        case .whisperKit:
            return "whisperkit"
        }
    }
}
