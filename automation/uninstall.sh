#!/bin/bash
set -euo pipefail

PLIST_NAME="com.davywade.photo-sync.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_NAME"
DOMAIN="gui/$(id -u)"
SERVICE="$DOMAIN/com.davywade.photo-sync"

echo "=== DavyWade Photo Sync — Uninstall ==="
echo ""

if launchctl print "$SERVICE" &>/dev/null; then
    echo "Removing launchd job..."
    launchctl bootout "$SERVICE" 2>/dev/null || true
    echo "✓ launchd job removed from launchctl."
else
    echo "No launchd job is currently loaded."
fi

if [[ -f "$PLIST_DEST" ]]; then
    echo "Removing plist from ~/Library/LaunchAgents/..."
    rm "$PLIST_DEST"
    echo "✓ plist file removed."
else
    echo "No plist file found at $PLIST_DEST."
fi

echo ""
echo "Note: The Shortcut \"DavyWade Photo Sync\" in Shortcuts.app was not removed."
echo "      Delete it manually if you no longer need it."
echo ""
echo "=== Done ==="
