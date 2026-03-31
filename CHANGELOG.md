# Changelog

All notable changes to KERNEL are documented in this file.

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
