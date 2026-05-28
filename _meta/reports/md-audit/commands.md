# Commands Audit — /commands/*.md
Generated: 2026-05-28

Files reviewed: 14
Total lines: 2,989

---

## FINDINGS

### 1. help.md — stale version number (HIGH)
**Tenet violated:** DEEP-UNDERSTANDING-FIRST (2) / STALE-vs-REALITY
Line 11: `Quick reference for KERNEL v7.6.1.` — CLAUDE.md declares `<kernel version="7.13.0">`.
Stale version is low-effort noise but signals the file is not maintained.
**Fix:** Change `v7.6.1` → `v7.13.0`.

---

### 2. handoff.md — wrong skill path (MEDIUM)
**Tenet violated:** STALE-vs-REALITY
Line 15: `Reference: skills/context/SKILL.md` — path does not exist.
Actual path is `skills/context-mgmt/SKILL.md`.
**Fix:** Change `skills/context/` → `skills/context-mgmt/`.

---

### 3. diagnose.md — missing `agentdb write-end` (MEDIUM)
**Tenet violated:** NO-DEFER (1) / consistency across sibling files
Every other stateful command (`review`, `validate`, `tearitapart`, `retrospective`, `handoff`) emits `agentdb write-end`. `diagnose.md` only emits via `<telemetry>` using `agentdb emit` but never records a checkpoint. Cross-session memory is incomplete for diagnosed bugs.
**Fix:** Add `<on_complete>` block after `<telemetry>` with:
```bash
agentdb write-end '{"command":"diagnose","mode":"bug|refactor","confidence":"high|medium|low","tier":N}'
```

---

### 4. dream.md — missing `agentdb write-end` (MEDIUM)
**Tenet violated:** NO-DEFER (1) / consistency with siblings
`dream.md` has `agentdb emit command "dream"` but never calls `write-end`. The exploration cycle is invisible to subsequent sessions.
**Fix:** Add `<on_end>` block at the bottom (before `</command>`):
```bash
agentdb write-end '{"command":"dream","topic":"X","survived":N,"chosen":"X","integrity":0.X}'
```

---

### 5. metrics.md — missing `agentdb read-start` and `write-end` (MEDIUM)
**Tenet violated:** DEEP-UNDERSTANDING-FIRST (2) / consistency
`metrics.md` calls `agentdb metrics` and `agentdb health` in `on_start`, but never calls `agentdb read-start` (which preloads context) or `write-end` (which records session output). All siblings call both.
**Fix:** Add `agentdb read-start` as first command in `on_start`. Add `<on_complete>` with a minimal `write-end`.

---

### 6. init.md — missing `agentdb write-end` (LOW)
**Tenet violated:** consistency
`init.md` runs agentdb init but never records a checkpoint. It's a one-shot setup command, so this is low severity — but the pattern is broken.
**Fix:** Add `agentdb write-end '{"command":"init","vaults":"$VAULTS"}'` at the end of Step 5 verify block.

---

### 7. metrics.md execution section — prose blob, not flow (LOW)
**Tenet violated:** STEP-BY-STEP FLOWS OVER BLOBS (9)
The `<execution>` block uses a numbered list but items 2 and 3 are prose paragraphs ("Analyze patterns…", "Present dashboard…") rather than executable steps with gates. Compare with how `retrospective.md` uses explicit bash commands per step.
**Fix:** Replace prose items 2-3 with:
```
2. Analyze output for:
   - Sessions getting longer → complexity creep
   - Adversary sample < 5 → under-reviewed
   - Hook failures → gate drift
   - Learnings unreinforced 30d+ → stale
3. agentdb health
4. Output: dashboard block + top 3 recommendations
```

---

## EXEMPLARS (do not change these — they embody the mindset)

- `commands/ingest.md` — complete step-by-step flows, branch gates, spec-completeness check, all three tenets (research-first, adversary, write-end) present
- `commands/review.md` — tight, scannable, confidence threshold table, Big 5 checks with grep detection commands, no prose bloat
- `commands/tearitapart.md` — clean phase structure, verdict gate with clear PROCEED/REVISE/RETHINK criteria

---

## Non-findings (reviewed, no action)

- `dream.md` test asserts `github_integration` presence — tag is present at line 175. Safe.
- `diagnose.md` test asserts `mode id="bug"` and `mode id="refactor"` — both present.
- `handoff.md` query `SELECT * FROM context WHERE type IN ('contract','checkpoint')` — `context` table with `ts` column confirmed in schema.sql. Query is valid.
- `ingest.md` step 5 `2b. If non-local profile: _gh_create_issue` — function exists in `hooks/scripts/github-integration.sh`. Valid reference.
- `forge.md` test asserts `"Measure entropy"` — present at line 79. Safe.
- `landing-page.md` — long (923 lines) but intentionally structured as a comprehensive scaffold generator with embedded code templates. Not a SKILL.md, no line cap applies to command files.
