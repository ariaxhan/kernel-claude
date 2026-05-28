# Skills SKILL.md Audit — 2026-05-28

**Files reviewed:** 20  
**Budget cap (CLAUDE.md):** 80L per SKILL.md  
**Files over cap:** 16 of 20

---

## High-Severity Findings

### F1 — build/SKILL.md: 340L blob (180+ lines over budget)
Lines 1–158 are usable executable content (goal extraction, solution exploration, research cache, execution, validation, failure handling). Lines 159–340 are four back-to-back prose blobs: CONTEXT ENGINEERING, AGENTIC BUILD PATTERNS, CONTEXT WINDOW HYGIENE, VELOCITY CALIBRATION, FLAGS. These contain research notes, historical context, and explanatory narrative — none of it as ordered executable steps. The build-research.md reference file already exists at 353 lines. This content belongs there, not inline. Tenet violations: 9 (blob not flow), 10 (not agent-readable), 8 (overengineered).

### F2 — 8 skills missing `agentdb write-end` (broken learning loop)
The following skills have no `on_complete` block: app-dev, architecture, context-mgmt, experiment, git, performance, quality, security. The CLAUDE.md `anti_patterns` block explicitly marks `skip_agentdb_write` as a critical failure. A skill that runs but never writes to AgentDB silently breaks continuity — the next session can't learn from this one. Tenet violations: 1 (no-defer — known gap, not tracked), 6 (measure-impact — no evidence loop).

### F3 — quality/SKILL.md: missing `on_complete` but test-coupled content
The r_factor formula (lines 61–92) and adsr block (lines 93–119) are asserted by tests (lines 1873, 1880, 1884, 2051 of run-tests.sh). The `on_complete` block is absent. When the quality skill runs, no verdict or R-factor result gets written to AgentDB. The R-factor is computed but never recorded — the `/kernel:metrics` dashboard that reads it gets nothing. Tenet violations: 1 (no-defer), 6 (measure-impact broken).

---

## Medium-Severity Findings

### F4 — debug/SKILL.md: 248L over budget; PERSISTENT_TRUTH_FILE and TOOLING_2026 sections are blobs
Lines 1–127 are well-structured XML phases (scientific_method, reproduce, isolate, root_cause, fix, cognitive_biases, anti_patterns, escalation) — correct flow format. Lines 130–248 are prose blobs: parallel_debug_strategy, agentic_debugging, persistent_truth_file, tooling_2026, debugger_mcp_integration, verbose_flag. These describe techniques but give no ordered steps. The content is research-level detail that belongs in debug-research.md. Tenet violations: 9 (blob not flow), 10 (not terse/scannable).

### F5 — Inconsistent adversarial verification: only orchestration/SKILL.md references the adversary agent
Every skill should end with adversarial verification for T2+ work. orchestration/SKILL.md references the adversary concept; the other 19 do not. ship/SKILL.md indirectly invokes it via /kernel:review. build/SKILL.md has a FAILURE HANDLING section but no "spawn adversary on your output." This is a consistency gap — the principle exists in CLAUDE.md but is not reinforced by individual skill flows. Tenet violation: 5 (adversarial verification not enforced in skill flows).

### F6 — build/SKILL.md: EXECUTION section (lines 114–121) is a blob, not a flow
"BEFORE each step: review research doc...  DURING: ...  AFTER: ..." is three sentences, not numbered steps. An agent executing this skill gets no ordered sequence for the execution phase — just three temporal markers with dense prose. Compare to debug/SKILL.md's numbered scientific_method phase — that's the correct pattern. Tenet violation: 9 (step-by-step flow over blob).

### F7 — context-mgmt/SKILL.md: name mismatch in frontmatter
The frontmatter declares `name: kernel:context` (line 2) but the directory and CLAUDE.md skill declaration use `context-mgmt`. The skill id attribute uses `context-mgmt`. The `name:` field is inconsistent and would fail any name-based lookup. Tenet violation: 4 (DRY/consistency — same thing named two ways).

### F8 — security/SKILL.md and architecture/SKILL.md: no `on_complete` + no measure-impact
security/SKILL.md (334L, over budget) defines good checklists but has no `on_complete` to record what was checked. architecture/SKILL.md (58L, under budget) has no `on_complete` and no way to know if the architecture review actually improved anything. Both lack MEASURE-IMPACT enforcement. Tenet violations: 1 (no-defer), 6 (measure-impact).

---

## Low-Severity Findings

### F9 — performance/SKILL.md (63L) and architecture/SKILL.md (58L): no `on_complete`
Both are appropriately lean but skip the AgentDB write-end. Given they're tiny and could add a one-line `on_complete` without bloating, the cost is low. Tenet violation: 6 (measure-impact — no evidence loop after running).

### F10 — tdd/SKILL.md: CORE_PRINCIPLES item 4 "80% COVERAGE MINIMUM" contradicts testing/SKILL.md golden_ratio_principle
tdd/SKILL.md line 28: "80% COVERAGE MINIMUM: Unit + integration + E2E. All edge cases covered." testing/SKILL.md line 89: "Test coverage follows diminishing returns past ~80%. Beyond that, invest in mutation testing..." These are not contradictory per se but the framing differs: tdd says 80% is the floor, testing implies 80% is nearly the ceiling. An agent loading both skills gets a mixed signal. Tenet violation: 4 (DRY — inconsistent guidance between siblings).

### F11 — experiment/SKILL.md: missing `on_complete`, but its own lifecycle writes to AgentDB via seeding schema
The experiment skill describes writing to `hypotheses` and `experiments` tables directly via SQL (lines 165–192). The `on_complete` section is absent, but the skill is unusual: it IS the recording mechanism. However it still doesn't end with an `agentdb write-end` call for the session-level summary. Low impact since the experimental writes happen inline. Tenet violation: 6 (minor — measure-impact not fully closed).

---

## Exemplars (do not modify)

- `skills/ship/SKILL.md` — 123L, ordered phases with gates, explicit AskUserQuestion points, failure_modes list, clean `on_complete`
- `skills/orchestration/SKILL.md` — heavy but every section is XML-structured with named ids, all test assertions present, no narrative prose
- `skills/debug/SKILL.md` — lines 1–127 are the exemplar section: XML phases with scientific_method, numbered steps, cognitive_biases as structured blocks

---

## Test-coupling summary

| File | Asserted strings (run-tests.sh) | test_coupled |
|---|---|---|
| skills/orchestration/SKILL.md | `worktree_safety`, `constraints.files`, `Post-agent validation`, `knowledge_injection`, `progressive_autonomy`, `budget_awareness`, `checkpoint_recovery`, `entropy_adaptive` | YES |
| skills/quality/SKILL.md | `r_factor`, `0.20 * test_pass_rate`, `0.15 * scope_accuracy`, `adsr` | YES |
| skills/app-dev/SKILL.md | `store submission\|Store Submission\|App Store\|Play Console`, `app.*mobile\|EAS\|store submission\|expo\|react native` | YES |
| All others | frontmatter `---` only | NO |
