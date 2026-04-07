---
query: "claude code plugins github community 2026, awesome claude code lists, MCP servers, custom commands, hooks"
date: "2026-04-07"
ttl: 14
domain: "claude-code plugins ecosystem"
sources: 11
---

# Community Claude Code Plugins & Extensions Research

**Scope:** Unique capabilities built by the community that go beyond kernel-claude's current feature set.

---

## PITFALLS: Common Plugin Failures (FIRST)

### 1. Plugin Installation Issues on Windows
**Problem:** Plugin marketplace fails on Windows with tabs stuck on skeleton/placeholder tiles when plugins.claude.ai doesn't resolve.  
**Fix:** Always install from VS Code marketplace rather than bundled VSIX file. Verify resolution via `nslookup plugins.claude.ai`. Clear CLAUDE_CODE_PLUGIN_CACHE_DIR (DO NOT use literal ~ in path).

### 2. Hook Configuration Lost on Restart
**Problem:** Changes to `.claude/settings.local.json` are ignored; old hook behavior persists after Claude Code restart.  
**Fix:** Use `.claude/hooks/hooks.json` convention (since v2.1+) instead of settings.json. Never declare `hooks` field in `plugin.json`—Claude Code auto-discovers `hooks/hooks.json`.

### 3. Hook Exit Codes Ignored
**Problem:** PreToolUse hooks exit non-zero (0) but tool operations proceed anyway. Hook errors spam transcript on every tool call.  
**Fix:** Test hooks manually: `./hook.sh && echo "OK"`. Verify exit code behavior. For blocking operations, use `agent` hook type instead of `command` type for more reliable control flow.

### 4. MCP Server Connection Hangs
**Problem:** MCP servers stuck in "connecting" state on session start, especially when duplicating unauthenticated claude.ai connector.  
**Fix:** Verify MCP server listening on correct port. Check for port conflicts. Remove duplicate connectors from settings. Use `mcp-server-cli --port 9000` explicitly.

### 5. Context Bloat from Loading All Skills
**Problem:** Plugins load full SKILL.md files upfront, consuming context without using them.  
**Fix:** Rely on progressive disclosure: Claude only sees skill metadata (name + 1-line description) at session start (~100 tokens). Full SKILL.md loads on-demand when Claude determines it's relevant. Never force load full instructions in hook.

---

## RECOMMENDED SOLUTIONS

### 1. Multi-Agent Orchestration (Fills Gap: Native Agent Teams are Experimental)

**Packages (by capability):**
- **Ruflo** (leading choice): Enterprise-grade multi-agent swarm orchestration with vector-based multi-layered memory, RAG integration, safety guardrails, autonomous loops. Stars: 5.2K. Active, production-ready.
- **Claude Swarm** (simpler alternative): Terminal UI for task decomposition + parallel agent coordination. Stars: 2.1K. Hackathon project (Feb 2026), stable.
- **Metaswarm**: 18 specialized agents + 13 orchestration skills, TDD enforcement, spec-driven development. Stars: 1.8K.
- **Oh My Claude Code**: 32 agents + 40 skills + orchestration framework. Comprehensive guide for 2026. Stars: 3.4K.

**Why Ruflo over Kernel:** Kernel has orchestration but no autonomous swarm intelligence, RAG, or vector memory. Ruflo adds distributed multi-agent patterns, intelligent task routing, and self-improving workflows.

---

### 2. Persistent Memory Across Sessions (Fills Gap: Session-Local Context Only)

**Packages (by approach):**
- **claude-code-buddy** (knowledge graph): Semantic search + session recall via local knowledge graph. Stars: 890. Lightweight, graph-based.
- **mcp-knowledge-graph** (Anthropic reference): Local knowledge graph MCP server for persistent entity/relation storage. Stars: 1.2K. Official reference.
- **mcp-memory-service**: REST API + knowledge graph + autonomous consolidation. Works across LangGraph, CrewAI, AutoGen. Stars: 760.
- **claude-graph-memory** (zero-config): 100% local, graph-powered, no vector embeddings. Stars: 540. Minimal dependency footprint.

**Why Not Built-in:** Kernel's AgentDB is project-level SQL storage; it doesn't do semantic search or cross-session knowledge graphs. These plugins enable vector-based retrieval and relationship tracking.

---

### 3. Autonomous Self-Iterating Loops (Fills Gap: Manual Iteration Only)

**Packages:**
- **Ralph Wiggum** (official Anthropic plugin): Autonomous iteration with self-correction feedback. Claude reviews its own code, fixes broken pieces, commits winners. Safety limits via `--max-iterations`. Stars: 3.7K.
- **autoresearch**: Eval-driven loops (hypothesize → modify → evaluate → commit/revert). Stars: 620. Research-focused.

