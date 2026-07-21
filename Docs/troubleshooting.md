# Troubleshooting

## Microphone Access

Open System Settings, then Privacy & Security, then Microphone. Enable VachaVox and restart the app if recording still fails.

If permission is later revoked, VachaVox does not start microphone capture and reports that microphone access is required. Re-enable it in System Settings, then use Settings > Permissions > Re-check.

## Paste Does Not Work

Paste mode needs Accessibility trust and a target app captured before dictation starts. Open VachaVox Settings, then Permissions, then use Request Access or Open Settings for Accessibility. After enabling VachaVox in System Settings, return to Settings > Permissions and click Re-check. Copy and Preview modes work without Accessibility.

If Paste still falls back to Copy, focus the destination text field first, start dictation from the hotkey, and confirm the popover reports the selected model as loaded.

Copy and Preview output modes do not need Accessibility permission. If the captured paste target has closed or cannot be restored, VachaVox copies the transcript instead of attempting a paste.

## First Transcription Is Slow

The first model load can compile local Core ML assets. Settings > Models shows whether the selected model is installed, loading, loaded, or failed. Warm dictations should be faster after the model is loaded and cached.

For machine-specific preparation and transcription measurements, including their limits, see [Local inference benchmark results](evidence/local-inference-benchmarks.md).

## Reset Local Model Cache

FluidAudio stores models under Application Support. Removing that cache forces the next transcription to download the model again.
