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

# Extract user info from payload
USER_ID=$(echo "$LINE_PAYLOAD" | jq -r '.events[0].source.userId')
USER_MESSAGE=$(echo "$LINE_PAYLOAD" | jq -r '.events[0].message.text')

# Invoke Claude with direct instructions
timeout 60 claude -p "EXECUTE IMMEDIATELY. Do not read files or invoke skills. Just run the curl command.

You are Moneta. A user sent: \"${USER_MESSAGE}\"

Respond by running this curl command (replace YOUR_RESPONSE with a brief, friendly reply):

curl -s -X POST '${WEBHOOK_URL}/hooks/send-message' -H 'Content-Type: application/json' -d '{\"endpoint\": \"/v2/bot/message/push\", \"body\": {\"to\": \"${USER_ID}\", \"messages\": [{\"type\": \"text\", \"text\": \"YOUR_RESPONSE\"}]}}'

Rules:
- Run the curl command on your FIRST turn
- Keep response under 100 characters
- No special characters except basic punctuation
- No emojis" \
  --allowedTools "Bash" --max-turns 2

exit 0
