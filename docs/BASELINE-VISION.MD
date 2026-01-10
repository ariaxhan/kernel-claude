# KERNEL Baseline System — Evolvable Project Intelligence

<!--
●CONTEXT|type:seed_document|for:coding_agent|purpose:build_kernel_baseline_architecture
-->

## WHAT THIS IS

KERNEL is a Claude Code plugin that initializes ANY coding project with lightweight, evolvable development intelligence. The baseline system provides structure and philosophy without prescribing content. Banks are templates with slots that grow around the codebase. Rules emerge from discovered patterns. State tracks reality. Everything is self-aware that it's scaffolding, not gospel.

## THE PROBLEM

Current approach has two failure modes:
1. **Heavy baselines** that prescribe stack-specific patterns, bloat context with 6000+ tokens, and calcify into irrelevant rules
2. **Empty baselines** that provide no structure, forcing repeated reconnaissance and pattern re-discovery every session

The goal: baseline that provides just enough structure to prevent drift without assuming anything about the codebase.

## THE SOLUTION

**Evolvable scaffolding with explicit self-awareness.**

Every artifact knows it's a template. Banks have capped slots designed to be filled. Rules start empty and grow from confirmed observations. A central state file prevents drift across sessions. Modes activate thinking styles; they don't prescribe procedures. Hooks offer suggestions; they don't auto-write.

Philosophy embedded everywhere:
- Detect, then act (never assume tooling)
- Correctness over speed
- Protect state before mutation
- Make time explicit
- Capture preferences only on confirmation
- Update state when reality changes

## KEY DECISIONS

| Decision | Rationale | Alternatives Rejected |
|----------|-----------|----------------------|
| Banks as slotted templates, not comprehensive guides | Prevents bloat; encourages evolution; caps enforce discipline | Heavy reference docs (2000+ tokens, become stale) |
| kernel/state.md as single source of truth | Prevents drift; gives every mode/agent shared world model | Scattered state across many files |
| Modes not procedures | 30 tokens vs 400; activate thinking style, not step-by-step | Procedural commands that duplicate bank content |
| Hooks as offers with manual acceptance | Prevents bad auto-capture from calcifying | Silent writes (dangerous), no capture (loses learning) |
| Four banks only (Discovery, Planning, Debugging, Review) | Minimal set that covers 80% of projects | Testing/Security/Frontend banks (too stack-specific; should emerge) |
| Rules split: preferences.md vs invariants.md | Clarifies what's negotiable vs non-negotiable | Single rules file (ambiguous priority) |
| Empty rules directory with placeholder structure | Creates scaffolding without prescriptive content | Pre-populated rules (would be wrong for most projects) |

## DESIGN CONSTRAINTS

- **Token budget**: ~330 tokens baseline (CLAUDE.md + modes + hooks). Banks load only when mode activates.
- **Slot caps**: Each bank section has explicit max items (10 bullets, 8 lines, etc.) to prevent creep
- **Self-awareness required**: Every template file must include notice that it's scaffolding designed to evolve
- **Stack agnostic**: Nothing assumes language, framework, or tooling. Those emerge.
- **Write contract clarity**: Every file knows what type of content belongs in it

## ANTI-REQUIREMENTS

