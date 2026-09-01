---
type: commission
status: complete
created: 2026-09-01
---

# Complexity enforcement

## Goal

Make `simplify` and `review` enforce measured complexity: AST-aware TypeScript scanning,
explicit exceptions, per-function budgets, regression diffs, and project verify wiring.

## Boundaries

- Kernel skill, analyzer, deterministic-review, tests, changelog, plan, review, chronicle only.
- Preserve existing public CLI behavior unless a new flag is used.
- No target-project mutation or new dependency.

## Done when

- Object-literal methods are measured through an installed ESLint parser; lizard remains fallback.
- `.ccnrc` and `--skip` support named budgets and justified exceptions.
- Baseline comparison emits reduced, unchanged, regressed counts and fails regressions.
- Both skills require a checked project verify/pre-commit path.
- Seeded fixtures, focused suite, real Matra probe, diff check, and full suite run are evidenced;
  unrelated existing red is isolated and reported.
