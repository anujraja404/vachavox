import SwiftUI

@main
struct VachaVoxApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsSceneView()
        }
    }
}

@MainActor
private struct SettingsSceneView: View {
    @StateObject private var runtime = AppRuntime.shared

    var body: some View {
        if let model = runtime.appModel, let coordinator = runtime.coordinator {
            SettingsView(model: model, coordinator: coordinator)
                .frame(minWidth: 980, minHeight: 640)
        } else {
            ProgressView("Starting VachaVox")
                .frame(width: 360, height: 180)
        }
    }
}

@MainActor
final class AppRuntime: ObservableObject {
    static let shared = AppRuntime()

    @Published private(set) var appModel: AppModel?
    @Published private(set) var coordinator: DictationCoordinator?

    private init() {}

    func configure(model: AppModel, coordinator: DictationCoordinator) {
        self.appModel = model
        self.coordinator = coordinator
    }
}
