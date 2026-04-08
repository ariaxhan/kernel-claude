# OSS Experiment Synthesis — Consolidated Hypotheses

**Date:** 2026-04-07
**Status:** HYPOTHESES SEEDED, EXPERIMENTS DESIGNED
**Sources:** 4 parallel research agents (39 OSS projects analyzed total)
**New hypotheses:** H078-H091 (14 total)
**Updated verdicts:** H070-H077 (3 refuted, 4 confirmed, 1 partial)

---

## H070-H077 Verdicts (Plugin Gap Experiments)

| ID | Plugin | Verdict | Action |
|----|--------|---------|--------|
| H070 | security-guidance | REFUTED | Kernel has 4 hooks + skill + reviewer. Adopt: add 9 code vuln patterns to existing hooks |
| H071 | hookify | CONFIRMED | Markdown-based hook rules are genuinely missing. Adopt: markdown rule interpreter |
| H072 | code-review | PARTIAL | Git blame analyzer + parallel perspectives are new. Kernel reviewer is deeper |
| H073 | claudetop/ccusage | CONFIRMED | Zero cost visibility. Install claudetop or build lightweight tracker |
| H074 | ralph-wiggum | REFUTED | Forge is heavier because it's better. Ralph trades quality for simplicity |
| H075 | mcp-knowledge-graph | CONFIRMED | AgentDB stores operations, not relationships. Add entity-relation + FTS5 |
| H076 | plugin-dev | CONFIRMED | No plugin creation tooling. Install alongside, don't absorb |
| H077 | feature-dev | REFUTED | Kernel ingest + forge + workflows cover all 7 phases with greater depth |

---

## New Hypotheses (H078-H091)

### AgentDB & Context Management

**H078 -- Graduated AgentDB retrieval reduces context tokens by 60%+**
Source: Git Context Controller (5-level retrieval), Claude-Mem (3-layer progressive disclosure), GitAgent (working/archive layers)
Statement: Adding `--summary`, `--last N`, `--decisions`, `--full` modes to `agentdb read-start` reduces context injection by 60%+ while maintaining session continuity.
Pass: Summary mode <100 tokens. Last-5 mode <500 tokens. No increase in "context not found" re-queries.
Fail: Summary mode misses critical context in >20% of sessions.
Evidence needed: Measure current read-start token count, implement modes, compare.
Effort: Medium (add query modes to agentdb CLI)

**H079 -- Decision capture prevents re-exploring rejected approaches**
Source: Git Context Controller (`note` field), GSD-2 (DECISIONS.md)
Statement: Adding `agentdb learn decision '{chose, rejected, reason}'` eliminates repeated exploration of already-rejected alternatives.
Pass: Over 10 sessions, zero re-explorations of rejected approaches. Decisions queryable.
Fail: Overhead >30s/session, or decisions never consulted.
Evidence needed: Implement, track over 10 sessions.
Effort: Low (add type to agentdb learn)

**H080 -- Working memory cap prevents context bloat without losing critical context**
Source: GitAgent (200-line MEMORY.md cap)
Statement: Enforcing a cap (200 items or 2000 tokens) on `agentdb read-start` forces better information hygiene.
Pass: Sessions start faster. No increase in context-not-found errors.
Fail: Cap causes critical context loss in >10% of sessions.
Evidence needed: Measure current load size, enforce cap, monitor miss rate.
Effort: Low (enforce in read-start script)

**H081 -- AgentDB pruning prevents performance degradation over 100+ sessions**
Source: Git Context Controller (`--prune-index N`), GitAgent (archive rotation)
Statement: Automatic pruning (keep last N learnings, archive old sessions) prevents query slowdown.
Pass: After 100+ sessions, read-start completes in <200ms. Pruned content accessible via archive.
Fail: Pruning removes information later needed (false pruning).
Evidence needed: Measure current query latency, implement pruning, measure again.
Effort: Low (add prune command)

### Compression & Token Efficiency

