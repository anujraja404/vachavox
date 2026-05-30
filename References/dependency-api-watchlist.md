# Dependency And API Watchlist

Last reviewed: 2026-04-28

## Purpose

Track external APIs, packages, and model sources that can materially affect VachaVox behavior, compatibility, privacy, or distribution.

## Project Relevance

VachaVox depends on external speech engines, model repositories, macOS permission APIs, and keyboard shortcut behavior. Changes upstream can break model loading, recording, insertion, or the privacy promise even when VachaVox source code has not changed.

## Current Project Baseline

- SwiftPM app targeting macOS 14.
- `Package.swift` minimums: FluidAudio `0.12.4`, WhisperKit `0.17.0`, KeyboardShortcuts `2.3.0`.
- `Package.resolved` pins: FluidAudio `0.14.1`, WhisperKit `0.18.0`, KeyboardShortcuts `2.4.0`.
- Model root: `~/vachavox/models`.
- Packaged app resources include `VachaVox.icns`, `MenuBarIcon.png`, `Info.plist`, and entitlements.

## Key Takeaways

- Treat dependency bumps as behavior changes, not housekeeping.
- Model repository layout matters as much as package APIs because VachaVox validates and loads local folders.
- SpeechAnalyzer is strategically important, but it does not fit the current macOS 14 baseline without availability gates.

## Watch Items

| Item | Why it matters | Update trigger |
| --- | --- | --- |
| FluidAudio | Owns Parakeet ASR integration, model loading behavior, and future streaming/endpointing options. | New minor release, changed model asset layout, new ASR version, or breaking `AsrModels`/`AsrManager` APIs. |
| Parakeet Core ML model repos | Determines model folder requirements, language coverage, and download sizes. | New recommended model, changed Hugging Face repo layout, checksum strategy, or language/RAM guidance. |
| WhisperKit/Argmax | Owns Whisper-family Core ML integration and model compatibility. | New package release, renamed GitHub package path, changed model download conventions, or streaming/local-server changes relevant to VachaVox. |
| `argmaxinc/whisperkit-coreml` | Source of WhisperKit Core ML model artifacts. | New model naming convention, removed model, revised recommended model, or changed file layout. |
| KeyboardShortcuts | Owns custom global shortcut recorder behavior and conflict warnings. | New macOS compatibility release, recorder UI behavior change, media/Fn key support change, or conflict handling changes. |
| Apple SpeechAnalyzer | Potential future local engine on macOS 26+. | VachaVox raises deployment target, user demand for no model downloads, or Apple expands supported devices/languages. |
| Apple permission APIs | Microphone and Accessibility behavior directly affect onboarding and output mode reliability. | macOS privacy prompt changes, TCC behavior changes, App Store review changes, or new required purpose strings. |
| Apple HIG and accessibility guidance | Determines expected macOS menu bar, popover, settings, and VoiceOver behavior. | Major macOS design update, new menu bar/status item guidance, or App Store accessibility metadata changes. |

## Implementation Implications

- Before dependency upgrades, run `swift test` and manually test model refresh, model load, hotkey recording, Fn push-to-talk, and paste output.
- Before changing model folders, test manual install, in-app download, reveal, delete, and failed/partial download states.
- Before adopting SpeechAnalyzer, create a separate engine adapter behind availability checks and keep FluidAudio/WhisperKit paths intact for macOS 14 users.
- Before changing permission copy, confirm `Info.plist`, Settings copy, popover blocking states, and troubleshooting docs stay consistent.

## Sources

- [FluidAudio GitHub](https://github.com/FluidInference/FluidAudio)
- [FluidAudio manual model loading](https://docs.fluidinference.com/asr/manual-model-loading)
- [WhisperKit/Argmax GitHub](https://github.com/argmaxinc/whisperkit)
- [WhisperKit Core ML models on Hugging Face](https://huggingface.co/argmaxinc/whisperkit-coreml)
- [KeyboardShortcuts GitHub](https://github.com/sindresorhus/KeyboardShortcuts)
- [Apple Developer: SpeechAnalyzer](https://developer.apple.com/documentation/speech/speechanalyzer)
- [Apple Developer: NSMicrophoneUsageDescription](https://developer.apple.com/documentation/bundleresources/information-property-list/nsmicrophoneusagedescription)
- [Apple Developer: AXIsProcessTrustedWithOptions](https://developer.apple.com/documentation/applicationservices/1459186-axisprocesstrustedwithoptions)
