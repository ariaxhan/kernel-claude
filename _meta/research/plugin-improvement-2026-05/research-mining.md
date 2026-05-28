---
name: plugin-improvement-research-mining-2026-05
description: Concrete, implementable plugin improvements surfaced by recent research and cross-project mining — ranked by leverage, not yet shipped.
type: reference
date: 2026-05-28
sources:
  - _meta/research/modelmind-mining-2026-05.md
  - _meta/research/dreams-synthesis-2026-05.md
  - _meta/research/cross-project-mining-2026-05.md
  - _meta/research/posttoolusefailure-schema.md
  - _meta/research/claude-techniques-april-2026.md
  - _meta/research/plugin-gap-verdicts-2026-04.md
  - agentdb learnings (top 40 by hit_count)
---

# Plugin Improvement — Research Mining 2026-05

Synthesized from 6 research documents + top-40 agentdb learnings. Each item: what, why (cited), tier, disruption risk.

---

## Rank 1 — Cost visibility (zero observability is a liability)

**What:** Install claudetop/ccusage as companion, OR add a lightweight cost tracker to the SessionEnd hook logging token counts + estimated cost to `_meta/logs/costs.jsonl`. Add burn-rate alerts for autonomous `/kernel:forge` loops.

**Why:** Plugin-gap H073 CONFIRMED. Kernel has zero financial observability. `_meta/logs/costs.jsonl` is referenced in NEXUS config but never implemented. AgentDB learnings confirm: "$0.40-0.60/query × stuck retries = silent invoice shock." A user discovered a $65 bill expected to be $10 after the fact (claudetop origin story). Autonomous forge loops are the highest risk surface.

**Tier:** 1 (SessionEnd hook addition) or install (claudetop alongside)

**Disruption:** Zero. Additive.

---

## Rank 2 — Compact at 60% context fill, not at limit

**What:** Lower the precompact hook threshold from ~80-90% to 60-70% fill. Reframe the trigger in `skills/context-mgmt/SKILL.md` from "token count" to "reasoning fidelity" — the real signal is hypothesis depth and step count, not token quantity.

**Why:** Three independent sources confirm this: `dreams/autonomous-dev-anti-patterns.md` (HF Daily Papers research, fidelity shallows at 60-70% with no visible signal), `cross-project-mining-2026-05.md` (3+ projects cross-cut), `claude-techniques-april-2026.md` Part 3 (Claude 4.6+ models self-aware of budget). The agent appears to work normally but produces shallower outputs — the "Token Snowball" anti-pattern. Current hooks fire too late, after damage has occurred.

**Tier:** 1 (hook threshold change + SKILL.md edit)

**Disruption:** Low. More frequent compactions; may interrupt some sessions earlier. Worth it.

---

## Rank 3 — PostToolUse code vulnerability scanning

**What:** Add PostToolUse hook scanning Write/Edit output for: `eval()`, `innerHTML`/`document.write`, `exec`/`os.system`, `pickle`, dangerous SQL string concatenation. ~30 lines bash. Complements existing `detect-secrets.sh` (which catches credentials, not code patterns).

**Why:** Plugin-gap H070 confirmed gap (timing: security-guidance warns at write-time; kernel catches at review-time). `cross-project-mining-2026-05.md` confirms the pattern cross-cuts 3 projects. `posttoolusefailure-schema.md` confirms the hook schema — PostToolUse gets `tool_name`, `tool_input`, `error` on stdin. The canonical field is `.error` not `.tool` (current `capture-error.sh` has the wrong field name as a bug). AgentDB top failure: "Prompt injection is OWASP LLM#1 for 2025. 73% of production deployments vulnerable."

**Tier:** 1 (new hook ~30L bash)

**Disruption:** Zero. Additive. Warn-only recommended for first version.

**Bug fix bundled:** `hooks/scripts/capture-error.sh` uses `.tool` but the official schema is `.tool_name`. Fix alongside.

---

## Rank 4 — kernel:research skill (Research-Failures-First with empirically ranked channels)

**What:** New `skills/research/SKILL.md` implementing the Research-Failures-First protocol with empirically ranked channels: GitHub issues (47% unique finding rate) + production case studies (78%) run in parallel. Anti-pattern web search explicitly dropped (15% unique rate, dud). Minimum 10 failure-mode entries enforced. Failure-mode map template with frontmatter. Gates implementation until map exists.

**Why:** `modelmind-mining-2026-05.md` — experiment H-RFF-001 ran 4 parallel agents on identical topics, each constrained to one source channel. Results: GitHub issues 47%, production case studies 78%, anti-pattern web 15% (dropped), forums 29% (optional). This protocol was invented from scratch per-project (modelmind, funjoin) every time — should be a canonical kernel skill. Also: "No implementation begins until the failure-mode map exists" is already in NEXUS but has no supporting skill infrastructure.

