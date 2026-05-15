# Cross-project mining for kernel-claude updates — 2026-05-14

Sourced from 14 CodingVault projects (excluding funjoin entirely). Strongest signals from `distillations/` threads, `dreams/` graduated docs, and recently-modified project `_meta/` directories.

## Projects examined (with mtime of last activity)
- distillations/: 2026-04-29 — GOLD: 6 living thread docs + 60+ archived raw activity files
- dreams/: 2026-04-29 — 25 graduated dream docs + active _sparks.md
- latent-diagnostics/: 2026-03-26 — ML interpretability research; negative results archived with rigor
- llm-bench/: 2026-04-05 — practical LLM benchmark CLI, programmatic verifiers only, shipped in one day
- honey-agent/: 2026-03-26 — deception-as-a-service hackathon; honeypot agents + Auth0 FGA
- hotel-quote-parser/: 2026-01-28 — document extraction; hybrid deterministic+LLM pipeline; inactive
- hwf/: SwiftUI/iOS — motion rules and transition anti-patterns documented
- itinerator/: 2026-02-08 archived; migrated from Cloud Functions to WebLLM browser-side
- event-horizon/ + event-horizon-frontend/: 2026-04-17 — 6-agent refactor; AGENT_REPORTS artifacts per domain
- cognitive-substrate/, go-voice/, docuseal/, maerai/, brink-mind/: minimal recent _meta activity

---

## Cross-cutting patterns (3+ projects)

**Pattern: AgentDB persistence is non-trivial and fails silently**
- Projects: kernel-claude (gotcha read utilization fix v7.9.2), funjoin (13 learnings volatile across sessions — blocker), adna (`skill_sqlite_persistence` formalized as knowledge primitive)
- Implication: Add explicit AgentDB persistence health check to SessionStart hook. Verify DB writable + last N learnings queryable. Emit WARNING if learnings count dropped (indicates WAL/SHM wipe). Document in `_meta/reference/`.

**Pattern: CLAUDE.md length inversely correlates with agent compliance**
- Projects: kernel-claude (compressed 653→320 tokens), distillations sparks 2026-04-06 ("Anthropic 2026 guidance: agent compliance drops as file length grows"), funjoin (CLAUDE.md ruthless pruning)
- Implication: Audit CLAUDE.md length on every major version. CI check fail at >400 tokens. Add to experiment engine: "CLAUDE.md length inversely correlated with rule compliance — shorter is strictly better."

**Pattern: Commit-before-move / COMMIT BEFORE MOVE as mandatory invariant**
- Projects: funjoin (11 files lost to mv on untracked), nunchi (`git stash` classified FORBIDDEN), distillations/threads/security.md (git stash = data loss attack vector)
- Implication: Add `COMMIT BEFORE MOVE` rule to `skills/git/SKILL.md`. PreToolUse hook checks for `mv`/`rm` in Bash + warns if `git status` shows untracked files in affected path. Write-time guard, not advisory.

**Pattern: Plugin registration is a second mandatory step after skill file creation**
- Projects: kernel-claude (plugin.json missing landing-page skill — silent failure, v7.12.1→7.12.2 fix), distillations/tooling 2026-04-20 ("broken registration = invisible feature")
- Implication: Pre-commit CI gate that checks every `.md` in `skills/` and `commands/` against `plugin.json` entries. Skill file without entry → block commit.

**Pattern: Parallel agent work on shared files causes merge conflicts — must serialize**
- Projects: kernel-claude (H015/H016 refuted: 7-way merge conflicts), event-horizon (6-agent refactor used domain-partitioned independent output dirs), funjoin (MAS overhead threshold), dreams/multi-agent-coordination
- Implication: Update `skills/git/SKILL.md` + forge to distinguish two parallelism regimes: (1) research/independent files = parallelize; (2) shared imports/coupled code = serialize. `/kernel:forge` HEAT phase should default-detect file dependencies before spawning parallel agents.

