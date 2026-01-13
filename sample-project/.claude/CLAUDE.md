# TaskMgr

**A simple CLI task manager demonstrating KERNEL in action.**

---

## What This Is

TaskMgr is a file-based task manager with:
- JSON storage (`tasks.json`)
- Priority levels and due dates
- Optional encryption for confidential tasks
- REST API sync capability

This project shows how KERNEL tailors Claude Code configuration to a specific project's needs - not by copying generic templates, but by creating project-specific rules, commands, and hooks.

---

## Project Context

**Tier**: 1 (hackathon-grade, ships fast)
**Stack**: Python 3.8+, no framework
**Domain**: CLI tool with local storage

**Key constraints**:
- Single-file architecture (`src/taskmgr.py`)
- JSON for persistence (no database)
- Environment variables for secrets
- Tests live in `tests/` with `test_` prefix

---

## Coding Rules (Tailored to TaskMgr)

These rules emerged from this project's patterns, not from a generic template:

### Python Style
- Type hints on all function signatures
- Docstrings for public functions only
- Line length: 100 chars (Black default for this project)
- Imports: stdlib first, then third-party, then local

### Data Handling
- All task data lives in `tasks.json`
- Backup before mutation: `shutil.copy2()` before writes
- UTC timestamps with timezone info: `datetime.now(timezone.utc)`
- Encrypted data stored as `{"encrypted": true, "data": "..."}`

### Error Handling
- User-facing errors to stderr with clear messages
- Return codes: 0 success, 1 user error, 2 system error
- Graceful degradation: sync failures don't block local operations

### Testing
- One test file per feature: `test_encryption.py`, `test_sync.py`, etc.
- Test files are self-contained (can run individually)
- Mock external dependencies (API server, encryption keys)

---

## Commands (Created for TaskMgr)

These commands were created because this project needed them, not because a template said to include them:

| Command | Why It Exists |
|---------|---------------|
| `/test-all` | TaskMgr has 4 test modules - needed one-liner to run all |
| `/export-tasks` | CSV export was a requested feature, wrapped as command |
| `/optimize-db` | Task ID gaps from deletions needed cleanup utility |
| `/generate-commit` | Team wanted conventional commits without remembering format |

**Not included**: `/deploy`, `/docker-build`, `/lint-fix` - TaskMgr doesn't need these.

---

## Hooks (Configured for Python Workflow)

Hooks in `settings.json` run automatically on file writes:

```
PostToolUse (Write on *.py):
  1. Black formatter (line-length 100)
  2. Pylint (fail under 7.0)
  3. Mypy type checking
  4. Auto-run tests if file is test_*.py
```

**Why these specific hooks?**
- Black: Team agreed on formatting standard
- Pylint 7.0 threshold: Catches real issues, ignores style nitpicks
- Mypy: Type hints are used, want to validate them
- Test auto-run: Faster feedback when editing tests

---

## How KERNEL Built This Configuration

1. **Analyzed the codebase**: Python CLI, JSON storage, test suite
2. **Detected patterns**: Formatting preferences, test structure, error handling style
3. **Created tailored artifacts**: Commands for THIS project's workflows, not generic ones
4. **Left out irrelevant configs**: No Docker, no CI/CD, no frontend tooling

This is what `/kernel-init` does: it reads YOUR project and creates configuration that fits, using KERNEL's banks as methodology guides - not as copy-paste templates.

---

## File Structure

```
sample-project/
├── src/
│   ├── taskmgr.py      # Main CLI (single file, ~400 lines)
│   └── api_server.py   # Mock REST API for sync testing
├── tests/
│   ├── test_encryption.py
│   ├── test_sync.py
│   ├── test_export.py
│   └── test_optimize.py
├── .claude/
│   ├── CLAUDE.md       # This file - project intelligence
│   ├── commands/       # 4 TaskMgr-specific commands
│   └── settings.json   # Python-specific hooks
├── docs/
│   ├── ARCHITECTURE.md
│   └── MIGRATION.md
└── tasks.json          # Data file (gitignored)
```

---

## What This Demonstrates

This sample project shows KERNEL's philosophy:

1. **Tailored, not templated**: Every config artifact exists because THIS project needs it
2. **Minimal surface area**: Only the commands and hooks that matter
3. **Project-aware rules**: Coding standards match actual codebase patterns
4. **Living documentation**: This file describes reality, not aspirations

Use this as a reference for how your own project's `.claude/CLAUDE.md` should look: specific, grounded, and useful.
