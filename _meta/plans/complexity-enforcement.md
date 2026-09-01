---
type: note
status: active
created: 2026-09-01
---

# Complexity enforcement

## Contract

- Goal: complexity becomes an AST-aware, configurable, regression-tracked build gate.
- Inputs: `.ccnrc`, source tree, optional base ref or baseline TSV.
- Outputs: budget violations or a per-function regression diff.
- Done: commission acceptance checks pass.

## Options

1. Lizard filters only: smallest; object-literal blindness remains. Rejected.
2. Existing ESLint AST for JS/TS, lizard fallback, stdlib config/diff layer. Chosen.
3. Custom TypeScript AST analyzer: full control; duplicates maintained parser logic. Rejected.

## Check

`tests/run-tests.sh complexity`; seeded object-method probe; `.ccnrc` budget/skip probes;
baseline regression probe; real Matra `knowledge-repo.ts` method scan; `tests/run-tests.sh`;
`git diff --check`.
