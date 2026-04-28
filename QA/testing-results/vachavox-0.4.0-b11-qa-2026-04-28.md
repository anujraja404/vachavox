# VachaVox 0.4.0 (11) QA Results

Date: 2026-04-28  
Build tested: `build/VachaVox.app`, archived as `build/VachaVox V0.4.0 B11.app`  
Environment: macOS 26.3.1, Mac15,6, arm64e  
Tester: Codex with SwiftPM, AppleScript UI scripting, and Computer Use

## Summary

Result: Partial pass.

The crash fix, settings UI, model readiness display, packaging, and unit tests passed. The live microphone and direct Paste end-to-end path could not be completed without changing macOS privacy permissions: the app reported Microphone as `unknown` and Accessibility as `false`. I did not grant or change OS privacy permissions during QA.

## Automated Verification

- `swift test`: Passed, 23 tests, 0 failures.
- `Scripts/compile_and_run.sh`: Passed.
- Package output:
  - `build/VachaVox.app`
  - `build/VachaVox V0.4.0 B11.app`
- Crash check after UI QA: no new `VachaVox*.ips` or `VachaVox*.crash` files after the B11 run.
- Process check: `VachaVox` remained running after Settings close/reopen checks.

## UI Test Matrix

| Area | Result | Evidence / Notes |
| --- | --- | --- |
| App launch | Pass | `pgrep` showed B11 running from `build/VachaVox.app/Contents/MacOS/VachaVox`. |
| App menu Settings | Pass | macOS `VachaVox > Settings...` opens populated Settings UI, not a blank `EmptyView`. |
| Settings close/reopen | Pass | Closed Settings, reopened it, no crash report appeared and process stayed alive. |
| General tab | Pass | Shows readiness, loaded model, microphone/accessibility states, output mode, shortcut, and app behavior controls. |
| Models tab | Pass | Shows current model, load state, loaded/active badge, `Reload Selected Model`, installed models, and available downloads. |
| Model load button | Pass | `Reload Selected Model` kept Parakeet TDT 0.6B v3 loaded and updated the loaded timestamp. |
| Dictation tab | Pass | Output segmented control switches Copy, Preview, and Paste; Paste shows Accessibility warning when trust is missing. |
| Hotkeys tab | Pass | Hold/toggle segmented control updates behavior copy; setting was restored to Hold to dictate after test. |
| Permissions tab | Pass | Shows separate Microphone and Accessibility rows with Re-check/Open/Request actions and Paste-mode guidance. |
| Privacy tab | Pass | Shows local-first privacy copy, model folder, version `0.4.0 (11)`, selected engine, and diagnostics. |
| Copy Diagnostics | Pass | Copied diagnostics without transcript/audio content. |
| Menu bar status item | Partial | Status item accessibility label reflected readiness: `VachaVox, Paste mode needs Accessibility access`. Popover contents were not exposed as a normal accessibility window through Computer Use. |
| Live microphone dictation | Not run | Blocked by Microphone `unknown`; approving a macOS permission prompt would change OS privacy settings. |
| Direct Paste into target text field | Not run | Blocked by Accessibility `false`; direct paste requires OS Accessibility trust. Unit tests cover target restore and fallback behavior. |
| Copy/Preview without Accessibility | Partial | Settings and unit coverage confirm these modes do not require Accessibility. Live dictation output was not exercised because Microphone permission was not granted during QA. |

## Current Runtime Diagnostics

Copied from VachaVox diagnostics:

```text
VachaVox 0.4.0 (11)
Readiness: Paste mode needs Accessibility access
Selected model: Parakeet TDT 0.6B v3
Model status: Ready
Output mode: Paste
Hotkey mode: Push to talk
Microphone: unknown
Accessibility trusted: false
Models folder: /Users/macbookpro/vachavox/models
```

## Defects / Residual Risk

- Live mic and direct Paste still need a manual QA pass after granting Microphone and Accessibility permissions to `com.local.vachavox`.
- Menu bar popover content was not available as a normal accessibility window in this test session, so popover internals were verified indirectly through status item label, settings state, and unit coverage.
- Multiple archived builds were created during iterative smoke testing (`B8` through `B11`). `B11` is the final build for this pass.

## Recommended Follow-Up QA

1. Grant Microphone permission when macOS prompts.
2. Enable VachaVox in System Settings > Privacy & Security > Accessibility.
3. Reopen Settings > Permissions and click Re-check.
4. Focus a TextEdit or browser text field, start dictation, speak a short phrase, stop dictation, and confirm text appears in the focused target.
5. Repeat the same phrase in Copy and Preview modes to confirm non-Accessibility output paths.
