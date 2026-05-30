import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusItemController {
    private let model: AppModel
    private let coordinator: DictationCoordinator
    private let openSettings: () -> Void
    private let openFileTranscriptionSettings: () -> Void
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let menuBarImage: NSImage?
    private var cancellables = Set<AnyCancellable>()

    init(
        model: AppModel,
        coordinator: DictationCoordinator,
        openSettings: @escaping () -> Void,
        openFileTranscriptionSettings: @escaping () -> Void
    ) {
        self.model = model
        self.coordinator = coordinator
        self.openSettings = openSettings
        self.openFileTranscriptionSettings = openFileTranscriptionSettings
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.menuBarImage = Self.loadMenuBarImage()

        configureStatusItem()
        configurePopover()

        model.$phase
            .sink { [weak self] _ in self?.updateIcon() }
            .store(in: &cancellables)
        model.$modelStatus
            .sink { [weak self] _ in self?.updateIcon() }
            .store(in: &cancellables)
        model.$microphonePermission
            .sink { [weak self] _ in self?.updateIcon() }
            .store(in: &cancellables)
        model.$accessibilityTrusted
            .sink { [weak self] _ in self?.updateIcon() }
            .store(in: &cancellables)
        model.$settings
            .sink { [weak self] _ in self?.updateIcon() }
            .store(in: &cancellables)
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.action = #selector(togglePopover)
        button.target = self
        button.toolTip = "VachaVox"
        updateIcon()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 360, height: 420)
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(
                startStop: { [weak self] in self?.coordinator.toggleDictation() },
                pauseResume: { [weak self] paused in self?.coordinator.setPaused(paused) },
                openSettings: { [weak self] in self?.openSettings() },
                openFileTranscriptionSettings: { [weak self] in self?.openFileTranscriptionSettings() },
                quit: { NSApp.terminate(nil) }
            )
            .environmentObject(model)
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        let state = model.readinessState
        let image = (menuBarImage?.copy() as? NSImage) ?? Self.fallbackMenuBarImage()
        button.image = image
        button.toolTip = "VachaVox - \(state.title)"
        button.setAccessibilityLabel("VachaVox, \(state.title)")
    }

    private static func loadMenuBarImage() -> NSImage? {
        let image = NSImage(named: "MenuBarIcon") ??
            Bundle.main.url(forResource: "MenuBarIcon", withExtension: "png").flatMap(NSImage.init(contentsOf:))
        guard let image else { return nil }
        image.isTemplate = true
        image.size = NSSize(width: 18, height: 18)
        return image
    }

    private static func fallbackMenuBarImage() -> NSImage {
        let image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "VachaVox") ?? NSImage()
        image.isTemplate = true
        image.size = NSSize(width: 18, height: 18)
        return image
    }
}
