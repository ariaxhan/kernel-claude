---
name: kernel:help
description: "Show KERNEL help. What commands do, how to use them, current plugin status. Triggers: help, how, what, commands."
user-invocable: true
allowed-tools: Read, Bash, Grep, Glob
---

<command id="help">

<purpose>
Quick reference for KERNEL v7.6.1.
Commands, agents, workflows, philosophy — and current plugin status.
</purpose>

<on_start>
Before showing help, check the actual state of the plugin as loaded in your context:
1. Is the session-start hook output visible? (Look for "# KERNEL" at conversation start)
2. Which profile is active? (local, github, github-oss, github-production)
3. Are there active contracts or pending reviews in AgentDB?
4. Report what you see — don't just recite docs.

```bash
agentdb read-start
```
</on_start>

<getting_started>
| What you want | What to type |
|---------------|--------------|
| Set up a new project | `/kernel:init` |
| Start working on anything | `/kernel:ingest` + describe task |
| Run autonomously overnight | `/kernel:forge` + describe goal |
| Explore approaches creatively | `/kernel:dream` + describe problem |
| Debug something broken | `/kernel:diagnose` + describe symptom |
| Save progress before stopping | `/kernel:handoff` |
</getting_started>

<commands>
## Core Workflow

| Command | Purpose | When to use |
|---------|---------|-------------|
| `/kernel:ingest` | Guided entry — classify, scope, execute | Default for any task. Human confirms each phase. |
| `/kernel:forge` | Autonomous engine — heat/hammer/quench/anneal | Run overnight. Iterates until antifragile or reports why not. |
| `/kernel:dream` | Creative exploration — 3 perspectives + stress test | When you need competing approaches before committing. |
| `/kernel:diagnose` | Systematic debugging + refactor analysis | Bugs, regressions, or before refactoring. Diagnosis before prescription. |

## Quality & Review

| Command | Purpose | When to use |
|---------|---------|-------------|
| `/kernel:validate` | Pre-commit gates — build, lint, test, security | Before every commit. Blocks on failure. |
| `/kernel:tearitapart` | Critical pre-implementation review | Before tier 2+ work. Verdict: PROCEED/REVISE/RETHINK. |
| `/kernel:review` | Code review for PRs or staged changes | Before merging. >80% confidence threshold. |

## Learning & Observability

| Command | Purpose | When to use |
|---------|---------|-------------|
| `/kernel:retrospective` | Cross-session learning synthesis | When 5+ learnings accumulated. Clusters, deduplicates, promotes patterns. |
| `/kernel:metrics` | Observability dashboard | Check session stats, agent success rates, hook health, learning utilization. |

## Session Management

| Command | Purpose | When to use |
|---------|---------|-------------|
| `/kernel:handoff` | Save context for next session | Before closing. Saves state, decisions, next steps. |
| `/kernel:init` | Initialize KERNEL for a project | Once per project. Creates `_meta/` structure. |
| `/kernel:help` | This help | When you need a reminder. |
</commands>

<command_flow>
Typical workflows — commands chain together:

**New feature:**
  ingest → (dream if complex) → tearitapart → execute → validate → review → handoff

**Bug fix:**
  diagnose → ingest (with diagnosis) → validate → review

**Overnight autonomous:**
  forge (runs heat/hammer/quench/anneal loop, ships when antifragile)

**End of session:**
  retrospective (if learnings accumulated) → handoff
</command_flow>

<tiers>
| Tier | Files | Your Role | Commands involved |
|------|-------|-----------|-------------------|
| 1 | 1-2 | Execute directly | ingest → validate |
| 2 | 3-5 | Orchestrate, spawn surgeon | ingest → tearitapart → validate → review |
| 3 | 6+ | Orchestrate, surgeon + adversary | ingest → tearitapart → validate → review |
</tiers>

<agents>
| Agent | Role |
|-------|------|
| **Surgeon** | Minimal diff implementation. Only touches contract-listed files. |
| **Adversary** | QA — assumes broken, finds edge cases, proves with evidence. |
| **Reviewer** | Code review with APPROVE/REQUEST CHANGES/COMMENT verdict. |
| **Researcher** | Finds proven solutions and anti-patterns before coding. |
| **Scout** | Codebase reconnaissance — maps structure, detects tooling. |
| **Validator** | Pre-commit quality gate — build, types, lint, tests, security. |
| **Dreamer** | Multi-perspective debate — minimalist/maximalist/pragmatist. |
</agents>

<philosophy>
<principle id="research_first">Research anti-patterns before solutions. Most problems are already solved.</principle>
<principle id="tests_first">Define success before coding. Tests before implementation.</principle>
<principle id="agentdb">Read at start. Write at end. Memory persists across sessions.</principle>
<principle id="big5">Big 5: input validation, edge cases, error handling, duplication, complexity.</principle>
<principle id="builtin">Built-in beats library. Library beats custom. Prove you need complexity.</principle>
</philosophy>

<tips>
- **Be specific**: "Add rate limiting to /api/upload" > "make it more secure"
- **Use the right command**: diagnose for bugs, dream for design, ingest for everything else
- **Check metrics**: `/kernel:metrics` shows if learnings are being used or ignored
- **Save often**: `/kernel:handoff` before long breaks — the next session starts faster
- **Run retrospective**: After several sessions, synthesize what you've learned
</tips>

</command>
