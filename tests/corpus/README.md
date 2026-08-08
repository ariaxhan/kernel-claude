# Violation corpus

The standing proof that KERNEL's gates can still refuse things.

```
python3 tests/corpus/run-corpus.py     # or: ./tests/run-tests.sh corpus
```

## Why this exists

A fence nobody has watched fail is decor. Three independent execution reviews on
2026-08-07 converged on the same defect class: gates that **fail dark**. Two
receipts, both from green CI runs:

- A repo's scope and tradition gates printed `PASS` while `rg: command not found`
  scrolled past in the same log. Exit 127 was swallowed by `|| true`, so a seeded
  forbidden file sailed through a required check.
- A profile detector required a literal hostname match, silently classified a
  whole silo as local, and switched off its entire issues layer for weeks. Nobody
  chose that.

Matra's phrasing, which is now the rule: *a fence that fails dark is a leash you
think you're holding.*

## The three checks

**Divergence (bidirectional).** `hooks/gates.json`, the scripts in
`hooks/scripts/`, and the bindings in `hooks/hooks.json` must describe the same
world. A script on disk with no registry row is invisible to coverage; a registry
row with no script is a fence that was quietly retired. Both fail. This is the
red-line that keeps the coverage check itself from failing open: coverage derives
from an authoritative registry, never from whatever the harness happens to know.

**Coverage.** Every `class: gate` needs at least one case it must BLOCK and one it
must ALLOW. Block-only coverage produces a gate that refuses ordinary work and
trains humans to override it; allow-only coverage produces decor.

**Liveness.** Every gate runs twice: once normally, once with its declared
`external_deps` removed from PATH (a sandbox PATH holding symlinks to everything
*except* those binaries, so the simulation is surgical). The second run must match
the gate's declared `degraded_mode`.

## Degraded modes

Each gate declares what it does when it *cannot run*, because the two real
failures we have on record went in opposite directions: one failed open silently,
one failed closed with a wrong diagnosis. Detecting that a check could not run is
not enough; the direction has to be a decision.

| mode | meaning |
|---|---|
| `fail-closed` | Refuse. For safety gates: a scanner that cannot scan must not wave things through. |
| `fail-open-loud` | Allow, but say so on stderr. Silent fail-open is never a valid declaration. |
| `fail-closed-when-armed` | Inert until its trigger state exists, then fail-closed. Needs a corpus case that arms it. |
| `fail-abstain` | Emit no decision. For gates whose dangerous direction is YES: uncertainty must never become consent. |

## Adding a gate

1. Add the script, and a row in `hooks/gates.json` with its class, events,
   `external_deps`, and `degraded_mode` plus the rationale for that direction.
2. Add at least one must-block and one must-allow case to `cases.json`.
3. Break it on purpose **in an isolated copy** and record what happened. Testing a
   live instrument in place contaminates the reading.

The harness fails if you skip step 1 or 2. Step 3 is on your honour, and it is the
one that has caught the most.

## Fixtures

Payloads that would trip a scanner just by existing (secrets, destructive
commands, injection strings) live in `cases.json` as `{{PLACEHOLDER}}` names and
are assembled from parts at runtime. A security corpus that its own guards refuse
to let you commit is a corpus nobody maintains.

## Founding receipt

On its first run the harness failed, correctly, on real defects:

- **`guard-bash` fails dark.** The destructive-command guard warned and exited 0
  when `jq` was missing, so with one binary absent the most important fence in
  KERNEL allowed everything. Verified by hand before fixing: a recursive-delete
  payload returned rc=0 under a PATH missing only `jq`. Now fails closed, with an
  explicit `KERNEL_GUARD_BASH_DEGRADED_OK=1` escape hatch.
- **`scan-output` degraded silently** when `python3` was absent: the injection
  tripwire switched off with no signal. Now warns.
- **`guard-context` and `auto-approve-safe`** were mis-declared by the first draft
  of the registry, which is what produced the `fail-closed-when-armed` and
  `fail-abstain` modes. The gates were right; the model was too crude.

Then the harness itself was broken on purpose in a throwaway copy: an unregistered
script appeared on disk (divergence caught it) and the `guard-bash` fix was
reverted (liveness caught it). Both failed as they should; the live tree stayed
green.
