---
name: cross-repo-patterns
description: Survey of sibling repo conventions, hooks, and automation scripts worth promoting into kernel-claude, plus drift to reconcile.
type: reference
date: 2026-05-28
surveyed_repos:
  - modelmind
  - augur
  - poetrytracker
  - our4cuts
  - kernel_systems
  - kernel-cursor
---

# Cross-Repo Pattern Survey — kernel-claude plugin

Surveyed 2026-05-28. Focus: `.claude/` configs, hooks, scripts, git automation, db patterns, design enforcement, worktree usage. Each finding is classified as **PROMOTE** (bring into kernel-claude) or **RECONCILE** (drift kernel must address).

---

## 1. modelmind — Ambient Learnings Hook

**What:** `.claude/hooks/ambient-learnings.sh` fires on every PostToolUse(Write|Edit). It does two jobs: (1) surfaces domain-relevant learnings from AgentDB once per domain per session, (2) tracks which files were touched to a `/tmp/` state dir for the pre-compact handoff. A companion script `scripts/retrieve-learnings.sh` does the DB query and bumps `hit_count` on surfaced rows.

**Kernel-claude status:** kernel has `log-write.sh` (PostToolUse) but it only logs writes to a cost ledger. No ambient learning surface at edit time.

**PROMOTE — Tier 1.**
Add an ambient-learnings variant to kernel's PostToolUse chain. The domain classifier is the only project-specific part (modelmind maps `assets/content/`, `src/components/`, etc.). Kernel's variant would map `commands/`, `agents/`, `skills/`, `hooks/` domains. Non-disruptive: runs async, exits fast when no DB or domain match.

---

## 2. modelmind — Pre-compact / Post-compact Context Pipeline

**What:** Three hooks form a complete compaction survival loop:
- `pre-compact-context.sh` (PreCompact): saves branch, uncommitted count, active contract, files touched, recent learnings, recent commits to AgentDB as `CTX-precompact-latest`. Outputs a markdown summary for the compaction prompt.
- `post-compact-restore.sh` (UserPromptSubmit): detects post-compaction via a session marker in `/tmp/`. If marker is absent, reads `CTX-precompact-latest` from AgentDB and outputs a structured restoration brief. Also restores top learnings from the active domain.
- `ambient-learnings.sh` continuously feeds `files_touched` + `domains_active` so pre-compact has rich state to save.

**Kernel-claude status:** kernel's `pre-compact-commit.sh` checkpoints via a git commit (--no-verify carve-out). `post-compact-restore.sh` exists and does retention scoring from a `.compact-keyterms` file, plus fallback session-start. This is a parallel evolution — modelmind's version is richer in AgentDB integration (contract awareness, domain learnings) while kernel's is richer in git-level state (keyterm retention scoring, actual commit).

**PROMOTE — Tier 2.** The gap: kernel's post-compact restore has no domain-specific learning surface. Modelmind's session marker approach (check `/tmp/`, touch on first run) is cleaner than relying solely on a `.compact-marker` file. Specifically promote:
1. The domain-learning retrieval in post-compact-restore.
2. The session marker pattern (fast exit on normal messages).
3. `files_touched` tracking as a side channel from the write hook.

Merge approach: extend kernel's existing scripts rather than replacing them. No new hook events needed.

---

## 3. modelmind — check-blockers.sh (SessionStart)

**What:** `scripts/hooks/check-blockers.sh` fires on SessionStart. Checks: open GitHub issues labeled "blocker", stale contracts (>48h in AgentDB with no verdict), uncommitted content changes. Outputs a briefing block.

**Kernel-claude status:** `session-start.sh` reads AgentDB and surfaces agent state. It does NOT check GitHub blocker issues or surface stale contracts by age.

**PROMOTE — Tier 1.** Stale contract detection is high value: any contract open >48h with no verdict is probably orphaned. A `SELECT` against AgentDB `context` table with `type='contract'` and `created_at < datetime('now', '-48 hours')` — add to session-start.sh. GitHub blocker check is profile-gated in kernel anyway, so wire it under the `github*` profile guard already present.

---

## 4. modelmind — warn-hardcoded-values.sh (PreToolUse on .tsx/.jsx)

