#!/usr/bin/env bash
# =============================================================================
#  build-dmg.sh — Build ClipVault and package it as a distributable DMG
#
#  Usage:
#    ./build-dmg.sh              # builds release, creates ClipVault-<VERSION>.dmg
#    ./build-dmg.sh --no-dmg     # builds release only, skips DMG creation
#
#  Requirements:
#    • Xcode command-line tools  (xcodebuild)
#    • create-dmg (optional, prettier DMG)  brew install create-dmg
#      Falls back to hdiutil if create-dmg is not installed.
#
#  Output:
#    dist/ClipVault-<VERSION>.dmg
# =============================================================================

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
APP_NAME="ClipVault"
VERSION="1.0.0"
BUILD_NUMBER="1"
SCHEME="ClipVault"
CONFIGURATION="Release"
PROJECT="ClipVault.xcodeproj"
DIST_DIR="$(pwd)/dist"
ARCHIVE_PATH="$(pwd)/build/${APP_NAME}.xcarchive"
EXPORT_PATH="$(pwd)/build/export"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
SKIP_DMG=false

# ── Argument parsing ───────────────────────────────────────────────────────────
for arg in "$@"; do
  case $arg in
    --no-dmg) SKIP_DMG=true ;;
    *) echo "Unknown argument: $arg"; exit 1 ;;
  esac
done

# ── Helpers ────────────────────────────────────────────────────────────────────
log()  { echo "▶  $*"; }
ok()   { echo "✅ $*"; }
fail() { echo "❌ $*" >&2; exit 1; }

# ── Pre-flight ─────────────────────────────────────────────────────────────────
[[ -f "$PROJECT/project.pbxproj" ]] || fail "Run this script from the clipVault/ directory after running 'xcodegen generate'."
command -v xcodebuild >/dev/null 2>&1 || fail "xcodebuild not found. Install Xcode command-line tools."

mkdir -p "$DIST_DIR" "$(dirname "$ARCHIVE_PATH")" "$EXPORT_PATH"

# ── Step 1: Archive ────────────────────────────────────────────────────────────
log "Archiving ${APP_NAME} ${VERSION} (${CONFIGURATION})…"
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  MARKETING_VERSION="$VERSION" \
  | grep -E "^(Archive|error:|warning:Build|✓|▶)" || true
ok "Archive complete: ${ARCHIVE_PATH}"

# ── Step 2: Export ─────────────────────────────────────────────────────────────
log "Exporting .app bundle…"
EXPORT_OPTIONS_PLIST="$(mktemp -t ExportOptions).plist"
cat > "$EXPORT_OPTIONS_PLIST" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>-</string>
</dict>
</plist>
PLIST

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | grep -E "(error:|Export)" || true

APP_BUNDLE="${EXPORT_PATH}/${APP_NAME}.app"
[[ -d "$APP_BUNDLE" ]] || fail "Export failed — ${APP_BUNDLE} not found."
ok "Export complete: ${APP_BUNDLE}"

# ── Step 3: DMG ────────────────────────────────────────────────────────────────
if [[ "$SKIP_DMG" == "true" ]]; then
  log "Skipping DMG creation (--no-dmg)."
  ok "Done. App bundle at: ${APP_BUNDLE}"
  exit 0
fi

DMG_PATH="${DIST_DIR}/${DMG_NAME}"
log "Creating DMG: ${DMG_PATH}…"

if command -v create-dmg >/dev/null 2>&1; then
  # Pretty DMG with Applications symlink
  create-dmg \
    --overwrite \
    --volname "${APP_NAME} ${VERSION}" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "${APP_NAME}.app" 150 185 \
    --hide-extension "${APP_NAME}.app" \
    --app-drop-link 450 185 \
    "$DMG_PATH" \
    "$EXPORT_PATH" \
    2>&1 | tail -5 || true
else
  # Fallback: plain hdiutil DMG
  log "create-dmg not found — using hdiutil (plain DMG)."
  STAGING="$(mktemp -d /tmp/dmg_staging.XXXXXX)"
  cp -R "$APP_BUNDLE" "$STAGING/"
  ln -s /Applications "$STAGING/Applications"
  hdiutil create \
    -volname "${APP_NAME} ${VERSION}" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    "$DMG_PATH" \
    2>&1 | tail -3
  rm -rf "$STAGING"
fi

[[ -f "$DMG_PATH" ]] || fail "DMG creation failed — ${DMG_PATH} not found."
DMG_SIZE=$(du -sh "$DMG_PATH" | cut -f1)
ok "DMG ready: ${DMG_PATH}  (${DMG_SIZE})"
