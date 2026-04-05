#!/usr/bin/env bash
set -euo pipefail

RELEASE_TAG="${1:?usage: scripts/build-dmg.sh <release-tag>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR/.." rev-parse --show-toplevel)"
BUILD_DIR="$ROOT/.build/release/$RELEASE_TAG"
DIST_DIR="$ROOT/dist"
STAGE_DIR="$BUILD_DIR/dmg-root"
APP_NAME="Vigil.app"
DMG_NAME="Vigil.dmg"
VOL_NAME="Vigil"

rm -rf "$BUILD_DIR" "$DIST_DIR/$APP_NAME" "$DIST_DIR/$DMG_NAME"
mkdir -p "$BUILD_DIR" "$DIST_DIR" "$STAGE_DIR"

(cd "$ROOT" && xcodegen generate)
xcodebuild build \
  -project "$ROOT/Vigil.xcodeproj" \
  -scheme Vigil \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  -destination 'platform=macOS'

APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME"

if [ ! -d "$APP_PATH" ]; then
  printf 'built app not found at %s\n' "$APP_PATH" >&2
  exit 1
fi

ditto "$APP_PATH" "$DIST_DIR/$APP_NAME"
ditto "$DIST_DIR/$APP_NAME" "$STAGE_DIR/$APP_NAME"
ln -s /Applications "$STAGE_DIR/Applications"

hdiutil create \
  -volname "$VOL_NAME" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DIST_DIR/$DMG_NAME"
