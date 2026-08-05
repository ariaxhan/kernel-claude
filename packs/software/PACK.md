---
name: software
kind: domain-pack
description: Code, systems, and shipping. Loaded when the router classifies domain=software.
---

# Software pack

Loaded on demand. Universal rules live in the kernel core and are not repeated here.

## Evidence that matters

Reproduction first. A defect you cannot reproduce is a hypothesis, not a bug.
Read the failing output, not the description of it. Prefer the running system to
the commit, the log line to the summary, and the actual type to the assumed one.

Before writing a call you have not used here before, resolve it against installed
package source or official docs. An API that exists in your memory but not in the
tree is the most expensive kind of confident wrong.

## Execution patterns

**direct** — the fix is known and local. Make it, exercise the changed path, done.
No branch ceremony, no plan document, no review gate.

**gated** — bounded change with a check that can fail. Reproduce or specify first,
make the smallest coherent change, run the project's configured checks, inspect
the diff. If the same fix would repeat on the next file, promote it to one place
now rather than pasting it twice.

**trajectory** — genuinely iterative work: performance tuning, flaky-test hunting,
anything where each measurement changes the next move. Measure, change one thing,
measure again. Stop when two consecutive passes move nothing.

## Verification

Use the project's nearest configured commands: `package.json` scripts, `Makefile`,
`justfile`. Invent nothing. If none are configured, say so rather than fabricating
a check.

A regression test for a bug fix must fail before the fix and pass after. If you did
not watch it fail, you did not test the fix; you tested that the suite runs.

Green sub-computation is not green control flow. Drive the armed path end to end:
a wired hook, a registered handler, a fresh runtime. Built-but-unreachable is not
shipped.

## Hazards

- **Silent parameter drop.** A wrapper that ignores an argument runs its default
  while reporting your value. Echo-test each wrapper parameter once.
- **Sibling defects.** Root-cause the class, not the symptom. Grep for the same
  shape elsewhere and fix them together or write the survivors down.
- **Patch churn.** Three consecutive patches to one file with no metric moving
  means the abstraction is wrong. Stop; do not write a fourth.
- **Generated files.** Editing build output is invisible until the next build
  erases it. Find the source.
- **Bulk mechanical work.** Script it, dry-run on two files, inspect, then run the
  set. Deterministic beats agentic for renames and migrations.

## Optional skills

`debug` · `review` · `tearitapart` · `eval` · `app-dev` · `knowledge-graph` ·
`ship` · `forge` · `architecture`

Load a skill when its methodology is actually in play, not as a checklist.
