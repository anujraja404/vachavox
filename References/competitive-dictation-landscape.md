# Competitive Dictation Landscape Reference

Last reviewed: 2026-04-28

## Purpose

Summarize current product patterns in Mac dictation tools so VachaVox can choose focused improvements without copying broad competitor scope.

## Project Relevance

VachaVox is narrower than many competitors: local-first, menu bar driven, SwiftPM native, and centered on system-wide dictation with local Parakeet/WhisperKit models. That narrowness is a strength if the app stays fast, private, and easy to trust.

## Key Takeaways

- TypeWhisper shows the broad open-source direction: many engines, local and cloud options, prompts, profiles, history, dictionary, snippets, and plugins. VachaVox should borrow the idea of clear engine choice, not the whole feature surface.
- Superwhisper emphasizes modes: raw transcription can become emails, notes, messages, or other formatted output. This validates future text cleanup/mode ideas, but it also increases privacy and complexity if cloud models are involved.
- MacWhisper's privacy support page is a useful copy model because it clearly separates local transcription from optional cloud providers, translation, and AI prompts.
- Wispr Flow frames privacy as a user/admin policy with separate server retention and local history settings. That is relevant only if VachaVox later adds accounts, sync, or history.
- MurmurFlow's positioning is close to VachaVox's local-first promise: on-device ASR, no cloud dependency, privacy-first messaging, and text cleanup ambitions.
- The current market is crowded. A credible VachaVox v1 should prioritize trust, native feel, simple setup, and reliable insertion over broad AI writing features.

## Implementation Implications

- Keep "local-only by default" visible in onboarding, Settings, and permissions surfaces.
- Make model setup less intimidating before adding advanced modes. Users must first understand which model is installed, selected, and ready.
- If adding text cleanup, define whether it is local-only. Do not introduce cloud cleanup without a clear privacy boundary and settings copy.
- If adding transcript history, make retention explicit and local-first by design. Consider a session-only last transcript before persistent history.
- Avoid feature sprawl in the menu bar popover. Competitors with many modes still need a one-glance start/stop workflow; VachaVox should keep that as the core.

## Sources

- [TypeWhisper GitHub](https://github.com/TypeWhisper/typewhisper-mac)
- [TypeWhisper website](https://www.typewhisper.com/en/)
- [Superwhisper docs](https://superwhisper.com/docs)
- [Superwhisper modes](https://superwhisper.com/docs/modes)
- [MacWhisper Support: Keeping Transcriptions Private](https://macwhisper.helpscoutdocs.com/article/52-keeping-transcriptions-private)
- [Wispr Flow: Privacy Mode and Data Retention](https://docs.wisprflow.ai/articles/6274675613-privacy-mode-data-retention)
- [MurmurFlow](https://murmurflow.app/)
