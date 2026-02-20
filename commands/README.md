# Commands

Invoked via `/kernel:<command>` in Claude Code.

| Command | Purpose |
|---------|---------|
| ingest | Universal entry — classify input, scope work, create contracts, orchestrate agents |
| validate | Pre-commit gate: types, lint, tests in parallel |
| ship | Commit, push, create PR (optionally release) |
| tearitapart | Critical review before implementing |
| branch | Create worktree for isolated development |
| handoff | Generate context brief for session continuity |

## Usage

```
/kernel:ingest     # Route any request through classification → scoping → execution
/kernel:validate   # Run all checks before committing
/kernel:ship       # Push and create PR
```

## Entry Point

**`/kernel:ingest` is the primary entry point.** It handles:
- Bug classification → debug pipeline
- Feature requests → research → plan → execute
- Refactoring → contract → surgeon
- Questions → research skill
- Verification → adversary

Other commands are specialized utilities for specific workflows.
