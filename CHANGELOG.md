# Version History

## Unreleased

### Improvements

- Reimagined the dictation popup as a centered top overlay on the active display with a native material card style.
- Added post-transcription transcript preview in the popup (up to 250 characters), then auto-dismiss after 2 seconds with a 1 second fade.
- Replaced the logo-first overlay treatment with Apple default symbols, default macOS font styling, and compact wrapped transcript text.

## 0.6.1 - 2026-04-28

Build: `21`

### Improvements

- Updated the default model root path to `/Users/macbookpro/local_ai_models/voice_models`.
- Kept model resolution behavior the same so engine and model folders are still appended by descriptor.

### Docs

- Updated README version and model root path documentation for the new default storage location.

## 0.6.0 - 2026-04-28

Build: `20`

### New Features

- Added Settings > File Transcription for choosing a local audio file and generating one Markdown transcript in `~/vachavox/output`.
- Added a menu bar popover shortcut that opens the File Transcription settings pane directly.
- Added file transcription support to the engine boundary, using FluidAudio's file URL transcription path for Parakeet and AVFoundation conversion for WhisperKit.

### Improvements

- File transcription uses the selected loaded local model without requiring Microphone or Accessibility permission.
- Generated Markdown includes source, generated timestamp, model, engine, and a readable transcript section with statement-style line breaks.
- Cancellation and completed output reveal actions are handled separately from dictation output delivery.

### Docs

- Updated privacy docs to clarify that generated Markdown transcripts are explicit user-created files.
- Documented the Parakeet 15 second Core ML pass limit and FluidAudio's internal long-audio chunking behavior.

### Tests

- Added file transcript writer coverage for output directory creation, sanitized timestamped names, metadata, default output root, and readable line splitting.
- Added coordinator coverage for missing loaded model errors, successful Markdown generation, no microphone/accessibility dependency, empty transcript failure, and cancellation state.

## 0.5.0 - 2026-04-28

Build: `17`

### Improvements

- Kept the packaged VachaVox menu bar glyph visible across idle, listening, transcribing, error, model, and permission states.
- Updated the packaged menu bar icon to a filled-circle template badge with the VachaVox mark cut through the center.
- Replaced the recording overlay text panel with a smaller square icon-only overlay using a pulsing red VachaVox mark.
- Moved the overlay anchor to the focused text field or caret, with top-center fallback placement near the camera notch when macOS does not expose text bounds.

### Tests

- Added overlay positioning coverage for default placement, bottom-edge flipping, edge clamping, and missing-anchor fallback.

## 0.4.1 - 2026-04-28

Build: `13`

### Fixes

- Fixed a crash when reopening Settings from the menu bar popover after the Settings window had been closed.
- Made Paste output restore the captured target app before posting Command-V, with clipboard fallback when Accessibility trust or the paste target is unavailable.

### Improvements

- Added explicit selected/loaded model readiness so installed models are no longer treated as active until they successfully load.
- Added clearer Settings > Models load controls and active load state messaging.
- Improved Settings > Permissions actions with separate request/open/re-check flows for Accessibility and Microphone status.

### Tests

- Added coverage for model load readiness, launch fallback selection, Accessibility paste fallback, and target-restore paste delivery.

## 0.4.0 - 2026-04-28

### New Features

- Redesigned the macOS Settings window with a General readiness page, grouped configuration sections, contextual permission rows, and a structured Privacy diagnostics pane.
- Reworked the menu bar popover into a compact operational panel with one primary action per state and session-scoped last transcript controls.
- Added state-specific menu bar symbols and accessibility labels for ready, paused, listening, transcribing, missing model, permission, and error states.

### Improvements

- Simplified model rows to use one primary action, such as Use Model or Download, with Reveal, Open Source, and Delete moved into a secondary menu.
- Made Accessibility messaging contextual to Paste output mode while keeping Copy and Preview available without Accessibility trust.
- Refined Dictation and Hotkeys copy so output behavior, speech-end behavior, performance tradeoffs, and shortcut mode are clearer.
- Polished the recording overlay and Preview Dictation window with local transcription language, better focus behavior, and default/cancel keyboard actions.
- Renamed the SwiftPM package, executable, source target, test target, and packaged binary to VachaVox.
- Moved local model storage to `~/vachavox/models` with migration from the previous model root when the new folder is missing.
- Added project agent instructions in `AGENTS.md`, including the hard ignore rule for the working folder.
- Updated packaging to preserve `build/VachaVox.app` and create a versioned archive app for each build number.

