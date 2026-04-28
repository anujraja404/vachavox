**Are you unable to paste into a text box?**

Do the following:

Step 1:
Open VachaVox Settings -> Permissions and click Request Access under Accessibility. If macOS opens System Settings, enable VachaVox under Privacy & Security -> Accessibility.

Step 2:
Return to VachaVox Settings -> Permissions and click Re-check.

Step 3:
Focus the target text box before starting dictation. Paste mode restores that target app after transcription. If the target app is unavailable or Accessibility is not trusted, VachaVox copies the transcript to the clipboard instead.

Step 4, only if VachaVox does not appear in Accessibility:
Run the command below, then manually add VachaVox in Settings -> Accessibility and turn it on.

```
tccutil reset Accessibility com.local.vachavox
```
