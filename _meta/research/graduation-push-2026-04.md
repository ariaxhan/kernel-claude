# Graduation Push — April 2026

Experiments EXP-190 through EXP-194. Five RISING hypotheses tested for graduation readiness.

## Graduated (3)

**H081** — AgentDB pruning prevents query degradation over 100+ sessions
- 9ms at current scale, 351ms at 10x (39x slowdown). Non-linear degradation confirms pruning is necessary before ~300 sessions.

**H103** — Error-learning taxonomy disconnect prevents learning from failures
- 27% of errors (20/74) have zero matching learnings. No shared key between tables. Structural disconnect, not behavioral.

**H105** — Hypothesis system over-theorized in coordination, under-observed in strategy
- Git graduates at 43% (observation-heavy). Coordination: 23% grad + 23% refuted (theory-heavy). Performance: 0% graduation, 10 hypotheses stuck.

## Advanced but Not Graduated (1)

**H079** — Decision capture prevents re-exploring rejected approaches
- Now 4 for / 1 against (conf 0.75). Zero decision-type learnings appear in re-exploration pairs. Strong signal but the 1 evidence_against keeps it below threshold.

## Refuted (1)

**H109** — Guard-to-learning ratio >10 predicts struggling sessions at 100% accuracy
- Threshold 10 accuracy is 70%, not 100%. False positive (03-29: ratio 38.5, only 4 errors) and false negative (04-01: ratio 3.1, 7 errors). The ratio correlates with session intensity, not struggle. Confidence dropped to 0.45.
