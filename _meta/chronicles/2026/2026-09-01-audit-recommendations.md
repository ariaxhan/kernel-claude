---
type: note
status: active
created: 2026-09-01
tier: 2
---

# Executing the audit recommendations, including the two that were wrong

## What was attempted

Aria: "execute all of the recommendations please", against the ranked audit in
`Vaults/_meta/reports/kernel-audit-2026-09-01/`.

## What actually changed

Shipped as 9.8.1, full suite 509 passed / 1 failed (the pre-existing `detect_vaults` test that
expects `~/Vaults`, reproducible on main):

- **Doctrine dedupe.** The compression block loaded six times in one session. The two globals
  keep it; the four project files that always load alongside a global now carry one line. ~972
  tokens a session.
- **session-start.** The preamble prints only when no loaded CLAUDE.md/AGENTS.md carries it.
  ~798 tokens a session here. The split lives in the generator, not its output.
- **chronicle-gate.** Refuses three times instead of once, accepts a one-line skipped note, and
  no longer prints its own bypass.
- **guard-bash.** Four narrowings, one widening. The widening closed a pre-existing hole where
  list-form argv matched nothing at all.
- **warn-hardcoded.** Precise instead of deleted.
- **detect-secrets.** Better refusal, no weakening.
- **kernel-install-current.** Updates every marketplace clone, not just the default account.
- **agentdb script.** Vault root from `$HOME` instead of a hardcoded `/Users/ariaxhan/...`.

## Verified live

- `bash tests/run-tests.sh` -> 509/1, matching main baseline.
- Guard changes tested in BOTH directions, 11 cases: a quoted command allowed, a shell body
  blocked, a Python body that shells out blocked, a bare force-delete blocked, a grep allowed.
- chronicle-gate driven through all four states in a throwaway repo.
- All four marketplace clones converged on 9.8.0 from four different commits.
- session-start verified with and without a CLAUDE.md present.

## What failed

**Two of the recommendations were wrong, and I wrote both of them.**

1. *"Cut session-start output by 60%."* The block is not accidentally duplicating CLAUDE.md;
   it is the same source rendered twice, and for any repo that is not kernel-claude the hook is
   the ONLY delivery of kernel doctrine. Executing it literally would have silently disarmed the
   plugin everywhere. The audit reasoned from token counts without asking what the tokens were
   for. Implemented as a conditional instead.

2. *"detect-secrets needs a fixtures exemption."* Written, then reverted within minutes: it
   failed three of this repo own detection tests, because `AKIAIOSFODNN7EXAMPLE` is the
   canonical AWS example key and contains the word EXAMPLE. The values that announce themselves
   as fake are exactly what a real leak looks like to a regex. The nuisance was real; the hole
   would have been worse.

A third, *"delete warn-hardcoded"*, was correct about the evidence (227 fires, zero behaviour
changes) and wrong about the remedy: the test suite uses it as the canonical content-consuming
advisory hook, so deleting it would have gutted coverage of the shared payload parser. Fixed its
precision instead.

**The guard blocked me from writing its own fix.** `guard-bash` refused the patch three times
because the patch comment quoted the command it was teaching the guard to ignore. That is the
cleanest possible demonstration of the false positive, and it cost three rewrites to land.

## Deferred

- The 90 separate `agent.db` files remain unshared: a lesson learned in one project is invisible
  in another unless written `--global`. Changing that is a data-migration decision, not a fix.
- Three kernel-claude branches still need Aria approval token to force-delete.

## Disagreement worth inheriting

An audit that ranks by measured cost will recommend cutting things that are cheap to measure and
expensive to lose. Two of five recommendations here were of exactly that shape. The token count
was right in both cases; the conclusion was wrong in both cases. Rank by cost, but before
executing a CUT, ask what breaks if it is gone, and check by removing it in a throwaway copy
rather than by reasoning.
