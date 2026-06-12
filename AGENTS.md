# VachaVox Agent Instructions

## Purpose

These instructions keep coding agents aligned with VachaVox as a local-first
SwiftPM macOS dictation app. Follow higher-priority system, developer, and user
instructions first; use this file for repository-specific constraints,
commands, and completion criteria.

## Non-Negotiable Ignore Rule

- Do not read, search, reference, copy from, or otherwise use `ar-working-folder/`.
- Treat `/Users/macbookpro/Developer/vachavox-macos/ar-working-folder` as off-limits.
- Exclude it from searches with `--glob '!ar-working-folder/**'`.

## Project Map

- This is a SwiftPM native macOS 14 menu bar dictation app.
- Package, product, target, module, and executable name: `VachaVox`.
- App bundle name: `VachaVox.app`.
- Bundle identifier: `com.local.vachavox`.
- This workspace is expected to be initialized as a Git repository with `main` as the default branch and `origin` pointing at the private GitHub repo named `vachavox`.
- Main source: `Sources/VachaVox/`.
- Tests: `Tests/VachaVoxTests/`.
- Scripts: `Scripts/`.
- Dev scripts: `src/scripts/`.
- Dev testing builds live under `src/dev_builds/` and are ignored from git.
- Current docs: `README.md`, `CHANGELOG.md`, `Docs/`, and `References/`.
- QA snapshots and inventories: `QA/`.
- Build products and app archives: `build/` and `.build/`.

## Working Style And Done Criteria

- Read the affected source, docs, and scripts before changing behavior.
- Keep edits scoped to the task and preserve existing app architecture unless
  the user explicitly asks for a redesign or rewrite.
- Use `rg` or `rg --files` for targeted search. Expand the search only when a
  required file, owner, date, command, or behavior is still missing.
- For longer or tool-heavy work, start with a short visible update, then keep
  plans tied to concrete files, commands, and validation.
- Done means the requested behavior is implemented or the blocker is named,
  relevant docs/changelog entries are updated, and the most relevant validation
  has run or is explicitly reported as skipped with a reason.

## Build And Test

- Prefer SwiftPM commands; this is not an Xcode project.
- Run `swift test` after code changes.
- Run `Scripts/package_app.sh` only when an explicit release build is requested.
- Run `Scripts/compile_and_run.sh` for a local app launch smoke test.
- Run `src/scripts/create_dev_test_build.sh` to create a timestamped current-source dev test build and refresh `src/dev_builds/VachaVox Dev Latest.app` after code changes.
- When searching, exclude generated/build outputs: `--glob '!ar-working-folder/**' --glob '!build/**' --glob '!.build/**'`.

## Codex Capabilities

- When skills, agents, or plugins matter, inspect the live local capability
  folders instead of relying on a static list:
  - `/Users/macbookpro/.codex/agents`
  - `/Users/macbookpro/.codex/skills`
  - `/Users/macbookpro/.agents/skills`
  - `/Users/macbookpro/.codex/plugins/cache`
- Keep the `ar-working-folder/` ignore rule when inspecting capabilities or project files.
- Use matching skills for clear task categories: Swift/macOS work, packaging,
  UI/accessibility, debugging, docs/release, GitHub, config, dependency, and
  security tasks.
- Use the GitHub plugin/skill for GitHub repository work when available,
  including repo creation, auth, and pushes. Prefer `gh` for git remote
  operations once authenticated.
- Use subagents only when the active Codex runtime supports them and the user explicitly asks for agents, subagents, delegation, or parallel work.
- For subagent work, give each agent a concrete scope, avoid overlapping file
  ownership, and integrate results before finalizing.

## Unreleased Workflow

- Default daily workflow is unreleased-first:
  - Every bug fix, feature, or code change must be recorded in `CHANGELOG.md` under `## Unreleased`.
  - Do not bump `MARKETING_VERSION` or `BUILD_NUMBER` during normal ongoing development.
  - After code changes, regenerate the dev test build with `src/scripts/create_dev_test_build.sh` and validate against that latest dev build.
  - Treat `src/dev_builds/VachaVox Dev Latest.app` as the test target until a release is explicitly requested.

