#!/bin/bash
# Claude Daemon - Long-running Claude process for LINE bot
# Uses stream-json format via Python adapter

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAEMON_DIR="/tmp/claude-daemon"
INPUT_PIPE="$DAEMON_DIR/input"
OUTPUT_FILE="$DAEMON_DIR/output"
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

    # Clean up
    rm -f "$INPUT_PIPE" "$OUTPUT_FILE" "$PID_FILE"
    mkfifo "$INPUT_PIPE"
    touch "$OUTPUT_FILE"

    log "Starting Claude daemon..."

    # Start Claude with stream-json via Python adapter
    (
        tail -f "$INPUT_PIPE" 2>/dev/null | \
        "$SCRIPT_DIR/to-stream-json.py" | \
        claude -p \
            --input-format stream-json \
            --output-format stream-json \
            --dangerously-skip-permissions \
            --verbose \
            >> "$OUTPUT_FILE" 2>> "$LOG_FILE"
    ) &

    CLAUDE_PID=$!
    echo "$CLAUDE_PID" > "$PID_FILE"
    log "Claude daemon started (PID $CLAUDE_PID)"

    # Send system prompt
    sleep 2
    log "Sending system prompt..."
    cat > "$INPUT_PIPE" << 'PROMPT'
You are Moneta, a helpful LINE bot assistant. Keep text responses under 200 chars.

You can send LINE messages via curl to http://localhost:8080/hooks/send-message:

Text: curl -X POST http://localhost:8080/hooks/send-message -H "Content-Type: application/json" -d '{"endpoint":"/v2/bot/message/push","body":{"to":"USER_ID","messages":[{"type":"text","text":"Hello!"}]}}'

Sticker: curl -X POST http://localhost:8080/hooks/send-message -H "Content-Type: application/json" -d '{"endpoint":"/v2/bot/message/push","body":{"to":"USER_ID","messages":[{"type":"sticker","packageId":"6359","stickerId":"11069850"}]}}'

The USER_ID will be provided with each message. Use Bash tool to send stickers or special messages.
PROMPT

    log "Daemon ready"
}

stop_daemon() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            log "Stopping daemon (PID $PID)..."
            pkill -P "$PID" 2>/dev/null || true
            kill "$PID" 2>/dev/null || true
        fi
        rm -f "$PID_FILE"
    fi
    pkill -f "tail -f $INPUT_PIPE" 2>/dev/null || true
    rm -f "$INPUT_PIPE"
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
