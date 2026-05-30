import AppKit
import SwiftUI

@MainActor
final class PreviewWindowController {
    private var window: NSWindow?

    func show(text: String, accept: @escaping (String) -> Void) {
        let view = PreviewView(
            text: text,
            accept: { [weak self] editedText in
                accept(editedText)
                self?.window?.close()
            },
            cancel: { [weak self] in
                self?.window?.close()
            }
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preview Dictation"
        window.minSize = NSSize(width: 460, height: 260)
        window.center()
        window.contentViewController = NSHostingController(rootView: view)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }
}

private struct PreviewView: View {
    @State private var text: String
    @FocusState private var editorFocused: Bool
    let accept: (String) -> Void
    let cancel: () -> Void

    init(text: String, accept: @escaping (String) -> Void, cancel: @escaping () -> Void) {
        self._text = State(initialValue: text)
        self.accept = accept
        self.cancel = cancel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit text before copying.")
                .font(.callout)
                .foregroundStyle(.secondary)

            TextEditor(text: $text)
                .font(.body)
                .frame(minHeight: 190)
                .padding(6)
                .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 1)
                }
                .focused($editorFocused)
                .accessibilityLabel("Dictation preview text")

            HStack {
                Spacer()
                Button("Cancel", action: cancel)
                    .keyboardShortcut(.cancelAction)
                Button("Copy") {
                    accept(text)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(18)
        .onAppear {
            editorFocused = true
        }
    }
}
