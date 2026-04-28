# VachaVox References

Last reviewed: 2026-04-28

## Purpose

This folder is a compact research base for future VachaVox work. It collects source-backed notes about macOS UX, local speech engines, privacy, permissions, competitors, and dependency/API watch items.

Use these files when planning product changes, UI redesigns, model work, privacy copy, or dependency upgrades. Keep canonical project facts in the existing app docs and use this folder for external context and implementation guidance.

## Project Relevance

VachaVox is a local-first macOS menu bar dictation app. Future work needs quick access to Apple platform guidance, speech-engine docs, privacy/permission boundaries, competitor patterns, and dependency watch items without rereading long reports.

## Key Takeaways

- Start with the focused brief that matches the task, then cross-reference existing repo docs for canonical project facts.
- Prefer primary sources before adding product claims to UI, privacy, model, or roadmap work.
- Treat competitor notes as dated market context, not product requirements.

## Implementation Implications

- When implementing a feature, use these briefs to identify required source checks and acceptance criteria.
- When updating a dependency or model catalog, refresh the relevant brief in the same change.
- When privacy, permissions, or output behavior changes, update both this reference folder and the canonical user-facing docs.

## Reference Briefs

| Brief | Use it for |
| --- | --- |
| [macos-ux-accessibility.md](macos-ux-accessibility.md) | Menu bar behavior, popovers, settings layout, controls, status items, VoiceOver, and keyboard access. |
| [speech-engines-models.md](speech-engines-models.md) | FluidAudio/Parakeet, WhisperKit, SpeechAnalyzer watch notes, model folders, and model-loading implications. |
| [privacy-permissions-output.md](privacy-permissions-output.md) | Local-first privacy language, microphone and Accessibility permissions, and Copy/Paste/Preview output behavior. |
| [competitive-dictation-landscape.md](competitive-dictation-landscape.md) | Competitor patterns from TypeWhisper, Superwhisper, MacWhisper, Wispr Flow, MurmurFlow, and adjacent local-first apps. |
| [dependency-api-watchlist.md](dependency-api-watchlist.md) | External packages and APIs to monitor, why they matter, and update triggers. |

## Existing Repo Docs To Cross-Reference

- [README.md](../README.md) - current app purpose, build commands, model root, version notes, and dependency list.
- [Docs/model-sources.md](../Docs/model-sources.md) - VachaVox model catalog and local model folder names.
- [Docs/model-installation.md](../Docs/model-installation.md) - manual model setup.
- [Docs/privacy.md](../Docs/privacy.md) - current privacy promise.
- [Docs/docs-brand/vachavox-logo-dimensions.md](../Docs/docs-brand/vachavox-logo-dimensions.md) - brand asset dimensions and resource targets.
- [from-chatgpt/deep-research-vachavox-macos-ui-redesign-report.md](../from-chatgpt/deep-research-vachavox-macos-ui-redesign-report.md) - detailed UI redesign research and recommendations.

## Maintenance Notes

- Refresh source links before major UI, privacy, model, or dependency changes.
- Prefer Apple documentation and upstream package docs over blog posts.
- For competitor notes, record the date reviewed because feature claims and pricing can change quickly.
- Keep each brief concise and actionable. Add deeper reports under `from-chatgpt/` or `Docs/` when the output becomes too long for quick reference.

## Sources

Primary source families reviewed:

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [FluidAudio GitHub](https://github.com/FluidInference/FluidAudio)
- [WhisperKit/Argmax GitHub](https://github.com/argmaxinc/whisperkit)
- [KeyboardShortcuts GitHub](https://github.com/sindresorhus/KeyboardShortcuts)
- [TypeWhisper GitHub](https://github.com/TypeWhisper/typewhisper-mac)
- [Superwhisper docs](https://superwhisper.com/docs)
- [MacWhisper Support](https://macwhisper.helpscoutdocs.com/article/52-keeping-transcriptions-private)
- [Wispr Flow docs](https://docs.wisprflow.ai/articles/6274675613-privacy-mode-data-retention)
- [MurmurFlow](https://murmurflow.app/)
