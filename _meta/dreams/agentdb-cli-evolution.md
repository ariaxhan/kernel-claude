# Dream: AgentDB CLI -- What should it become?

Generated: 2026-03-25
Status: OPEN -- awaiting selection

## Context

AgentDB is a ~960-line bash CLI (`orchestration/agentdb/agentdb`) backed by SQLite. 4 tables: `learnings` (18 rows), `context` (27 rows across contracts/checkpoints/verdicts), `errors` (0), `events` (telemetry). Plus `context_sessions` and `nodes` from migration 002.

Current command surface: 22 commands across 4 groups (core, graph tracking, telemetry, utilities). Session-start hook at `hooks/scripts/session-start.sh` calls `preflight`, `read-start`, then runs inline queries for top learnings, checkpoints, and contracts.

The CLI does two jobs: agent lifecycle (read-start/write-end/learn/contract/verdict) and human observability (status/metrics/health/export). The tension is that agents need structured data and humans need situational awareness.

---

## Q1: What creative new commands would make agentdb genuinely more useful?

### MINIMALIST

You have 22 commands. Agents use 5 of them. The rest are dead weight.

Kill `stats` (duplicate of `status`). Kill `recent` (it's `query` with training wheels). Kill `export` (nobody reads exported markdown files -- the DB IS the export). That's 3 commands deleted, zero functionality lost.

The one command worth adding: `agentdb wtf`. One command. Shows: last error, last failed verdict, last 3 learnings of type `failure`, and the active contract. That's everything a confused agent OR human needs. The "what just happened?" command. 6 lines of SQL, 20 lines of bash.

```
$ agentdb wtf
Last error: none
Last failure: "sqlite busy timeout in concurrent agent writes" (3 days ago)
Active contract: CR-20260325-auth-refactor (tier 2, 4 files)
Last verdict: FAIL -- "missing edge case for expired tokens"
```

**Effort:** 2 hours. Net negative lines (delete 3, add 1).

### MAXIMALIST

If we're building the memory system agents deserve, here's what that looks like:

**`agentdb timeline [--since 24h]`** -- Unified chronological view across ALL tables. Every checkpoint, learning, error, verdict, emit event -- interleaved by timestamp. This is `git log` for agent work. Right now you have to mentally stitch together 5 different query results. The timeline does it for you.

```
$ agentdb timeline --since 4h
16:42  [session]    session:start branch=feature/auth tier=2
16:43  [contract]   CR-20260325 -- "refactor auth middleware, 4 files"
16:45  [checkpoint] surgeon: "completed token validation extraction"
16:51  [learning]   pattern: "service layer needs explicit error types"
16:58  [verdict]    FAIL -- "missing expired token edge case"
17:02  [checkpoint] surgeon: "added expiry handling, retry 2/3"
17:08  [verdict]    PASS -- "all 12 assertions green"
17:09  [session]    session:end success=1 duration=27min
```

**`agentdb blame <learning-id>`** -- Trace a learning back to the session, contract, and verdict that created it. Like `git blame` but for institutional memory. "Why do we know this? What happened?"

**`agentdb drift`** -- Proactive health that runs BETWEEN sessions. Detects: learnings that contradict each other, contracts never closed (orphaned), error patterns that have no corresponding failure learning (unprocessed), DB growth rate trending toward bloat. Outputs a score 0-100 and specific remediation.

**`agentdb replay <session-id>`** -- Reconstruct the full narrative of a past session from its events. Useful for debugging why an agent session went sideways. Pulls from events + context + errors for that session window.

**`agentdb suggest`** -- Before session-start dumps context, predict what THIS session will need based on the git branch, recent errors, and active contracts. "You're on branch feature/auth. Last session failed on token expiry. 3 learnings are relevant. Here's your briefing."

**Effort:** 3-5 days. Adds ~400 lines. Requires `context_sessions` to actually be populated (currently underused -- sessions table has no data flowing in from hooks).

### PRAGMATIST

Ship 3 commands now. Defer 2 until evidence shows they're needed.

**Ship now:**

1. **`agentdb wtf`** -- The confused-agent escape hatch. Merge of last error + last fail verdict + active contract + recent failures. Agents can call this mid-session when they hit something unexpected. Humans can call it to understand what just happened. (2 hours)

2. **`agentdb timeline [N]`** -- Last N events across all tables, interleaved by timestamp. Start simple: just query all tables with UNION ALL, sort by ts. No filters, no flags. The `git log --oneline` of agentdb. (3 hours)

3. **`agentdb guide`** -- Print a context-aware cheat sheet. Not the full help text -- a decision tree: "If you're starting work: `read-start`. If something broke: `wtf`. If you learned something: `learn`. If you're done: `write-end`." This replaces bloating session-start with CLI education. (1 hour)

**Defer:**
- `blame` and `replay` -- need more session data before these are useful. Upgrade path: add when `context_sessions` has >50 rows.
- `drift` -- `preflight` + `health` cover 80% of this. Upgrade path: add when we see actual drift-related session-start failures in the error log.

**Delete now:** `stats` (subsumed by `status`), `recent` (subsumed by `timeline`).

**Tradeoffs:** No cross-table correlation yet (blame/replay). No predictive context (suggest). These become obvious next steps once timeline proves the unified-view pattern works.

**Effort:** 1 day total. Net +1 command (add 3, delete 2).

---

## Q2: How should session-start explain agentdb CLI usage?

### MINIMALIST

It shouldn't. Session-start's job is CONTEXT, not EDUCATION. The protocol block in `session-start.sh` (lines 88-153) already tells agents what to do: `read-start` on start, `write-end` on end, `learn` when discovered. That's the entire API surface an agent needs.

If an agent doesn't know what commands exist, it reads `agentdb help`. Done. Don't put a manual in the briefing. Put a one-liner: "Run `agentdb help` for available commands."

Delete the 65-line protocol block. Replace with 3 lines.

**Effort:** 30 minutes.

### MAXIMALIST

Session-start should be ADAPTIVE. Right now it dumps the same protocol block every session regardless of what the agent needs.

Build a `agentdb briefing` command that generates context-aware session-start output:
- If there's an active contract: lead with it, skip the decision tree
- If there are recent errors: lead with those, include relevant `learn` examples
- If the DB is empty: show the full onboarding guide with examples
- If learnings are stale (>30 days, 0 hits): suggest pruning
- Include inline command hints next to each context section: "3 recent failures (fix with: `agentdb learn failure 'what' 'evidence'`)"

The session-start hook becomes: `$AGENTDB briefing --profile $PROFILE`. One line. All the intelligence lives in agentdb, not in 150 lines of bash in the hook.

This also means the briefing is testable (`agentdb briefing` works standalone) and agents can re-brief mid-session.

**Effort:** 2-3 days. Moves ~80 lines from session-start.sh into agentdb. Net complexity neutral but much more maintainable.

### PRAGMATIST

Ship a middle ground: keep session-start lean, add `agentdb guide` as a standalone command, and add a single hint line.

**Change session-start.sh** (line 93): after the agentdb commands, add one line:
```
Stuck? Run: agentdb wtf | Commands: agentdb help
```

**Add `agentdb guide`** that prints a 10-line decision tree with examples:
```
$ agentdb guide
Starting work?     agentdb read-start
Something broke?   agentdb wtf
Learned something? agentdb learn failure "description" "evidence"
Done for now?      agentdb write-end '{"did":"X","next":"Y"}'
Want overview?     agentdb timeline 10
Full reference?    agentdb help
```

**Don't touch** the existing protocol block yet. It works. The guide is additive, not a rewrite.

**Tradeoff:** The protocol block is still static. But it's not broken -- it just isn't smart. Upgrade path: replace with `agentdb briefing` when we've validated the guide pattern and have data on what agents actually reference.

**Effort:** 1 hour.

---

## Q3: How do we track if agentdb itself is healthy?

### MINIMALIST

`preflight` already runs on every session start. `health` exists for manual checks. You don't need more monitoring for a SQLite file with 46 rows.

The only missing check: DB size. Add one line to `preflight`:
```bash
[ $(stat -f%z "$DB" 2>/dev/null || stat -c%s "$DB") -gt 10485760 ] && echo "preflight:bloat -- DB > 10MB"
```

That's it. When it's 10MB, you prune. Until then, stop monitoring a healthy patient.

**Effort:** 15 minutes.

### MAXIMALIST

AgentDB should track its own vital signs over time, not just point-in-time checks.

**`agentdb vitals`** -- Self-monitoring dashboard:
- **Growth rate:** DB size over last 10 sessions. Trend line. Alert if doubling per week.
- **Learning decay:** % of learnings with 0 hits and age >14 days. High decay = learnings aren't useful.
- **Contract lifecycle:** avg time from contract create to close/verdict. Orphan rate (contracts with no verdict).
- **Error-to-learning ratio:** errors recorded vs failure learnings. Low ratio = agents aren't learning from errors.
- **Schema drift score:** compare runtime schema against `schema.sql` canonical definition. Any delta = drift.
- **Checkpoint freshness:** time since last write-end. If >7 days, the system isn't being used.

Store vitals in the `events` table (category: 'vitals'). Query them over time. This turns agentdb from a passive store into a self-aware system.

Add a `preflight` check: if vitals haven't been recorded in 7 days, emit a warning. If learning decay >60%, suggest `prune`.

**Effort:** 3-4 days. ~200 lines. Requires vitals to be emitted consistently (hook integration).

### PRAGMATIST

Ship 3 concrete checks in `preflight`. Defer the dashboard.

**Add to `cmd_preflight` now:**

1. **Bloat check:** DB size > 5MB triggers warning. Current DB is 192K so this gives massive runway.
2. **Orphan contracts:** contracts older than 48 hours with no verdict. These are forgotten work.
3. **Stale learnings ratio:** if >50% of learnings have 0 hits and are >14 days old, suggest pruning.

```
preflight:bloat -- agent.db is 6.2MB (consider: agentdb prune all)
preflight:orphan_contracts -- 2 contracts with no verdict (>48h old)
preflight:stale_learnings -- 12/18 learnings never reinforced (67%)
```

These are cheap (3 SQL queries), run every session, and catch the actual problems: bloat, forgotten contracts, and useless learnings.

**Defer:** Time-series vitals, growth rate trending, error-to-learning ratio. These need more data to be meaningful. Upgrade path: add `agentdb vitals` when the DB has >100 sessions of data.

**Tradeoff:** No trending. You see the current state, not the trajectory. But at 192K and 46 rows, trajectory doesn't matter yet.

**Effort:** 2 hours.

---

## Summary Table

| Question | Minimalist | Pragmatist | Maximalist |
|----------|-----------|------------|------------|
| Q1: New commands | `wtf` only, delete 3 | `wtf` + `timeline` + `guide`, delete 2 | 5 new commands (timeline, blame, drift, replay, suggest) |
| Q2: Session-start | 3-line replacement | Add hint line + standalone `guide` | Adaptive `briefing` command replaces hook logic |
| Q3: Health tracking | 1-line size check in preflight | 3 checks in preflight (bloat, orphans, stale) | Full `vitals` dashboard with trending |
| Total effort | ~3 hours | ~1.5 days | ~8-12 days |
| Lines changed | Net negative | Net +80 | Net +600 |

---

**This dream is OPEN.** Pick a perspective, mix them, or argue with them. Then: `/kernel:forge` to build, or `/kernel:ingest` for guided execution.
