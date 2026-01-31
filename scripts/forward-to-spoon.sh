#!/bin/bash
# Forward webhook execution to spoon sprite
# Usage: forward-to-spoon.sh <script-name> [env-var-name]

set -euo pipefail

SCRIPT_NAME="${1:-}"
ENV_VAR_NAME="${2:-}"

# Get the public URL for this sprite (line-echo-bot)
WEBHOOK_BASE_URL="https://line-echo-bot-bl4eg.sprites.app"

if [ -z "$SCRIPT_NAME" ]; then
    echo "Usage: $0 <script-name> [env-var-name]"
    exit 1
fi

# Build the command to run on spoon
CMD="cd ~/line-bot && export WEBHOOK_BASE_URL='$WEBHOOK_BASE_URL' && ./scripts/${SCRIPT_NAME}"

# If env var specified, pass it through
if [ -n "$ENV_VAR_NAME" ] && [ -n "${!ENV_VAR_NAME:-}" ]; then
    ENV_VALUE="${!ENV_VAR_NAME}"
    # Use base64 to safely pass JSON
    ENV_B64=$(echo "$ENV_VALUE" | base64 -w0)
    CMD="cd ~/line-bot && export WEBHOOK_BASE_URL='$WEBHOOK_BASE_URL' && export ${ENV_VAR_NAME}=\$(echo '$ENV_B64' | base64 -d) && ./scripts/${SCRIPT_NAME}"
fi

# Execute on spoon sprite
sprite -s spoon exec bash -c "$CMD"
