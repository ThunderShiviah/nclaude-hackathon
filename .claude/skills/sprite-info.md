# Sprite Info & Testing

## Active Sprite

- **Name:** `line-echo-bot`
- **Organization:** `thunder-shiviah`
- **URL:** https://line-echo-bot-bl4eg.sprites.app

## Webhook Endpoints

| Endpoint | Purpose |
|----------|---------|
| `/hooks/line-webhook` | Receives LINE messages, invokes Claude to respond |
| `/hooks/send-message` | Forwarder - sends messages to LINE API (token isolated) |

## Architecture

```
LINE User → LINE Platform → /hooks/line-webhook → line-claude.sh → Claude CLI
    → /hooks/send-message → send-line-message.sh → LINE Push API → User
```

**Key Design:** LINE token never exposed to Claude - the forwarder holds it.

## Autonomous Testing

### Test 1: Forwarder Only

```bash
curl -s -X POST https://line-echo-bot-bl4eg.sprites.app/hooks/send-message \
  -H "Content-Type: application/json" \
  -d '{"userId": "Utest123", "message": "Test message"}'
```

**Expected:** JSON response (LINE API error for fake userId is OK)

### Test 2: Full Flow

```bash
curl -s -X POST https://line-echo-bot-bl4eg.sprites.app/hooks/line-webhook \
  -H "Content-Type: application/json" \
  -d '{"events":[{"type":"message","source":{"userId":"Utest123"},"message":{"type":"text","text":"Hello"}}]}'
```

Then check logs:
```bash
sleep 10 && sprite exec bash -c 'tail -50 ~/webhook.log'
```

### Test 3: Full Flow with Real User

Use a real userId from previous logs (e.g., `Uc1a46f1bcb85135637f6052187c7c50c`):

```bash
curl -s -X POST https://line-echo-bot-bl4eg.sprites.app/hooks/line-webhook \
  -H "Content-Type: application/json" \
  -d '{"events":[{"type":"message","source":{"userId":"Uc1a46f1bcb85135637f6052187c7c50c"},"message":{"type":"text","text":"What is 2+2?"}}]}'
```

## Verification Checklist

| Check | Log Pattern |
|-------|-------------|
| Request received | `incoming HTTP POST request` |
| Hook matched | `line-webhook got matched` |
| Script executed | `executing ./scripts/line-claude.sh` |
| Claude responded | `command output:` (not "Invalid API key") |
| Forwarder called | `send-message got matched` |
| LINE API success | `{"sentMessages":[...]}` |

## Common Issues

### Claude not authenticated
```
command output: Invalid API key · Please run /login
```
**Fix:** Run `sprite console` then `claude` to authenticate interactively.

### Webhook not running
```bash
sprite exec bash -c 'pgrep -f webhook || echo "NOT RUNNING"'
```
**Fix:** Restart webhook:
```bash
sprite exec bash -c 'cd ~/line-bot && LINE_CHANNEL_ACCESS_TOKEN="..." nohup webhook -hooks hooks.json -verbose -port 8080 >> ~/webhook.log 2>&1 &'
```

### Deploy latest code
```bash
sprite exec bash -c 'cd ~/line-bot && git pull && chmod +x scripts/*.sh'
```

## View Claude's Conversation Logs

```bash
sprite exec bash -c 'ls -la ~/.claude/projects/-home-sprite-line-bot/'
sprite exec bash -c 'cat ~/.claude/projects/-home-sprite-line-bot/SESSION_ID.jsonl'
```
