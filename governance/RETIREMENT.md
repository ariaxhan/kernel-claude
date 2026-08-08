# Retiring a mechanism

Nothing in KERNEL is deleted quietly. A hook, skill, agent, guard, or library
function leaves the same way it arrived: on purpose, with a reason someone can
read later.

## Why this exists

An audit of v7 through v9 found that exactly one removal in KERNEL's history
shipped with evidence: the v8.1.2 debloat, which measured invocation counts across
~1,900 sessions before cutting ten skills and seven agents. Everything else died
by **erosion** - a rewrite moved on and its call sites never came back.

- The spec-interview recipe dissolved into a vague sentence during a prose
  rewrite. Nobody decided that. It took an archaeology dig to find and 9.1.2 to
  restore.
- The GitHub layer's posting functions still work perfectly today. Their callers
  lived in the commands layer, which was migrated to skills; the re-wiring never
  happened. The lib sat with zero callers for months while its tests stayed green.

Both were invisible because deletion-by-rewrite leaves no artifact. This is the
artifact.

## The rule

Retiring a mechanism requires a line in `governance/retirements.jsonl`:

```json
{"date":"","mechanism":"","kind":"","commit":"","why":"","replaced_by":"","evidence":""}
```

- `why` states the reason it is going, not that it went.
- `replaced_by` is `n/a` only when nothing takes over, said out loud.
- `evidence` is what makes the verdict checkable: measured invocation counts, an
  incident, a review. "Seemed unused" is not evidence; it is the feeling that
  precedes an archaeology dig.

Append only. The ledger is a record, not a workspace: a wrong entry gets a
correcting entry, never an edit.

## The fence

`scripts/check-orphans.py` fails when a library function loses its last **call
site in code**, unless it is recorded in `governance/orphans-baseline.json` with
the issue that will decide its fate. New orphans fail the build; healed ones fail
too, so the baseline cannot outlive the debt it records.

Two deliberate exclusions, both learned the hard way:

- **Tests do not count as callers.** A suite that greps for a function name is
  asserting the wiring exists, not using it. Counting those mentions is exactly
  how a stranded function hides - and it hid five of them here until the
  exclusion landed.
- **Docs do not count as callers.** Being written about is not being used.

One category is reported rather than counted: **prose-wired** functions, named
only in a `SKILL.md` or an agent file. KERNEL's runtime is partly an agent reading
markdown, so those are reachable - but only when the agent follows the prose,
which under load is a coin toss. They are surfaced on every run so the difference
between "wired" and "written about" stays visible.
