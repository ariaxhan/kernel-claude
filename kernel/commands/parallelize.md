---
description: For parallel work - Set up git worktrees for multiple branches
allowed-tools: Bash, Read, Write, AskUserQuestion, Task, TodoWrite
---

# Set Up Parallel Worktrees

**When to use**: Working on multiple related features or testing changes in isolation.
**What it does**: Creates git worktree structure for parallel development without stashing.

## Execution Steps

### 1. Analyze Task and Extract Streams

Parse the user's request to identify independent work streams:

```
Example:
USER: "Add OAuth, billing, and notifications"

STREAMS:
1. OAuth Authentication
   - Files: src/auth/, models/user.py
   - Branch: feature-oauth
   - Scope: Large

2. Billing Integration
   - Files: src/billing/, services/stripe.py
   - Branch: feature-billing
   - Scope: Large

3. Email Notifications
   - Files: src/notifications/, workers/email.py
   - Branch: feature-notifications
   - Scope: Medium
```

If user hasn't provided enough detail, ask for clarification on:
- What are the independent streams?
- What files/modules will each stream touch?
- Any dependencies between streams?

### 2. Ask for Coordination Mode

Use AskUserQuestion to ask:

```
question: "How should I coordinate work across the worktrees?"
options:
  1. Independent - I'll create worktrees and provide commands for you to open new terminals with Claude in each. You manually merge when done.
  2. Coordinated - I'll create worktrees, spawn agents in each, monitor progress, and handle merging for you.
```

### 3. Create Worktrees

For each stream, create a worktree:

```bash
# Get current directory name for naming convention
PROJECT_NAME=$(basename $(pwd))

# Create worktrees (one per stream)
git worktree add -b [branch-name] ../${PROJECT_NAME}-[stream-name]

# Example:
git worktree add -b feature-oauth ../myproject-feature-oauth
git worktree add -b feature-billing ../myproject-feature-billing
git worktree add -b feature-notifications ../myproject-feature-notifications
```

Verify with `git worktree list`

### 4A. Independent Mode Instructions

Provide copy-paste commands for the user:

```markdown
## Worktrees Created!

### Open New Terminals (macOS)

**Automated** (copy-paste these):
```bash
osascript -e 'tell application "Terminal" to do script "cd /path/to/worktree-1 && claude"'
osascript -e 'tell application "Terminal" to do script "cd /path/to/worktree-2 && claude"'
osascript -e 'tell application "Terminal" to do script "cd /path/to/worktree-3 && claude"'
```

**Manual**:
```bash
# Tab 1
cd /path/to/worktree-1
claude

# Tab 2
cd /path/to/worktree-2
claude

# Tab 3
cd /path/to/worktree-3
claude
```

### Task Breakdown

**Worktree 1** (feature-oauth):
- [Specific tasks for this stream]

**Worktree 2** (feature-billing):
- [Specific tasks for this stream]

**Worktree 3** (feature-notifications):
- [Specific tasks for this stream]

### Merging When Done

```bash
# Return to main worktree
cd /original/path

# Merge each branch
git checkout main
git merge feature-oauth
git merge feature-billing
git merge feature-notifications

# Push
git push origin main
```

Or create PRs:
```bash
git push -u origin feature-oauth
git push -u origin feature-billing
git push -u origin feature-notifications
# Then create PRs on GitHub
```

### Cleanup

```bash
# Remove worktrees
git worktree remove ../myproject-feature-oauth
git worktree remove ../myproject-feature-billing
git worktree remove ../myproject-feature-notifications

# Delete branches (if merged)
git branch -d feature-oauth
git branch -d feature-billing
git branch -d feature-notifications
```
```

### 4B. Coordinated Mode Execution

Spawn agents in each worktree using Task tool:

```
For each stream:
  1. Use TodoWrite to add task for this stream
  2. Use Task tool to spawn agent with:
     - subagent_type: "general-purpose"
     - prompt: "You are working in worktree [path] on branch [branch-name].
               Your task: [specific stream tasks]

               IMPORTANT: Your working directory is [worktree-path].
               All file operations should be relative to this directory.

               When done:
               - Commit your changes
               - Report completion

               Do NOT merge or delete the worktree."
  3. Track agent progress
```

Example:
```
Task 1: OAuth Agent
  Directory: ../myproject-feature-oauth
  Branch: feature-oauth
  Task: Implement OAuth login flow

Task 2: Billing Agent
  Directory: ../myproject-feature-billing
  Branch: feature-billing
  Task: Integrate Stripe payment processing

Task 3: Notifications Agent
  Directory: ../myproject-feature-notifications
  Branch: feature-notifications
  Task: Set up email notification system
```

Monitor agents:
- Track completion status
- Handle errors/questions
- Coordinate if dependencies emerge

When all agents complete:
1. Review each branch
2. Merge in appropriate order (considering dependencies)
3. Clean up worktrees
4. Report final status

### 5. Final Verification

After setup, verify:
```bash
git worktree list        # Shows all worktrees
git branch              # Shows all branches
```

## Edge Cases

### If Git State is Dirty
```
Error: Current working directory has uncommitted changes
Solution: Ask user to commit or stash first
```

### If Worktree Already Exists
```
Error: Worktree path already exists
Solution: Suggest different naming or cleanup existing
```

### If No Git Repository
```
Error: Not in a git repository
Solution: Cannot use worktrees, suggest regular subagents
```

## Success Criteria

- ✅ All worktrees created successfully
- ✅ Each on correct branch
- ✅ Commands provided are copy-paste ready
- ✅ Clear merge/cleanup instructions given
- ✅ (Coordinated mode) Agents successfully spawned and tracked

## Anti-Patterns

❌ Creating worktrees without user approval
❌ Auto-merging without review
❌ Forgetting to provide cleanup commands
❌ Not checking git status first

## Related

- See `.claude/skills/worktree-parallelization/SKILL.md` for detection criteria
- Integration with existing subagent workflows
