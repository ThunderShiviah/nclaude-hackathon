#!/bin/bash
# LINE Message Forwarder
# Receives userId and message, sends to LINE Push API
# Token is in environment, never exposed to callers

if [ -z "$LINE_CHANNEL_ACCESS_TOKEN" ]; then
    echo '{"error": "LINE_CHANNEL_ACCESS_TOKEN not set"}'
    exit 1
fi

# Read JSON payload from LINE_MESSAGE_PAYLOAD env var
PAYLOAD="${LINE_MESSAGE_PAYLOAD:-}"

if [ -z "$PAYLOAD" ]; then
    echo '{"error": "No payload received"}'
    exit 1
fi

# Extract userId and message using jq
USER_ID=$(echo "$PAYLOAD" | jq -r '.userId // empty')
MESSAGE=$(echo "$PAYLOAD" | jq -r '.message // empty')

if [ -z "$USER_ID" ] || [ -z "$MESSAGE" ]; then
    echo '{"error": "Missing userId or message", "received": '"$PAYLOAD"'}'
    exit 1
fi

# Send to LINE Push API
RESPONSE=$(curl -s -X POST https://api.line.me/v2/bot/message/push \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${LINE_CHANNEL_ACCESS_TOKEN}" \
    -d "{
        \"to\": \"${USER_ID}\",
        \"messages\": [
            {
                \"type\": \"text\",
                \"text\": $(echo "$MESSAGE" | jq -Rs .)
            }
        ]
    }")

echo "$RESPONSE"
