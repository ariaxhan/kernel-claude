---
name: worktree-parallelization
description: Detect tasks that benefit from git worktree parallelization and coordinate multi-context development
---

# Worktree Parallelization Skill

## Purpose

This skill teaches Claude when and how to leverage git worktrees for parallel development across independent work streams.

**Key Concept**: Git worktrees allow multiple working directories from the same repository, each on different branches. This enables:
- True parallel development without conflicts
- Independent Claude instances in isolated contexts
- Separate branches managed simultaneously
- Clean separation of concerns

---

## When to Suggest Worktrees

### ✅ USE WORKTREES WHEN:

1. **3+ Independent Work Streams**
   - Each stream modifies different files/modules
   - Minimal cross-dependencies
   - Each stream is substantial (multi-file, multi-step)

2. **Long-Running Development**
   - Tasks taking 30+ minutes each
   - Benefits from context preservation
   - Requires focused, uninterrupted work

3. **Different Feature Contexts**
   - Authentication + Payments + Analytics
   - Frontend + Backend + Infrastructure
   - Feature A + Bug Fix B + Refactor C

4. **Potential Merge Complexity**
   - Changes to shared files would conflict
   - Safer to develop in isolation
   - Complex merge logic best done manually

5. **Parallel Testing/Experimentation**
   - Testing different approaches simultaneously
   - A/B implementation comparisons
   - Rapid prototyping multiple solutions

### ❌ DO NOT USE WORKTREES FOR:

- Quick fixes (< 15 minutes)
- Single-file changes
- Tightly coupled changes requiring constant coordination
- When regular subagents are sufficient
- Simple, linear workflows

---

## Detection Pattern

When analyzing a user's task, extract work streams:

```
TASK: "Add user auth, payment processing, and analytics dashboard"

ANALYSIS:
Stream 1: User Authentication
  - Files: src/auth/, models/user.py, routes/auth.py
  - Dependencies: Database schema, session management
  - Estimated scope: Large (30+ min)

Stream 2: Payment Processing
  - Files: src/payments/, services/stripe.py, routes/checkout.py
  - Dependencies: External API (Stripe), webhooks
  - Estimated scope: Large (45+ min)

Stream 3: Analytics Dashboard
  - Files: src/analytics/, components/Dashboard.tsx, routes/analytics.py
  - Dependencies: Data aggregation, charting library
  - Estimated scope: Medium (25+ min)

VERDICT: ✅ 3 independent streams, each substantial, minimal overlap
→ SUGGEST WORKTREES
```

---

## How to Suggest

When you detect a pattern match, proactively suggest:

```
I can see this task has 3 independent work streams:
1. [Stream name] - [Files affected]
2. [Stream name] - [Files affected]
3. [Stream name] - [Files affected]

This is a great candidate for git worktree parallelization. I can:
- Set up separate worktrees for each stream
- Provide commands to launch Claude in each context
- Give you merge/cleanup instructions

Would you like me to set up worktrees? Run `/parallelize` or I can proceed with regular development.
```

**IMPORTANT**: Always ASK first. Never automatically create worktrees without user approval.

---

## Coordination Modes

When user approves, ask which coordination mode:

### Mode 1: Independent (Simpler)
- Create worktrees with branches
- Provide terminal commands for user to open new Claude instances
- Each Claude works independently
- User manually merges branches when ready

**Best for**: Truly isolated features, experienced users, maximum control

### Mode 2: Coordinated (Advanced)
- Create worktrees with branches
- Spawn Task agents in each worktree context
- Main Claude monitors progress
- Main Claude coordinates merging

**Best for**: Related features, complex coordination, automated workflow

---

## Example Usage Flow

```
USER: "Add OAuth login, subscription billing, and email notifications"

CLAUDE (via this skill):
  Detects 3 streams → Suggests worktrees → User approves

CLAUDE: "Which coordination mode?
  1. Independent - You manage each Claude instance
  2. Coordinated - I spawn agents and coordinate merging"

USER: "Independent"

CLAUDE (via /parallelize command):
  Creates worktrees → Generates terminal commands → Provides merge plan

USER: Opens 3 terminals, runs Claude in each

CLAUDE INSTANCES: Work independently on their streams

USER: Merges branches when ready
```

---

## Integration with Existing Workflows

- **Subagents**: Use for sub-tasks WITHIN each worktree
- **Commands**: Each worktree Claude has access to same commands
- **Skills**: All skills available in each context
- **Git**: Each worktree is independent git working directory

---

## Anti-Patterns

❌ **Don't suggest worktrees for**:
- "Fix typo in README"
- "Add a console.log"
- "Update dependency version"

❌ **Don't create worktrees without user approval**

❌ **Don't use worktrees when subagents are sufficient**

---

## Success Metrics

Worktrees are working well when:
- ✅ Parallel development is truly independent
- ✅ No merge conflicts despite simultaneous work
- ✅ Each stream completes without waiting on others
- ✅ Context switching overhead is eliminated

---

## Reference

See `/parallelize` command for implementation details.
