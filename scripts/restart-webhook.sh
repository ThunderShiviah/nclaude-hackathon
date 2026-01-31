#!/bin/bash
# Restart webhook server with environment variables
# Run this after git pull to apply changes

# Source environment variables (LINE credentials)
source ~/.bashrc

# Stop existing webhook process
pkill -f webhook || true
sleep 1

# Start webhook server
cd ~/line-bot
nohup webhook -hooks hooks.json -verbose -port 8080 > ~/webhook.log 2>&1 &

echo "Webhook restarted with PID $!"
echo "Logs: tail -f ~/webhook.log"
