# Test Webhook Skill

Test the LINE bot webhook end-to-end using the forwarder architecture.

## Usage

Invoke with: `/test-webhook` or `/test-webhook "custom message"`

## Architecture

```
LINE → line-webhook → line-claude.sh → Claude → send-message → send-line-message.sh → LINE API
```

## Test 1: Forwarder Endpoint (send-message)

Test the forwarder independently:

```bash
curl -s -X POST https://line-echo-bot-bl4eg.sprites.app/hooks/send-message \
  -H "Content-Type: application/json" \
  -d '{"userId": "Utest123", "message": "Test from forwarder"}'
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
  -d '{"events":[{"type":"message","source":{"userId":"Utest123"},"message":{"type":"text","text":"TEST_MESSAGE"}}]}'
```

Replace `TEST_MESSAGE` with the argument if provided, or use "Hello from test".

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
| LINE_PAYLOAD passed | Log shows LINE_PAYLOAD with test message |
| Claude invoked | Log shows claude command output |
| Claude called forwarder | Log shows "incoming HTTP POST" for send-message |
| send-line-message.sh executed | Log shows "executing ./scripts/send-line-message.sh" |
| LINE_MESSAGE_PAYLOAD received | Log shows userId and message in payload |

## Expected Failures (OK)

- LINE API error for fake userId `Utest123` - expected, proves flow works
- "Invalid API key" from Claude - need to run `claude /login` on sprite

## Troubleshooting

Check if webhook running:
```bash
sprite exec bash -c 'pgrep -f webhook || echo "NOT RUNNING"'
```

Restart webhook:
```bash
sprite exec bash -c 'pkill -f webhook || true; sleep 1; cd ~/line-bot && LINE_CHANNEL_ACCESS_TOKEN="$LINE_CHANNEL_ACCESS_TOKEN" nohup webhook -hooks hooks.json -verbose -port 8080 >> ~/webhook.log 2>&1 &'
```

Deploy latest code:
```bash
sprite exec bash -c 'cd ~/line-bot && git pull && chmod +x scripts/*.sh'
```
