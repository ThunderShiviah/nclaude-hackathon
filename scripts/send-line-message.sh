#!/bin/bash
# LINE API Forwarder
# Forwards any LINE API request, adding authentication
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

# Extract endpoint and body using jq
ENDPOINT=$(echo "$PAYLOAD" | jq -r '.endpoint // empty')
BODY=$(echo "$PAYLOAD" | jq -c '.body // empty')
METHOD=$(echo "$PAYLOAD" | jq -r '.method // "POST"')

if [ -z "$ENDPOINT" ]; then
    echo '{"error": "Missing endpoint", "received": '"$PAYLOAD"'}'
    exit 1
fi

# Build the full URL
BASE_URL="https://api.line.me"
FULL_URL="${BASE_URL}${ENDPOINT}"

# Forward to LINE API with authentication
if [ "$BODY" = "null" ] || [ -z "$BODY" ]; then
    # No body (e.g., GET requests or empty POST)
    RESPONSE=$(curl -s -X "$METHOD" "$FULL_URL" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${LINE_CHANNEL_ACCESS_TOKEN}")
else
    # With body
    RESPONSE=$(curl -s -X "$METHOD" "$FULL_URL" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${LINE_CHANNEL_ACCESS_TOKEN}" \
        -d "$BODY")
fi

echo "$RESPONSE"
