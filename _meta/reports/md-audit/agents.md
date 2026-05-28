# Agent Files Audit — agents/*.md

**Date:** 2026-05-28
**Files audited:** 16
**Auditor:** subagent (sonnet-4-6), read-only

---

## Findings

### F1 — dreamer.md: missing on_start, on_end, checklist, agentdb write-end, agent wrapper

**File:** `agents/dreamer.md`
**Tenets violated:** 9 (flows over blobs), 6 (measure impact), 10 (agent-reader optimized)
**Severity:** medium

dreamer.md is structurally incomplete vs every other agent in the directory. It has:
- No `<on_start>` block (no `agentdb read-start` or `inject-context`)
- No `<on_end>` block with `agentdb write-end` — the `<agentdb>` block uses `agentdb emit command` for event tracking only, which is not the session-end checkpoint
- No `<checklist>` section
- No `<agent id="...">` wrapper (every other agent has one)

Result: dreamer sessions leave no session-end record in AgentDB, breaking continuity (tenet 2: DEEP-UNDERSTANDING-FIRST). A future session's `read-start` will not see what dreamer did.

**Fix:**
1. Wrap content in `<agent id="dreamer">...</agent>`
2. Add `<on_start>agentdb read-start</on_start>` after frontmatter
3. Add `<on_end>agentdb write-end '{"agent":"dreamer","topic":"X","chosen":"X"}'</on_end>`
4. Add `<checklist>` with: codebase scanned, 3 perspectives generated, written to _meta/dreams/, user prompted, AgentDB recorded

**Test coupled:** tests assert `minimalist`, `maximalist`, `pragmatist` exist and frontmatter starts with `---` — none of these are broken by adding the lifecycle blocks.

---

### F2 — approval-learner.md: write-end in wrong tag, no checklist

**File:** `agents/approval-learner.md`
**Tenets violated:** 9 (flows over blobs), 10 (agent-reader optimized)
**Severity:** medium

`agentdb write-end` is inside an `<output>` tag instead of an `<on_end>` tag. No `<checklist>` section exists. Every other complete agent (adversary, analyzer, blind-evaluator, cartographer, coroner, deep-diver, pre-ship, researcher, reviewer, scout, surgeon, validator) uses `<on_end>` and `<checklist>`. The inconsistency means an agent reader scanning for `<on_end>` to find its mandatory terminal action will not find it.

**Fix:**
1. Move the `agentdb write-end` block out of `<output>` into a proper `<on_end>` block.
2. Add `<checklist>` with items: PR context fetched, comments classified, patterns extracted, existing rules checked, AgentDB updated, promotion threshold evaluated, contradictions surfaced to user.

**Test coupled:** tests assert `confidence_scoring`, `times_validated / times_applied`, `progressive trust`, `observe.*suggest.*enforce`, `model: sonnet` — none touched by structural fix.

---

### F3 — triage.md / understudier.md: skill_load outside `<agent>` wrapper

**File:** `agents/triage.md`, `agents/understudier.md`
**Tenets violated:** 10 (agent-reader optimized), 9 (flows over blobs)
**Severity:** low

Both files close their `</agent>` tag before the `<skill_load>` block. The `skill_load` lines appear after `</agent>`. An agent reader executing in document order will see the agent definition end before the skill_load instruction, meaning the load might be skipped or appear as orphaned context.

```
# triage.md line 86: </agent>
# triage.md line 88: <skill_load>reference: skills/quality/SKILL.md</skill_load>
```

Additionally, both triage and understudier have `inject-context triage|understudier` as a valid type in `agentdb inject-context` (orchestration/agentdb/agentdb line 1330) but both use `agentdb read-start` instead. The specialized context slice (complexity signals + recent contracts) would be more relevant than the generic read-start output.

**Fix (each file):**
1. Move `<skill_load>` inside `</agent>` (before closing tag).
2. Change `agentdb read-start` to `agentdb inject-context triage` (triage) and `agentdb inject-context understudier` (understudier) to receive the complexity-relevant context slice.

