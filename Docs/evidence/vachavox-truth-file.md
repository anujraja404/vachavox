# VachaVox evidence handoff

Use this file as the bounded source for public statements about the current evidence set.

## Verified support boundaries

- VachaVox is a macOS 14+ SwiftPM menu-bar app with two local transcription engine families: FluidAudio Parakeet and WhisperKit/Core ML.
- The current source catalog contains exactly 3 Parakeet and 7 WhisperKit configurations, listed in [supported models and permission recovery](supported-models-and-permissions.md).
- The current source validates model folders under `/Users/macbookpro/local_ai_models/voice_models`; voice models are not bundled.
- Dictation requires microphone permission. Accessibility is required only for automatic Paste output; Copy and Preview remain available without it. Paste falls back to Copy when Accessibility trust or the captured target is unavailable.
- File transcription requires a loaded local model, but not microphone or Accessibility permission.

## Measured outcomes

- On one MacBook Pro (`Mac15,6`, Apple M3 Pro, 18 GB unified memory, macOS 26.5.1 build 25F80), a 5.159-second locally generated English AIFF completed with non-empty output on the installed Parakeet TDT 0.6B v3 and Distil-Whisper Large v3 folders.
- The exact startup, preparation, and warm-transcription timings are in [local inference benchmark results](local-inference-benchmarks.md) and its two JSON result files.
- Model-inference CPU and memory are intentionally not claimed because the measurement process cannot isolate Core ML/framework allocation by model. The JSON files contain only startup-process resource values and label their scope.

## Do not claim from this evidence

- Do not generalize latency, memory, accuracy, language coverage, or compatibility to other Macs or unmeasured models.
- Do not describe fresh-engine timing as a true cold boot: OS/Core ML caches were not cleared.
- Do not claim cloud inference, App Store distribution, adoption, user counts, accuracy percentages, or performance improvements.
- Do not publish transcript text from the benchmark fixture; the fixture is temporary and deleted after each run.
