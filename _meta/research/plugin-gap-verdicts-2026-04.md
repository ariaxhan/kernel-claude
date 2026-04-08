# Plugin Gap Verdicts — H070-H077

date: 2026-04-07
method: source code analysis of each plugin vs kernel-claude capabilities
evidence: GitHub repos (anthropics/claude-code, liorwn/claudetop, ryoppippi/ccusage, shaneholloman/mcp-knowledge-graph)

---

## H070: security-guidance — Hook-based real-time security scanning

**Verdict: REFUTED**

**Plugin:** PreToolUse hook (Python) that pattern-matches 9 vulnerability categories in Write/Edit/MultiEdit content: GitHub Actions injection, child_process.exec, eval(), new Function(), dangerouslySetInnerHTML, innerHTML, document.write, pickle, os.system. Session-scoped dedup so each warning shows once.

**Kernel already has:**
- `hooks/scripts/detect-secrets.sh` — PreToolUse hook on Write|Edit that blocks 16 secret patterns (API keys for OpenAI, GitHub, AWS, Slack, Stripe, Anthropic, Google, Azure, JWTs, private keys)
- `hooks/scripts/guard-bash.sh` — blocks force push to main, rm -rf root/home
- `hooks/scripts/guard-config.sh` — protects .claude directory
- `hooks/scripts/warn-hardcoded.sh` — async warning on hardcoded values
- `skills/security/SKILL.md` — comprehensive security methodology (OWASP, XSS, CSRF, injection, supply chain, prompt injection)
- `agents/reviewer.md` — 11-phase review protocol including Phase 08: Security

**Gap analysis:** Kernel's hooks focus on secrets and destructive commands. security-guidance focuses on *code vulnerability patterns* (eval, innerHTML, pickle). These are complementary, not overlapping. However, kernel's security skill already teaches the reviewer agent to catch these patterns during review. The difference is *timing*: security-guidance warns at write-time (proactive), kernel catches at review-time (reactive).

**Nuance:** The write-time warning is a genuine UX improvement for catching vulnerabilities before they land, but kernel's multi-layer approach (hooks + skill + reviewer) provides deeper coverage. The 9 patterns in security-guidance are a subset of what kernel's security skill covers.

**Adoptable technique:** Add code vulnerability pattern detection (eval, innerHTML, exec, pickle) to kernel's existing PreToolUse hook chain. ~30 lines of bash or a Python hook. Low effort, high value.

---

## H071: hookify — Conversational hook creation

**Verdict: CONFIRMED**

**Plugin:** Natural language hook creation via `/hookify`. Generates markdown rule files with YAML frontmatter + regex patterns. Supports bash/file/stop/prompt events. Conditions with operators (regex_match, contains, not_contains, equals, starts_with, ends_with). Hot-reload without restart.

**Kernel has:** 6 shell script hooks in hooks/scripts/, manually authored. hooks.json configuration. No conversational creation, no markdown-based rule format, no hot-reload.

**Gap:** Kernel hooks work but require editing shell scripts and hooks.json manually. hookify's markdown-based rules with YAML frontmatter are significantly more accessible and faster to iterate. The `/hookify` command that analyzes conversation to auto-generate rules has no kernel equivalent.

**Adoptable technique:** The markdown rule format (YAML frontmatter with event/pattern/action/conditions) is the key innovation. Kernel could add a hookify-style rule interpreter that reads `.claude/hookify.*.local.md` files alongside its existing shell hooks. This would let users create hooks conversationally while keeping kernel's existing bash hooks for complex logic.

---

## H072: code-review — 5 parallel reviewers

**Verdict: CONFIRMED (partial)**

**Plugin:** 4 parallel agents (2x CLAUDE.md compliance, 1x bug detector, 1x git history analyzer), confidence scoring 0-100, threshold filtering at 80, GitHub PR comment integration with full SHA links, automatic skip logic for closed/draft/trivial PRs.

**Kernel has:** 1 reviewer agent with 11-phase protocol, confidence scoring (weighted formula across 7 dimensions), Big 5 quality checks, security/performance phases. Also has adversary agent for tier 3 verification. `/kernel:review` command.

**Gap analysis:** Kernel's single reviewer is *deeper* (11 phases vs 4 parallel focuses). But code-review's parallel approach catches *different perspectives simultaneously* — especially the git history analyzer (blame context) which kernel lacks. Kernel's reviewer runs sequentially through phases; code-review runs 4 agents in parallel and deduplicates.

**What kernel already does better:** Confidence scoring (weighted multi-dimensional vs simple 0-100), Big 5 methodology, adversary agent for tier 3.

**What code-review does better:** Parallel independent perspectives, git blame context analysis, GitHub PR comment integration with direct code links, automatic PR skip logic.