**H082 -- Content-type-aware compression saves >20% tokens per session**
Source: Headroom (7 content types, specialized compressors, 26-54% savings)
Statement: Applying regex-based content detection + type-specific compression to tool outputs reduces token consumption >20%.
Pass: Measure tokens before/after on 10 real sessions. >20% reduction, no re-invocations.
Fail: <10% savings, or task quality degrades.
Evidence needed: Port Headroom's content_detector pattern, measure on real sessions.
Effort: Medium (implement content router + compressors)

**H083 -- Waste signal detection identifies >10% compressible tokens in typical tool outputs**
Source: Headroom (HTML, base64, whitespace, JSON detection)
Statement: Regex-only detection of waste signals (HTML noise, base64 blobs, excessive whitespace, large JSON) finds >10% compressible content.
Pass: Sample 50 tool outputs. >10% average waste detected.
Fail: Tool outputs already clean (<5% waste).
Evidence needed: Build regex detector, run on real tool outputs.
Effort: Low (pure regex, no dependencies)

**H084 -- Token budget categories improve first-attempt success rate**
Source: GSD-2 (system 15%, task 20%, code 40%, reserve 10%)
Statement: Explicit context budget allocation prevents instructions and code from crowding each other.
Pass: Compare first-attempt success: 10 sessions with budgets vs 10 without.
Fail: Budget too rigid -- agents need dynamic allocation per task type.
Evidence needed: Implement budget tracking, run controlled comparison.
Effort: Medium (add to context-mgmt skill)

### Knowledge & Anti-Drift

**H085 -- Append-only decision log reduces "wrong direction" rework by >30%**
Source: GSD-2 (DECISIONS.md, never edit, only supersede)
Statement: Structured decision log (append-only, read at session start) prevents the most dangerous drift: loss of "why."
Pass: Over 10 sessions, fewer wrong-direction starts. Decisions cited in agent reasoning.
Fail: Log grows too large within 20 sessions, or adds overhead without reducing rework.
Evidence needed: Create _meta/DECISIONS.md, track rework incidents.
Effort: Low (create file, read at session start)

**H086 -- Structured knowledge tables outperform unstructured _learnings.md**
Source: GSD-2 (Rules/Patterns/Lessons with K/P/L IDs)
Statement: Separating learnings into three typed tables with IDs improves retrieval accuracy and reduces stale entries.
Pass: After 15 sessions, fewer stale entries. Agents cite knowledge IDs.
Fail: Overhead of maintaining three tables exceeds benefit.
Evidence needed: Refactor _learnings.md, track citation rate.
Effort: Low (restructure existing file)

**H087 -- Phase boundary manifest rebuild prevents summary drift**
Source: GSD-2 ("defragment at phase boundaries")
Statement: Rebuilding AgentDB session context from scratch at tier boundaries prevents photocopy-of-photocopy degradation.
Pass: Compare manifest accuracy at session end: incremental vs rebuild. Rebuild has fewer factual errors.
Fail: Rebuild cost exceeds benefit, or incremental is accurate enough.
Evidence needed: Implement rebuild at handoff/compaction points, compare accuracy.
Effort: Low-Medium (add to handoff command)

### Agent Architecture

**H088 -- IO-declared contracts enable automatic dependency resolution**
Source: GSD-2 (reactive task graph from IO intersections)
Statement: Adding explicit `inputs[]` and `outputs[]` fields to contracts enables automatic DAG construction.
Pass: Tier 3 contracts auto-derive execution order matching manual sequencing.
Fail: IO declarations too ambiguous or too rigid for real agent work.
Evidence needed: Extend contract schema, test on 3 tier-3 tasks.
Effort: Medium (contract schema change + agent updates)

**H089 -- Cross-model adversarial review catches 20%+ more issues than same-family**
Source: claude-octopus, claude-review-loop, adversarial-spec (3 independent convergences)
Statement: Using a different model family (e.g., Codex, Gemini) for adversary review catches blind spots same-family misses.
Pass: On 10 reviews, cross-model finds 20%+ issues not caught by Claude-only review.
Fail: Cross-model adds latency/cost without meaningful catch-rate improvement.
Evidence needed: Set up cross-model review pipeline, compare catch rates.
Effort: High (integrate external model API)

