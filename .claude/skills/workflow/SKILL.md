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
    ├── Claude Session 1 → sandbox-{task-1} sprite → PR #A
    ├── Claude Session 2 → sandbox-{task-2} sprite → PR #B
    └── Claude Session 3 → sandbox-{task-3} sprite → PR #C
                              │
                              ▼
                    All merge to main via PR
                              │
                              ▼
                    Production auto-syncs (SIGHUP reload)
```

## Key Principles

1. **Production is read-only** - Only updates via GitHub webhook
2. **One sprite per session** - Prevents git conflicts between Claude sessions
3. **PRs are the merge point** - All changes reviewed before production
4. **Ephemeral sandboxes** - Create per task, destroy after PR merged

## Branch Protection

The `main` branch is protected. Direct pushes are blocked.
All changes must go through pull requests.

## Workflow Steps

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

## Why Sprite Isolation?

- **No git conflicts** - Each session has independent working directory
- **Parallel work** - Multiple Claude sessions can work simultaneously
- **Clean state** - No accumulated cruft between tasks
- **Safe experimentation** - Mistakes don't affect other sessions
