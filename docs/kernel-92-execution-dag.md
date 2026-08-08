---
type: plan
status: active
created: 2026-08-08
subject: Groomed 9.2 backlog + execution DAG (post three-way commission, post pilots)
---

# Kernel 9.2 execution DAG

Groomed 2026-08-08 against the signed commission
(Vaults _meta/commissions/2026-08-07-kernel-92-execution-redesign.md) and both pilot
verdicts. Tracker actions taken during grooming: #176 closed as superseded (scope split
into #173 corpus entries + #174's first ledger entry); #170 retitled to match its amended
scope (commission schema was cut); #173 gained the checks-watch-lies corpus entry.

## The backlog (7 open, all specced, all evidence-backed)

| # | unit | type | status of spec |
|---|---|---|---|
| 173 | fence liveness: gate registry, violation-corpus CI harness, degraded-mode declarations, done-verb hook, codex-dialect + absence-of-CI-run + per-mode + checks-watch corpus entries | build, foundation | complete (4 amendment comments folded) |
| 175 | guard-bash false positives (branch -d as -D; prose-mention matching) | build, small | complete (5+ repros across 3 sessions) |
| 174 | migration-map: ONE append-only retirement ledger + orphaned-caller CI check; first entry retires dead root hooks.json | build, small | complete |
| 169 | GitHub layer re-wire: 3 orphaned posting functions, issue-per-commission, state-change receipts as comments, docs/chronicles carve-out | build | complete |
| 170 | chronicle Stop-gate, minimal: one small file per session, gate-enforced; scaffolding tripwire in same PR | build + gate | complete |
| 171 | process rule text: issues-first, cycle primitive, WIP 1, verifier cap 2 (disagreement rounds only), one blind round per milestone, no-worktree parallel doctrine | governance text | ACCEPTED by both pilots; just needs landing |
| 179 | human-pass skill + ship-path verdict gate | skill + gate | complete (founding example: paper-rooms 1.3(7) pass) |

Resolved/superseded this grooming: #176 (closed; kernel exonerated by forensics).
Deliberately NOT combined: #175 stays separate from #173 - it is a surgical fix landable
before the harness exists, and merging it would couple a one-hour fix to the biggest unit.

## The DAG

```
#173 fence liveness ──────┬─▶ #175 guard-bash fixes   (corpus entries prove the fix)
  (registry + corpus       ├─▶ #170 chronicle Stop-gate (new gate → born-broken + corpus)
   harness + done-verb)    └─▶ #179 ship-path verdict gate (gate half)
#174 migration ledger ─────── independent (its CI check is plain, not corpus-dependent)
#171 process rule text ────── independent (text only, pilots already validated it)
#169 GitHub re-wire ───────── independent ──▶ #179 (receipts-as-comments feed the verdict receipt)
#179 skill half ───────────── independent (guide-generation method needs no kernel gate)
```

Rationale for the one hard spine: #173 builds the instrument every later gate must be
tested against. Landing any NEW gate before the corpus harness exists would repeat the
founding defect (gates nobody has seen fail).

## Waves (one shared tree, WIP 1 write-cycle, per our own signed protocol)

Serial write cycles; parallelism spent on CI wall-clock overlap and read-only prep for the
next cycle (recon, corpus-case drafting) while the current PR's checks run.

- **Wave 1 - foundations, 3 cycles:**
  1. #173 (largest; do first while context is rich - the corpus harness, registry, and
     done-verb hook; every amendment comment is already an enumerated corpus case)
  2. #174 (small; its first ledger entry needs #176's forensics, fresh now)
  3. #171 (text; fastest; written verbatim from the signed commission)
- **Wave 2 - gates on the harness, 3 cycles:** #175, #170, #169 (any order; #169 last so
  its receipt functions are exercised immediately by #170's gate landing)
- **Wave 3 - 1-2 cycles:** #179 (skill + ship-gate, consuming done-verb + receipts)
- **Release: 9.2.0 after waves 1-2** (units 1-5 per the commission's acceptance clause);
  #179 rides 9.2.0 if wave 3 completes in the same session, else 9.2.1. Every release:
  full local suite green, CI conclusion read explicitly (never --watch exit), tag, verify
  at head SHA.

## Standing rules for the run

- One PR per issue, branch from fresh origin/main, squash-merge only on explicitly read
  green conclusions.
- Every added gate: corpus entry + born-broken receipt (seeded in isolation) in the PR.
- Two consecutive scaffolding-only cycles on any unit = halt and re-bound (tripwire).
- kernel-claude's working tree may carry another session's uncommitted work: never stash
  or reset it; build via scratch clone or plumbing when the tree is contaminated.
- Estimated effort: wave 1 ≈ 4-6 agent-hours (#173 dominates), wave 2 ≈ 3, wave 3 ≈ 2.
```
