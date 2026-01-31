---
name: test-webhook
description: Test the LINE bot webhook end-to-end using curl commands
---

# Test Webhook

Test the LINE bot webhook end-to-end using the forwarder architecture.

## Architecture

```
LINE → line-webhook → line-claude.sh → Claude → send-message → send-line-message.sh → LINE API
```

## Test 1: Forwarder Endpoint (send-message)

Test the forwarder independently:

```bash
curl -s -X POST https://line-echo-bot-bl4eg.sprites.app/hooks/send-message \
  -H "Content-Type: application/json" \
  -d '{"endpoint": "/v2/bot/message/push", "body": {"to": "Utest123", "messages": [{"type": "text", "text": "Test from forwarder"}]}}'
```

**Expected:** JSON response (error for fake userId is OK - we're testing the forwarder works)

Check logs:
```bash
sprite exec bash -c 'tail -20 ~/webhook.log'
```

## Test 2: Full Flow (line-webhook)

```bash
curl -s -X POST https://line-echo-bot-bl4eg.sprites.app/hooks/line-webhook \
  -H "Content-Type: application/json" \
  -d '{"events":[{"type":"message","source":{"userId":"Utest123"},"message":{"type":"text","text":"Hello from test"}}]}'
```

Wait and check logs:
```bash
sleep 5
sprite exec bash -c 'tail -50 ~/webhook.log'
```

## Verification Checklist

| Check | How to verify |
|-------|---------------|
| line-webhook received | Log shows "incoming HTTP POST" for line-webhook |
| line-claude.sh executed | Log shows "executing ./scripts/line-claude.sh" |
| Claude invoked | Log shows claude command output |
| Claude called forwarder | Log shows "incoming HTTP POST" for send-message |

## Troubleshooting

Check if webhook running:
```bash
sprite exec bash -c 'pgrep -f webhook || echo "NOT RUNNING"'
```

Deploy latest code:
```bash
sprite exec bash -c 'cd ~/line-bot && git pull && chmod +x scripts/*.sh'
```
