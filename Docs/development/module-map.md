# VachaVox Module Map

This is a quick boundary guide so multiple developers or agents can work in parallel with minimal conflicts.

## Core modules

- `Sources/VachaVox/App`
  - App lifecycle, state container, and dictation coordination.
  - Coordination point: touches most runtime flows; avoid mixing unrelated UI or model edits here.

- `Sources/VachaVox/UI`
  - Popover, settings screen, preview window, recording overlay, and UI anchoring.
  - Parallel-safe with model/audio internals when public interfaces remain stable.

- `Sources/VachaVox/MenuBar`
  - Menu bar status item behavior and hotkey interaction surface.
  - Coordination point with `App` and `UI` for state/status vocabulary changes.

- `Sources/VachaVox/Settings`
  - Persistent app/user settings and setting defaults.
  - Coordination point with `UI/SettingsView` and runtime consumers in `App`.

- `Sources/VachaVox/Audio`
  - Microphone capture, audio chunking, and resampling.
  - Parallel-safe with output/docs work; coordinate with transcription engine changes.

- `Sources/VachaVox/VAD`
  - Voice activity detection behavior and speech-end logic.
  - Coordination point with `Audio` and dictation session flow in `App`.

- `Sources/VachaVox/Transcription`
  - Engine protocol/router and engine-specific implementations (Parakeet, WhisperKit).
  - Coordination point with `Models` and `App` load/ready state behavior.

- `Sources/VachaVox/Models`
  - Model catalog, local discovery, download, and model readiness state.
  - Coordination point with `Transcription`, settings model UI, and permission messaging.

- `Sources/VachaVox/Output`
  - Text output destination behavior and file transcription output generation.
  - Coordination point with permissions and transcript UX copy.

- `Sources/VachaVox/Permissions`
  - Accessibility/microphone checks and permission request/open flows.
  - Coordination point with output-mode behavior and settings UI messaging.

- `Sources/VachaVox/Utilities`
  - Shared utility services (system settings opener, login item helpers).
  - Keep utility changes narrow; avoid feature logic drift here.

- `Sources/VachaVox/Resources`
  - Bundled assets, plist, entitlements, app/icon resources.
  - Coordinate any entitlement or app identity updates with release/build owners.

## Parallel work guidance

- Prefer one feature per module owner where possible (for example: one person in `Transcription`, another in `UI`).
- Avoid simultaneous edits in `App/DictationCoordinator.swift` unless changes are tightly coordinated.
- When adding new cross-module behavior, define/adjust interfaces first, then let module owners implement internals independently.
- Keep status vocabulary consistent across `MenuBar`, `UI`, and `Permissions`.
