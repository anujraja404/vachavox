import AppKit
import Combine
import SwiftUI

@MainActor
final class RecordingOverlayWindowController {
    private let model: AppModel
    private let window: NSPanel
    private var cancellables = Set<AnyCancellable>()

    init(model: AppModel) {
        self.model = model
        self.window = NSPanel(
            contentRect: NSRect(
                origin: .zero,
                size: RecordingOverlayPositioning.overlaySize
            ),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.contentViewController = NSHostingController(
            rootView: RecordingOverlayView(model: model)
        )

        model.$phase
            .combineLatest(model.$popupResultVisible, model.$popupResultText)
            .sink { [weak self] phase, popupVisible, popupText in
                self?.syncVisibility(phase: phase, popupVisible: popupVisible, popupText: popupText)
            }
            .store(in: &cancellables)
    }

    private func syncVisibility(phase: DictationPhase, popupVisible: Bool, popupText: String) {
        let visible = phase == .listening || phase == .transcribing || popupVisible
        if visible {
            resizeForPhase(phase, popupVisible: popupVisible, popupText: popupText)
            position()
            window.orderFrontRegardless()
        } else {
            window.orderOut(nil)
        }
    }

    private func resizeForPhase(_ phase: DictationPhase, popupVisible: Bool, popupText: String) {
        let size = Self.idealSize(phase: phase, popupVisible: popupVisible, popupText: popupText)
        let currentFrame = window.frame
        let resized = NSRect(origin: currentFrame.origin, size: size)
        window.setFrame(resized, display: true)
    }

    private static func idealSize(phase: DictationPhase, popupVisible: Bool, popupText: String) -> CGSize {
        if popupVisible, !popupText.isEmpty {
            let resultWidth = min(
                RecordingOverlayPositioning.resultMaxWidth,
                max(RecordingOverlayPositioning.resultMinWidth, CGFloat(popupText.count) * 5.4)
            )
            let contentWidth = max(0, resultWidth - 28)
            let textHeight = popupText.heightForOverlay(width: contentWidth)
            let estimatedHeight = max(102, min(300, textHeight + 44))
            return CGSize(width: resultWidth, height: estimatedHeight)
        }

        switch phase {
        case .listening:
            return CGSize(width: 188, height: 62)
        case .transcribing:
            return CGSize(width: 232, height: 62)
        default:
            return RecordingOverlayPositioning.overlaySize
        }
    }

    private func position() {
        let screen = activeMenuBarScreen() ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else { return }
        let origin = RecordingOverlayPositioning.menuBarCenteredOrigin(
            overlaySize: window.frame.size,
            visibleFrame: visibleFrame
        )
        window.setFrameOrigin(origin)
    }

    private func activeMenuBarScreen() -> NSScreen? {
        if let keyScreen = NSApp.keyWindow?.screen ?? NSApp.mainWindow?.screen {
            return keyScreen
        }
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { screen in
            screen.frame.contains(mouse)
        }
    }
}

private struct RecordingOverlayView: View {
    @ObservedObject var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: showsResultText ? 7 : 8) {
            if showsResultText {
                Text(model.popupResultText)
                    .font(.system(size: 13))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Image(systemName: "command")
                        .font(.system(size: 11, weight: .regular))
                    Text("Use V to paste")
                        .font(.system(size: 11, weight: .regular))
                        .lineLimit(1)
                }
                .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(titleText)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: showsResultText ? RecordingOverlayPositioning.resultMaxWidth : 236, alignment: .leading)
        .background(backgroundSurface)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .opacity(resultOpacity)
        .scaleEffect(reduceMotion ? 1 : (showsResultText ? 1 : 0.96))
        .animation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.86), value: showsResultText)
        .animation(reduceMotion ? nil : .easeOut(duration: 1.0), value: model.popupResultFading)
    }

    private var accessibilityLabel: String {
        if showsResultText {
            return "VachaVox, transcript copied. Use Command V to paste."
        }
        return model.phase == .listening ? "VachaVox, Listening" : "VachaVox, Transcribing locally"
    }

    private var showsResultText: Bool {
        model.popupResultVisible && !model.popupResultText.isEmpty
    }

    private var titleText: String {
        return model.phase == .listening ? "Listening" : "Transcribing locally"
    }

    private var iconName: String {
        return model.phase == .listening ? "mic.fill" : "waveform.and.magnifyingglass"
    }

    @ViewBuilder
    private var backgroundSurface: some View {
        if #available(macOS 15.0, *) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        }
    }

    private var resultOpacity: Double {
        guard showsResultText else { return 1 }
        return model.popupResultFading ? 0 : 1
    }
}

private extension String {
    func heightForOverlay(width: CGFloat) -> CGFloat {
        guard width > 0 else { return 0 }
        let bounding = (self as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: NSFont.systemFont(ofSize: 13)],
            context: nil
        )
        return ceil(bounding.height)
    }
}
