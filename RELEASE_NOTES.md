# KERNEL v1.5.0

**Automatic Methodology + Tailored Configuration**

This release makes KERNEL methodology automatic. No more typing `/plan` or `/debug` - KERNEL detects context and applies the right approach. Commands reduced from 19 to 11.

---

## Automatic Methodology

**The big change:** Methodology now applies based on context, not commands.

| You're doing... | KERNEL automatically... |
|-----------------|-------------------------|
| Implementing new feature | Researches, plans, defines interfaces first |
| Fixing a bug | Reproduces, isolates, finds root cause |
| Refactoring | Understands deeply before changing |
| Completing work | Reviews against requirements |

**Removed commands (now automatic):**
- `/plan` → Applied when implementing
- `/debug` → Applied when fixing bugs
- `/review` → Applied before completing
- `/research` → Applied before new functionality
- `/discover` → Applied in unfamiliar codebases
- `/iterate` → Applied when refactoring
- `/tearitapart` → Applied before complex implementations
- `/arbiter-compact` → Available as hook configuration

**Remaining commands (11):**
- Setup: `/kernel-init`, `/kernel-user-init`
- Pipelines: `/build`, `/docs`
- Git: `/branch`, `/ship`, `/parallelize`, `/release`
- Maintenance: `/kernel-status`, `/kernel-prune`, `/handoff`

## Redundancy Layers

Methodology applied through three layers (if one misses, others catch):

1. **`kernel/rules/methodology.md`** - Context detection rules
2. **Project CLAUDE.md** - Default behaviors section
3. **`kernel/banks/`** - Deep methodology when needed

## Default Behaviors in CLAUDE.md

`/kernel-init` now creates a "Default Behaviors" section:
- When Implementing New Features
- When Debugging
- When Refactoring
- Before Completing Any Task

## Philosophy Shift

KERNEL now explicitly:
- Uses banks as **methodology guides**, not copy-paste templates
- Only creates artifacts the specific project **actually needs**
- **Tailors everything** to the actual codebase patterns
- **Applies methodology automatically** based on task context

## Cleanup

- Removed 8 methodology commands (now automatic)
- Removed duplicate directories (`hooks/`, `rules/`, `state.md` at root)
- Removed outdated `BASELINE-*.md` design docs
- Consolidated `DOCUMENTATION-BANK.md` (now 643 lines)
- Net reduction: ~3000 lines removed

## Fixes

- Fixed `/kernel:init` → `/kernel-init` syntax across all docs
- Updated `/ship` command with release workflow

---

# KERNEL v1.4.0

**Bank Architecture Expansion + New Development Commands**

This release adds four major new commands with token-optimized methodology banks.

---

## New Commands

| Command | Description |
|---------|-------------|
| `/research` | Deep research phase - find existing solutions before writing code |
| `/build` | Full pipeline from idea to working code |
| `/iterate` | Continuous improvement for existing code |
| `/tearitapart` | Critical review before implementation |

## New Knowledge Banks

Token-optimized methodology banks (~100-150 lines each):

- **RESEARCH-BANK.md** - Find existing packages, document pitfalls, source diversity
- **BUILD-BANK.md** - Full pipeline: idea -> research -> plan -> review -> execute -> validate
- **ITERATION-BANK.md** - Deep understanding, improvement identification, prioritization
- **TEARITAPART-BANK.md** - Critical review checklists, issue documentation, recommendations

## Architecture: Slim Commands + Banks

Commands are now ~15-30 lines that reference methodology banks on-demand:
- **Before:** 300-500 line standalone commands (~4000 tokens per invocation)
- **After:** 15-30 line commands (~100 tokens) + banks loaded when needed (~1500 tokens)
- **Result:** 50-75% token reduction for most uses

## Token Math Example

```
/research invocation (old): ~4000 tokens (full 15KB command)
/research invocation (new): ~100 tokens (slim command)
  + ~1500 tokens (bank, if methodology needed)
  = ~1600 tokens total (60% reduction)
```

---

# KERNEL v1.0.0

**Self-Evolving Project Intelligence for Claude Code**

The first release of KERNEL - a Claude Code plugin that progressively builds your project configuration based on observed patterns instead of upfront speculation.

---

## What's Included

### Core Commands

