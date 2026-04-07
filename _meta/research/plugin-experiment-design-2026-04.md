# Plugin Gap Experiment — Design Document

**Date**: 2026-04-07
**Status**: HYPOTHESES SEEDED, EXPERIMENTS DESIGNED, READY TO RUN
**Hypotheses**: H070–H077 (8 total)
**Experiments**: EXP-128–EXP-135

---

## Executive Summary

Research identified 10+ kernel capability gaps. After filtering for overlap, 8 unique hypotheses remain — each tests whether a specific public plugin fills a genuine gap that kernel cannot.

**Priority tiers** (run these first):

### Tier 1 — High confidence these fill real gaps
| ID | Plugin | Gap | Why likely |
|----|--------|-----|------------|
| H070 | **security-guidance** | Hook-based real-time security scanning | Kernel's security skill is on-demand only. Hook-based = catches before commit, not during review |
| H073 | **claudetop/ccusage** | Cost monitoring | Kernel has zero cost visibility. This is a pure gap, no overlap |
| H076 | **plugin-dev** | Plugin scaffolding | Kernel has no tooling for creating plugins. Direct gap |

### Tier 2 — Likely valuable but overlaps exist
| ID | Plugin | Gap | Overlap concern |
|----|--------|-----|-----------------|
| H072 | **code-review** | 5 parallel reviewers | Kernel has /kernel:review (1 reviewer). Quantitative improvement, not categorical |
| H071 | **hookify** | Conversational hook creation | Kernel hooks work, just harder to create. UX improvement |
| H074 | **ralph-wiggum** | Lightweight autonomous loops | Kernel has /forge. Ralph is lighter but less structured |

### Tier 3 — Worth testing but uncertain value
| ID | Plugin | Gap | Uncertainty |
|----|--------|-----|-------------|
| H075 | **mcp-knowledge-graph** | Semantic cross-session memory | AgentDB works well for structured recall. Semantic search may not add enough value for kernel's use case |
| H077 | **feature-dev** | 7-phase feature workflow | Kernel's ingest + forge cover similar ground. May only help for truly unfamiliar codebases |

---

## Experiment Protocol

For each hypothesis:
1. **Install** the plugin in an isolated session
2. **Run** the designed experiment (see agentdb EXP-128 through EXP-135)
3. **Measure** against pass criteria
4. **Verdict**: CONFIRMED (graduate → recommend install), REFUTED (kill → document why), INCONCLUSIVE (retest with better design)

### Execution Order
Run Tier 1 first (H070, H073, H076) — these are most likely to graduate.
Then Tier 2 (H072, H071, H074) — measure quantitative improvement.
Finally Tier 3 (H075, H077) — only if Tier 1-2 don't fill enough gaps.

### Estimated Time
- Tier 1: ~30 min total (3 experiments)
- Tier 2: ~45 min total (3 experiments)
- Tier 3: ~60 min total (2 experiments, cross-session)
- Total: ~2.5 hours for full experiment run

---

## Plugins NOT Tested (and why)

| Plugin | Why excluded |
|--------|-------------|
| **Ruflo** (swarm orchestration) | Kernel already has multi-agent orchestration with AgentDB contracts. Ruflo adds enterprise swarm features kernel doesn't need at current scale |
| **Claude Command Suite** (216 commands) | Too broad — testing 216 commands isn't an experiment. Individual useful commands can be replicated as kernel skills |
| **jeremylongshore skills library** (2,811 skills) | Quantity ≠ quality. Kernel's 20 custom skills are domain-tuned. Bulk import would dilute |
| **claude-code-buddy** | Overlaps with mcp-knowledge-graph (H075). Testing one semantic memory solution is enough |
| **metaswarm** | Overlaps with kernel orchestration + Ruflo. Three-way comparison adds noise |
| **autoresearch** | Overlaps with ralph-wiggum (H074). Both do autonomous iteration |

---

## Installation Commands

```bash
# Tier 1
/plugin install security-guidance@claude-plugins-official
# claudetop: pip install claudetop (or npm install -g claudetop)
/plugin install plugin-dev@claude-plugins-official

# Tier 2
/plugin install code-review@claude-plugins-official
/plugin install hookify@claude-plugins-official
/plugin install ralph-wiggum@claude-plugins-official

# Tier 3
# mcp-knowledge-graph: configure in .mcp.json
/plugin install feature-dev@claude-plugins-official
```

---

## Success Criteria

**Experiment succeeds overall if:**
- >= 3 plugins graduate (confirmed to fill genuine gaps)
- Each graduated plugin has clear, measurable improvement over kernel baseline
- No graduated plugin introduces context bloat > 500 tokens at session start

**Experiment fails if:**
- All plugins overlap too much with kernel (< 2 graduates)
- Context cost of plugins outweighs their benefits
