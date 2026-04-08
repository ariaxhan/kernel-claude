# Comprehensive Experiment Benchmark — April 2026

**Date:** 2026-04-08
**Experiments this session:** 19 (EXP-136 through EXP-154)
**New hypotheses:** 23 (H078-H100)
**Mutations:** 3 (H095→H096, H092→H097, H086→H100)
**Refutations:** 2 (H095 load→compaction, H086 structured tables)
**Emergent discoveries:** 5 (H092-H096, H098-H100)

---

## The Big Picture

### What we measured (numbers, not opinions)

| Metric | Value | Implication |
|--------|-------|-------------|
| AgentDB learnings | 356 items, ~23,562 tokens | 61.5% of startup context cost |
| Hit rate | 109/356 (30.6%) active | 69.4% of learnings never referenced |
| Decision-like learnings | 23/356 (6.5%) | Decisions not captured systematically |
| Coordination failure impact | 52.5% of total hits | Most impactful failures are process, not code |
| Domain fragmentation | 64 domains, 21 singletons | Too granular for useful categorization |
| Hook overhead | 87ms/Bash, 4.4s/session-start | Measurable but below 5% threshold |
| Compaction frequency | 83 events across 30 sessions | Driven by session complexity, not DB size |
| Session tracking | 1 unique session_id for 2697 events | Broken — observability impossible |

### Top 3 findings

**1. Weighted-50 retrieval is the single biggest lever**
- 85.7% token savings (23,562→3,378)
- 84.8% hit coverage preserved
- Formula doesn't matter — hit-count dominates any weighting
- Decisions are supplementary, not primary (H079 reframed)

