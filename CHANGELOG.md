# Changelog

All notable changes to KERNEL are documented in this file.

## [8.1.2] - 2026-07-15

KERNEL 8.1.2 is the de-bloat release. It removes maximal-delegation doctrine and
never-fired surfaces that a current strong model no longer needs, grounded in an evidence
sweep of ~1,900 real sessions. Same guardrails, far less ceremony and context weight.

### Changed
- **Delegation is now cost-gated, not tier-mandated.** The ambient block and governance no
  longer say "the coordinating agent does not implement." Default is inline; spawn a subagent
  only to protect context, buy real wall-clock on heavy file-disjoint work, on explicit
  request, or for independent verification, never for independence alone.
- **Tiering is by reversibility x blast radius, not file count.** Removed the "1-2 / 3-5 / 6+
  files" tables from ingest and diagnose; the `parallel_first` invariant is now the
  `spawn_cost_test` heuristic.
- **Worktrees are opt-in (I0.14), not a per-agent default** — they caused ref-lock races and
  out-of-project writes when used reflexively.
- SessionStart caps the dynamic AgentDB dump so the static rules always survive truncation.
- `landing-page` skill trimmed from 929 lines to a lean interview -> scaffold -> deploy contract.

### Removed
- 10 never-fired skills (api, backend, e2e, performance, testing, refactor, git, security,
  quality, validate) — the work still happens; the model does it directly, the hooks remain
  the real guardrails.
- 7 never-fired / redundant agents (validator, triage, approval-learner, analyzer,
  cartographer, coroner, pre-ship).

### Added
- `lane-worker` agent — isolated, file-disjoint implementation lane for commissioned parallel
  bursts (bakes in the worktree/no-commit/follow-the-pilot contract).
- `transcript-archaeologist` agent — read-only forensic miner of session transcripts + git
  history; returns cited conclusions, not the raw pile.

Net: 34 -> 24 skills, 15 -> 10 agents. 349 tests pass.

## [8.1.1] - 2026-07-11

KERNEL 8.1.1 fixes the installed entrypoint for the new governance-sync operator.
The 8.1.0 documentation used a repository-root-relative `scripts/governance-sync.py`
path, but installed skills execute from `skills/governance-sync`, so the documented
audit, adopt, generate, check, and init commands failed before reaching the script.

### Fixed
- Resolve the installed plugin root from `CLAUDE_PLUGIN_ROOT`, which is supplied by
  Claude Code and the Codex compatibility loader, with a skill-directory fallback for
  direct installed-layout execution.
- Route every governance-sync command example through the resolved absolute script
  path instead of assuming the current directory is the plugin root.
- Add an armed disposable installed-cache test that runs from
  `skills/governance-sync` through both the loader environment and fallback paths.

## [8.1.0] - 2026-07-11

KERNEL 8.1 adds one canonical governance source for its Claude Code and Codex
instruction adapters, plus an explicit operator for auditing and safely adopting the
same pattern in other Git repositories.

### Added
- Added `governance/kernel.md.tmpl` and an allowlisted, deterministic generator for
  readable checked-in `CLAUDE.md`, `AGENTS.md`, and the static SessionStart guidance.
  CI and the canonical version-bump process reject generated drift.
- Added explicit-only `/kernel:governance-sync` and `$kernel:governance-sync`
  operations to audit, adopt, generate, initialize, and check native repository
  instructions. Existing conflicts, symlinks, hardlinks, unsafe paths, and unrelated
  partial files are refused instead of overwritten.
- Added manifest- and provenance-aware audit states for generated-current,
  generated-stale, incomplete, and conflicting adapters while preserving nested
  instruction scopes and deduplicating linked Git worktrees.

### Changed
- Governance writes are crash-consistent per file: each completed replacement is a
  whole fsynced file, an interruption leaves visible drift, `check` remains read-only,
  and rerunning the explicit operation converges the remaining files. KERNEL does not
  maintain a hidden governance lock, recovery journal, or background migration.
- Context receipts count `CLAUDE.md`, `.claude/CLAUDE.md`, and `AGENTS.md` without
  double-counting byte-identical instruction files.

### Verification
- The read-only Vaults audit completed across **49 canonical Git repositories** with
  zero traversal errors. This is an inventory and classification result only; KERNEL
  8.1 does **not** claim those repositories were migrated or modified.
- Generator, governance state-machine, manifest, version, release-documentation, and
  full bounded test gates pass for the release candidate.

## [8.0.2] - 2026-07-11

KERNEL 8.0.2 fixes cross-client advisory hooks that Codex skipped whenever the shared
manifest marked them `async`. Upgrade and restart Codex so its installed cache loads
the corrected manifest.

### Fixed
- Removed exactly six unsupported `async` keys while preserving every hook command,
  matcher, order, and timeout. The advisory checks now run synchronously in both Claude
  Code and Codex and still exit successfully when their own downstream work fails.
- Normalized valid Claude Write/Edit and Codex `apply_patch` payloads for structure,
  hardcoded-value, JSON-schema, write-log, and error-capture advisory hooks, so inspected
  paths, added content, and errors are no longer silently empty.
- Made `log-write.sh` wait for its AgentDB timing emit and tolerate emit failure instead
  of leaving a detached child after the hook process exits.
- Added armed cross-loader payload, failure, false-positive, command-retention,
  no-child, and critical-guard-integrity regressions. The blocking guards remain
  unchanged.

## [8.0.1] - 2026-07-11

KERNEL 8.0.1 is the corrected KERNEL 8 release. An incomplete 8.0.0 candidate reached
the public `main` branch before the full release gate had finished. Users who installed
or refreshed 8.0.0 should upgrade to 8.0.1 and restart Claude Code or Codex so the
versioned plugin cache cannot keep serving the incomplete build.

### Fixed
- Completed the strict-JSON manifest runtime with typed divergence and preflight
  checks, canonical receipts and hashes, safe path handling, and transactional ledger
  and deactivation behavior.
- Added validated runtime selection, forward-only normal upgrades, explicit rollback,
  and ownership-safe repair for the three KERNEL helper links without overwriting user
  files, directories, malformed links, or unrelated links.
- Rewrote the README, setup guide, and migration guide around the actual KERNEL 8 user
  flow, including executable Claude Code and Codex install, upgrade, reinstall, and
  rollback commands plus honest data-preservation and compatibility boundaries.
- Made the shared hook configuration parse in both Claude Code and Codex. Codex
  `apply_patch` payloads now reach the secret and configuration guards; dot-segment
  traversal and malformed hook JSON fail closed, while removing an existing secret
  remains possible.
- Added Codex-native explicit-only policies for `init`, `forge`, `experiment`, and
  `landing-page`, corrected Codex invocation syntax to `$kernel:<skill>`, and documented
  that Claude agent definitions, asynchronous hooks, and SessionEnd do not become
  native Codex lifecycle features through the compatibility loader.
- Restored essential tier-2 orchestration rules through SessionStart for plugin users
  who do not receive repository `AGENTS.md` automatically.
- Made no-marker compaction restoration silent without hiding legitimate runtime
  selection messages in other paths.
- Added an exact-root ownership boundary for the shared Vaults continuity service.
  KERNEL compaction hooks cleanly no-op only when the active project is the Vaults root
  and the shared engine plus an executable host adapter exist; nested repositories keep
  KERNEL's no-auto-commit fallback, and SessionStart retains governance without a
  competing restore injection.
