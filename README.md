# KERNEL

**Self-Evolving Configuration for Claude Code**

KERNEL is a Claude Code plugin that progressively builds your project configuration based on observed patterns. Instead of manually creating commands, agents, and rules, KERNEL watches how you work and suggests artifacts that automate your workflows.

## What KERNEL Does

When you work with Claude Code, patterns emerge:
- You repeat the same multi-step workflow
- You need specialized expertise for certain tasks
- You integrate external services
- You state preferences about how things should be done

KERNEL captures these patterns and creates the appropriate Claude Code artifacts:

| Pattern | Artifact Created |
|---------|------------------|
| Repeated workflow | `.claude/commands/workflow-name.md` |
| Specialized task | `.claude/agents/specialist-name.md` |
| External service | Entry in `.mcp.json` |
| Pre/post processing | Hook in `.claude/settings.json` |
| Domain capability | `.claude/skills/capability.md` |
| Explicit preference | `.claude/rules/topic.md` |

## Quick Start

### 1. Install the Plugin

**Via Plugin Menu (Recommended):**

1. In Claude Code, run `/plugin`
2. Navigate to **Marketplaces** tab
3. Select **+ Add Marketplace**
4. Enter: `https://github.com/ariaxhan/kernel-plugin`
5. Go to **Discover** tab and enable the KERNEL plugin

```
┌─ Add Marketplace ───────────────────────────────────────────────────────┐
│ Enter marketplace source:                                               │
│     https://github.com/ariaxhan/kernel-plugin                           │
╰─────────────────────────────────────────────────────────────────────────╯
```

**Programmatic (for teams):**

Add to `~/.claude/settings.json` or your project's `.claude/settings.json`:
```json
{
  "extraKnownMarketplaces": {
    "kernel-marketplace": {
      "source": { "source": "github", "repo": "ariaxhan/kernel-plugin" }
    }
  },
  "enabledPlugins": { "kernel@kernel-marketplace": {} }
}
```

See [SETUP.md](SETUP.md) for detailed installation instructions.

### 2. Initialize KERNEL in Your Project

```bash
cd your-project
claude

# Inside Claude Code, run:
/kernel-init
```

This analyzes your project and creates a customized `.claude/CLAUDE.md` with:
- Detected tier (T1 hackathon, T2 production, T3 critical)
- Stack-specific coding rules
- KERNEL artifact templates

### 3. Work Normally

As you work, KERNEL observes patterns and asks before creating artifacts:

```
"I noticed you've run this 3-step deployment workflow twice.
Should I create a /deploy command for it?"
```

## Features

### Knowledge Banks

KERNEL includes token-optimized methodology banks:

- **PLANNING-BANK** - Get-it-right-first-time methodology
- **DEBUGGING-BANK** - Systematic diagnosis and root cause fixing
- **DISCOVERY-BANK** - Codebase reconnaissance and pattern extraction
- **REVIEW-BANK** - Correctness, consistency, completeness validation
- **DOCUMENTATION-BANK** - Docs style selection, budgets, maintenance

Banks load on-demand via mode commands (~140 lines each, zero cost until used).

### Arbiter Context Compression

KERNEL includes **arbiter** - a propositional logic engine for mathematical context compression.

**Why Arbiter?**
- Conversations accumulate context that must eventually be compacted
- Traditional summarization loses precision and nuance
- Arbiter represents knowledge as logical facts, preserving exactness

**How It Works**:
1. Extract conversation facts in propositional logic format:
   ```
   use_python
   use_fastapi
   authenticated -> can_read
   admin & authenticated -> can_write
   ```

2. Compress via logical redundancy removal:
   - Removes tautologies (always-true statements)
   - Eliminates semantic redundancies
   - Validates consistency (no contradictions)

3. Result: **95% token reduction** with zero information loss

**Manual Usage**: `/arbiter-compact`

**Automatic Usage**: Enable PreCompact hook in `.claude/settings.json`:
```json
{
  "hooks": {
    "PreCompact": [{
      "matcher": "*",
      "hooks": [{
        "type": "prompt",
        "prompt": "Extract facts in arbiter syntax per .claude/rules/arbiter-syntax.md"
      }]
    }]
  }
}
```

When enabled, arbiter automatically compresses context before every compaction, allowing seamless infinitely-long conversations.

### Configuration Type Distinctions

**IMPORTANT**: See [CONFIG-TYPES.md](CONFIG-TYPES.md) for the complete guide on when to use each artifact type.

