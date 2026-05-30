#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/version.env"

CONFIGURATION="${CONFIGURATION:-debug}"
PATCH_ROOT="$ROOT_DIR/src/patch"
DEV_BUILDS_DIR="$ROOT_DIR/src/dev_builds"
STAMP="$(date +%Y%m%d-%H%M%S)"
STAMPED_APP_DIR="$DEV_BUILDS_DIR/${APP_NAME}-dev-test-${STAMP}.app"
CONTENTS_DIR="$STAMPED_APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
INFO_PLIST="$CONTENTS_DIR/Info.plist"
ENTITLEMENTS="$ROOT_DIR/Sources/VachaVox/Resources/VachaVox.entitlements"
SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"

mkdir -p "$DEV_BUILDS_DIR"

APPLIED_PATCHES=()
PATCH_FILES=()

revert_applied_patches() {
  if [[ ${#APPLIED_PATCHES[@]} -eq 0 ]]; then
    return
  fi

  for ((i=${#APPLIED_PATCHES[@]}-1; i>=0; i--)); do
    git apply -R "${APPLIED_PATCHES[$i]}"
  done
}

trap revert_applied_patches EXIT

while IFS= read -r patch_file; do
  PATCH_FILES+=("$patch_file")
done < <(find "$PATCH_ROOT" -type f -name '*.patch' | sort)

if [[ ${#PATCH_FILES[@]} -gt 0 ]]; then
  echo "Applying patches from $PATCH_ROOT ..."
fi

for patch_file in "${PATCH_FILES[@]}"; do
  if git apply --check "$patch_file" >/dev/null 2>&1; then
    git apply "$patch_file"
    APPLIED_PATCHES+=("$patch_file")
    echo "Applied patch: $patch_file"
  elif git apply -R --check "$patch_file" >/dev/null 2>&1; then
    echo "Patch already applied, skipping: $patch_file"
  else
    echo "Cannot cleanly apply patch: $patch_file" >&2
    exit 1
  fi
done

swift build -c "$CONFIGURATION"

rm -rf "$STAMPED_APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$ROOT_DIR/.build/$CONFIGURATION/$PRODUCT_NAME" "$MACOS_DIR/$PRODUCT_NAME"
chmod +x "$MACOS_DIR/$PRODUCT_NAME"

if [[ -d "$ROOT_DIR/Sources/VachaVox/Resources" ]]; then
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

codesign --force --deep --sign "$SIGN_IDENTITY" --entitlements "$ENTITLEMENTS" "$STAMPED_APP_DIR"
echo "Dev test app: $STAMPED_APP_DIR"
