#!/bin/bash
# Health check loop - triggers Claude via LINE webhook every 60 seconds

USER_ID="Uc1a46f1bcb85135637f6052187c7c50c"
WEBHOOK_URL="http://localhost:8080"

while true; do
  TIMESTAMP=$(date "+%H:%M:%S")

  # Send through line-webhook so Claude processes it
  curl -s -X POST "${WEBHOOK_URL}/hooks/line-webhook" \
    -H "Content-Type: application/json" \
    -d "{\"events\":[{\"type\":\"message\",\"source\":{\"userId\":\"${USER_ID}\"},\"message\":{\"type\":\"text\",\"text\":\"Heartbeat check at ${TIMESTAMP}. Reply with a short status.\"}}]}" \
    > /dev/null 2>&1

  sleep 600
done
