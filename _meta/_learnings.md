# KERNEL Plugin Learnings

tokens: ~200 | type: log | append-only

---

**Living log of insights while developing this plugin.** New learnings at top.

## Format

```markdown
## {date}
**Context:** {feature/component}
**Type:** pattern | gotcha | fix
**What:** {brief description}
**Why:** {rationale}
```

## Learnings

<!-- append new learnings here, newest at top -->

## 2026-05-14 (v7.13.0 — multi-project refresh)

**Context:** plugin update pass after 6-week lag
**Type:** pattern
**What:** Compaction must trigger at ~60% context fill, not at limit. Reasoning fidelity degrades 30-40% earlier than current pre-compact-commit.sh detects.
**Why:** HF Daily Papers research, modelmind retrospectives, dreams/autonomous-dev-anti-patterns all converge: solve rate drops 65%→21% when context architectural mental model gets evicted. The agent appears to be working normally during the degradation — no visible signal beyond output quality. Token count is the wrong metric; reasoning depth (hypothesis count, backtracking) is the real signal.

---

## 2026-05-14

**Context:** research methodology (Research-Failures-First protocol)
**Type:** pattern
**What:** Failure-mode hunting before implementation has an empirical channel taxonomy. Run Channel-A (GitHub issues, 47% unique-find rate) + Channel-D (production case studies, 78%) in parallel; never run Channel-B alone (anti-pattern web search, 15% — mostly re-derives A).
**Why:** modelmind H-RFF-001 experiment ran 4 parallel research agents constrained to one channel each. The channel ranking is reproducible. Anti-pattern web search ("X gotchas") is the most common research move and the lowest-yield one. Deliverable is one committed canonical map at `_meta/research/<topic>.md` with ≥10 unique entries.

---

## 2026-05-14

**Context:** orchestration — agent reporting
**Type:** gotcha
**What:** Never trust an agent summary. Always verify by reading the output file.
**Why:** Surgeon agent claimed drag-and-drop was implemented but only added type definitions (modelmind, 2026-03-30). Recurred twice in the same project before promoting to invariant. Now hardcoded into surgeon, adversary, and orchestration skill: orchestrator opens the deliverable file before marking a contract DONE. Receipts from subagents are pointers, not evidence.

---

## 2026-05-14

**Context:** ingest / build methodology
**Type:** pattern
**What:** Spec framing (exact code, exact config) > contract framing (goals + constraints). 0.95 confidence from 20 modelmind experiments, avg quality 9.4/10.
**Why:** Specification prompts with exact code achieve 100% success across all scopes (1-10 files). Contract prompts ("achieve X under constraint Y") leave interpretation gaps that agents fill incorrectly. The plan phase must produce execution-ready artifacts — exact code snippets, exact SQL, exact config — not goal descriptions. Test: "could a fresh agent execute this with zero follow-up questions?" If no, the spec is incomplete.

---

## 2026-05-14

**Context:** parallel agent orchestration
**Type:** gotcha
**What:** Parallel agents on shared files cause silent merge conflicts. Linters silently revert manual edits. Dirty worktree + worktrees = N-way conflicts.
**Why:** modelmind hit 7-way conflicts on 10 files when 5+ surgeons fixed the same orthogonal bugs in parallel. The zero-overlap file plan was correct for *intended* changes but every agent also fixed shared issues (lint errors, missing content) independently. Always commit/stash before spawning worktree agents. Add comments explaining WHY code is the way it is so linters/agents don't blindly revert.

---

## 2026-05-14

**Context:** orchestration — agent count
**Type:** pattern
**What:** 2-3 files per agent is the quality sweet spot. 1-file tasks: execute directly (no agent). 6-10 files: works but slower than 2-3.
**Why:** modelmind H001 promoted at 0.75 confidence after 20+ runs. File count is a better tier predictor than complexity score. Heuristic: ambiguous tier → higher tier; ambiguous file count → split into multiple 2-3-file contracts rather than one big contract.

---

## 2026-05-14

**Context:** evaluation infrastructure
**Type:** gotcha
**What:** Self-scoring inflates eval scores by ~36% structurally. 9.0/10 blind vs 14.0/10 self-scored. This is structural bias, not calibration drift.
**Why:** dreams/agent-evaluation-infrastructure documents the gap across multiple FunJoin eval runs (CMP-001/002). Procedural separation ("evaluator agent reads its own output but pretends not to") doesn't fix it. Only structural separation works: the evaluator must be a different agent that never sees the solution. Eval skill needs a blind-evaluator agent.

---

## 2026-05-14

**Context:** architecture — skills vs agents
**Type:** pattern
**What:** Skills-first 8:4:2 ratio. Skills are the primary unit of capability; agents are lean executors. If agents outnumber skills, the system is over-partitioned.
**Why:** dreams/agent-architecture-composition (Apr 23). Counter-intuitive: more agents ≠ more capability. The 8:4:2 skill:agent:command ratio is empirically validated across modelmind, FunJoin reference design, and kernel-claude itself. When tempted to add a new agent, ask first: could this be a skill on existing agents?

---

## 2026-05-14