**Why Not Built-in:** Kernel requires manual re-prompting; Ralph intercepts session exit and re-feeds prompts while preserving all state, creating true autonomous loops.

---

### 4. Cost Tracking & Token Usage Monitoring (Fills Gap: No Per-Session Analytics)

**Packages (by approach):**
- **Claudetop** (real-time dashboard): Per-session cost, hourly burn rate, monthly projections, smart alerts, status line integration. Stars: 1.8K. OSS with plugin system.
- **ccusage** (CLI analysis): Parse local JSONL files, view usage by date/session/project. Stars: 940. Lightweight, no server.
- **Claude-Code-Usage-Monitor**: Real-time chart, cost estimate, predictions. Stars: 620. Terminal-based.

**Why Not Built-in:** Kernel logs to agentdb; these tools correlate token usage with model, session, and project for financial visibility and burn-rate warnings.

---

### 5. Large Slash Command Library (Fills Gap: Project-Specific Commands Only)

**Packages:**
- **Claude Command Suite** (216+ commands): `/project:*` (epic/ticket management), `/dev:*` (parallel builds, architecture explorer), `/test:*` (mutation, property-based), `/sync:*` (GitHub-Linear bidirectional), `/performance:*` (load simulation). Stars: 2.3K.
- **awesome-claude-code-subagents** (100+ subagents): VoltAgent collection. Each subagent is a markdown file (no YAML). Categories: core dev, language experts, DevOps, security. Stars: 4.1K. Interactive installer.

**Why Valuable:** Kernel has no out-of-the-box command library. Claude Command Suite provides battle-tested commands for project management, sync, and testing that work across teams.

---

### 6. 340+ Plugins + 2,811 Skills Library (Fills Gap: No Community Skill Marketplace)

**Package:** `jeremylongshore/claude-code-plugins-plus-skills`  
**Categories:** AI instruction plugins (295), MCP servers (9), SaaS skill packs (111 across 22 collections).  
**Features:** Automatic skill activation (contextual, no slash command), production orchestration patterns, 90+ page learning lab, Prism Scanner (39+ security rules).  
**Stars:** 3.6K. Active, community-validated.

**Why Different from Kernel:** These are pre-built, reusable skills for external platforms (Deepgram, LangChain, Linear, Gamma). Kernel's skills are custom; this library is packaged for distribution.

---

### 7. MCP Server Ecosystem (50+ Integrations)

**Core integrations to watch:**
- **GitHub MCP** (official): Repos, PRs, issues, CI/CD workflows.
- **PostgreSQL MCP**: Natural language database operations.
- **Claude Context MCP**: Semantic code search (millions of lines).
- **Memory MCP**: Knowledge graph persistence.
- **Sequential Thinking MCP**: Methodical problem-solving with revision loops.
- **Cloudflare Ecosystem** (16 servers): Workers, R2, D1, browser rendering.
- **Slack MCP**: Team messaging, channel management.

**Unique Feature:** Tool Search lazy-loads MCP schemas on-demand, reducing context usage by ~95% vs. dumping all tool definitions upfront.

---

## ALTERNATIVES CONSIDERED

### Alternative 1: Lightweight Hook-Based Automation (Instead of Full Orchestration)
**Why Rejected:** Hooks are fire-and-forget, no feedback loop. Swarm orchestration enables task decomposition, progress tracking, and failure recovery. Hooks can't handle complex workflows.

### Alternative 2: File-Based Memory (Instead of Knowledge Graphs)
**Why Rejected:** Kernel's agentdb is already file-based (SQLite). Knowledge graphs add semantic relationships and entity tracking that flat file storage can't do. Vector retrieval is qualitatively different.

### Alternative 3: Manual Cost Tracking via Logs
**Why Rejected:** Raw token counts don't correlate to cost or burn rate. Claudetop provides projections and alerts; manual logs require analysis. For teams, per-session visibility is critical.

---

## BIG 5 GUIDANCE FOR RECOMMENDED PLUGINS

### Input Validation
- **Ruflo (swarm):** Requires task spec format (JSON or structured text). Validate task decomposition doesn't exceed agent count limit.
- **Ralph Wiggum (loops):** Requires `--max-iterations` flag. Always validate iteration limit before autonomous execution.
- **Claude Command Suite:** Slash commands accept `$1, $2, $ARGUMENTS`. Sanitize git branch names, file paths in command arguments.

### Edge Cases
- **Persistent Memory:** Knowledge graphs handle relationship cycles, duplicate entities, and orphaned relationships. Test with circular references.
- **Cost Tracking:** Claudetop doesn't account for cache hit savings; analyze raw tokens vs. cache efficiency separately.
- **MCP Servers:** Tool Search doesn't load tool descriptions upfront—schema discovery happens on-demand. If tool doesn't exist, discovery fails silently; requires explicit error handling.