**Pattern: PostToolUse security scanning inverts the agent security model**
- Projects: funjoin (posttooluse-security-scan.sh detects generated code vulnerabilities after write), kernel-claude (hardcoded-value warnings), honey-agent (canary credentials)
- Implication: Add PostToolUse hook scanning generated code for: eval(), innerHTML/document.write, exec/os.system, pickle, dangerous SQL string concatenation. ~30 lines bash (validated by plugin-gap-verdict H070).

**Pattern: Documentation-before-archive as mandatory closure ritual**
- Projects: distillations/sparks 2026-04-17 (explicit pattern), funjoin (offboarding-as-knowledge-extraction spec), event-horizon (AGENT_REPORTS archival), latent-diagnostics (negative results archived with disclaimers)
- Implication: Add to `skills/git/SKILL.md` documentation-before-archive gate. `/kernel:handoff` should warn if no handoff doc exists for current session before user runs `/clear`.

**Pattern: Context compaction must trigger at 60-70% fill, not at limit**
- Projects: dreams/autonomous-dev-anti-patterns (HF Daily Papers research, fidelity degrades at 60-70%), kernel-claude research (claude-best-practices-2026: "compact aggressively at 70% window fill"), claude-techniques-april-2026 (context awareness section)
- Implication: precompact hook threshold should be 60-70%, not 80-90%. New experiment: H-COMPACT-THRESHOLD: 60% vs 80% session quality measurement.

---

## Single-project insights worth promoting

**Insight: Prompt-router as lightweight RAG alternative for context injection**
- From: funjoin/.claude/userpromptsubmit-router.sh (2026-04-29)
- Goes to: `hooks/scripts/userpromptsubmit-router.sh` — reads routes.json, matches against live prompt, injects up to 3 context hints. Highest-leverage addition not yet in kernel. Token-efficient RAG approximation.

**Insight: Full lifecycle hook coverage — start/prompt/tool/end — as production harness baseline**
- From: funjoin/.claude/ (2026-04-23) — 4 distinct hook types covering all lifecycle points
- Goes to: `hooks/scripts/` — kernel has SessionStart and PostToolUse but lacks fully wired session-end handler and prompt-submit scanner. funjoin stop-session-end.py (170 lines) and userpromptsubmit-scan.py are reference implementations.

**Insight: AgentDB lifecycle toolbox (bootstrap/export/purge/sanitize) as graduation requirement**
- From: funjoin _meta/agentdb/ (2026-04-18)
- Goes to: `orchestration/agentdb/` — kernel has migrations + CLI but no lifecycle management. Sanitize specifically enables external sharing without manual per-entry review.

**Insight: 4-type failure taxonomy (Action/Reasoning/Tool/State) for AgentDB error classification**
- From: dreams/autonomous-dev-anti-patterns (Microsoft Research AgentRx, 115 annotated trajectories)
- Goes to: `orchestration/agentdb/migrations/` — add `failure_type` column to errors table. `/kernel:coroner` agent tags each failure. Enables "what failure type is most common this week?" as queryable.

**Insight: Reasoning fidelity degradation at 60-70% context fill is structural, not token problem**
- From: dreams/autonomous-dev-anti-patterns (HF Daily Papers)
- Goes to: `skills/context-mgmt/SKILL.md` — current framing "token count" as health metric. Reclassify: real signal is reasoning depth (hypothesis exploration, step count, backtracking). Measure quality, not quantity.

**Insight: Blind evaluation protocol — self-scoring inflates by 5 points (36%) systematically**
- From: funjoin eval infrastructure (CMP-001/002), distillations/threads/testing
- Goes to: `skills/eval/SKILL.md` or `agents/reviewer.md` — add mandatory blind evaluation. Second agent (never exposed to original output) scores result. 9.0/10 blind vs 14.0/10 self-scored gap is structural bias, not calibration drift.

**Insight: Gotcha-first research before any high-risk infrastructure change**
- From: modelmind (expo-router v4: 6 critical gotchas before implementation, 2026-04-07), one-shot-implementation-methodology (Pattern 5), hotel-quote-parser
- Goes to: `skills/build/SKILL.md` — add "gotcha-first research" mandatory before any navigation, auth, or schema change. Distinct phase from `/kernel:tearitapart` (design-level teardown).

