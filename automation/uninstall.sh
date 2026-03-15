#!/bin/bash
set -euo pipefail

PLIST_NAME="com.davywade.photo-sync.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_NAME"

echo "=== DavyWade Photo Sync — Uninstall ==="
echo ""

if [[ -f "$PLIST_DEST" ]]; then
    echo "Unloading launchd job..."
    launchctl unload "$PLIST_DEST" 2>/dev/null || true

    echo "Removing plist from ~/Library/LaunchAgents/..."
    rm "$PLIST_DEST"

    echo "✓ launchd job removed."
else
    echo "No launchd job found at $PLIST_DEST. Nothing to remove."
fi

echo ""
echo "Note: The Shortcut \"DavyWade Photo Sync\" in Shortcuts.app was not removed."
echo "      Delete it manually if you no longer need it."
echo ""
echo "=== Done ==="
