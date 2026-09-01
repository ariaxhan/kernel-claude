---
type: chronicle
status: active
created: 2026-09-01
---

# Lizard's false table became an AST-aware project gate

**What mattered:** Matra's “all complexity reduced” receipt was false: ESLint's AST found 66
functions over 15 and every returned-object method lizard omitted. Manual measurement could not
prevent recurrence, so simplify now ends only when the project's normal verify path owns the gate.

**Shipped**
- `scripts/complexity.{sh,py}`: ESLint AST, lizard fallback disclosure, `.ccnrc`, diffs, CI ratchet.
- `skills/{simplify,review}/SKILL.md`: per-function budgets, regression record, seeded armed gate.
- Ten focused regressions plus deterministic-review `NOT_CHECKED` analyzer failures.

**Verified how:** focused complexity 10/10; tokens 8/8; kernel9 1/1; real Matra scan listed
`createKnowledgeRepo` plus all 23 returned methods. Full suite: 506 pass, one unrelated existing
portable test failure; it writes `~/Vaults` in the real home, loses to existing
`~/Documents/Vaults`, then returns before cleanup. Exact empty residue removed.

**Wrong or surprising**
- A complete Matra AST snapshot is 7,336 functions/428 KB; the enforceable baseline needs only
  the 66 current over-budget rows. New over-budget functions are caught without a giant ledger.

**Open:** merge/release state and independent verifier verdict are recorded on the PR/AgentDB.
