import Foundation

protocol TranscriptionEngine: AnyObject {
    func prepare(model: LocalModelDescriptor) async throws
    func transcribe(_ request: TranscriptionRequest) async throws -> TranscriptionResult
    func transcribeFile(
        _ url: URL,
        punctuationEnabled: Bool,
        progress: @escaping @Sendable (Double, String) -> Void
    ) async throws -> TranscriptionResult
    func cancel() async
}

struct TranscriptionRequest: Sendable {
    var samples16k: [Float]
    var duration: TimeInterval
    var punctuationEnabled: Bool
}

struct TranscriptionResult: Sendable, Equatable {
    var text: String
}

enum TranscriptionError: LocalizedError {
    case emptyAudio
    case engineUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .emptyAudio:
            return "No speech was detected"
        case .engineUnavailable(let reason):
            return reason
        }
    }
}
