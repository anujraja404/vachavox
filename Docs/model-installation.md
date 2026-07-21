# Model Installation

The current VachaVox source scans this model root:

```text
/Users/macbookpro/local_ai_models/voice_models
```

## Folder Layout

```text
~/vachavox/models
├── parakeet
│   ├── parakeet-tdt-0.6b-v3
│   ├── parakeet-tdt-0.6b-v2
│   └── parakeet-tdt-ctc-110m
└── whisperkit
    ├── openai_whisper-tiny
    ├── openai_whisper-base
    ├── openai_whisper-small
    ├── openai_whisper-medium
    ├── openai_whisper-large-v3
    ├── openai_whisper-large-v3_turbo
    └── distil-whisper_distil-large-v3
```

## Parakeet Requirements

Parakeet 0.6B folders require:

```text
Preprocessor.mlmodelc
Encoder.mlmodelc
Decoder.mlmodelc
JointDecision.mlmodelc or JointDecisionv3.mlmodelc
parakeet_vocab.json
```

The v3 model uses `JointDecisionv3.mlmodelc`. The v2 model uses `JointDecision.mlmodelc`.

The 110M model requires:

```text
Preprocessor.mlmodelc
Decoder.mlmodelc
JointDecision.mlmodelc
parakeet_vocab.json
```

Manual download example:

```bash
mkdir -p /Users/macbookpro/local_ai_models/voice_models/parakeet
git lfs install
git clone https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml /Users/macbookpro/local_ai_models/voice_models/parakeet/parakeet-tdt-0.6b-v3
```

The folder names intentionally match FluidAudio's local cache layout. If you have an older `*-coreml` folder under `/Users/macbookpro/local_ai_models/voice_models/parakeet`, move or redownload it into the matching folder name without the `-coreml` suffix.

## WhisperKit Requirements

WhisperKit folders require:

```text
config.json
generation_config.json
MelSpectrogram.mlmodelc or MelSpectrogram.mlpackage
AudioEncoder.mlmodelc or AudioEncoder.mlpackage
TextDecoder.mlmodelc or TextDecoder.mlpackage
```

Use Settings > Models > Download for the built-in WhisperKit catalog, or copy prepared Core ML folders into `/Users/macbookpro/local_ai_models/voice_models/whisperkit/<folder>`.

For the exact source-supported model IDs, configured resource guidance, and recovery boundaries, see [Supported models and permission recovery](evidence/supported-models-and-permissions.md).
