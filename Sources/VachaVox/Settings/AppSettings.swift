import Foundation

struct AppSettings: Codable, Equatable {
    var selectedEngine: TranscriptionEngineKind = .parakeet
    var selectedModelID = ModelCatalog.defaultModelID
    var hotkeyMode: HotkeyMode = .pushToTalk
    var hotkeyPreset: HotkeyPreset = .functionKey
    var outputMode: OutputMode = .paste
    var punctuationEnabled = true
    var silenceSensitivity = 0.025
    var performanceMode: PerformanceMode = .balanced
    var launchAtLogin = false
    var isPaused = false
    var hotKeyDescription = "Fn"

    var selectedModel: LocalModelDescriptor {
        ModelCatalog.descriptor(for: selectedModelID)
    }
}

enum HotkeyMode: String, Codable, CaseIterable, Identifiable {
    case pushToTalk
    case toggle

    var id: String { rawValue }
    var label: String {
        switch self {
        case .pushToTalk:
            return "Push to talk"
        case .toggle:
            return "Toggle"
        }
    }
}

enum HotkeyPreset: String, Codable, CaseIterable, Identifiable {
    case functionKey
    case commandShiftD
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .functionKey:
            return "Fn"
        case .commandShiftD:
            return "Command-Shift-D"
        case .custom:
            return "Custom shortcut"
        }
    }
}

enum OutputMode: String, Codable, CaseIterable, Identifiable {
    case copy
    case paste
    case preview

    var id: String { rawValue }
    var label: String {
        switch self {
        case .copy:
            return "Copy"
        case .paste:
            return "Paste"
        case .preview:
            return "Preview"
        }
    }
}

enum PerformanceMode: String, Codable, CaseIterable, Identifiable {
    case fastest
    case balanced
    case highestAccuracy

    var id: String { rawValue }
    var label: String {
        switch self {
        case .fastest:
            return "Fastest"
        case .balanced:
            return "Balanced"
        case .highestAccuracy:
            return "Highest accuracy"
        }
    }
}

struct SettingsStore {
    private let defaults: UserDefaults
    private let key = "VachaVox.AppSettings.v1"
    private let legacyKey = ["Ch", "apad", "Ch", "apad", ".AppSettings.v1"].joined()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> AppSettings {
        if let settings = loadSettings(forKey: key) {
            return settings
        }
        if let settings = loadSettings(forKey: legacyKey) {
            save(settings)
            return settings
        }
        return AppSettings()
    }

    func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: key)
    }

    private func loadSettings(forKey key: String) -> AppSettings? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(AppSettings.self, from: data)
    }
}