## Release Workflow (Explicit Trigger Only)

- Only run release versioning and packaging when the developer explicitly requests creating a new release build/version.
- On explicit release requests:
  - `version.env` remains the source of truth for release versioning.
  - Update `MARKETING_VERSION` and `BUILD_NUMBER` for the release.
  - Compile release notes from `CHANGELOG.md` `## Unreleased`, then ship and move those entries into the new released version section.
  - Keep `README.md` version notes and `CHANGELOG.md` aligned with `version.env`.
  - Run `Scripts/package_app.sh` to produce:
    - `build/VachaVox.app` as the current runnable app.
    - `build/VachaVox V${MARKETING_VERSION} B${BUILD_NUMBER}.app` as the archived build.
  - Do not overwrite an existing versioned `.app`; bump `BUILD_NUMBER` or remove the archive only when explicitly intended.

## Current UI Direction

- Keep VachaVox native, quiet, local-first, and utility-focused.
- Treat the menu bar popover as the primary operational surface.
- Keep Settings as native grouped forms, not dashboard-style UI.
- Use shared status vocabulary across settings, popover, overlay, preview, menu bar icon, and alerts: `Ready to dictate`, `Paused`, `Listening`, `Transcribing locally`, `No model installed`, `Microphone access required`, `Paste mode needs Accessibility access`, `Error`.
- Accessibility permission is blocking only for Paste output mode. Copy and Preview must remain usable without Accessibility trust.
- Prefer one obvious primary action per state or row; move secondary actions into menus when that reduces choice overload.
- Status must not rely on color alone. Pair semantic colors with text, symbols, labels, or accessibility values.

## Product Constraints

- Keep VachaVox local-first. Audio and transcripts must not be uploaded by the app.
- Transcription uses local FluidAudio Parakeet and WhisperKit/Core ML model folders.
- Active model storage is `/Users/macbookpro/local_ai_models/voice_models`.
- Preserve the paste fallback: Paste mode uses Accessibility permission; Copy and Preview must work without Accessibility trust.
- Preserve menu bar accessory behavior, microphone permission handling, and the concise privacy promise.
- Be conservative with signing and entitlements. Keep `Sources/VachaVox/Resources/VachaVox.entitlements` minimal unless a feature requires a new entitlement.

## Documentation

- Update docs with behavior changes, packaging changes, permissions changes, model path changes, UI changes, or brand asset changes.
- At minimum, update `README.md` and `CHANGELOG.md` for user-visible or release-relevant work.
- Keep `CHANGELOG.md` `## Unreleased` current during ongoing development; do not wait for release day to capture change notes.
- Use `Docs/development/module-map.md` before splitting work across multiple agents/developers to avoid module overlap conflicts.
- `Docs/patch-workflow-reference.md` is optional legacy guidance only, not the active default process.
- Keep current-state docs under `Docs/` and engineering context under `References/` aligned with the code.
- Historical changelog entries may describe old behavior, but active setup and command docs must use VachaVox names and paths.

## Verification And QA

- For code changes, run `swift test` unless impossible.
- For packaging or release work, run `Scripts/package_app.sh`.
- For local app smoke checks, run `Scripts/compile_and_run.sh`.
- For UI work, verify affected keyboard navigation, VoiceOver labels, non-color status cues, light/dark appearance, and relevant states.
- For permission/output work, verify Accessibility denied with Paste, Accessibility denied with Copy, microphone denied, and normal ready states.
- For model work, verify no model installed, one ready model, download in progress, selected model deleted, and failed/unavailable model states when practical.
- For git setup work, commit on `main`, create or update the private GitHub repo named `vachavox`, and push to `origin`.
- If the best validation cannot run, explain the constraint and name the next
  best check.
