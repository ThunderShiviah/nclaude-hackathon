#!/bin/bash
# LINE Claude Bot Script
# Simple: Claude responds, Stop hook sends to LINE
# Commands run on spoon sprite via sprite exec

set -euo pipefail

WEBHOOK_URL="${WEBHOOK_BASE_URL:-http://localhost:8080}"

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

echo "[line-claude] Message from $USER_ID: $USER_MESSAGE"

# Send typing indicator
curl -s -X POST "${WEBHOOK_URL}/hooks/send-message" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg chatId "$USER_ID" '{endpoint: "/v2/bot/chat/loading/start", body: {chatId: $chatId, loadingSeconds: 60}}')" &

# Write context for Stop hook
cat > /tmp/line-context.json << EOF
{"user_id": "$USER_ID", "webhook_url": "$WEBHOOK_URL"}
EOF

# Escape message safely
USER_MESSAGE_ESCAPED=$(echo "$USER_MESSAGE" | jq -Rs '.')

# Invoke Claude - response sent by Stop hook
timeout 120 claude --continue --model opus -p "You are Moneta, a helpful LINE bot assistant.

User message: $USER_MESSAGE_ESCAPED

IMPORTANT: When you need to run commands, prefix them with: sprite -s spoon exec -- bash -c \"...\"
This runs commands on the spoon compute sprite.

Respond helpfully. Your response will be sent to the user automatically."

exit 0
