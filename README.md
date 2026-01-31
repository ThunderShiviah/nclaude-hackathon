# nclaude-hackathon

## GitHub Sync Webhook

Automatically syncs the local repository with remote changes when code is pushed to the main branch.

### Endpoint

```
POST /hooks/github-sync
```

### How It Works

1. Receives push events from GitHub
2. Verifies the webhook signature using HMAC-SHA256
3. Runs `git fetch && git reset --hard origin/main`
4. Restarts the webhook server

### Setup

1. Install [webhook](https://github.com/adnanh/webhook):
   ```bash
   # macOS
   brew install webhook

   # Linux
   apt-get install webhook
   ```

2. Set the webhook secret:
   ```bash
   export GITHUB_WEBHOOK_SECRET="your-secret-here"
   ```

3. Start the webhook server:
   ```bash
   webhook -hooks hooks.json -verbose -port 9000
   ```

4. Configure GitHub webhook:
   - Go to your repository → Settings → Webhooks → Add webhook
   - Payload URL: `https://your-server.com/hooks/github-sync`
   - Content type: `application/json`
   - Secret: Same value as `GITHUB_WEBHOOK_SECRET`
   - Events: Select "Just the push event"

### Security

- All requests are verified using GitHub's HMAC-SHA256 signature
- Only push events to the `main` branch trigger a sync
- The webhook secret must be set via environment variable
