#!/bin/bash
# LINE Claude Bot Script
# Sends messages to persistent Claude daemon, forwards responses to LINE

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAEMON_DIR="/tmp/claude-daemon"
INPUT_PIPE="$DAEMON_DIR/input"
OUTPUT_PIPE="$DAEMON_DIR/output"
WEBHOOK_URL="${WEBHOOK_BASE_URL:-http://localhost:8080}"

log() {
    echo "[line-claude] $(date '+%Y-%m-%d %H:%M:%S') $1"
}

# Ensure daemon is running
ensure_daemon() {
    if [ ! -p "$INPUT_PIPE" ] || [ ! -p "$OUTPUT_PIPE" ]; then
        log "Starting daemon..."
        "$SCRIPT_DIR/claude-daemon.sh" start
        sleep 2
    fi
}

if [ -z "${LINE_PAYLOAD:-}" ]; then
    echo "No LINE_PAYLOAD received"
    exit 0
fi

# Skip non-message events
EVENT_TYPE=$(echo "$LINE_PAYLOAD" | jq -r '.events[0].type // "unknown"')
if [ "$EVENT_TYPE" != "message" ]; then
    echo "Skipping non-message event: $EVENT_TYPE"
    exit 0
fi

# Extract user info
USER_ID=$(echo "$LINE_PAYLOAD" | jq -r '.events[0].source.userId')
USER_MESSAGE=$(echo "$LINE_PAYLOAD" | jq -r '.events[0].message.text')

log "Message from $USER_ID: $USER_MESSAGE"

ensure_daemon

# Build stream-json message
JSON_MSG=$(jq -n --arg msg "$USER_MESSAGE" \
    '{type:"user",message:{role:"user",content:$msg}}')

# Send to daemon and read response
RESPONSE=""
{
    # Send message to Claude
    echo "$JSON_MSG" > "$INPUT_PIPE"

    # Read response with timeout
    timeout 30 cat "$OUTPUT_PIPE" | while IFS= read -r line; do
        MSG_TYPE=$(echo "$line" | jq -r '.type // empty' 2>/dev/null)
        if [ "$MSG_TYPE" = "assistant" ]; then
            CONTENT=$(echo "$line" | jq -r '.message.content // empty' 2>/dev/null)
            if [ -n "$CONTENT" ]; then
                echo "$CONTENT"
                break
            fi
        fi
    done
} > /tmp/claude-response-$$.txt 2>/dev/null || true

RESPONSE=$(cat /tmp/claude-response-$$.txt 2>/dev/null || echo "")
rm -f /tmp/claude-response-$$.txt

if [ -z "$RESPONSE" ]; then
    RESPONSE="Sorry, I couldn't process your message right now."
    log "No response from daemon"
fi

log "Response: $RESPONSE"

# Send to LINE via forwarder
PAYLOAD=$(jq -n \
    --arg endpoint "/v2/bot/message/push" \
    --arg to "$USER_ID" \
    --arg text "$RESPONSE" \
    '{endpoint: $endpoint, body: {to: $to, messages: [{type: "text", text: $text}]}}')

RESULT=$(curl -s -X POST "${WEBHOOK_URL}/hooks/send-message" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD")

log "LINE API result: $RESULT"
echo "$RESPONSE"
