import XCTest
@testable import VachaVox

final class SettingsStoreTests: XCTestCase {
    func testRoundTripsSettings() {
        let suiteName = "VachaVoxTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        var settings = AppSettings()
        settings.selectedEngine = .whisperKit
        settings.selectedModelID = "openai_whisper-small"
        settings.hotkeyMode = .toggle
        settings.hotkeyPreset = .custom
        settings.outputMode = .paste
        settings.punctuationEnabled = false
        settings.silenceSensitivity = 0.04

        store.save(settings)

        XCTAssertEqual(store.load(), settings)
    }

    func testMigratesLegacySettingsKey() throws {
        let suiteName = "VachaVoxTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var settings = AppSettings()
        settings.outputMode = .preview
        settings.punctuationEnabled = false
        let legacyKey = ["Ch", "apad", "Ch", "apad", ".AppSettings.v1"].joined()
        defaults.set(try JSONEncoder().encode(settings), forKey: legacyKey)

        let store = SettingsStore(defaults: defaults)

        XCTAssertEqual(store.load(), settings)
        XCTAssertNotNil(defaults.data(forKey: "VachaVox.AppSettings.v1"))
    }

    @MainActor
    func testAppModelReflectsPausedSettingOnLaunch() {
        let suiteName = "VachaVoxTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        var settings = AppSettings()
        settings.isPaused = true
        store.save(settings)

        let model = AppModel(settingsStore: store)

        XCTAssertEqual(model.phase, .paused)
        XCTAssertEqual(model.statusMessage, "Paused")
    }
}
