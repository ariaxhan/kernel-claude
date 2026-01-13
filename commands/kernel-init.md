---
description: Initialize KERNEL for project - analyzes codebase and creates tailored configuration
allowed-tools: Read, Write, Glob, Bash, Grep, AskUserQuestion
---

# Initialize KERNEL

Create project-specific Claude Code configuration by analyzing the codebase and tailoring every artifact to this project's actual needs.

**Philosophy**: KERNEL uses banks as methodology guides, not as copy-paste templates. Every command, rule, and hook should exist because THIS project needs it.

---

## Step 1: Analyze the Project

Gather context before creating anything:

```
READ:
- README.md → purpose, features, audience
- package.json / pyproject.toml / Cargo.toml / go.mod → stack, dependencies
- Existing tests → testing patterns, coverage expectations
- .github/workflows → CI patterns (if any)
- Existing .claude/ → prior configuration
- Source structure → module organization, key files
```

**Determine:**
- **Tier**: 1 (hackathon), 2 (production), 3 (critical systems)
- **Stack**: Primary language, frameworks, tools
- **Domain**: API, CLI, library, web app, mobile, etc.
- **Patterns**: How errors are handled, how tests are structured, naming conventions

---

## Step 2: Ask Clarifying Questions (If Needed)

If intent is unclear, ask:
- "What's the primary use case for this project?"
- "Are there any specific workflows you repeat often?"
- "What quality standards matter most? (tests, types, docs)"

Don't assume - ask when uncertain.

---

## Step 3: Create Directory Structure

Only create what's needed:

```
.claude/
├── CLAUDE.md       # Project intelligence (always)
├── commands/       # Only if project has repeatable workflows
├── rules/          # Only if project has specific conventions
└── settings.json   # Only if hooks make sense for this stack
```

**Do NOT create empty directories.** If no commands are needed, don't create `commands/`.

---

## Step 4: Write Project CLAUDE.md

Create `.claude/CLAUDE.md` with content tailored to THIS project:

```markdown
# [Project Name]

**[One-line description of what this project does]**

---

## Project Context

**Tier**: [1/2/3] - [explanation]
**Stack**: [detected stack]
**Domain**: [what kind of project]

**Key constraints**:
- [Constraint 1 specific to this project]
- [Constraint 2 specific to this project]

---

## Coding Rules

[Rules that emerged from analyzing THIS codebase, not generic best practices]

### [Category 1]
- [Specific rule observed in codebase]
- [Another specific rule]

### [Category 2]
- [More specific rules]

---

## Commands

[Only list commands that were created for this project]

| Command | Purpose |
|---------|---------|
| `/command-name` | Why this command exists for this project |

---

## Methodology

KERNEL provides methodology banks for common workflows:
- `/plan` — Think before coding, using PLANNING-BANK methodology
- `/debug` — Systematic diagnosis, using DEBUGGING-BANK methodology
- `/review` — Correctness validation, using REVIEW-BANK methodology
- `/discover` — Map codebase, populate understanding

Banks are guides, not scripts. Adapt methodology to context.
```

---

## Step 5: Create Commands (Only If Needed)

**Before creating any command, ask**: "Would this project actually use this?"

**Good reasons to create a command:**
- Workflow is repeated 2+ times in this project
- Project has a specific multi-step process (deploy, release, test cycle)
- Team has requested automation for something

**Bad reasons to create a command:**
- "It might be useful someday"
- "Other projects have this"
- "The template includes it"

**When creating a command:**
- Write it specifically for this project's tools and structure
- Reference actual file paths and commands
- Include project-specific context

---

## Step 6: Create Rules (Only If Needed)

Rules capture preferences and patterns specific to this project.

**Only create rules for:**
- Explicitly stated preferences ("we use tabs", "no semicolons")
- Observed patterns that differ from defaults
- Non-negotiable constraints (security, compliance)

**Do NOT create rules for:**
- General best practices (those are assumed)
- Things that haven't been decided yet
- Preferences that can be inferred from tooling config

---

## Step 7: Configure Hooks (Only If Stack Benefits)

Hooks run automatically on tool use. Only configure if:
- Project has formatters/linters that should auto-run
- Project has validation that should happen on writes
- Stack has common automation patterns

**Example decision tree:**
- Python project with Black/Ruff → configure PostToolUse formatter hook
- Rust project with cargo fmt → configure PostToolUse formatter hook
- Markdown-only project → probably no hooks needed
- Project without tests → don't add test-running hooks

---

## Step 8: Report What Was Created

```
KERNEL initialized for [Project Name]

Detected:
  Tier: [tier] — [why]
  Stack: [stack]
  Domain: [domain]

Created:
  .claude/CLAUDE.md     — Project-specific configuration
  [.claude/commands/]   — [N commands, if any]
  [.claude/rules/]      — [N rules, if any]
  [.claude/settings.json] — [Hooks, if any]

Not created (not needed for this project):
  [List anything intentionally skipped and why]

Methodology available:
  /discover  — Map codebase
  /plan      — Planning methodology
  /debug     — Debugging methodology
  /review    — Review methodology

Next steps:
  1. Review .claude/CLAUDE.md and adjust if needed
  2. Use /discover if codebase is unfamiliar
  3. Work normally - patterns will emerge
```

---

## Anti-Patterns

- **DON'T copy-paste bank content** into CLAUDE.md - reference banks, don't duplicate
- **DON'T create generic commands** - every command should mention this project's specifics
- **DON'T assume conventions** - discover them from the codebase
- **DON'T create empty structures** - if nothing goes in a directory, don't create it
- **DON'T include irrelevant methodology** - no frontend rules for a CLI tool

---

## What Makes Good Project Config

**Specific**: References actual files, paths, and tools in this project
**Minimal**: Only includes what's actually used
**Grounded**: Rules based on observed patterns, not aspirations
**Honest**: Describes reality, admits what's not yet decided

See `sample-project/.claude/CLAUDE.md` for an example of well-tailored configuration.
