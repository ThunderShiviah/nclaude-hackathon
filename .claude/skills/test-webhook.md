# Test Webhook Skill

Test the LINE bot webhook end-to-end by sending a mock payload and checking logs.

## Usage

Invoke with: `/test-webhook` or `/test-webhook "custom message"`

## Steps

1. **Send test request:**
```bash
curl -s -X POST https://line-echo-bot-bl4eg.sprites.app/hooks/line-webhook \
  -H "Content-Type: application/json" \
  -d '{"events":[{"type":"message","source":{"userId":"Utest123"},"message":{"type":"text","text":"TEST_MESSAGE"}}]}'
```
Replace `TEST_MESSAGE` with the argument if provided, or use "Hello from test".

2. **Wait for processing:**
```bash
sleep 5
```

3. **Check webhook logs:**
```bash
sprite exec bash -c 'tail -40 ~/webhook.log'
```

4. **Analyze results and report:**

| Check | How to verify |
|-------|---------------|
| Request received | Log shows "incoming HTTP POST request" |
| Hook matched | Log shows "line-webhook got matched" |
| Hook triggered | Log shows "hook triggered successfully" |
| Script executed | Log shows "executing ./scripts/line-claude.sh" |
| LINE_PAYLOAD passed | Log shows environment with the test message |
| Claude responded | Log shows "command output:" with curl command or response |
| No errors | No "error" or "Invalid API key" messages |

## Expected Failures (OK)

- LINE API returning error for fake userId `Utest123` - this is expected
- The test passes if Claude generates the correct curl command

## Troubleshooting

If webhook not running:
```bash
sprite exec bash -c 'pgrep -f webhook || echo "NOT RUNNING"'
```

Restart webhook:
```bash
sprite exec bash -c 'cd ~/line-bot && LINE_CHANNEL_ACCESS_TOKEN="..." nohup webhook -hooks hooks.json -verbose -port 8080 >> ~/webhook.log 2>&1 &'
```