**Adoptable technique:** Add a git-history-analyzer perspective to kernel's review pipeline. Consider parallelizing review phases (Big5 + security + performance in parallel rather than sequential). The PR skip logic (closed/draft/trivial detection) is also worth adopting.

---

## H073: claudetop/ccusage — Cost monitoring

**Verdict: CONFIRMED**

**Plugin:** Real-time status line showing per-session cost, burn rate/hr, monthly projection, cache efficiency, model cost comparison, context composition breakdown. Smart alerts ($5/$10/$25 marks, budget exceeded, low cache, burn rate spike, spinning detection). Session history analytics. iTerm2 integration. Daily budget tracking.

**Kernel has:** Zero cost visibility. `_meta/logs/costs.jsonl` mentioned in NEXUS config but no implementation found. No token tracking, no burn rate, no budget alerts.

**Gap:** This is a clear, unambiguous gap. Kernel has sophisticated AgentDB telemetry for session tracking, learnings, and agent coordination, but zero financial observability. claudetop solves a real problem (the author discovered a $65 bill expected to be $10).

**Adoptable technique:** claudetop hooks into Claude Code's status line API (documented extension point that pipes JSON telemetry to executables in `~/.claude/claudetop.d/`). Kernel should either: (1) install claudetop as a companion tool, or (2) build a lightweight cost tracker into kernel's existing SessionEnd hook that logs token counts and estimated costs to AgentDB. The smart alerts (burn rate spike, spinning detection) are particularly valuable for kernel's autonomous /forge loops.

---

## H074: ralph-wiggum — Lightweight autonomous loops

**Verdict: REFUTED**

**Plugin:** Stop hook that intercepts Claude's exit and re-feeds the same prompt. Simple bash loop: work, try to exit, hook blocks, repeat. `--max-iterations` safety net. `--completion-promise` for exit condition.

**Kernel has:** `/kernel:forge` — 4-phase autonomous engine (HEAT/HAMMER/QUENCH/ANNEAL), up to 10 iterations, integrity scoring 0-1.0, adversarial entropy testing, multi-approach exploration, agentdb audit trail. Also `/kernel:experiment` — 20-cycle autonomous loop for hypothesis testing.

**Gap analysis:** Ralph is simpler — that's the claim. But "simpler" here means "less safe." Ralph is literally a while-true loop with a string-match exit condition. Kernel's forge has: integrity scoring, approach switching on failure, adversarial verification, structured learning capture, max 3 anneals + 10 iterations as multi-layered safety. Ralph's only safety is --max-iterations.

**What ralph does differently:** The Stop hook mechanism (intercepting exit) is clever and lightweight. No configuration, no phases, just a prompt and a loop. Good for mechanical batch tasks.

**What kernel does better:** Everything else. Adversarial testing, approach diversity, structured failure learning, integrity scoring, audit trail.

**Verdict rationale:** Kernel's forge is heavier because it's *better*, not because it's bloated. The lightweight claim is true but not a gap — it's a tradeoff of quality for simplicity. For users who want a dumb loop, ralph works. For users who want antifragile output, forge wins.

---

## H075: mcp-knowledge-graph — Semantic cross-session memory

**Verdict: CONFIRMED**

**Plugin ecosystem:** Multiple implementations (mcp-knowledge-graph, claude-graph-memory, claude-code-buddy, memento-mcp). Core capability: entities, relations, observations stored in a graph. Semantic search via local embeddings or FTS5. Persistent across sessions.

**Kernel has:** AgentDB (SQLite) with structured tables for sessions, learnings, hypotheses, contracts, events. SQL queries for retrieval. FTS not implemented. No entity-relation model, no semantic search, no embeddings.

