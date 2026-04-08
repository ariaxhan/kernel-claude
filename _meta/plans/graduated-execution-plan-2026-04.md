# Execution Plan: 5 Graduated Hypotheses

**Date:** 2026-04-08
**Scope:** H078, H080, H093, H094, H101
**Tier:** 2 (5 files modified in agentdb CLI + hooks)
**Branch:** feature/graduated-hypothesis-execution

---

## Implementation Groups

### Group A: AgentDB Retrieval Overhaul (H078 + H080)
**Files:** `orchestration/agentdb/agentdb` (cmd_read_start function, lines 264-319)
**What:** Replace all-or-nothing read-start with WEIGHTED-75 graduated retrieval + memory cap

**Current behavior (lines 264-319):**
- Loads 5 recent failures (by timestamp)
- Loads 5 top patterns (by hit_count then timestamp)
- Loads 5 top gotchas (by hit_count then timestamp)
- Loads 5 recent errors
- Total: ~20 items, but misses 84% of high-value learnings

**New behavior:**
```
read-start [--full|--summary|--tiered]
  Default (no flag): WEIGHTED-75
    Score = (hit_count * 10) + (is_failure * 50) + (recency_7d * 10) + (recency_14d * 5)
    Load top 75 by score
    Cap at ~4,000 tokens (insight only, skip evidence unless --full)
    
  --summary: Top 10 by score (~400 tokens)
  --full: All learnings (current behavior, ~23K tokens)
  --tiered: Hot (hit>5) + Warm (all failures) + Cold (last 7 days) (~8K tokens)
```

**Specific changes to cmd_read_start():**
1. Add mode parameter parsing (default/--summary/--full/--tiered)
2. Replace 4 separate LIMIT 5 queries with single WEIGHTED query
3. Increase failure bonus from implicit to explicit 50-point weight
4. Add section headers that indicate mode: `## Context (weighted-75, ~3.4K tokens)`
5. Preserve error replay detection (lines 291-311) — this is valuable
6. Preserve contract + checkpoint loading (lines 313-318)

**Acceptance criteria:**
- Default mode loads ~75 items at ~3,400 tokens
- 84%+ failure coverage preserved
- `--summary` mode under 500 tokens
- `--full` mode backward-compatible with current behavior
- hit_count still updated for loaded learnings

---

### Group B: Session Tracking Fix (H094)
**Files:** `hooks/scripts/session-start.sh` (line 341), `orchestration/agentdb/agentdb` (cmd_emit, line 861)
**What:** Generate and propagate session_id

**Root cause (line 341 of session-start.sh):**
```bash
"$AGENTDB" emit session "session:start" "" "{...}" "" "" 2>/dev/null &
#                                                    ^^ empty session_id
```

**Fix:**
1. In `session-start.sh`: Generate session_id at top: `KERNEL_SESSION_ID="sess-$(date +%Y%m%d%H%M%S)-$$"`
2. Export it: `export KERNEL_SESSION_ID`
3. Pass to emit: `"$AGENTDB" emit session "session:start" "" "{...}" "" "$KERNEL_SESSION_ID"`
4. Write to a file for other hooks: `echo "$KERNEL_SESSION_ID" > "$PROJECT_ROOT/_meta/.session_id"`

5. In all other hooks (guard-bash, detect-secrets, etc.): Read session_id:
   ```bash
   SESSION_ID=$(cat "$PROJECT_ROOT/_meta/.session_id" 2>/dev/null || echo "")
   ```
   Pass as 6th arg to `agentdb emit`

**Acceptance criteria:**
- Every event has non-NULL session_id after fix
- session_id persists across hooks within same session
- session_id changes on new session-start
- Per-session queries now return meaningful results

---

### Group C: Coordination-Aware Adversary (H093 + H101)
**Files:** `agents/adversary.md`, `CLAUDE.md` (adversary section)
**What:** Expand adversary scope from code-only to coordination + code, increase activation

**Current adversary (agents/adversary.md):**
- Reviews code diffs for quality, security, performance
- 80% confidence threshold
- Only triggered for tier 3 contracts

**Changes:**

1. **Expand scope** — Add coordination checks to adversary.md:
   ```
   ## Coordination Verification (NEW — H093)
   Before code review, verify coordination integrity:
   - [ ] File overlap: Did multiple agents touch the same files? (check git diff per agent branch)
   - [ ] Claim verification: Did agents claim completion? Verify output files exist.
   - [ ] Scope drift: Did agents modify files outside their contract constraints?
   - [ ] Duplicate work: Search for identical changes across agent branches.
   
   Weight: Coordination issues are 4.3x more impactful than code issues.
   If coordination check fails, STOP code review — fix coordination first.
   ```

2. **Lower activation threshold** — In CLAUDE.md tier rules:
   ```
   Current: tier 3 only → adversary
   New: tier 2+ → adversary (coordination checks)
         tier 3 → adversary (coordination + code)
   ```

3. **Add coordination verdict type** — In agentdb:
   ```bash
   agentdb verdict coordination-pass|coordination-fail <evidence>
   ```

**Acceptance criteria:**
- Adversary fires on all tier 2+ contracts (not just tier 3)
- Coordination checks run BEFORE code review
- Activation rate increases from 16.7% to >50% of sessions with contracts
- Coordination failures caught proactively (before merge, not after incident)

---

## Execution Order

1. **Group B first** (H094 session tracking) — 2 files, enables measurement of Groups A and C
2. **Group A second** (H078+H080 retrieval) — 1 file, biggest token savings
3. **Group C third** (H093+H101 adversary) — 2 files, biggest quality improvement

**Estimated effort:** ~45 min total (Group B: 10 min, Group A: 20 min, Group C: 15 min)

---

## Risk Assessment

| Change | Risk | Mitigation |
|--------|------|-----------|
| Read-start overhaul | Missing critical context | --full flag preserves current behavior as escape hatch |
| Session ID generation | ID collision | PID + timestamp + random is unique enough |
| Session ID file | Stale across sessions | session-start.sh overwrites on each start |
| Adversary activation increase | Slower tier 2 execution | Coordination checks are fast (file list comparison, not code review) |
| Failure bonus increase (20→50) | Over-weighting old failures | Recency bonus counterbalances; 14-day decay prevents stale failures from dominating |

---

## Validation

After implementation, run:
```bash
# Group B: Verify session tracking
agentdb emit session "test" "" "{}" "" ""
agentdb query "SELECT session_id FROM events ORDER BY id DESC LIMIT 1;"
# Should return non-NULL

# Group A: Compare token output
agentdb read-start | wc -c          # Should be ~13,600 chars (~3,400 tokens)
agentdb read-start --full | wc -c   # Should be ~94,000 chars (~23,500 tokens)
agentdb read-start --summary | wc -c # Should be ~1,600 chars (~400 tokens)

# Group C: Verify adversary scope
grep -c "Coordination" agents/adversary.md  # Should be >0
```
