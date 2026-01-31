---
name: line-message
description: Send LINE messages via the forwarder endpoint
---

# LINE Message

Send messages to users via the LINE bot forwarder.

## Configuration

- **Bot Name:** Moneta
- **User ID:** `Uc1a46f1bcb85135637f6052187c7c50c`
- **Forwarder URL:** `https://line-echo-bot-bl4eg.sprites.app/hooks/send-message`

## Forwarder Payload Format

```json
{
  "endpoint": "/v2/bot/message/push",
  "body": {
    "to": "USER_ID",
    "messages": [{"type": "text", "text": "Message"}]
  },
  "method": "POST"
}
```

## Send a Text Message

```bash
curl -s -X POST https://line-echo-bot-bl4eg.sprites.app/hooks/send-message \
  -H "Content-Type: application/json" \
  -d '{"endpoint": "/v2/bot/message/push", "body": {"to": "Uc1a46f1bcb85135637f6052187c7c50c", "messages": [{"type": "text", "text": "Hello from Claude"}]}}'
```

## Show Typing Indicator

```bash
curl -s -X POST https://line-echo-bot-bl4eg.sprites.app/hooks/send-message \
  -H "Content-Type: application/json" \
  -d '{"endpoint": "/v2/bot/chat/loading/start", "body": {"chatId": "Uc1a46f1bcb85135637f6052187c7c50c"}}'
```

## Available LINE API Endpoints

| Endpoint | Purpose |
|----------|---------|
| `/v2/bot/message/push` | Send messages to a user |
| `/v2/bot/chat/loading/start` | Show typing indicator |
| `/v2/bot/message/reply` | Reply with replyToken (expires in 30s) |

## Message Types

### Text
```json
{"type": "text", "text": "Hello"}
```

### Sticker
```json
{"type": "sticker", "packageId": "1", "stickerId": "1"}
```

### Multiple Messages (up to 5)
```json
{"messages": [
  {"type": "text", "text": "Message 1"},
  {"type": "text", "text": "Message 2"}
]}
```
