# Tear Down: Cross-Machine Portability

reviewed: 2026-03-13
tier: 2
scope: 7 files (common.sh, 4 hooks, tests, init.md)

## Big 5

| Check | Status | Notes |
|-------|--------|-------|
| input_validation | PASS | jq with defaults, env var validation |
| edge_cases | PASS | Handles missing dirs, missing DB, env override |
| error_handling | PASS | Intentional suppression for optional ops |
| duplication | PASS | Extracted to common.sh (was duplicated in 4 files) |
| complexity | PASS | Functions <15 lines |

## Security

| Check | Status |
|-------|--------|
| No hardcoded secrets | PASS |
| No eval usage | PASS |
| set -e in lifecycle hooks | PASS |
| SQL injection safe | PASS |
| Shell expansion safe | PASS |

## Testing

| Suite | Pass | Fail |
|-------|------|------|
| agentdb | 17 | 0 |
| edge | 4 | 0 |
| hooks | 9 | 0 |
| security | 6 | 0 |
| observe | 4 | 0 |
| verify | 7 | 0 |
| tokens | 6 | 0 |
| portable | 7 | 0 |
| **TOTAL** | **60** | **0** |

## Architecture

### Portability Strategy
```
Detection Order (common.sh):
1. $KERNEL_VAULTS env var (explicit override)
2. ~/Vaults/_meta/agentdb/agent.db (standard)
3. ~/Downloads/Vaults/_meta/agentdb/agent.db (fallback)
4. ~/Vaults (default if nothing found)
```

### File Structure
```
hooks/scripts/
├── common.sh          # Shared detection logic (NEW)
├── session-start.sh   # Sources common.sh
├── session-end.sh     # Sources common.sh
├── capture-error.sh   # Sources common.sh
└── pre-compact-commit.sh  # Sources common.sh
```

### Init Flow
1. Detect existing Vaults or create ~/Vaults
2. Find plugin in ~/.claude/plugins/cache
3. Symlink agentdb CLI to $VAULTS/.local/bin
4. Symlink kernel components for hooks
5. Optional: symlink ~/.claude for git sharing
6. Add to PATH
7. Initialize AgentDB

## Verdict: PROCEED

All tests pass. Duplication fixed. Cross-machine portability verified.

### What Works
- Hooks auto-detect Vaults location via common.sh
- KERNEL_VAULTS env override for custom setups
- init.md under token budget (116 lines)
- Test suite covers portability scenarios
- No hardcoded paths in hook scripts

### Action Items (None Required)
- [x] Extract Vaults detection to common.sh
- [x] Update all hooks to source common.sh
- [x] Add portability test suite
- [x] Trim init.md to <180 lines
- [x] Fix test that expected wrong agent location