**Insight: MCP config quarterly audit — SSE transport deprecated, deferred loading mandatory at 50+ tools**
- From: dreams/mcp-infrastructure (graduated 2026-04-16)
- Goes to: `_meta/reference/mcp-ops-checklist.md` — quarterly audit: verify `"type": "http"` not `"type": "sse"`, MAX_MCP_OUTPUT_TOKENS per server, deferred loading active if >50 tools, audit postinstall scripts (`npx -y` pattern).

**Insight: `max_budget_usd` as mandatory invariant, not optional config**
- From: dreams/agent-sdk-deployment-patterns, distillations/ai-patterns 2026-04-02 spark: "$0.40-0.60/query × 200 stuck retries = $120 silently"
- Goes to: `skills/orchestration/SKILL.md` — any `/kernel:forge` autonomous loop must document cost cap as required, not optional. Preflight check warns if no budget cap before long autonomous run.

---

## New tech/integrations adopted since Mar 2026

**Astro 5 with React islands** (funjoin-website, ourlastframe — same 7-day window): document Astro decision tree in `skills/build/SKILL.md`. Static-only → Astro w/o islands; static + interactive → Astro + `client:load` islands; per-request SSR → Next.js. Wrap React components as islands, zero rewrites.

**Cloudflare Workers + D1 + R2 as full mobile backend stack** (modelmind, company-site, ourlastframe): new `skills/backend/cloudflare-edge.md`. Workers AI + D1 + R2. Edge AI translation cache: ~500ms first request, ~10ms cached, 50x reduction. CF Pages auto-handles clean URLs — explicit `_redirects` rules create redirect loops.

**Claude Managed Agents (public beta 2026-04-18)** (funjoin Sunny agent, dreams/agent-sdk-deployment-patterns): document SDK → Managed Agents promotion decision tree in `skills/orchestration/SKILL.md`. SDK constraints: 12s subprocess overhead, 1-level subagent depth, permission complexity, billing gap, session persistence security — all resolved by Managed Agents. Pattern: SDK for prototype + eval, Managed Agents for production unattended workloads.

**Fastlane + ASC API key as EAS replacement for React Native** (modelmind full EAS exit arc): add to `skills/app-dev/SKILL.md`. ASC API key replaces deprecated username/password. Three-stage exit arc (EAS Build → Fastlane, EAS Submit → ASC API key, EAS Updates → R2 OTA) achievable per stage.

**vite-react-ssg as SSG retrofit without framework migration** (funjoin-website 31-route pre-rendering): note in `skills/build/SKILL.md`. Use vite-react-ssg for minimum disruption within Vite; Astro when partial hydration control needed. SSG promotion reversible.

**Effort parameter replacing extended thinking tokens (Claude Opus 4.7)** (distillations/research/claude-techniques-april-2026 2026-04-19): update `skills/claude-api/SKILL.md`. `effort` replaces `thinking: {budget_tokens}`. Start `xhigh` for coding. Opus 4.7 interprets prompts literally — explicit scope ("apply to X, Y, AND Z"). Uses tools LESS than 4.6; raise effort to restore tool usage.

**posttooluse-security-scan.sh + userpromptsubmit-scan.py** (funjoin/.claude/hooks/ 2026-04-23/29): adopt both into `hooks/scripts/`.

**FSRS pattern as deployed ML state persistence** (modelmind 2026-04-03): demonstrates "algorithm simple, persistence/sync architecture is the hard part." Same applies to AgentDB.

---

## Methodology evolution