**2. Coordination failures are 4.3x more impactful than code quality failures**
- 14 coordination learnings account for 52.5% of all hit impact
- The adversary agent has NEVER FIRED (or isn't tracked)
- Cross-model review (H089) matters less than coordination-aware review
- Top failures: worktree scope creep, parallel bug duplication, surgeon false claims

**3. The type system is fine; the domain taxonomy is broken**
- GSD-2's Rules/Patterns/Lessons scheme fails (72.2% unclassifiable)
- Current 4-type system covers 100% of learnings
- Real problem: 64 domains (should be ~10), 119 unclassified (33.4%)
- Research domain: 34 learnings, 0 hits (reference material, not operational knowledge)

---

## Strategy Tournament Results

### Retrieval Strategies (H078 benchmark)

| Strategy | Items | Tokens | Hit% | Failures | Savings |
|----------|-------|--------|------|----------|---------|
| A. Full load (baseline) | 356 | 23,562 | 100% | 57 | 0% |
| B. **Weighted-50** | 50 | 3,378 | 84.8% | 29 | 85.7% |
| C. Tiered-20 | 20 | 1,351 | 40.6% | 20 | 94.3% |
| D. Decision-aware-50 | 50 | 3,355 | 40.6% | 16 | 85.8% |

**Winner: Strategy B** — best balance of coverage and savings.
**Recommended: Strategy B + 10 decision overlay = ~60 items, ~4,000 tokens (H098)**

### Scoring Function Sensitivity (H078 sub-experiment)

| Formula pair | Top-10 overlap |
|-------------|---------------|
| Weighted vs Hit-only | 10/10 (100%) |
| Weighted vs Recency | 0/10 (0%) |
| Hit-only vs Recency | 0/10 (0%) |
| Weighted vs Decayed | 8/10 (80%) |

**Finding: Hit-count and recency are orthogonal.** Any weighted formula collapses to hit-count dominance. TIER them as separate dimensions (H099).

### Failure Taxonomy (H093 benchmark)

| Category | Learnings | Hits | Avg Hits | Impact Share |
|----------|-----------|------|----------|-------------|
| Coordination | 14 (25%) | 95 | 6.8 | 52.5% |
| Code Quality | 36 (63%) | 59 | 1.6 | 32.6% |
| Infrastructure | 7 (12%) | 27 | 3.9 | 14.9% |

**Finding: The adversary should audit coordination, not just code.**

### Knowledge Organization (H086 benchmark)

| Scheme | Coverage | Drawback |
|--------|----------|----------|
| Current (pattern/failure/gotcha/preference) | 100% | 'pattern' too broad |
| GSD-2 (Rules/Patterns/Lessons) | 27.8% | 72.2% unclassifiable |

**Finding: Current scheme wins. Real problem is domain fragmentation, not types.**

### Domain Consolidation (H100 benchmark)

| Canonical Domain | Learnings | Hits | Avg Hits |
|-----------------|-----------|------|----------|
| (unclassified) | 119 | 126 | 1.1 |
| product | 26 | 105 | 4.0 |
| system-arch | 55 | 72 | 1.3 |
| security | 12 | 40 | 3.3 |
| coordination | 25 | 39 | 1.6 |
| data | 19 | 31 | 1.6 |
| devtools | 17 | 6 | 0.4 |
| operations | 11 | 5 | 0.5 |
| content | 14 | 5 | 0.4 |
| testing | 12 | 1 | 0.1 |
| research | 34 | 0 | 0.0 |

**Finding: Product and security are high-value (4.0 and 3.3 avg hits). Research is never referenced (0 hits). Testing barely referenced (1 hit).**

### Token Budget Composition (H084 benchmark)

| Component | Tokens | % of Startup | % of 200K |
|-----------|--------|-------------|-----------|
| AgentDB (full) | 23,562 | 61.5% | 11.8% |
| CLAUDE.md hierarchy | 7,296 | 19.0% | 3.6% |
| System + tools | 5,000 | 13.1% | 2.5% |
| Rules files | 2,447 | 6.4% | 1.2% |
| **Total startup** | **38,305** | **100%** | **19.2%** |

With weighted-50: startup drops to 18,121 tokens (9.1%), freeing 20,184 tokens.

---

## Hypothesis Confidence Map (Post-Benchmark)

### Rising (evidence accumulating)
| ID | Statement | Confidence | Experiments |
|----|-----------|------------|-------------|
| H078 | Graduated retrieval reduces tokens 60%+ | 0.6 | 3 supports |
| H093 | Coordination failures > code quality in impact | 0.6 | 2 supports |
| H098 | Weighted-50 + decision overlay is optimal | 0.5 | 1 support (interaction) |
| H099 | Tiered retrieval beats single formula | 0.5 | 1 support |
| H097 | Session-start is the UX friction point | 0.5 | 1 support |
| H094 | Session tracking is broken | 0.5 | 1 support |
| H080 | Working memory cap prevents bloat | 0.5 | 2 supports |
| H100 | Domain consolidation > type restructuring | 0.5 | 2 supports |

### Falling (evidence against)
| ID | Statement | Confidence | Evidence |
|----|-----------|------------|----------|
| H095 | Load size → compaction frequency | 0.1 | REFUTED: compaction driven by session complexity |
| H086 | Structured knowledge tables | 0.15 | REFUTED: 72.2% unclassifiable |
| H092 | Hook overhead >5% | 0.2 | INCONCLUSIVE: ~1-3%, below threshold |
| H079 | Decision capture as primary strategy | 0.3 | REFRAMED: supplementary role |

### Emerged (not in any prior hypothesis set)
| ID | Source | Statement |
|----|--------|-----------|
| H096 | Mutation of H095 | Compaction driven by in-session generation, not startup load |
| H097 | Mutation of H092 | Startup overhead (4.4s) is the friction, not per-action |
| H098 | H078×H080 interaction | Weighted-50 + decision overlay is optimal combo |
| H099 | EXP-151 scoring sensitivity | Hit-count and recency are orthogonal — tier them |
| H100 | EXP-152 organization failure | Fix domains (64→10), not types |

---

## What No Hypothesis Covers Yet (Gaps)

1. **Unclassified learning triage**: 119 learnings (33.4%) have no domain. What's the cheapest way to classify them? Auto-classify from insight text? This is prerequisite for domain-aware retrieval.

2. **Research domain utility**: 34 learnings, 0 hits. Is research knowledge fundamentally different from operational knowledge? Should it be stored differently (reference docs, not learnings)?

3. **Hit count decay**: Do high-hit learnings stay high forever, or do they decay? No temporal analysis of hit_count evolution exists. Critical for long-term retrieval weighting.

4. **Agent spawn → compaction pipeline**: If H096 is correct (compaction driven by in-session generation), what's the exact chain? Spawn agent → tool calls → context fills → compaction. Can we predict compaction from agent count?

5. **Cross-project knowledge transfer**: Learnings span multiple projects (kernel-claude, modelmind, CollabVault). Are learnings from one project useful in another? Or is project-local knowledge dominant?

---

## Experiment Methodology

All experiments were **quantitative** — SQL queries against AgentDB data, token measurements against real files, classification of real learnings. No synthetic data. No simulated outcomes.

**Evidence quality tiers:**
- **Strong**: Direct measurement (token counts, hit distributions, overlap analysis)
- **Medium**: Classification + counting (failure taxonomy, decision-like detection)
- **Weak**: Absence evidence (adversary never fired, session tracking broken)

The 3 mutations demonstrate the engine's self-correction: H095 refuted → H096 spawned, H092 refined → H097, H086 refuted → H100 spawned. Each mutation narrows the hypothesis from an overconfident claim to a data-supported version.

---

*19 experiments, 23 hypotheses, 3 mutations, 2 refutations, 5 emergent discoveries. All from a single 1MB database.*
