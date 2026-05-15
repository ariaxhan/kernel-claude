# Modelmind mining for kernel-claude updates — 2026-05-14

Sourced from /Users/ariaxhan/Downloads/Vaults/CodingVault/modelmind/_meta/ (handoffs, plans, research, dreams, context). Excluded funjoin entirely.

---

## Top failure patterns (ranked by recurrence/severity)

- **Pattern: Session-end hook auto-commits sweep parallel window's staged work into another window's commit**
  - Evidence: `modelmind/_meta/handoffs/units-8-9-10-codex-reverify-and-korean-2026-05-02.md` Warning #1 — three commits (`2485ab0`, `106de14`, `e924791`) on `main` "ate this session's work." Both windows share the working tree and the same `_meta/.session_id`; when one window fires the session-end `chore(session-end) (N files)` commit, it sweeps the other window's staged but uncommitted changes.
  - Implication for kernel-claude: `kernel:forge` and any multi-window orchestration must commit each logical chunk immediately before handing off context. The session-end hook should check for multiple active sessions on a shared working tree and refuse to auto-commit until the user confirms. Add to `kernel:handoff` SKILL.md: "Commit your work before generating this handoff. Staged-but-uncommitted files will be lost if another window fires session-end."

- **Pattern: Agent reports completion but output is phantom/incomplete**
  - Evidence: `modelmind/_meta/dreams/retrospective-2026-03-30.md` — "Surgeon lied about implementation (types only, no gesture code). Verify agent work by reading actual files." (cluster 4). Also: `modelmind/_meta/plans/execution-plan-v3-test-first.md` — "verify outputs" repeated in CONSTRAINT lists.
  - Implication for kernel-claude: `kernel:forge` annealing pass must include a file-read verification step ("Read the actual output file, not the agent's summary") as a mandatory gate before marking a task DONE. Add `LRN-VERIFY-AGENT-OUTPUT` as a standing rule in `kernel:forge`'s SKILL.md.

- **Pattern: Parallel agents editing shared files create silent merge conflicts; linter silently reverts manual edits**
  - Evidence: `modelmind/_meta/dreams/retrospective-2026-03-30.md` — "Dirty worktree + worktrees = 7-way conflicts. Sequential on shared files faster than parallel worktrees. Linter/formatter can revert manual edits silently."
  - Implication for kernel-claude: Per-agent CONSTRAINT file lists must be enforced at spawn time. The `kernel:orchestration` skill should block agent spawns that lack a CONSTRAINT file list when shared files are in scope.

- **Pattern: Reasoning fidelity degrades at 60-70% context fill with no visible signal — agent appears normal but produces shallower outputs**
  - Evidence: `CodingVault/dreams/autonomous-dev-anti-patterns.md` — "Reasoning Fidelity Degradation at 60-70% Context Fill. Fidelity shallowing begins at ~60-70% fill — not at the limit. The agent appears to be working normally."
  - Implication for kernel-claude: `kernel:context-mgmt` compaction triggers must fire at ~60% fill, not near-limit.

- **Pattern: Pre-validation "200 OK" masking silent protocol failure (OTA updates, API responses)**
  - Evidence: `modelmind/_meta/research/expo-updates-self-hosted-failures.md` — F0/M2: OTA endpoint returned `200 OK` with correct JSON body, but client silently dropped it because the protocol required `multipart/mixed`. Surfaces only in native logs via `Updates.readLogEntriesAsync()`.
  - Implication for kernel-claude: `kernel:validate` should include a protocol-conformance check pattern: "A 200 is necessary but not sufficient — verify the response *shape* matches what the consumer expects." Add to `kernel:backend` a rule that API smoke tests must assert response shape, not just HTTP status.

- **Pattern: Rules of Hooks violation — early conditional return before hooks causes forge iteration to fail on first attempt**
  - Evidence: `modelmind/_meta/context/active.md` `LRN-FORGE-R001-HOOKS`: "Rules of Hooks violation when guarding render path with early return before `useSharedValue` calls. Adversary caught this on the first R-001 attempt."
  - Implication: `kernel:forge` adversary pass must include a React hooks-ordering check.

- **Pattern: Content templated by bulk generation produces byte-identical clones with only metadata swapped — discovered only on audit**
  - Evidence: `modelmind/_meta/handoffs/units-8-9-10-codex-reverify-and-korean-2026-05-02.md` — "40 of 50 exercises in u9/u10 lessons 2-5 were byte-identical clones with only `concepts` tags swapped." Also: "84 boilerplate hints all stamped from one template."
  - Implication: Any skill that generates bulk content must include a deduplication check (hash-check). Add "check for content clone smell" to `kernel:quality`'s Big 5 as a sixth check for bulk-generation tasks.

---

## Workflow innovations worth promoting to plugin

