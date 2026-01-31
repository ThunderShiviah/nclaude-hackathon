#!/bin/bash
#
# GitHub Sync Hook Script
# Syncs local repository with remote changes and restarts webhook server.
#
# Triggered by: GitHub webhook (push events)
# Note: Signature verification is handled by webhook tool before this script runs
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_PREFIX="[github-sync]"

log() {
    echo "$LOG_PREFIX $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_error() {
    echo "$LOG_PREFIX $(date '+%Y-%m-%d %H:%M:%S') ERROR: $1" >&2
}

# Change to project directory
cd "$PROJECT_DIR"

log "Starting sync from origin/main..."

# Fetch latest changes
if ! git fetch origin main; then
    log_error "Failed to fetch from origin"
    exit 1
fi

log "Fetch complete. Resetting to origin/main..."

# Reset to match remote exactly
if ! git reset --hard origin/main; then
    log_error "Failed to reset to origin/main"
    exit 1
fi

log "Reset complete. Restarting webhook server..."

# Restart webhook server
# Uses pkill to find and restart the webhook process
WEBHOOK_PID=$(pgrep -f "webhook -hooks" || true)

if [[ -n "$WEBHOOK_PID" ]]; then
    log "Stopping webhook server (PID: $WEBHOOK_PID)..."
    kill "$WEBHOOK_PID" 2>/dev/null || true
    sleep 2
fi

# Start webhook server in background
# The server will be started by the process manager (systemd/launchd) or manually
log "Webhook server stopped. It should be restarted by your process manager."
log "If running manually, start with: webhook -hooks hooks.json -verbose"

log "Sync complete!"
