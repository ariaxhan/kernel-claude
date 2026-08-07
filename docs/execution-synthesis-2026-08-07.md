---
type: report
status: active
created: 2026-08-07
subject: Three-session synthesis (vaults-root + paper-rooms + matra) reshaping kernel 9.2
---

# Execution synthesis: what three parallel excavations agree on

Sources: paper-rooms blind reviews (_meta/reports/blind-review-2026-08-07/, receipts read
directly), matra execution operating system (matra-suite _meta/plans/2026-08-07, bb5c3b8),
kernel-claude v7-v9 archaeology (this session), exchanged via first-use cross-session
SendMessage (CLI 2.1.224, same day it shipped).

## Unanimous findings (three independent evidence bases)

1. **Fences fail dark.** The #1 defect class everywhere, with receipts:
   - paper-rooms: scope + tradition gates printed PASS with `rg` missing (exit 127
     swallowed), in the PR's own green CI run 29144214386; a seeded forbidden file passed.
   - matra: profile detection required literal "github.com", silently shutting off the
     whole issues layer for weeks; a pre-push guard misread a 403 as key-not-registered.
   - kernel archaeology: the GitHub layer eroded to zero callers with no decision, no
     alarm.
   Matra's phrasing, adopted: **"a fence that fails dark is a leash you think you're
   holding."** The positioning is right but incomplete without liveness.

2. **"Pushed" is a claim, not a state.** matra main sat 51 commits behind for days;
   this session's Vaults root is unpushable behind a 1.7GB commit; vault gotcha
   (committed != pushed != deployed != working) has top hit count. Done-verbs need a
   fresh origin/live read, hook-checked.

3. **Verifier recursion is real waste.** matra froze product 3h11m perfecting a test
   oracle (3 rejections: b507d4f, e3d4ecda, f28fe6ea); urban-atlas P6 halted a phase when
   scaffolding outran outcomes; paper-rooms: review loops churn while 7 phone defects sat
   under 506 green tests. Cap: ONE adjudicated blind round per milestone; verifier
   recursion cap 2; two consecutive scaffolding-only cycles = halt.

4. **Issues-first works.** Unanimous support for #171. paper-rooms revived github_layer
   independently the same day (epic #27, issues #19-#26) — convergent evolution.

5. **What to keep:** context-blind mutation-qualified verifiers (only mechanism that
   caught real lies in matra: throwing stub passing 19/19, 3-user privacy leak,
   wrong-identity commit); stacked PRs; cycle-with-receipt primitive; serial single merge
   authority.

## Adjudicated disagreement: #170 manifests

Both peers attacked kernel.commission/v1 as a new manifest runtime:
- matra: manifest ceremony died twice (crystal 0 rows, trajectory runtime abandoned,
  29 checkpoints/day re-binding one frozen SHA — "resume recovered position, never truth").
- paper-rooms: urban-atlas P6 halted because governance/manifest scaffolding outran
  outcomes; manifests must stay ONE small file rewritten per cycle.

**Verdict: they're right; #170 is amended.** Chronicle Stop-gate survives (unanimous
support — prose rules die without enforcement). kernel.commission/v1 as a new schema is
CUT; commissions ride the existing surfaces (agentdb contract + the GitHub issue as the
public commission). kernel.chronicle stays a single small file per session, not a growing
apparatus, and ships with the scaffolding tripwire alongside.

## Kernel's record, answering paper-rooms' open questions

- **Serial single-writer vs waiving I0.14 (worktrees) for burns: do NOT waive.** The
  record is brutal and one-sided: vault gotcha (18 hits) — 60 worktree branches across
  urban-atlas, 949 commits, ZERO merged; matra's own 30 worktrees / 26 unmerged clean
  commits; urban-atlas' 42-worktree disaster. Meanwhile the 2026-07-24/25 triple-cycle
  burn landed ~50 lanes with NO worktrees: file-disjoint branches, one merge authority,
  landing as a first-class pass (burn-lander). Parallelism pays only when lanes are
  file-disjoint, and file-disjoint lanes don't need worktrees — they need a lander.
- **WIP cap 1 vs 2:** matra ran cap 2 on disjoint trees; one shared tree = cap 1. Kernel
  record agrees: every multi-writer incident traces to shared-surface writes.
- **Receipts: issue comments over receipt dirs.** Archaeology shows file-side call sites
  eroded silently while issue-comment call sites survived rewrites. Receipt lands as a
  comment on the cycle's issue (visible, reviewable, rewrite-proof); file fallback only
  when GitHub is unreachable; never block on the API.

## 9.2 scope, reshaped (supersedes the original issue list where they conflict)

1. **NEW, now top priority — fence liveness (#173):** every guard distinguishes "check
   failed" from "check couldn't run"; degraded mode surfaces loudly; `command -v` guards
   on undeclared tool deps; every new gate ships with a break-it-on-purpose receipt
   (born broken, in isolation, per the vault reflex).
2. **#169 GitHub re-wire** — unchanged, now carries receipts-as-issue-comments.
3. **#170 amended** — chronicle Stop-gate + single-small-file rule + scaffolding
   tripwire; commission schema cut.
4. **#171** — unchanged, plus verifier-recursion cap 2 and the blind-review budget
   (one adjudicated round per milestone).
5. **Done-verb hook** — "done/shipped/pushed" claims require a fresh origin/live
   comparison (folds into #173 or its own issue).