- Made retrospective staleness use `COALESCE(last_hit, ts)` so recently recalled older
  learnings are not archived, and corrected release instructions to name the exact
  canonical files changed by `scripts/bump-version.sh`.

### Verification
- The corrected candidate passes the bounded full suite: **368 passed, 0 failed**, plus
  focused runtime-upgrade, release-documentation, cross-loader hook, retrospective,
  compaction, and version-synchronization gates.

## [8.0.0] - 2026-07-11

KERNEL 8 unifies its public operations as skills, makes strict JSON the canonical
resumable state format, and adds a safe runtime selector so plugin updates cannot quietly
leave AgentDB, hooks, and orchestration pinned to 7.23.

### BREAKING
- **`commands/` removed.** Workflow, state, validator, operator, and methodology
  definitions all live in `skills/`. Namespaced invocations remain `/kernel:<skill>`.
- **experiment collision resolved**: the autonomous engine (former command) and the
  methodology (former skill) merged into one `skills/experiment/SKILL.md`.
- **Design renamed to frontend.** Use `/kernel:frontend`; `/kernel:design` is removed.
- **Canonical state is strict JSON.** Historical YAML records are preserved but are not
  active KERNEL 8 resume inputs. KERNEL 7 may not resume KERNEL 8-created state.

### Added
- **Manifest runtime** actions: `validate | latest | divergence | preflight | compile |
  resume | activate | deactivate`. Duplicate JSON keys and invalid schema are rejected.
- **Schemas** (`schemas/`): kernel.handoff/v1, kernel.checkpoint/v1,
  kernel.retrospective-result/v1, kernel.context-receipt/v1.
- **/kernel:checkpoint** (new skill): bounded mid-task manifest — steps completed with
  evidence, exact resume position — for safe context resets without handoff ceremony.
- **Context policies** sealed | bounded | advisory, enforced by the new
  `guard-context.sh` PreToolUse hook reading the activated manifest: sealed blocks
  forbidden globs (fails closed), bounded ledgers extra loads into the receipt.
- **Context selectors v1**: whole-file, line ranges, markdown headings, grep+context,
  git diffs. `compile` emits a token-estimated context receipt with budget status.
- **Taxonomy**: every skill carries a kernel-validated frontmatter block
  (kind: methodology|workflow|state_transition|validator|operator, side_effects,
  confirmation, produces/consumes). Side-effecting skills (forge, init, experiment,
  landing-page) carry disable-model-invocation: true (test-enforced).
- **Validated runtime selection and host repair.** The plugin root Claude Code actually
  loaded is authority. Normal sessions move `current` forward only; explicit rollback
  can select a lower trusted root. Startup atomically repairs exactly three recognizable
  old numbered KERNEL links and refuses every user-owned or malformed destination.
- **Rollback tool:** `scripts/select-runtime.sh /trusted/kernel/root` validates identity,
  version, and helpers without deleting cache or project data.
- **Release and migration tests** cover upgrades, rollback, malformed caches, broken and
  relative links, user-owned objects, atomic failure, data preservation, and live docs.
- **Claude/Codex hook compatibility gate.** `hooks/hooks.json` now has a regression test
  that permits only the shared loaders' top-level `description` and `hooks` fields. This
  prevents the old top-level `version` field from breaking Codex startup. Native Codex
  manifest packaging remains deferred because its validator conflicts with Claude's
  explicit-only marker for side-effecting skills; Codex uses its compatibility loader.
- **Executable Codex lifecycle docs.** Install uses `codex plugin marketplace add` plus
  `codex plugin add`; normal updates use `codex plugin marketplace upgrade`; targeted
  recovery uses `codex plugin remove` then `codex plugin add`. These flows were exercised
  against the current CLI in a disposable Codex home instead of inferred from Claude's
  slash commands.
- **Cross-loader security tests.** Claude and Codex hook payloads exercise the installed
  entry points separately. Config guards reject dot-segment traversal before allowlist
  checks, and the ship methodology now requires an explicit resource ceiling for
  heavyweight verification.
- **Context graph (shadow telemetry).** Receipt-derived projection only:
  `orchestration/agentdb/graph-project.py` + `agentdb graph-project|graph-suggest`.
  `kernel-manifest deactivate --receipt` auto-projects; `write-end` records outcome.
  JSON manifests remain authoritative; graph suggestions remain advisory.

### Changed
- **handoff** emits canonical JSON manifests (markdown renders are non-authoritative) and
  validates its own output. **ingest** is the unified entry: discovers/validates
  manifests, checks divergence (live state wins; inherited phases invalidate by rule),
  compiles bounded context, arms the policy, resumes at the declared phase.
  **retrospective** additionally emits a validated machine-readable mutation record.
- `/kernel:init` now uses validated shared runtime helpers, creates missing links only
  after confirmation, and never moves or replaces the whole `~/.claude` directory.
- `/kernel:retrospective` now queries the current AgentDB learning columns and records
  evidence for resolved contradictions. This release's loader, path-validation, install,
  and bounded-test lessons were promoted into the testing, security, and ship skills.
- README, setup, migration, help, governance, workflows, metadata, and CI now describe
  the same supported surfaces, update/reload behavior, JSON state, and data boundaries.

### Deprecated
- Legacy markdown and YAML records remain historical artifacts. Convert or create a new
  JSON manifest before using the KERNEL 8 resume runtime.

## [7.23.0] - 2026-07-06

The Fable harness prune. One theme: the plugin stops re-teaching what the model already
knows and stops contradicting the layers above it.

### Changed
- **session-start.sh** static context cut from ~4.8KB to ~0.6KB: the `<protocol>`,
  `<decision_tree>`, Commands/Tiers reference, and profile-gated static blocks are replaced by
  one compact block (agentdb quick reference, the reversibility x silence x blast radius tier
  line, a pointer to `/kernel:help`). All dynamic state stays; scripted "ASK USER" prompts now
  state facts instead; the NOT-INITIALIZED wall is 2 lines; the stale "local: commit to main"
  advice is gone.
- **Per-commit autopush install is opt-in** (`AUTOPUSH_ON=1`); explicit push is the rule
  (2026-06-15 directive) and the plugin was fighting it. `AUTOPUSH_OFF=1` stays as hard off.
- **detect_vaults()** emits a one-line stderr warning when it falls through to the hardcoded
  default path, naming the resolved path and the `KERNEL_VAULTS` override.
- **Skills pruned**: tdd merged into testing (one skill owns test methodology); build, debug,
  orchestration, quality, and git rewritten to <=80 lines each; dated blog-citation walls,
  the r_factor/adsr machinery, and the speculative orchestration XML sub-blocks deleted.
  Orchestration gains the lane-contract fields and a worker-model doctrine (cheap models only
  for total-spec execution; lane reports are claims, wrong roughly 1 in 5).
- **Agents**: understudier folded into triage (viability pre-flight one-liner); researcher's
  `model: haiku` pin removed (deep research on haiku is a tier mismatch). 15 agents on disk,
  and CLAUDE.md / plugin.json / marketplace.json now agree (blind-evaluator, deep-diver,
  dreamer documented).
