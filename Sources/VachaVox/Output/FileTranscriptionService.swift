import Foundation

struct FileTranscriptMetadata: Equatable {
    var sourceFileName: String
    var sourcePath: String
    var generatedAt: Date
    var modelDisplayName: String
    var engineLabel: String
}

struct FileTranscriptWriteResult: Equatable {
    var outputURL: URL
    var markdown: String
}

struct FileTranscriptionService {
    var outputRoot: URL
    var fileManager: FileManager
    var dateProvider: () -> Date

    init(
        outputRoot: URL = FileTranscriptionService.defaultOutputRoot,
        fileManager: FileManager = .default,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.outputRoot = outputRoot
        self.fileManager = fileManager
        self.dateProvider = dateProvider
    }

    static var defaultOutputRoot: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("vachavox", isDirectory: true)
            .appendingPathComponent("output", isDirectory: true)
    }

    func writeTranscript(
        sourceURL: URL,
        transcript: String,
        model: LocalModelDescriptor,
        generatedAt: Date? = nil
    ) throws -> FileTranscriptWriteResult {
        let cleanedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTranscript.isEmpty else {
            throw TranscriptionError.emptyAudio
        }

        let date = generatedAt ?? dateProvider()
        try fileManager.createDirectory(at: outputRoot, withIntermediateDirectories: true)

        let outputURL = outputRoot.appendingPathComponent(
            outputFileName(sourceURL: sourceURL, generatedAt: date)
        )
        let metadata = FileTranscriptMetadata(
            sourceFileName: sourceURL.lastPathComponent,
            sourcePath: sourceURL.path,
            generatedAt: date,
            modelDisplayName: model.displayName,
            engineLabel: model.engine.label
        )
        let markdown = Self.markdown(metadata: metadata, transcript: cleanedTranscript)
        try markdown.write(to: outputURL, atomically: true, encoding: .utf8)
        return FileTranscriptWriteResult(outputURL: outputURL, markdown: markdown)
    }

    func outputFileName(sourceURL: URL, generatedAt: Date? = nil) -> String {
        let date = generatedAt ?? dateProvider()
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        return "\(Self.sanitizedBaseName(baseName))_\(Self.timestampFormatter().string(from: date)).md"
    }

    static func markdown(metadata: FileTranscriptMetadata, transcript: String) -> String {
        let generated = metadata.generatedAt.formatted(date: .abbreviated, time: .standard)
        let body = readableLines(from: transcript).joined(separator: "\n\n")
        return """
        # Transcript: \(metadata.sourceFileName)

        Generated: \(generated)

        Model: \(metadata.modelDisplayName)

        Engine: \(metadata.engineLabel)

        Source: \(metadata.sourcePath)

        ## Transcript

        \(body)
        """
    }

    static func readableLines(from transcript: String, fallbackWordLimit: Int = 30) -> [String] {
        let normalized = transcript
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return [] }

        let sentencePattern = #"(?<=[.!?])\s+|\n+"#
        let sentenceParts = normalized
            .split(usingRegex: sentencePattern)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if sentenceParts.count > 1 || normalized.rangeOfCharacter(from: CharacterSet(charactersIn: ".!?")) != nil {
            return sentenceParts
        }

        let words = normalized.split { $0.isWhitespace }.map(String.init)
        guard words.count > fallbackWordLimit else { return [normalized] }

        var lines: [String] = []
        var current: [String] = []
        for word in words {
            current.append(word)
            if current.count >= fallbackWordLimit {
                lines.append(current.joined(separator: " "))
                current.removeAll(keepingCapacity: true)
            }
        }
        if !current.isEmpty {
            lines.append(current.joined(separator: " "))
        }
        return lines
    }

    static func sanitizedBaseName(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let scalars = name.unicodeScalars.map { scalar -> Character in
            allowed.contains(scalar) ? Character(scalar) : "_"
        }
        let collapsed = String(scalars)
            .replacingOccurrences(of: #"_+"#, with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_-"))
        return collapsed.isEmpty ? "audio" : collapsed
    }

    private static func timestampFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }
}

private extension String {
    func split(usingRegex pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [self]
        }
        let nsRange = NSRange(startIndex..<endIndex, in: self)
        var parts: [String] = []
        var previousLocation = nsRange.location
        for match in regex.matches(in: self, range: nsRange) {
            let partRange = NSRange(location: previousLocation, length: match.range.location - previousLocation)
            if let range = Range(partRange, in: self) {
                parts.append(String(self[range]))
            }
            previousLocation = match.range.location + match.range.length
        }
        let tailRange = NSRange(location: previousLocation, length: nsRange.location + nsRange.length - previousLocation)
        if let range = Range(tailRange, in: self) {
            parts.append(String(self[range]))
        }
        return parts
    }
}
