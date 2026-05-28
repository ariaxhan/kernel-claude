---
date: 2026-05-28
status: waves-A-B-shipped (commit cb3e14c); wave-C pending user decision
scope: KERNEL plugin .md corpus (skills/, commands/, agents/, root CLAUDE.md)
files_reviewed: 50 (20 skills + 14 commands + 16 agents)
regression_guard: "bash tests/run-tests.sh stays at 242 passed, 0 failed"
tenets_enforced: [1 NO-DEFER, 4 DRY, 6 MEASURE-IMPACT, 9 STEP-BY-STEP, 10 AGENT-READER]
---

## STATUS (2026-05-28)

**Shipped — Waves A + B (commit cb3e14c, branch chore/kernel-md-consistency, suite 242/0):**
- write-end bookend added to 8 skills (architecture, context-mgmt, experiment, git,
  performance, quality, security, app-dev) — each payload carries a measurable field.
- read-start added to diagnose + dream (analysis-entry commands).
- dreamer name `kernel:dreamer`→`dreamer` (fixed real `kernel:kernel:dreamer` double-prefix).
- ship/context-mgmt frontmatter names normalized to bare; reviewer inject-context fixed;
  help version + handoff dead-path corrected.

**Deviations from the proposal (judgment, anti-overengineering):**
- Did NOT add write-end to diagnose/dream/metrics/init — they already record via
  `agentdb emit` or are read-only/bootstrap. Forcing write-end there = cargo-cult.
- triage/understudier/approval-learner left intact — verified already well-formed
  (bookends present). The audit's "orphan/missing" claim was a misread.
- validator gate-comment skipped (cosmetic; risks the gate-count test).

**Pending — Wave C (needs user decision; see §4 WAVE C below).** Subjective + higher-risk
blob→reference extraction and prose→numbered-steps rewrites. NOT executed unilaterally.

# KERNEL .md Philosophy Enshrinement — Prioritized, Test-Safe Change Plan

## 0. Root CLAUDE.md verdict (judged against the 10 tenets)

The `<kernel version="7.13.0">` root is an **exemplar** and must NOT be restructured.
It models exactly what the corpus should converge to:
- Tenet 9: `<flow>` is ordered numbered/id'd steps with explicit `<branches>` and retry caps — not prose.
- Tenet 1+6: `<agentdb>` block makes read-start/write-end the mandatory bookends; `<anti_patterns>` hard-blocks `skip_agentdb_write`.
- Tenet 10: terse XML, scannable, no marketing prose.
- Tenet 2: the header comment (lines 6-19) correctly warns the file is NOT loaded for plugin users and that session-start.sh is the real delivery channel.

**One root-level consistency note (not a code change, a doctrine point):** the root declares
`skip_agentdb_write` a *critical failure*, yet 8 skills + 2 commands + 1 agent ship with no
write-end. The corpus violates its own root invariant. That is the single highest-leverage gap
(see §4). The root itself is correct; the children drifted from it.

---

## 1. Dedupe + Rank by leverage

Findings collapse into **four repeating defects**, not 24 unique ones. Ranking by how many
files a single canonical fix improves:

| Rank | Defect class | Tenet | Files affected | Leverage |
|------|-------------|-------|----------------|----------|
| **L1** | **Missing `agentdb write-end` / `<on_end>` terminal block** | 1 + 6 | 8 skills (app-dev, architecture, context-mgmt, experiment, git, performance, quality, security), 3 commands (diagnose, dream, init), 1 cmd partial (metrics also missing read-start), 2 agents (dreamer, approval-learner) | HIGHEST — restores the root's own mandatory bookend across 13 files, one identical pattern |
| **L2** | **Stale / wrong cross-references (STALE-vs-REALITY)** | 2 + 4 | help.md (v7.6.1→7.13.0), handoff.md (skills/context→context-mgmt), context-mgmt frontmatter (name: kernel:context→context-mgmt), reviewer.md (inject-context adversary→reviewer) | HIGH — 4 one-token edits, each kills a trust-eroding lie an agent reads as fact |
| **L3** | **Prose blobs where ordered steps belong; reference material inlined in SKILL.md over cap** | 9 + 10 | build (340L), security (334L), debug (248L), git (160L), metrics.md exec items 2-3, build EXECUTION section | MEDIUM — improves executability; bounded line-count wins; per-file judgement |
| **L4** | **Structural drift: tags out of `<agent>` order, missing `<checklist>`, wrong wrapper** | 9 + 10 | triage (skill_load after </agent>), understudier (same), approval-learner (write-end in `<output>`), dreamer (no wrapper/checklist), validator (out-of-scope gates 7-9 unlabeled) | MEDIUM — structural consistency for the agent reader |

