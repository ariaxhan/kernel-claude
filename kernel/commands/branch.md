---
description: Before starting work - Create intention-focused git branch
allowed-tools: Bash, AskUserQuestion
---

# Create Branch

**When to use**: Before starting any new work (NEVER WORK ON MAIN).
**What it does**: Creates properly named git branch based on work type.

## Steps

1. **Check current state**
   ```bash
   git status --short
   git branch --show-current
   ```

2. **If already on a feature branch**
   - Ask: continue on this branch or create new?
   - If continue: exit early

3. **Get branch intention**
   Ask user for:
   - Type: feat | fix | docs | refactor | test | chore
   - Description: 2-4 words, kebab-case

4. **Create branch**
   - Uncommitted changes will automatically move to new branch
   ```bash
   git checkout -b <type>/<description>
   ```

5. **Open new terminal**
   - Open a fresh terminal in the project directory
   - This isolates the new branch work environment

6. **Push branch** (only if no uncommitted changes)
   ```bash
   git push -u origin <type>/<description>
   ```
   - If there are uncommitted changes, inform user they can push after first commit

7. **Confirm**
   Report: "Ready to work on `<branch>` in new terminal. Uncommitted changes moved to this branch."

## Branch Types

| Type | Use For |
|------|---------|
| feat/ | New feature |
| fix/ | Bug fix |
| docs/ | Documentation |
| refactor/ | Code restructure |
| test/ | Test changes |
| chore/ | Maintenance |
