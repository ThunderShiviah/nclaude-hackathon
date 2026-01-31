#!/bin/bash
# PreToolUse hook: Block dangerous sprite commands
# Prevents the LINE bot from creating, listing, or destroying sprites

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Check for blocked sprite commands
if echo "$COMMAND" | grep -qE 'sprite\s+(create|list|ls|destroy|login|logout)'; then
    echo '{"decision":"block","reason":"Sprite management commands (create, list, destroy, login, logout) are not allowed for security reasons."}'
    exit 0
fi

# Allow the command
exit 0
