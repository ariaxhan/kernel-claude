# Dreams folder synthesis for kernel-claude updates — 2026-05-14

Sourced from /Users/ariaxhan/Vaults/CodingVault/dreams/. 18 of 25 graduated docs post-date the last plugin update (Apr 7, 2026).

## Source files read (with mtime, all HIGH priority)
- agent-architecture-composition.md (Apr 23)
- agent-evaluation-infrastructure.md (Apr 11)
- evaluation-architecture.md (Apr 20)
- multi-ai-config-transpilation.md (Apr 20)
- mcp-infrastructure.md (Apr 16)
- agent-sdk-deployment-patterns.md (Mar 31)
- one-shot-implementation-methodology.md (Mar 27)
- intelligence-automation-and-quiescence.md (Mar 27)
- agent-control-plane.md (Feb 8)
- enforcement-architecture.md (Feb 3)
- command-protocol-architecture.md (Feb 8)
- multi-agent-coordination.md (Feb 16)
- qa-orchestration-patterns.md (Feb 18)
- progressive-on-demand-systems.md (Feb 1)
- autonomous-dev-anti-patterns.md (Apr 4)
- ai-infrastructure-integrity.md (Apr 5)
- production-llm-operations.md (Apr 5)
- _sparks.md (Apr 29)

---

## Validated patterns the plugin should adopt

| Pattern | Source | Proposed home |
|---|---|---|
| Skills-first 8:4:2 ratio (skills are primary unit; if agents outnumber skills, over-partitioned) | agent-architecture-composition | CLAUDE.md philosophy + orchestration skill |
| CLAUDE.md as behavioral router (under ~200 tokens; skills carry depth; extract if >500) | agent-architecture-composition, multi-ai-config-transpilation | CLAUDE.md + anti_patterns rule |
| Task-property-conditional parallelism (verify independence + duration > spawn overhead BEFORE multi-agent) | agent-architecture-composition | orchestration SKILL.md |
| Devcontainer delivery (Docker + keychain secrets-bridge + skills + CLAUDE.md = reproducible agent env) | agent-architecture-composition | new docs/DEVCONTAINER-DELIVERY.md |
| MAS coordination overhead threshold (ask "do tasks share state?" + "task longer than spawn overhead?" before N agents) | agent-architecture-composition | orchestration SKILL.md |
| Skills and evals designed simultaneously (skills first, evals second, code third) | evaluation-architecture | eval SKILL.md + ingest command |
| Blind evaluator agent (separate, never exposed to solution; structural not procedural separation) | evaluation-architecture, agent-evaluation-infrastructure | new agents/blind-evaluator.md + eval SKILL.md |
| Two-phase eval protocol (Run 1 = intentional failure cold-scored; Run 2 = optimization from failure) | evaluation-architecture | eval SKILL.md |
| Programmatic verifiers over LLM-as-judge (deterministic where possible; LLM only for non-deterministic) | agent-evaluation-infrastructure | eval SKILL.md |
| AgentDB decontamination protocol (Taxonomy: keep/generalize/delete; periodic, not one-time) | agent-evaluation-infrastructure | agentdb docs |
| Train/test split discipline (agent context = training; golden dataset = test; formalize in SPLIT.md) | agent-evaluation-infrastructure | new eval skill section |
| Reasoning fidelity degrades at 60-70% context fill, not at limit (compact triggers at ~60%) | autonomous-dev-anti-patterns, ai-infrastructure-integrity | context-mgmt SKILL.md |
| Verification architecture > generation quality (catch rate matters more than patch brilliance) | autonomous-dev-anti-patterns | quality SKILL.md + forge command |
| Minimal diff over full rewrite (constrained output is safer + more verifiable) | autonomous-dev-anti-patterns | build SKILL.md + surgeon agent |
| AgentRx 4-type failure taxonomy (Action/Reasoning/Tool/State) with distinct fix strategies | autonomous-dev-anti-patterns | coroner agent + agentdb schema |
| `max_budget_usd` as mandatory invariant, not optional (circuit breaker for per-call billing) | mcp-infrastructure, _sparks | orchestration SKILL.md + CLAUDE.md |
| MCP deferred loading mandatory at >50 tools (full schema = context exhausted before work) | mcp-infrastructure | orchestration SKILL.md |
| MCP quarterly audit checklist (transport, auth, token limits, tool count, annotations) | mcp-infrastructure | new docs/MCP-OPERATIONS.md |
| Config hierarchy: CLAUDE.md > rules/ > reference/ (critical rules must be top-level) | command-protocol-architecture, git-as-coordination-infrastructure | CLAUDE.md + rules/kernel.md |
| Explicit INIT Phase 0 as bootstrap gate (check prerequisites before any irreversible work) | _sparks (Apr 19) | TEMPLATE.md + skills |
| In-place detection as idempotent skill entry gate (Phase 0 detects if already initialized) | _sparks (Apr 23) | TEMPLATE.md + init command |
| Compaction at 60% fill (before damage), not 95% (after) — reasoning quality not token count | ai-infrastructure-integrity | context-mgmt SKILL.md |
| inject-context pipeline (orchestrator injects BEFORE spawn; never let agents discover at runtime) | agent-control-plane | orchestration SKILL.md |
| Verification loop = highest-ROI agent action (3-5x quality multiplier per Claude best practices 2026) | _sparks (Apr 6) | forge + validate commands |
| Systematically explore bounded space (3 hops from symptom) > open-ended "find the bug" | evaluation-architecture | diagnose command |

