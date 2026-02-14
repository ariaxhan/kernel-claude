# KERNEL

**The AI Coding OS for Claude Code** | v4.1.0

KERNEL is a Claude Code plugin that transforms how you develop. It analyzes your codebase, creates tailored configuration, spawns specialized agents, applies methodology automatically, and evolves over time. Your coding assistant becomes a coding OS.

---

## What's New in v4.1.0

- **Plugin structure fix** — Commands, agents, skills, hooks moved to root level for correct plugin discovery
- **Updated manifest** — `plugin.json` now includes repository, license, keywords metadata

### v4.0.0 (Previous)

- Compact Unicode syntax, 5-tier model routing, hooks system, magic keywords
- Autonomy rules, 16 commands, 13 rules, coding-prompt-bank skill
- Memory system, frontend design philosophy

---

## Quick Start

### 1. Install the Plugin

```
/install-plugin https://github.com/ariaxhan/kernel-claude
```

### 2. Initialize Your Project

```bash
cd your-project
claude

# Inside Claude Code:
/repo-init
```

KERNEL analyzes your project and creates:
- `.claude/CLAUDE.md` — Project-specific coding rules
- `.claude/rules/` — Patterns discovered in your codebase
- `_meta/` — Session tracking structure
- `_memory/` — Project knowledge base

### 3. Work Normally

Methodology applies automatically:
- **Implementing a feature?** KERNEL researches and plans first
- **Fixing a bug?** KERNEL debugs systematically (reproduce → isolate → root cause)
- **Writing code?** KERNEL spawns test-runner and type-checker
- **Before completing?** KERNEL reviews for correctness

No commands to remember. Just work.

---

## Understanding the Syntax

KERNEL uses a compact, token-efficient syntax in its `CLAUDE.md`. Here's what each symbol means:

### Section Markers

| Symbol | Section | Purpose |
|--------|---------|---------|
| `Ψ:CORE` | Core Philosophy | Foundational principles that guide all behavior |
| `→:AUTONOMY` | Autonomy Rules | When to act, pause, or ask |
| `≠:ANTI` | Anti-Patterns | Behaviors to explicitly avoid |
| `Γ:SESSION` | Session Protocol | How to start, work through, and end sessions |
| `Σ:METHODOLOGY` | Auto-Methodology | Task detection → bank loading |
| `Φ:ROUTING` | Model Routing | Which AI model for which task |
| `Ω:KEYWORDS` | Magic Keywords | Shortcut modes for power users |
| `Ξ:GIT` | Git Discipline | Commit format, push protocol |
| `Δ:QUALITY` | Quality Gates | Pre-commit validation requirements |
| `∇:EVOLUTION` | Self-Evolution | How the system learns and updates itself |

### Inline Rules

Rules use a compact notation:

```
●rule_name|condition→action
```

Examples:
- `●fail_fast|exit_early|clear_errors|no_silent_failures` — Always exit early with clear errors
- `●atomic_commits|one_logical_change=one_commit` — Each commit is one logical unit
- `●pattern_repeats(2+)|→encode_to_rules` — When a pattern repeats, encode it as a rule

### Why This Syntax?

1. **Token efficiency** — ~800 tokens vs ~2000+ for verbose markdown. Less context consumed = more room for your code.
2. **Scannable** — Symbols create visual landmarks. Find sections instantly.
3. **Precise** — No ambiguity. Each rule is a clear directive.
4. **Evolvable** — Easy to add/remove rules without restructuring.

---

## Features

### Automatic Methodology

KERNEL detects what you're doing and applies the right approach:

| You're doing... | KERNEL automatically... | Bank |
|-----------------|-------------------------|------|
| Implementing a feature | Researches, plans, defines interfaces | PLANNING |
| Fixing a bug | Reproduces, isolates, finds root cause | DEBUGGING |
| Choosing an approach | Searches packages, finds 3+ sources | RESEARCH |
| Completing work | Reviews correctness, conventions, edge cases | REVIEW |
| Exploring new codebase | Maps structure, detects tooling, extracts patterns | DISCOVERY |
| Refactoring | Understands deeply, identifies specifics, prioritizes | ITERATION |
| Planning complex work | Challenges assumptions, finds risks | TEARITAPART |

