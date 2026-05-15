# kernel-claude state audit — 2026-05-14

## TL;DR

1. **9 of 19 skills are stale** (not touched since 2026-04-01): `app-dev`, `architecture`, `backend`, `context-mgmt`, `design`, `e2e`, `eval`, `performance`, `tdd`. (11 if including `orchestration` and `quality`.)
2. **All 14 agents and all 3 workflows last touched before 2026-04-01** (most on 2026-03-31). Entire agent roster technically stale.
3. **NEXUS layer (parent CLAUDE.md) has evolved past kernel-claude** on three critical fronts: (a) `research-failures-first` protocol with `deep-diver` agent detailed in NEXUS but absent here; (b) `kernel:ship` skill referenced in NEXUS ambient routing doesn't exist; (c) 15 hard invariants (I0.1–I0.15) in CodingVault layer have no equivalent here.
4. **`session-end.sh` and `pre-compact-commit.sh` both use `--no-verify`** — intentional for loop prevention but contradicts CodingVault I0.5 ("Never `--no-verify`"). Undocumented exception.
5. **9 of 19 SKILL.md files exceed NEXUS 80-line cap** by 2.5x–4x. `_learnings.md` last updated 2026-03-04 (v6.0.0). ~22 version increments unlogged.

---

## Skills inventory

| name | mtime | lines | purpose | status |
|---|---|---|---|---|
| api | 2026-04-27 | 325 | REST API design: resource naming, status codes, cursor pagination, versioning | current |
| app-dev | 2026-03-31 | 127 | Mobile/web build pipeline, EAS, store submission | STALE |
| architecture | 2026-03-04 | 58 | System architecture, modular design, dependency management | STALE |
| backend | 2026-03-08 | 297 | Repository pattern, service layer, N+1, cache-aside | STALE |
| build | 2026-05-12 | 337 | Solution exploration: 2-3 approaches, simplest, never first | current |
| context-mgmt | 2026-03-13 | 112 | Context engineering, progressive disclosure, AgentDB offloading | STALE |
| debug | 2026-05-14 | 241 | Systematic debugging: Zeller scientific method, binary search | current |
| design | 2026-03-04 | 113 | Anti-convergence frontend aesthetics, mood variants | STALE |
| e2e | 2026-03-08 | 206 | Playwright, Page Object Model, flaky test strategies | STALE |
| eval | 2026-03-08 | 136 | EDD, pass@k metrics, capability evals | STALE |
| experiment | 2026-04-06 | 253 | Scientific method for rules: seed, test, graduate, kill | current |
| git | 2026-05-14 | 160 | Atomic commits, conventional messages, branch strategies | current |
| orchestration | 2026-03-31 | 247 | Multi-agent coordination, contracts, fault tolerance, worktrees | STALE |
| performance | 2026-03-04 | 63 | Measure before optimizing, bottleneck identification | STALE |
| quality | 2026-03-31 | 121 | Big 5: input validation, edge cases, error handling, dup, complexity | STALE |
| refactor | 2026-05-06 | 131 | Behavior-preserving transformations, tests green before/after | current |
| security | 2026-05-12 | 322 | Zod, SQL injection, XSS, CSRF, rate limiting, OWASP top 10 | current |
| tdd | 2026-03-08 | 128 | TDD red-green-refactor, Supabase/Redis/OpenAI mocks | STALE |
| testing | 2026-05-14 | 234 | Edge cases over happy paths, regression tests | current |

Stale by 4-week rule: 11 of 19. Skills exceeding NEXUS 80-line cap: 9 of 19.

---

## Agents inventory

