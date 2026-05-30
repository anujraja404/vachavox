# Contributing to VachaVox

Thanks for your interest. VachaVox is a personal project that I'm happy to keep open — contributions are welcome as long as they fit the project's philosophy: **do one thing well, stay local-first, stay simple.**

---

## Before you start

- Check [open issues](https://github.com/anujraja404/vachavox/issues) to see if your idea or bug is already tracked.
- For anything beyond a small bug fix, open an issue first to discuss it. This saves both of us time.
- This is not a feature-maximising project. PRs that add complexity without clear user value are unlikely to be merged.

---

## Setting up the dev environment

**Requirements:**
- macOS 14.0+
- Swift 5.10+ — ships with Xcode 15.3 or later (install from the Mac App Store or [developer.apple.com](https://developer.apple.com/xcode/))
- A local Core ML voice model for runtime testing — see [Docs/model-installation.md](Docs/model-installation.md)

**Build and run:**

```bash
git clone https://github.com/anujraja404/vachavox.git
cd vachavox
swift build
```

**Run tests:**

```bash
swift test
```

**Package the app bundle:**

```bash
Scripts/package_app.sh
# Output: build/VachaVox.app
```

**Create a dev test build** (isolated bundle ID, timestamped, does not touch release artifacts):

```bash
src/scripts/create_dev_test_build.sh
# Output: src/dev_builds/VachaVox Dev Latest.app
```

This is a SwiftPM project — there is no Xcode project file. Use any editor; VS Code with the Swift extension works well.

---

## Project structure

| Path | What lives here |
|------|-----------------|
| `Sources/VachaVox/` | All Swift source code |
| `Sources/VachaVox/App/` | App lifecycle, coordinator, model |
| `Sources/VachaVox/UI/` | SwiftUI views and window controllers |
| `Sources/VachaVox/Transcription/` | Engine router and local model engines |
| `Sources/VachaVox/Audio/` | Microphone capture and resampling |
| `Sources/VachaVox/Models/` | Model catalog and download service |
| `Sources/VachaVox/Output/` | Text paste, copy, preview, file transcription |
| `Sources/VachaVox/Settings/` | User preferences (AppSettings) |
| `Tests/VachaVoxTests/` | Unit and integration tests |
| `Scripts/` | Build and packaging scripts |
| `Docs/` | User-facing documentation |

See [Docs/development/module-map.md](Docs/development/module-map.md) for module boundaries and guidance on making changes safely.

---

## Making a change

1. Fork the repo and create a branch: `git checkout -b fix/your-description`
2. Make your change — keep it focused. One fix or feature per PR.
3. Run `swift test` and confirm nothing breaks.
4. If you're touching audio, transcription, or output: manually smoke-test dictation end-to-end.
5. Open a pull request with a clear description of what changed and why.

**Code style:** Follow the patterns already in the file you're editing. No linter is enforced, but keep it consistent with the surrounding code.

**Comments:** Only add a comment if the *why* is non-obvious. The code should speak for itself.

---

## What makes a good contribution

- Bug fixes with a clear reproduction case
- Improvements to existing behaviour that don't add surface area
- Documentation fixes and clarity improvements
- Test coverage for untested behaviour

**Less likely to be merged:**
- New settings, toggles, or modes that existing users don't need
- Cloud/API integrations (this is a local-first app by design)
- UI overhauls without prior discussion

---

## Reporting a bug

Use the [bug report issue template](https://github.com/anujraja404/vachavox/issues/new?template=bug_report.md). Include:
- macOS version
- VachaVox version (shown in Settings > About)
- The model you're using (Parakeet or Whisper)
- Steps to reproduce — if I can't reproduce it, I can't fix it

---

## License

By contributing, you agree that your changes will be licensed under the project's [GNU Affero General Public License v3](LICENSE). If you contribute, you also agree that Anuj Raja (@anujraja404) may offer your contributions under a commercial license to paying customers.
