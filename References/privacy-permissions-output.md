# Privacy, Permissions, And Output Reference

Last reviewed: 2026-04-28

## Purpose

Keep VachaVox's privacy and permission behavior understandable, honest, and aligned with macOS expectations.

## Project Relevance

VachaVox's product promise is local-first dictation:

- Audio is captured only while dictation is active.
- Transcription runs locally through FluidAudio or WhisperKit/Core ML.
- Transcripts are not stored as app history.
- Output is delivered by Copy, Paste, or Preview.
- Paste mode depends on Accessibility trust.

Related implementation areas include `PermissionsService.swift`, `TextOutputService.swift`, `DictationCoordinator.swift`, `SettingsView.swift`, and `Sources/VachaVox/Resources/Info.plist`.

## Key Takeaways

- `NSMicrophoneUsageDescription` is required when the app accesses the microphone. The string should explain why microphone access is needed in user-facing terms.
- Accessibility trust is checked with `AXIsProcessTrustedWithOptions`; prompting and System Settings routing should be explicit because the user ultimately enables the app in Privacy & Security.
- Accessibility is not equally required for every output path. In VachaVox, it is required for Paste mode, while Copy and Preview can work without simulated paste.
- Local-first privacy copy should distinguish audio, transcript text, local model files, and clipboard behavior. Users care about where data goes and whether history is retained.
- Competitors increasingly separate cloud processing, local processing, and local history retention. VachaVox should keep those concepts separate if future cloud or history features are added.

## Implementation Implications

- Keep the microphone purpose string concise and benefit-led, for example: "VachaVox uses the microphone only while you dictate so it can transcribe speech on this Mac."
- In permissions UI, show "Microphone required to record dictation" and "Accessibility required for Paste mode" as separate rows.
- If output mode is Copy or Preview, do not present missing Accessibility as a blocking error. It can be shown as optional or not needed for the selected mode.
- If future features add cloud models, AI cleanup, sync, analytics, or transcript history, update privacy copy before implementation is considered complete.
- Treat clipboard output as local but visible to other apps through normal macOS clipboard behavior. Avoid implying it is private storage.
- For destructive privacy changes, such as enabling transcript auto-delete or disabling history if history is added later, use explicit confirmation and consequence text.

## Sources

- [Apple Developer: NSMicrophoneUsageDescription](https://developer.apple.com/documentation/bundleresources/information-property-list/nsmicrophoneusagedescription)
- [Apple Developer: AXIsProcessTrustedWithOptions](https://developer.apple.com/documentation/applicationservices/1459186-axisprocesstrustedwithoptions)
- [Apple Support: Allow accessibility apps to access your Mac](https://support.apple.com/guide/mac-help/allow-accessibility-apps-to-access-your-mac-mh43185/mac)
- [MacWhisper Support: Keeping Transcriptions Private](https://macwhisper.helpscoutdocs.com/article/52-keeping-transcriptions-private)
- [Wispr Flow: Privacy Mode and Data Retention](https://docs.wisprflow.ai/articles/6274675613-privacy-mode-data-retention)
- Existing project context: [Docs/privacy.md](../Docs/privacy.md), [README.md](../README.md)
