---
description: Create intention-focused branch for work
allowed-tools: Bash, AskUserQuestion
---

# Branch Command

Create a focused branch before starting work.

## Steps

1. **Check current state**
   ```bash
   git status --short
   git branch --show-current
   ```

2. **If uncommitted changes exist**
   - Ask: commit them first, stash them, or abort?

3. **If already on a feature branch**
   - Ask: continue on this branch or create new?

4. **Get branch intention**
   Ask user for:
   - Type: feat | fix | docs | refactor | test | chore
   - Description: 2-4 words, kebab-case

5. **Create and push branch**
   ```bash
   git checkout -b <type>/<description>
   git push -u origin <type>/<description>
   ```

6. **Confirm**
   Report: "Ready to work on `<branch>`. Commits will be isolated from main."

## Branch Types

| Type | Use For |
|------|---------|
| feat/ | New feature |
| fix/ | Bug fix |
| docs/ | Documentation |
| refactor/ | Code restructure |
| test/ | Test changes |
| chore/ | Maintenance |
