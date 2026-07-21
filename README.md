<p align="center">
  <img src="Docs/docs-brand/vachavox-logo-readme.png" width="280" alt="VachaVox logo" />
</p>

<h1 align="center">VachaVox</h1>

<p align="center"><strong>On-device voice dictation for macOS.</strong><br/>Hold a key, speak, and place the result where you need it.</p>

<p align="center">
  <a href="https://github.com/anujraja/VachaVox/actions/workflows/ci.yml"><img src="https://github.com/anujraja/VachaVox/actions/workflows/ci.yml/badge.svg" alt="CI" /></a>
</p>

<p align="center">
  <a href="https://github.com/anujraja/VachaVox/releases/download/v0.6.3/VachaVox-v0.6.3-B23.zip">⬇ Download v0.6.3 for macOS</a>
  &nbsp;·&nbsp;
  <a href="Docs/evidence/local-inference-benchmarks.md">Local inference evidence</a>
  &nbsp;·&nbsp;
  <a href="Docs/privacy.md">Privacy</a>
  &nbsp;·&nbsp;
  <a href="CHANGELOG.md">Changelog</a>
  &nbsp;·&nbsp;
  <a href="https://anujraja.com/VachaVox">Landing-Page</a>
  &nbsp;·&nbsp;
</p>

---

## Why VachaVox

VachaVox is a focused macOS menu-bar app for local dictation and audio-file transcription.

| Local by design | Practical output modes | Model control |
| --- | --- | --- |
| Speech is transcribed with local Parakeet or WhisperKit/Core ML model folders. | Paste, Copy, and Preview keep dictation useful when a target app or permission is unavailable. | Select, load, validate, and manage supported local models from Settings. |

The app does not use a cloud inference API for transcription. Model downloads are explicit, and the exact supported-model and permission boundaries are documented in [Supported models and permission recovery](Docs/evidence/supported-models-and-permissions.md).

## Screenshots

<table>
  <tr>
    <td align="center"><img src="Docs/Screens/vachavox-listening.png" width="260" alt="Listening state" /><br/><sub>Hold trigger — listening starts</sub></td>
    <td align="center"><img src="Docs/Screens/vachavox-result.png" width="260" alt="Transcript result" /><br/><sub>Transcript auto-pasted where your cursor is (Cmd+V if not)</sub></td>
    <td align="center"><img src="Docs/Screens/vachavox-popover.png" width="380" alt="Menu bar popover" /><br/><sub>Menu bar popover</sub></td>
  </tr>
</table>

## How it works

1. Choose and load a compatible local model in Settings.
2. Hold Fn (or your configured shortcut) and speak.
3. VachaVox transcribes the captured audio locally, then Paste, Copy, or Preview handles the result.

It can also transcribe a user-selected audio file to a Markdown document. File transcription requires a loaded model, but does not require Microphone or Accessibility permission.

## Requirements

- macOS 14.0 or later
- A local Core ML voice model — see [Model Installation](Docs/model-installation.md)

## Quick start

1. [Download the current release](https://github.com/anujraja/VachaVox/releases/download/v0.6.3/VachaVox-v0.6.3-B23.zip) and open VachaVox.
2. Install a compatible local model using [Model Installation](Docs/model-installation.md).
3. In **Settings → Models**, select and load the model.
4. Grant **Microphone** access, then hold Fn to dictate.
5. Choose **Paste**, **Copy**, or **Preview** in Settings. Paste needs Accessibility permission; Copy and Preview do not.

If Paste cannot use Accessibility or the original target app is unavailable, VachaVox copies the transcript instead. [Recovery steps](Docs/evidence/supported-models-and-permissions.md#permission-and-output-recovery) cover every supported fallback.

## Evidence, not estimates

The repository includes machine-specific, rerunnable evidence for local model preparation and transcription. The current public result set records the exact device, OS, source revision, input duration, warm/fresh-engine state, sample counts, and known limits.

- [Read the measured results and method](Docs/evidence/local-inference-benchmarks.md)
- [Inspect the Parakeet JSON result](Docs/evidence/runs/local-inference-20260721T020703Z.json)
- [Inspect the Distil-Whisper JSON result](Docs/evidence/runs/local-inference-20260721T020730Z.json)

These are measurements from one M3 Pro MacBook Pro, not universal latency, memory, accuracy, or compatibility claims.

## Building from Source

Requires Swift 5.10+ (ships with Xcode 15.3+).

```bash
swift build                   # compile
swift test                    # run tests
src/scripts/create_dev_test_build.sh  # create an isolated VachaVox Dev app
```

Voice models are not bundled. For a release-style bundle, run `Scripts/package_app.sh`; it intentionally refuses to overwrite an existing versioned archive. See [Model Installation](Docs/model-installation.md) before runtime testing.

## Status and scope

**Current release:** v0.6.3 (build 23). VachaVox is intentionally a narrow local-first utility: dictation, output delivery, model selection, and audio-file transcription.

If you find a reproducible issue, [open an issue](https://github.com/anujraja/VachaVox/issues) with your macOS version, selected model, output mode, and steps to reproduce.

Future work is deliberately uncommitted; see the [changelog](CHANGELOG.md) for shipped behavior.

## Documentation

| Topic | Where to start |
| --- | --- |
| Install and validate a model | [Model Installation](Docs/model-installation.md) · [Model Sources](Docs/model-sources.md) |
| Local-inference proof | [Benchmark results](Docs/evidence/local-inference-benchmarks.md) · [Evidence truth file](Docs/evidence/vachavox-truth-file.md) |
| Permissions and fallbacks | [Supported models and permission recovery](Docs/evidence/supported-models-and-permissions.md) · [Troubleshooting](Docs/troubleshooting.md) |
| Privacy and contribution | [Privacy](Docs/privacy.md) · [Contributing](CONTRIBUTING.md) |

## License

VachaVox is licensed under the [MIT License + Commons Clause](LICENSE). For commercial use involving a product, SaaS, service, or resale, see the [Commercial License](COMMERCIAL_LICENSE.md).

Built on [FluidAudio](https://github.com/FluidInference/FluidAudio), [WhisperKit](https://github.com/argmaxinc/WhisperKit), and [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts).
