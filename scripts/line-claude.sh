#!/bin/bash
# LINE Claude Bot Script
# Claude responds naturally; Stop hook sends the response to LINE

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

# Write context for the Stop hook (env vars don't pass through reliably)
LINE_CONTEXT_FILE="/tmp/line-context.json"
jq -n --arg user_id "$USER_ID" --arg webhook_url "${WEBHOOK_BASE_URL:-http://localhost:8080}" \
    '{user_id: $user_id, webhook_url: $webhook_url}' > "$LINE_CONTEXT_FILE"

# Escape message for prompt (use jq to handle special chars)
USER_MESSAGE_SAFE=$(echo "$USER_MESSAGE" | jq -Rs '.' | sed 's/^"//; s/"$//')

# Invoke Claude - just respond naturally, Stop hook handles LINE API
timeout 60 claude -p "You are Moneta, a helpful and friendly LINE bot assistant.

User message: ${USER_MESSAGE_SAFE}

Respond naturally and helpfully. Keep responses concise (under 200 characters when possible).
Do not use special characters that might cause issues.
Just respond with your message - it will be sent to the user automatically."

exit 0
