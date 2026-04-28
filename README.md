# VachaVox

Local-first native macOS menu bar dictation app built with SwiftPM for macOS 14.

Current version: `0.6.1 (21)`.

## What It Does

- Records while you hold Fn by default, then transcribes locally.
- Shows a centered top popup during dictation and briefly previews the generated transcript text after completion.
- Pastes the result into the frontmost app when Accessibility is granted.
- Keeps Copy and Preview output modes available without Accessibility trust.
- Supports local Parakeet Core ML models through FluidAudio.
- Supports local OpenAI Whisper-family Core ML models through WhisperKit.
- Generates local Markdown transcripts from selected audio files.
- Provides a menu bar popover, recording overlay, and full settings window.

“OpenAI downloadable models” means local Whisper/WhisperKit Core ML models. This app does not use the OpenAI cloud API.

## Version 0.6.1

- Changes the default model root to `/Users/macbookpro/local_ai_models/voice_models`.
- Keeps model engine and model folder composition unchanged under that root (for example, `parakeet/parakeet-tdt-0.6b-v3`).

## Version 0.6.0

- Adds Settings > File Transcription for choosing an audio file and generating one Markdown transcript under `~/vachavox/output`.
- Adds a menu bar popover shortcut that opens the File Transcription pane directly.
- Uses the loaded local model for file transcription without requiring Microphone or Accessibility permission.
- Keeps long Parakeet audio user-friendly by relying on FluidAudio's internal chunking and disk-backed file path.
- Formats transcript bodies into readable Markdown lines instead of one large paragraph.

## Version 0.5.0

- Uses a filled-circle VachaVox menu bar icon that matches macOS template icon conventions.
- Replaces the recording overlay text panel with a compact square overlay that shows only a smaller red VachaVox mark.
- Anchors the recording overlay to the focused text field or caret, with a top-center fallback near the camera notch when macOS does not expose text bounds.

## Version 0.4.1

- Keeps model installation separate from model readiness: the selected model must load successfully before dictation starts.
- Adds explicit model load controls and loaded/active status in Settings > Models.
- Fixes a Settings reopen crash after the Settings window has been closed.
- Improves Paste mode by restoring the captured target app before posting Command-V, with clipboard fallback when needed.
- Improves Accessibility permission handling with request, System Settings, and re-check actions in Settings > Permissions.

## Version 0.4.0

- Redesigned Settings around a General readiness page, grouped forms, and clearer state language.
- Simplified model management so each model row has one primary action plus secondary actions in a menu.
- Reworked the popover, menu bar icon states, overlay, preview window, permission copy, and privacy diagnostics for the local-first VachaVox flow.
- Made Accessibility messaging contextual to Paste output mode.

## Version 0.3.2

- Added the final VachaVox brand asset package under `Docs/brand-assets/` and `Docs/vachavox-brand-assets-final.zip`.
- Refreshed the packaged app icon and menu bar glyph from the approved final VachaVox logo board.
- Added logo dimensions and usage specs for generated web, app, social, and template assets.

## Version 0.3.1.1

- Added a Settings > Permissions refresh button to re-check Microphone and Accessibility status after changes in macOS System Settings.
- Updated the Accessibility settings action to request the macOS trust prompt before opening System Settings, matching the working TypeWhisper permission flow.

## Version 0.3.1

- Completed the app rebrand to VachaVox.
- Added the VachaVox app icon and updated packaged app metadata.
- Moved the recording overlay near the active text cursor when macOS exposes caret bounds, with mouse-position fallback.
- Simplified the recording overlay so it shows only the current recording/transcribing state, not previous transcripts.

## Version 0.3.0

- Fixed Parakeet model storage so downloaded FluidAudio models are validated and loaded from the same folder layout.
- Added startup preloading of the best installed local model.
- Split Settings > Models into downloaded models and available downloads.
- Added clearer model status, progress, source links, delete confirmation, and native macOS visual polish.

## Version 0.2.0

This version is the TypeWhisper-inspired rewrite while keeping the SwiftPM macOS app structure.

- Added GPLv3 licensing and TypeWhisper attribution.
- Added WhisperKit and KeyboardShortcuts dependencies.
- Added a local model catalog for Parakeet and WhisperKit models under `~/vachavox/models`.
- Added explicit model scanning, validation, download, load, delete, reveal, and refresh actions.
- Added a transcription router that selects the correct local engine for Parakeet or WhisperKit.
- Changed the default output mode to paste, with clipboard fallback when Accessibility is missing.
- Replaced the fixed Command-Shift-D hotkey with Fn push-to-talk by default.
- Added configurable shortcut support for normal key combinations.
- Rebuilt Settings as a full-size sidebar window.
- Rebuilt the menu bar popover with model, engine, output, hotkey, pause, settings, quit, and last transcript controls.
- Added a lightweight recording/transcribing overlay.
- Added a generated app icon, white template menu bar icon, and package script icon metadata.
- Added model installation/source docs and model validation tests.

See [CHANGELOG.md](CHANGELOG.md) for version history.

## Development

```bash
swift build
swift test
Scripts/package_app.sh
Scripts/compile_and_run.sh
src/scripts/create_dev_test_build.sh
```

This is a SwiftPM app, not an Xcode project. `Scripts/package_app.sh` builds the executable, assembles `build/VachaVox.app`, copies resources, sets the app icon, signs the bundle, and copies a versioned archive app into `build/`.

Packaging creates:

```text
build/VachaVox.app
build/VachaVox V<marketing-version> B<build-number>.app
```

Dev test packaging creates:

```text
src/dev_builds/VachaVox-dev-test-<timestamp>.app
```

`src/scripts/create_dev_test_build.sh` is for development-only verification. It does not modify version numbers, does not run release-only documentation steps, and does not create release archives under `build/`. The script temporarily applies any patch files under `src/patch/` (for example `src/patch/model_path_patch/model-path-override.patch`) during build assembly and reverts those source changes before exiting.

## Models

Model root:

```text
/Users/macbookpro/local_ai_models/voice_models
├── parakeet
│   └── parakeet-tdt-0.6b-v3
└── whisperkit
    └── openai_whisper-small
```

Use Settings > Models to download, select, load, reveal, or delete model folders. A model can be installed but not active; Settings shows the selected model's load state and whether it is ready for dictation. Manual setup details are in [Docs/model-installation.md](Docs/model-installation.md), and model options are listed in [Docs/model-sources.md](Docs/model-sources.md).

## File Transcription

Open Settings > File Transcription, choose an audio file, and click Generate. VachaVox writes exactly one Markdown file to:

```text
~/vachavox/output
```

The filename uses the source audio basename plus generation date and time, such as `meeting_2026-04-28_14-35-09.md`. File transcription runs locally, uses the selected loaded model, and does not paste, copy, upload, or require microphone access.

## License And Attribution

VachaVox is licensed under GPLv3. See [LICENSE](LICENSE).

Includes code and design patterns adapted from [TypeWhisper](https://github.com/TypeWhisper/typewhisper-mac).

Dependencies:

- [FluidAudio](https://github.com/FluidInference/FluidAudio)
- [WhisperKit](https://github.com/argmaxinc/WhisperKit)
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)

Future cloud transcription could be added with secure API key storage, but it is not part of the current local downloadable model work.
