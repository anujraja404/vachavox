import AppKit
import ApplicationServices
import Foundation

@MainActor
final class TextOutputService {
    private let permissionsService: PermissionAuthorizing
    private let previewController: PreviewPresenting
    private let outputTargetController: OutputTargetControlling

    init(
        permissionsService: PermissionAuthorizing,
        previewController: PreviewPresenting,
        outputTargetController: OutputTargetControlling? = nil
    ) {
        self.permissionsService = permissionsService
        self.previewController = previewController
        self.outputTargetController = outputTargetController ?? SystemOutputTargetController()
    }

    func capturePasteTarget() -> OutputTargetSnapshot? {
        outputTargetController.captureFocusedTarget(
            excludingBundleIdentifier: Bundle.main.bundleIdentifier
        )
    }

    func deliver(
        _ text: String,
        mode: OutputMode,
        pasteTarget: OutputTargetSnapshot? = nil
    ) async throws -> OutputDeliveryResult {
        switch mode {
        case .copy:
            copy(text)
            return .copied
        case .paste:
            if permissionsService.isAccessibilityTrusted(prompt: false) {
                guard let pasteTarget else {
                    copy(text)
                    return .copiedPasteTargetUnavailable
                }
                guard await outputTargetController.restore(pasteTarget) else {
                    copy(text)
                    return .copiedPasteTargetUnavailable
                }
                pastePreservingClipboard(text)
                return .pasted(targetName: pasteTarget.displayName)
            } else {
                copy(text)
                return .copiedAccessibilityMissing
            }
        case .preview:
            previewController.show(text: text) { [weak self] acceptedText in
                self?.copy(acceptedText)
            }
            return .previewing
        }
    }

    func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func pastePreservingClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        let previousString = pasteboard.string(forType: .string)

        copy(text)
        outputTargetController.postPasteShortcut()

        if let previousString {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                pasteboard.clearContents()
                pasteboard.setString(previousString, forType: .string)
            }
        }
    }
}

struct OutputTargetSnapshot: Equatable {
    var processIdentifier: pid_t
    var bundleIdentifier: String?
    var localizedName: String?

    var displayName: String {
        localizedName ?? bundleIdentifier ?? "target app"
    }
}

@MainActor
protocol OutputTargetControlling {
    func captureFocusedTarget(excludingBundleIdentifier: String?) -> OutputTargetSnapshot?
    func restore(_ target: OutputTargetSnapshot) async -> Bool
    func postPasteShortcut()
}

@MainActor
final class SystemOutputTargetController: OutputTargetControlling {
    func captureFocusedTarget(excludingBundleIdentifier: String?) -> OutputTargetSnapshot? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        if let excludingBundleIdentifier, app.bundleIdentifier == excludingBundleIdentifier {
            return nil
        }
        return OutputTargetSnapshot(
            processIdentifier: app.processIdentifier,
            bundleIdentifier: app.bundleIdentifier,
            localizedName: app.localizedName
        )
    }

    func restore(_ target: OutputTargetSnapshot) async -> Bool {
        guard let app = NSRunningApplication(processIdentifier: target.processIdentifier),
              !app.isTerminated else {
            return false
        }
        let activated = app.activate(options: [])
        try? await Task.sleep(nanoseconds: 180_000_000)
        return activated
    }

    func postPasteShortcut() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}

enum OutputDeliveryResult: Equatable {
    case copied
    case pasted(targetName: String)
    case copiedAccessibilityMissing
    case copiedPasteTargetUnavailable
    case previewing

    var statusMessage: String {
        switch self {
        case .copied:
            return "Copied"
        case .pasted(let targetName):
            return "Pasted into \(targetName)"
        case .copiedAccessibilityMissing:
            return "Copied - enable Accessibility for paste"
        case .copiedPasteTargetUnavailable:
            return "Copied - paste target unavailable"
        case .previewing:
            return "Previewing"
        }
    }
}
