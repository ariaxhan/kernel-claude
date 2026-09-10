---
type: report
status: active
created: 2026-09-10
---

# kernel:simplify audit (2026-09-10)

## 1. Current rule
`skills/simplify/SKILL.md` (157 lines, v9.10.3). Two-layer rule since 0e87640:

- **Destination invariant (2026-09-03):** simplification changes how outcomes are delivered,
  never which outcomes exist. Step 1 freezes a preservation contract (outcomes, features,
  behaviors, constraints, acceptance conditions); step 2 traces every item to the proposed
  result; step 8 re-checks item by item. "Later / not now / manual for the pilot / narrower
  audience" counts as a scope cut unless the source of truth already said it.
- **Measured code layer (2026-08-27, 24cf67d):** `scripts/complexity.sh` -> `complexity.py`.
  ESLint AST for JS/TS, lizard fallback (labelled on stderr, not proof for object-literal
  methods). `.ccnrc` budgets + reasoned skips. Ladder 1-5 leave / 6-10 if touching /
  11-15 refactor / >15 split. `--diff` regression rows, `--check-baseline` CI ratchet.
  Exit 2 invalid config, exit 3 no analyzer, both block.
- Gate wiring into the project's own verify path is mandatory, proven red on a seeded
  over-budget fixture then green.
- Builder never signs its own result: verifier gets DISCOVERY AXIS: invariant.

## 2. Usage across the vaults
Since first ship 2026-08-27 (15 days).

| Signal | Count |
|---|---|
| Claude sessions invoking the skill (`Skill` tool 33 + `/kernel:simplify` 8) | 38 |
| Codex sessions that actually loaded `skills/simplify/SKILL.md` | 57 |
| Codex sessions that emitted a `## Complexity report` | 57 |
| Total real runs | ~95 |
| Ambient mentions (routed by CLAUDE.md/AGENTS.md, not runs) | 2563 files / 526 `$kernel:simplify` |

Heaviest callers: Vaults root, CollabVault, tbs-care, buzz, nexus-office, matra.

## 3. Results
Wins (measured):
- nexus-office `office-sync.py`: CCN 50/47/31 -> 14/10/10, 535 tests green (first dogfood).
- matra repo-wide 2026-09-01: 26 functions over 15 -> all <=15, worst 98 -> 1, three
  file-disjoint surgeon lanes, adversary re-measured, 1030 tests green, shipped + TestFlight.
- V4 site: `build.mjs` 495 -> 77 lines, 10 modules, byte-identical output proven by a
  checked-in 41-file SHA-256 manifest, all complexity exceptions removed.

Failures the skill itself caused or missed:
- **2026-09-04 (the expensive one):** two independent Codex lanes read "simpler" as "smaller
  product". Nexus Office foundation lane deleted plan capabilities; TBS CTO lane deferred
  newsletter, localization, brand, physical, annual. Fixed by 0e87640 the day before, so the
  fix landed but the lanes still drifted -> the rule is stated, not enforced.
- **Measurement blindness:** lizard never enters methods in the object literal returned by
  `createKnowledgeRepo`; the baseline "toFtsQuery 21" was a mis-parse over 469 NLOC. Matra had
  66 functions over 15 under ESLint AST that lizard reported as zero.
- **Gate leak:** the ESLint parser matched only named-function messages, so `npm verify` passed
  with an AST-measured CCN 16 arrow in `assets/site.js`. Now fixed (`arrow_name`, parser
  fail-closed).
- **Environment:** V4 analyzer died on `~/.cache/uv` denied by the workspace sandbox.
- **Verifier substitution:** Codex runs mostly report `Verified by: /root/simplify_verifier`
  or `primary lane validation`; Claude runs report `Verified by: self, ...` /
  `builder self-measure`. The independent-verifier rule is the most-skipped clause.
- **Template echo:** 79 occurrences of the literal `Verified by: <verifier identity>` in
  transcripts. The output block is being pasted, not filled.

## 4. Gaps found, and what was done (2026-09-10)

| Gap | Fix |
|---|---|
| No non-code mode; plans/docs runs emitted meaningless `Reduced: 0` | `<mode>` block: `code` vs `system`, each with its own report shape |
| Preservation contract lived only in the model's head | Step 1 writes `.simplify-contract.md`; steps 9 and the verifier diff the file |
| Scope-cut rule was prose with nothing checking it | Verifier CHECK diffs the contract file line by line against source of truth and result |
| Sequencing-is-not-deletion unenforced | Step 9 + `system` report require a delivery route and acceptance condition per deferred line |
| Analyzer died mid-run (uv cache, missing ESLint, stale baseline) | New `<preflight>` block; `complexity.py` now redirects an unwritable uv cache to tmp on its own |
| Baseline drifted from the default branch | Preflight diffs `.complexity-baseline.tsv` / `.ccnrc` against `origin/<default>`; step 8 commits the baseline and records its ref |
| `Verified by: self` / builder-written verify script accepted | Hard rule bans self, `builder self-measure`, `primary lane validation`, builder-authored scripts, and template placeholders |
| Nothing told the skill to delete rather than repair | New `<deletion_doctrine>`: broken test, guard, path or superseded machinery gets deleted unless it is on the contract, is the sole defense against an irreversible failure, or is a published contract. Deletion is tactic #1. |

Deliberately not built: a hook that refuses self-signed reports. The vault rule is to prevent at
the state transition, not to detect afterward, and the skill now refuses to emit an unsigned
report. Add the hook only if the rule is observed being skipped again.

## 5. Side effect: the ambient ratchet was already red
`tests/kernel9/test_ambient_budget.py` measured 4147 tok against a 4000 ratchet BEFORE this
change; skill descriptions had drifted since 9.6.0. The guard earns its keep (every user pays it
every session), so it was fixed, not deleted: 13 skill descriptions trimmed of restatement and
dead trigger words (frontend alone carried 16 internal mood codenames that the skill body already
lists). Now 3993 tok, green.
