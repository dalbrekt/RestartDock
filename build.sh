#!/bin/bash
# Builds RestartDock.app and installs it to /Applications.
# Usage: ./build.sh            (build + install + launch)
#        ./build.sh --no-install
set -euo pipefail
cd "$(dirname "$0")"

APP=RestartDock
BUILD=build
BUNDLE="$BUILD/$APP.app"

rm -rf "$BUILD"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"

swiftc -O -swift-version 5 \
  -target arm64-apple-macosx13.0 \
  -framework AppKit -framework ServiceManagement \
  -o "$BUNDLE/Contents/MacOS/$APP" \
  Sources/main.swift

cp Info.plist "$BUNDLE/Contents/Info.plist"
codesign --force --sign - "$BUNDLE"

echo "Built $BUNDLE"

if [[ "${1:-}" == "--no-install" ]]; then exit 0; fi

pkill -x "$APP" 2>/dev/null || true
rm -rf "/Applications/$APP.app"
cp -R "$BUNDLE" "/Applications/$APP.app"
open "/Applications/$APP.app"
echo "Installed and launched /Applications/$APP.app"
