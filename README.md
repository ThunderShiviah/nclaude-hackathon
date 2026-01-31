# LINE Echo Bot

A simple LINE bot that echoes user messages back to them, using [adnanh/webhook](https://github.com/adnanh/webhook).

## Prerequisites

- [webhook](https://github.com/adnanh/webhook) installed
- A LINE Messaging API channel (create one at [LINE Developers Console](https://developers.line.biz/console/))
- `curl` installed on your system

## Setup

### 1. Get LINE Credentials

1. Go to the [LINE Developers Console](https://developers.line.biz/console/)
2. Create a new provider (or use an existing one)
3. Create a new Messaging API channel
4. Note down your:
   - **Channel Secret** (from the Basic settings tab)
   - **Channel Access Token** (from the Messaging API tab - you may need to issue one)

### 2. Configure Environment

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env and add your LINE credentials
# LINE_CHANNEL_SECRET=your_channel_secret_here
# LINE_CHANNEL_ACCESS_TOKEN=your_channel_access_token_here
```

### 3. Start the Webhook Server

```bash
# Load environment variables and start webhook
source .env && webhook -hooks hooks.json -verbose
```

By default, the webhook server listens on port 9000. The LINE webhook endpoint will be:
```
http://your-server:9000/hooks/line-webhook
```

### 4. Configure LINE Webhook URL

1. Go to your channel's Messaging API settings in LINE Developers Console
2. Set the Webhook URL to your server's endpoint (e.g., `https://your-domain.com/hooks/line-webhook`)
3. Enable "Use webhook"
4. You can disable "Auto-reply messages" and "Greeting messages" for a cleaner experience

**Note:** LINE requires HTTPS for webhook URLs. For local development, you can use tools like [ngrok](https://ngrok.com/) to create a secure tunnel.

## Project Structure

```
.
├── hooks.json           # Webhook configuration
├── scripts/
│   └── line-echo.sh    # Echo bot script
├── .env.example        # Environment template
├── .env                # Your credentials (not committed)
└── README.md
```

## How It Works

1. User sends a message to your LINE bot
2. LINE platform sends a webhook POST request to your server
3. `webhook` verifies the request signature using your channel secret
4. `webhook` extracts the `replyToken` and message `text` from the payload
5. `line-echo.sh` sends a reply back using the LINE Messaging API

## Troubleshooting

- **Signature verification failed**: Make sure `LINE_CHANNEL_SECRET` is correct
- **Reply not sent**: Check that `LINE_CHANNEL_ACCESS_TOKEN` is valid and not expired
- **Webhook not receiving requests**: Ensure your server is publicly accessible via HTTPS

## License

MIT
