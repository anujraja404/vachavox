import AppKit
import Carbon
import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let dictation = Self(
        "dictation",
        default: .init(.d, modifiers: [.command, .shift])
    )
}

@MainActor
final class HotKeyService {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var flagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var isFnDown = false
    private var keyboardHandlersRegistered = false
    private let model: AppModel
    private let start: @MainActor () -> Void
    private let stop: @MainActor () -> Void
    private let toggle: @MainActor () -> Void

    init(
        model: AppModel,
        start: @escaping @MainActor () -> Void,
        stop: @escaping @MainActor () -> Void,
        toggle: @escaping @MainActor () -> Void
    ) {
        self.model = model
        self.start = start
        self.stop = stop
        self.toggle = toggle
    }

    func registerConfiguredHotKey() {
        unregister()

        switch model.settings.hotkeyPreset {
        case .functionKey:
            registerFunctionKeyMonitor()
        case .commandShiftD:
            KeyboardShortcuts.Name.dictation.shortcut = .init(.d, modifiers: [.command, .shift])
            registerKeyboardShortcutsHandlers()
        case .custom:
            registerKeyboardShortcutsHandlers()
        }
    }

    private func registerKeyboardShortcutsHandlers() {
        guard !keyboardHandlersRegistered else { return }
        keyboardHandlersRegistered = true
        KeyboardShortcuts.onKeyDown(for: .dictation) { [weak self] in
            Task { @MainActor in self?.handleShortcutDown() }
        }
        KeyboardShortcuts.onKeyUp(for: .dictation) { [weak self] in
            Task { @MainActor in self?.handleShortcutUp() }
        }
    }

    private func registerFunctionKeyMonitor() {
        let handler: (NSEvent) -> Void = { [weak self] event in
            Task { @MainActor in self?.handleFlagsChanged(event) }
        }
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: handler)
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            Task { @MainActor in self?.handleFlagsChanged(event) }
            return event
        }
    }

    private func registerCarbonCommandShiftD() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return noErr }
                let service = Unmanaged<HotKeyService>.fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in
                    service.handleKeyDown()
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        let hotKeyID = EventHotKeyID(signature: OSType(0x43484150), id: 1)
        RegisterEventHotKey(
            UInt32(kVK_ANSI_D),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let fnDown = event.keyCode == 63 || event.modifierFlags.contains(.function)
        guard fnDown != isFnDown else { return }
        isFnDown = fnDown
        if fnDown {
            handleKeyDown()
        } else {
            handleKeyUp()
        }
    }

    private func handleShortcutDown() {
        guard model.settings.hotkeyPreset != .functionKey else { return }
        handleKeyDown()
    }

    private func handleShortcutUp() {
        guard model.settings.hotkeyPreset != .functionKey else { return }
        handleKeyUp()
    }

    private func handleKeyDown() {
        switch model.settings.hotkeyMode {
        case .pushToTalk:
            start()
        case .toggle:
            toggle()
        }
    }

    private func handleKeyUp() {
        guard model.settings.hotkeyMode == .pushToTalk else { return }
        stop()
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
        if let flagsMonitor {
            NSEvent.removeMonitor(flagsMonitor)
            self.flagsMonitor = nil
        }
        if let localFlagsMonitor {
            NSEvent.removeMonitor(localFlagsMonitor)
            self.localFlagsMonitor = nil
        }
        isFnDown = false
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}
