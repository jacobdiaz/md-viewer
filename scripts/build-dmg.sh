#!/usr/bin/env bash
# Builds the app, then packages it into build/MDViewer-<version>.dmg with an Applications shortcut.
set -euo pipefail

cd "$(dirname "$0")/.."

./scripts/build-app.sh

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)"
DMG="build/MDViewer-${VERSION}.dmg"
STAGING="build/dmg-staging"

rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
cp -R build/MDViewer.app "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create \
    -volname "MD Viewer" \
    -srcfolder "$STAGING" \
    -ov -format UDZO \
    "$DMG" >/dev/null

rm -rf "$STAGING"
echo "Built $DMG"
