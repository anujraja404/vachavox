import Foundation
import FluidAudio
import WhisperKit

actor ModelDownloadService {
    private let modelStore: ModelStore
    private let fileManager: FileManager

    init(modelStore: ModelStore = ModelStore(), fileManager: FileManager = .default) {
        self.modelStore = modelStore
        self.fileManager = fileManager
    }

    func download(_ model: LocalModelDescriptor, progress: (@Sendable (Double) -> Void)? = nil) async throws {
        try fileManager.createDirectory(
            at: modelStore.rootURL.appendingPathComponent(model.engine.folderName, isDirectory: true),
            withIntermediateDirectories: true
        )

        switch model.engine {
        case .parakeet:
            try await downloadParakeet(model, progress: progress)
        case .whisperKit:
            try await downloadWhisperKit(model, progress: progress)
        }
    }

    private func downloadParakeet(_ model: LocalModelDescriptor, progress: (@Sendable (Double) -> Void)?) async throws {
        guard let spec = model.parakeetSpec else {
            throw ModelDownloadError.unsupportedModel("Unsupported Parakeet model \(model.id)")
        }
        _ = try await AsrModels.download(
            to: modelStore.modelURL(for: model),
            version: spec.version
        ) { downloadProgress in
            progress?(downloadProgress.fractionCompleted)
        }
    }

    private func downloadWhisperKit(_ model: LocalModelDescriptor, progress: (@Sendable (Double) -> Void)?) async throws {
        let downloaded = try await WhisperKit.download(variant: model.id) { downloadProgress in
            progress?(downloadProgress.fractionCompleted)
        }
        let destination = modelStore.modelURL(for: model)
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try fileManager.copyItem(at: downloaded, to: destination)
    }
}

enum ModelDownloadError: LocalizedError {
    case unsupportedModel(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedModel(let message):
            return message
        }
    }
}
