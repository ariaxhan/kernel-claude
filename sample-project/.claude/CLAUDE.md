# TaskMgr

**A simple CLI task manager demonstrating KERNEL in action.**

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

These rules emerged from this project's patterns:

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

## Default Behaviors

These apply automatically based on task context:

### When Adding Features to TaskMgr
1. Check if feature fits the "simple CLI" philosophy
2. Research existing Python patterns (argparse, JSON handling)
3. Plan where new code goes (likely extending taskmgr.py)
4. Write tests alongside implementation

### When Debugging TaskMgr
1. Reproduce with specific command: `python src/taskmgr.py [args]`
2. Check `tasks.json` for data corruption
3. Verify environment variables if encryption/sync involved
4. Add temporary logging, don't commit debug code

### When Refactoring
1. Run full test suite first: `python -m unittest discover tests/`
2. Make one change, run tests, commit
3. Target: fewer lines, same functionality

### Before Completing
1. Run `python -m black src/ --line-length 100`
2. Run `python -m pylint src/taskmgr.py`
3. Run all tests
4. Update README if behavior changed

---

## Commands (Created for TaskMgr)

| Command | Purpose |
|---------|---------|
| `/test-all` | Run all 4 test modules with verbose output |
| `/export-tasks` | Export tasks to CSV format |
| `/optimize-db` | Reindex task IDs to remove gaps |
| `/generate-commit` | Create conventional commit message from changes |

**Not included**: `/deploy`, `/docker-build` - TaskMgr doesn't need these.

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

---

## KERNEL Reference

**Banks** (auto-applied based on context):
- `PLANNING-BANK.md` — Used when adding new features
- `DEBUGGING-BANK.md` — Used when fixing issues
- `REVIEW-BANK.md` — Used before completing tasks

**Explicit commands** (when needed):
- `/build` — Full pipeline for larger features
- `/branch`, `/ship` — Git workflow

---

## What This Demonstrates

1. **Tailored rules**: Python style specific to TaskMgr, not generic "best practices"
2. **Automatic methodology**: No need to type `/plan` - planning happens when implementing
3. **Minimal commands**: Only 4 commands, each exists for a specific TaskMgr workflow
4. **Context-aware hooks**: Python tooling runs automatically on Python files
