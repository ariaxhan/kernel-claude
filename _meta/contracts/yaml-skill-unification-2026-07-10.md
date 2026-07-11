# CONTRACT: yaml-skill-unification | 2026-07-10

**GOAL:** Remove the kernel commands layer; every kernel operation is a first-class skill.
YAML is the canonical machine-readable representation for resumable runtime state
(handoff, checkpoint, retrospective mutations, context receipts). Hooks are first-class:
manifests feed hooks (sealed/bounded context enforcement), hooks feed manifests (ledger,
receipts). TIER: 3 | BRANCH: feat/yaml-skill-unification (stacked on feat/aggressive-promotion,
which is unmerged and unPR'd — merge order matters, see Risks).

**Driving evidence:** EXP-L21 (attention ledger, `Vaults/_meta/research/attention-ledger-2026-07-10/findings.md`):
load-bearing context is FLAT at ~47-71k/decision while attended grows 7-11x; late-session
efficiency 10.6-15.8%. Design target for resume: boot + task manifest + ~2-12k selected
history. Resumptions must reconstruct bounded task state, never inherit whole conversations.

---

## 1. Current architecture (verified 2026-07-10)

- `commands/` — 14 flat .md files (3,030 lines), frontmatter `name: kernel:X`,
  `user-invocable`, `allowed-tools`; body `<command id="X">`. Registered explicitly in
  `.claude-plugin/plugin.json` `"commands"` array.
- `skills/` — 19 dirs, `skills/<name>/SKILL.md` + `reference/*-research.md`, frontmatter
  `name`, `description` (with "Triggers:"), `allowed-tools`; body `<skill id="X">`.
  Auto-discovered (no plugin.json key), surface as `/kernel:<dirname>`.
- Both layers surface identically as invocable skills in Claude Code (verified in live
  session listing + docs: commands were merged into skills upstream).
- Handoffs: markdown briefs at `_meta/handoffs/*.md`; resume = ingest step 1b parses
  markdown prose. No checkpoint primitive. No schemas. No context budget accounting.
- Enforcement surfaces referencing `commands/`: `tests/run-tests.sh` (~30 refs),
  `hooks/scripts/validate-structure.sh`, `hooks/scripts/guard-config.sh` (allowlist),
  `scripts/bump-version.sh` (commands/help.md), `.claude-plugin/plugin.json`,
  `CLAUDE.md` `<commands>` block, `AGENTS.md`, `README.md`, `docs/QUICKSTART.md`,
  `workflows/*.md` (`command: /kernel:ingest`), `agents/*.md` (invocation strings only),
  `hooks/scripts/session-start.sh` + `pre-compact-commit.sh` (invocation strings only).
- Collision: `commands/experiment.md` (autonomous engine, 307 ln) vs
  `skills/experiment/SKILL.md` (methodology, 79 ln). Both live.
- Test baseline: 255/255 PASS.

## 2. Verified Claude Code capabilities (docs fetched this session)

- Plugin `skills/<dir>/SKILL.md` → `/kernel:<dir>`. Invocation names preserved exactly.
- Native frontmatter: `name`, `description`, `when_to_use`, `argument-hint`, `arguments`,
  `disable-model-invocation`, `user-invocable`, `allowed-tools`, `disallowed-tools`,
  `model`, `effort`, `context: fork`, `agent`, `hooks` (skill-scoped hooks), `paths`, `shell`.
- Unknown frontmatter keys silently tolerated → kernel-owned taxonomy lives under a
  `kernel:` map, validated by kernel's own validator, never by the host.
- `skills/` auto-discovered; `"commands"` key removable; `!`cmd`` injection + `$ARGUMENTS`
  work in skills; skill edits hot-reload.
- YAML tooling on this machine: NO pyyaml; ruby+Psych present. Validator parse chain:
  python3+pyyaml → ruby -ryaml (JSON bridge) → explicit failure (fallback-first: sealed
  resume BLOCKS on unvalidatable manifest; advisory warns).

## 3. Migration table (every command has a destination)

| # | command | destination | kind | model-invocable | notes |
|---|---------|-------------|------|-----------------|-------|
| 1 | ingest.md | skills/ingest/SKILL.md | workflow | yes | + manifest runtime: discovery, validation, divergence, context compile, receipt, bounded resume |
| 2 | forge.md | skills/forge/SKILL.md | workflow | **no** | autonomous loop + budget; explicit invocation only |
| 3 | validate.md | skills/validate/SKILL.md | validator | yes | body carries over |
| 4 | tearitapart.md | skills/tearitapart/SKILL.md | validator | yes | body carries over |
| 5 | review.md | skills/review/SKILL.md | validator | yes | body carries over |
| 6 | handoff.md | skills/handoff/SKILL.md | state_transition | yes | rewritten: emits kernel.handoff/v1 YAML (canonical) + optional md render (non-authoritative) |
| 7 | retrospective.md | skills/retrospective/SKILL.md | state_transition | yes | keeps ladder; + emits kernel.retrospective-result/v1 mutation record |
| 8 | diagnose.md | skills/diagnose/SKILL.md | workflow | yes | body carries over |
| 9 | dream.md | skills/dream/SKILL.md | workflow | yes | body carries over |
| 10 | metrics.md | skills/metrics/SKILL.md | workflow | yes | read-only |
| 11 | init.md | skills/init/SKILL.md | operator | **no** | machine setup; explicit only |
| 12 | help.md | skills/help/SKILL.md | methodology | yes | rewritten for unified architecture |
| 13 | experiment.md | **merge → skills/experiment/SKILL.md** | workflow | **no** | collision resolved: engine becomes the SKILL.md body; prior methodology content already lives in reference/experiment-research.md + engine loads it. One /kernel:experiment. |
| 14 | landing-page.md | skills/landing-page/SKILL.md | operator | **no** | 923 ln; deploys; explicit only |
| — | (new) | skills/checkpoint/SKILL.md | state_transition | yes | NEW: emits kernel.checkpoint/v1 for safe context resets mid-task |

`commands/` directory deleted. plugin.json `"commands"` key deleted. NO compatibility
aliases: invocation strings (`/kernel:X`) are IDENTICAL before/after, so an alias layer
would perpetuate dual architecture for zero user benefit (per commission: compat only
where it doesn't perpetuate dual architecture).

## 4. Unified taxonomy (kernel-validated frontmatter)

Every kernel skill adds a kernel-owned block (host tolerates unknown keys; kernel's
validate-skills test enforces it):

```yaml
kernel:
  kind: methodology | workflow | state_transition | validator | operator
  version: 1
  side_effects: none | writes_meta | writes_repo | writes_remote | deploys
  confirmation: none | on_side_effect | always
  produces: [kernel.handoff/v1]        # optional
  consumes: [kernel.handoff/v1, kernel.checkpoint/v1]  # optional
  requires_skills: [quality, testing]  # loaded on invoke
  optional_skills: [orchestration]     # loaded on condition
```

Existing 18 methodology skills get minimal blocks (`kind: methodology`, `version: 1`,
side_effects/confirmation as applicable) — additive, no methodology rewrites.
Native controls: `disable-model-invocation: true` on forge, init, experiment,
landing-page (side-effecting/expensive can't fire ambiently — test-enforced).

## 5. Schemas (files to create)

`schemas/kernel.handoff.v1.schema.json` — sections: schema, identity, provenance
(branch, commit, dirty, artifacts[path,sha256], retrospective_refs), objective (goal,
success_conditions, non_goals), contract (invariants, assumptions, decisions_accepted,
alternatives_rejected), workflow (phases[name,status: inherited|required|invalidated],
invalidation_rules[trigger,invalidates]), runtime (required_skills[name,version?],
preflight[cmd,expect]), context (policy.mode: sealed|bounded|advisory, required[selector],
optional[selector], forbidden[glob], budget.target_tokens, budget.max_tokens),
execution (entry_phase, entrypoint, stop_conditions, checkpoints), open_threads,
warnings, outputs (required[path|check], completion), resume (prompt).

`schemas/kernel.checkpoint.v1.schema.json` — schema, identity, provenance (branch,
commit, dirty), task (goal, handoff_ref?), steps_completed[step,evidence],
current_outputs[path], pending_steps[], resume (position, entrypoint, next_operation),
context (policy passthrough, required selectors).

`schemas/kernel.retrospective-result.v1.schema.json` — schema, identity, analyzed
(learnings, clusters, merged, archived, contradictions), mutations[ {op: create|modify|
remove|promote, artifact_type: hook|agent|skill|prose, path, reason, evidence,
reinforced} ], project_fit (missing[], dormant[]).

`schemas/kernel.context-receipt.v1.schema.json` — exactly the commission's fields:
schema, manifest_tokens, project_instructions_tokens, always_skills_tokens,
workflow_skills_tokens, domain_skills_tokens, selected_artifacts_tokens, agentdb_tokens,
total_estimated_tokens, target_budget_tokens, maximum_budget_tokens,
status: within_budget|target_exceeded|maximum_exceeded, + estimation_method (chars/4,
documented uncertainty), loads_beyond_manifest[] (bounded-mode ledger).

Context selectors v1 (small, testable): `{path}` (whole file) · `{path, lines: "A-B"}` ·
`{path, heading: "## X"}` · `{path, grep: "pat", context: N}` · `{git_diff: "revA..revB"}`.
yaml-path/json-path/symbols: DEFERRED (documented in schema description).

## 6. Runtime (files to create)

`orchestration/manifest/kernel-manifest` (bash+python3 CLI, mirrors agentdb placement):
- `validate <file>` — parse (pyyaml→ruby chain) + validate against schema by `schema:` field. Exit 0/1/2 (2 = cannot parse/no parser).
- `latest [--dir _meta/handoffs|_meta/checkpoints]` — newest manifest path (checkpoint beats handoff when newer).
- `divergence <file>` — live git state vs manifest provenance: branch match, commit ancestry, dirty state, artifact sha256s. Reports per-check PASS/DIVERGED. Exit 1 on any divergence.
- `compile <file>` — resolve context selectors → emit compiled context bundle paths + `kernel.context-receipt/v1` YAML to stdout; chars/4 token estimates; status vs budgets.
- `activate <file>` / `deactivate` — write/remove `_meta/.active-manifest.json` (JSON bridge for hooks; gitignored).

`hooks/scripts/guard-context.sh` (PreToolUse: Read|Grep|Glob) — reads
`_meta/.active-manifest.json`; sealed: block (exit 2) forbidden-glob access; bounded:
append access to `_meta/.context-ledger` (gitignored) and allow; advisory/no manifest:
allow. Fail-open ONLY when no manifest active; fail-closed (block) when sealed manifest
present but unparseable. Registered in hooks/hooks.json.

`.gitignore` += `_meta/.active-manifest.json`, `_meta/.context-ledger`.
`_meta/checkpoints/` created (with .gitkeep).

## 7. Files to modify

- `.claude-plugin/plugin.json` — drop `"commands"`, description (20 skills, 0 commands), version 8.0.0.
- `.claude-plugin/marketplace.json` — description, version 8.0.0.
- `tests/run-tests.sh` — retarget ~30 command-path tests to skill paths; ADD migration + manifest + guard-context tests (list in §9).
- `hooks/scripts/validate-structure.sh` — commands case → skills case.
- `hooks/scripts/guard-config.sh` — keep commands allowlist entry (host projects may still use commands/), no functional change needed.
- `scripts/bump-version.sh` — commands/help.md → skills/help/SKILL.md.
- `hooks/scripts/pre-compact-commit.sh`, `session-start.sh` — invocation strings unchanged (/kernel:ingest, /kernel:help still valid); update any commands/ PATH references only.
- `CLAUDE.md` — `<commands>` → `<skills>` workflow entries + state-operations section; stays <400 lines (test-enforced).
- `AGENTS.md` — mirror CLAUDE.md changes.
- `README.md`, `docs/QUICKSTART.md` — terminology + unchanged invocations noted.
- `docs/skill-template.md` — new frontmatter conventions incl. kernel: block.
- `workflows/*.md` — `command:` → `skill:` labels.
- `CHANGELOG.md` — 8.0.0 entry.
- `docs/MIGRATION-8.md` — NEW: user-facing migration notes.

## 8. Behavior contracts for the four state operations

**handoff** — compile authoritative kernel.handoff/v1 YAML to `_meta/handoffs/<name>-<date>.yaml`;
git hygiene phase kept; markdown render optional and marked `# RENDERED FROM <yaml> — NOT AUTHORITATIVE`;
must `kernel-manifest validate` its own output before reporting done.

**checkpoint** — bounded kernel.checkpoint/v1 to `_meta/checkpoints/<task>-<ts>.yaml`;
records steps_completed w/ evidence, pending, exact resume position; validates own output.
For context resets mid-task WITHOUT full handoff ceremony.

**ingest** — unified entry. No manifest → classify flow (existing). Manifest supplied or
discovered (`kernel-manifest latest`) → validate → divergence check → live-state-wins
invalidation (authority order: live verified repo state > current user instruction >
manifest > chronicle > inferred history) → `compile` context per policy → emit receipt →
`activate` manifest (arms guard-context) → resume at entry_phase → `deactivate` at
completion. Budget overrun: target_exceeded → warn + proceed trimming optional context;
maximum_exceeded → STOP, report, ask.

**retrospective** — existing ladder flow + emit kernel.retrospective-result/v1 to
`_meta/reports/retrospective-<date>.yaml`; validates own output.

## 9. Tests (added; all existing retargeted tests stay)

1. every former command name resolves to a skill dir (migration completeness table check)
2. commands/ dir absent; plugin.json has no commands key
3. no live file references `commands/` paths (grep sweep excluding _meta archives/CHANGELOG)
4. all SKILL.md frontmatter parses (python3 frontmatter check) + kernel: block present on kernel-authored skills
5. side-effecting skills (forge, init, experiment, landing-page) have disable-model-invocation: true
6. schemas parse as JSON; example manifests validate (fixtures under tests/fixtures/manifests/)
7. kernel-manifest validate rejects: missing schema field, wrong section types, bad policy mode
8. kernel-manifest latest finds newest across handoffs+checkpoints; explicit path accepted
9. divergence: branch mismatch detected; artifact hash mismatch detected; clean state passes
10. compile: receipt emits all commission fields; selector types file/lines/heading/grep/git_diff resolve; token estimate > 0; status transitions at target/max budgets
11. guard-context: sealed blocks forbidden Read (exit 2); bounded appends ledger + allows; no active manifest allows; sealed + unparseable manifest blocks (fail-closed)
12. checkpoint fixture resumes at declared position (resume.position surfaced by ingest dry-run helper)
13. retrospective-result example validates; mutation ops enum enforced
14. version sync includes skills/help/SKILL.md
15. workflows reference skills not commands

Claude Code behaviors not unit-testable headlessly (skill hot-reload, ambient
non-invocation, /kernel:X routing): executable smoke-test instructions in
docs/MIGRATION-8.md + strongest local proof = this session's own listing (deployed, your check).

## 10. Acceptance criteria

- [ ] 0 files under commands/; plugin.json clean; version 8.0.0 everywhere (version-sync test green)
- [ ] 20 skill dirs (19 existing + checkpoint; experiment merged; 13 migrated in)
- [ ] 4 schema files + validator CLI with validate/latest/divergence/compile/activate
- [ ] guard-context hook registered; sealed/bounded/advisory semantics implemented + documented
- [ ] handoff/checkpoint/retrospective emit validated YAML; ingest consumes + emits receipt
- [ ] full test suite green (≥255 retargeted + ~20 new)
- [ ] resume path exercised end to end: real handoff YAML generated → fresh validate → divergence → compile → receipt → resume position (live run this session)
- [ ] docs updated; chronicle written (Vaults/_meta/chronicles/2026/)

## 11. Risks & deferred

- **Stacked branch**: feat/aggressive-promotion (2 commits: ladder, armed-path) is unmerged,
  no PR. This work stacks on it; PR for this branch must merge after (or subsume) it.
- **Parser dependency**: no pyyaml here; ruby bridge covers macOS. Linux hosts without
  either get explicit exit-2 "cannot validate" (fail-closed for sealed). Documented.
- **Token estimates are chars/4** — directional, stated in receipt (estimation_method).
- **Deferred**: yaml-path/json-path/symbol selectors; EXP-L21b rerun-verification;
  boot-layer audit (session-start block is counted in receipts, not shrunk here);
  agentdb schema changes (none needed — emits reuse existing tables); markdown handoff
  auto-migration tool (old .md handoffs remain readable by ingest's legacy branch for
  one release, flagged deprecated — thin, explicit removal path in MIGRATION-8.md).
- **Non-goals honored**: tradition untouched (boundary doc in MIGRATION-8.md §tradition);
  no agentdb redesign; methodology bodies not rewritten (frontmatter-only for the 18).

## 12. Commit plan

1. `chore: commit session artifacts + hooks.json version-key removal` (baseline)
2. `feat(runtime): manifest schemas, kernel-manifest CLI, guard-context hook` (additive, green)
3. `feat(skills)!: migrate all 14 commands to skills, merge experiment, drop commands layer` (+ all reference/test retargets, green)
4. `feat(state): yaml-first handoff, checkpoint, ingest manifest runtime, retrospective mutations` (green)
5. `chore(release): kernel 8.0.0 — unified skill architecture` (docs, changelog, version)

Amendments to this contract are recorded in §13 below as discovered.

## 13. Amendments

(none yet)