**H090 -- Real-time context monitoring prevents unnecessary compactions**
Source: claude-hud (17.5K stars, de facto standard for runtime observability)
Statement: Monitoring context usage in real-time enables proactive management, reducing surprise compactions.
Pass: Sessions with monitoring have fewer compactions and more efficient context use.
Fail: Monitoring adds overhead without changing behavior.
Evidence needed: Install claude-hud, track compaction frequency before/after.
Effort: Low (install existing tool)

**H091 -- Dynamic rigor levels improve review efficiency**
Source: correctless (adjust review intensity based on code complexity)
Statement: Scaling adversary scrutiny based on code complexity (simple=fast, complex=thorough) improves review efficiency.
Pass: Average review time decreases without reducing catch rate.
Fail: Complexity classification unreliable, or all code needs thorough review.
Evidence needed: Add complexity scoring to adversary dispatch, measure efficiency.
Effort: Medium (triage agent integration)

---

## Priority Matrix

### Do First (low effort, high evidence potential)
| ID | Hypothesis | Effort | Impact |
|----|-----------|--------|--------|
| H079 | Decision capture | Low | High (anti-drift) |
| H085 | Append-only decision log | Low | High (anti-drift) |
| H083 | Waste signal detection | Low | Medium (token savings) |
| H080 | Working memory cap | Low | Medium (context hygiene) |
| H081 | AgentDB pruning | Low | Medium (performance) |
| H086 | Structured knowledge tables | Low | Medium (retrieval quality) |

### Do Second (medium effort, high potential)
| ID | Hypothesis | Effort | Impact |
|----|-----------|--------|--------|
| H078 | Graduated retrieval | Medium | High (60%+ token reduction) |
| H082 | Content-type compression | Medium | High (20%+ savings) |
| H084 | Token budget categories | Medium | Medium (first-attempt success) |
| H087 | Phase boundary rebuild | Low-Med | Medium (anti-drift) |

### Evaluate Carefully (high effort or uncertain value)
| ID | Hypothesis | Effort | Impact |
|----|-----------|--------|--------|
| H089 | Cross-model adversary | High | High (quality) |
| H088 | IO-declared contracts | Medium | Medium (automation) |
| H091 | Dynamic rigor levels | Medium | Medium (efficiency) |
| H090 | Real-time monitoring | Low | Uncertain (behavioral change) |

---

## Experiment Execution Plan

**Phase 1: Evidence Mining (today)**
Test H083, H080, H081 against existing data — these can be partially validated from AgentDB telemetry without implementation.

**Phase 2: Low-Effort Implementation (next session)**
Implement H079, H085, H086 — these are file structure changes + agentdb schema additions.

**Phase 3: Medium Implementation (following sessions)**
Implement H078, H082 — these require code changes to agentdb CLI and compaction pipeline.

**Phase 4: External Integration**
Test H089 (cross-model review), H090 (claude-hud) — these require external tool setup.

---

## Cross-Reference: Strongest Patterns

Three patterns emerged independently from multiple sources:

### 1. Graduated/Tiered Retrieval
- Git Context Controller: 5 levels (summary/lastN/hash/decisions/full)
- Claude-Mem: 3 layers (index/timeline/detail)
- GitAgent: 2 layers (working/archive)
**Convergence strength:** 3/3 projects implement this. Kernel's all-or-nothing AgentDB is the outlier.

### 2. Decision Capture (Why, Not Just What)
- Git Context Controller: `note` field for rejected alternatives
- GSD-2: Append-only DECISIONS.md
- GitAgent: `key-decisions.md` in runtime
**Convergence strength:** 3/3 projects capture decisions separately from learnings. Kernel doesn't.

### 3. Cross-Model Review
- claude-octopus: Up to 8 models simultaneously
- claude-review-loop: Claude writes, Codex reviews
- adversarial-spec: Multi-LLM debate until consensus
**Convergence strength:** 3 independent projects solving same blind spot. Kernel's adversary is same-family.

---

*Sources: 4 research agents, 39 OSS projects, 12 new discoveries*
