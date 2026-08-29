#!/usr/bin/env bash
# Builds, Developer ID-signs, notarizes and staples a PomodoroX release for direct
# distribution, producing a fully notarized .app and notarized .dmg.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

if [[ -f "$ROOT/version.env" ]]; then
  source "$ROOT/version.env"
else
  APP_NAME="PomodoroX"
  BUNDLE_ID="com.pomodorox.app"
  MARKETING_VERSION="1.0.2"
  BUILD_NUMBER="3"
fi

DIST_DIR="${DIST_DIR:-$ROOT/dist}"
SKIP_NOTARIZE="${SKIP_NOTARIZE:-0}"

# 1. Resolve signing identity
if [[ -z "${APP_IDENTITY:-}" ]]; then
  APP_IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null \
    | grep "Developer ID Application:" \
    | head -1 \
    | sed -E 's/.*"(.*)".*/\1/')
fi

if [[ -z "$APP_IDENTITY" ]]; then
  echo "ERROR: No 'Developer ID Application' identity found in keychain." >&2
  exit 1
fi

TEAM_ID=$(sed -E 's/.*\(([A-Z0-9]+)\)$/\1/' <<<"$APP_IDENTITY")

# 1b. Find notary profile
find_notary_profile() {
  local candidates=("${NOTARY_PROFILE:-}" WOS-Notary DiskX-Notary ProcessX-Notary notarytool)
  local p
  for p in "${candidates[@]}"; do
    [[ -z "$p" ]] && continue
    if xcrun notarytool history --keychain-profile "$p" >/dev/null 2>&1; then
      echo "$p"; return 0
    fi
  done
  return 1
}

if [[ "$SKIP_NOTARIZE" != "1" ]]; then
  if ! NOTARY_PROFILE="$(find_notary_profile)"; then
    echo "ERROR: No valid notarytool keychain profile found." >&2
    exit 1
  fi
fi

echo "==> Identity: $APP_IDENTITY"
echo "==> Team ID:  $TEAM_ID"
echo "==> Version:  $MARKETING_VERSION ($BUILD_NUMBER)"
echo "==> Notary:   ${NOTARY_PROFILE:-(skipped)}"
echo

# 2. Build Release .app via XcodeGen and XcodeBuild
echo "==> Generating Xcode project and building Release binary..."
xcodegen generate >/dev/null

xcodebuild -scheme PomodoroX-macOS -configuration Release -destination 'platform=macOS,arch=arm64' build >/dev/null

DERIVED_APP_PATH=$(find /Users/honato/Library/Developer/Xcode/DerivedData -name "PomodoroX.app" -path "*/Build/Products/Release/*" | head -1)

if [[ -z "$DERIVED_APP_PATH" || ! -d "$DERIVED_APP_PATH" ]]; then
  echo "ERROR: Could not locate built PomodoroX.app" >&2
  exit 1
fi

mkdir -p "$DIST_DIR"
APP="$DIST_DIR/${APP_NAME}.app"
rm -rf "$APP"
cp -R "$DERIVED_APP_PATH" "$APP"

# Ensure AppIcon is properly copied to Contents/Resources
mkdir -p "$APP/Contents/Resources"
if [[ -f "$ROOT/Sources/PomodoroXApp/Resources/AppIcon.icns" ]]; then
  cp "$ROOT/Sources/PomodoroXApp/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
  plutil -replace CFBundleIconFile -string "AppIcon" "$APP/Contents/Info.plist" 2>/dev/null || plutil -insert CFBundleIconFile -string "AppIcon" "$APP/Contents/Info.plist"
  plutil -replace CFBundleIconName -string "AppIcon" "$APP/Contents/Info.plist" 2>/dev/null || plutil -insert CFBundleIconName -string "AppIcon" "$APP/Contents/Info.plist"
fi

# Strip extended attributes
xattr -cr "$APP"
find "$APP" -name '._*' -delete

# 3. Code sign embedded frameworks and the main app bundle
ENTITLEMENTS="$ROOT/Entitlements/PomodoroX-DeveloperID.entitlements"

echo "==> Signing embedded frameworks..."
if [[ -d "$APP/Contents/Frameworks" ]]; then
  for fw in "$APP/Contents/Frameworks/"*.framework; do
    if [[ -d "$fw" ]]; then
      codesign --force --timestamp --options runtime --sign "$APP_IDENTITY" "$fw"
    fi
  done
fi

echo "==> Signing main application bundle..."
codesign --force --timestamp --options runtime \
  --entitlements "$ENTITLEMENTS" \
  --sign "$APP_IDENTITY" \
  "$APP"

echo "==> Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$APP"

if [[ "$SKIP_NOTARIZE" == "1" ]]; then
  echo "SKIP_NOTARIZE=1 set. Stopping after signing."
  exit 0
fi

# 4. Notarize the .app bundle
notarize() {
  local target="$1"
  local output status
  set +e
  output=$(xcrun notarytool submit "$target" --keychain-profile "$NOTARY_PROFILE" --wait 2>&1)
  status=$?
  set -e
  echo "$output"

  if [[ $status -ne 0 ]] || grep -qi "status: Invalid" <<<"$output"; then
    echo "ERROR: Notarization failed for $target." >&2
    exit 1
  fi
}

APP_ZIP="$DIST_DIR/${APP_NAME}-${MARKETING_VERSION}.zip"
rm -f "$APP_ZIP"
trap 'rm -f "$APP_ZIP"' EXIT

echo
echo "==> Notarizing app bundle with Apple Notary Service..."
/usr/bin/ditto -c -k --keepParent "$APP" "$APP_ZIP"
notarize "$APP_ZIP"

echo "==> Stapling ticket to .app..."
xcrun stapler staple "$APP"
rm -f "$APP_ZIP"

# 5. Create DMG and Notarize DMG
DMG="$DIST_DIR/${APP_NAME}-${MARKETING_VERSION}.dmg"
DMG_LATEST="$DIST_DIR/${APP_NAME}.dmg"
DMG_STAGING="$DIST_DIR/.dmg-staging"

rm -rf "$DMG_STAGING" "$DMG" "$DMG_LATEST"
mkdir -p "$DMG_STAGING"
cp -R "$APP" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

echo
echo "==> Packaging DMG..."
hdiutil create \
  -volname "$APP_NAME $MARKETING_VERSION" \
  -srcfolder "$DMG_STAGING" \
  -ov -format UDZO \
  "$DMG" >/dev/null
rm -rf "$DMG_STAGING"

echo "==> Signing DMG..."
codesign --force --timestamp --sign "$APP_IDENTITY" "$DMG"

echo "==> Notarizing DMG with Apple Notary Service..."
notarize "$DMG"

echo "==> Stapling ticket to DMG..."
xcrun stapler staple "$DMG"

cp "$DMG" "$DMG_LATEST"

# Copy to website downloads
mkdir -p "$ROOT/website/downloads"
cp "$DMG" "$ROOT/website/downloads/PomodoroX.dmg"
cp "$DMG" "$ROOT/website/downloads/PomodoroX-${MARKETING_VERSION}.dmg"

# 6. Verification
echo
echo "==> Gatekeeper assessment..."
spctl --assess --type execute --verbose=2 "$APP"
spctl --assess --type install --verbose=2 "$DMG"
xcrun stapler validate "$APP"
xcrun stapler validate "$DMG"

echo
echo "🎉 SUCCESS: Notarized & Stapled artifacts ready!"
echo "  App: $APP"
echo "  DMG: $DMG"
echo "  Website DMG: $ROOT/website/downloads/PomodoroX.dmg"
