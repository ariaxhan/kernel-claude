---
doc_kind: reference
depends_on: [kernel/commands/*.md]
review_cadence: 30
last_reviewed: 2026-01-10
owners: ["@ariaxhan"]
---

# KERNEL Commands Reference

Complete reference for all 10 KERNEL commands with clear "when/what" descriptions.

## Command Overview

All commands follow pattern: **When to use** + **What it does**

| Command | When | What |
|---------|------|------|
| `/init` | First setup or updating | Initialize/update KERNEL templates |
| `/clean` | Regular maintenance | Show config health and prune stale entries |
| `/explore` | Before work in unfamiliar code | Map codebase structure and conventions |
| `/plan` | Before implementing features | Plan to get it right first time |
| `/debug` | Fixing bugs | Systematic diagnosis and root cause fixing |
| `/audit` | Before committing | Review code quality and documentation |
| `/branch` | Before starting work | Create intention-focused git branch |
| `/ship` | Work is complete | Commit, push, and create PR |
| `/parallelize` | Parallel work needed | Set up git worktrees for multiple branches |
| `/handoff` | Ending session | Generate context handoff for continuation |

---

## Setup & Maintenance

### `/init`

**When**: First time setting up KERNEL or updating templates to latest version.
**What**: Analyzes project and creates/updates customized configuration.

**Modes**:
1. **First time setup** - Full initialization with tier/stack detection
2. **Template refresh** - Update templates only, preserve customizations

**First Time Setup**:
- Analyzes project (tier, stack, domain)
- Creates `CLAUDE.md` with customized philosophy
- Copies `kernel/banks/` (5 methodology banks)
- Copies `kernel/commands/` (all 10 commands)
- Creates `kernel/state.md` (world model)
- Copies `kernel/hooks/` and `kernel/rules/` templates

**Template Refresh**:
- Updates banks and commands to latest plugin version
- Preserves your `CLAUDE.md`, `kernel/rules/`, `kernel/state.md`
- Shows what was updated and what was preserved

**Example**:
```
> /init

Mode: First time setup or update? [setup/update]

Analyzing project...
- TIER: 2 (Production-grade)
- STACK: TypeScript, React, Node.js
- DOMAIN: Web Application

Created:
✓ CLAUDE.md (customized)
✓ kernel/banks/ (5 banks)
✓ kernel/commands/ (10 commands)
✓ kernel/state.md

Next: Run /explore to map codebase
```

---

### `/clean`

**When**: Regular maintenance to check config health.
**What**: Shows status of all KERNEL artifacts and prompts to remove stale entries.

**Process**:
1. **Show Status** - Lists all artifacts by category (active/stale/new/untracked)
2. **Handle Untracked** - Offers to bootstrap new entries into registry
3. **Prune Stale** - For entries unused 30+ days, prompts for removal

**Stale Criteria**: No reference in 30+ days

**Example**:
```
> /clean

KERNEL Config Status
====================
Config entries: 15
  Active (last 7 days): 10
  Stale (30+ days): 3
  New (< 7 days): 2

Commands: 10 total
  [active] explore (2d ago, 15 uses)
  [stale] old-deploy (35d ago, 2 uses)

Review and remove stale? [Y/n] Y

STALE: [command] old-deploy
  Last used: 35 days ago
  Remove? [Y/n] Y
✓ Removed

Clean complete
  Reviewed: 3
  Removed: 1
  Kept: 2
```

**Safety**: Never auto-deletes, always prompts, logs all removals.

---

## Development Workflow

### `/explore`

**When**: Before starting work in unfamiliar codebase or after significant changes.
**What**: Maps repository structure, detects tooling, extracts conventions.

**Discovers**:
- **Repo Map**: Entrypoints, modules, directories, tests, docs
- **Tooling**: Formatter, linter, type checker, test runner, package manager
- **Conventions**: Naming patterns, error handling, logging, config
- **Critical Paths**: Migration files, auth code, schemas (Do Not Touch)

**Updates**: `kernel/state.md` with all discoveries

**Example**:
```
> /explore

TOOLING
-------
✓ Formatter: prettier
✓ Linter: eslint
✓ Tests: jest

CONVENTIONS
-----------
Naming:
  - Files: kebab-case
  - Functions: camelCase
  - Classes: PascalCase

CRITICAL PATHS
--------------
⚠️ src/auth/ - Security-critical
⚠️ src/models/schema.ts - Migration-critical

State updated. Ready to work.
```

---

### `/plan`

**When**: Before implementing new features, complex changes, or refactoring.
**What**: Systematic planning to understand requirements and design implementation.

**Process**:
1. Understand goal
2. Extract assumptions
3. Investigate patterns
4. Define interfaces
5. Mental simulation

**Prevents**:
- Wasted implementation cycles
- Missing edge cases
- Incorrect assumptions
- Integration issues

**Example**:
```
> /plan

Goal: Add user authentication

Assumptions extracted:
1. Using JWT tokens
2. PostgreSQL for user storage
3. bcrypt for password hashing

Investigating existing patterns...
Found: src/api/ follows REST conventions

Plan:
1. Create src/auth/jwt.ts (token generation)
2. Create src/models/user.ts (user schema)
3. Add POST /auth/login endpoint
4. Add middleware for route protection

Estimated complexity: Medium
Estimated files: 4 new, 2 modified

Proceed with implementation? [Y/n]
```

---

### `/debug`

**When**: Fixing bugs, investigating errors, or troubleshooting unexpected behavior.
**What**: Applies scientific method to diagnose root cause.

**Steps**:
1. **Reproduce** - Consistently trigger the issue
2. **Isolate** - Narrow down to specific component
3. **Hypothesize** - Form theory about cause
4. **Verify** - Test hypothesis with minimal change
5. **Fix** - Apply proper solution
6. **Confirm** - Ensure resolved, no regressions

**Example**:
```
> /debug

Issue: Users can't log in

Reproducing...
✓ Consistently fails with "Invalid credentials"

Isolating...
- Frontend: Sends correct payload
- API: Receives correct payload
- Auth: Password comparison fails

Hypothesis: bcrypt comparison reversed

Verifying...
✓ Found: bcrypt.compare(hash, password) should be bcrypt.compare(password, hash)

Fix applied: src/auth/login.ts:45

Confirming...
✓ Login now works
✓ No regressions in test suite
```

---

### `/audit`

**When**: Before committing code to ensure quality.
**What**: Reviews code for correctness and audits documentation.

**Checks**:
- **Code Review**: Correctness, consistency, completeness, conventions, invariants
- **Documentation Audit**: Frontmatter, staleness, budgets, links, orphans

**Integrated workflow**:
1. Make changes
2. Run `/audit`
3. Fix issues found
4. Run `/audit` again
5. Run `/ship`

**Example**:
```
> /audit

CODE REVIEW
-----------
✓ src/api/auth.ts - all checks passed
⚠ src/utils/parser.ts:45 - missing JSDoc

DOCUMENTATION
-------------
✗ docs/api-reference.md - stale (depends_on modified)

Issues: 1 warning, 1 staleness

Fix? [Y/n] Y

✓ Added JSDoc to parser.ts
✓ Updated api-reference.md

All checks passed. Ready to commit.
```

---

## Git Workflow

### `/branch`

**When**: Before starting any new work (NEVER WORK ON MAIN).
**What**: Creates properly named git branch based on work type.

**Branch Types**:
- `feat/` - New feature
- `fix/` - Bug fix
- `docs/` - Documentation
- `refactor/` - Code restructure
- `test/` - Test changes
- `chore/` - Maintenance

**Example**:
```
> /branch

Current: main

Type? [feat/fix/docs/refactor/test/chore] feat
Description? (2-4 words, kebab-case) user-authentication

Creating branch...
✓ git checkout -b feat/user-authentication
✓ Ready to work

Uncommitted changes moved to new branch.
```

---

### `/ship`

**When**: After work is complete and tested (run `/audit` first).
**What**: Commits changes with conventional message, pushes branch, creates PR.

**Process**:
1. Check git status
2. Generate commit message from changes
3. Commit with conventional format
4. Push branch to remote
5. Create PR with summary

**Example**:
```
> /ship

Checking state...
✓ On feat/user-authentication
✓ 4 files changed

Generating commit message...

feat(auth): add user authentication

- Add JWT token generation
- Add user model and schema
- Add login endpoint
- Add auth middleware

Co-Authored-By: Claude <noreply@anthropic.com>

Commit? [Y/n] Y
✓ Committed

Pushing...
✓ git push -u origin feat/user-authentication

Creating PR...
✓ https://github.com/user/repo/pull/123

PR created successfully.
```

---

### `/parallelize`

**When**: Working on multiple related features or testing changes in isolation.
**What**: Creates git worktree structure for parallel development.

**Modes**:
1. **Independent** - Manual coordination, you open terminals for each worktree
2. **Coordinated** - Automated agents spawned in each worktree

**Example**:
```
> /parallelize

Task: Add OAuth, billing, notifications

Streams identified:
1. OAuth (src/auth/)
2. Billing (src/billing/)
3. Notifications (src/notifications/)

Creating worktrees...
✓ ../myproject-oauth (branch: feat/oauth)
✓ ../myproject-billing (branch: feat/billing)
✓ ../myproject-notifications (branch: feat/notifications)

Open new terminals:
osascript -e 'tell app "Terminal" to do script "cd ../myproject-oauth && claude"'
osascript -e 'tell app "Terminal" to do script "cd ../myproject-billing && claude"'

Work in parallel, merge when done.
```

---

### `/handoff`

**When**: Ending work session, switching tasks, or preparing team handoff.
**What**: Creates structured handoff document with context, decisions, and next steps.

**Includes**:
- Summary (one sentence)
- Goal and current state
- Decisions made (with rationale)
- Artifacts created
- Open threads
- Next steps
- Context essentials
- Warnings (pitfalls to avoid)
- Continuation prompt (2-3 sentences for next session)

**Example**:
```
> /handoff

CONTEXT HANDOFF
===============

Summary: Building user authentication system with JWT tokens

Goal: Add secure login/logout for web app

Current state: Completed backend (JWT, user model, endpoints), frontend pending

Decisions:
- JWT over sessions (stateless, scales better)
- bcrypt for hashing (industry standard)
- 24h token expiry (balance security/UX)

Artifacts:
- src/auth/jwt.ts
- src/models/user.ts
- src/api/auth.ts

Next steps:
1. Implement frontend login form
2. Add token refresh logic
3. Test full flow

Continuation prompt:
> We're adding user authentication to the web app. Backend is complete (JWT tokens, user model, auth endpoints). Next: implement frontend login form and token refresh logic.

Save to file? [Y/n]
```

---

## Command Organization

All commands are in `kernel/commands/` directory.

After running `/init`, commands are copied to your project and become available for use.

---

## Workflow Example

Typical development workflow using KERNEL commands:

```
1. /init              # Set up KERNEL (first time)
2. /explore           # Map codebase before starting
3. /branch            # Create feature branch
4. /plan              # Plan implementation
   [make changes]
5. /debug             # Fix any issues
6. /audit             # Check quality before commit
7. /ship              # Commit, push, create PR
8. /handoff           # End session with context handoff
```

---

## See Also

- [README.md](../README.md) - KERNEL overview
- [SETUP.md](../SETUP.md) - Installation guide
- [CONFIG-TYPES.md](../CONFIG-TYPES.md) - When to use commands vs agents vs skills
- `kernel/banks/` - Methodology banks loaded by commands