What this is NOT:
- ❌ A comprehensive best practices guide (that's what the internet is for)
- ❌ Stack-specific patterns (Python, Node, Go details emerge from codebase)
- ❌ Prescriptive procedures (agents know how to code; give them philosophy not instructions)
- ❌ Auto-writing system (all pattern capture requires confirmation)
- ❌ Heavy upfront content (banks are 500-800 tokens, not 2000)

## ARCHITECTURE

### File Structure

```
kernel/
├── state.md                    # Single source of truth (updated by all modes/agents)
├── banks/
│   ├── DISCOVERY-BANK.md       # How to inventory and map the repo
│   ├── PLANNING-BANK.md        # Get-it-right-first-time methodology
│   ├── DEBUGGING-BANK.md       # Systematic diagnosis
│   └── REVIEW-BANK.md          # Correctness and consistency validation
├── modes/
│   ├── discover.md             # Activate discovery mode (~30 tokens)
│   ├── plan.md                 # Activate planning mode (~30 tokens)
│   ├── debug.md                # Activate debugging mode (~30 tokens)
│   └── review.md               # Activate review mode (~30 tokens)
└── hooks/
    ├── post-write.md           # Format if formatter exists
    ├── pattern-capture.md      # Offer to save discovered patterns
    └── pre-complete.md         # Suggest validation before task completion

.claude/
├── CLAUDE.md                   # Core philosophy only (~150 tokens)
└── rules/
    ├── preferences.md          # [EMPTY TEMPLATE] Formatting, defaults, presentation
    ├── invariants.md           # [EMPTY TEMPLATE] Non-negotiable contracts
    ├── patterns.md             # [EMPTY TEMPLATE] Discovered codebase patterns
    └── decisions.md            # [EMPTY TEMPLATE] Architecture decision log
```

### Token Budget Breakdown

| Component | Count | Tokens Each | Loaded When | Total Baseline |
|-----------|-------|-------------|-------------|----------------|
| CLAUDE.md | 1 | 150 | Always | 150 |
| Modes | 4 | 30 | Always (metadata only) | 120 |
| Hooks | 3 | 20 | Always | 60 |
| Banks | 4 | 500-800 | On mode activation | 0 |
| Rules | 4 | varies | When relevant | 0 |
| State | 1 | ~200 | On mode activation | 0 |
| **BASELINE** | | | | **~330** |

### Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLAUDE.md                                │
│                    (Philosophy: ~150 tokens)                     │
│         "Correctness > speed. Detect, then act."                │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      MODE ACTIVATION                             │
│                                                                  │
│   /discover ──▶ Load DISCOVERY-BANK + state.md                  │
│   /plan ──────▶ Load PLANNING-BANK + state.md                   │
│   /debug ─────▶ Load DEBUGGING-BANK + state.md                  │
│   /review ────▶ Load REVIEW-BANK + state.md                     │
│                                                                  │
│   Mode stays active until exit condition or new mode            │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      kernel/state.md                             │
│                  (Shared world model: ~200 tokens)               │
│                                                                  │
│   Updated by: all modes, all agents                             │
│   Contains: repo map, tooling, conventions, validation matrix   │
│   Prevents: drift between sessions, repeated reconnaissance     │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                         HOOKS                                    │
│                                                                  │
│   post-write ────▶ "Formatter detected. Format? [y/n]"          │
│   pattern-capture ▶ "I noticed X. Save to rules? [y/n]"         │
│   pre-complete ──▶ "Validation available. Run? [y/n]"           │
│                                                                  │
│   ALL hooks are OFFERS. Never silent writes.                    │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     .claude/rules/                               │
│                   (Starts empty, grows)                          │
│                                                                  │
│   preferences.md ──▶ Negotiable: formatting, defaults           │
│   invariants.md ───▶ Non-negotiable: contracts, boundaries      │
│   patterns.md ─────▶ Discovered: naming, error handling         │
│   decisions.md ────▶ Recorded: architecture choices             │
└─────────────────────────────────────────────────────────────────┘
```

## COMPONENT SPECIFICATIONS

### kernel/state.md

The single source of truth. Every mode reads it. Every mode/agent updates it when they learn something.

```markdown
# Kernel State
<!-- Auto-updated. Do not edit structure. Add content to slots. -->

## Repo Map (max 15 lines)
[TO DISCOVER: entrypoints, modules, boundaries]

## Tooling Inventory (max 10 lines)
| Tool | Command | Status |
|------|---------|--------|
| Formatter | [unknown] | [unchecked] |
| Linter | [unknown] | [unchecked] |
| Typecheck | [unknown] | [unchecked] |
| Tests | [unknown] | [unchecked] |
| Package mgr | [unknown] | [unchecked] |

## Conventions (max 10 bullets)
[TO DISCOVER: naming, error handling, logging, config patterns]

## Validation Matrix (max 8 rows)
| Check | Command | Last Run | Status |
|-------|---------|----------|--------|
| [discovered checks populate here] |

## Active Preferences
→ See .claude/rules/preferences.md

## Recent Decisions (max 5, link to decisions.md for full)
[TO POPULATE: as decisions are made]

## Do Not Touch (max 5 bullets)
[TO DISCOVER: migrations, auth, critical paths]

---
⚠️ This file is the shared world model. Update when reality changes.
```

### Bank Template (applies to all banks)

Each bank follows this structure:

```markdown
# [BANK NAME]

## Philosophy (3-5 lines, never changes)
[Core principle this bank embodies]

## Process (skeleton, not procedure)
[High-level phases, not step-by-step instructions]

## Slots (capped, designed to fill)

### [Slot Name] (max N items)
[TO EVOLVE: description of what goes here]
- [empty until discovered]

### [Another Slot] (max N items)
[TO EVOLVE: description]
- [empty until discovered]

## Stack Patterns (max 10 total across all stacks)
[TO EVOLVE: Add as you encounter language/framework specifics]

## Pitfalls Observed (max 10 bullets)
[TO EVOLVE: Add when you hit issues]

---
⚠️ TEMPLATE NOTICE
This bank is scaffolding. Expect gaps.
Fill slots as you learn this codebase.
Move stable discoveries to .claude/rules/ when they solidify.
Respect caps; if full, replace least valuable or move to rules.
```

### Mode Template (applies to all modes)

Ultra-thin. ~30 tokens each.

```markdown
---
description: [One line]
---
# [Mode Name]

Entering [MODE] mode.
1. Read [BANK-NAME] from kernel/banks/
2. Read kernel/state.md for current context
3. Apply methodology until [exit condition]
4. Update state.md with any discoveries

[Single sentence about what makes this mode distinct]
```

### Hook Template

Offers, not actions. ~20 tokens each.

```markdown
---
trigger: [event]
---
# [Hook Name]

When [trigger condition]:
1. Check if [relevant tool/pattern] exists
2. If yes: "[Offer message]? [y/n]"
3. On confirm: [minimal action]
4. Log to state.md if state changed
```

### CLAUDE.md

Core philosophy only. The anchor.

```markdown
# KERNEL

CORRECTNESS > SPEED
One working implementation beats three debug cycles.

DETECT, THEN ACT
Never assume tooling. Find it first.

PROTECT STATE
Backup before mutation. Explicit time. Confirm before delete.

CAPTURE ON CONFIRMATION
Patterns save only when approved. Never silent writes.

---

This project uses KERNEL.
- Banks in kernel/banks/ contain methodology (load via modes)
- State in kernel/state.md tracks reality (read on mode activation)  
- Rules in .claude/rules/ capture project-specific patterns (evolve over time)

When uncertain, read state.md first.
```

## BANK SPECIFICATIONS

### DISCOVERY-BANK.md (~500 tokens)

**Purpose:** Build the world model. Populate state.md.

**Slots:**
- Repo map patterns (max 10): How to find entrypoints, modules, boundaries
- Tooling detection (max 8): Commands to check for formatter, linter, tests, etc.
- Convention extraction (max 10): What to look for (naming, error handling, logging)
- Risk identification (max 5): Migrations, auth, external APIs, data writes

**Exit condition:** state.md is populated with discovered information

### PLANNING-BANK.md (~600 tokens)

**Philosophy:** Get it right first time. Mental simulation before execution.

**Slots:**
- Pre-implementation checklist (max 8): WHAT/WHY/DONE-WHEN, assumptions, interfaces
- Investigation patterns (max 10): How to find existing patterns in THIS codebase
- Risk planning (max 5): What could go wrong, how to validate
- Stack patterns (max 10): Language-specific planning patterns as discovered

**Exit condition:** Plan approved, implementation begins

### DEBUGGING-BANK.md (~500 tokens)

**Philosophy:** Reproduce first. Isolate. Instrument. Bisect. Confirm fix.

**Slots:**
- Reproduction patterns (max 8): How to reliably trigger the bug
- Isolation techniques (max 8): Binary search, minimal repro, dependency removal
- Instrumentation (max 6): Logging, breakpoints, state inspection
- Regression validation (max 5): How to prove it's fixed and stays fixed

**Exit condition:** Bug confirmed fixed, regression check identified

### REVIEW-BANK.md (~500 tokens)

**Philosophy:** Correctness, consistency, completeness.

**Slots:**
- Correctness checks (max 10): Does it do what it should?
- Convention adherence (max 8): Does it match state.md conventions?
- Validation matrix check (max 6): Are all relevant validations passing?
- Interface stability (max 5): Does it break contracts in invariants.md?

**Exit condition:** Review approved or changes requested

## SAFETY PRIMITIVES

Embedded in philosophy, enforced in banks:

| Primitive | When | Action |
|-----------|------|--------|
| Backup before mutation | Any persistent state change | Copy/backup first |
| Confirm before delete | Any destructive operation | Explicit user confirmation |
| Characterization before refactor | Any significant restructure | Tests or validation plan first |
| Timezone explicitness | Any time handling | UTC with explicit timezone |
| Compatibility notes | Any interface change | Document in decisions.md |

## WRITING CONTRACT

| Content Type | Where It Goes | Example |
|--------------|---------------|---------|
| Philosophy | CLAUDE.md, bank headers | "Correctness > speed" |
| Methodology | Banks (process sections) | How to plan, debug, review |
| Discovered patterns | Bank slots → rules/patterns.md when stable | "Errors use Result<T, Error> pattern" |
| Preferences | rules/preferences.md | "Date format: Jan 15, 2026" |
| Invariants | rules/invariants.md | "Auth tokens never logged" |
| Decisions | rules/decisions.md | "Chose SQLite because..." |
| Current reality | kernel/state.md | Tooling inventory, conventions |

**Promotion path:** Bank slot discovery → repeated use → promote to rules/ when stable

## SUCCESS CRITERIA

- [ ] Baseline loads in ~330 tokens
- [ ] Banks load only on mode activation
- [ ] All template files include self-awareness notice
- [ ] All slots have explicit caps
- [ ] state.md exists and is updated by modes
- [ ] Hooks offer, never auto-write
- [ ] Rules directory starts empty with placeholder structure
- [ ] /discover populates state.md from empty
- [ ] Philosophy ("correctness > speed", "detect then act") appears in CLAUDE.md

## YOUR TASK

1. **Critique this architecture first.** Identify simplifications. Flag anything that seems like premature complexity.

2. **Build the file structure.** Create all directories and files with template content.

3. **Prioritize:**
   - kernel/state.md (the anchor everything references)
   - CLAUDE.md (philosophy)
   - Four banks with slotted structure
   - Four modes (ultra-thin)
   - Three hooks (offer-based)
   - Rules directory with empty placeholders

4. **Validate:** After creation, run /discover on the KERNEL project itself to test that state.md gets populated.

5. **Report:** What you built, any deviations from this spec, and recommendations for improvement.

## INSTRUCTIONS FOR CODING AGENT

1. **First**: Read this entire document and FLOWCHARTS.md if provided
2. **Then**: Critique the architecture; identify simplifications before building
3. **Before building**: Confirm understanding of slot caps and self-awareness requirements
4. **During build**: Every template file needs the ⚠️ TEMPLATE NOTICE block
5. **If unclear**: The constraints exist for reasons; ask rather than assume
6. **Test**: Run /discover on the kernel project itself to validate the system works