| name | mtime | lines | role | status |
|---|---|---|---|---|
| adversary | 2026-04-07 | 120 | Skeptical QA — assumes broken until proven; PASS/FAIL to AgentDB | current |
| analyzer | 2026-03-31 | 133 | Cross-task intelligence: dependency, systemic patterns, priority | STALE |
| approval-learner | 2026-03-31 | 107 | Pattern observer: extracts rules from human review decisions | STALE |
| cartographer | 2026-03-31 | 112 | Whole-codebase mapper using 1M context | STALE |
| coroner | 2026-03-31 | 122 | Post-mortem analyst for failed contracts | STALE |
| dreamer | 2026-03-31 | 76 | Multi-perspective debate: minimalist/maximalist/pragmatist | STALE |
| pre-ship | 2026-03-31 | 162 | Composite release gate: 4 parallel validators, SHIP/NO-SHIP | STALE |
| researcher | 2026-04-01 | 180 | Pre-implementation research: existing solutions before code | STALE |
| reviewer | 2026-04-01 | 116 | Code review: actionable, APPROVE/REQUEST/COMMENT, >80% confidence | STALE |
| scout | 2026-03-31 | 193 | Codebase reconnaissance: structure, tooling, risk zones | STALE |
| surgeon | 2026-04-01 | 125 | Surgical implementer: minimal diff, contract scope only | STALE |
| triage | 2026-03-31 | 88 | Complexity classifier (Haiku): low/med/high/epic | STALE |
| understudier | 2026-03-31 | 102 | Pre-flight validator (Haiku): viability before surgeon commit | STALE |
| validator | 2026-03-31 | 222 | Pre-commit gate: 9-gate safety chain | STALE |

All except `adversary` stale by 4-week rule. Notable: `deep-diver` agent referenced in NEXUS does not exist.

---

## Commands inventory

| name | mtime | lines | purpose | status |
|---|---|---|---|---|
| diagnose | 2026-03-31 | 135 | Systematic debugging + refactor analysis | STALE |
| dream | 2026-03-31 | 186 | Creative exploration: 3 perspectives + 4-persona stress test | STALE |
| experiment | 2026-04-06 | 307 | Scientific experimentation: seed, list, test, verdict, graduate, kill | current |
| forge | 2026-04-07 | 257 | Autonomous engine: heat/hammer/quench/anneal | current |
| handoff | 2026-03-31 | 132 | Context handoff brief, writes to `_meta/handoffs/` | STALE |
| help | 2026-03-25 | 124 | Show KERNEL help with state, profile, contracts | STALE |
| ingest | 2026-04-07 | 232 | Universal entry: research → classify → scope → success → execute → learn | current |
| init | 2026-03-31 | 122 | Initialize KERNEL globally: Vaults, symlinks, CLI, database | STALE |
| landing-page | 2026-04-15 | 923 | Guided landing page generator: interview → scaffold → CF Pages | current |
| metrics | 2026-03-31 | 43 | Observability dashboard: sessions, agents, hooks, learning health | STALE |
| retrospective | 2026-03-31 | 71 | Cross-session learning synthesis | STALE |
| review | 2026-03-31 | 144 | Code review for PRs: spawns reviewer, >80% confidence | STALE |
| tearitapart | 2026-03-31 | 144 | Critical pre-implementation review: PROCEED/REVISE/RETHINK | STALE |
| validate | 2026-03-31 | 129 | Pre-commit verification: build, types, lint, tests, security | STALE |

Missing: `kernel:ship` (referenced in NEXUS ambient routing for "ship, commit, push" triggers).

---

## Hooks inventory

