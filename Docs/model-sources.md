# Model Sources

VachaVox stores local speech models under `~/vachavox/models`.

## Parakeet / FluidAudio

| Model | Folder | Languages | RAM | Source |
| --- | --- | --- | --- | --- |
| Parakeet TDT 0.6B v3 | `parakeet/parakeet-tdt-0.6b-v3` | 25 European languages | 16 GB | `FluidInference/parakeet-tdt-0.6b-v3-coreml` |
| Parakeet TDT 0.6B v2 | `parakeet/parakeet-tdt-0.6b-v2` | English | 16 GB | `FluidInference/parakeet-tdt-0.6b-v2-coreml` |
| Parakeet TDT-CTC 110M | `parakeet/parakeet-tdt-ctc-110m` | English | 8 GB | `FluidInference/parakeet-tdt-ctc-110m-coreml` |

Parakeet models are loaded with FluidAudio `AsrModels.load(from:version:)`; the app does not silently download on first dictation.

FluidAudio Parakeet models run individual Core ML passes at 16 kHz with a 240,000 sample maximum, which is 15 seconds per model pass. For audio file transcription, VachaVox uses FluidAudio's file URL transcription path so longer files are chunked internally with overlapping windows and disk-backed processing when needed. Users do not need to split long recordings manually, and the final output remains one Markdown file.

## WhisperKit

| Model | Folder | Languages | RAM |
| --- | --- | --- | --- |
| Whisper Tiny | `whisperkit/openai_whisper-tiny` | Multilingual | 8 GB |
| Whisper Base | `whisperkit/openai_whisper-base` | Multilingual | 8 GB |
| Whisper Small | `whisperkit/openai_whisper-small` | Multilingual | 8 GB |
| Whisper Medium | `whisperkit/openai_whisper-medium` | Multilingual | 16 GB |
| Whisper Large v3 | `whisperkit/openai_whisper-large-v3` | Multilingual | 24 GB |
| Whisper Large v3 Turbo | `whisperkit/openai_whisper-large-v3_turbo` | Multilingual | 16 GB |
| Distil-Whisper Large v3 | `whisperkit/distil-whisper_distil-large-v3` | English | 16 GB |

WhisperKit models come from `argmaxinc/whisperkit-coreml` and run locally through Core ML. They are not OpenAI cloud API calls.
