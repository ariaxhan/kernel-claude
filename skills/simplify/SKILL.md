---
name: simplify
description: "Reduce cyclomatic complexity with a number, not an opinion. Measures every function with lizard, refactors the worst first, refuses to game the metric, and hands the before/after table to a verifier that re-measures. Triggers: simplify, refactor, complexity, spaghetti, nested, god function, untangle."
user-invocable: true
allowed-tools: Agent, Bash, Read, Edit, Write, Grep, Glob
kernel:
  kind: workflow
  version: 1
  side_effects: writes_source
  confirmation: none
---

<skill id="simplify">

<purpose>
AI-written code works but branches like a jungle. This skill forces one measurement the model
cannot skip (cyclomatic complexity per function, from a tool) and names the one way it will
cheat (hiding branches in dense one-liners). Prose about "cleaner code" is not accepted; the
number is.

Adapted from saurabhkumar8112/cyclomatic-complexity-skill (Apache-2.0), with one change:
the refactoring model never signs its own before/after table. A verifier re-measures.
</purpose>

<on_start>
agentdb recall "simplify complexity <files/symbols>" --global
</on_start>

<measure>
```bash
# whole repo, worst first (TSV: file, line, function, ccn, nloc)
${CLAUDE_PLUGIN_ROOT}/scripts/complexity.sh <repo-dir>
# only what this branch changed
${CLAUDE_PLUGIN_ROOT}/scripts/complexity.sh <repo-dir> <base-ref>
```
The project's own linter config wins. If eslint `complexity`, radon, sonar, or golangci
sets a threshold, pass it: `CCN_MAX=<n> scripts/complexity.sh ...`. No config: default 15.

Exit 3 means no lizard and no uvx. Say so and count by hand (decision points + 1:
`if`, `elif`, `case`, loops, `catch`, ternary, `&&`/`||` in conditions). Never skip silently.

Ladder (default, project config outranks it):
- 1 to 5: leave alone
- 6 to 10: refactor only if already touching
- 11 to 15: refactor now
- over 15: must split
</measure>

<workflow>
1. Measure. Print the table before touching anything. Rank by CCN descending.
2. Confirm tests exist and pass. None: say so, refactor conservatively, propose one test per
   extracted function.
3. Refactor worst first, one function at a time, commit each working state.
4. Re-measure the same command. Print before/after.
5. Hand off to the verifier (below). Its re-measure is the record, not yours.
</workflow>

<tactics order="preference">
1. Guard clauses: invert, return early, kill nesting.
2. Extract function. The name says what, not how. Names are documentation.
3. Lookup table or map instead of if/else or switch chains.
4. Named predicates: `if is_eligible_for_refund(order)` beats a four-clause boolean.
5. Polymorphism or strategy for switch-on-type, only when the switch appears in 2+ places.
6. Flatten loops: extract the body, `continue` instead of nested `if`.
</tactics>

<hard_rules>
- Preserve behavior. Tests before and after. Same inputs, same outputs, same errors.
- Do not game the metric. A dense one-liner hiding six branches is worse than the honest
  if-chain it replaced. Complexity moves into named units; it never disappears into cleverness.
  A CCN drop with a rising token count per line is the tell.
- Do not change public APIs or exported signatures without asking.
- One responsibility per function. If the name needs "and", split again.
- Small functions with clear names beat few functions with section comments.
</hard_rules>

<verify>
Spawn a verifier that never saw this session's reasoning. It receives: the diff, the before
table, the claimed after table, the test command, and this contract:

```
ACCEPTANCE: every function in the before table is at or under the after value claimed
ACCEPT WHEN: complexity.sh re-run matches the claimed after table; tests pass; no exported signature changed
CHECK: ${CLAUDE_PLUGIN_ROOT}/scripts/complexity.sh <repo> <base-ref>; <test command>; git diff <base-ref> -- <files> | grep -E '^[-+](def |export |func |pub fn )'
ESCALATE IF: any function's re-measured CCN exceeds the claim, or a one-liner replaced a branch without a name
DISCOVERY AXIS: invariant
```
Builder and verifier identities go on the receipt. The builder never fills in "behavior verified".
</verify>

<output>
End with, and nothing after it:
```
## Complexity report
| Function | Before | After |
|----------|--------|-------|
| parse_order | 14 | 4 |

Extracted: validate_header, resolve_discount
Tests: <command> <pass/fail before> -> <pass/fail after>
Verified by: <verifier identity> (re-measured: match | mismatch)
```
Keep prose minimal. Numbers and diffs do the talking.
</output>

</skill>