| hook | trigger | purpose | status |
|---|---|---|---|
| session-start.sh (347L) | SessionStart | Loads AgentDB context, outputs git state + philosophy + decision tree, detects profile | current (2026-04-07) |
| guard-bash.sh (26L) | PreToolUse: Bash | Guards dangerous patterns (rm -rf, dd) with circuit breaker | current |
| guard-config.sh (27L) | PreToolUse: Write/Edit | Protects hooks.json, CLAUDE.md, plugin.json from unreviewed changes | current |
| detect-secrets.sh (43L) | PreToolUse: Write/Edit | Blocks writes containing API keys, tokens, credentials | current |
| validate-structure.sh (41L) | PreToolUse: Write/Edit (async) | Warns on missing frontmatter / triggers | STALE (2026-03-31) |
| warn-hardcoded.sh (25L) | PreToolUse: Write/Edit (async) | Warns on hardcoded hex/px in components | STALE (2026-03-31) |
| auto-approve-safe.sh (40L) | PermissionRequest: Bash | Auto-approves safe read-only patterns | STALE (2026-03-24) |
| log-write.sh (29L) | PostToolUse: Write/Edit (async) | Logs file writes to AgentDB | STALE (2026-03-25) |
| validate-json-schema.sh (30L) | PostToolUse: Write/Edit (async) | Validates JSON/SQL after writes | STALE (2026-03-31) |
| capture-error.sh (23L) | PostToolUseFailure | Captures tool failures to AgentDB | STALE (2026-03-31) |
| post-compact-restore.sh (118L) | UserPromptSubmit | Restores methodology context after compaction | current (2026-04-07) |
| pre-compact-commit.sh (213L) | PreCompact | Saves contract + learnings + branch before compaction | current (2026-04-07) |
| session-end.sh (92L) | SessionEnd | AgentDB checkpoint, batch commits, push attempt | current (2026-04-07) |
| circuit-breaker.sh (94L) | sourced | Disables guard hook for 10 min after 3 consecutive failures | STALE |
| common.sh (223L) | sourced | Shared utilities: Vaults detection, profile, AgentDB path | current |
| github-integration.sh (342L) | sourced by session-end | Profile-gated GitHub Issues/Discussions integration | STALE |

Missing: `budget-check.sh` enforcing NEXUS 80L SKILL.md line caps (referenced in parent NEXUS but not in kernel-claude).

---

## CLAUDE.md gaps

**Missing concepts (referenced in parent layers, absent here):**

- `research-failures-first` protocol — NEXUS mandates spawning `deep-diver` to produce failure-mode map before any non-trivial implementation. Reference file `_meta/reference/research-failures-first.md` referenced by NEXUS but missing here.
- `kernel:ship` skill — NEXUS routes "ship, commit, push" to `kernel:ship` + `kernel:git`. No `kernel:ship` exists.
- `deep-diver` agent — Referenced in NEXUS as standard research agent. Not defined.
- `step-away` skill — NEXUS routes "step away, parallel forge, fan out" here. Not present.
- 15 hard invariants (I0.1–I0.15) from CodingVault — including worktree isolation (I0.14), hook-enforced safety (I0.15), anchor-drift stop (I0.13), no hallucinated APIs (I0.12), explicit agent scope contracts (I0.11). No equivalent invariant system here.
- CONFIRM handshake for T3 — NEXUS mandates one-block confirmation (what/scope/approach/pushback/opinion). Tier classification exists but no formalized handshake gate.
- Worktree session-recovery W10 (anchor recovery: stop → handoff → /clear → resume) — handoff command covers some but explicit "stop, do not one-more-try" trigger absent.
- `budget-check.sh` enforcing 80L SKILL.md cap — hook missing.

**Stale claims:**

- CLAUDE.md says "19 skills, 13 commands". Actual: 19 skills, 14 commands (landing-page added after description written).
- `_learnings.md` last entry 2026-03-04 (v6.0.0). Plugin now v7.12.2. ~22 version increments unlogged. Header says "Living log… newest at top" but nothing appended since pre-v7 era.
- CLAUDE.md `<git>` rule says "No AI attribution… Co-Authored-By, Generated with Claude Code, or tool signatures" aligns with I0.4. But `session-end.sh` uses `--no-verify` bypassing detect-secrets and guard hooks — comment says "intentional — avoids infinite hook loops" but exception undocumented in CLAUDE.md.

---

## Research gaps in plugin

All research files March–April 2026. Nothing from May. Last write: 2026-04-19.

| topic | last updated | size | gap |
|---|---|---|---|
| ai-code-anti-patterns | Mar 12 | 8.5KB | No update since pre-v7 |
| ai-landing-page-failures-2026 | Apr 10 | 27KB | Current |
| claude-best-practices-2026 | Apr 4 | 26KB | ~6 weeks old |
| claude-techniques-april-2026 | Apr 19 | 15KB | Most recent — still 3.5 weeks |
| token-budget-research | Mar 25 | 12KB | Pre-v7.x work |

