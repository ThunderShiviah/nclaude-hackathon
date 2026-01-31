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
3. Think of a helpful, friendly response to their message
4. Send your response by calling the message forwarder endpoint

To send your response, execute this curl command (replace USER_ID and YOUR_MESSAGE):

curl -s -X POST ${WEBHOOK_URL}/hooks/send-message \\
  -H 'Content-Type: application/json' \\
  -d '{\"userId\": \"USER_ID\", \"message\": \"YOUR_MESSAGE\"}'

The forwarder will handle sending to LINE. You just provide userId and message." \
  --allowedTools "Bash" --max-turns 3

exit 0
