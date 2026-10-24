#!/usr/bin/env bash
# run.sh — Launch ClipVault locally for testing
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="${SCRIPT_DIR}/dist/ClipVault.app"

if [[ ! -d "$APP" ]]; then
    echo "ClipVault.app not found. Running ./package.sh first…"
    (cd "$SCRIPT_DIR" && ./package.sh)
fi

echo "Launching ClipVault from ${APP}…"
open "$APP"
echo "ClipVault is now running in your menu bar (top tray icon)!"
