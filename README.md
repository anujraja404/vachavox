# VachaVox

> Local-first voice dictation for macOS. Hold a key, speak, and your words appear where your cursor is — no cloud, no subscription.

[⬇ Download v0.6.3 for macOS](https://github.com/anujraja-dev/vachavox/releases/download/v0.6.3/VachaVox-v0.6.3-B23.zip) &nbsp;·&nbsp; [Privacy](Docs/privacy.md) &nbsp;·&nbsp; [Changelog](CHANGELOG.md)

---

## What it does

VachaVox is a macOS menu bar app that transcribes your speech using a local Core ML model — nothing leaves your machine. Hold Fn (or a custom hotkey), speak, and VachaVox pastes the transcribed text directly into whatever app you're using. It supports Parakeet and Whisper-family models, works without Accessibility permission in Copy/Preview modes, and also transcribes audio files to Markdown.

## Requirements

- macOS 14.0 or later
- A local Core ML voice model — see [Model Installation](Docs/model-installation.md)

## Quick Start

1. Download the app from the link above, open it, and grant Microphone access when prompted
2. Install a voice model using [Docs/model-installation.md](Docs/model-installation.md)
3. Open Settings > Models, select and load your model
4. Hold Fn to dictate — VachaVox pastes the result into the frontmost app (grant Accessibility for paste mode)

## Building from Source

Requires Swift 5.10+ (ships with Xcode 15.3+).

```bash
swift build                   # compile
swift test                    # run tests
Scripts/package_app.sh        # create build/VachaVox.app
```

Voice models are not bundled — download them separately after building. See [Docs/model-installation.md](Docs/model-installation.md).

## Documentation

- [Model Installation](Docs/model-installation.md)
- [Model Sources](Docs/model-sources.md)
- [Troubleshooting](Docs/troubleshooting.md)
- [Privacy](Docs/privacy.md)

## License

MIT © 2026 Anuj Raja — see [LICENSE](LICENSE).

Built on [FluidAudio](https://github.com/FluidInference/FluidAudio), [WhisperKit](https://github.com/argmaxinc/WhisperKit), and [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts). Inspired by [TypeWhisper](https://github.com/TypeWhisper/typewhisper-mac).