Banks are loaded automatically. You don't invoke them.

### 5-Tier Model Routing

KERNEL routes work to the right model for cost and quality:

| Tier | Model | Best For | Cost |
|------|-------|----------|------|
| 1 | Ollama | Drafts, brainstorming, variations | Free (local) |
| 2 | Gemini | Web search, bulk file reads (50+), research | Free tier (2M context) |
| 3 | Sonnet | Implementation, synthesis, file writes | $3/1M input |
| 4 | Opus | Planning, design, orchestration, review | $15/1M input |
| 5 | Haiku | Test execution, lint, type checking | $0.25/1M input |

**The orchestrator (you) always runs on Opus.** Subagents are routed by task complexity.

### Magic Keywords

Type these anywhere to activate special modes:

| Keyword | Mode | What Happens |
|---------|------|-------------|
| `ulw` or `fast` | Ultrawork | Spawns 3-5 parallel agents for maximum throughput |
| `ralph` | Persistence | Loops until the task is verified complete — no stopping early |
| `eco` | Ecomode | Routes everything to the cheapest capable model |

### Hooks System

KERNEL includes prompt-based hooks that fire automatically:

**SessionStart** — When you open Claude Code, KERNEL detects your project type (package.json, pyproject.toml, etc.), notes existing tests and build configs, and prepares to spawn validation agents.

**PostToolUse (Edit|Write)** — After any code modification, KERNEL considers spawning test-runner or type-checker in the background. No announcement — it just validates.

### Autonomy Rules

KERNEL knows when to act and when to ask:

| Action | Examples |
|--------|---------|
| **ACT** (just do it) | Read files, explore code, run allowed tools, reversible operations |
| **PAUSE** (be careful) | Destructive operations, irreversible changes, security-sensitive actions |
| **ASK** (get approval) | Multi-step plans, design decisions, ambiguous intent, uncertainty |

### Memory-First Protocol

Before every task, KERNEL checks existing knowledge:

```
_memory/               → Architecture, conventions, dependencies, hotspots, bugs, decisions
kernel/project-notes/  → Past bug solutions, ADRs, infrastructure knowledge, work logs
_meta/                 → Session context, learnings, active work state
```

**Why?** Memory check takes 10 seconds. Re-discovery takes 10+ minutes. KERNEL breaks the rediscovery loop.

### Quality Gates

Before any commit, KERNEL validates:

1. Tests pass
2. Types check
3. Lint clean
4. Security scan

**If any gate fails, the commit is blocked.** Quality is non-negotiable.

### Self-Evolution

KERNEL updates itself:

- Pattern repeats 2+ times → encoded as a rule
- Mistake repeats → prevention rule added
- Discovery made → logged to `_meta/_learnings.md` + config updated
- Stale rule found → deleted (deletion is evolution too)

### Frontend Design Philosophy

KERNEL enforces intentional design:

- **System fonts first** — Never Inter or Geist (AI aesthetic signatures)
- **No emoji in UI** — Professional, not playful
- **Sophistication through restraint** — Every element earns its place
- **One signature element** — Customize until unrecognizable
- **Anti-pattern enforcement** — Rejects AI slop (purple gradients, shadcn defaults, three-column grids)

Use `/design` to activate full design mode with audit, build, review, and token generation.

---

## Agents (19)

Agents spawn proactively based on context. You don't invoke them — they activate when needed.

### Fast Validation (Haiku)

| Agent | Trigger | Purpose |
|-------|---------|---------|
| `test-runner` | Code written | Run tests, report failures |
| `type-checker` | TS/Python changes | Validate types |
| `lint-fixer` | Any code | Auto-fix lint issues |
| `build-validator` | Significant changes | Verify builds |
| `dependency-auditor` | package.json changes | Check CVEs, outdated packages |
| `git-historian` | "why" questions, legacy code | Analyze git history |
| `git-sync` | End of response | Auto-commit and push |
| `metadata-sync` | End of response | Update `_meta/` files |

