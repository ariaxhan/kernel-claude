# Dream: Instrumentation + Compression Resilience

**Date:** 2026-04-07
**Winner:** Pragmatist (integrity: 0.72, council-fixed)
**Status:** APPROVED — proceeding to implementation

## Decision

Phased approach: instrument today (Phase 1), experiment next session (Phase 2).

### Phase 1 — Instrument (~3 hours, 4-5 files)
1. Fix duration — use `context_sessions.started_at`, compute delta at session-end
2. Fix token tracking — `wc -c` on context snapshot, ±20% margin documented
3. Add retention scoring — bash-native key-term grep (not Python port)
4. New `compaction_events` table — tokens_before, tokens_after, retention_score
5. Fix cost — parse session token data into `context_sessions.tokens_used`

### Phase 2 — Experiment (next session, ~4 hours)
6. Baseline: 3+ sessions, stratified by type (research/build/forge)
7. Test GCC hash+intent approach (50 tokens vs 500)
8. Test claude-remember staging→recent→archive pipeline
9. Test context-engineering-toolkit priority assembly

### Council Fixes Applied
- Duration from DB timestamps, not temp files
- Bash-native retention scoring, not Python port
- Stratified baseline (min 2 per session type)
- ±20% token estimation margin documented

## Shattered Approaches
- **Minimalist** (0.45): Token estimation too inaccurate, `/usage` scraping fragile, no cost coverage
- **Maximalist** (0.55): Per-tool hooks add latency, 2-day build delay, scope creep, autonomous compression dangerous

## External Repos (in CodingVault/external/)
- claude-mem, claude-remember, git-context-controller, headroom, palinode
- mcp-handoff-server, agent-context-protocol, engram, context-engineering-toolkit, gsd-2