- **Docs**: tiers unified on reversibility everywhere; the duplicated 8-step `<flow>` block is
  3 lines; app-dev described fastlane-first; AGENTS.md regenerated from CLAUDE.md.

### Removed
- `frontend/build/` (generated) untracked + gitignored; stray `solution.py` + its bytecode
  deleted; `skills/TEMPLATE.md` moved to `docs/skill-template.md`.

## [7.22.0] - 2026-06-27

### Removed
- **Runaway-agent killswitch removed entirely** (killswitch.sh / killswitch-init.sh /
  killswitch-status.sh / KILLSWITCH.md + both hook entries). The wall-clock and tool-count
  caps tripped mid-forge on normal multi-hour sessions, and the over-cap escape hatches were
  partly unreachable (override-file write blocked by guard-config; env prefix never reached
  the hook). Net friction outweighed the runaway protection.

## [7.21.0] - 2026-06-26

### Added
- **Runaway-agent killswitch** as a PreToolUse budget cap (wall-clock + tool-count),
  merged via PR #140. Reverted one day later in 7.22.0; see above.
- **CI auto-fix workflow** that reacts when Tests & Quality goes red on main.

### Fixed
- Test assertion for the (deliberately disabled) autopush-postcommit hook.
- Ongoing skill syncs from external sources (2026-06-20 through 2026-06-26).

## [7.20.0] - 2026-06-15

The auto-commit / auto-push path now refuses to ship a red test suite. Previously the
SessionEnd auto-commit (and the PreCompact checkpoint) committed with `--no-verify` — a
documented carve-out to avoid an infinite hook chain — which meant those `chore(session-end)`
commits *never ran the tests*. A red suite rode onto `main` for days until CI caught it.

### Added
- **`hooks/scripts/test-gate.sh`** — reusable, generic test runner. Detects the project's
  nearest configured test command (`_meta/.test-cmd` override → `npm test` → `tests/run-tests.sh`
  → `make test` / `just test` → `pytest`), runs it with a timeout, and records a verdict to
  `_meta/.test-status` (`PASS|FAIL|NONE`). On red it also `agentdb learn`s the failure so the
  next session is pre-loaded with it. Exit 0 = green or no suite; exit 1 = red.
- **Test-gate suite** in `tests/run-tests.sh` (9 tests): detection, pass/fail verdicts,
  no-suite-is-green, red→green self-heal, `.test-cmd` override, and wiring assertions for all
  four consumers below.

### Changed
- **`session-end.sh`** runs the test gate before the auto-commit (only when real files
  changed — pure `_meta/logs|agentdb` churn is skipped). On red it still commits locally
  (never lose work) but tags the message `[TESTS RED]`, writes `_meta/plans/tests-red.md`,
  and withholds the push.
- **`autopush.sh` (sweep) + `autopush-postcommit`** are now hard gates (I0.15): either refuses
  to push any repo whose `_meta/.test-status` is `FAIL`. Red never reaches the remote, and the
  block self-clears the moment the suite goes green.
- **`session-start.sh`** surfaces a red verdict first thing (`## ⚠️ TESTS RED`) with an ASK USER
  prompt, so the next session fixes the suite before new work.
- **`hooks.json`** SessionEnd timeout `30s → 210s` (the gate runs the suite inline).
- `_meta/.test-status` added to `.gitignore` (transient run-state, like `.compact-marker`).

### Fixed
- **`test_detect_vaults_default`** was failing in CI. Two drifts: its skip-guard didn't probe
  `~/Documents/Vaults` (so it ran where it should have skipped), and its assertion still
  expected the old `~/Vaults` default after the canonical default moved to `~/Documents/Vaults`.
  Guard now mirrors `detect_vaults()` exactly; assertion matches the real default.

## [7.19.0] - 2026-06-13

Keep the plugin general. Reverts the institutional-layer coupling that 7.18 added to
`session-start.sh`.

### Changed
- **Removed the "Tradition" block from `session-start.sh`.** 7.18 made the hook reference a
  specific institutional vocabulary (telos / ethos / doctrine / canon / chronicles / rites /
  phronesis / commission). That is a *consuming repo's* overlay, not something a general,
  standalone plugin should know about — even keyed on file existence, it leaked bespoke
  concepts into a product other people install. Such session overlays belong in the consuming
  repo's own vault-level `settings.json` SessionStart hook, which Claude Code runs alongside
  the plugin's. The plugin again knows a "vault" only as its agentdb data home.

### Kept (from 7.18)
- The post-migration **vault-detection fix** stands: `detect_vaults()` checks
  `~/Documents/Vaults` before legacy `~/Vaults`; `KERNEL_VAULTS` overrides for non-standard
  locations. This release re-publishes it cleanly so it reaches installs pinned to older
  cached versions.

## [7.18.0] - 2026-06-13

Hooks enforce the tradition. An institutional layer becomes part of every session instead of
a sentence that gets ignored under load.

### Added
- **Institutional-layer surfacing in `session-start.sh`.** When a vault carries an
  institutional layer (`_meta/ethos.md` present — alongside `telos.md`, `doctrine.md`,
  `canon/`, `chronicles/`, `rites/`), the SessionStart hook injects a compact **Tradition**
  block into every session: read ethos/doctrine + skim canon before MAJOR autonomous work,
  write a chronicle after, treat big delegated work as a commission. Keyed on file existence,
  so it is silent and zero-cost in vaults without the layer. Enforcement-by-presence per
  invariant **I0.15** (hooks, not honor-system) — the prior CLAUDE.md pointer was prose that
  load pressure ignored.

### Fixed
- **Post-migration vault detection now ships by default.** `detect_vaults()` checks
  `~/Documents/Vaults` before the legacy `~/Vaults`, so the "KERNEL NOT INITIALIZED" banner no
  longer fires on machines whose vault moved to `~/Documents/Vaults` (and agentdb / agent-identity
  paths resolve correctly). Present in source since 7.17; this release guarantees it reaches
  installs still pinned to an older cached version. `KERNEL_VAULTS` remains the explicit override
  for non-standard locations.

## [7.17.0] - 2026-06-06

Cross-project retrieval. `agentdb recall` learns to reach beyond one project.

### Added
- **`agentdb recall --global`** — unions local FTS results with a cross-project
  **global brain** (a metabrain-native `global.db`, located via `$AGENTDB_GLOBAL`
  or by walking up to a vault root), tagged `[global]`. Read-only on the global
  brain (never rebuilds its FTS or writes — an external consolidation job owns it);
  LIKE fallback when the brain has no FTS index. A shared `_recall_emit` helper
  (FTS-or-LIKE, always visibility-filtered) drives both local + global; dedup keeps
  the local copy of any lesson present in both. Local-only `recall` is unchanged.

### Fixed
- **`agentdb decay` no longer deletes still-used learnings.** Since 7.15 `hit_count`
  is recall-only, so a learning that read-start surfaces every session but that was
  never recalled keeps `hit_count=0` — the old `decay` (delete `hit_count=0 AND >46d`)
  would wrongly delete it. Now requires `load_count=0` too: only truly untouched
  learnings (never recalled AND never loaded, >46d) are removed.