**Tier:** 2 (new skill file + update ingest command to reference it)

**Disruption:** Low. Adds a pre-implementation gate that may feel slow but is the correct forcing function.

---

## Rank 5 — COMMIT BEFORE MOVE PreToolUse hook

**What:** PreToolUse hook on Bash: when command contains `mv` or `rm`, check `git status` for untracked files in the affected path. Warn and optionally block. Add rule to `skills/git/SKILL.md`.

**Why:** `cross-project-mining-2026-05.md` — funjoin lost 11 files to `mv` on untracked state. `distillations/threads/security.md` classified `git stash` as a data loss attack vector. `modelmind-mining-2026-05.md` — three commits ate a parallel window's work when session-end swept staged changes. I0.1 ("Commit before move: never mv/rm in _meta/ without committing first") exists as a CLAUDE.md invariant but is honor-system only. I0.15 says: "Critical safety is enforced by external hooks, not by agent honor-system instructions." This is I0.15's most unimplemented case.

**Tier:** 1 (hook + SKILL.md edit)

**Disruption:** Low. Warn-only by default; block configurable.

---

## Rank 6 — Prompt-triggered context injection hook (userpromptsubmit-router)

**What:** UserPromptSubmit hook reads a `routes.json` config, matches against the live prompt, and injects up to 3 context hints — highest-leverage reference snippets, agent memory, or skill summaries. No vector DB needed. Token-efficient RAG approximation.

**Why:** `cross-project-mining-2026-05.md` — funjoin invented this locally; identified as "most novel hook pattern in vault." Addresses the "pre-load over ask" philosophy in CLAUDE.md: "Mine history upfront, inject context before work starts — don't discover at runtime." Kernel has SessionStart and PostToolUse hooks but no prompt-submit scanner. Reference implementation: `funjoin/.claude/hooks/userpromptsubmit-router.sh`.

**Tier:** 2 (new hook + routes.json config format + docs)

**Disruption:** Zero. Additive. routes.json is user-configured, defaults to empty.

---

## Rank 7 — AgentRx 4-type failure taxonomy in coroner + agentdb schema

**What:** Add `failure_type` enum (Action/Reasoning/Tool/State) to `errors` table in agentdb schema. Update `agents/coroner.md` to classify failures by type on each post-mortem. Enables: "what failure type is most common this month?" as a queryable metric.

**Why:** `dreams/autonomous-dev-anti-patterns.md` — Microsoft Research AgentRx study, 115 annotated trajectories. Each type has a distinct mitigation: Action failures → more tool constraints; Reasoning failures → higher effort / more thinking; Tool failures → schema fixes / better tool selection; State failures → checkpoint more often. `modelmind-mining-2026-05.md` confirms: "No failure taxonomy for classifying agent failures in agentdb — worked around with free-text." Free-text is unqueryable and can't surface patterns. AgentDB top learnings confirm repeated failure patterns that could be classified this way.

**Tier:** 2 (migration + coroner agent update)

**Disruption:** Low. Schema additive (nullable column). Existing data unaffected.

---

## Rank 8 — Blind evaluator agent (structural, not procedural, separation)

**What:** New `agents/blind-evaluator.md` — receives only problem + rubric, never the solution. Structurally isolated: separate context, no access to original agent output. Scores 0-10 with confidence. Blocks merge below 0.80. Required for any user-facing or high-stakes eval per `anti_patterns` rule: "Spawn blind-evaluator for any user-facing or high-stakes eval. Self-scoring inflates ~36% structurally."

**Why:** `dreams/evaluation-architecture.md` + `agent-evaluation-infrastructure.md` — FJ-5147: self=10, blind=5 on same output. 36% systematic inflation. `cross-project-mining-2026-05.md` — funjoin CMP-001/002 confirmed the gap. The anti_patterns block `self_score_high_stakes_eval` already exists in CLAUDE.md but the agent to fulfill it doesn't. The `anti_pattern` promises a tool that doesn't exist yet.

**Tier:** 2 (new agent file + eval SKILL.md update)

**Disruption:** Low. Only fires when explicitly spawned or when high-stakes eval is detected.

---

## Rank 9 — Plugin registration CI gate

**What:** Pre-commit script that checks every `.md` in `skills/` and `commands/` against `plugin.json` entries. Skill file without a registered entry → block commit. Covers the inverse too: plugin.json entry pointing to missing file.

**Why:** `cross-project-mining-2026-05.md` — kernel-claude v7.12.1→7.12.2 fix was triggered by `plugin.json` missing the landing-page skill — silent failure, invisible to users. `distillations/tooling 2026-04-20`: "broken registration = invisible feature." This class of error is undetectable without a gate.

