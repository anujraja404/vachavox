# VachaVox useful commands

## Project root

```bash
cd /Users/macbookpro/Developer/vachavox-macos
```

## Frequent development commands

```bash
# Build the SwiftPM app
swift build

# Run the full test suite
swift test

# Build and launch the app locally (smoke check)
Scripts/compile_and_run.sh

# Create packaged app outputs in build/
Scripts/package_app.sh

# Create a current-source dev app in src/dev_builds/
src/scripts/create_dev_test_build.sh

# Preserve dev preferences while rebuilding the dev app
RESET_DEV_SETTINGS=0 src/scripts/create_dev_test_build.sh
```

## Useful git checks

```bash
# See what changed
git status -sb

# View recent commits
git log --oneline -n 10
```

## Check exactly which `.app` is currently running

```bash
pgrep -x VachaVox >/dev/null && APP_PATH="$(ps -p "$(pgrep -x VachaVox | head -n1)" -o comm= | sed 's#/Contents/MacOS/VachaVox$#.app#')" && echo "Running app: $APP_PATH" && /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist" | awk '{print "Marketing version: "$0}' && /usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Contents/Info.plist" | awk '{print "Build number: "$0}' || echo "VachaVox is not running"
```