**What:** `scripts/hooks/warn-hardcoded-values.sh` intercepts Write|Edit on `.tsx`/`.jsx` in `src/` or `app/`. Scans the new content for hardcoded hex colors, raw pixel values (`fontSize: 14`), and hardcoded font family names. Exits 0 (warning only, not blocking). Uses Python for JSON parsing but grep for pattern matching.

**Kernel-claude status:** kernel's `warn-hardcoded.sh` does a similar check but is simpler — only hex colors and `px` values, no font-family check, no scope restriction to component directories. Also uses `jq` rather than Python.

**RECONCILE — Tier 1.** Kernel's version should add the font-family check that modelmind has. More importantly: modelmind's version restricts to `src/` and `app/` directories, avoiding false positives on config/data files. Kernel's version fires on all `.tsx|.jsx|.svelte|.vue|.css` — no path restriction. Add a path prefix guard matching wherever the active project's component files live (parameterize via env or config).

---

## 5. modelmind — validate-content-write.sh (PostToolUse, domain-specific gate)

**What:** After any Write|Edit on `assets/content/**/*.json`, validates JSON syntax AND schema (required fields, valid exercise types, non-empty IDs and questions). Exits 1 on failure, blocking further tool use.

**Kernel-claude status:** `validate-json-schema.sh` (PostToolUse) validates JSON syntax and checks for KERNEL-specific schema fields (agent frontmatter, etc.). Does not do field-level schema validation for domain content.

**PROMOTE as pattern, not as code.** The principle: PostToolUse validators should check domain schema, not just syntax. Kernel's `validate-json-schema.sh` should be extended to validate agent/skill/command YAML/JSON frontmatter fields (e.g., confirm `id`, `purpose`, `file` are present in commands). Currently it only checks JSON syntax.

---

## 6. modelmind — block-eas-build.sh (PreToolUse Bash)

**What:** Hard blocks any `eas build` invocation with a clear error message pointing to the local release flow. Exits 2 (block). Simple grep on the command string.

**Kernel-claude status:** `guard-bash.sh` has a pattern for blocking dangerous commands. The specific "block a retired flow with a friendly redirect" pattern is not used.

