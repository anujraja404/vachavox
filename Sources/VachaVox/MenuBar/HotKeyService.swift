import AppKit
import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let dictation = Self(
        "dictation",
        default: .init(.d, modifiers: [.command, .shift])
    )
}

enum FunctionKeyTransition: Equatable {
    case down
    case up
}

struct FunctionKeyStateTracker {
    private(set) var isDown = false

    mutating func transition(isFunctionKeyEvent: Bool, functionModifierDown: Bool) -> FunctionKeyTransition? {
        guard isFunctionKeyEvent || functionModifierDown != isDown else { return nil }
        guard functionModifierDown != isDown else { return nil }

        isDown = functionModifierDown
        return functionModifierDown ? .down : .up
    }

    mutating func reset() {
        isDown = false
    }
}

@MainActor
final class HotKeyService {
    private static let functionKeyCode: UInt16 = 63

    private var flagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var functionKeyState = FunctionKeyStateTracker()
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

    private func handleFlagsChanged(_ event: NSEvent) {
        guard model.settings.hotkeyPreset == .functionKey else { return }

        let transition = functionKeyState.transition(
            isFunctionKeyEvent: event.keyCode == Self.functionKeyCode,
            functionModifierDown: event.modifierFlags.contains(.function)
        )

        switch transition {
        case .down:
            handleKeyDown()
        case .up:
            handleKeyUp()
        case nil:
            break
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
        if let flagsMonitor {
            NSEvent.removeMonitor(flagsMonitor)
            self.flagsMonitor = nil
        }
        if let localFlagsMonitor {
            NSEvent.removeMonitor(localFlagsMonitor)
            self.localFlagsMonitor = nil
        }
        functionKeyState.reset()
    }
}
