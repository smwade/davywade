#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_NAME="com.davywade.photo-sync.plist"
PLIST_SRC="$SCRIPT_DIR/$PLIST_NAME"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_NAME"
DOMAIN="gui/$(id -u)"
SERVICE="$DOMAIN/com.davywade.photo-sync"

echo "=== DavyWade Photo Sync — Install ==="
echo ""

# Remove existing job if loaded
if launchctl print "$SERVICE" &>/dev/null; then
    echo "Removing existing job..."
    launchctl bootout "$SERVICE" 2>/dev/null || true
fi

echo "Copying plist to ~/Library/LaunchAgents/..."
cp "$PLIST_SRC" "$PLIST_DEST"

echo "Loading launchd job..."
launchctl bootstrap "$DOMAIN" "$PLIST_DEST"

# Verify
if launchctl print "$SERVICE" &>/dev/null; then
    echo "✓ launchd job is running."
else
    echo "✗ launchd job failed to load. Check: launchctl print $SERVICE"
    exit 1
fi

echo ""
echo "=== Create the macOS Shortcut ==="
echo ""
echo "Open Shortcuts.app and create a new shortcut called:"
echo "  \"DavyWade Photo Sync\""
echo ""
echo "Add these actions in order:"
echo ""
echo "  1. Run Shell Script"
echo "     Input: (none)"
echo "     Shell: /bin/bash"
echo "     Script:"
echo "       rm -rf \"$SCRIPT_DIR/../photos/\"*"
echo ""
echo "  2. Find Photos"
echo "     Where: Album is \"DavyWade.com\""
echo ""
echo "  3. Repeat with Each (photo in Photos)"
echo "     → Save File"
echo "       Save: Repeat Item"
echo "       To: $SCRIPT_DIR/../photos/"
echo "       Ask Where to Save: OFF"
echo "       Overwrite If File Exists: ON"
echo ""
echo "  4. Run Shell Script"
echo "     Input: (none)"
echo "     Shell: /bin/bash"
echo "     Script:"
echo "       export PATH=\"/opt/homebrew/bin:/usr/local/bin:\$PATH\""
echo "       \"$SCRIPT_DIR/sync-and-deploy.sh\""
echo ""
echo "=== Done ==="
echo "The job will run hourly. To trigger manually: npm run sync"
