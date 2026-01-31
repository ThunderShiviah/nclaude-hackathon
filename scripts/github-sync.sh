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

# Find current webhook process and capture its environment
WEBHOOK_PID=$(pgrep -f "webhook -hooks" || true)

if [[ -n "$WEBHOOK_PID" ]]; then
    # Capture environment variables from running process
    if [[ -f "/proc/$WEBHOOK_PID/environ" ]]; then
        log "Capturing environment from PID $WEBHOOK_PID..."
        eval "$(cat /proc/$WEBHOOK_PID/environ | tr '\0' '\n' | grep -E '^(LINE_|GITHUB_)' | sed 's/^/export /')" 2>/dev/null || true
    fi

    log "Stopping webhook server (PID: $WEBHOOK_PID)..."
    kill "$WEBHOOK_PID" 2>/dev/null || true
    sleep 2
fi

# Start webhook server in a new session (detached from current process tree)
# Using setsid ensures the new webhook survives even if this script's parent dies
log "Starting webhook server..."
cd "$PROJECT_DIR"
setsid sh -c 'webhook -hooks hooks.json -verbose -port 8080 >> ~/webhook.log 2>&1' &

sleep 2

NEW_PID=$(pgrep -f "webhook -hooks" || true)
if [[ -n "$NEW_PID" ]]; then
    log "Webhook server started (PID: $NEW_PID)"
else
    log_error "Failed to start webhook server"
    exit 1
fi

log "Sync complete!"
