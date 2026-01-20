---
paths: "**/*"
---

# Commit Discipline Rule

**Commit early, commit often, commit atomically.**

## Philosophy

```
SMALL COMMITS > BIG COMMITS
Each commit = one logical unit
Each commit = independently useful
Each commit = can be reverted cleanly
```

## When to Commit

- After implementing a single function/feature
- After fixing a single bug
- After updating a single config
- After any system evolution (rules, agents, skills)
- Before switching to different work
- Every 3-5 messages if actively coding
- **ALWAYS before session end**

## Commit Format

```
<type>(<scope>): <subject>

[optional body]

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Types
| Type | Use |
|------|-----|
| feat | New feature |
| fix | Bug fix |
| docs | Documentation |
| style | Formatting |
| refactor | Code restructure |
| test | Tests |
| chore | Maintenance, config |

### Scope
The area affected: `api`, `auth`, `ui`, `db`, `system`, etc.

## Anti-Patterns

- Commits with 10+ files (split them)
- "WIP" commits (name what's actually done)
- Mixing unrelated changes (separate commits)
- Going 30+ minutes without commit
- Ending session with uncommitted work

## Process

1. `git status` - see what's changed
2. Stage related files only
3. Write descriptive message
4. Commit
5. Repeat for other logical units

## Push Protocol

- Push at end of logical work unit
- Push before ending session
- Push after config evolution
- Don't accumulate unpushed commits