---

## 2. Cross-file consistency pass (DRY — define once, reference)

**Unevenly enforced tenets and their canonical home:**

1. **AgentDB bookends (read-start / write-end).** Canonical definition already lives in root
   `<agentdb>`. The children should not redefine it — they should each carry the *minimal
   terminal one-liner* with skill/command/agent-specific payload. This is the L1 fix. The
   *pattern* is DRY (defined in root); the *instances* are required per-file because each agent
   actually executes its own write-end with its own payload.

2. **`inject-context <role>` slices.** agentdb maps `adversary|reviewer` and `triage`/
   `understudier` to specialized slices. reviewer.md mislabels itself as adversary; triage/
   understudier use generic read-start instead of their dedicated slice. Canonical: each agent
   names its OWN role in inject-context. No shared file needed — just self-consistent labels.

3. **Reference material vs. SKILL.md.** Canonical home for context-engineering notes, agentic
   patterns, tooling surveys = `skills/<id>/reference/<id>-research.md` (already exists for
   build, debug, git). SKILL.md = ordered executable steps + gates + on_complete ONLY. This is
   the DRY home for L3 prose.

**Prose duplicated across many files:** the BEFORE/DURING/AFTER and "analyze patterns and
surface insights" style narrative recurs in build EXECUTION and metrics exec items. Replace with
numbered steps (see §3 template). No single shared file — the fix is structural, not extraction.

---

## 3. Shared flow-template (convert blob-heavy SKILL.md to this)

Every SKILL.md should reduce to this skeleton (the root `<flow>` already models it):

```
<skill id="X" triggers="...">
  <on_start>agentdb read-start  # or inject-context <role> for agents</on_start>
  <flow>
    1. <verb> ... (gate: <observable condition>)
    2. <verb> ... (gate: ...)
    3. <verb> ...
  </flow>
  <gates>build | types | lint | tests | security — any fail = block</gates>
  <on_complete>agentdb write-end '{"skill":"X", "<metric>":N, ...}'</on_complete>
</skill>
# Deep explanation / patterns / tooling surveys → skills/X/reference/X-research.md
```

Rule: SKILL.md holds **what the agent executes**; `reference/*-research.md` holds **why / context
the agent consults on demand**. Numbered ordered steps with inline gates replace every prose blob.

---

## 4. WAVES

### WAVE A — high-leverage, low-risk, NOT test-coupled (safe now)

These are additive one-liner inserts and single-token corrections. None touch a string any test
greps for (verified against tests/run-tests.sh — see §5 exclusion list).

**A1. Add `<on_complete>` agentdb write-end to skills missing it (NOT quality, NOT app-dev — those are Wave B):**
- skills/architecture/SKILL.md
- skills/context-mgmt/SKILL.md
- skills/experiment/SKILL.md
- skills/git/SKILL.md
- skills/performance/SKILL.md
- skills/security/SKILL.md
(payloads as recommended in each finding)

**A2. Add `<on_end>` / write-end to commands missing it:**
- commands/diagnose.md, commands/dream.md, commands/init.md
- commands/metrics.md: add `agentdb read-start` to `<on_start>` AND `<on_complete>` write-end