**Missing research topics** (techs active across ≥2 CodingVault projects with no research file):
- expo-router v4 patterns and failure modes (modelmind)
- react-native-reanimated v4 worklet patterns (modelmind)
- budget-check.sh / NEXUS token enforcement interaction
- Cloudflare Pages deployment failures (multiple projects)
- `agentdb inject-context` role-scoped knowledge usage patterns
- PostToolUse vs PostToolUseFailure unified hook I/O reference

---

## Internal contradictions

- **`--no-verify` in hooks vs I0.5**: `session-end.sh:86` and `pre-compact-commit.sh:108` use `--no-verify`. NEXUS I0.5 says "Never". Justified but undocumented carve-out.
- **Auto-push in session-end vs I0.8**: `session-end.sh:87` attempts auto `git push` at session end. NEXUS I0.8: "Push to `main` requires explicit user say-so." If branch is `main`, session-end auto-pushes without confirmation. CodingVault notes "I0.8 manual `main` push beats NEXUS auto-push" but conflict undocumented in kernel-claude.
- **`context-mgmt` naming vs invocation**: CHANGELOG v7.0.2 renamed `context` → `context-mgmt` to avoid shadowing native `/context`. CLAUDE.md `<skills>` lists it as `kernel:context` in triggers. Frontmatter says `name: kernel:context`. Consistent within plugin but NEXUS ambient routing doesn't reference it — context-mgmt won't auto-load under NEXUS ambient ingest.
- **Tier boundaries differ between layers**: kernel-claude T2=3-5 says "create contract, spawn agents". NEXUS T2=3-5 says "write a one-paragraph plan in `_meta/plans/`, then execute" (no mandatory agent spawn). Inconsistent behavior depending on which layer wins.
- **Research mandate differs**: kernel-claude `<flow>` says `classify.familiar AND scope.tier==1 → skip research`. NEXUS says "Research — failures-first, mandatory before any non-trivial implementation" with no familiar/tier-1 exemption.
- **Skill `quality` "load before any review"**: marked `triggers="Big 5, ai code, review, validate, pre-commit"`. CLAUDE.md says "Load before any review/validate." But `tearitapart.md` and `review.md` don't load it in their `<skill_load>` blocks.

---

## Top 5 update candidates (highest leverage)

1. **Add `kernel:ship` skill** — Referenced in NEXUS ambient routing for the most common end-of-work trigger ("ship, commit, push"). Currently routes to `kernel:git` which covers commit patterns but not the release-gate sequence (validate → review → push → tag). Hot path with no dedicated handler.

2. **Add I0-style invariants to CLAUDE.md** — CodingVault layer has 15 hard invariants representing Aria's most battle-tested rules. None encoded here. Highest-leverage: I0.13 (anchor-drift stop), I0.14 (parallel agents in isolated worktrees), I0.15 (critical safety by hooks not honor-system).

3. **Write `research-failures-first.md` reference protocol** — NEXUS mandates this file at `_meta/reference/research-failures-first.md` and its `deep-diver` spawn pattern. Update ingest.md to match NEXUS failure-hunting sequence (GitHub issues open/closed → Reddit → HN → post-mortems → docs → failure-mode map format).

4. **Refresh the 11 stale skills** — Particularly: `orchestration` needs worktree isolation protocol + `agentdb inject-context` patterns from v7.9.x; `tdd` needs updates from `claude-techniques-april-2026.md`; `design` needs the 5 new mood variants (ember, arctic, void, patina, signal) added to CLAUDE.md but not SKILL.md; `context-mgmt` needs 60% fill compaction trigger.

5. **Log 6 weeks of learnings to `_learnings.md`** — File frozen at v6.0.0 (2026-03-04). CHANGELOG documents 22+ version increments of significant discoveries (GEPA traces, R-factor quality scoring, learning decay, worktree safety, budget-aware agents, approval learner, knowledge injection via `inject-context`). Each should be distilled into the learnings log. Retrospective command's value depends on this file being current.
