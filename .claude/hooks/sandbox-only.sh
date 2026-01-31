#!/bin/bash
#
# Sandbox-Only Hook for Dev Sprite
# Restricts Bash commands to only allow sprite exec to sandbox sprite.
#

COMMAND=$(jq -r '.tool_input.command' < /dev/stdin)

# Allow only sprite exec commands targeting sandbox
if echo "$COMMAND" | grep -qE '^sprite\s+exec\s+.*sandbox'; then
  exit 0
fi

# Deny everything else
echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Only sprite exec sandbox allowed"}}'