- **Old: Research when blocked → New: Gotcha-first research before implementation begins** (modelmind expo-router v4, hotel-quote-parser, one-shot-implementation-methodology Pattern 5, kernel-claude landing-page failure modes catalog)
- **Old: Parallelize everything → New: Enumerate task dependencies first; parallelize only acyclic task graphs** (H015/H016 refuted, MAS overhead threshold, domain-partitioned parallel refactor)
- **Old: Single evaluator → New: Blind evaluation mandatory for high-stakes assessment** (funjoin CMP-001/002 36% inflation, agent-evaluation-infrastructure 4-layer eval)
- **Old: CLAUDE.md as documentation → New: CLAUDE.md as compliance surface; shorter = more compliant** (distillations/sparks 2026-04-06, funjoin config evolution, kernel-claude 653→320 token compression)
- **Old: AgentDB as logging → New: AgentDB as coordination bus requiring full database lifecycle tooling** (funjoin bootstrap/export/purge/sanitize, adna skill_sqlite_persistence, distillations/ai-patterns AgentDB propagation)
- **Old: Multi-agent = more agents → New: Skills-heavy architecture (8:4:2 ratio) with agents as lean executors** (funjoin 8-skill/4-agent/2-command, kernel-claude Forge skills-first composition)

---

## Hooks/skills/agents invented locally — promotion candidates

**userpromptsubmit-router.sh** (funjoin/.claude/hooks/) — prompt-triggered context injection via routes.json. Most novel hook pattern in vault.

**posttooluse-ambient-learnings.sh** (funjoin/.claude/hooks/ 2026-04-29) — continuous learning capture after each tool use. Closes feedback loop: agent action → learning captured immediately. vs kernel's batch-at-session-end approach.

**AgentDB sanitize.py** (funjoin/_meta/agentdb/ 2026-04-18) — automated internal→external shareable. Strips internal codenames, ticket IDs, personnel identifiers. Hours → minutes for publication.

**stop-session-end.py (170L)** (funjoin/.claude/hooks/) — full session termination handler covering learning capture, session duration logging, compaction telemetry, context state snapshot.

**userpromptsubmit-scan.py** (funjoin/.claude/hooks/ 2026-04-23 expanded) — pre-execution prompt security scan. Catches injection patterns, COMMIT BEFORE MOVE violations, unsafe operation requests before agent execution.

**Plugin-gap-verdict methodology (H070-H077)** (kernel-claude/_meta/research/plugin-gap-verdicts-2026-04.md) — systematic competitor analysis producing CONFIRMED/PARTIAL/REFUTED verdicts with adoptable techniques. Quarterly research ritual. Priority adoptions: install claudetop/ccusage for cost visibility, hookify markdown rule format, extend AgentDB with entity-relations + FTS5, git blame analyzer in review pipeline.

**latent-diagnostics negative results archival** (latent-diagnostics/_meta/ 2026-02-23) — archive failed experiments with disclaimers (deprecated/), document confounds (n_active collapsed under length control), preserve null results (TruthfulQA showed no signal). For kernel-claude experiment engine: refuted hypotheses (H015, H016) should not be deleted — archived with evidence as "refuted" in hypothesis table.

---

## TL;DR — top 5 plugin actions from this mining

1. **Add `userpromptsubmit-router.sh` hook** from funjoin — prompt-triggered context injection without vector DB. Most novel working pattern not yet in kernel.
2. **PostToolUse code vulnerability scanning** — 9 patterns (eval, innerHTML, exec, pickle, SQL string concat) in ~30 lines bash. Plugin-gap H070 confirmed gap.
3. **COMMIT BEFORE MOVE PreToolUse hook** — funjoin lost 11 files. Warn when `mv`/`rm` in Bash and `git status` shows untracked files.
4. **Cost visibility (claudetop/ccusage)** — kernel has zero financial observability. Plugin-gap H073 CONFIRMED. Especially critical for autonomous /forge loops.
5. **AgentDB lifecycle toolbox** (bootstrap/export/purge/sanitize from funjoin) — when AgentDB transitions to team-operational, needs same ops toolbox as production database.

Cross-cutting: CLAUDE.md compliance ∝ 1/length (Anthropic-confirmed). Compaction at 60-70% fill, not 80%+. Blind evaluation mandatory (self-scoring inflates 36% systematically). Reasoning fidelity is the metric, not token count.