## 0.3.2

### New Features

- Added the final VachaVox brand asset package generated from `from-chatgpt/logo-v2-detailed.png`.
- Added `Docs/vachavox-brand-assets-final.zip` with SVG, PNG, WebP, PDF, favicon, app icon, social, web, template, and theme-token assets.
- Added logo dimensions and usage specs under `Docs/docs-brand/`.

### Improvements

- Refreshed the packaged `VachaVox.icns` app icon from the final brand board.
- Replaced the menu bar template image with the final V-shaped waveform glyph.

## 0.3.1.1

### Fixes

- Added a manual refresh action in Settings > Permissions so the app re-checks Microphone and Accessibility status after the user grants access in macOS System Settings.
- Changed the Accessibility settings action to request the macOS Accessibility trust prompt before opening System Settings, matching the TypeWhisper flow that reliably registers the app in Privacy & Security > Accessibility.
- Added short permission polling after opening permission settings so the app updates its displayed permission state without requiring a restart.

## 0.3.1

### New Features

- Renamed and rebranded the packaged app to VachaVox.
- Added the VachaVox icon from `Docs/docs-brand/VachaVox_logo_final.png`.

### Improvements

- Moved the recording overlay near the focused text cursor when caret bounds are available.
- Added mouse-position fallback for apps that do not expose caret bounds through macOS Accessibility.
- Removed previous transcript text from the recording overlay.
- Simplified the overlay copy to current recording/transcribing state only.

## 0.3.0

### New Features

- Added startup model preloading using the best installed local model.
- Split Settings > Models into downloaded models and available downloads.
- Added source links, clearer local paths, progress indicators, and delete confirmation for model management.

### Improvements

- Aligned Parakeet local folder paths with FluidAudio's download/load layout so downloaded Parakeet models can be loaded reliably.
- Added legacy `*-coreml` Parakeet folder diagnostics with move/redownload guidance.
- Refined Settings and Popover styling toward native macOS grouped controls and clearer model readiness states.

### Tests

- Added Parakeet folder mapping coverage for v3, v2, and 110M models.
- Added best-available model priority coverage.
- Added legacy Parakeet folder diagnostic coverage.

## 0.2.0

Current rewrite release.

### New Features

- Added local Parakeet and WhisperKit model support.
- Added model storage under `~/vachavox/models`.
- Added model catalog entries for Parakeet TDT v3, Parakeet TDT v2, Parakeet TDT-CTC 110M, and Whisper-family Core ML models.
- Added model scan, validation, download, load, delete, reveal in Finder, and refresh workflows.
- Added a transcription engine router for Parakeet and WhisperKit.
- Added a WhisperKit transcription engine for local Whisper-family models.
- Added Fn push-to-talk as the default hotkey.
- Added configurable non-Fn shortcuts through KeyboardShortcuts.
- Added push-to-talk and toggle hotkey modes.
- Added a full-size Settings window with Home, Models, Dictation, Hotkeys, Permissions, and Privacy/About sections.
- Added a polished menu bar popover with selected model, engine, output, hotkey, pause, settings, quit, and last transcript controls.
- Added a lightweight recording/transcribing overlay.
- Added a new app icon and white/template menu bar icon.

### Improvements

- Changed default output mode to paste.
- Added clipboard fallback with a clear status message when Accessibility permission is missing.
- Stopped silent model download on first dictation; models are now downloaded or installed explicitly.
- Added GPLv3 license file and TypeWhisper attribution.
- Added dependency attribution for WhisperKit, KeyboardShortcuts, and FluidAudio.
- Updated packaging to copy resources and set `CFBundleIconFile`.
- Added documentation for model sources and manual model installation.

### Tests

- Added settings round-trip coverage for engine, model, hotkey, and output settings.
- Added model scanning tests for valid and invalid Parakeet folders.
- Added model scanning tests for valid and invalid WhisperKit folders.
- Added tests for missing selected model status and empty model catalog state.

### Verification

- `swift build`
- `swift test`
- `Scripts/package_app.sh`
- `Scripts/compile_and_run.sh`

## 0.1.0

Initial high-level prototype release.

- SwiftPM macOS menu bar app.
- Basic microphone capture and dictation flow.
- Initial FluidAudio Parakeet transcription path.
- Basic settings, status item, and clipboard/paste output behavior.
