#!/bin/bash
# Claude Daemon - Long-running Claude process for LINE bot
# Uses stream-json format for multiplexed message handling

set -euo pipefail

DAEMON_DIR="/tmp/claude-daemon"
INPUT_PIPE="$DAEMON_DIR/input"
OUTPUT_PIPE="$DAEMON_DIR/output"
PID_FILE="$DAEMON_DIR/claude.pid"
LOG_FILE="$DAEMON_DIR/daemon.log"

log() {
    echo "[claude-daemon] $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

start_daemon() {
    mkdir -p "$DAEMON_DIR"

    # Check if already running
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            log "Daemon already running (PID $PID)"
            return 0
        fi
    fi

    # Clean up old pipes
    rm -f "$INPUT_PIPE" "$OUTPUT_PIPE"
    mkfifo "$INPUT_PIPE"
    mkfifo "$OUTPUT_PIPE"

    log "Starting Claude daemon..."

    # Start Claude with stream-json I/O
    # --verbose is required for stream-json output format
    claude \
        --input-format stream-json \
        --output-format stream-json \
        --dangerously-skip-permissions \
        --verbose \
        < "$INPUT_PIPE" \
        > "$OUTPUT_PIPE" \
        2>> "$LOG_FILE" &

    CLAUDE_PID=$!
    echo "$CLAUDE_PID" > "$PID_FILE"
    log "Claude daemon started (PID $CLAUDE_PID)"

    # Keep input pipe open to prevent EOF
    exec 3>"$INPUT_PIPE"

    # Send initial system message
    log "Sending system prompt..."
    cat >&3 <<'INIT'
{"type":"user","message":{"role":"user","content":"You are Moneta, a helpful LINE bot assistant. Keep all responses concise (under 200 characters). Be friendly and helpful. Do not use markdown or special formatting."}}
INIT

    log "Daemon ready"
}

stop_daemon() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            log "Stopping daemon (PID $PID)..."
            kill "$PID" 2>/dev/null || true
            wait "$PID" 2>/dev/null || true
        fi
        rm -f "$PID_FILE"
    fi
    rm -f "$INPUT_PIPE" "$OUTPUT_PIPE"
    log "Daemon stopped"
}

status_daemon() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            echo "running:$PID"
            return 0
        fi
    fi
    echo "stopped"
    return 1
}

case "${1:-}" in
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    status)
        status_daemon
        ;;
    restart)
        stop_daemon
        sleep 1
        start_daemon
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        exit 1
        ;;
esac
