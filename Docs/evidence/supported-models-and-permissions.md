# Supported models and permission recovery

This page records the models and recovery behavior supported by the current VachaVox source. It does not claim that every catalog option is installed on this Mac or that every external model folder is compatible.

## Supported local model catalog

VachaVox's `ModelCatalog` currently routes these exact IDs to local FluidAudio/Parakeet or WhisperKit/Core ML engines. The current code scans the fixed root `/Users/macbookpro/local_ai_models/voice_models`; models are not bundled with the app.

| Engine | Model ID and expected folder | Languages shown by the app | Configured RAM guidance |
| --- | --- | --- | --- |
| Parakeet | `parakeet-tdt-0.6b-v3-coreml` → `parakeet/parakeet-tdt-0.6b-v3` | 25 European languages | 16 GB |
| Parakeet | `parakeet-tdt-0.6b-v2-coreml` → `parakeet/parakeet-tdt-0.6b-v2` | English | 16 GB |
| Parakeet | `parakeet-tdt-ctc-110m-coreml` → `parakeet/parakeet-tdt-ctc-110m` | English | 8 GB |
| WhisperKit | `openai_whisper-tiny` → `whisperkit/openai_whisper-tiny` | Multilingual | 8 GB |
| WhisperKit | `openai_whisper-base` → `whisperkit/openai_whisper-base` | Multilingual | 8 GB |
| WhisperKit | `openai_whisper-small` → `whisperkit/openai_whisper-small` | Multilingual | 8 GB |
| WhisperKit | `openai_whisper-medium` → `whisperkit/openai_whisper-medium` | Multilingual | 16 GB |
| WhisperKit | `openai_whisper-large-v3` → `whisperkit/openai_whisper-large-v3` | Multilingual | 24 GB |
| WhisperKit | `openai_whisper-large-v3_turbo` → `whisperkit/openai_whisper-large-v3_turbo` | Multilingual | 16 GB |
| WhisperKit | `distil-whisper_distil-large-v3` → `whisperkit/distil-whisper_distil-large-v3` | English | 16 GB |

The RAM values are static guidance displayed by the app, not measured minimums or performance guarantees. A valid Parakeet folder needs the version-specific Core ML components plus `parakeet_vocab.json`; a valid WhisperKit folder needs `config.json`, `generation_config.json`, and MelSpectrogram, AudioEncoder, and TextDecoder Core ML assets. See [Model Installation](../model-installation.md) for the validation layout.

Both engines use local model folders: Parakeet through FluidAudio and WhisperKit through WhisperKit/Core ML. The app does not send audio or transcript text to a cloud inference API. Model download actions are explicit; VachaVox does not silently download a model when dictation starts.

## Permission and output recovery

| State | What VachaVox does | Recovery |
| --- | --- | --- |
| Microphone denied or revoked | It does not start capture and reports “Microphone access is required.” | Enable VachaVox in System Settings → Privacy & Security → Microphone, then return to VachaVox and refresh/restart if needed. |
| Accessibility denied or revoked while Paste is selected | The transcript is copied instead of pasted; paste is never attempted without Accessibility trust. | Enable VachaVox in System Settings → Privacy & Security → Accessibility, return to Settings → Permissions, and use Re-check. |
| Paste target is unavailable | The transcript is copied instead of attempting a paste into an unavailable app. | Focus the desired target before dictation, then try again; Copy remains available. |
| Copy selected | The transcript goes to the clipboard and does not require Accessibility permission. | Paste manually in the destination app. |
| Preview selected | The editable preview opens and does not require Accessibility permission. | Edit if needed, then choose Copy. |
| No valid selected model | Dictation does not start; the app reports no installed model. | Install a catalog-compatible local folder and load the selected model in Settings. |
| Model is installed but not loaded | Dictation and file transcription ask the user to load it first. | Settings → Models → Load. |

Audio-file transcription does not need microphone or Accessibility permission because the user explicitly selects a file. It still needs a loaded local model.

The recovery tests cover microphone denial and refresh after revocation, missing-model readiness, Paste fallback for missing Accessibility and unavailable targets, plus Copy and Preview without Accessibility. For manual Accessibility recovery details, see [Fix Accessibility](../docs-troubleshooting/fix-accessibility.md).
