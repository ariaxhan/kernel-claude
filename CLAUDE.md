# Kernel

**The Complete AI Coding OS for Claude Code.**

---

## SUBAGENT OUTPUT RULE (CRITICAL - READ FIRST)

```
EVERY SUBAGENT MUST WRITE TO FILES.

When spawning ANY subagent:
1. Tell it WHERE to write (absolute path in _meta/ or relevant folder)
2. Tell it WHAT format (.md, structured)
3. Subagent MUST write findings to file BEFORE returning
4. Subagent output in terminal is ALSO required (both, not either/or)

Example prompt to subagent:
"Research X. Write findings to /project/_meta/research/output.md.
Also return summary to me."

NEVER spawn subagents that only return to you.
Their work is LOST if not written to files.
```

---

## Philosophy

```
CORRECTNESS > SPEED
One working implementation beats three debug cycles.
Think before typing. Simulate before running.

EVERY LINE IS LIABILITY
Config > code. Native > custom. Existing > new.
Delete what doesn't earn its place.

INVESTIGATE BEFORE IMPLEMENT
Never assume. Search for existing patterns first.
Copy what works. Adapt minimally.

DETECT, THEN ACT
Don't assume tooling exists. Find it.
Don't assume conventions. Discover them.

PROTECT STATE
Backup before mutation. Confirm before deletion.
Make time explicit (UTC + timezone).

SELF-EVOLUTION
When you learn something → UPDATE THE SYSTEM.
Patterns that work → encode them.
Repeated mistakes → patch the rules.
```

---

## Session Protocol

```
SESSION START:
1. Read _meta/_session.md for context
2. Read _meta/context/active.md for current work
3. Check kernel/state.md for project reality
4. Check for uncommitted work (git status)
5. Suggest next actions proactively

DURING:
- Update active.md as you work
- Log learnings to _meta/_learnings.md immediately
- Commit after each logical unit (see Git Discipline below)

SESSION END:
- Update _meta/_session.md
- Archive active.md if work is complete
- Commit and push (ALWAYS)
```

---

## Auto-Sync Pattern (MANDATORY)

Two agents handle metadata + git operations at the END of each response:

### `@metadata-sync`
Updates `_meta/context/active.md` and `_meta/_learnings.md`.

**Spawn at end of response if:**
- Files were created/edited/deleted
- Tasks completed
- Decisions made
- Learnings discovered
- Status changed

### `@git-sync`
Commits and pushes all changes.

**Spawn at end of response if:**
- Files changed (any type)
- Metadata updated
- Any work completed

### Usage Pattern

Every response should end with (if changes were made):

```
Sync: @metadata-sync
Sync: @git-sync
```

Both run in parallel. **No manual git commands from main agent. No manual active.md updates in main response.**

---

## Git Commit Discipline

```
SMALL COMMITS > BIG COMMITS
Each commit = one logical unit
Each commit = independently useful
Each commit = can be reverted cleanly

WHEN TO COMMIT:
- After implementing a single function/feature
- After fixing a single bug
- After any system evolution
- Every 3-5 messages if actively coding
- ALWAYS before session end

FORMAT:
<type>(<scope>): <subject>

Co-Authored-By: Claude <noreply@anthropic.com>

TYPES: feat | fix | docs | style | refactor | test | chore

ANTI-PATTERNS:
- Commits with 10+ files (split them)
- "WIP" commits (name what's actually done)
- Mixing unrelated changes
- Ending session with uncommitted work
```

---

## Commands (14)

| Command | Purpose |
|---------|---------|
| `/build` | Full pipeline: idea → research → plan → implement → validate |
| `/ship` | Commit, push, create PR from branch |
| `/branch` | Create isolated worktree for new work |
| `/validate` | Pre-commit gate: types + lint + tests |
| `/iterate` | Continuous improvement on existing code |
| `/tearitapart` | Critical review before implementing |
| `/parallelize` | Set up multiple worktrees for parallel work |
| `/release` | Bump version, tag, push release |
| `/docs` | Documentation mode: audit, generate, maintain |
| `/handoff` | Generate context brief for session continuity |
| `/kernel-init` | Initialize KERNEL for a new project |
| `/kernel-user-init` | Initialize user-level KERNEL at ~/.claude/ |
| `/kernel-status` | Show config health and staleness report |
| `/kernel-prune` | Remove stale config entries |

