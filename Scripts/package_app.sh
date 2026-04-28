#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/version.env"

CONFIGURATION="${CONFIGURATION:-release}"
APP_DIR="$ROOT_DIR/build/${APP_NAME}.app"
VERSIONED_APP_DIR="$ROOT_DIR/build/${APP_NAME} V${MARKETING_VERSION} B${BUILD_NUMBER}.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
INFO_PLIST="$CONTENTS_DIR/Info.plist"

if [ -e "$VERSIONED_APP_DIR" ]; then
  echo "Versioned app already exists: $VERSIONED_APP_DIR" >&2
  echo "Bump BUILD_NUMBER in version.env or remove the archived app intentionally." >&2
  exit 1
fi

swift build -c "$CONFIGURATION"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$ROOT_DIR/.build/$CONFIGURATION/$PRODUCT_NAME" "$MACOS_DIR/$PRODUCT_NAME"
chmod +x "$MACOS_DIR/$PRODUCT_NAME"

if [ -d "$ROOT_DIR/Sources/VachaVox/Resources" ]; then
  rsync -a --exclude Info.plist --exclude '*.entitlements' "$ROOT_DIR/Sources/VachaVox/Resources/" "$RESOURCES_DIR/"
fi

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
    <string>${BUNDLE_ID}</string>
    <key>CFBundleIconFile</key>
    <string>VachaVox</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
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

ENTITLEMENTS="$ROOT_DIR/Sources/VachaVox/Resources/VachaVox.entitlements"
SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"
codesign --force --deep --sign "$SIGN_IDENTITY" --entitlements "$ENTITLEMENTS" "$APP_DIR"

ditto "$APP_DIR" "$VERSIONED_APP_DIR"

echo "Current app: $APP_DIR"
echo "Versioned app: $VERSIONED_APP_DIR"