### Notes
- `recall --global` degrades silently to local-only when no global brain exists, so
  it's safe for every plugin user. The global-brain builder (cross-project importer
  + nightly consolidation) is environment-specific infrastructure, not shipped in the
  plugin; the plugin ships only the retrieval side.

## [7.16.0] - 2026-06-06

Zero-touch auto-push. A commit that isn't pushed is incomplete work (stranded,
undeployed, invisible to the next clone). The plugin now guarantees pushing with no
command and no per-machine setup: `autopush.sh install` (SessionStart) drops a
per-commit auto-push `post-commit` hook into every repo in the current project's tree
(walks to the outermost superproject — covers the whole vault from anywhere inside it),
so every commit pushes itself the instant it's made; `autopush.sh sweep` (SessionEnd)
pushes any straggler whose push failed. Ships via the marketplace, so every machine with
the plugin gets it automatically — nothing to paste into settings.json. Origin-only,
skips detached/mid-rebase, non-fatal; `AUTOPUSH_OFF=1` to disable, `DRY_RUN=1` previews.

## [7.15.0] - 2026-06-06

Retrieval quality pass: `agentdb recall` (FTS5 relevance search, added in 7.14)
was returning duplicate and human-only learnings and ranking on a poisoned
signal. Five additive fixes, all verified on scratch copies of live DBs (our4cuts
546-row + modelmind 854-row), zero live data touched. Source analysis in
`_meta/reports/` (retro-agentdbs, retrieval-deepdive, dream-retrieval).

### Fixed
- **recall returned duplicate insights.** The learning DBs carry many near-identical
  rows; recall returned the same lesson N times. Now over-fetches ranked rows and
  dedups by a 200-char insight-prefix key in awk, keeping the best-ranked of each.
  (bm25() can't live inside `GROUP BY`/an aggregate — the optimizer flattens the
  subquery and throws "unable to use function bm25 in the requested context" — so
  dedup is done post-query, not in SQL.)
- **recall leaked human-only learnings to agents.** It never applied the migration-009
  visibility filter, so `human_only`/`operational` rows were fed into agent context.
  Both the FTS path and the LIKE fallback now filter `visibility='agent'` (NULL =
  agent for pre-009 rows); the relevance-feedback bump filters too.
