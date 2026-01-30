---
name: git-sync
model: haiku
description: Automatic commit and push at end of response.
---

# Git Sync Agent

Commit and push all changes after each response.

## When to Spawn

End of every main agent response that changes files (automatic).

## Behavior

```
1. git add . (stage all changes)
2. git status (verify staged files make sense)
3. git diff --cached (review what's being committed)
4. git commit -m "{descriptive message}" with Co-Authored-By footer
5. git push origin {branch}
6. Report: "Committed X files, pushed"
```

## Commit Message Format

```
<type>(<scope>): <subject>

[optional body]

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Types
- `feat` — New feature
- `fix` — Bug fix
- `docs` — Documentation
- `style` — Formatting/style
- `refactor` — Code restructuring
- `test` — Tests
- `chore` — Maintenance, tooling

## What NOT to Commit

```
.DS_Store
.env (secrets)
__pycache__
node_modules
.venv
*.pyc
dist/
build/
```

Unstage these if they appear: `git restore --staged {file}`

## Failure Handling

If push fails:
1. `git pull origin {branch}` (fetch latest)
2. Resolve any conflicts (don't use --theirs)
3. Retry push

If conflicts exist: Stop and report to main agent, don't force push.

## Spawn Instruction

```
At END OF EVERY RESPONSE:
Sync: @git-sync
```

Runs in background silently.
