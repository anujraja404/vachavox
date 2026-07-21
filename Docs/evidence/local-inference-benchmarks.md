# Local inference benchmark results

This page publishes a reproducible, machine-specific measurement. It is not a claim about every Mac, every model version, or live dictation end-to-end latency.

## Current measured baseline

| Field | Value |
| --- | --- |
| Device | MacBook Pro (`Mac15,6`), Apple M3 Pro, 18 GB unified memory |
| OS | macOS 26.5.1 (25F80) |
| Build | VachaVox 0.6.3, build 23; source revision `df2c404`; worktree was dirty with this evidence program |
| Input | 5.159 s AIFF generated locally by macOS `say`: “VachaVox measures local transcription on this Mac using a generated English speech sample.” |
| Input retention | Temporary fixture deleted after each run; no transcript text is stored in the evidence |
| Model inference CPU/RAM | Not recorded: the XCTest process cannot attribute Core ML/framework allocations to one model reliably |

The app-startup probe measures a fresh VachaVox process through `applicationDidFinishLaunching`; model loading is excluded. It recorded 0.860 s in the Parakeet run and 0.350 s in the Distil-Whisper run (one sample each). Its process-only peak memory footprint was 139,330,472 bytes and 139,461,544 bytes respectively. These are startup-probe process values, not model-inference memory.

| Installed model | Local directory size | Fresh-engine prepare, n=1 | First file transcription, n=1 | Warm file transcription, n=3 | Result |
| --- | ---: | ---: | ---: | ---: | --- |
| Parakeet TDT 0.6B v3 | 483,262,917 bytes | 0.265 s | 0.195 s | median 0.114 s | Non-empty transcript produced |
| Distil-Whisper Large v3 | 1,514,540,848 bytes | 1.234 s | 1.002 s | median 0.797 s | Non-empty transcript produced |

“Fresh-engine” means a new `TranscriptionEngineRouter` in a new benchmark test process. It does **not** clear macOS/Core ML caches, so it is not a true cold-boot measurement. “Warm” means the same prepared engine repeatedly transcribed the same local input. File-transcription timings include the engine’s file path (including audio decoding/conversion where that engine performs it); they do not include microphone capture, voice-activity trimming, output delivery, or UI display.

The exact, machine-readable evidence is committed with the result set: [Parakeet run](runs/local-inference-20260721T020703Z.json) and [Distil-Whisper run](runs/local-inference-20260721T020730Z.json).

## Rerun

Run one installed catalog model at a time:

```bash
Scripts/measure_local_inference.sh parakeet-tdt-0.6b-v3-coreml
Scripts/measure_local_inference.sh distil-whisper_distil-large-v3
```

The script builds the current SwiftPM source, creates the local `say` fixture, measures startup, runs `LocalInferenceBenchmarkTests`, and writes a timestamped JSON file under `Docs/evidence/runs/`. Use `VACHAVOX_BENCHMARK_WARM_SAMPLES=5` to change the warm sample count. It does not download models, upload audio, retain the fixture, or record transcript text.

## Interpretation limits

- The directory-size and configured-RAM columns are resource trade-off indicators, not measured runtime-memory requirements.
- Results will change with macOS, hardware, thermal state, power mode, model contents, and cache state.
- These results confirm only the two model folders installed on the measured machine. The supported catalog is documented separately in [supported models and permission recovery](supported-models-and-permissions.md).
