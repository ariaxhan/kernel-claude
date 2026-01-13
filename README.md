# KERNEL

**Project Intelligence for Claude Code**

KERNEL is a Claude Code plugin that creates tailored configuration for your project. It analyzes your codebase and builds configuration that fits - coding rules from your patterns, commands for workflows you repeat, hooks for tools you use. Methodology is applied automatically based on context.

---

## Why KERNEL?

Claude Code is powerful, but every project is different. KERNEL bridges this gap by:

1. **Analyzing your project** - stack, patterns, conventions
2. **Creating tailored config** - only what this project needs
3. **Applying methodology automatically** - no commands to remember
4. **Evolving over time** - configuration grows as patterns emerge

---

## Quick Start

### 1. Install the Plugin

```
/install-plugin https://github.com/ariaxhan/kernel-plugin
```

### 2. Initialize Your Project

```bash
cd your-project
claude

# Inside Claude Code:
/kernel-init
```

KERNEL analyzes your project and creates `.claude/CLAUDE.md` with:
- Project-specific coding rules
- Default behaviors for implementing, debugging, reviewing
- Commands tailored to your workflows (only if needed)

### 3. Work Normally

Methodology applies automatically:
- **Implementing a feature?** KERNEL plans and researches first
- **Fixing a bug?** KERNEL debugs systematically
- **Before completing?** KERNEL reviews for correctness

No commands to remember. Just work.

---

## Philosophy

### Automatic Methodology

KERNEL doesn't require you to type `/plan` or `/debug`. It detects context and applies the right approach:

| You're doing... | KERNEL automatically... |
|-----------------|-------------------------|
| Implementing new feature | Researches, plans, defines interfaces first |
| Fixing a bug | Reproduces, isolates, finds root cause |
| Refactoring | Understands deeply before changing |
| Completing work | Reviews against requirements |

### Tailored, Not Templated

Every artifact is created because your project needs it:

```
Good: "Created /test-all because this project has 4 test modules"
Bad:  "Created /test-all because the template includes it"
```

### Minimal Commands

Only 11 explicit commands exist. Everything else is automatic.

---

## Commands

### Setup
| Command | Purpose |
|---------|---------|
| `/kernel-init` | Initialize KERNEL for a project |
| `/kernel-user-init` | Set up user-level defaults |

### Pipelines
| Command | Purpose |
|---------|---------|
| `/build` | Full pipeline: idea → research → plan → implement → validate |
| `/docs` | Documentation mode |

### Git Workflow
| Command | Purpose |
|---------|---------|
| `/branch` | Create worktree for isolated work |
| `/ship` | Commit, push, create PR |
| `/parallelize` | Set up multiple worktrees |
| `/release` | Version bump, tag, push |

### Maintenance
| Command | Purpose |
|---------|---------|
| `/kernel-status` | Show config health |
| `/kernel-prune` | Remove stale config entries |
| `/handoff` | Generate session continuation brief |

---

## Knowledge Banks

KERNEL includes 10 methodology banks that apply automatically:

| Bank | When It Applies |
|------|-----------------|
| **PLANNING-BANK** | Before implementing features |
| **DEBUGGING-BANK** | When fixing bugs or errors |
| **RESEARCH-BANK** | Before writing new functionality |
| **REVIEW-BANK** | Before completing any task |
| **DISCOVERY-BANK** | First time in unfamiliar codebase |
| **ITERATION-BANK** | When refactoring or improving |
| **TEARITAPART-BANK** | Before implementing complex plans |
| **DOCUMENTATION-BANK** | When working on docs |
| **BUILD-BANK** | Full implementation pipeline |
| **CODING-PROMPT-BANK** | Core philosophy, tier requirements |

Banks are referenced automatically based on context. You don't invoke them.

---

## What Gets Created

### Always: `.claude/CLAUDE.md`

Your project's intelligence file:
- Project context (tier, stack, domain)
- Coding rules from your patterns
- Default behaviors for implementing/debugging/reviewing
- References to methodology banks

### Sometimes: Commands

Only for workflows this project repeats:

```markdown
# Example: /test-all (for a Python project with 4 test modules)
---
description: Run all pytest tests with coverage
---

Run: `pytest tests/ -v --cov=src`
```

### Sometimes: Hooks

Only if the stack benefits:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write",
      "hooks": [{
        "type": "command",
        "command": "if [[ \"$FILE_PATH\" == *.py ]]; then ruff format \"$FILE_PATH\"; fi"
      }]
    }]
  }
}
```

---

## Project Structure

```
kernel-plugin/
├── commands/              # 11 explicit commands
│   ├── kernel-init.md
│   ├── build.md
│   ├── ship.md
│   └── ...
├── kernel/
│   ├── banks/             # 10 methodology banks
│   │   ├── PLANNING-BANK.md
│   │   ├── DEBUGGING-BANK.md
│   │   └── ...
│   ├── rules/
│   │   └── methodology.md # Auto-detection rules
│   └── state.md
├── sample-project/        # Example showing KERNEL in action
├── CONFIG-TYPES.md        # When to use each artifact type
└── SETUP.md               # Detailed installation guide
```

---

## Example: Sample Project

`sample-project/` demonstrates KERNEL for a Python CLI:

```
sample-project/.claude/CLAUDE.md shows:
- Tier 1 classification
- Python-specific coding rules
- Default behaviors tailored to TaskMgr workflows
- 4 commands for TaskMgr-specific tasks
- Hooks for Black, Pylint, Mypy

Note what's automatic:
- Planning before implementing
- Debugging methodology when fixing
- Review before completing
```

---

## Configuration Types

| I want Claude to... | Create... |
|---------------------|-----------|
| Follow rules on all tasks | `.claude/CLAUDE.md` or `.claude/rules/` |
| Run workflow when I say `/name` | `.claude/commands/name.md` |
| Auto-run on file write | Hook in `.claude/settings.json` |
| Delegate to specialist | `.claude/agents/name.md` |
| Connect to external service | `.mcp.json` entry |

See [CONFIG-TYPES.md](CONFIG-TYPES.md) for the complete guide.

---

## How Automatic Methodology Works

KERNEL detects context from your messages and applies methodology:

**Signal detection:**
```
"implement", "add", "create" → Planning methodology
"bug", "error", "fix", "broken" → Debugging methodology
"improve", "refactor", "clean up" → Iteration methodology
"what could go wrong" → Critical review methodology
```

**Redundancy layers:**
1. `kernel/rules/methodology.md` - Detection rules
2. Project CLAUDE.md - Default behaviors
3. `kernel/banks/` - Deep methodology when needed

This means methodology is always applied, even if one layer is missing.

---

## Requirements

- Claude Code CLI **v1.0.33+**
- Python 3.8+ (optional, for arbiter)

Works on macOS, Linux, and Windows.

---

## License

MIT

---

## Author

Aria Han — [github.com/ariaxhan](https://github.com/ariaxhan)
