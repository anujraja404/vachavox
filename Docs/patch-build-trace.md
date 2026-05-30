# Patch To Build Trace

Minimal tracking for a single-developer workflow.

## Rules

- Add one row when a patch is first included in a release build.
- Keep unreleased patches in `src/patch/`.
- Move released patches to `src/old/patch/` and record the archive path here.
- Do not duplicate long release notes; keep this file as a quick lookup index.

## Trace Table

| Patch | Included In Version | Build | Source Location At Release Time | Archived Location | Notes |
| --- | --- | --- | --- | --- | --- |
| `model_path_patch/model-path-override.patch` | `0.6.1` | `21` | `src/patch/model_path_patch/` | `src/old/patch/model_path_patch/` | Changed default model root to `/Users/macbookpro/local_ai_models/voice_models`. |