**Context:** session-end hooks (shared working tree)
**Type:** gotcha
**What:** When multiple Claude Code windows share a working tree, one window's session-end auto-commit can sweep another window's staged-but-uncommitted work into its commit.
**Why:** modelmind 2026-05-02 lost three logical commits to this. Both windows share the same `_meta/.session_id`; whichever window fires session-end first sweeps everything. Always commit each logical chunk immediately before handing off context. Add to handoff workflow: "Commit your work before generating this handoff."

---

## 2026-05-14

**Context:** failure classification
**Type:** pattern
**What:** AgentRx 4-type failure taxonomy: Action (wrong move) / Reasoning (wrong logic) / Tool (tool failure) / State (corrupt context). Each has a distinct mitigation strategy.
**Why:** dreams/autonomous-dev-anti-patterns — Microsoft Research AgentRx, 115 annotated trajectories. Free-text failure logs prevent pattern queries ("most common failure this week"). Adding `failure_type` enum to agentdb learnings + coroner classification enables targeted prevention rather than generic post-mortems.

---

## 2026-04-19 → 2026-04-07 (v7.7–v7.12 catch-up: discoveries from interim CHANGELOG)

**Type:** pattern
**What:** Six weeks of plugin development produced features that weren't logged here:
- **GEPA execution traces** (v7.8.0): `agentdb trace` records goal/exploration/plan/action/outcome per task. Enables cause-of-death analysis with structured evidence.
- **R-factor composite quality** (v7.8.0): 6-dimension weighted score (tests + acceptance + scope + security + budget + first-try). Replaces binary pass/fail. Thresholds: 0.85 production, 0.70 good, 0.50 acceptable.
- **Learning decay** (v7.8.0): `agentdb decay` archives stale learnings (0 hits, >46 days). Natural selection — useful learnings accumulate hits, stale ones get pruned.
- **11-phase adversarial review** (v7.7.1): checkpoint → Big5 → scope → smoke → edge cases → error paths → regression → security → contract → mutation → quality. Confidence threshold 0.8.
- **9-gate safety chain** (v7.7.1): branch isolation → atomic commits → lint → types → tests → security → adversarial review → human checkpoint → post-merge monitoring.
- **Knowledge injection** (v7.7.1): `agentdb inject-context <role>` builds role-scoped slices. Surgeon gets gotchas+patterns; adversary gets failures+errors. Inject BEFORE spawn; never let agents discover context at runtime.
- **Approval learner** (v7.8.0): observes human review decisions, extracts patterns, progressively promotes rules. Confidence = validated/applied.
- **Worktree safety protocol** (v7.7.0): `constraints.files` in contract JSON; surgeon validates every diff against it; orchestrator rejects out-of-scope changes.
- **Read-utilization tracking** (v7.9.2): `read-start` bumps `hit_count`/`last_hit`. Unread gotchas are failures.
**Why:** `_learnings.md` froze at v6.0.0 (2026-03-04) while CHANGELOG advanced to v7.12.2. ~22 version increments unlogged. This catch-up entry restores continuity so retrospectives have data to synthesize.

---

## 2026-03-04 (v6.0.0)

**Context:** Version alignment
**Type:** fix
**What:** Bumped plugin and marketplace versions to 6.0.0 to match kernel CLAUDE.md.
**Why:** Single source of truth. Plugin manifest, marketplace listing, and kernel tag must stay in sync.

---

## 2026-03-03 (v5.6.0)

**Context:** Design skill creation
**Type:** pattern
**What:** Created `/design` skill with 4 aesthetic variants (abyss, spatial, verdant, substrate) to break distributional convergence in AI-generated interfaces.
**Why:** Every AI-built interface looks the same — Inter font, rounded corners, blue accent. The design skill provides distinctive aesthetics that fight homogenization.

---

## 2026-02-20 (v5.5.0)

**Context:** Command consolidation
**Type:** pattern
**What:** Consolidated /kernel:build and /kernel:contract into /kernel:ingest as universal entry point. 6 commands instead of 8.
**Why:** Too many entry points creates confusion. Single universal router that classifies → scopes → contracts → orchestrates is cleaner. Users don't need to know which command to use — ingest figures it out.

---

## 2026-02-20 (Documentation Audit)

**Context:** Cross-verification pass
**Type:** fix
**What:** Fixed version mismatches (marketplace.json), ghost references (001_init.sql, BUILD-BANK.md, /orchestrate), unprefixed commands, state.md→active.md references.
**Why:** Documentation drift causes confusion. Single source of truth requires regular audits.

---

## 2026-02-17 (v5.4.0)

**Context:** Hooks + Article alignment
**Type:** pattern
**What:** Added SessionStart and PostToolUseFailure hooks. SessionStart outputs git state + philosophy + agentdb read-start.
**Why:** Plugin CLAUDE.md isn't auto-loaded, so hooks inject philosophy at session start. Error capture is automatic via PostToolUseFailure.

---

## 2026-01-28 (v4.0.0)

**Context:** Major rewrite
**Type:** pattern
**What:** Adopted compact Unicode syntax, reduced CLAUDE.md from ~800 to ~200 tokens.
**Why:** Token efficiency. Compact syntax (Ψ/→/≠) conveys same meaning with fewer tokens.

---

*This file is append-only. When we learn, we log here.*
