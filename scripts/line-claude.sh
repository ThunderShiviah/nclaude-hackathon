#!/bin/bash
# LINE Claude Bot Script
# Receives LINE webhook payload, invokes Claude to respond via Push API

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

# Check if LINE_CHANNEL_ACCESS_TOKEN is set
if [ -z "$LINE_CHANNEL_ACCESS_TOKEN" ]; then
    echo "LINE_CHANNEL_ACCESS_TOKEN environment variable not set"
    exit 1
fi

# Invoke Claude with the full payload
timeout 60 claude -p "You are Moneta, a helpful and friendly LINE bot assistant.

You received this LINE webhook payload:

$LINE_PAYLOAD

Your task:
1. Extract the userId from events[0].source.userId
2. Read the user's message from events[0].message.text
3. Think of a helpful, friendly response to their message
4. Send your response using the LINE Push API

IMPORTANT: You MUST execute the curl command to send your response. The LINE_CHANNEL_ACCESS_TOKEN is: $LINE_CHANNEL_ACCESS_TOKEN

Execute this curl command (replace USER_ID with the actual userId and YOUR_RESPONSE with your message):

curl -s -X POST https://api.line.me/v2/bot/message/push \\
  -H 'Content-Type: application/json' \\
  -H 'Authorization: Bearer $LINE_CHANNEL_ACCESS_TOKEN' \\
  -d '{\"to\": \"USER_ID\", \"messages\": [{\"type\": \"text\", \"text\": \"YOUR_RESPONSE\"}]}'

Remember to properly escape any special characters in your response JSON." \
  --allowedTools "Bash" --max-turns 3

exit 0
