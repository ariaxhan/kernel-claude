# AgentDB recall Phase 1 and memory experiment (#272)

## Phase 1, 2026-11-26

Invariant: recall surfaces the most relevant learning for this query, rather than the most popular learning overall.

- Preamble: capped hit boost, two rotating under-five-hit slots, shared display/load/event selection.
- Recall: seven ordinary slots plus one low-hit match passing the unchanged relevance floor; no qualifying match leaves the slot empty. LIKE fallback ranks relevance before capped popularity. Exploration candidates are not truncated before term scoring.
- Prune: delegates to existing 46-day decay with archive events and resurrection.
- NULL-ID historical rows excluded from preamble selection to prevent SQL NOT IN suppression.

Verification on disposable copies only; recall uses --ids:

- Golden corpus: 29 positives, 16 negatives. Before/after recall@8: 29/29; negatives correct: 7/16 both, identical nine existing false-hit cases. No regression. Top-8 gate passes.
- At k=5, incumbent 26/29, candidate 27/29. The historical 0.95 gate at k=5 fails for both on this current corpus; this is not a new regression. The requested top-8 check passes.
- Seven CLI regression tests pass, including empty stores, floor rejection, rotation, reversible prune, zero-effect IDs, and best-match selection beyond 40 candidates.
- tests/run-tests.sh: 45 passed, zero failed. Disposable Git fixtures require GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=commit.gpgsign GIT_CONFIG_VALUE_0=false because inherited global signing prevents their initial commits. Product code unchanged for this environment issue.
- Independent gpt-6.1-sol review through llm-bench CodexCLIProvider: REQUEST CHANGES for truncation and LIKE floor, then APPROVE after repair. Native subagent dispatch failed with missing thread-store rollout; standalone review used replacement instructions and no tools.

### Real query replay

25 recorded recall_call queries per store; identical snapshots per condition. Overlap is set intersection divided by incumbent result count. Low-hit counts are displayed occurrences, not distinct IDs. Diversity is distinct preamble learnings over ten read-starts.

| Store | Mean top-8 overlap | Low-hit old/new | Zero-hit new | Preamble diversity old/new |
|---|---:|---:|---:|---:|
| vault | 0.995 | 27/28 | 3 | 12/30 |
| coding | 0.840 | 51/51 | 14 | 12/30 |
| home | 0.975 | 41/46 | 19 | 10/28 |

These measurements establish retrieval behavior, not task usefulness. No model-comparison results are claimed here. Phase 2 will use llm-bench, never the NOT CERTIFIED model-familiarity grader.

Scratch receipts: /tmp/kernel-272/{before.txt,final-eval8.txt,before-k5.json,after-k5.json,replay.json,repo-tests-final.txt,review.txt}.

## Phase 2 experiment, 2026-11-26

Same task, same model, only memory differs. Harness: llm-bench `run_single_test` with a deterministic choice grader (positive/negative controls asserted). The model-familiarity engine was not used (NOT CERTIFIED). Memory per condition came from `recall --ids` on DB copies.

- Tasks: 20 retrospective fleet diagnosis tasks (fleet-01..20) from ariaxhan/Vaults #872, #874, #875, #885, #886, #887, #888, #889, #890, #900, #901, #902, #903. That is 13 correlated issue clusters. Each task offers three actions: the correct one, the one that repeats the failure a learning exists to prevent (recurrence), and a distractor.
- Conditions: none, old recall top 8, new recall top 8 with the exploration slot. Exploration-only was not run.
- Models: gpt-6.1-sol (Codex CLI, medium effort), qwen3.8:27b (Ollama, temperature 0).

| Model | Condition | n | Success | Recurrence | Success 95% Wilson |
|---|---|---:|---:|---:|---|
| gpt-6.1-sol | none | 20 | 20/20 | 0/20 | 0.84-1.00 |
| gpt-6.1-sol | old | 20 | 20/20 | 0/20 | 0.84-1.00 |
| gpt-6.1-sol | new | 20 | 20/20 | 0/20 | 0.84-1.00 |
| qwen3.8:27b | none | 20 | 20/20 | 0/20 | 0.84-1.00 |
| qwen3.8:27b | old | 20 | 20/20 | 0/20 | 0.84-1.00 |
| qwen3.8:27b | new | 20 | 20/20 | 0/20 | 0.84-1.00 |

Recurrence 95% upper bound: 0.16 in every cell. Zero invalid outputs.

Replicate: an accidental concurrent second run produced a second trial for 117 of 120 keys. All of them were 100% correct, and 117 of 117 matched the primary run's action. The table uses the first trial per key.

Verdict: the experiment is at ceiling and cannot tell the conditions apart. Even with no memory, both models get every task right. So it shows neither benefit nor harm from the Phase 1 ranking. A three-way choice whose evidence already names the failure is too easy. The next useful version needs open-ended tasks (a real repair graded by tests) or prompts that leave out the evidence the learning supplies.

Limitations: 20 tasks in 13 correlated clusters. Hindsight snapshot. Choice accuracy, not production repair. Wilson intervals assume independence and are only descriptive here.

Receipts: /tmp/kernel-272/{experiment-manifest.json,experiment-results.jsonl,experiment-final.json,recompute.py}.
