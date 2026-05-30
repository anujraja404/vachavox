# VachaVox Agent Instructions

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
- Dev testing apps and patch-check builds live under `src/dev_builds/` and are ignored from git.
- Development patch overrides: `src/patch/`.
- Current docs: `README.md`, `CHANGELOG.md`, `Docs/`, and `References/`.
- QA snapshots and inventories: `QA/`.
- Build products and app archives: `build/` and `.build/`.

## Build And Test

- Prefer SwiftPM commands; this is not an Xcode project.
- Run `swift test` after code changes.
- Run `Scripts/package_app.sh` for release packaging.
- Run `Scripts/compile_and_run.sh` for a local app launch smoke test.
- Run `src/scripts/create_dev_test_build.sh` for local dev test builds in `src/dev_builds/`; it applies `src/patch/**/*.patch` temporarily, builds a test app, then reverts those patch changes from the working tree.
- When searching, exclude generated/build outputs: `--glob '!ar-working-folder/**' --glob '!build/**' --glob '!.build/**'`.

## Codex Capabilities

- When skills, agents, or plugins matter for the task, inspect the live local capability folders instead of assuming a stale list:
  - `/Users/macbookpro/.codex/agents`
  - `/Users/macbookpro/.codex/skills`
  - `/Users/macbookpro/.agents/skills`
  - `/Users/macbookpro/.codex/plugins/cache`
- Keep the `ar-working-folder/` ignore rule when inspecting capabilities or project files.
- Use the GitHub plugin/skill for GitHub repository work when available, including repo creation, auth, and pushes. Prefer `gh` for the actual git remote operations once authenticated.
- Use a matching skill when the task clearly fits, especially for planning, UI work, docs, release, debugging, accessibility, packaging, or GitHub work.
- Project-relevant skills quick reference:
  - Planning/context: `create-plan`, `codebase-orientation`, `architecture-review`.
  - Swift/macOS: `swift-concurrency-expert`, `swiftui-ui-patterns`, `swiftui-view-refactor`, `swiftui-performance-audit`, `swiftui-liquid-glass`, `macos-spm-app-packaging`, `ios-debugger-agent`.
  - UI/accessibility: `frontend-design`, `frontend-responsive-design-standards`, `accessibility-basic-check`, `agent-browser`, `screenshot`.
  - Testing/debugging: `unit-test-starter`, `integration-test-planner`, `debugging-checklist`, `bug-repro-plan`, `linter-fix-guide`.
  - Docs/release: `doc`, `changelog-generator`, `release-notes-drafter`, `release-audit`, `app-store-changelog`.
  - GitHub/config/deps/security: `github`, `git-basic-helper`, `gh-fix-ci`, `gh-address-comments`, `config-file-explainer`, `dependency-risk-audit`, `dependency-upgrade-plan`, `security-quick-scan`.
- Use subagents only when the active Codex runtime supports them and the user explicitly asks for agents, subagents, delegation, or parallel work.
- For subagent work, give each agent a concrete scope, avoid overlapping file ownership, and integrate results before finalizing.
- Project-relevant agents quick reference:
  - Code discovery: `explorer`, `code-mapper`, `code-archaeologist`.
  - Implementation: `worker`, `implementation_worker`, `swift-expert`, `swiftui-expert`, `ui-engineer`.
  - UI/accessibility: `ui-designer`, `ui-visual-validator`, `accessibility-expert`, `accessibility-specialist`, `accessibility-tester`.
  - Review/testing: `reviewer`, `code-reviewer`, `senior-code-reviewer`, `tester`, `test-automator`, `qa-expert`.
  - Debug/build/docs: `debugger`, `build-engineer`, `docs_researcher`, `documentation-engineer`.
  - Security/release/git: `security-auditor`, `git-ops`, `git-workflow-manager`.

## Packaging And Versions

- `version.env` is the packaging source of truth.
- `APP_NAME` and `PRODUCT_NAME` must remain `VachaVox`.
- Update `MARKETING_VERSION` in `version.env` for user-visible app changes:
  - Minor bump for features, UI behavior changes, model/output/permission behavior changes, packaging changes, and meaningful UX work.
  - Patch bump for bug fixes, docs-visible corrections, copy fixes, and small non-breaking improvements.
- Bump `BUILD_NUMBER` for each packaged or distributable build, even when `MARKETING_VERSION` does not change.
- Keep `README.md` current version, README version notes, and `CHANGELOG.md` aligned with `version.env`.
- `Scripts/package_app.sh` must create both:
  - `build/VachaVox.app` as the current runnable app.
  - `build/VachaVox V${MARKETING_VERSION} B${BUILD_NUMBER}.app` as the archived build.
- Do not overwrite an existing versioned `.app`; bump `BUILD_NUMBER` or remove the archive only when explicitly intended.

## Patch Lifecycle

- Keep active development-only overrides in `src/patch/`.
- After a patch is included in a new release (version bump plus changelog entry), move that patch folder or `.patch` file from `src/patch/` to `src/old/patch/`.
- Preserve patch names when archiving (example: `src/patch/model_path_patch/` -> `src/old/patch/model_path_patch/`).
- Treat `src/patch/` as release-pending only, so `src/scripts/create_dev_test_build.sh` applies only unreleased patches.
- Automatically update `Docs/patch-build-trace.md` whenever a patch is first shipped in a version/build.
- If the shipped change maps to work tracking, add or update one short row in `Docs/ticket-log.md`.

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
- Model storage is `~/vachavox/models`.
- Preserve the paste fallback: Paste mode uses Accessibility permission; Copy and Preview must work without Accessibility trust.
- Preserve menu bar accessory behavior, microphone permission handling, and the concise privacy promise.
- Be conservative with signing and entitlements. Keep `Sources/VachaVox/Resources/VachaVox.entitlements` minimal unless a feature requires a new entitlement.

## Documentation

- Update docs with behavior changes, packaging changes, permissions changes, model path changes, UI changes, or brand asset changes.
- At minimum, update `README.md` and `CHANGELOG.md` for user-visible or release-relevant work.
- For patch-based releases, also update `Docs/patch-build-trace.md` and `Docs/ticket-log.md` in the same change.
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
