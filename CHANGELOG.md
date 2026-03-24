# Changelog

All notable changes to KERNEL are documented in this file.

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
- **CLAUDE.md context note** -- Added developer note that CLAUDE.md is NOT loaded for plugin users; session-start.sh is the only ambient context delivery mechanism.

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
