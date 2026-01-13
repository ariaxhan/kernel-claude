# KERNEL

**Project Intelligence for Claude Code**

KERNEL is a Claude Code plugin that creates tailored configuration for your project. Instead of copy-pasting generic templates, KERNEL analyzes your codebase and builds configuration that actually fits - commands for workflows you repeat, rules for patterns you follow, hooks for tools you use.

---

## Why KERNEL?

Claude Code is powerful out of the box, but every project is different:
- A Python CLI needs different tooling than a React app
- A production API needs stricter rules than a hackathon project
- Your deploy workflow isn't the same as anyone else's

KERNEL bridges this gap by:
1. **Analyzing your project** - stack, patterns, conventions
2. **Creating tailored config** - only what this project needs
3. **Providing methodology** - banks of knowledge for planning, debugging, reviewing
4. **Evolving over time** - configuration grows as patterns emerge

---

## Quick Start

### 1. Install the Plugin

In Claude Code, run:
```
/plugin
```

Navigate to **Marketplaces** → **+ Add Marketplace** and enter:
```
https://github.com/ariaxhan/kernel-plugin
```

Then go to **Discover** and enable the KERNEL plugin.

### 2. Initialize Your Project

```bash
cd your-project
claude

# Inside Claude Code:
/kernel-init
```

KERNEL will analyze your project and create `.claude/CLAUDE.md` with:
- Project-specific coding rules
- Commands tailored to your workflows (only if needed)
- Hooks for your stack's tools (only if beneficial)

### 3. Use Methodology Banks

When you need structured thinking:

| Command | When to Use |
|---------|-------------|
| `/plan` | Before implementing something complex |
| `/debug` | When systematically diagnosing an issue |
| `/review` | When validating correctness of changes |
| `/discover` | When exploring an unfamiliar codebase |
| `/research` | Before writing code, find existing solutions |
| `/build` | Full pipeline from idea to working code |
| `/iterate` | Improving existing code systematically |
| `/tearitapart` | Critical review before implementation |

---

## Philosophy

### Tailored, Not Templated

KERNEL never just copies files. Every artifact is created because your project needs it:

```
Good: "Created /test-all because this project has 4 test modules"
Bad:  "Created /test-all because the template includes it"
```

### Minimal Surface Area

Less is more. KERNEL only creates:
- Commands for workflows you actually repeat
- Rules for patterns that differ from defaults
- Hooks for tools the project actually uses

If something isn't needed, it doesn't exist.

### Banks as Guides, Not Scripts

Knowledge banks contain methodology, not procedures to execute blindly:

```
PLANNING-BANK teaches:
- "Simulate execution mentally before coding"
- "Define interfaces before implementations"
- Not: "Step 1: Create file X. Step 2: Write function Y."
```

You adapt the methodology to your context.

### Progressive Evolution

Configuration grows organically:
1. Start minimal (just CLAUDE.md)
2. Notice repeated workflows → create commands
3. Discover patterns → codify as rules
4. Set up automation → add hooks

Don't front-load decisions. Let patterns emerge.

---

## What Gets Created

### Always: `.claude/CLAUDE.md`

Your project's intelligence file:
- Project context (tier, stack, domain)
- Coding rules specific to this codebase
- Commands that exist and why
- Methodology references

### Sometimes: Commands

Only created for workflows this project actually uses:

```markdown
# Example: /test-all (created for a Python project)
---
description: Run all pytest tests with coverage
allowed-tools: Bash
---

Run the test suite for this project:
1. Execute: `pytest tests/ -v --cov=src`
2. Report coverage summary
3. If tests fail, show failure details
```

### Sometimes: Hooks

Only configured if the stack benefits:

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

### Sometimes: Rules

Only for project-specific patterns:

```markdown
# .claude/rules/api-conventions.md

All API endpoints in this project:
- Return JSON with `{data, error, meta}` envelope
- Use HTTP status codes correctly (201 for create, 204 for delete)
- Include request-id header for tracing
```

---

## Knowledge Banks

KERNEL includes 10 methodology banks (~100-150 lines each):