| Command | Description |
|---------|-------------|
| `/kernel-init` | Initialize KERNEL in any project - analyzes stack, detects tier, creates customized CLAUDE.md |
| `/discover` | Map codebase, find tooling, extract conventions, populate state.md |
| `/plan` | Get-it-right-first-time planning methodology |
| `/debug` | Systematic diagnosis and root cause fixing |
| `/review` | Correctness, consistency, completeness validation |
| `/docs` | Documentation audit, generation, and maintenance |
| `/kernel-status` | Show config health and staleness report |
| `/kernel-prune` | Review and remove stale config entries |
| `/handoff` | Generate context handoff brief for session continuation |
| `/parallelize` | Set up git worktrees for parallel development |

### Knowledge Banks

Token-optimized methodology templates (~140 lines each):

- **PLANNING-BANK.md** - Mental simulation, interface definition first
- **DEBUGGING-BANK.md** - Reproduce → Isolate → Instrument → Root cause → Fix
- **DISCOVERY-BANK.md** - Reconnaissance, map terrain, extract conventions
- **REVIEW-BANK.md** - Correctness, convention adherence, invariants
- **DOCUMENTATION-BANK.md** - Style selection, budgets, maintenance system

Banks load on-demand (zero token cost until referenced via mode commands).

### Skills

Lightweight capability pointers (~50-100 tokens each):

- **worktree-parallelization** - Detect tasks suitable for git worktree parallel development

### Rules Templates

Starter templates for project-specific patterns:

- `preferences.md` - Formatting, presentation, tool choices
- `assumptions.md` - Extract assumptions before executing
- `invariants.md` - Non-negotiable contracts
- `patterns.md` - Discovered coding patterns
- `decisions.md` - Architecture decision log

### Configuration Reference

- **CONFIG-TYPES.md** - Complete guide on when to use Agents vs Skills vs Commands vs Rules vs Hooks vs MCP (decision tree, comparison table, anti-patterns)

### Sample Project

Included `sample-project/` with a TaskMgr CLI demonstrating KERNEL in action with:
- CSV export functionality
- Database optimization
- Encryption support
- API sync capabilities
- Full test suite

---

## Installation

### Via Plugin Menu (Recommended)

1. In Claude Code, run `/plugin`
2. Navigate to **Marketplaces** tab
3. Select **+ Add Marketplace**
4. Enter: `https://github.com/ariaxhan/kernel-plugin`
5. Go to **Discover** tab and enable the KERNEL plugin

### Programmatic

Add to `~/.claude/settings.json`:
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

---

## How It Works

### Philosophy

- **CORRECTNESS > SPEED** - One working implementation beats three debug cycles
- **INVESTIGATE BEFORE IMPLEMENT** - Search for existing patterns first
- **DETECT, THEN ACT** - Don't assume tooling exists, find it
- **PROTECT STATE** - Backup before mutation, confirm before deletion

### The Bank Architecture

Instead of loading 6000+ tokens of coding rules upfront, KERNEL uses:

1. **Banks** (~140 lines each) - Methodology templates, load on-demand
2. **Skills** (~50-100 tokens) - Lightweight pointers, auto-discovered
3. **Commands** (0 tokens until used) - On-demand workflow invocation
4. **State** (~70 lines) - Single source of truth, updated by modes

**Total baseline cost: ~200 tokens** (vs ~6000+ traditional approach)

### Pattern → Artifact Mapping

When patterns emerge during work, KERNEL creates the appropriate Claude Code artifact:

| Pattern | Artifact Created |
|---------|------------------|
| Repeated workflow | `.claude/commands/workflow-name.md` |
| Specialized task | `.claude/agents/specialist-name.md` |
| External service | Entry in `.mcp.json` |
| Pre/post processing | Hook in `.claude/settings.json` |
| Domain capability | `.claude/skills/capability.md` |
| Explicit preference | `.claude/rules/topic.md` |

---

## Requirements

- Claude Code CLI **v1.0.33+**
- Python 3.8+ (optional, for Claude Docs MCP server)

---

## Platform Support

Works on macOS, Linux, and Windows.

---

## Known Limitations

- `extraKnownMarketplaces` only works in interactive mode (not CI/headless)
- Banks are project-agnostic templates - fill slots as you learn your codebase
- Config registry tracking (`memory/config_registry.jsonl`) requires manual bootstrap for existing configs

---

## What's Next

Planned for future releases:
- More stack-specific banks (React, FastAPI, Go, Rust)
- Auto-detection of config staleness via hook integration
- Team preset configurations
- Integration with CI/CD for validation

---

## Contributing

Contributions welcome. Read `CONFIG-TYPES.md` before creating artifacts and follow the philosophy in `CLAUDE.md`.

---

## License

MIT

---

**Author**: Aria Han
**Repository**: https://github.com/ariaxhan/kernel-plugin
