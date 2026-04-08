# Mid-Confidence Hypothesis Deepening (2026-04-07)

7 hypotheses at 0.25-0.5 confidence, each with 1 prior experiment. Added EXP-200 through EXP-206.

## Results

| ID | Claim | Prior | New | Verdict | Key Finding |
|----|-------|-------|-----|---------|-------------|
| H084 | Token budget categories improve first-attempt success | 0.4 | 0.4 | inconclusive | No session-level success metric exists. Budget categories are prescriptive without diagnostic data. AgentDB is 61.5% of startup — would violate any category budget — but no evidence this causes failures. |
| H089 | Cross-model adversarial catches 20%+ more | 0.4 | 0.35 | inconclusive | All 5 adversary runs were same-model (opus). Cross-model never implemented. Adversary caught real issues (SQL injection, context loss) but the cross-model delta claim is untestable. Dropped confidence. |
| H097 | Session-start 4.4s is primary UX friction | 0.5 | 0.35 | inconclusive | session:start duration_ms is NULL in all 40 events. 4.4s was a single measurement, never tracked. Per-hook avg=121ms is imperceptible. Cannot confirm consistency or primacy. Dropped. |
| H098 | Weighted-50 + decision overlay is optimal read-start | 0.5 | 0.6 | supports | Weighted-50 = 61.3% of weighted-75 tokens with 100% overlap. Savings confirmed. Decision overlay untestable (no decision type in learnings). Weighted-50 alone is a solid default. |
| H099 | Tiered retrieval outperforms single weighted | 0.5 | 0.45 | inconclusive | Uncapped tiered = 137 items / 191% cost of weighted-75. Tiers are 88% orthogonal (good) but cost is prohibitive. Capped tiered (10/tier) promising but untested. |
| H100 | Domain consolidation improves retrieval | 0.5 | 0.6 | supports | Backend domain filter: 19/356 items (94.7% reduction). But 119 items (33.4%) have no domain — binding constraint. Consolidation helps IF combined with backfill. |
| H104 | Refuted hypotheses share more-is-better fallacy | 0.5 | 0.65 | supports | Refuted: 6/6 absolute/quantified claims. Graduated: 17/19 directional without multipliers. The pattern is precise: specific comparative multipliers fail; directional prescriptions survive. |

## Blockers for Further Progress

- **H084**: Needs session-level outcome tracking (success/failure per task) to correlate budgets with results
- **H089**: Needs actual cross-model implementation (e.g., sonnet reviewing opus output) to test the 20% claim
- **H097**: Needs session-start duration instrumentation (currently NULL in all events)
- **H099**: Needs capped-tiered experiment (top-10 per tier) to test cost-effective version

## Experiments Recorded

EXP-200 (H084), EXP-201 (H089), EXP-202 (H097), EXP-203 (H098), EXP-204 (H099), EXP-205 (H100), EXP-206 (H104)
