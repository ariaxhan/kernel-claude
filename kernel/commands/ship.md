---
description: When work is complete - Commit, push, and create PR
allowed-tools: Bash, Read
---

# Ship Changes

**When to use**: After work is complete and tested (run /audit first).
**What it does**: Commits changes with conventional message, pushes branch, creates PR.

## Steps

1. **Check state**
   ```bash
   git status --short
   git branch --show-current
   git log origin/main..HEAD --oneline
   ```

2. **If on main** → Error: "Cannot ship from main. Create a branch first."

3. **If uncommitted changes**
   - Stage all: `git add -A`
   - Generate commit message from changes
   - Commit with conventional format

4. **Push branch**
   ```bash
   git push -u origin $(git branch --show-current)
   ```

5. **Create PR**
   - Generate title from branch name
   - Generate body from commit history
   ```bash
   gh pr create --fill
   ```

6. **Report**
   - PR URL
   - Ask: "Switch to main and create new branch for next task?"

## Commit Message Format

```
<type>(<scope>): <description>

- Change 1
- Change 2

Co-Authored-By: Claude <noreply@anthropic.com>
```
