#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PHOTOS_DIR="$PROJECT_DIR/photos"
HASH_FILE="$SCRIPT_DIR/.photo-hashes"
LOG_FILE="$SCRIPT_DIR/logs/sync.log"

# Logging setup — rotate at 1000 lines
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

rotate_log() {
    if [[ -f "$LOG_FILE" ]] && (( $(wc -l < "$LOG_FILE") > 1000 )); then
        tail -500 "$LOG_FILE" > "$LOG_FILE.tmp"
        mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi
}

rotate_log
log "=== Sync started ==="

# Ensure photos directory exists
mkdir -p "$PHOTOS_DIR"

# Clear photos dir and export from Photos.app album
rm -rf "$PHOTOS_DIR"/* 2>/dev/null || true
log "Exporting photos from 'DavyWade.com' album..."
osascript -e "
tell application \"Photos\"
    set targetAlbum to album \"DavyWade.com\"
    set photoList to every media item of targetAlbum
    export photoList to POSIX file \"$PHOTOS_DIR/\" with using originals
    return (count of photoList) as text
end tell
" 2>&1 | tee -a "$LOG_FILE"

# Remove .mov files (Live Photo videos)
find "$PHOTOS_DIR" -name '*.mov' -delete 2>/dev/null || true

# Compute hash of all files in photos/
compute_hash() {
    if [[ -d "$PHOTOS_DIR" ]] && compgen -G "$PHOTOS_DIR/*" > /dev/null 2>&1; then
        find "$PHOTOS_DIR" -type f -not -name '.DS_Store' -exec shasum {} \; | sort | shasum | awk '{print $1}'
    else
        echo "empty"
    fi
}

CURRENT_HASH=$(compute_hash)
PREVIOUS_HASH=""

if [[ -f "$HASH_FILE" ]]; then
    PREVIOUS_HASH=$(cat "$HASH_FILE")
fi

if [[ "$CURRENT_HASH" == "$PREVIOUS_HASH" ]]; then
    log "No changes detected. Skipping deploy."
    exit 0
fi

log "Changes detected (hash: $CURRENT_HASH). Building and deploying..."

# Save new hash
echo "$CURRENT_HASH" > "$HASH_FILE"

# Convert images and build/deploy
cd "$PROJECT_DIR"
npm run convert-images 2>&1 | tee -a "$LOG_FILE"
./deploy.sh 2>&1 | tee -a "$LOG_FILE"

log "=== Deploy complete ==="

# macOS notification
osascript -e 'display notification "Photos synced and deployed successfully." with title "DavyWade.com"' 2>/dev/null || true
