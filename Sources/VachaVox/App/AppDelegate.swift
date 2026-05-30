import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let appModel = AppModel()

    private var statusItemController: StatusItemController?
    private var settingsWindowController: SettingsWindowController?
    private var recordingOverlayWindowController: RecordingOverlayWindowController?
    private var hotKeyService: HotKeyService?
    @Published private(set) var coordinator: DictationCoordinator?
    private var permissionsService: PermissionsService?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let permissionsService = PermissionsService()
        let modelStore = ModelStore()
        let modelDownloadService = ModelDownloadService(modelStore: modelStore)
        let previewController = PreviewWindowController()
        let outputService = TextOutputService(
            permissionsService: permissionsService,
            previewController: previewController
        )
        let transcriptionEngine = TranscriptionEngineRouter(modelStore: modelStore)
        let coordinator = DictationCoordinator(
            model: appModel,
            permissionsService: permissionsService,
            audioCaptureService: AudioCaptureService(),
            voiceActivityService: VoiceActivityService(),
            modelStore: modelStore,
            modelDownloadService: modelDownloadService,
            transcriptionEngine: transcriptionEngine,
            outputService: outputService,
            fileTranscriptionService: FileTranscriptionService()
        )

        let settingsWindowController = SettingsWindowController(model: appModel, coordinator: coordinator)
        let recordingOverlayWindowController = RecordingOverlayWindowController(model: appModel)
        let statusItemController = StatusItemController(
            model: appModel,
            coordinator: coordinator,
            openSettings: {
                settingsWindowController.show()
            },
            openFileTranscriptionSettings: {
                coordinator.openFileTranscriptionSettings()
                settingsWindowController.show()
            }
        )
        let hotKeyService = HotKeyService(
            model: appModel,
            start: { coordinator.startDictation() },
            stop: { coordinator.stopDictation() },
            toggle: { coordinator.toggleDictation() }
        )

        self.permissionsService = permissionsService
        self.coordinator = coordinator
        self.settingsWindowController = settingsWindowController
        self.recordingOverlayWindowController = recordingOverlayWindowController
        self.statusItemController = statusItemController
        self.hotKeyService = hotKeyService
        AppRuntime.shared.configure(model: appModel, coordinator: coordinator)

        appModel.microphonePermission = permissionsService.microphonePermission
        appModel.accessibilityTrusted = permissionsService.isAccessibilityTrusted(prompt: false)
        coordinator.refreshModels()
        coordinator.loadBestAvailableModelOnLaunch()
        hotKeyService.registerConfiguredHotKey()
        appModel.$settings
            .map { "\($0.hotkeyPreset.rawValue)-\($0.hotkeyMode.rawValue)" }
            .removeDuplicates()
            .dropFirst()
            .sink { [weak hotKeyService] _ in
                hotKeyService?.registerConfiguredHotKey()
            }
            .store(in: &cancellables)
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyService?.unregister()
    }
}
