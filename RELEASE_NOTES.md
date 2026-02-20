# v5.5.0 - Unified Entry Point

## What's New

### `/kernel:ingest` is now the universal entry point

Consolidated `/kernel:build` and `/kernel:contract` into `/kernel:ingest`. One command to rule them all:

- **Classify** — Detect bug/feature/refactor/question from input signals
- **Scope** — Count affected files, determine tier (1/2/3)
- **Contract** — Create work agreement for Tier 2+ (multi-file work)
- **Orchestrate** — Spawn surgeon and/or adversary agents as needed

### Streamlined command set (6 total)

| Command | Purpose |
|---------|---------|
| `/kernel:ingest` | Universal entry — classify, scope, contract, orchestrate |
| `/kernel:validate` | Pre-commit: types, lint, tests |
| `/kernel:ship` | Commit, push, PR |
| `/kernel:tearitapart` | Critical review |
| `/kernel:branch` | Worktree creation |
| `/kernel:handoff` | Context handoff |

### Documentation consistency

- All commands now properly prefixed with `kernel:`
- Removed orphaned migration file (001_init.sql)
- Fixed ghost references to non-existent files/commands
- Added `commands/README.md` for discoverability

## Upgrade

No breaking changes. If you were using `/kernel:build` or `/kernel:contract`, use `/kernel:ingest` instead.

---

# v5.4.0 - Hooks + Article Alignment

## What's New

### Hooks (Now Included!)
- **SessionStart**: Outputs git state, KERNEL philosophy, and runs `agentdb read-start`
- **PostToolUseFailure**: Automatically captures tool errors to the errors table

### AgentDB Improvements
- `agentdb read-start` now shows **Recent Errors** alongside failures, patterns, contracts, and checkpoints
- Install prompt now copies CLAUDE.md to your project's `.claude/` directory

### Article Alignment
This release aligns the plugin with the Medium article: *I Replaced Endless AI-Generated Markdown With One SQLite DB*

## Install

```
/install-plugin https://github.com/ariaxhan/kernel-claude
```

Then paste the full install prompt from the README.