**Tier:** 1 (~20L bash, wired via hooks or tests/run-tests.sh)

**Disruption:** Zero. Will catch future mistakes, not break existing registrations.

---

## Rank 10 — Effort parameter + literal scope guidance in agent contracts and skills

**What:** Update `skills/orchestration/SKILL.md` and the surgeon agent contract template with: (1) `effort: xhigh` for production code generation, `high` for intelligence-sensitive tasks; (2) explicit scope syntax: "Apply to X, Y, AND Z" not "Apply this pattern"; (3) "report all, filter downstream" for code review harnesses (Opus 4.7 literal interpretation suppresses findings if prompt says "be conservative").

**Why:** `claude-techniques-april-2026.md` — Opus 4.7 interprets instructions literally and explicitly. Old generalization patterns fail. Effort parameter replaces manual `budget_tokens`. Code review harness tuning: "report only high-severity issues" with Opus 4.7 = suppressed findings. Also: Opus 4.7 uses tools LESS than 4.6; raise effort to restore tool usage in agentic contexts.

**Tier:** 1 (SKILL.md edits + agent template updates)

**Disruption:** Zero. Instructions are additive.

---

## Rank 11 — Session-end hook: multi-window guard

**What:** Session-end hook should check for multiple active sessions sharing a working tree (`git status` + session ID comparison) and refuse to auto-commit until user confirms. Add warning to `kernel:handoff` SKILL.md: "Commit your work before generating this handoff. Staged-but-uncommitted files will be swept if another window fires session-end."

**Why:** `modelmind-mining-2026-05.md` — three commits ate a parallel window's staged work because both windows shared a working tree and the same `_meta/.session_id`. Evidence: commits `2485ab0`, `106de14`, `e924791`. The session-end hook carve-out (intentional `--no-verify`) makes this harder to fix but not impossible — the guard belongs inside session-end.sh itself.

**Tier:** 2 (hook logic + session ID tracking)

**Disruption:** Medium. Changes session-end behavior for multi-window users. Safe default: warn, not block.

---

## Rank 12 — AgentDB persistence health check at SessionStart

**What:** SessionStart hook: verify DB is writable + last N learnings queryable. Emit WARNING if learnings count dropped (indicates WAL/SHM wipe). Log to `_meta/logs/agentdb-health.jsonl`.

**Why:** `cross-project-mining-2026-05.md` — "AgentDB persistence is non-trivial and fails silently" cross-cuts 3 projects (kernel-claude, funjoin 13 learnings volatile, adna formalized as knowledge primitive). Silent WAL wipe means sessions proceed without realizing prior learnings are gone — maximum damage, zero signal.

**Tier:** 1 (SessionStart hook addition ~20L)

**Disruption:** Zero. Read-only check.

---

## Rank 13 — Spec-completeness gate in kernel:tearitapart

**What:** Add a "spec completeness" verdict to `/kernel:tearitapart` before the PROCEED/REVISE/RETHINK verdict. Gate: "Could an agent execute this spec with zero follow-up questions?" If no: REVISE with specific gaps listed. Template: exact code snippets, exact config, exact SQL — not goals.

**Why:** `modelmind-mining-2026-05.md` — H002/H003 promoted (confidence 0.95): "Specification prompts with exact code achieve 100% success across all scopes (1-10 files). 20 experiments, avg quality 9.4/10." `dreams/one-shot-implementation-methodology.md` Pattern 2. `dreams-synthesis-2026-05.md` — "Teardown-as-specification-gate: block implementation until teardown finds zero 'agent will guess' gaps." The 4b spec-completeness gate was recently added to ingest but tearitapart still lacks it.

**Tier:** 1 (tearitapart command update)

**Disruption:** Zero. Adds a phase before the existing verdict.

---

## Rank 14 — Phase A / Phase B split for risky requirements in kernel:forge

**What:** Add to forge ANNEAL template: "If a requirement has a high-risk subcomponent (native dep, store submission gate, device-only verifiable), split into phase A (safe, ships) + phase B (deferred pending verification). Phase A ships a no-op skeleton." Add file-read verification step as mandatory gate before marking DONE: read actual output file, not agent summary.

**Why:** `modelmind-mining-2026-05.md` — pattern used twice in one forge session (R-007, R-003). Standing failure: "Surgeon agent claimed drag-and-drop was implemented but only added type definitions. Actual GestureDetector/Pan gesture code was never written." (top agentdb failure by recurrence). "Never trust an agent summary — always read the actual output file" repeated across two retrospectives.

**Tier:** 1 (forge command template edit)

**Disruption:** Zero. Template guidance only.

---

## Rank 15 — AgentDB entity-relation layer + FTS5

