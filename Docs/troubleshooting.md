# Troubleshooting

## Microphone Access

Open System Settings, then Privacy & Security, then Microphone. Enable VachaVox and restart the app if recording still fails.

## Paste Does Not Work

Paste mode needs Accessibility trust and a target app captured before dictation starts. Open VachaVox Settings, then Permissions, then use Request Access or Open Settings for Accessibility. After enabling VachaVox in System Settings, return to Settings > Permissions and click Re-check. Copy and Preview modes work without Accessibility.

If Paste still falls back to Copy, focus the destination text field first, start dictation from the hotkey, and confirm the popover reports the selected model as loaded.

## First Transcription Is Slow

The first model load can compile local Core ML assets. Settings > Models shows whether the selected model is installed, loading, loaded, or failed. Warm dictations should be faster after the model is loaded and cached.

## Reset Local Model Cache

FluidAudio stores models under Application Support. Removing that cache forces the next transcription to download the model again.
