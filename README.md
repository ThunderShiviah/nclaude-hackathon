# nclaude-hackathon

A Claude-powered LINE bot with automatic deployment via GitHub webhooks.

## Features

- **LINE Bot (Moneta)**: Claude-powered assistant that responds to LINE messages
- **Dynamic LINE API**: Supports typing indicators, text messages, stickers, and more
- **Auto-deployment**: GitHub push to main triggers automatic sync on sprite

## Architecture

```
LINE User → LINE Platform → /hooks/line-webhook → Claude CLI → /hooks/send-message → LINE API
GitHub Push → /hooks/github-sync → git pull → webhook restart
```

## Webhook Endpoints

| Endpoint | Purpose |
|----------|---------|
| `/hooks/line-webhook` | Receives LINE messages, invokes Claude |
| `/hooks/send-message` | LINE API forwarder (adds auth token) |
| `/hooks/github-sync` | Auto-deployment on push to main |

## Setup

### Prerequisites

- [webhook](https://github.com/adnanh/webhook) installed
- Claude CLI installed and authenticated
- LINE Messaging API channel

### Environment Variables

```bash
# LINE Bot
export LINE_CHANNEL_SECRET="your_channel_secret"
export LINE_CHANNEL_ACCESS_TOKEN="your_channel_access_token"

# GitHub Sync (optional)
export GITHUB_WEBHOOK_SECRET="your_github_webhook_secret"
```

### Start Webhook Server

```bash
webhook -hooks hooks.json -verbose -port 8080
```

### Configure LINE Webhook

1. Go to [LINE Developers Console](https://developers.line.biz/console/)
2. Set Webhook URL: `https://your-server.com/hooks/line-webhook`
3. Enable "Use webhook"

### Configure GitHub Webhook (Optional)

1. Go to repository → Settings → Webhooks
2. Payload URL: `https://your-server.com/hooks/github-sync`
3. Content type: `application/json`
4. Secret: Same as `GITHUB_WEBHOOK_SECRET`
5. Events: "Just the push event"

## Project Structure

```
.
├── hooks.json                    # Webhook configuration
├── scripts/
│   ├── line-claude.sh           # Claude bot handler
│   ├── send-line-message.sh     # LINE API forwarder
│   └── github-sync.sh           # Auto-deployment script
└── .claude/skills/              # Claude skills
```

## Security

- LINE signature verification via HMAC-SHA256
- GitHub webhook signature verification
- LINE token isolated in forwarder (never exposed to Claude)

## License

MIT
# Auto-sync test: Sat Jan 31 13:39:23 JST 2026