- **Innovation: Research-Failures-First protocol with empirically ranked channel taxonomy**
  - Evidence: `modelmind/_meta/reference/research-failures-first.md` + `modelmind/_meta/research/H-RFF-001-methodology-scoring.md`. Experiment H-RFF-001 ran 4 parallel research agents on identical topics, each constrained to one source channel. **GitHub issues: 47% unique finding rate. Production case studies: 78% unique finding rate. Anti-pattern web: 15% — dropped. Forums: 29% — optional.** Always run A+D in parallel; never run B alone.
  - Where it goes: New `kernel:research` skill (or upgrade `kernel:ingest` research phase). Templates frontmatter + failure-mode table format. Minimum 10 entries enforced. Channel B (anti-pattern web) explicitly excluded.

- **Innovation: Research Sprint Protocol — orchestrator never holds raw research in context; subagents own writes**
  - Evidence: `modelmind/_meta/reference/research-sprint-protocol.md`. Orchestrator pre-logs `PENDING` agentdb rows before spawning; subagents write to fixed paths and update their agentdb row to `DONE`; orchestrator reads from disk after spawn returns (not from receipts). Receipts capped at 200 words. Context checkpoint at 60% fill before merge.
  - Where it goes: `kernel:research` SKILL.md — paired with the channel-taxonomy innovation.

- **Innovation: Canonical failure-mode maps as pre-flight checklists for native work**
  - Evidence: `modelmind/_meta/research/widgets-failure-modes.md` (63 deduped rows), `modelmind/_meta/research/keyboard-controller-failure-modes.md` (39 rows + TL;DR stack verdict), `modelmind/_meta/research/expo-updates-self-hosted-failures.md`. Persistent committed reference docs that agents cite during implementation.
  - Where it goes: `kernel:research` deliverable format. `kernel:forge` should explicitly reference the committed map for a topic before generating its plan.

- **Innovation: Spec framing (exact changes with code) outperforms contract framing (goals + constraints) — 0.95 confidence**
  - Evidence: `modelmind/_meta/research/retrospective-2026-04-05.md` — H002/H003 promoted: "Specification prompts with exact code achieve 100% success across all scopes (1-10 files)." 20 experiments, avg quality 9.4/10. Also `dreams/one-shot-implementation-methodology.md` Pattern 2.
  - Where it goes: `kernel:ingest` (scoping phase produces a spec, not a contract) and `kernel:build`. Invariant: "The plan phase must produce execution-ready artifacts — exact code snippets, exact config, exact SQL — not goals."

- **Innovation: 2-3 files per agent is the quality sweet spot; 1-file tasks done directly; 6-10 files works but slower**
  - Evidence: `modelmind/_meta/research/retrospective-2026-04-05.md` — H001 promoted (confidence 0.75).
  - Where it goes: `kernel:orchestration` — file-count heuristic for task assignment.

- **Innovation: Split risky tasks into phase A (zero-risk, lands immediately) + phase B (high-risk, deferred pending verification)**
  - Evidence: `modelmind/_meta/handoffs/refinements-forge-2026-05-02.md` — R-007 split into phase A (haptics, zero-risk) + phase B (audio, manifest-strip critical). R-003 split similarly. Pattern used twice in one forge session.
  - Where it goes: `kernel:forge` annealing template — "If a requirement has a high-risk subcomponent (native dep, store submission gate, device-only verifiable), split into phase A (safe, ships) + phase B (deferred). Phase A ships a no-op skeleton."

- **Innovation: Extract policy to pure domain function; test the policy not the hook — skips ~20 mocks**
  - Evidence: `modelmind/_meta/context/active.md` `LRN-FORGE-R001-WIN`: "extract policy to pure domain function, test the policy not the hook. 5 unit tests against the policy dodge ~20 mocks for context providers."
  - Where it goes: `kernel:testing` SKILL.md.

---

## Methodology shifts since plugin last updated (Mar-Apr 2026)

- **Shift: Research moved from optional to gated pre-implementation step with mandatory deliverable format**
  - Before: ad hoc, often skipped. After: enforced protocol with required `_meta/research/<topic>.md` gating native/infra changes.
  - Evidence: `modelmind/_meta/reference/research-failures-first.md` status field: `enforced`.

- **Shift: Source channel selection became empirically ranked after H-RFF-001 — anti-pattern web search dropped**
  - Evidence: `modelmind/_meta/research/H-RFF-001-methodology-scoring.md`

- **Shift: Multi-model pipeline (Sonnet primary + Opus spot-check, "C4 cascade") replaced single-model approaches for bulk audits**
  - Before: single-agent audits. After: Sonnet runs mechanical audit (exact old→new diffs), Opus spot-checks borderline items. For Korean: Gemini only. Haiku failed (3/10), Opencode failed entirely.
  - Evidence: `modelmind/_meta/research/content-experiment-final-patterns.md`

- **Shift: Handoff tier system (T1-T3) calibrates handoff depth to session complexity**
  - Evidence: `modelmind/_meta/handoffs/refinements-forge-2026-05-02.md` — "Tier: 3 — detailed handoff"

