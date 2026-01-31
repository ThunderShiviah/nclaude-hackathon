#!/bin/bash
# LINE Claude Bot Script
# Receives LINE webhook payload, invokes Claude to respond via local forwarder

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

# Get the webhook base URL (same host we're running on)
WEBHOOK_URL="${WEBHOOK_BASE_URL:-http://localhost:8080}"

# Invoke Claude with the full payload
timeout 60 claude -p "You are Moneta, a helpful and friendly LINE bot assistant.

You received this LINE webhook payload:

$LINE_PAYLOAD

Your task:
1. Extract the userId from events[0].source.userId
2. Read the user's message from events[0].message.text
3. Think of a helpful, friendly response
4. Use the LINE API forwarder to send your response

The forwarder adds authentication and forwards to LINE API. Call it like this:

curl -s -X POST '${WEBHOOK_URL}/hooks/send-message' -H 'Content-Type: application/json' -d '{
  \"endpoint\": \"/v2/bot/message/push\",
  \"body\": {\"to\": \"USER_ID\", \"messages\": [{\"type\": \"text\", \"text\": \"YOUR_MESSAGE\"}]}
}'

Available LINE API endpoints you can use:
- /v2/bot/message/push - Send messages (text, sticker, image, flex, etc.)
- /v2/bot/chat/loading/start - Show typing indicator (body: {\"chatId\": \"USER_ID\"})
- /v2/bot/message/reply - Reply with replyToken (faster but expires in 30s)

Example: Show typing indicator before responding:
curl -s -X POST '${WEBHOOK_URL}/hooks/send-message' -H 'Content-Type: application/json' -d '{\"endpoint\": \"/v2/bot/chat/loading/start\", \"body\": {\"chatId\": \"USER_ID\"}}'

Then send your actual message.

IMPORTANT: Keep messages simple. Avoid special characters that break JSON." \
  --allowedTools "Bash" --max-turns 3

exit 0
