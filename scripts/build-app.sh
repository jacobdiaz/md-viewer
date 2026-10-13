#!/usr/bin/env bash
# Builds a release binary and assembles build/MDViewer.app.
set -euo pipefail

cd "$(dirname "$0")/.."

swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

APP="build/MDViewer.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN_DIR/MDViewer" "$APP/Contents/MacOS/MDViewer"
cp Info.plist "$APP/Contents/Info.plist"
cp Web/* "$APP/Contents/Resources/"
cp Icon/AppIcon.icns "$APP/Contents/Resources/"
printf 'APPL????' > "$APP/Contents/PkgInfo"

codesign --force --sign - "$APP"

# Ask Launch Services to re-read the document types so Finder offers MD Viewer for .md files.
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
"$LSREGISTER" -f "$APP" >/dev/null

echo "Built $APP"