- **Ranking was uncalibrated.** The failure boost (−5) was a sledgehammer next to
  bm25's ~−0.5..−8 range — a barely-relevant failure beat a near-perfect pattern.
  Recalibrated: failure/gotcha −1.5, `MIN(hit_count,20)*0.05` (capped so popular
  rows can't run away), recency −0.5. Relevance leads; boosts nudge.

### Changed
- **hit_count is now relevance-only; read-start uses `load_count`.** read-start
  blanket-bumped hit_count on every dumped row each session, making it a
  session-open counter that both its own score and recall ranked on. New
  `load_count` column (added idempotently by preflight, like 009) takes the
  session-open telemetry; `hit_count` is now incremented ONLY by recall (and
  learn-time reinforce) — a trustworthy "answered a real task query" signal.
  Migration `013_learnings_load_count` (marker-only; preflight owns the column).
- **Query hygiene in recall.** Strips 1-char tokens and common stopwords before
  building the OR'd FTS query, with a raw-terms fallback if hygiene empties it.

### Notes
- Existing per-project DBs self-heal on next session start (preflight runs before
  read-start) — no manual migration needed. No FTS sync triggers (they abort the
  learn path on SQLite 3.43); rebuild-on-recall remains the design.
- Promoted the universal **"Done = verified live, not committed"** rule into the
  shared layer (session-start.sh delivery + CLAUDE.md anti-pattern), generalized
  from our4cuts' deploy-verification bruise.

## [7.14.0] - 2026-05-28

Correctness + consistency pass: hardened the AgentDB self-heal and the security
hooks (real users depend on both), then converted the skill corpus from prose
blobs to numbered executable flows. Source reports in `_meta/reports/`
(adversary-agentdb-migration-drift, review-hooks, skill-flow-rewrite-audit) and
plan in `_meta/plans/md-philosophy-enshrinement.md`.

### Fixed
- **AgentDB migration drift self-heal.** Existing DBs created on an older version never received later migrations (they only ran on fresh `init`). Preflight now applies pending migrations every session start, and force-re-reads idempotent migrations to restore a migration-created table (e.g. `events`) that drifted away while its `_migrations` marker stayed recorded — previously this looped forever on "missing_table" + phantom repairs. `find_project_root` gains an `AGENTDB_ROOT` override + loud fallback warning to stop orphan DBs.
- **Migration 010 timestamp normalization** guarded with `strftime(...) IS NOT NULL` so empty/garbage `ts` are left intact instead of silently overwritten with NULL (data loss). Adversary-found.
- **Secret scanner missed real Anthropic keys.** `sk-ant-[a-zA-Z0-9]{20,}` stopped at the first hyphen, so `sk-ant-api03-…` matched nothing. Broadened the `sk-` family; the scanner now also fails *closed* when `jq` is missing.
- **Security guards could fail open.** Blocking guards (guard-bash, guard-config, detect-secrets) no longer source the circuit breaker — a tripped breaker made them `exit 0` (allow), disabling scanning for 10 min. A safety gate must always run (I0.15).
- **Guard bypasses closed:** force-push `-f`/`--force-with-lease` in any position; `rm -fr`/`--no-preserve-root` flag orderings on root/home; `git status; rm -rf /` command chaining slipping past auto-approve.
- **Lifecycle hooks** no longer auto-push `main` (I0.8), and escape the checkpoint payload so a contract goal containing `"`/`\` no longer drops the auto-handoff.

### Changed
- **18 over-cap skills rewritten** from prose "blobs to remember" into terse, numbered, ordered, gated executable flows; deep context relocated to each skill's `reference/<id>-research.md` (build 340→156L, api 325→114L, etc.). No information deleted — verified by an opus info-loss auditor reading surviving content per diff.
- **`agentdb write-end` bookend enforced** across every skill flow that lacked one; `read-start` added to the analysis-entry commands (diagnose, dream).
- **Consistency fixes:** `dreamer` agent name `kernel:dreamer`→`dreamer` (resolved a `kernel:kernel:dreamer` double-prefix registration); `ship`/`context-mgmt` frontmatter names normalized; `reviewer` inject-context slice corrected; stale `help.md` version + `handoff.md` dead path fixed.

### Added
- **`scripts/bump-version.sh`** — single-command version bump across every canonical declaration (plugin.json, marketplace.json, CLAUDE.md, help.md, README install path), pure-Python (macOS/Linux safe).
- **`test_version_sync_all`** — fails the suite if any canonical version declaration drifts from `plugin.json`, replacing the narrower plugin↔marketplace check. Drift is now impossible to commit.

## [7.13.0] - 2026-05-14

Six-week refresh after a research+audit pass synthesizing modelmind, cross-project, and dreams folder learnings. Source reports in `_meta/research/modelmind-mining-2026-05.md`, `_meta/research/cross-project-mining-2026-05.md`, `_meta/research/dreams-synthesis-2026-05.md`, and `_meta/audit/state-audit-2026-05.md`.

### Added (Wave 1)
- **Research-Failures-First protocol** — `_meta/reference/research-failures-first.md`. Empirically ranked channel taxonomy (GitHub issues 47% unique-find rate + production case studies 78% run in parallel; anti-pattern web search 15% dropped). Mandatory canonical map at `_meta/research/<topic>.md` with ≥10 entries before any native/schema/auth/sync/store-submission work.
- **`deep-diver` agent** — `agents/deep-diver.md`. Sonnet agent that runs the Research-Failures-First protocol, spawns Channel-A + Channel-D in parallel, verifies deliverables by file (not by receipt), commits the canonical map, returns ≤200-word receipt to orchestrator. NEXUS layer was already routing to this agent; now it exists.
- **Fidelity health check** in `skills/context-mgmt/SKILL.md` — five reasoning-quality signals (hypothesis depth, backtracking presence, step count, cross-file awareness, inline verification) that warrant compaction independent of the token meter.

### Changed
- **Compaction trigger** moved to **~60% context fill** in `skills/context-mgmt/SKILL.md`, with rationale: reasoning fidelity degrades at 60-70% (HF Daily Papers research). Previous threshold of "~70% capacity" was too late.
- **Verify-by-file invariant** hardcoded across `agents/surgeon.md`, `agents/adversary.md`, and `skills/orchestration/SKILL.md`. Subagent receipts describe intent; the deliverable file is evidence. Modelmind LRN: surgeon claimed drag-and-drop "implemented" but the file contained only type definitions.
- **Shared-file parallelism warning** in `skills/orchestration/SKILL.md` anti-patterns — even with zero-overlap file plans, parallel agents independently fix common lint/format issues and produce N-way merge conflicts.
- **`_learnings.md` refresh** — log frozen at v6.0.0 (Mar 4) caught up to v7.12.2 with distilled entries from 6 weeks of CHANGELOG advances (GEPA traces, R-factor scoring, learning decay, 11-phase review, 9-gate safety, knowledge injection, approval learner, worktree safety, read-utilization tracking).

### Fixed
- **`--no-verify` hidden carve-out** — `session-end.sh` and `pre-compact-commit.sh` use `--no-verify` to avoid infinite hook loops. This was undocumented at the CLAUDE.md level, creating an invisible contradiction with the stated rule. Now explicit in `<git><hook_carve_outs>` with rationale, and both scripts reference the carve-out documentation inline. The exception is machine-only; user-driven and agent-driven commits must still pass all gates.

### Added (Wave 2)
- **`kernel:ship` skill** — `skills/ship/SKILL.md`. The release-gate sequence (preflight → validate → review → push → optional tag → checkpoint) NEXUS already routed to. Push to `main` requires explicit user confirmation (mirrors NEXUS I0.8). Force-push never auto-attempted on rejection.
- **`blind-evaluator` agent** — `agents/blind-evaluator.md`. Structurally separate eval agent that receives only the problem statement + rubric, never the solution. Includes contamination check on input (refuses to score if implementer narrative leaked in). Self-scoring inflates ~36% structurally; only structural separation fixes it.
- **AgentRx 4-type failure taxonomy in `agents/coroner.md`** — independent of root-cause-of-death, classify the failure *mechanism* as Action / Reasoning / Tool / State, each with distinct mitigations. Source: Microsoft Research AgentRx, 115 annotated trajectories. Enables queries like "mostly State failures lately = context-mgmt regression."
- **`max_budget_usd` invariant** in `skills/orchestration/SKILL.md` and budget preflight in `commands/forge.md`. Promotes the cost cap from optional config to mandatory infrastructure for any autonomous loop or tier 2+ multi-agent spawn. One stuck retry at $0.40-0.60/query × 200 retries = $120 silently — the cap is the only mechanism that catches this.
- **Spec-completeness gate (step 4b)** in `commands/ingest.md` — execution-ready artifacts (exact file paths, exact symbols, exact code snippets, exact configs/SQL) required before handing off to a surgeon or starting execution. Litmus test: "could a fresh agent execute this with zero follow-up?" If no, the spec is incomplete. Source: modelmind H002/H003, 0.95 confidence.

### Changed (Wave 2)
- **CLAUDE.md `<invariants>` block** — three highest-leverage NEXUS I0 invariants mirrored to the plugin for visibility: I0.13 (anchor-drift stop), I0.14 (worktree isolation for parallel agents), I0.15 (hooks-not-honor-system for critical safety). Full I0 list lives in `CodingVault/.claude/CLAUDE.md`.
- **CLAUDE.md `<anti_patterns>`** gained three new blocks: `trust_agent_summary` (files describe reality, not receipts), `self_score_high_stakes_eval` (use blind-evaluator), `autonomous_loop_without_budget_cap` (`max_budget_usd` mandatory).
- **`skills/eval/SKILL.md` restructure** — new core principle on structural separation, new `<blind_evaluation_protocol>` block, two-phase eval pattern (cold Run 1 scored, optimization Run 2), four new anti-patterns (self-score, post-merge eval, greenfield in golden dataset, context breadth before baseline).

---

## [7.9.2] - 2026-04-01

### Fixed
- **AgentDB read utilization** — `read-start` now bumps `hit_count`/`last_hit` on surfaced learnings, enabling natural selection (useful learnings accumulate hits, stale ones get pruned). (#127)
- **Gotchas never surfaced** — `read-start` now includes "Known Gotchas" section (34/37 gotchas were invisible). (#127)
- **Domain column empty** — `learn` auto-infers domain from `$PWD` basename when not explicitly provided. (#127)
- **Symlink test** — test checked `session-start.sh` but `update_current_symlink` moved to `common.sh` in v7.9.1.
- **CI shellcheck** — excluded `node_modules/` from shellcheck scan.

### Changed
- **Agent context injection** — surgeon, adversary, reviewer, researcher now use `agentdb inject-context <role>` for role-scoped knowledge instead of generic `read-start` dumps. (#127)
- **3 new tests** — 230 total passing.

---

## [7.9.0] - 2026-03-31

### Added
- **Cartographer agent** — Opus whole-codebase mapper with 1M context. (#38)
- **Coroner agent** — Sonnet post-mortem analyst for failed contracts. (#47)
- **Pre-ship agent** — Composite release gate, 4 parallel validators, SHIP/NO-SHIP verdict. (#98)
- **App development skill** — Mobile/web build, EAS, store submission patterns. (#102)
- **PostToolUse JSON schema validation** — validates JSON/SQL after writes. (#99)
- **Session-start blocker surfacing** — stale contracts + error loop detection. (#100)
- **Hardcoded value warning** — hex colors and px values in components. (#101)
- **Entropy-adaptive coordination** — dynamic agent orchestration by task entropy. (#71)
- **27 new tests** — 227 total passing.

---

## [7.6.4] - 2026-03-30

### Fixed
- **capture-error.sh reads `tool_name`** — PostToolUseFailure hook now reads `tool_name` from stdin JSON (was reading `tool`, causing all errors to log as 'unknown'). (#103)
- **session-start creates MEMORY.md** — Auto-memory directory and MEMORY.md are created on first session if missing, preventing read-start crash. (#104)

### Added
- **Phase 0 bug fix tests** — 3 new regression tests for capture-error tool extraction and memory directory creation.
## [7.7.0] - 2026-03-30

### Added
- **AskUserQuestion integration** — All 11 commands (except help) now have `<ask_user>` blocks at phase boundaries. 7 agent definitions include decision-point questions. Session-start hook surfaces stale contracts and uncommitted files as prompts. (#119)
- **Worktree safety protocol** — Surgeon agent validates file modifications against contract constraints. Orchestration skill enforces pre-spawn clean state and post-agent diff validation. `constraints.files` documented in contract JSON schema. (#116)
- **3 new worktree safety tests** — Validates surgeon, orchestration, and agentdb constraint support.

### Changed
- **Philosophy rewrite** — Comprehensive rewrite of `<philosophy>` section. All original principles preserved. 5 new principles: pre-load over ask, fallback-first, composite quality, ask at decision points, slow down to speed up. (#118)
- **Token budget compliance** — Trimmed ingest.md (214→190 lines) and forge.md (207→188 lines) to stay under 200-line budget after AskUserQuestion additions.
## [7.7.1] - 2026-03-30

### Added
- **11-phase adversarial review protocol** — Reviewer agent upgraded with structured review: checkpoint → Big5 → scope → smoke → edge cases → error paths → regression → security → contract → mutation → quality. Confidence scoring formula with 0.8 threshold. (#89)
- **9-gate safety chain** — Validator agent upgraded with progressive gates: branch isolation → atomic commits → lint → types → tests → security → adversarial review → human checkpoint → post-merge monitoring. Fail-fast model. (#91)
- **Triage agent** — Haiku-powered complexity classifier. Single fast call classifies low/medium/high/epic before expensive agents spawn. (#92)
- **Understudier agent** — Haiku pre-flight validates approach viability before surgeon commit. Checks: existence, compatibility, conflicts, dependencies, test infrastructure. (#40)
- **Knowledge injection system** — `agentdb inject-context <agent_type>` builds agent-specific context slices. Orchestrator injects before spawn. Surgeon gets gotchas+patterns, adversary gets failures+errors, researcher gets all learnings by domain. (#110)
- **17 new tests** — Phase 2 agent tests (4), triage/understudier tests (8), knowledge injection tests (5). 152 total passing.

### Changed
- **plugin.json description** — Updated to reflect 9 agents, knowledge injection, 11-phase review, 9-gate safety chain.
## [7.8.0] - 2026-03-30

### Added
- **GEPA execution traces** — `agentdb trace <json>` records goal/exploration/plan/action/outcome for every task. New `execution_traces` table via migration 005. (#90)
- **IMMUNE pattern antibodies** — `agentdb antibody <pattern>` searches learnings by pattern match. Finds proven solutions and known failures for similar problems. (#96)
- **Learning decay** — `agentdb decay` archives stale learnings (0 hits, >46 days). Reports freshness distribution: high-confidence/reinforced/unvalidated. (#97)
- **Approval learner agent** — Sonnet observer that extracts patterns from human review decisions. Progressive rule promotion: observe → suggest → enforce. Confidence = validated/applied. (#111)
- **R-factor quality scoring** — Composite weighted quality score replacing binary pass/fail. 6 dimensions: tests + acceptance + scope + security + budget + first-try. Thresholds: 0.85 (production), 0.70 (good), 0.50 (acceptable). (#68)
- **13 new tests** — Learning system (6), approval learner + R-factor (7). 148 total passing.
## [7.8.1] - 2026-03-30

### Added
- **Skill template system** — `skills/TEMPLATE.md` provides documented skeleton for creating domain-specific skills. Covers: source loading, triggers, quality gates, output format, flags, anti-patterns. (#115)
- **Pre-tool validation hook** — `validate-structure.sh` warns on missing frontmatter (commands/agents) and missing triggers (skills). Async, never blocks. (#117)
- **Analyzer agent** — Opus-powered cross-task intelligence. Dependency detection, batch analysis, systemic patterns, priority recommendation. (#93)
- **Progressive autonomy** — Confidence-based human escalation in orchestration skill. Supervised → semi-autonomous → autonomous. Security-sensitive changes always escalate. (#95)
- **Budget-aware agents** — Token budget tracking and self-regulation protocol. Alerts at 50/80/95%. Agents see remaining budget and adjust complexity. (#94)
- **ADSR anomaly detection** — Proactive deviation detection in quality skill. Anomaly → Detection → Suppression → Recovery. Baselines from historical data. (#112)
- **Checkpoint-based recovery** — Resume from last good state in orchestration skill. Saves 40-60% on failures. Version safety prevents stale state. (#113)
- **Co-change graph** — `agentdb co-change <file>` mines git history for file co-modification patterns. Predicts impacted files. (#114)
- **18 new tests** — Framework (8), agents (6), extensions (4). 153 total passing.

---

## [7.6.1] - 2026-03-25

### Added
- **`/kernel:retrospective` command** — Cross-session learning synthesis. Queries AgentDB learnings, clusters by theme, merges duplicates, resolves contradictions, archives stale entries, promotes high-confidence patterns into rules. 5 dedicated tests.
- **Command routing in ingest** — Execute phase now routes to the right command before implementing: `/kernel:dream` for design, `/kernel:diagnose` for bugs, `/kernel:forge` for autonomous runs, `/kernel:tearitapart` for pre-implementation critique.
- **Context-aware help** — `/kernel:help` now checks actual plugin state (profile, active contracts, AgentDB status) before showing help, so the output reflects reality rather than just reciting docs.

### Fixed
- **Renamed `auto.md` → `forge.md`** — Filename now matches the `kernel:forge` frontmatter name. Was causing `/kernel:forge` to not load correctly.
- **Stale `/kernel:auto` references** — Updated diagnose.md and CHANGELOG.md to reference `/kernel:forge`.

### Removed
- **`code-review.yml` CI workflow** — Removed failing GitHub Actions workflow that required `CLAUDE_CODE_OAUTH_TOKEN`. Local `/kernel:review` is more thorough. Re-add when token is configured.

### Changed
- **Updated `/kernel:help`** — Full rewrite with all 12 commands, workflow chains, agent roster, and usage tips.
- **Ingest learn phase** — Now suggests `/kernel:retrospective` when 5+ learnings accumulated.
- **Ingest execute phase** — Tier 2+ now includes `/kernel:tearitapart`, `/kernel:validate`, and `/kernel:review` steps.
- **Forge/handoff learn phases** — Reference `/kernel:retrospective` for cross-session synthesis.

---

## [7.6.0] - 2026-03-25

### Added
- **`/kernel:forge` command** — Autonomous development engine. Heat/hammer/quench/anneal cycle. Generates competing approaches, implements against failing tests, adversarial review, iterates until antifragile. Stops after 3 structural failures or 10 iterations. Full AgentDB audit trail.
- **`/kernel:dream` upgrade** — Now includes 4-persona stress test council (Devil's Advocate, Pragmatic Engineer, Security Auditor, End User) that probes each perspective for flaws. Integrity scoring 0.0-1.0.
- **`/kernel:diagnose` command** — Bug mode and refactor mode with structured diagnosis output.
- **`/kernel:metrics` command** — Observability dashboard wrapping `agentdb metrics` + `agentdb health`.
- **Aggressive skill loading** — Ingest and forge commands now load skills by classify/domain/tier triggers.

---

## [7.5.1] - 2026-03-24

### Changed
- **Session-start rewrite** — Replaced 105-line static methodology block with skill-referencing decision tree. Session hook now points to skills instead of duplicating their content. Skills ARE the methodology; the hook is the routing protocol. (#59)
- **Profile-gated git workflow** — Git skill and all 3 workflow files (feature, bugfix, refactor) now enforce PR requirements by profile: local (direct OK), github (PRs optional), github-oss (PRs required), github-production (PRs + review required). (#55)
- **XML decision tree protocol** — Session-start outputs a structured `<decision_tree>` with 8 steps (READ → CLASSIFY → RESEARCH → SCOPE → DEFINE SUCCESS → EXECUTE → SHIP → LEARN), each referencing the specific skill to load.
- **Skills index in session output** — Categorized as always/by_task/by_domain/commands/advanced so Claude aggressively loads relevant skills.

---

## [7.5.0] - 2026-03-24

### Added
- **Project profile detection** — Auto-detects project complexity as `local`, `github`, `github-oss`, or `github-production`. Gates context output and feature availability accordingly. (#54)
  - `local`: No GitHub remote. Minimal context, no GitHub features referenced.
  - `github`: Private GitHub repo. Standard context.
  - `github-oss`: Public GitHub repo. Full context with branch protection, PR workflow, and agent details.
  - `github-production`: >2 collaborators, environments, or projects board. Full context plus team signals.
- **`detect_profile()`** in common.sh — Pure functions (`parse_github_remote`, `classify_profile`) + cached detection with 1hr TTL, 5s API timeout, graceful offline degradation.
- **Profile-gated session output** — Session start now shows `**Profile:** {tier}` in header and adjusts reference sections by profile. Local projects get compact output. OSS/production projects get full GitHub workflow guidance.

---

## [7.4.0] - 2026-03-24

### Added
- **Post-compaction context restoration** — New `UserPromptSubmit` hook restores methodology context after compaction. PreCompact writes a marker with active contract, recent learnings, and branch info. First user message after compaction gets full context injection. Marker auto-deletes after use. (#33)
- **Circuit breaker for hooks** — Guard hooks (guard-bash, guard-config, detect-secrets, auto-approve-safe) now degrade gracefully. After 3 consecutive failures, the hook disables itself for 10 minutes instead of blocking all operations. Project-scoped state in `_meta/.breakers/`. Lifecycle hooks (session-start, session-end, pre-compact) are exempt — they always run. (#21)
- **`/kernel:diagnose` command** — Systematic debugging and refactor analysis before fixing. Bug mode: reproduce → trace → isolate → hypothesize → diagnose. Refactor mode: map → trace deps → measure coupling → risks → diagnose. Produces structured diagnosis with blast radius, affected files, and recommended approach. Hands off to `/kernel:ingest` or `/kernel:forge`. (#35)

---

## [7.3.0] - 2026-03-24

### Added
- **`/kernel:dream` command** — Multi-perspective debate before implementation. Generates three competing approaches grounded in actual codebase context:
  - **Minimalist** 🔻 — Radical simplification. Questions whether the feature is needed. Finds the 20-line version. Provocative and terse.
  - **Maximalist** 🔺 — Full vision. The architecture you'd be proud of in 6 months. Extensible, thorough, ambitious.
  - **Pragmatist** ⚖️ — The 80/20 point. Ships this week with explicit tradeoffs and documented upgrade path.
  
  Each perspective uses a distinct voice reflecting its value system. The dreamer prevents Claude's convergence bias from collapsing the solution space before you see alternatives. (#42)

- **Dreamer agent** — For tier 2+ dreams, spawns a dedicated agent that reads the actual codebase to ground each perspective in real files and patterns. Writes to `_meta/dreams/` and optionally posts to GitHub Discussions (Decisions category) when `gh` is authenticated.

- **Agent personality system (dreamer voices)** — First implementation of distinct agent voices. Minimalist is terse/provocative, Maximalist is expansive/visionary, Pragmatist is balanced/deadline-aware. Foundation for full personality system across all agents. (#53)

### Philosophy

The dreamer enforces the existing "never implement first solution" rule structurally instead of as a prohibition. Three value systems compete because they're structurally opposed — minimalist and maximalist can't converge. This guarantees solution space expansion before narrowing.

**Pipeline:** Dream → Select → Plan → TearItApart → Execute

---

## [7.2.0] - 2026-03-24

### Added
- **Telemetry events table** -- Migration 003 adds `events` table for tracking session lifecycle, agent spawns, hook executions, and command usage. Auto-applies on next session start. (#43)
- **`agentdb emit`** -- New subcommand for recording telemetry events with category, duration, and metadata.
- **`agentdb health`** -- New subcommand showing schema status, dependency checks, learning stats, and disk usage.
- **Learning deduplication** -- Similar learnings reinforce existing records (bumps hit_count) instead of creating duplicates. (#20)
- **Learning highlights** -- Session start surfaces top 3 most-reinforced learnings so patterns propagate across sessions.
- **Stale learning pruning** -- Learnings with 0 hits older than 30 days auto-pruned at session start.
- **System health warnings** -- Session start checks for missing dependencies (jq, gh) and auth status. Warnings only shown when something needs attention.
- **Auto-migration** -- Session start runs `agentdb init` automatically, applying any pending schema migrations. Plugin updates are seamless.

### Changed
- **Directive calibration** -- Softened aggressive MUST/NEVER language that caused Claude 4.6 over-triggering. Security-critical directives (secrets, data loss) remain strong. (#34)
- **CLAUDE.md context note** — Added developer note that CLAUDE.md is NOT loaded for plugin users; session-start.sh is the only ambient context delivery mechanism.
- **aDNA graph attribution** — README now credits [aDNA (Lattice Protocol)](https://github.com/LatticeProtocol/adna) for the graph architecture that inspired AgentDB's nodes/edges/context_sessions system.

---

## [7.1.2] - 2026-03-24

### Fixed
- **capture-error.sh dead code** — Hook read from `$CLAUDE_TOOL_USE_RESULT` env var instead of stdin. Zero errors were ever captured. Now reads stdin like every other hook. Fixes [#19](https://github.com/ariaxhan/kernel-claude/issues/19).
- **Silent push failures** — session-end.sh swallowed push failures with `|| true`. Now warns on stderr so data loss is visible. Fixes [#23](https://github.com/ariaxhan/kernel-claude/issues/23).
- **Version mismatch** — CLAUDE.md said 7.0.4 while plugin.json said 7.1.1. Synced to 7.1.2. Fixes [#27](https://github.com/ariaxhan/kernel-claude/issues/27).
- **detect-secrets gaps** — Added 6 missing secret patterns: Anthropic API keys (`sk-ant-`), Google/GCP API keys (`AIza`), Google OAuth tokens, Google OAuth client IDs, Azure connection strings, Azure storage account keys. Fixes [#29](https://github.com/ariaxhan/kernel-claude/issues/29).

---

## [7.1.1] - 2026-03-13

### Fixed
- **Stale hooks after update** - Session start now auto-updates `current` symlink to latest version. Fixes [#10](https://github.com/ariaxhan/kernel-claude/issues/10) where Claude Code downloads new versions but doesn't activate them.

### Added
- `update_current_symlink()` in common.sh - Self-healing function that detects and fixes stale plugin symlinks

---

## [7.1.0] - 2026-03-13

### Added
- **Cross-machine portability** - Hooks now auto-detect Vaults location via `common.sh`
- **KERNEL_VAULTS env var** - Explicit override for custom Vaults locations
- **Portability test suite** - 7 new tests verifying cross-machine behavior
- **Teammate sync** - Session start auto-pulls latest from remote (if clean working tree)

### Changed
- **Detection order** - `$KERNEL_VAULTS` → `~/Vaults` → `~/Downloads/Vaults`
- **No duplication** - All hooks source `hooks/scripts/common.sh` instead of duplicating detection logic
- **init.md trimmed** - Reduced from 250 to 116 lines (under token budget)

### Fixed
- **Agent file creation** - Test now properly uses KERNEL_VAULTS override
- **60 tests passing** - Full test suite green

---

## [7.0.4] - 2026-03-13

### Fixed
- **hooks.json paths** - Reverted to `${CLAUDE_PLUGIN_ROOT}` for hook script paths. v7.0.1's change to `${CLAUDE_PROJECT_DIR}` was wrong — that points to the user's project, not the plugin directory.

**The correct pattern:**
- `hooks.json`: Use `${CLAUDE_PLUGIN_ROOT}` to find hook scripts in the plugin directory
- Hook scripts: Use `SCRIPT_DIR` self-location to find agentdb binary, `CLAUDE_PROJECT_DIR` for user's project

---

## [7.0.3] - 2026-03-13

### Fixed
- **Hook scripts self-location** - All hooks now use `SCRIPT_DIR` to locate plugin binaries instead of relying on env vars. Fixes "agentdb not found" errors from v7.0.2.

### Enhanced
- **Session start output** - Now shows 5 recent git commits (not just 1) for better project context

---

## [7.0.2] - 2026-03-13

### Fixed
- **Hook scripts env vars** - Fixed all 5 hook scripts using wrong env vars (`CLAUDE_PLUGIN_ROOT`, `CLAUDE_PROJECT_ROOT`). Now correctly use `CLAUDE_PROJECT_DIR` which is set by Claude Code's hook executor.
- **Context skill conflict** - Renamed `skills/context/` to `skills/context-mgmt/` with name `kernel:context`. The old `name: context` shadowed Claude's native `/context` command.

### Changed
- **Skill invocation** - Context skill now invoked as `/kernel:context` to avoid shadowing native `/context`

---

## [7.0.1] - 2026-03-13

### Fixed
- **Hook portability** - Replaced `${CLAUDE_PLUGIN_ROOT}` with `${CLAUDE_PROJECT_DIR}` in hooks.json. `CLAUDE_PLUGIN_ROOT` is broken in Claude Code's hook executor ([issue #24529](https://github.com/anthropics/claude-code/issues/24529)).

---

## [7.0.0] - 2026-03-12

### Changed
- **Research-first workflow** - Research phase now mandatory before implementation
- **Skill references** - Skills link to research docs in `skills/*/reference/`
- **AgentDB contracts** - Tier 2+ requires contracts before spawning agents

---

## [6.1.5] - 2026-03-08

### Fixed
- **Command namespacing** - Commands now explicitly include `kernel:` prefix in name field (e.g., `name: kernel:ingest`)
- Commands now appear as `/kernel:ingest` instead of `/ingest` in autocomplete

---

## [6.1.2] - 2026-03-08

### Fixed
- **Command format** - Converted all commands from XML to YAML frontmatter (Claude Code requirement)
- **Build skill format** - Added missing YAML frontmatter to skills/build/SKILL.md
- **Frontmatter fields** - Added `name`, `description`, `user-invocable`, `allowed-tools` to all commands

### Changed
- Commands now use standard YAML frontmatter instead of custom XML tags
- All commands include `user-invocable: true` for slash command registration

---

## [6.1.1] - 2026-03-08

### Fixed
- **Commands not loading** - Added explicit `commands` array to plugin.json (commands require explicit registration, unlike skills which auto-discover)
- **Plugin manifest** - Added `skills`, `agents`, `hooks` fields for proper component registration
- **Marketplace sync** - Updated version and description to match plugin.json

---

## [6.1.0] - 2026-03-08

### Added

#### Skills (5 new)
- **tdd** - Test-Driven Development with mock patterns (Supabase, Redis, OpenAI)
- **eval** - Eval-Driven Development with pass@k metrics
- **e2e** - Playwright E2E testing with Page Object Model
- **api** - REST API design patterns (resources, status codes, pagination)
- **backend** - Backend patterns (repository, caching, queues, N+1 prevention)

#### Agents (1 new)
- **reviewer** - PR/code review with >80% confidence threshold

#### Commands (2 new)
- **/kernel:validate** - Pre-commit verification loop (build, types, lint, tests, security)
- **/kernel:review** - Code review with APPROVE/REQUEST CHANGES/COMMENT verdicts

#### Hooks
- **detect-secrets.sh** - Blocks writes containing API keys, tokens, credentials (10 patterns)

#### LSP Support
- Setup guide for 600x faster code navigation (`_meta/reference/lsp-setup.md`)
- Session start hook warns when LSP not enabled
- CLAUDE.md guidance to prefer LSP over grep

### Enhanced
- **security skill** - Zod validation, XSS/DOMPurify, CSRF, file upload, rate limiting
- **context skill** - Compaction strategies, AgentDB offloading patterns
- **adversary agent** - Added >80% confidence threshold and calibration

---

## [6.0.0] - 2026-03-04

Major architecture release: XML-structured config for AI parsing.

### Added
- XML-structured CLAUDE.md for deterministic AI parsing
- 11 skills with dedicated research references
- 5 agents (surgeon, adversary, researcher, scout, validator)
- Session lifecycle hooks (start, end, pre-compact)
- Guard hooks (bash, config protection)
- AgentDB CLI tool

### Changed
- Reduced CLAUDE.md to <150 lines
- Reduced kernel.md to <100 lines
- Skills split into SKILL.md + reference/*-research.md

---

## [5.6.0] - 2026-02-28

### Added
- Design skill with 4 aesthetic mood variants
- Anti-convergence philosophy for UI work

---

## [5.5.0] - 2026-02-26

### Added
- Orchestrator pattern for multi-agent coordination
- AgentDB bus for inter-agent communication

---

## [5.4.0] - 2026-02-24

### Added
- Hook system (PreToolUse, PostToolUse, SessionStart/Stop)
- Article alignment with Anthropic best practices

---

## [5.3.0] - 2026-02-22

### Added
- Simplified one-command install
- AgentDB CLI with status/prune/export/recent commands

---

## [5.2.0] - 2026-02-20

### Added
- AgentDB read/write hooks to all commands
- Skill-specific AgentDB ON_START/ON_END
- Health check and session summary scripts

### Changed
- Unified setup.sh script

---

## [1.2.0] - 2026-01-15

### Added
- Propositional logic context compression (arbiter)
- User-level init command
- Worktree-based git workflow

---

## [1.1.0] - 2026-01-10

### Added
- /docs command
- Branch-first git workflow to core philosophy

---

## [1.0.0] - 2026-01-08

Initial release.

### Added
- Core KERNEL philosophy and methodology
- Knowledge banks (debugging, planning, security, testing, frontend, code-review)
- Basic commands (init, prune, status)
- Plugin manifest for Claude Code marketplace