**Gap analysis:** AgentDB stores *operational data* (what happened, what was learned, what's contracted). Knowledge graphs store *conceptual relationships* (entity A relates to entity B via relation R). These serve different purposes. AgentDB answers "what did we do last session?" Knowledge graphs answer "how does concept X relate to concept Y across all sessions?"

**Example:** AgentDB can tell you "auth refactor failed because of circular import." A knowledge graph can tell you "AuthService depends on UserService depends on SessionService, and SessionService has a weak reference back to AuthService" — structural knowledge that persists and compounds.

**Adoptable technique:** Add an entity-relation layer to AgentDB. The 002_graph_tracking migration already exists in `orchestration/agentdb/migrations/` — this suggests kernel was already heading in this direction. The specific technique: store entities and relations in AgentDB tables, add FTS5 for text search. Full vector embeddings are overkill for a CLI tool; FTS5 + structured relations cover 80% of the value.

---

## H076: plugin-dev — Plugin scaffolding

**Verdict: CONFIRMED**

**Plugin:** 7 specialized skills (hook development, MCP integration, plugin structure, plugin settings, command development, agent development, skill development). 8-phase guided workflow (`/plugin-dev:create-plugin`). Validation utilities (validate-agent.sh, validate-hook-schema.sh, hook-linter.sh). 11K+ words of skill content, 10K+ words of reference docs.

**Kernel has:** No plugin creation tooling. Kernel IS a plugin, but has no meta-tooling for creating other plugins. Skills cover build, testing, security, etc. — but none cover Claude Code plugin architecture specifically.

**Gap:** Genuine gap. If someone wants to build a Claude Code plugin, kernel offers no guidance. plugin-dev provides the full lifecycle: structure, hooks, MCP, commands, agents, skills, validation, publishing.

**Adoptable technique:** This is an INSTALL, not an ADOPT situation. plugin-dev is a standalone toolkit for a different use case (building plugins). Kernel should recommend installing plugin-dev alongside kernel rather than absorbing its 20K+ words of plugin-specific documentation. The one adoptable piece: plugin-dev's validation utilities (validate-agent.sh, validate-hook-schema.sh) could be used to validate kernel's own agents and hooks.

---

## H077: feature-dev — 7-phase feature workflow

**Verdict: REFUTED**

**Plugin:** 7 phases: Discovery, Codebase Exploration (parallel code-explorer agents), Clarifying Questions, Architecture Design (parallel code-architect agents), Implementation, Quality Review (parallel code-reviewer agents), Summary. 3 specialized agents: code-explorer, code-architect, code-reviewer.

**Kernel has:** `/kernel:ingest` — 6-phase guided workflow: Classify, Research, Scope, Tests, Execute, Learn. Plus `/kernel:forge` for autonomous execution. Plus `workflows/feature.md` defining: Scout, Research, Plan, Implement, Verify, Ship. Plus 13 agents (scout, researcher, surgeon, adversary, reviewer, etc.).

**Comparison:**

| Phase | feature-dev | kernel equivalent |
|-------|------------|-------------------|
| Discovery | Clarify feature request | ingest step 1: classify |
| Codebase Exploration | code-explorer agents | scout agent + researcher agent |
| Clarifying Questions | Organized question list | ingest challenge phase (from CLAUDE.md) |
| Architecture Design | code-architect agents (2-3 approaches) | forge HEAT phase (2-3 approaches) + dreamer agent |
| Implementation | Direct implementation | surgeon agent (tier 2+) |
| Quality Review | code-reviewer agents (3 parallel) | reviewer agent (11-phase) + adversary agent |
| Summary | What was built, next steps | ingest step 6: learn + agentdb write-end |

**Verdict rationale:** Kernel covers every phase of feature-dev with equal or greater depth. Kernel additionally has: tiered orchestration (1/2/3), adversarial verification, AgentDB persistence, research caching, experiment engine, and structured learning. feature-dev is a simpler, more accessible version of what kernel already does comprehensively.

---

## Summary Table

| ID | Plugin | Verdict | Rationale |
|----|--------|---------|-----------|
| H070 | security-guidance | REFUTED | Kernel has 4 security hooks + security skill + reviewer. Plugin's 9 code patterns are a subset. Adopt: add eval/innerHTML patterns to existing hooks. |
| H071 | hookify | CONFIRMED | Conversational hook creation + markdown rules are genuinely missing from kernel. |
| H072 | code-review | CONFIRMED (partial) | Git blame analysis + parallel perspectives are new. But kernel's reviewer is deeper. Adopt: git history analyzer + parallel review phases. |
| H073 | claudetop/ccusage | CONFIRMED | Zero cost visibility in kernel. Clear, unambiguous gap. |
| H074 | ralph-wiggum | REFUTED | Kernel's forge is heavier because it's better. Ralph trades quality for simplicity. |
| H075 | mcp-knowledge-graph | CONFIRMED | AgentDB stores operations, not conceptual relationships. Entity-relation + FTS5 would compound knowledge. |
| H076 | plugin-dev | CONFIRMED | Kernel has no plugin creation tooling. Recommend installing alongside, not absorbing. |
| H077 | feature-dev | REFUTED | Kernel's ingest + forge + workflows cover all 7 phases with greater depth. |

**Score: 4 CONFIRMED, 1 PARTIAL, 3 REFUTED**

**Priority adoption order:**
1. claudetop/ccusage (H073) — install immediately, zero cost visibility is a liability
2. hookify patterns (H071) — add markdown rule interpreter for accessible hook creation
3. Knowledge graph layer (H075) — extend AgentDB with entity-relations + FTS5
4. Git blame reviewer (H072) — add history-aware perspective to review pipeline
5. Code vulnerability patterns (H070) — add 9 patterns to existing PreToolUse hooks (~30 lines)