**What:** Extend AgentDB with entity and relation tables (entity_name, entity_type, relation_type, source, target). Add FTS5 for full-text search across learnings and entities. `002_graph_tracking` migration already exists — this is completion, not new design.

**Why:** Plugin-gap H075 CONFIRMED. "AgentDB stores operational data (what happened); knowledge graphs store conceptual relationships (how entity A relates to B across sessions)." The 002_graph_tracking migration already exists in `orchestration/agentdb/migrations/` — infrastructure was pre-wired. FTS5 + structured relations cover 80% of semantic search value without vector embeddings. Per agentdb learnings: "Hallucinations most dangerous in agentic context. 15-25% error rate with 50+ tools. Semantic filtering reduces errors 86.4%."

**Tier:** 3 (migration + FTS5 + inject-context update)

**Disruption:** Low. Schema additive. FTS5 is SQLite built-in.

---

## Rank 16 — MCP ops checklist + quarterly audit ritual

**What:** New `_meta/reference/mcp-ops-checklist.md` covering: SSE transport deprecated → verify `"type": "http"`; MAX_MCP_OUTPUT_TOKENS per server; deferred loading mandatory if >50 tools; audit `npx -y` postinstall scripts. Add quarterly audit cron or checklist to `kernel:retrospective`.

**Why:** `dreams/mcp-infrastructure.md` (graduated 2026-04-16) — "Treating MCP setup as one-time config event is an anti-pattern; operational overhead compounds invisibly." `cross-project-mining-2026-05.md` confirms. Plugin currently has no MCP operational guidance. The vault runs >100 tools across connected MCP servers — deferred loading is already mandatory per system-reminder but undocumented as an audit item.

**Tier:** 1 (reference doc + retrospective command addition)

**Disruption:** Zero. Documentation only.

---

## Summary table (leverage-ranked)

| Rank | What | Tier | Disruption | Primary source |
|------|------|------|------------|----------------|
| 1 | Cost visibility (SessionEnd hook + claudetop) | 1 | None | H073, agentdb learnings |
| 2 | Compact at 60% fill, not limit | 1 | Low | dreams, cross-project, claude-techniques |
| 3 | PostToolUse code vulnerability scanning | 1 | None | H070, cross-project, posttoolusefailure-schema |
| 4 | kernel:research skill (RFF protocol) | 2 | Low | modelmind, cross-project |
| 5 | COMMIT BEFORE MOVE PreToolUse hook | 1 | Low | cross-project, I0.15 |
| 6 | userpromptsubmit-router hook | 2 | None | cross-project (funjoin) |
| 7 | AgentRx 4-type failure taxonomy | 2 | Low | dreams, modelmind, agentdb |
| 8 | Blind evaluator agent | 2 | Low | dreams, cross-project |
| 9 | Plugin registration CI gate | 1 | None | cross-project (v7.12.1 regression) |
| 10 | Effort param + literal scope in contracts | 1 | None | claude-techniques-april-2026 |
| 11 | Session-end multi-window guard | 2 | Medium | modelmind |
| 12 | AgentDB persistence health check | 1 | None | cross-project |
| 13 | Spec-completeness gate in tearitapart | 1 | None | modelmind, dreams |
| 14 | Phase A/B split + file-read verify in forge | 1 | None | modelmind, agentdb |
| 15 | AgentDB entity-relation + FTS5 | 3 | Low | H075, agentdb |
| 16 | MCP ops checklist + quarterly audit | 1 | None | dreams, cross-project |

---

## Bundled bug fixes (ship with nearest related item)

- `hooks/scripts/capture-error.sh` line 14: uses `.tool` but official PostToolUseFailure schema is `.tool_name`. Fix with Rank 3 (PostToolUse scanning).
- `hooks/scripts/guard-bash.sh`: regex `.*(-f|--force)` matches `-f` in branch names like `fix/` and `fallback/` — blocks legitimate pushes. Fix standalone (Tier 1, ~2L change). (Source: agentdb top failures.)
- Migration 005 (`execution_traces` table) and 008 (`errors.domain` column) are on disk but not applied to live DB — confirmed by orchestrator recon. Fix: `cmd_preflight` Check 4 should apply pending migrations, not just warn.

---

## Not yet adoptable (needs more evidence or is external-install only)

- **Devcontainer delivery** (DEVCONTAINER-DELIVERY.md) — dreams-synthesis-2026-05.md proposes but no vault project has shipped this pattern for kernel itself.
- **Claude Managed Agents** — cross-project-mining notes SDK → Managed Agents decision tree; not yet relevant to kernel's own architecture (CLI tool, not production backend).
- **Fastlane / EAS exit arc** — modelmind-specific; not applicable to kernel-claude.
- **plugin-dev validation utilities** — H076: recommend installing alongside, not absorbing.
