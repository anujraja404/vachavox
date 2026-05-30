#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/version.env"

osascript -e "quit app \"${APP_NAME}\"" >/dev/null 2>&1 || true
"$ROOT_DIR/Scripts/package_app.sh"
open "$ROOT_DIR/build/${APP_NAME}.app"
