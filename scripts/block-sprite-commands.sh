#!/bin/bash
# PreToolUse hook: Block sprite list commands
# Prevents the LINE bot from listing sprites (security/privacy)

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only block listing sprites (privacy concern)
if echo "$COMMAND" | grep -qE 'sprite\s+(list|ls)(\s|$)'; then
    echo '{"decision":"block","reason":"Listing sprites is not allowed for privacy reasons."}'
    exit 0
fi

# Allow the command
exit 0