**Test coupled:** tests assert `model: haiku`, `viable|risky|blocked`, `low.*medium.*high.*epic` — none touched.

---

### F4 — triage.md / understudier.md: no checklist

**File:** `agents/triage.md`, `agents/understudier.md`
**Tenets violated:** 9 (flows over blobs)
**Severity:** low

Both agents have `on_start`, `on_end`, protocol, and output but no `<checklist>`. All 10+ other complete agents have checklists — they serve as the final executable gate before `on_end`. Missing checklist means no gate before the agent writes to AgentDB.

**Fix (triage):** Add checklist: [ ] AgentDB context read, [ ] file count verified, [ ] risk signals checked, [ ] classification assigned with reasoning, [ ] YAML output produced.

**Fix (understudier):** Add checklist: [ ] Contract files exist on disk, [ ] imports/exports compatible, [ ] no recent commits conflict, [ ] dependencies present, [ ] test infra exists, [ ] viability verdict written.

---

### F5 — validator.md: safety_chain (Gates 7-9) describes pre-ship pipeline, not validator scope

**File:** `agents/validator.md`
**Tenets violated:** 8 (don't overengineer), 10 (agent-reader optimized)
**Severity:** low

The `<safety_chain>` section lists 9 gates. Gates 7-9 (adversarial review, human checkpoint, post-merge monitoring) are NOT run by the validator agent — they are run by reviewer/adversary, the human, and post-merge monitoring respectively. The validator's own protocol has 7 phases (secrets → scope → big5 → types → lint → tests → commit). The safety_chain inclusion makes the validator appear responsible for work it doesn't do, which could cause an agent to wait for or attempt those gates.

Adding a note like `# Validator runs Gates 1-6. Gates 7-9 are pre-ship pipeline steps run by other agents.` would clarify scope without removing the text.

**Test coupled:** YES — `test_validator_has_9_gates` asserts `Gate 1:` and `Gate 9:` exist. DO NOT remove those lines. Only add a scope clarification comment before Gate 7.

---

### F6 — reviewer.md: on_start uses inject-context adversary, not inject-context reviewer

**File:** `agents/reviewer.md`
**Tenets violated:** 4 (DRY / battle-tested — use the canonical pattern)
**Severity:** low

`reviewer.md` calls `agentdb inject-context adversary` at startup. The inject-context implementation (agentdb line 1313) maps `adversary|reviewer` to the same context slice, so this is functionally correct. But the intent reads as "reviewer is just an alias for adversary" — it would be clearer and more self-documenting to call `agentdb inject-context reviewer`. No behavior change.

**Fix:** Change line 17 from `agentdb inject-context adversary` to `agentdb inject-context reviewer`.

**Test coupled:** No test asserts the inject-context call form in reviewer.md.

---

## Exemplars (files that embody the mindset well — do not modify)

- `agents/adversary.md` — clear phased protocol, coordination check first, explicit PASS/FAIL with no middle ground, complete lifecycle.
- `agents/coroner.md` — best use of numbered phases with explicit output per phase, AgentRx taxonomy integration, complete checklist.
- `agents/surgeon.md` — worktree_safety section is a textbook numbered executable flow. No prose hedging.

---

## Summary table

| Finding | File(s) | Severity | Effort | Test coupled |
|---------|---------|----------|--------|--------------|
| F1: Missing on_start/on_end/checklist/agent wrapper | dreamer.md | medium | small | no |
| F2: write-end in wrong tag, no checklist | approval-learner.md | medium | trivial | no |
| F3: skill_load outside agent tag; wrong inject-context type | triage.md, understudier.md | low | trivial | no |
| F4: Missing checklist | triage.md, understudier.md | low | trivial | no |
| F5: safety_chain describes out-of-scope gates | validator.md | low | trivial | YES — preserve Gate 9: |
| F6: inject-context adversary vs reviewer label | reviewer.md | low | trivial | no |