### Deep Analysis (Opus)

| Agent | Trigger | Purpose |
|-------|---------|---------|
| `code-reviewer` | Before commit, "review this" | Find issues |
| `security-scanner` | Auth/input code | Find vulnerabilities |
| `test-generator` | New function/module | Generate tests |
| `api-documenter` | API changes | Update docs |
| `perf-profiler` | "slow" mentions | Profile bottlenecks |
| `refactor-scout` | "improve" mentions | Find refactoring opportunities |
| `migration-planner` | Major changes | Plan transitions |
| `frontend-stylist` | UI/CSS work | Design with philosophy enforcement |
| `media-handler` | Image/video/audio | Process multimedia |
| `database-architect` | Schema/query work | Design data layer |
| `debugger-deep` | Complex bugs | Root cause analysis (5-phase) |

---

## Commands (14)

### Setup & Maintenance

| Command | Purpose |
|---------|---------|
| `/repo-init` | Generate KERNEL config for any codebase — analyzes codebase, creates tailored config |
| `/kernel-user-init` | Set up user-level defaults at `~/.claude/` |
| `/kernel-status` | Show config health, staleness, and untracked artifacts |
| `/kernel-prune` | Review and remove stale config entries |

### Development

| Command | Purpose |
|---------|---------|
| `/build` | Full pipeline: research → plan → implement → validate |
| `/iterate` | Continuous improvement: analyze → identify → apply → test |
| `/tearitapart` | Critical review: challenge assumptions, find risks before implementing |
| `/validate` | Pre-commit gate: run types, lint, and tests in parallel |
| `/design` | Design mode: load philosophy, audit UI, build with intention |
| `/docs` | Documentation mode: audit, generate, maintain docs |

### Git Workflow

| Command | Purpose |
|---------|---------|
| `/branch` | Create worktree for isolated development work |
| `/ship` | Commit, push, and create PR from current branch |
| `/parallelize` | Set up multiple worktrees for parallel development streams |
| `/handoff` | Generate context brief for session continuity |

---

## Rules (13)

Foundational constraints applied across all work.

| Rule | Purpose |
|------|---------|
| `assumptions` | Extract and confirm assumptions before executing any task |
| `commit-discipline` | Atomic, frequent, conventional commits — push immediately |
| `context-cascade` | Pass outputs between phases, not full context (prevents token bloat) |
| `decisions` | Architecture Decision Records — logged choices with rationale |
| `fail-fast` | Exit early, clear errors, no silent failures |
| `frontend-conventions` | Implementation patterns for intentional UI development |
| `invariants` | Non-negotiable contracts: security, integrity, data safety |
| `investigation-first` | Search for existing patterns before implementing |
| `memory-protocol` | Check project memory before acting (10s vs 10min) |
| `methodology` | Auto-detect task type and load relevant knowledge bank |
| `patterns` | Discovered codebase patterns (naming, errors, logging) |
| `preferences` | Negotiable defaults (formatting, tool choices) |
| `self-evolution` | Update system when patterns emerge or mistakes repeat |

---

## Knowledge Banks (10)

Methodology templates loaded automatically based on task context.

| Bank | When It Applies |
|------|-----------------|
| **PLANNING-BANK** | Before implementing features — interface design, mental simulation |
| **DEBUGGING-BANK** | When fixing bugs — reproduce, isolate, root cause, fix |
| **RESEARCH-BANK** | Before writing new functionality — find packages, compare approaches |
| **REVIEW-BANK** | Before completing any task — correctness, conventions, edge cases |
| **DISCOVERY-BANK** | First time in unfamiliar codebase — map structure, detect tooling |
| **ITERATION-BANK** | When refactoring or improving — prioritize by impact |
| **TEARITAPART-BANK** | Before implementing complex plans — challenge every assumption |
| **DOCUMENTATION-BANK** | When working on docs — audience analysis, structure |
| **BUILD-BANK** | Full implementation pipeline — idea → code → validate |
| **CODING-PROMPT-BANK** | Core AI coding philosophy — tier system, execution laws |

