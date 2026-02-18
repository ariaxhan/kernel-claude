---
description: Create worktree for isolated development work
allowed-tools: Bash, AskUserQuestion
---

# Branch Command (Worktree-Based)

## ●:ON_START

```bash
agentdb read-start
```

Create an isolated worktree before starting work. Never work directly on main.

## Philosophy

```
NEVER WORK ON MAIN
All work happens on isolated worktrees.
Create worktree first, then code.
Each worktree = isolated context = own Claude session.
```

## Steps

### 1. Check Current State

```bash
git status --short
git branch --show-current
git worktree list
```

### 2. If Uncommitted Changes Exist
- Ask: commit them first, stash them, or abort?

### 3. If Already in a Worktree (not main)
- Ask: continue here, or create new worktree?

### 4. If on Main, Get Branch Intention

Ask user for:
- **Type**: feat | fix | docs | refactor | test | chore
- **Description**: 2-4 words, kebab-case

### 5. Create Worktree and Open Terminal

```bash
# Get project name for naming
PROJECT=$(basename $(pwd))

# Create worktree with new branch
git worktree add -b <type>/<description> ../${PROJECT}-<type>-<description>

# Open in new terminal (macOS)
open -a Terminal ../${PROJECT}-<type>-<description>
```

**For Linux:**
```bash
# gnome-terminal
gnome-terminal --working-directory="../${PROJECT}-<type>-<description>"

# OR xterm
xterm -e "cd ../${PROJECT}-<type>-<description> && $SHELL" &
```

**For Windows (PowerShell):**
```powershell
Start-Process wt -ArgumentList "-d", "..\${PROJECT}-<type>-<description>"
```

### 6. Confirm

Report:
```
Worktree created and terminal opened!

Setup:
  Main directory: [current path] (stays on main)
  Worktree: ../${PROJECT}-<type>-<description> (on <type>/<description>)

New Terminal window opened at the worktree location.

You can now:
  1. Start Claude Code in the new terminal
  2. Work on your feature in isolation
  3. When done, use /ship to push and create PR

Cleanup (after merge):
  git worktree remove ../${PROJECT}-<type>-<description>
  git branch -d <type>/<description>
```

## Branch Types

| Type | Use For |
|------|---------|
| feat/ | New feature |
| fix/ | Bug fix |
| docs/ | Documentation |
| refactor/ | Code restructure |
| test/ | Test changes |
| chore/ | Maintenance |

## Example Flow

```
USER: /branch

CLAUDE: What type of work?
  1. feat - New feature
  2. fix - Bug fix
  3. docs - Documentation
  4. refactor - Code restructure
  5. test - Test changes
  6. chore - Maintenance

USER: feat

CLAUDE: Brief description (2-4 words, kebab-case)?

USER: user-authentication

CLAUDE: Creating worktree...

  git worktree add -b feat/user-authentication ../myapp-feat-user-authentication
  open -a Terminal ../myapp-feat-user-authentication

Worktree created and terminal opened!

Setup:
  Main directory: ~/projects/myapp (stays on main)
  Worktree: ../myapp-feat-user-authentication (on feat/user-authentication)

Start Claude Code in the new terminal to begin work.
```

## Why Worktrees Instead of Branches?

| Traditional Branching | Worktree Approach |
|----------------------|-------------------|
| `git checkout -b feat/x` | `git worktree add -b feat/x ../proj-feat-x` |
| Same directory, different branch | Separate directory, own context |
| Stash required for context switch | Just open another terminal |
| One Claude session | Multiple parallel Claude sessions |
| Risk of cross-contamination | Complete isolation |

## Edge Cases

### If Already on Feature Branch
```
You're on branch: feat/existing-work

Options:
  1. Continue here (don't create new worktree)
  2. Create new worktree for different task
```

### If Worktree Already Exists
```
Worktree already exists at: ../myapp-feat-user-authentication

Options:
  1. Open terminal to existing worktree
  2. Remove it and create fresh
  3. Create with different name
```

### If Not a Git Repository
```
Error: Not in a git repository
Cannot create worktrees outside of git repos.
```

## Related

- `/ship` - Push branch and create PR from worktree

## ●:ON_END

```bash
agentdb write-end '{"command":"branch","did":"created worktree","branch":"<type>/<description>","path":"<worktree-path>"}'
```
