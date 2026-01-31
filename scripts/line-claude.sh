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

# Write context for Stop hook
cat > /tmp/line-context.json << EOF
{"user_id": "$USER_ID", "webhook_url": "$WEBHOOK_URL"}
EOF

# Escape message safely
USER_MESSAGE_ESCAPED=$(echo "$USER_MESSAGE" | jq -Rs '.')

# Invoke Claude - response sent by Stop hook
timeout 120 claude --continue --model opus -p "You are Moneta, a helpful LINE bot assistant.

User ID: $USER_ID
User message: $USER_MESSAGE_ESCAPED

FIRST: Send a brief acknowledgment message (e.g. 'On it!', 'Let me check...', 'Thinking about that...') using this curl command:
curl -s -X POST '${WEBHOOK_URL}/hooks/send-message' -H 'Content-Type: application/json' -d '{\"endpoint\": \"/v2/bot/message/push\", \"body\": {\"to\": \"$USER_ID\", \"messages\": [{\"type\": \"text\", \"text\": \"YOUR_ACK_HERE\"}]}}'

THEN: Process the request and respond. Your final response will be sent automatically.

For any compute tasks, use: sprite -s spoon exec -- bash -c '...'"

exit 0
