---
name: workflow
description: Development workflow with branch protection and PR process
---

# Development Workflow

## Branch Protection

The `main` branch is protected. Direct pushes are blocked. All changes must go through pull requests.

## Workflow Steps

1. **Create a feature branch**
   ```bash
   git checkout -b feature/description
   ```

2. **Make changes and commit**
   ```bash
   git add <files>
   git commit -m "Description of changes"
   ```

3. **Push branch to origin**
   ```bash
   git push -u origin feature/description
   ```

4. **Create pull request**
   ```bash
   gh pr create --title "Feature: description" --body "Details..."
   ```

5. **Merge PR** (via GitHub UI or CLI)
   ```bash
   gh pr merge --merge
   ```

6. **Auto-deployment**
   - Merging to main triggers the GitHub webhook
   - Sprite automatically runs `git pull` and restarts webhook
   - Changes are live within seconds

## After Merging

```bash
git checkout main
git pull origin main
git branch -d feature/description
```

## Quick Reference

| Action | Command |
|--------|---------|
| New branch | `git checkout -b feature/x` |
| Push branch | `git push -u origin feature/x` |
| Create PR | `gh pr create` |
| Merge PR | `gh pr merge --merge` |
| Switch to main | `git checkout main && git pull` |
