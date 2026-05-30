# Speech Engines And Models Reference

Last reviewed: 2026-04-28

## Purpose

Capture external speech-engine and model-management context for VachaVox's local-first dictation stack.

## Project Relevance

VachaVox currently supports:

- FluidAudio-backed Parakeet models through `FluidAudioParakeetTranscriptionEngine.swift`.
- WhisperKit-backed Whisper-family Core ML models through `WhisperKitTranscriptionEngine.swift`.
- A local model catalog in `ModelCatalog.swift`, with storage under `~/vachavox/models`.
- SwiftPM dependencies declared in `Package.swift` and pinned in `Package.resolved`.

The current checked package pins are newer than the declared minimums: FluidAudio `0.14.1`, WhisperKit `0.18.0`, and KeyboardShortcuts `2.4.0`.

## Key Takeaways

- FluidAudio positions Parakeet TDT v3 as a Core ML ASR option for batch transcription with 25 European languages, while older v2 is English-only. VachaVox should keep the UI clear about model language coverage.
- FluidAudio manual loading requires the full model asset set beside the vocabulary file: `Preprocessor.mlmodelc`, `Encoder.mlmodelc`, `Decoder.mlmodelc`, `JointDecision.mlmodelc`, and `parakeet_vocab.json`.
- WhisperKit/Argmax provides on-device Whisper-family speech recognition for Apple Silicon and a CLI path for testing model folders outside the app.
- WhisperKit Core ML models are distributed separately from the package. VachaVox should continue treating model download/install state as explicit user-visible state.
- Apple SpeechAnalyzer is a future watch item for macOS 26+. It is on-device, asynchronous, and system-managed, but it is outside the current macOS 14 target.

## Implementation Implications

- Keep model validation strict. A Parakeet folder should not be considered installed unless all required FluidAudio assets are present.
- Preserve engine-specific model root layout because FluidAudio and WhisperKit use different model folder expectations.
- Keep "downloaded", "selected", "loaded", and "ready" distinct in code, but simplify user-facing labels so users do not need to understand every internal state.
- For future live/streaming transcription, evaluate engine behavior separately. Batch local dictation, streaming partials, endpointing, and text cleanup are different product commitments.
- Do not add SpeechAnalyzer behind the existing app target without a compatibility plan. It would require macOS 26 availability gates and a new engine adapter.

## Sources

- [FluidAudio GitHub](https://github.com/FluidInference/FluidAudio)
- [FluidAudio manual model loading](https://docs.fluidinference.com/asr/manual-model-loading)
- [FluidAudio introduction](https://docs.fluidinference.com/introduction)
- [WhisperKit/Argmax GitHub](https://github.com/argmaxinc/whisperkit)
- [WhisperKit Core ML models on Hugging Face](https://huggingface.co/argmaxinc/whisperkit-coreml)
- [Apple Developer: SpeechAnalyzer](https://developer.apple.com/documentation/speech/speechanalyzer)
- [Apple WWDC25: Bring advanced speech-to-text to your app with SpeechAnalyzer](https://developer.apple.com/videos/play/wwdc2025/277/)
- Existing project context: [Docs/model-sources.md](../Docs/model-sources.md), [Docs/model-installation.md](../Docs/model-installation.md)
