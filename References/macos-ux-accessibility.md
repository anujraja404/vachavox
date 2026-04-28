# macOS UX And Accessibility Reference

Last reviewed: 2026-04-28

## Purpose

Guide future VachaVox UI work toward a quiet native macOS utility: fast from the menu bar, conventional in Settings, and accessible without relying on visual-only status.

## Project Relevance

VachaVox is a SwiftPM macOS 14 menu bar dictation app with:

- A persistent status item in `Sources/VachaVox/MenuBar/StatusItemController.swift`.
- A transient popover in `Sources/VachaVox/UI/PopoverView.swift`.
- A split-view Settings surface in `Sources/VachaVox/UI/SettingsView.swift`.
- Hotkey, model, permissions, and output controls that must stay understandable in small utility surfaces.

## Key Takeaways

- Menu bar extras should expose app-specific functionality while the app is running; VachaVox should use the status item for readiness and quick dictation access, not as a second settings window.
- Popovers are transient and best for a small set of related tasks. Keep the popover compact: current state, primary action, blocking issue if any, and a short route to Settings.
- Settings should behave like settings. Apple guidance around `NavigationSplitView` and grouped forms supports the current sidebar direction, but rows should be grouped and aligned more like a native preferences window than a dashboard.
- Segmented controls fit mutually exclusive choices such as Copy/Paste/Preview and hotkey mode. Keep labels consistent and avoid mixing unrelated actions into one segmented control.
- Status cannot rely on color alone. Model readiness, permission problems, recording, transcribing, paused, and error states need text, symbols, and accessibility labels.
- VoiceOver users should be able to identify and activate every control. Repeated labels like "Delete" or "Reveal" need model-specific accessibility labels when they appear in repeated model rows.

## Implementation Implications

- Prefer a dedicated template-style menu bar glyph family over reusing the full app icon at menu bar scale.
- Treat the menu bar popover as the operational center. Settings should configure the app; the popover should answer "Can I dictate now?"
- Rename or repurpose the current Home settings pane as General or Status when doing the UI redesign. Use it as a setup/readiness page, not a dashboard.
- Use native controls consistently: `Picker` with `.segmented` for small exclusive choices, toggles for binary choices, sliders with clear semantic labels, and menus for secondary model actions.
- Add accessibility labels/values to status badges, model actions, recording overlay state, and status item icon variants.
- Verify UI changes with VoiceOver traversal, Full Keyboard Access, light/dark appearance, Differentiate Without Color, and Reduced Motion where animation is used.

## Sources

- [Apple HIG: The menu bar](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar)
- [Apple Developer: MenuBarExtra](https://developer.apple.com/documentation/SwiftUI/MenuBarExtra)
- [Apple HIG: Popovers](https://developer.apple.com/design/human-interface-guidelines/popovers)
- [Apple WWDC22: What's new in SwiftUI](https://developer.apple.com/videos/play/wwdc2022/10052/)
- [Apple HIG: Segmented controls](https://developer.apple.com/design/human-interface-guidelines/segmented-controls)
- [Apple Developer: VoiceOver evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/voiceover-evaluation-criteria)
- Existing project context: [UI redesign report](../from-chatgpt/deep-research-vachavox-macos-ui-redesign-report.md)
