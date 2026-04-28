# VachaVox 0.4.1 (13) Build Verification

Date: 2026-04-28  
Build tested: `build/VachaVox.app`, archived as `build/VachaVox V0.4.1 B13.app`  
Bundle identifier: `com.local.vachavox`

## Summary

This pass corrects the release version from `0.4.0` to `0.4.1` for the Settings crash fix, explicit model load readiness, Paste target restore behavior, and improved Permissions actions.

## Verification

| Check | Result | Notes |
| --- | --- | --- |
| `swift test` | Pass | 23 tests passed, 0 failures. |
| `Scripts/compile_and_run.sh` | Pass | Built release app, signed it ad hoc, created the versioned archive, and launched the app. |
| Bundle version | Pass | `CFBundleShortVersionString` is `0.4.1`; `CFBundleVersion` is `13`. |
| Archived app | Pass | `build/VachaVox V0.4.1 B13.app` exists. |
| Current app launch | Pass | `VachaVox` is running from `build/VachaVox.app/Contents/MacOS/VachaVox`. |
| Code signature | Pass | Bundle is ad-hoc signed with identifier `com.local.vachavox`. |

## Notes

- `version.env`, `README.md`, `CHANGELOG.md`, bundled `Info.plist` fallback metadata, Settings diagnostics fallback metadata, and brand asset packaging docs now align on `0.4.1 (13)`.
- Live microphone dictation and direct Paste into a target text field were not re-tested in this pass because those require changing macOS privacy permissions. The existing B11 QA report documents that limitation in detail.
