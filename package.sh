#!/usr/bin/env bash
# =============================================================================
#  package.sh — Build ClipVault and create all distributables (DMG, ZIP, .app)
#
#  Usage:
#    ./package.sh [version]
#    ./package.sh 1.0.0
# =============================================================================

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
BOLD=$'\e[1m'; DIM=$'\e[2m'; RESET=$'\e[0m'
GREEN=$'\e[32m'; YELLOW=$'\e[33m'; CYAN=$'\e[36m'; RED=$'\e[31m'

info()    { echo "${CYAN}▸${RESET} $*"; }
success() { echo "${GREEN}✔${RESET} $*"; }
warn()    { echo "${YELLOW}⚠${RESET} $*"; }
die()     { echo "${RED}✖${RESET} $*" >&2; exit 1; }

# ── Configuration ─────────────────────────────────────────────────────────────
APP_NAME="ClipVault"
VERSION="${1:-1.0.0}"
BUILD_NUMBER="1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="${SCRIPT_DIR}/dist"
BUILD_DIR="${SCRIPT_DIR}/build"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/export"
DMG_PATH="${DIST_DIR}/${APP_NAME}-${VERSION}.dmg"
ZIP_PATH="${DIST_DIR}/${APP_NAME}-${VERSION}-macos-universal.zip"
PROJECT="${SCRIPT_DIR}/${APP_NAME}.xcodeproj"

echo ""
echo "${BOLD}  ClipVault — Distributable Builder${RESET}"
echo "${DIM}  Version ${VERSION}  ·  macOS 13.0+ (Universal)${RESET}"
echo ""

# ── Step 0: Pre-flight & Project Generation ───────────────────────────────────
command -v xcodebuild >/dev/null 2>&1 || die "xcodebuild not found. Install Xcode."

if command -v xcodegen >/dev/null 2>&1; then
    info "Regenerating Xcode project with xcodegen…"
    (cd "$SCRIPT_DIR" && xcodegen generate >/dev/null)
fi

[[ -f "$PROJECT/project.pbxproj" ]] || die "Project file missing: ${PROJECT}"

# ── Step 1: Run Unit Tests ───────────────────────────────────────────────────
info "Running unit tests…"
TEST_OUT=$(xcodebuild test \
    -project "$PROJECT" \
    -scheme "$APP_NAME" \
    -destination "platform=macOS" \
    2>&1)

if echo "$TEST_OUT" | grep -q "TEST SUCCEEDED"; then
    TEST_COUNT=$(echo "$TEST_OUT" | grep -E "Executed [0-9]+ tests, with 0 failures" | tail -1 | sed -E 's/.*Executed ([0-9]+) tests.*/\1/' || echo "all")
    success "Unit tests passed (${TEST_COUNT} tests, 0 failures)"
else
    echo "$TEST_OUT" | tail -30
    die "Unit tests failed"
fi

# ── Step 2: Archive (Release Build) ──────────────────────────────────────────
mkdir -p "$DIST_DIR" "$BUILD_DIR" "$EXPORT_PATH"
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"

info "Building Release archive (${APP_NAME} ${VERSION})…"
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$APP_NAME" \
    -configuration "Release" \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    MARKETING_VERSION="$VERSION" \
    >/dev/null 2>&1 || die "Archive failed"

success "Archive generated: ${DIM}${ARCHIVE_PATH}${RESET}"

# ── Step 3: Export Standalone App Bundle ──────────────────────────────────────
info "Exporting standalone .app bundle…"
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
    >/dev/null 2>&1 || die "Export failed"
rm -f "$EXPORT_OPTIONS_PLIST"

APP_BUNDLE="${EXPORT_PATH}/${APP_NAME}.app"
[[ -d "$APP_BUNDLE" ]] || die "Exported app bundle not found at ${APP_BUNDLE}"

# Copy directly to dist/ClipVault.app
rm -rf "${DIST_DIR}/${APP_NAME}.app"
cp -R "$APP_BUNDLE" "${DIST_DIR}/${APP_NAME}.app"
success "Application bundle: ${DIM}${DIST_DIR}/${APP_NAME}.app${RESET}"

# ── Step 4: Create Apple Disk Image (DMG) ─────────────────────────────────────
info "Packaging Apple Disk Image (DMG)…"
rm -f "$DMG_PATH"

if command -v create-dmg >/dev/null 2>&1; then
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
        >/dev/null 2>&1 || true
fi

if [[ ! -f "$DMG_PATH" ]]; then
    # Fallback to hdiutil
    STAGING="$(mktemp -d /tmp/dmg_staging.XXXXXX)"
    cp -R "$APP_BUNDLE" "$STAGING/"
    ln -s /Applications "$STAGING/Applications"
    hdiutil create \
        -volname "${APP_NAME} ${VERSION}" \
        -srcfolder "$STAGING" \
        -ov \
        -format UDZO \
        "$DMG_PATH" \
        >/dev/null 2>&1
    rm -rf "$STAGING"
fi

[[ -f "$DMG_PATH" ]] || die "DMG creation failed"
success "DMG package: ${GREEN}${BOLD}${DMG_PATH}${RESET} ($(du -sh "$DMG_PATH" | cut -f1))"

# ── Step 5: Create Distributable ZIP Archive ──────────────────────────────────
info "Packaging ZIP archive…"
rm -f "$ZIP_PATH"
ZIP_STAGING="$(mktemp -d /tmp/zip_staging.XXXXXX)"
ZIP_FOLDER="${ZIP_STAGING}/${APP_NAME}-${VERSION}"
mkdir -p "$ZIP_FOLDER"
cp -R "$APP_BUNDLE" "$ZIP_FOLDER/"
cp "${SCRIPT_DIR}/README.md" "$ZIP_FOLDER/README.md"

(cd "$ZIP_STAGING" && zip -r --quiet "$ZIP_PATH" "${APP_NAME}-${VERSION}/")
rm -rf "$ZIP_STAGING"

[[ -f "$ZIP_PATH" ]] || die "ZIP packaging failed"
success "ZIP package: ${GREEN}${BOLD}${ZIP_PATH}${RESET} ($(du -sh "$ZIP_PATH" | cut -f1))"

# ── Step 6: Create Launch/Test Helper Script ──────────────────────────────────
cat > "${SCRIPT_DIR}/run.sh" <<'LAUNCHER'
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
LAUNCHER
chmod +x "${SCRIPT_DIR}/run.sh"

echo ""
echo "${BOLD}Distributables in ${DIST_DIR}:${RESET}"
echo "  • ${BOLD}DMG:${RESET}  $(du -sh "$DMG_PATH" | cut -f1)   ${DIM}${DMG_PATH}${RESET}"
echo "  • ${BOLD}ZIP:${RESET}  $(du -sh "$ZIP_PATH" | cut -f1)   ${DIM}${ZIP_PATH}${RESET}"
echo "  • ${BOLD}App:${RESET}  $(du -sh "${DIST_DIR}/${APP_NAME}.app" | cut -f1)   ${DIM}${DIST_DIR}/${APP_NAME}.app${RESET}"
echo ""
echo "${GREEN}${BOLD}Ready to test:${RESET} run ${BOLD}clipVault/run.sh${RESET} or ${BOLD}open clipVault/dist/ClipVault.app${RESET}"
echo ""
