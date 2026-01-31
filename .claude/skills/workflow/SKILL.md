---
name: workflow
description: Development workflow with sprite isolation and PR process
---

# Development Workflow

## Architecture Overview

```
Production Sprite (line-echo-bot)
    │ Always on main, auto-syncs via GitHub webhook
    │
    ├── Claude Session → feature branch → Test on Dev Sprite → PR → Merge
    │
Dev Sprite (line-bot-dev)
    │ For testing before merge - mirrors prod environment
    │ URL: https://line-bot-dev-bl4eg.sprites.app
```

## Key Principles

1. **Production is read-only** - Only updates via GitHub webhook
2. **Test on dev sprite first** - Always test changes on line-bot-dev before merging
3. **PRs are the merge point** - All changes reviewed before production
4. **Dev sprite mirrors prod** - Same setup, but not connected to real LINE bot

## Branch Protection

The `main` branch is protected. Direct pushes are blocked.
All changes must go through pull requests.

## Sprites

| Sprite | Purpose | URL |
|--------|---------|-----|
| `line-echo-bot` | Production - connected to LINE | https://line-echo-bot-bl4eg.sprites.app |
| `line-bot-dev` | Development/Testing | https://line-bot-dev-bl4eg.sprites.app |

## Workflow Steps

### 1. Make changes locally and push to feature branch

```bash
git checkout -b feature/description
# Make changes
git add . && git commit -m "Description"
git push -u origin feature/description
```

### 2. Test on dev sprite BEFORE creating PR

```bash
# Deploy feature branch to dev sprite
sprite -s line-bot-dev exec -- bash -c "cd ~/line-bot && git fetch origin && git checkout feature/description && git pull"

# Restart webhook on dev sprite
sprite -s line-bot-dev exec -- bash -c "pkill -f webhook; cd ~/line-bot && nohup webhook -hooks hooks.json -verbose -port 8080 > ~/webhook.log 2>&1 &"

# Test the webhook
curl -X POST https://line-bot-dev-bl4eg.sprites.app/hooks/line-webhook \
  -H "Content-Type: application/json" \
  -d '{"events":[{"type":"message","source":{"userId":"Utest123"},"message":{"type":"text","text":"test message"}}]}'

# Check logs
sprite -s line-bot-dev exec -- bash -c "tail -50 ~/webhook.log"
```

### 3. Create PR after testing passes

```bash
gh pr create --title "Feature: description" --body "Tested on dev sprite ✓"
```

### 4. After PR is merged

Production sprite auto-syncs when PR merges (GitHub webhook → git pull).

## Alternative: Sandbox Sprites (for parallel work)

### 1. Create and setup sandbox sprite

```bash
# Generate unique sprite name
SPRITE_NAME="sandbox-$(date +%s)"

# Create sprite
sprite create $SPRITE_NAME

# Clone repo
sprite -s $SPRITE_NAME exec "git clone https://github.com/ThunderShiviah/nclaude-hackathon.git ~/workspace"

# IMPORTANT: Setup GitHub authentication
GH_TOKEN=$(gh auth token)
sprite -s $SPRITE_NAME exec "echo '$GH_TOKEN' | gh auth login --with-token && gh auth setup-git"
```

### 2. Create feature branch and make changes

```bash
sprite -s $SPRITE_NAME exec "cd ~/workspace && git checkout -b feature/description"
sprite -s $SPRITE_NAME exec "cd ~/workspace && <edit commands>"
sprite -s $SPRITE_NAME exec "cd ~/workspace && git add . && git commit -m 'Description'"
```

### 3. Push and create PR

```bash
sprite -s $SPRITE_NAME exec "cd ~/workspace && git push -u origin feature/description"
sprite -s $SPRITE_NAME exec "cd ~/workspace && gh pr create --title 'Feature: description' --body 'Details...'"
```

### 4. After PR is merged - cleanup

```bash
sprite -s $SPRITE_NAME destroy --force
```

Production sprite auto-syncs when PR merges (GitHub webhook → SIGHUP reload).

## Quick Reference

| Action | Command |
|--------|---------|
| Create sandbox | `sprite create sandbox-{id}` |
| Setup auth | `gh auth token \| sprite exec "gh auth login --with-token"` |
| Run command | `sprite -s sandbox-{id} exec "command"` |
| Create branch | `sprite exec "git checkout -b feature/x"` |
| Push branch | `sprite exec "git push -u origin feature/x"` |
| Create PR | `sprite exec "gh pr create"` |
| Cleanup | `sprite -s sandbox-{id} destroy --force` |

## Why Dev Sprite Testing?

- **Safe experimentation** - Test changes without affecting production or real LINE users
- **Same environment** - Dev sprite mirrors prod setup (webhook, Claude CLI, scripts)
- **Fast feedback** - Verify changes work before creating PR
- **No LINE tokens needed** - Dev sprite uses dummy tokens; only prod connects to LINE

## Why Sandbox Sprites (for parallel work)?

- **No git conflicts** - Each session has independent working directory
- **Parallel work** - Multiple Claude sessions can work simultaneously
- **Clean state** - No accumulated cruft between tasks