**A3. Stale-reference single-token fixes:**
- commands/help.md line 11: `v7.6.1` → `v7.13.0`
- commands/handoff.md line 15: `skills/context/SKILL.md` → `skills/context-mgmt/SKILL.md`
- skills/context-mgmt/SKILL.md line 2: `name: kernel:context` → `name: context-mgmt`
- agents/reviewer.md line 17: `inject-context adversary` → `inject-context reviewer`

**A4. Agent structural fixes (no asserted strings):**
- agents/dreamer.md: wrap in `<agent id="dreamer">`, add `<on_start>` read-start, `<on_end>` write-end, `<checklist>`
- agents/approval-learner.md: move write-end from `<output>` into new `<on_end>`; add `<checklist>`
- agents/triage.md: move `<skill_load>` inside `</agent>`; `read-start` → `inject-context triage`; add `<checklist>`
- agents/understudier.md: move `<skill_load>` inside `</agent>`; `read-start` → `inject-context understudier`; add `<checklist>`

Wave A total: ~17 files, all additive/single-token. Run `bash tests/run-tests.sh` after.

### WAVE B — test-coupled: MUST preserve asserted strings

Edit allowed, but the listed grep target must survive verbatim. Add on_complete AFTER the
asserted content; never alter the asserted token.

| File | Change | Asserted string to PRESERVE | Test |
|------|--------|-----------------------------|------|
| skills/quality/SKILL.md | add `<on_complete>` write-end after adsr block | `r_factor`, weighted formula incl `test_pass_rate`, `scope_accuracy`, `adsr` | test_quality_skill_has_r_factor (L1872), test_r_factor_has_weighted_formula (L1879), test_quality_has_adsr (L2050) |
| skills/app-dev/SKILL.md | add `<on_complete>` write-end at end; do NOT rewrap in XML this wave | `store submission`/`App Store`/`Play Console`, and `EAS`/`expo`/`react native` | test_app_dev_has_store_submission (L2033), test_app_dev triggers (L2037) |
| agents/validator.md | add clarifying comment before Gate 7 (validator runs 1-6; 7-9 owned elsewhere) | must NOT remove `Gate 9` — keep all 9 gate lines | test_validator_has_9_gates (L1824) |

### WAVE C — judgement calls / risky / subjective (needs user sign-off)

- **C1. Blob→reference extraction for over-cap SKILL.md** (build 340L→~80, debug 248L→~130,
  git 160L→~114, security 334L stays mostly code). Moving 100-180 lines per file into
  `reference/*-research.md`. Risk: a test or hook may grep a string that lives in the moved
  region. MUST grep each moved block against run-tests.sh + hooks/ before cutting. Net line
  reduction is real value but this is the only destructive-ish wave.
- **C2. build EXECUTION + metrics exec-items prose→numbered steps** (tenet 9 rewrite). Subjective
  wording; pairs naturally with C1 for build.
- **C3. tdd "80% MINIMUM"→"TARGET"** reframing to de-conflict with testing golden_ratio. Low
  severity, semantic nuance — confirm the threshold intent with user before softening "MINIMUM".
- **C4. app-dev XML rewrap** (cosmetic consistency) — explicitly deferred; not worth the risk.

---

## 5. ALREADY GOOD — do NOT touch (exemplars)

- root **CLAUDE.md** `<kernel>` block — the reference structure all of the above converges to.
- skills/**ship**/SKILL.md, skills/**orchestration**/SKILL.md
- commands/**ingest**.md, commands/**review**.md, commands/**tearitapart**.md
- agents/**adversary**.md, agents/**coroner**.md, agents/**surgeon**.md

These already carry on_start + on_end + checklist + numbered flows. Copy their shape; don't edit them.

## 6. Regression guard

After EACH wave: `bash tests/run-tests.sh` must report **242 passed, 0 failed**. Wave B is the
only wave that can break a test — the preserve-string table in §4 is the gate. If C1 moves any
line, grep the moved text against `tests/run-tests.sh` and `hooks/` FIRST; abort the cut if it hits.