| Bank | Purpose |
|------|---------|
| **PLANNING-BANK** | Think before coding - mental simulation, interface-first design |
| **DEBUGGING-BANK** | Reproduce → Isolate → Instrument → Root cause → Fix |
| **DISCOVERY-BANK** | Map unfamiliar codebases - reconnaissance methodology |
| **REVIEW-BANK** | Validate correctness, consistency, completeness |
| **DOCUMENTATION-BANK** | Docs style selection, budgets, maintenance system |
| **RESEARCH-BANK** | Find existing solutions before writing code |
| **BUILD-BANK** | Full pipeline: research → plan → review → execute → validate |
| **ITERATION-BANK** | Systematic improvement of existing code |
| **TEARITAPART-BANK** | Critical review before implementation |
| **CODING-PROMPT-BANK** | Core philosophy and tier-based requirements |

Banks load on-demand via commands. Zero token cost until used.

---

## Commands Reference

### Initialization
| Command | Purpose |
|---------|---------|
| `/kernel-init` | Initialize KERNEL for a project |
| `/kernel-user-init` | Set up user-level defaults (~/.claude/) |

### Methodology
| Command | Purpose |
|---------|---------|
| `/discover` | Map codebase, extract conventions |
| `/plan` | Get-it-right-first-time planning |
| `/debug` | Systematic diagnosis |
| `/review` | Correctness validation |
| `/research` | Find existing solutions |
| `/build` | Full implementation pipeline |
| `/iterate` | Continuous improvement |
| `/tearitapart` | Critical pre-implementation review |
| `/docs` | Documentation mode |

### Git Workflow
| Command | Purpose |
|---------|---------|
| `/branch` | Create worktree for isolated work |
| `/ship` | Push and create PR |
| `/parallelize` | Set up multiple worktrees |
| `/release` | Version bump, tag, push |
| `/handoff` | Generate context for session continuation |

### Maintenance
| Command | Purpose |
|---------|---------|
| `/kernel-status` | Show config health |
| `/kernel-prune` | Remove stale config entries |
| `/arbiter-compact` | Compress conversation context |

---

## Project Structure

```
kernel-plugin/
├── commands/              # Plugin commands
│   ├── kernel-init.md
│   ├── discover.md
│   ├── plan.md
│   └── ...
├── kernel/
│   ├── banks/             # Methodology banks
│   │   ├── PLANNING-BANK.md
│   │   ├── DEBUGGING-BANK.md
│   │   └── ...
│   ├── rules/             # Rule templates
│   ├── hooks/             # Hook templates
│   ├── tools/             # Arbiter compression engine
│   └── state.md           # State template
├── sample-project/        # Example showing KERNEL in action
├── CONFIG-TYPES.md        # When to use each artifact type
├── SETUP.md               # Detailed installation guide
└── README.md              # This file
```

---

## Example: Sample Project

`sample-project/` demonstrates KERNEL configuration for a Python CLI:

```
sample-project/.claude/CLAUDE.md shows:
- Tier 1 (hackathon) classification
- Python-specific coding rules (type hints, error handling)
- 4 commands tailored to TaskMgr workflows
- Hooks for Black, Pylint, Mypy

Note what's NOT included:
- No Docker commands (project doesn't use Docker)
- No frontend rules (it's a CLI)
- No generic "best practices" (only project-specific patterns)
```

This is what good KERNEL config looks like: specific, minimal, grounded.

---

## Configuration Types

Before creating artifacts, understand when to use each type:

| I want Claude to... | Create... |
|---------------------|-----------|
| Follow rules on all tasks | `.claude/CLAUDE.md` or `.claude/rules/` |
| Run workflow when I say `/name` | `.claude/commands/name.md` |
| Auto-run on file write/commit | Hook in `.claude/settings.json` |
| Delegate to specialist sub-agent | `.claude/agents/name.md` |
| Learn how to do something | `.claude/skills/name/SKILL.md` |
| Connect to external service | `.mcp.json` entry |

See [CONFIG-TYPES.md](CONFIG-TYPES.md) for the complete decision guide.

---

## Requirements

- Claude Code CLI **v1.0.33+**
- Python 3.8+ (optional, for arbiter compression)

Works on macOS, Linux, and Windows.

---

## Contributing

Contributions welcome. Before creating artifacts:
1. Read [CONFIG-TYPES.md](CONFIG-TYPES.md)
2. Review existing banks in `kernel/banks/`
3. Check `sample-project/` for style reference

---

## License

MIT

---

## Author

Aria Han — [github.com/ariaxhan](https://github.com/ariaxhan)