**PROMOTE as pattern — Tier 1.** For kernel-claude: consider a similar guard for `npm install --global` (installs that bypass the project's pinned deps) or accidental `agentdb init` on an existing DB (which would reset migrations). The pattern is: identify retired/dangerous command → block with exact replacement instruction. Takes 10 lines.

---

## 7. modelmind — validate-content-on-end.sh (SessionEnd)

**What:** On SessionEnd, checks whether any `assets/content/` JSON was modified (staged or unstaged) and if so, runs the full content validator and i18n validator. Warnings only — doesn't block session end.

**Kernel-claude status:** `session-end.sh` does a batch commit of `_meta/` files (--no-verify carve-out). It does NOT run any domain validators at end-of-session.

**PROMOTE — Tier 1.** Kernel should run `validate-json-schema.sh` or a lightweight check over modified agent/skill/command JSON at session end. Currently validation only fires on write (PostToolUse). A session-end pass catches edits that bypassed the hook (e.g., manual terminal edits during a session). Non-blocking: warn, don't fail session-end.

---

## 8. our4cuts — check-design-system.sh (pre-commit git hook)

**What:** A pre-commit hook (wired via `.claude/hooks/`, enforced by I0.5 so `--no-verify` is banned) that scans staged `.astro`/`.ts`/`.css`/`.html` files for design-system violations: Tailwind CDN usage, inline tailwind.config blocks, hardcoded brand hex colors (by explicit list), and raw HTML marketing pages added to `public/` instead of `src/pages/`. Exits 1 on violation with specific file + rule reference.

**Kernel-claude status:** budget-check.sh runs as a pre-commit hook (via hooks.json → but check: it appears to be wired from CodingVault/.claude/CLAUDE.md line-cap rules, not from kernel's hooks.json). No design-system violation scanner at commit time.

**PROMOTE — Tier 2.** Kernel should have a pre-commit hook that enforces its own invariants at commit time, not just at write time. Candidates:
- No `Co-Authored-By` or `Generated with` in commit messages (I0.4 is currently honor-system).
- No secrets in staged files (kernel has `detect-secrets.sh` as PreToolUse but not pre-commit).
- SKILL.md / command file line-cap enforcement (budget-check.sh from CodingVault level, verify it actually fires for kernel-claude commits).

The our4cuts hook is the gold-standard example: it lists exempt paths explicitly, uses `is_exempt()` helper, reports violation count with rule reference. Use this structure for kernel's new pre-commit gate.

---

## 9. our4cuts — save.sh (user-facing git automation)

**What:** `scripts/save.sh` — one command (`npm run save "feat(scope): description"`). Does: stage all → block placeholder messages (saves/wip/update/etc.) → commit → pull with rebase+autostash → push. On any failure (commit blocked by pre-commit hook, rebase conflict), prints plain-English recovery steps. Built for non-technical collaborators.

**Kernel-claude status:** no equivalent. Aria uses git directly. session-end.sh automates the _meta/ batch commit but not feature commits.

**RECONCILE — not a promote.** Kernel-claude is a plugin used by agents, not non-technical collaborators. The save.sh pattern is appropriate for our4cuts (joo/aria pair, shared repo). Kernel's W6 workflow covers the same ground for agent-driven commits. However: the banned-message list (`save|wip|update|fix|test|misc|changes|stuff`) and the conventional-commit format enforcement are worth mirroring in kernel's git hook (currently only I0.4/I0.6 are enforced; there's no gate on message quality at commit time).

---

## 10. poetrytracker — Migration Pattern (idempotent PRAGMA-gated ALTERs)

**What:** `src/server/db/migrations.ts` — all ALTER TABLE statements are gated by `hasColumn(db, table, column)` which runs `PRAGMA table_info(table)`. Every migration is idempotent. Indexes use `CREATE INDEX IF NOT EXISTS`. The migration test (`tests/db/migrations.test.ts`) builds a realistic legacy DB (original v1 schema, no migrated columns) and asserts the full migration chain applies cleanly — specifically guarding against the production incident where schema.sql created indexes on columns that migrations hadn't added yet, crashing all reads on existing DBs.

**Kernel-claude status (CONFIRMED BUG from shared recon):** migrations 005, 008, 009 exist on disk but are NOT in `_migrations` table on the live DB. `execution_traces` table (from 005) is MISSING. `errors.domain` column (from 008) is MISSING. Migration loop only runs inside `cmd_init` (new DB only); `cmd_preflight` warns but never applies.

**PROMOTE — Tier 2 — HIGH PRIORITY.** This is an active bug, not a pattern gap.

Poetrytracker's pattern is the fix model:
1. Change kernel's migration runner to run migrations on EVERY startup (not just new DB), gated by the `_migrations` table marker.
2. Wrap every `ALTER TABLE` in a `hasColumn`-equivalent guard (in bash: `sqlite3 "$DB" "PRAGMA table_info(table)" | grep -q column_name`).
3. Add a migration test that builds a pre-005 legacy DB and verifies the full chain applies without error.

Concretely: `cmd_preflight` Check 4 needs to change from WARN to APPLY. The loop already exists in `cmd_init` — extract it to a `run_pending_migrations` function callable from both.

---

## 11. augur — launchd daemon pattern (caffeinate + scheduled Python modules)

**What:** augur uses macOS launchd (`com.aria.augur-caffeinate`, `-tick`, `-watchdog`, `-resolve`, `-experiments`) + a runner wrapper (`augur-runner.sh`) that: sources venv, loads `.env` silently (never echoes), dispatches to subcommand, logs stdout/stderr per-command to `_meta/logs/`. Install script (`install-launchd.sh`) is idempotent (unload-then-load). Caffeinate plist prevents sleep gaps during autonomous runs.

**Kernel-claude status:** no equivalent daemon/scheduler. Augur is explicitly for ops automation that runs between sessions. The caffeinate pattern specifically prevents the "session went to sleep mid-forge" failure mode.

**PROMOTE — Tier 2, but only if kernel adds autonomous loop features.** Immediate value: document the caffeinate plist as a reference in `_meta/reference/` for users running `/kernel:forge` overnight. The runner pattern (venv + .env + per-command logs) is a good template for any kernel subcommand that spawns as a launchd job. Non-disruptive to current plugin users.

---

## 12. kernel_systems (aDNA) — Template/Working-Project Detection on Startup

**What:** CLAUDE.md detects on every startup whether the repo is the base template (`role: template` in MANIFEST.md) or a working project. Template → offer fork/project creation, don't run normal workflow. Working project → check for first-run state and invoke onboarding skill if needed. Uses `last_edited_by: agent_aria` as a "never customized" signal.

**Kernel-claude status:** kernel detects session context (profile: local/github/etc.) on startup but has no concept of "is this a fresh install vs a working install." Fresh installs hit `agentdb read-start` and get nothing — no guided setup.

**PROMOTE — Tier 2.** Add a `cmd_init` detection path to session-start.sh: if `_meta/agentdb/agent.db` doesn't exist (fresh install), output a guided setup message pointing to the init workflow rather than silently failing. The aDNA `role: template` pattern is overkill for kernel, but the first-run detection and guided onboarding output is directly applicable.

---

## 13. kernel-cursor — Cursor Port Divergence

**What:** kernel-cursor is a Cursor IDE port of kernel-claude. It has `.cursor/commands/` (validate, ship, iterate, tearitapart, build, handoff) mapping to kernel's slash commands, and `kernel/hooks/` with markdown-defined behavioral hooks (pattern-capture.md, post-write.md, pre-complete.md) that are documentation-style, not executable scripts. The `_meta/_learnings.md` is append-only structured log (no DB), and `kernel/state.md` has explicit slot caps to prevent bloat.

**RECONCILE — ongoing drift, not a promote.** The cursor port was last validated 2026-01-10. Kernel-claude has since added: `execution_traces` (migration 005), `errors.domain` (migration 008), visibility/sensitivity learnings columns (migration 009), the full W9 parallel review workflow, I0.13/I0.14/I0.15 invariants, and the budget-check gates. None of these exist in kernel-cursor. 

Reconcile strategy: establish a "cursor port update" step in the kernel release process. When kernel-claude's CHANGELOG gets a new invariant or workflow, open a tracking note in kernel-cursor. Not urgent unless Aria uses kernel-cursor actively — check usage before investing.

The slot-cap convention from `kernel/state.md` ("`max 15 lines`", "`max 10 bullets`") is worth backporting to kernel-claude's session state files to prevent context bloat.

---

## Summary — Priority Order

| # | Finding | Source | Action | Tier |
|---|---------|--------|--------|------|
| 1 | Migration runner applies pending migrations at startup | poetrytracker | FIX — active bug | 2 |
| 2 | Stale contract detection in session-start | modelmind | PROMOTE | 1 |
| 3 | Ambient learnings surface on PostToolUse(Write) | modelmind | PROMOTE | 1 |
| 4 | Session-end domain validator pass | modelmind | PROMOTE | 1 |
| 5 | Domain-learning surface in post-compact restore | modelmind | PROMOTE | 2 |
| 6 | warn-hardcoded: add font-family check + path restriction | modelmind | RECONCILE | 1 |
| 7 | Pre-commit hook for I0.4 (no AI attribution) enforcement | our4cuts pattern | PROMOTE | 2 |
| 8 | First-run detection + guided setup in session-start | kernel_systems | PROMOTE | 2 |
| 9 | Slot-cap convention in session state files | kernel-cursor | RECONCILE | 1 |
| 10 | Cursor port sync — I0.13/14/15, W9, migration 005/008/009 | kernel-cursor | RECONCILE | 2 |
| 11 | Block-retired-flow pattern (friendly redirect hooks) | modelmind | PROMOTE as pattern | 1 |
| 12 | launchd caffeinate reference for overnight forges | augur | DOCUMENT | 1 |

---

## Non-disruption notes

All promotions are additive (new hooks, extended scripts). Tier 1 changes touch 1-2 files. Tier 2 changes touch 3-5 files and should go through the contract → surgeon → adversary flow. The migration fix (item 1) is the highest risk: it changes cmd_preflight behavior from WARN to APPLY — test on a copy of the live DB before shipping.
