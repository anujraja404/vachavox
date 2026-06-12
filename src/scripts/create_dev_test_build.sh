#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/version.env"

log() {
  printf '[create_dev_test_build] %s\n' "$*"
}

on_error() {
  local exit_code="$?"
  local line_no="$1"
  local command="$2"

  printf '[create_dev_test_build] ERROR: line %s exited with %s while running: %s\n' \
    "$line_no" "$exit_code" "$command" >&2
}

trap 'on_error "$LINENO" "$BASH_COMMAND"' ERR

CONFIGURATION="${CONFIGURATION:-debug}"
RESET_DEV_SETTINGS="${RESET_DEV_SETTINGS:-1}"
DEV_APP_NAME="${APP_NAME} Dev"
DEV_BUNDLE_ID="${BUNDLE_ID}.dev"
DEV_BUILDS_DIR="$ROOT_DIR/src/dev_builds"
STAMP="$(date +%Y%m%d-%H%M%S)"
STAMPED_APP_DIR="$DEV_BUILDS_DIR/${DEV_APP_NAME} V${MARKETING_VERSION} B${BUILD_NUMBER} ${STAMP}.app"
LATEST_APP_DIR="$DEV_BUILDS_DIR/${DEV_APP_NAME} Latest.app"
CONTENTS_DIR="$STAMPED_APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
INFO_PLIST="$CONTENTS_DIR/Info.plist"
ENTITLEMENTS="$ROOT_DIR/Sources/VachaVox/Resources/VachaVox.entitlements"
SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"

mkdir -p "$DEV_BUILDS_DIR"

log "Root: $ROOT_DIR"
log "Configuration: $CONFIGURATION"
log "Dev bundle id: $DEV_BUNDLE_ID"
log "Timestamped app: $STAMPED_APP_DIR"
log "Latest app: $LATEST_APP_DIR"

if [[ "$RESET_DEV_SETTINGS" != "0" ]]; then
  log "Resetting dev preferences for $DEV_BUNDLE_ID"
  defaults delete "$DEV_BUNDLE_ID" >/dev/null 2>&1 || true
else
  log "Preserving dev preferences because RESET_DEV_SETTINGS=0"
fi

log "Quitting existing dev app if running..."
osascript -e "tell application id \"$DEV_BUNDLE_ID\" to quit" >/dev/null 2>&1 || true

log "Building SwiftPM target..."
swift build -c "$CONFIGURATION" --product "$PRODUCT_NAME"
BUILD_BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
EXECUTABLE_PATH="$BUILD_BIN_DIR/$PRODUCT_NAME"

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
  printf '[create_dev_test_build] ERROR: executable not found at %s\n' "$EXECUTABLE_PATH" >&2
  exit 1
fi

log "Assembling app bundle..."
rm -rf "$STAMPED_APP_DIR" "$LATEST_APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$EXECUTABLE_PATH" "$MACOS_DIR/$PRODUCT_NAME"
chmod +x "$MACOS_DIR/$PRODUCT_NAME"

if [[ -d "$ROOT_DIR/Sources/VachaVox/Resources" ]]; then
  rsync -a --exclude Info.plist --exclude '*.entitlements' "$ROOT_DIR/Sources/VachaVox/Resources/" "$RESOURCES_DIR/"
fi

log "Writing Info.plist..."
cat > "$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${PRODUCT_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${DEV_BUNDLE_ID}</string>
    <key>CFBundleIconFile</key>
    <string>VachaVox</string>
    <key>CFBundleDisplayName</key>
    <string>${DEV_APP_NAME}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${DEV_APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${MARKETING_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSMicrophoneUsageDescription</key>
    <string>VachaVox records your microphone only while dictation is active so it can transcribe speech locally.</string>
</dict>
</plist>
PLIST

log "Signing app bundle..."
codesign --force --deep --sign "$SIGN_IDENTITY" --entitlements "$ENTITLEMENTS" "$STAMPED_APP_DIR"

log "Refreshing latest dev app copy..."
ditto "$STAMPED_APP_DIR" "$LATEST_APP_DIR"

log "Timestamped dev app: $STAMPED_APP_DIR"
log "Latest dev app: $LATEST_APP_DIR"
