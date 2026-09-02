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

## The verifier found a real regression, and it was in the fix for a false positive

An independent adversary, given the acceptance record but not the reasoning, reported
DO NOT MERGE on 9.8.1 with one blocking finding:

```
X=$(grep -o "<destructive literal>" file.txt); eval "$X"
```

main blocked it. My branch allowed it. The cause was change 3(b), "a search pattern is data":
I replaced the quoted grep pattern with a placeholder before keyword matching, on the reasoning
that grep never executes what it looks for. That reasoning is correct about grep and incomplete
about the command line, because a later segment can run what the grep returned.

This is worth stating plainly: the regression was introduced by a fix for a false positive that
had blocked me three times in one session. Irritation is a bad reason to loosen a safety gate,
and it produced exactly the failure the gate exists to prevent. The narrowing was still right;
it just needed the other half.

The exemption is now withdrawn whenever the command also holds `eval`, `source`, a bare `.`,
`xargs`, or an interpreter `-c` reading a variable. Differential against main across six cases:
grep-then-eval, grep-then-source and grep-then-xargs block on both sides again, the bare
destructive command blocks on both, and the original false positive is still allowed.

The verifier also confirmed, with numbers I had not produced: the compression conditional
suppresses the preamble for 100% of projects under the vault and is correct in every case
because the Claude global genuinely carries the rule; detect-secrets' `PATTERNS` array is
byte-identical to main; all four guard hash pins match the shipped files; and the
`detect_vaults` failure reproduces on main.

Its one quarantined finding (a CLAUDE.md that shows the header inside a code fence would
suppress the real preamble) was cheap enough to just fix rather than accept.

## Three rounds on one exemption, and what settled it

The search-pattern exemption took three adversarial rounds:

1. Stripped the pattern unconditionally. A grep-then-eval walked through.
2. Enumerated re-execution verbs (eval, source, xargs, bare dot, `-c` with a variable).
   Eight more routes walked through: backticks, `$()` in command position, a here-string,
   `printf | bash`, `zsh -s`, process substitution, and writing the match to a file and running
   it by path, which involves no "re-execution verb" at all.
3. Inverted to an allowlist. The exemption applies only when the whole command is recognisably
   inert; anything unrecognised keeps the literal visible.

The verifier confirmed round three holds and could not route captured grep output to an executor
without also failing the inert test. Its own summary of why: "an allowlist of recognized-inert
forms with unrecognized = stay visible as the fail-safe default is the right shape for this
problem."

Two shell bugs had been quietly defeating rounds one and two, and both are worth remembering
independently of this feature:

- **BSD sed does not expand `\n` in a replacement.** `sed -E 's/[;|]/\n/g'` produced a literal
  `n`, not a newline, so splitting a command into segments yielded ONE segment on macOS and
  every pipeline looked like its first command. This pattern appears elsewhere in the guard and
  predates this change.
- **`read` returns non-zero on a final line with no trailing newline**, so the LAST segment of a
  split was silently dropped. `grep ... | zsh -s` survived two rounds on that alone: the loop
  examined `grep`, called it inert, and never saw `zsh`.

Both are the same class as the audit's own findings: a check that looks like it runs, reports
success, and is examining nothing.

**A second near-miss with the same cause as the earlier stash.** A seeded-defect run put the
pre-fix guard into the working tree, and the command timed out before its restore line. The
broken guard sat in the tree until the next check caught it. Twice in one session a timeout has
stranded a file mid-experiment. The fix both times was the same and should have been the first
move: run the experiment on a copy, never on the tree.

## Deferred, filed separately

The verifier found a pre-existing GTFOBins-class gap present identically on main and this
branch: `sort --compress-program=` executes an arbitrary program, and `tail -f` hangs
indefinitely, and neither is blocked standalone. Unrelated to this exemption, and not a reason
to hold the merge.
