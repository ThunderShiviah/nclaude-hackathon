#!/bin/bash
# LINE Claude Bot Script
# Sends messages to persistent Claude daemon

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAEMON_DIR="/tmp/claude-daemon"
INPUT_PIPE="$DAEMON_DIR/input"
OUTPUT_FILE="$DAEMON_DIR/output"
WEBHOOK_URL="${WEBHOOK_BASE_URL:-http://localhost:8080}"

log() {
    echo "[line-claude] $(date '+%Y-%m-%d %H:%M:%S') $1"
}

ensure_daemon() {
    if [ ! -p "$INPUT_PIPE" ]; then
        log "Starting daemon..."
        "$SCRIPT_DIR/claude-daemon.sh" start
        sleep 3
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

# Generate unique request marker
REQUEST_ID="REQ_$(date +%s%N)_$$"

# Record output position AFTER ensuring daemon is ready
sleep 0.5
OUTPUT_POS=$(wc -c < "$OUTPUT_FILE" 2>/dev/null || echo 0)

# Send message with USER_ID so Claude can send messages directly
echo "[USER_ID:$USER_ID] $USER_MESSAGE" > "$INPUT_PIPE"

# Wait for response - only look at NEW output after our position
TIMEOUT=30
ELAPSED=0
RESPONSE=""

while [ $ELAPSED -lt $TIMEOUT ]; do
    sleep 1
    ELAPSED=$((ELAPSED + 1))

    CURRENT_SIZE=$(wc -c < "$OUTPUT_FILE" 2>/dev/null || echo 0)
    if [ "$CURRENT_SIZE" -gt "$OUTPUT_POS" ]; then
        # Only read new content
        NEW_CONTENT=$(tail -c +$((OUTPUT_POS + 1)) "$OUTPUT_FILE")
        
        # Get the LAST assistant message from new content only
        RESPONSE=$(echo "$NEW_CONTENT" | \
            grep '"type":"assistant"' | \
            tail -1 | \
            jq -r '.message.content[0].text // empty' 2>/dev/null || true)
        
        if [ -n "$RESPONSE" ]; then
            # Update position so next request doesn't see this response
            OUTPUT_POS=$CURRENT_SIZE
            break
        fi
    fi
done

if [ -z "$RESPONSE" ]; then
    RESPONSE="Sorry, I couldn't process your message right now."
    log "No response from daemon"
fi

log "Response: $RESPONSE"

# Send to LINE via forwarder (Claude may have already sent via Bash tool)
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