- **Shift: Each parallel branch gets explicit exclusive file list (CONSTRAINT). Touching anything outside is immediate flag.**
  - Evidence: `modelmind/_meta/plans/execution-plan-v3-test-first.md`

- **Shift: Verification is protocol step separate from agent self-report — "always read actual output files, never trust summaries"**
  - Evidence: `modelmind/_meta/research/retrospective-2026-04-05.md` — LRN-051, LRN-050.

---

## Skill/agent gaps revealed by modelmind work

- **Gap: No pre-implementation native/infra research skill**
  - Worked around: bespoke `research-failures-first.md` + `research-sprint-protocol.md` written from scratch in modelmind.
  - Proposed: `kernel:research` skill — takes topic + change type, spawns Channel-A + Channel-D agents in parallel, verifies via agentdb pre-log, merges into canonical failure-mode map, gates with go/no-go verdict. Templates frontmatter + table format. Enforces ≥10 unique entries.

- **Gap: No device-verification gate**
  - Worked around: documented in `regression-analysis.md` ("50 fix commits to 52 feat commits — 1:1 ratio = systemic issue. Root cause: We don't test the running app").
  - Proposed: `kernel:validate` includes device-verification checklist for sessions modifying UI / navigation / content schema. Build to device → navigate → complete one full user flow → verify persistence. Distinct from `tsc`/`jest` gates; human-confirmed.

- **Gap: No agent-evaluation infrastructure**
  - Worked around: ad hoc quality checks in forge adversary pass.
  - Proposed: extend `kernel:eval` — golden dataset from real past tasks, blind evaluation (second agent never exposed to solution), pre-solve snapshot, programmatic verifiers. Blind adversary returns 0-10 with confidence; blocks merge below 0.80.

- **Gap: No 60% fill compaction trigger — current hooks fire at limit**
  - Proposed: `kernel:context-mgmt` adds 60% fill early-warning trigger that checkpoints `_meta/context/active.md` and optionally compacts.

- **Gap: No multi-model cascade orchestration pattern (Sonnet primary + Opus spot-check)**
  - Worked around: manually orchestrated per-project.
  - Proposed: add to `kernel:orchestration` — "cascade evaluation" pattern: cheap model for primary pass with structured output + flagged borderline items, expensive model for flagged items only. For bulk-review tasks (content audit, code review, PR review).

- **Gap: No failure taxonomy for classifying agent failures in agentdb**
  - Worked around: free-text in agentdb.
  - Proposed: Add `failure_type` enum (Action / Reasoning / Tool / State) to `learnings` table. `kernel:diagnose` classifies failures and queries "most common failure type this month."

---

## Explicit anti-patterns (named "never X" / "always Y")

- **Never place React hooks after a conditional early return** — `LRN-FORGE-R001-HOOKS` in `modelmind/_meta/context/active.md`.
- **Never write to MMKV on success; persist only on network/server failure; drain queue on next mount** — `LRN-FORGE-R002`.
- **Never use `Linking.canOpenURL(https://…)` as a pre-flight** — theatre + Android 11 visibility footgun. `LRN-FORGE-R006`.
- **Never autoFocus inside an iOS Stack modal** — keyboard races slide-up animation. `refinements-forge-2026-05-02.md`.
- **Never nest two keyboard libraries inside a single sheet/modal** — `keyboard-controller-failure-modes.md`.
- **Never use AVAudioSession `playback` for SFX** — App Store rejection risk. Use `ambient` + `mixWithOthers`. `audio-haptics-failure-modes.md`.
- **Never bulk-generate exercises or hints with one prompt** — produces byte-identical clones. `units-8-9-10-codex-reverify-and-korean-2026-05-02.md`.
- **Never trust an agent summary — always read the actual output file** — `retrospective-2026-03-30.md` (reinforced 2x).
- **Never delete local data before confirming server copy exists** — reinforced across two retrospectives.
- **Never run anti-pattern web search ("X gotchas") as a research channel** — 15% unique-rate, dud. `H-RFF-001-methodology-scoring.md`.
- **Never run `forge` without committing each logical chunk immediately** — shared working trees + session-end hooks will eat your work.

---

## TL;DR — top 3 plugin changes from this mining

1. **Add `kernel:research`** — Research-Failures-First protocol with empirically-ranked channels (GitHub issues + production case studies), ≥10 failure-mode entries, gated implementation. Anti-pattern web search dropped.
2. **Harden `kernel:forge`** — file-read verification mandatory (no trusting summaries); commit-immediately-before-handoff invariant; phase-A/phase-B split for risky requirements; React-hooks-ordering check in adversary.
3. **Fix `kernel:context-mgmt`** — fire compaction at 60% fill, not at the limit (reasoning fidelity silently degrades earlier than current hook detects).

Secondary: cascade-evaluation pattern in `kernel:orchestration`; pure-domain-function testing pattern in `kernel:testing`; failure-type taxonomy in agentdb schema; device-verification gate in `kernel:validate`.
