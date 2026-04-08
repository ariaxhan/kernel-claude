# Batch Experiment Results: Zero-Experiment Hypotheses

**Date:** 2026-04-07
**Experiments:** EXP-175 through EXP-183 (9 experiments, 9 hypotheses)

## Verdict Table

| Hypothesis | Verdict | Conf | Key Finding |
|---|---|---|---|
| H082 Content-type compression | REFUTES | 0.25→0.18 | Total content is 96KB. 20% savings = 19KB — trivial vs 200K+ context. Overhead exceeds benefit. |
| H096 Compaction correlates with activity | SUPPORTS | 0.40→0.55 | Compact/activity ratio stable 0.02-0.07 across 11 days. Activity volume drives compaction, not read-start load. |
| H102 Waste in hooks not content | SUPPORTS | 0.40→0.55 | Hooks: 399.5s (2816 calls). Errors: 19KB (71 entries). Hook infrastructure is the dominant waste vector. |
| H106 Guard-bash break-even exceeded | SUPPORTS | 0.40→0.55 | 1971 guard-bash calls, ZERO blocks, 175.9s overhead. 100% pass-through. Break-even clearly exceeded. |
| H107 Compound domain co-loading | SUPPORTS | 0.40→0.55 | Onboarding co-occurs with enterprise-safety (6x), workflow (6x), backend (3x). Natural cluster. |
| H087 Manifest rebuild degradation | INCONCLUSIVE | 0.25 (no change) | Compaction events lack session_id. Day-level proxy suggests 1.6-6.5/session but cannot confirm manifest rebuilds. |
| H090 Proactive context monitoring | SUPPORTS | 0.25→0.44 | Zero proactive context management exists. All compaction is purely reactive. Monitoring would help. |
| H091 Dynamic rigor levels | SUPPORTS | 0.20→0.40 | 5 adversary verdicts all checked identical dimensions regardless of task complexity. Static rigor confirmed. |
| H088 IO-declared contracts enable DAGs | SUPPORTS | 0.20→0.40 | Single contract has clear implicit IO. DAG inferrable: agentdb→agents→tests. Explicit IO would automate this. |

## Actionable Findings

1. **Guard-bash is pure waste** (H106): 1971 calls, 0 blocks, 3 minutes burned. Candidate for removal or sampling.
2. **Hook overhead dominates** (H102): 6.7 minutes total hook time. Target hooks for optimization, not tool output.
3. **Content compression is not worth pursuing** (H082): Kill this research direction. The data is already small.
4. **Onboarding is a compound domain** (H107): Auto-load enterprise-safety + workflow when onboarding is accessed.
5. **Add session_id to compaction events** (H087): Current schema blocks per-session analysis. Easy fix, high signal.

## Method

All experiments used SQL queries against AgentDB (`_meta/agentdb/agent.db`). No synthetic data. All measurements from production telemetry.