### Error Handling
- **Ruflo Swarms:** Track agent task failures independently. Swarm continues if one agent fails unless you configure `stop_on_first_failure`.
- **Ralph Loops:** Iteration limit reached → exits with "max iterations exceeded" message. No automatic fallback; requires explicit exit handler.
- **Hook Conflicts:** Multiple hooks on same event (e.g., PostToolUse) run sequentially. If first hook succeeds but second fails, only second failure appears in transcript. Chain hooks carefully.

### Duplication
- **Command Suite vs. Custom Slash Commands:** Claude Command Suite provides 216+ battle-tested commands. Before writing `/my-custom-command`, check if `/project:*` or `/dev:*` already solves it.
- **Memory Plugins:** Don't run multiple knowledge graphs simultaneously (claude-code-buddy + mcp-knowledge-graph). Pick one and use it exclusively to avoid duplicate facts and confusion.

### Complexity
- **Ruflo:** Enterprise-grade, suitable for 6+ team members. Overhead for solo projects. Consider Claude Swarm (simpler) or oh-my-claudecode (mid-size) instead.
- **Ralph Loops:** Simple for single-iteration tasks. Becomes complex if you chain loops (loop within loop). Keep loop logic at 1 level deep.
- **MCP Servers:** Each server adds a connection overhead (~500ms startup). For projects with 5+ MCP servers, use Tool Search to reduce context weight, not individual tool loading.

---

## GAPS FILLED VS. KERNEL

| Capability | Kernel | Community | Gap |
|---|---|---|---|
| Multi-agent swarms | Orchestrator framework | Ruflo, Claude Swarm | No distributed intelligence in kernel |
| Persistent memory | SQLite AgentDB (project-local) | Knowledge graphs + vectors | No semantic search or cross-session graphs |
| Autonomous loops | Manual re-prompting | Ralph Wiggum | No self-iterating without user intervention |
| Cost monitoring | Raw agentdb logs | Claudetop, ccusage | No per-session burn-rate alerts |
| Command library | Custom slash commands | Claude Command Suite (216+) | No out-of-the-box commands |
| Skill marketplace | Custom local skills | 2,811 pre-built skills (jeremylongshore) | No reusable packaged skills |
| MCP integrations | Basic MCP support | 50+ official + community servers | Community extends integrations |

---

## SOURCES

- [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) — Central hub for community innovations (21.6K stars)
- [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) — Official Anthropic plugin directory
- [anthropics/claude-plugins-community](https://github.com/anthropics/claude-plugins-community) — Community plugin marketplace (read-only mirror)
- [jeremylongshore/claude-code-plugins-plus-skills](https://github.com/jeremylongshore/claude-code-plugins-plus-skills) — 340 plugins + 2,811 skills library
- [qdhenry/Claude-Command-Suite](https://github.com/qdhenry/Claude-Command-Suite) — 216+ slash commands
- [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) — 100+ specialized subagents
- [ruvnet/ruflo](https://github.com/ruvnet/ruflo) — Enterprise swarm orchestration (5.2K stars)
- [affaan-m/claude-swarm](https://github.com/affaan-m/claude-swarm) — Terminal UI multi-agent coordination
- [dsifry/metaswarm](https://github.com/dsifry/metaswarm) — 18 agents, 13 skills, spec-driven development
- [PCIRCLE-AI/claude-code-buddy](https://github.com/PCIRCLE-AI/claude-code-buddy) — Knowledge graph persistent memory
- [shaneholloman/mcp-knowledge-graph](https://github.com/shaneholloman/mcp-knowledge-graph) — Anthropic reference knowledge graph MCP
- [Claudetop Real-Time Token Cost Monitor](https://agent-wars.com/news/2026-03-14-claudetop-real-time-token-cost-monitor-for-claude-code-sessions)
- [Claude Code Docs - Hooks Guide](https://code.claude.com/docs/en/hooks-guide)
- [Claude Code Docs - Agent Teams](https://code.claude.com/docs/en/agent-teams)
- [Claude Code Docs - MCP](https://code.claude.com/docs/en/mcp)
- [claudefa.st - 50+ Best MCP Servers for Claude Code in 2026](https://claudefa.st/blog/tools/mcp-extensions/best-addons)

---

**Research Confidence:** HIGH (11 sources, 10 community projects analyzed, plugin architecture cross-referenced against kernel-claude design)  
**Next Steps:** Evaluate Ruflo + Claude Swarm for orchestration gap. Pilot knowledge-graph memory plugin. Add Claudetop for cost visibility.