---

## Agents (19)

**Spawn proactively. Don't wait for permission.**

### Fast Validation (haiku)
| Agent | Trigger | Purpose |
|-------|---------|---------|
| `test-runner` | Any code written | Run tests |
| `type-checker` | TypeScript/Python | Check types |
| `lint-fixer` | Any code | Auto-fix lint |
| `build-validator` | Significant changes | Verify builds |
| `dependency-auditor` | package.json changes | Check CVEs |
| `git-historian` | "why" or legacy code | Understand history |
| `git-sync` | End of response | Auto-commit changes |
| `metadata-sync` | End of response | Update _meta files |

### Deep Analysis (opus)
| Agent | Trigger | Purpose |
|-------|---------|---------|
| `code-reviewer` | PR or "review this" | Find issues |
| `security-scanner` | Auth/input handling | Find vulnerabilities |
| `test-generator` | New function/module | Generate tests |
| `api-documenter` | API changes | Update docs |
| `perf-profiler` | "slow" or perf concern | Profile bottlenecks |
| `refactor-scout` | "improve" or messy code | Find opportunities |
| `migration-planner` | Major change | Plan transition |
| `frontend-stylist` | UI/CSS work | Design visual styles |
| `media-handler` | Image/video/audio | Process multimedia |
| `database-architect` | Schema/query work | Design data layer |
| `debugger-deep` | Complex bugs | Root cause analysis |

---

## Rules (12)

| Rule | Purpose |
|------|---------|
| `self-evolution.md` | Update system when you learn |
| `commit-discipline.md` | Small, atomic, frequent commits |
| `assumptions.md` | Extract and verify before executing |
| `investigation-first.md` | Find patterns before writing |
| `fail-fast.md` | Exit early, clear errors |
| `invariants.md` | Non-negotiable constraints |
| `methodology.md` | KERNEL development methodology |
| `patterns.md` | Reusable code patterns |
| `preferences.md` | Formatting and style preferences |
| `decisions.md` | Logged architectural decisions |
| `memory-protocol.md` | Check project memory BEFORE acting |
| `context-cascade.md` | Pass outputs only between phases |

---

## Project Notes (4 templates)

In `kernel/project-notes/` - check these FIRST:

| File | Purpose |
|------|---------|
| `bugs.md` | Past bug solutions (check before debugging) |
| `decisions.md` | Architecture decisions (ADR format) |
| `key_facts.md` | Infrastructure knowledge (ports, URLs, tables) |
| `issues.md` | Work log for session context |

---

## Banks (10 methodology templates)

In `kernel/banks/`:

| Bank | When to Use |
|------|-------------|
| `BUILD-BANK` | Planning new features |
| `DEBUGGING-BANK` | Diagnosing issues |
| `REVIEW-BANK` | Code review |
| `PLANNING-BANK` | Architecture decisions |
| `RESEARCH-BANK` | Investigating unknowns |
| `DISCOVERY-BANK` | Mapping new codebases |
| `ITERATION-BANK` | Improving existing code |
| `DOCUMENTATION-BANK` | Writing docs |
| `TEARITAPART-BANK` | Critical review |
| `CODING-PROMPT-BANK` | Coding patterns |

---

## Benchmark System

`_meta/benchmark/` tracks performance automatically:

- `metrics.jsonl` - Quantitative data (tokens, time, errors)
- `journal.md` - Qualitative reflections at checkpoints
- `summary.md` - Weekly rollup

Data is used for self-improvement: find patterns, optimize workflows.

---

## Self-Evolution (MANDATORY)

When you learn something:
1. **Log** to `_meta/_learnings.md`
2. **Update** the relevant config (agent/rule/skill/CLAUDE.md)
3. **Commit** with `chore(system): {what evolved}`
4. **Tell user** briefly what changed

Deletion is evolution too. Kill what doesn't work.

---

## Defaults

- Prefer clarity over cleverness
- Prefer explicit over implicit
- Prefer existing patterns over new inventions
- Prefer small verified steps over large speculative leaps

**When uncertain:** Read `kernel/state.md`, then ask.