---

## Skills (3)

Auto-triggered capabilities based on keywords in your messages.

| Skill | Triggers | Purpose |
|-------|----------|---------|
| `debug` | "bug", "error", "broken", "fix", "not working" | Systematic 5-phase debugging methodology |
| `research` | "research", "investigate", "learn about", "deep dive" | Structured investigation with source tracking |
| `coding-prompt-bank` | "coding rules", "initialize project", "new codebase" | Base AI coding philosophy, tier-based complexity |

---

## Session Tracking

KERNEL maintains context across sessions:

```
_meta/
├── _session.md           # Session context (blockers, decisions, infrastructure)
├── _learnings.md         # Evolution log (append-only, dated entries)
├── context/
│   └── active.md         # Current work state
└── benchmark/
    ├── metrics.jsonl      # Quantitative performance data
    ├── journal.md         # Qualitative reflections
    └── summary.md         # Weekly rollup
```

### Session Protocol

```
START → Read _meta/_session.md, active.md, kernel/state.md, git status
DURING → Update active.md, log learnings, spawn agents proactively
END → @metadata-sync + @git-sync (both run in parallel, automatic)
```

---

## Project Structure

```
kernel-claude/
├── CLAUDE.md                    # Core config (compact Unicode syntax)
├── README.md                    # This file
├── .claude-plugin/              # Plugin metadata
│   ├── plugin.json
│   └── marketplace.json
├── commands/                    # 16 plugin commands (auto-discovered)
├── agents/                      # 19 plugin agents (auto-discovered)
├── skills/                      # 3 plugin skills (auto-discovered)
│   ├── debug/SKILL.md
│   ├── research/SKILL.md
│   └── coding-prompt-bank/SKILL.md
├── hooks/                       # Plugin hooks (auto-discovered)
│   └── hooks.json
├── .claude/                     # KERNEL self-development config
│   ├── settings.json            # Project-level hooks
│   ├── settings.local.json      # Local permissions (gitignored)
│   └── rules/                   # 13 rule definitions
├── kernel/                      # Templates distributed via /repo-init
│   ├── CLAUDE.md                # Project intelligence template
│   ├── state.md                 # Shared world model
│   ├── banks/                   # 10 methodology banks
│   ├── rules/                   # Rule templates
│   ├── skills/                  # Skill templates
│   ├── hooks/                   # Hook templates
│   └── project-notes/           # Project memory templates
├── _meta/                       # Session tracking
├── memory/                      # Config registry
└── .mcp.json                    # MCP servers config
```

---

## Configuration Types

| I want Claude to... | Plugin location | Project location |
|---------------------|----------------|------------------|
| Follow rules on all tasks | N/A (not distributable) | `.claude/CLAUDE.md` or `.claude/rules/` |
| Run workflow when I say `/name` | `commands/name.md` | `.claude/commands/name.md` |
| Auto-run on code changes | `hooks/hooks.json` | `.claude/settings.json` |
| Delegate to specialist | `agents/name.md` | `.claude/agents/name.md` |
| Auto-trigger on keywords | `skills/name/SKILL.md` | `.claude/skills/name/SKILL.md` |
| Connect to external service | `.mcp.json` | `.mcp.json` |

---

## Philosophy

### Correctness Over Speed

KERNEL prioritizes working code on the first attempt. Mental simulation catches 80% of bugs before execution. Think before typing.

### Every Line Is Liability

Config over code. Native over custom. Existing over new. Delete what doesn't earn its place. The best code is code you don't write.

### Investigate Before Implement

Never assume. Find existing patterns first. Copy what works. Adapt minimally. Fighting the framework causes pain.

### Tailored, Not Templated

Every artifact is created because your project needs it:

```
Good: "Created test-runner because project has pytest"
Bad:  "Created test-runner because the template includes it"
```

---

## Requirements

- Claude Code CLI **v1.0.33+**
- Works on macOS, Linux, and Windows

---

## License

MIT

---

## Author

Aria Han — [github.com/ariaxhan](https://github.com/ariaxhan)
