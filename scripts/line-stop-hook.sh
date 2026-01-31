#!/bin/bash
# Stop Hook: Send Claude's response to LINE when Claude finishes
# This guarantees the user always gets a response

# Read hook input from stdin
INPUT=$(cat)

# Extract session info
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')

# Check if we already sent a message this session (progressive enhancement path)
SENT_FLAG="/tmp/line-sent-${SESSION_ID}"
if [ -f "$SENT_FLAG" ]; then
    rm -f "$SENT_FLAG"
    exit 0  # Already sent via PostToolUse, skip
fi

# Read LINE context (user_id, webhook_url) written by line-claude.sh
LINE_CONTEXT_FILE="/tmp/line-context.json"
if [ ! -f "$LINE_CONTEXT_FILE" ]; then
    echo "Context file not found: $LINE_CONTEXT_FILE" >&2
    exit 0
fi

USER_ID=$(jq -r '.user_id' "$LINE_CONTEXT_FILE")
WEBHOOK_URL=$(jq -r '.webhook_url' "$LINE_CONTEXT_FILE")

if [ -z "$USER_ID" ] || [ "$USER_ID" = "null" ]; then
    echo "No user_id in context" >&2
    exit 0
fi

# Read the transcript to get Claude's last response
if [ ! -f "$TRANSCRIPT_PATH" ]; then
    echo "Transcript not found: $TRANSCRIPT_PATH" >&2
    exit 0
fi

# Extract Claude's last assistant message text from the JSONL transcript
CLAUDE_RESPONSE=$(tac "$TRANSCRIPT_PATH" | while read -r line; do
    TYPE=$(echo "$line" | jq -r '.type // empty')
    if [ "$TYPE" = "assistant" ]; then
        # Extract text content from the message
        echo "$line" | jq -r '.message.content[] | select(.type=="text") | .text' 2>/dev/null | head -1
        break
    fi
done)

if [ -z "$CLAUDE_RESPONSE" ]; then
    echo "No Claude response found in transcript" >&2
    exit 0
fi

# Use jq to safely construct JSON (handles all escaping)
PAYLOAD=$(jq -n \
    --arg endpoint "/v2/bot/message/push" \
    --arg to "$USER_ID" \
    --arg text "$CLAUDE_RESPONSE" \
    '{endpoint: $endpoint, body: {to: $to, messages: [{type: "text", text: $text}]}}')

# Send to LINE via the forwarder
RESPONSE=$(curl -s -X POST "${WEBHOOK_URL}/hooks/send-message" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD")

echo "Sent to LINE: $RESPONSE" >&2

# Clean up context file
rm -f "$LINE_CONTEXT_FILE"

exit 0