---

## Anti-patterns the plugin should explicitly warn against

| Anti-pattern | Source | Plugin location |
|---|---|---|
| Self-scoring evals (5-point structural inflation; FJ-5147: self=10, blind=5) | evaluation-architecture, agent-evaluation-infrastructure | eval SKILL.md anti_patterns |
| Post-merge evaluation (answer key in codebase; agents reading solution during cold eval) | agent-evaluation-infrastructure | eval SKILL.md anti_patterns |
| Greenfield tickets in golden dataset (scores collapse: self=10, blind=3) | agent-evaluation-infrastructure | eval SKILL.md anti_patterns |
| Optimizing context breadth before establishing baseline (can't distinguish signal from noise) | agent-evaluation-infrastructure | eval SKILL.md anti_patterns |
| Treating MCP setup as one-time config event (operational overhead compounds invisibly) | mcp-infrastructure | new MCP-OPERATIONS.md |
| Mixing permission layers (allowedTools + disallowedTools + permissionMode + hooks) — undefined behavior | agent-sdk-deployment-patterns | CLAUDE.md anti_patterns |
| Session persistence default in SDK (30-day persistence = data leak in multi-tenant) | agent-sdk-deployment-patterns | docs/DEVCONTAINER-DELIVERY.md |
| Embedding all workflow instructions in CLAUDE.md (balloons context; skills can't be versioned) | agent-architecture-composition | CLAUDE.md + anti_patterns |
| Code → evals → skills sequence (evals pass trivially; calibrated to implementation, not intent) | evaluation-architecture | eval SKILL.md anti_patterns |
| AI-enabled cheap refactoring as reason to defer architectural decisions (removes forcing function) | _sparks (Apr 7) | tearitapart command |
| Single-agent assumption in multi-agent context (tools designed for solo agent fail in coordination) | multi-agent-coordination | orchestration SKILL.md anti_patterns |
| Waiting for "maturity" before promoting to default (production use IS maturity testing) | multi-agent-coordination | forge command |
| Context breadth past baseline = diminishing returns (optimize domain guide quality first) | agent-evaluation-infrastructure | orchestration SKILL.md |
| Treating AI config (CLAUDE.md, hooks, MCP schemas) as documentation rather than load-bearing infrastructure | ai-infrastructure-integrity | rules/kernel.md |
| Placeholder specs ("Fill in API key here") — each placeholder is a failure point in one-shot delivery | one-shot-implementation-methodology | ingest command |
| Generic "run tests" pre-commit hooks that miss project-class-specific failure modes | _sparks (Apr 23) | validate command |
| Runaway agent cost without cap ($0.40-0.60/query × stuck retries = silent invoice shock) | _sparks (Apr 2) | CLAUDE.md anti_patterns |

---

## Architecture shifts since plugin last updated

- "Skills as secondary" → **Skills-first 8:4:2 as primary scaling axis** (more skills per agent, not more agents) — needs ratio guidance in CLAUDE.md agents section
- "Single flat CLAUDE.md" → **CLAUDE.md as router + skills as payloads + settings.json as permissions** (three-part contract)
- "Devcontainer is optional" → **Devcontainer + secrets-bridge is canonical reproducible delivery**
- "Always parallelize" → **Task-property-conditional parallelize** (MAS overhead often exceeds benefit) — parallel_first invariant needs nuance
- "LLM-as-judge for eval" → **Programmatic verifiers preferred; LLM judge only where deterministic scoring impossible**
- "Single-run evaluation" → **Two-phase protocol (Run 1 cold-scored + Run 2 optimized)**
- "Skills/evals designed after code" → **Skills and evals written simultaneously before first code commit**
- "Token count as health metric" → **Reasoning quality (hypothesis depth, step count) as session health; compact at 60%**
- "MCP = one-time integration" → **MCP = infrastructure needing quarterly operational audits**
- "Session state assumed ephemeral" → **Sessions persist 30 days by default; ephemeral containers are explicit design choice**
- "Permission layers combined" → **Single permission layer only**
- "12s SDK overhead = bug to fix" → **12s floor is architectural; raw API for sub-second latency**
- "Subagents can be recursive" → **Subagent hierarchy is flat (max 1 level deep in SDK)**
- "CLAUDE.md more instructions = more compliance" → **Longer CLAUDE.md = lower compliance; pruning = compliance amplifier**
- "Failure is failure" → **AgentRx 4-type taxonomy (Action/Reasoning/Tool/State) with distinct mitigations**
- "Forge is about code generation" → **Forge includes verification architecture as first-class concern; catch rate > generation quality**
- "Multi-AI config is per-tool" → **Canonical spec + transpiler to tool formats; Stage 4: per-context behavioral router**

---

## New vocabulary / mental models worth adopting

| Term | Meaning | Use in |
|---|---|---|
| Quiescence | Extended period of zero commits where automation continues — maturity signal, not abandonment | KERNEL docs, retrospective |
| Antifragile | Improves under adversarial pressure (not merely robust) — forge target state | forge command |
| Execution rails | Complete, zero-ambiguity spec executed without interpretation | ingest + one-shot pattern |
| Skills-first ratio | Skills:agents ratio as primary health metric (8:4:2 canonical) | orchestration SKILL + CLAUDE.md |
| Blind evaluator | Structurally separate eval agent with no access to solution | eval SKILL, blind-evaluator agent |
| Token Snowball | Context fill causing architectural mental model eviction; solve rate 65%→21% | context-mgmt SKILL, forge |
| Reasoning fidelity | Quality metric (hypothesis depth, step count) independent of token count | context-mgmt SKILL |
| Validate-then-optimize | Two-phase: cold failure run scored, then optimization | eval SKILL, forge |
| Structural separation | Architectural constraint that holds under pressure (vs procedural which fails) | eval SKILL, enforcement docs |
| MAS overhead threshold | Point where multi-agent coordination cost exceeds parallelism benefit | orchestration SKILL |
| Domain-partitioned isolation | Parallel agents with READ/WRITE directory isolation + interface contracts | orchestration SKILL |
| Decontamination | Periodic AgentDB cleanup removing ticket-specific answer keys from training set | agentdb docs |
| Three-part contract | CLAUDE.md as router + skills as payloads + settings.json as permissions | CLAUDE.md, onboarding |
| Burst→Consolidation→Quiescence | Dev cycle where commit absence + running automation = healthy maturity | retrospective command |
| AgentRx taxonomy | 4-type failure classification: Action/Reasoning/Tool/State | coroner agent |
| agnix | Static analysis linter for AI config files — "ESLint for AI config" | new docs/MCP-OPERATIONS.md |
| GEPA trace | 4-phase structured reasoning audit: Goal/Exploration/Plan/Action | diagnose command |
| Expand-then-consolidate | QA orchestration rhythm: over-assign contracts, then right-size | orchestration SKILL + qa patterns |
| Execution-ready artifact | Complete spec (exact code, config, SQL, deps) — not design doc | ingest command |
| Knowledge graph per-agent bundles | Stage 4 multi-AI config: selective context loading per agent role | orchestration SKILL (advanced) |

---

## Concrete skill/agent proposals

| Proposed | Role | Source |
|---|---|---|
| `agents/blind-evaluator.md` | Receives only problem + rubric, never solution; structural isolation | evaluation-architecture, agent-evaluation-infrastructure |
| `skills/eval-infrastructure/SKILL.md` | New eval skill: golden dataset, train/test splits, decontamination, blind protocols | agent-evaluation-infrastructure |
| `skills/mcp-ops/SKILL.md` or `docs/MCP-OPERATIONS.md` | Quarterly MCP audit: transport, auth, token limits, deferred loading | mcp-infrastructure |
| `skills/client-delivery/SKILL.md` or `docs/DEVCONTAINER-DELIVERY.md` | Docker + secrets-bridge + skills delivery for client projects | agent-architecture-composition |
| `commands/audit.md` (kernel:audit) | Multi-repo cross-system intelligence: spans repos + Jira + GitLab + infra in parallel | _sparks (Apr 9) |
| `commands/offboard.md` (kernel:offboard) | Knowledge extraction from departing devs (code/design/config) | _sparks (Apr 15) |
| Enhanced `agents/coroner.md` with AgentRx 4-type taxonomy | Action/Reasoning/Tool/State classification + type-specific mitigation | autonomous-dev-anti-patterns |
| `agents/qa-orchestrator.md` | Contract decomposition → schema-first → expand-then-consolidate → window-scoped | qa-orchestration-patterns |
| `skills/llmops/SKILL.md` | Model selection benchmark, reasoning API migration, in-context RL skill internalization | production-llm-operations |

---

## Methodology fingerprints

| Methodology | Source | Plugin enforcement |
|---|---|---|
| Teardown-as-specification-gate (block implementation until teardown finds zero "agent will guess" gaps) | one-shot-implementation-methodology | tearitapart: add "spec completeness" verdict before PROCEED |
| Zero-interpretation contracts ("could agent execute with zero follow-up?") | one-shot-implementation-methodology | ingest: completeness gate |
| Framework failure mode research BEFORE implementation (not reactive debugging) | one-shot-implementation-methodology | ingest research step: explicit pre-implementation pitfall research |
| Failure-mode map before non-trivial code (design failure taxonomy first, build against known failures) | autonomous-dev-anti-patterns | tearitapart: add failure taxonomy phase |
| Skills before code (case studies → skills → eval harness → code → run evals) | evaluation-architecture | ingest flow reordering |
| Diagnosis artifact as separate commit before fix commit | agent-control-plane | diagnose command + git SKILL |
| Commit before destructive move (one atomic checkpoint before any irreversible file op) | _sparks (Apr 9) | git SKILL + rules/kernel.md invariant |
| Quarterly portfolio culling (90-day no-commit + no active intent = archive) | _sparks (Apr 17) | retrospective command |
| `agentdb wtf` / `agentdb timeline` as session health queries | ai-infrastructure-integrity, _sparks (Mar 30) | agentdb CLI + metrics |
| Baseline before optimization (minimal context first, measure, then test one addition at a time) | agent-evaluation-infrastructure | experiment + eval SKILL |
| Pre-merge snapshot for cold evaluation (never evaluate against post-merge codebase) | agent-evaluation-infrastructure | eval SKILL |
| Read utilization tracking for AgentDB (unread gotchas are failures; escalate or evict unused) | ai-infrastructure-integrity | agentdb inject-context |
| Evidence gates (transitions require proof objects, not confidence rhetoric) | enforcement-architecture | validator agent + pre-ship agent |

---

## TL;DR — top 5 plugin actions from dreams synthesis

1. **`agents/blind-evaluator.md`** + restructure `skills/eval/` — self-scoring inflates 5pts/36% structurally. Need structural (not procedural) eval separation.
2. **Compact at 60% fill, not at limit** — reasoning fidelity degrades at 60-70%; current trigger is too late. Reclassify "context problem" as "fidelity problem."
3. **AgentRx 4-type failure taxonomy** in coroner + agentdb schema — Action/Reasoning/Tool/State with distinct mitigations.
4. **Three-part contract docs** — CLAUDE.md as router, skills as payloads, settings.json as permissions. Plus 8:4:2 skills:agents:commands ratio guidance.
5. **`docs/DEVCONTAINER-DELIVERY.md` + `docs/MCP-OPERATIONS.md`** — devcontainer + secrets-bridge is canonical client delivery; quarterly MCP audits are operational, not one-time.

Vocabulary to absorb: quiescence, execution rails, Token Snowball, reasoning fidelity, blind evaluator, MAS overhead threshold, validate-then-optimize, structural separation, GEPA trace, expand-then-consolidate, three-part contract.