This is the **most critical resource** for understanding KERNEL. It includes:
- Decision tree for choosing the right artifact type
- Detailed comparison of agents vs skills vs commands vs rules
- Common confusion scenarios with examples
- Anti-patterns to avoid
- Validation checklist

**Read CONFIG-TYPES.md BEFORE creating any artifacts** to ensure you're using the right type for your use case.

### Artifact Types

**Commands** (`/command-name`)
```markdown
---
description: One-line description
allowed-tools: Read, Write, Bash
---
Instructions for Claude when /command-name is invoked.
```

**Agents** (Specialized sub-agents)
```markdown
---
name: agent-name
description: What it specializes in
tools: Read, Write, Grep, Glob, Bash
model: sonnet
---
You are a specialist in X. Your job is to...
```

**MCP Servers** (External integrations)
```json
{"mcpServers": {"name": {"command": "npx", "args": ["package-name"]}}}
```

**Hooks** (Pre/post processing)
```json
{"hooks": {"PostToolUse": [{"matcher": "Write", "hooks": [{"type": "command", "command": "prettier --write $CLAUDE_FILE_PATHS"}]}]}}
```

**Skills** (Domain capabilities)
Markdown files describing patterns and examples for specific domains.

**Rules** (User preferences)
Imperative rules grouped by topic that Claude follows.

### Included Commands

| Command | Description |
|---------|-------------|
| `/kernel-init` | Initialize KERNEL for any project |
| `/discover` | Map codebase, find tooling, extract conventions |
| `/plan` | Get-it-right-first-time planning mode |
| `/debug` | Systematic diagnosis and root cause fixing |
| `/review` | Correctness, consistency, completeness validation |
| `/docs` | Documentation audit, generation, maintenance |
| `/kernel-status` | Show config health and staleness report |
| `/kernel-prune` | Review and remove stale config entries |
| `/handoff` | Generate context handoff for session continuation |
| `/parallelize` | Set up git worktrees for parallel development |
| `/arbiter-compact` | Compress conversation context via propositional logic |

## Project Structure

```
kernel-plugin/
├── kernel/                    # Templates (copied to projects)
│   ├── banks/                 # Methodology banks
│   │   ├── PLANNING-BANK.md
│   │   ├── DEBUGGING-BANK.md
│   │   ├── DISCOVERY-BANK.md
│   │   ├── REVIEW-BANK.md
│   │   └── DOCUMENTATION-BANK.md
│   ├── commands/              # Mode commands
│   ├── hooks/                 # Hook templates
│   ├── rules/                 # Rule templates
│   └── state.md               # World model template
├── commands/                  # Plugin commands
├── docs/
│   └── documentation-files/   # Doc templates & scripts
├── CONFIG-TYPES.md            # Artifact type guide
├── README.md
└── SETUP.md
```

## Philosophy

KERNEL follows these principles:

1. **Conservative**: Only create artifacts for clear, repeated patterns
2. **Minimal**: Start simple, iterate later
3. **Ask First**: Confirm with user before creating if unsure
4. **Check Existing**: Read configs first to avoid duplicates

Configuration should grow organically from actual usage, not speculation.

## Config Lifecycle

KERNEL doesn't just add configuration - it also identifies stale entries for removal.

### Reference Tracking

When you use a command, agent, skill, or rule, KERNEL updates `memory/config_registry.jsonl`:
```json
{"type": "command", "name": "deploy", "created": "2025-01-01T00:00:00Z", "last_referenced": "2025-01-09T00:00:00Z", "reference_count": 12}
```

### Health Check

Run `/kernel:status` to see config health:
```
Config entries: 12
  Active (referenced last 7 days): 8
  Stale (no reference 30+ days): 3
  New (< 7 days old): 1
```

### Pruning

Run `/kernel:prune` to review stale entries:
```
STALE: [command] old-workflow
  Created: 2024-11-01
  Last referenced: 2024-12-01 (39 days ago)
  Reference count: 2

  Remove this entry? [Y/n/skip all]
```

- KERNEL never auto-deletes; always prompts for confirmation
- Entries flagged after 30 sessions with zero references
- Rejecting keeps the entry and resets its staleness timer
- All removals are logged for audit trail

## Requirements

- Claude Code CLI **v1.0.33+** (plugins require this version or later)
- Python 3.8+ (optional, for Claude Docs MCP server)

## Platform Support

KERNEL works on **macOS**, **Linux**, and **Windows**. The plugin installation method (`/plugin` menu) works the same on all platforms.

## License

MIT

## Contributing

Contributions welcome. Read `CONFIG-TYPES.md` before creating artifacts and review the banks in `kernel/banks/` for methodology.
