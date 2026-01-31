#!/bin/bash
# LINE Echo Bot Script
# This script receives a message from the LINE webhook and echoes it back to the user.

# Arguments passed from webhook:
# $1 = replyToken
# $2 = message text

REPLY_TOKEN="$1"
MESSAGE_TEXT="$2"

# Check if we have the required arguments
if [ -z "$REPLY_TOKEN" ] || [ -z "$MESSAGE_TEXT" ]; then
    echo "Missing required arguments (replyToken or message text)"
    exit 0
fi

# Check if LINE_CHANNEL_ACCESS_TOKEN is set
if [ -z "$LINE_CHANNEL_ACCESS_TOKEN" ]; then
    echo "LINE_CHANNEL_ACCESS_TOKEN environment variable not set"
    exit 1
fi

# Echo the message back to the user
RESPONSE=$(curl -s -X POST https://api.line.me/v2/bot/message/reply \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${LINE_CHANNEL_ACCESS_TOKEN}" \
    -d "{
        \"replyToken\": \"${REPLY_TOKEN}\",
        \"messages\": [
            {
                \"type\": \"text\",
                \"text\": \"Echo: ${MESSAGE_TEXT}\"
            }
        ]
    }")

echo "Reply sent: $RESPONSE"
