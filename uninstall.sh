#!/bin/bash
# Removes RestartDock: quits it, unregisters the login item, deletes the app and its preferences.
set -uo pipefail

APP=RestartDock
BUNDLE_ID=ai.digital-mirror.RestartDock
INSTALLED="/Applications/$APP.app"

pkill -x "$APP" 2>/dev/null && echo "Quit running $APP"

if [[ -x "$INSTALLED/Contents/MacOS/$APP" ]]; then
  "$INSTALLED/Contents/MacOS/$APP" --unregister || echo "Warning: could not unregister login item (remove it in System Settings > General > Login Items)"
fi

if [[ -d "$INSTALLED" ]]; then
  rm -rf "$INSTALLED" && echo "Removed $INSTALLED"
else
  echo "$INSTALLED not found"
fi

defaults delete "$BUNDLE_ID" 2>/dev/null && echo "Removed preferences"

echo "Uninstall complete"
