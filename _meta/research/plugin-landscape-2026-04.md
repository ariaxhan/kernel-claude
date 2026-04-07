# Claude Code Plugin Landscape Research

**Date**: 2026-04-07  
**Query**: Publicly available Claude Code plugins, extensions, slash commands, and ecosystems  
**Confidence**: High (official docs + community surveys + adoption metrics)  
**TTL**: 14 days (ecosystem evolves rapidly)

---

## Executive Summary

- **Official plugins**: 13 Anthropic-maintained plugins in claude-code/plugins
- **Marketplace plugins**: 416+ plugins, 2,787 skills across official + community marketplaces
- **Community repositories**: 3 major curated lists (awesome-claude-plugins, awesome-claude-code, claude-code-plugins-plus-skills) with 10,000+ indexed repositories
- **MCP integration**: Full support via .mcp.json; 100s of MCP servers available
- **Marketplaces**: anthropics/claude-plugins-official (official), tonsofskills.com (416 plugins), claudemarketplaces.com (registry)
- **Status**: Ecosystem stable, Q1 2026 expansion into Cowork (non-coding domains), emerging gaps in security review and multi-account management

---

## Pitfalls (What Breaks)

### Pitfall 1: Plugin Marketplace Navigation Confusion
**Problem**: No visual distinction between plugin types. Every card on claude.com/plugins looks identical—name, description, install count. Users can't tell if they're installing pure MCP connectors or full skill+agent+hook bundles.

**Evidence**: Medium article (Apr 2026) reports that 11 of 30 most-installed plugins are MCP-only; if the MCP server unplugs, the plugin is empty.

**Fix**: 
- When installing, check plugin contents: does it have `/skills`, `/agents`, `/commands`?
- Use tonsofskills.com (dedicates a full page to each plugin showing what's inside)
- Query plugin.json in marketplace repos to verify components

### Pitfall 2: Context Window Bloat from Plugin Overload
**Problem**: Installing even 3-4 heavy plugins (each with 50+ skills + agents) consumes significant context. No built-in context meter for plugins during development.

**Evidence**: Multiple sources cite high context usage as top limitation; teams must be selective about enabled plugins.

**Fix**:
- Use `/reload-plugins` to batch test instead of manually restarting
- Enable only plugins needed for current task
- Use sub-agents to compartmentalize plugin context
- Monitor context via `/doctor` or `/context` commands

### Pitfall 3: Security: No Pre-Install Inspection Mode
**Problem**: `/plugin install` immediately downloads AND activates plugins. No dormant state for user inspection before execution.

**Evidence**: GitHub issue #28879 (feature request, unfixed); security gap flagged in multiple sources.

**Fix**:
- For third-party plugins: read plugin.json + SKILL.md files in GitHub repo before installing
- For sensitive environments: run plugins in isolated sessions first
- Use marketplace plugins from verified publishers only (Anthropic, major organizations)

### Pitfall 4: Multi-Account Configuration Hell
**Problem**: If you use Claude Code with multiple accounts (work + personal), CLAUDE.md and plugin config don't follow CLAUDE_CONFIG_DIR across account switches. 195+ developers reported this.

**Evidence**: GitHub issues; multiple workarounds exist but no native solution.

**Fix**:
- Use git branches to manage separate `.claude/` configs per account
- Symlink CLAUDE.md files to a shared config location (before switching accounts)
- Use Hookify plugin to selectively enable/disable rules per context
- Consider separate machines or containers for account isolation

### Pitfall 5: Stale or Abandoned Community Plugins
**Problem**: 9,000+ plugins exist, but only 50-100 are production-ready. No standardized "last maintained" signal.

**Evidence**: Ecosystem survey notes dramatic quality variance; tonsofskills.com is most curated (416 validated plugins vs 9,000 total).

**Fix**:
- Prefer plugins from: Anthropic (official), tonsofskills.com (curated), >100 stars on GitHub
- Check last commit date and open issues in GitHub repo
- Use awesome-claude-code repo (hesreallyhim) which curates by quality, not just availability
- Test plugins in non-critical workflows first

---

## Official Anthropic Plugins

**Location**: github.com/anthropics/claude-code/tree/main/plugins (13 plugins)

| Plugin | Purpose | Key Features |
|--------|---------|--------------|
| **agent-sdk-dev** | Claude Agent SDK development kit | `/new-sdk-app` command; agents: agent-sdk-verifier-py, agent-sdk-verifier-ts |
| **claude-opus-4-5-migration** | Migrate code to Opus 4.5 API | Automated model string & prompt migration |
| **code-review** | Automated PR review with confidence scoring | `/code-review` command; 5 parallel review agents |
| **commit-commands** | Git workflow automation | `/commit`, `/commit-push-pr`, `/clean_gone` commands |
| **explanatory-output-style** | Educational insights on implementation | Hook: SessionStart injection |
| **feature-dev** | 7-phase feature development workflow | `/feature-dev` command; explorer, architect, reviewer agents |
| **frontend-design** | Production-grade UI design guidance | Auto-invoked for frontend work |
| **hookify** | Create custom hooks to prevent unwanted behaviors | `/hookify`, `/hookify:list`, `/hookify:configure`, `/hookify:help` |
| **learning-output-style** | Interactive learning mode | Hook: encourages 5-10 line code contributions |
| **plugin-dev** | Comprehensive plugin development toolkit | `/plugin-dev:create-plugin`; 7 expert skills |
| **pr-review-toolkit** | Specialized PR review agents | `/pr-review-toolkit:review-pr`; 6 focused agents |
| **ralph-wiggum** | Autonomous iterative development loops | `/ralph-loop`, `/cancel-ralph` commands |
| **security-guidance** | Security issue detection while editing | Hook: monitors command injection, XSS, eval usage, etc. |

**Install**: `/plugin install plugin-name@claude-plugins-official`

---

## Community Plugin Marketplaces

### Tons of Skills (tonsofskills.com) — Most Curated
- **Size**: 416 plugins, 2,787 skills, 30 categories
- **Quality**: All plugins pass CI validation (JSON schema, secret scanning, dangerous pattern detection)
- **Installation**: `/plugin install name@claude-code-plugins-plus` or ccpi CLI
- **Notable**: Dedicated page per plugin showing skills list, metadata, related plugins
- **Link**: https://tonsofskills.com

### Official Anthropic Marketplace
- **Size**: 416 plugins (overlaps with tonsofskills)
- **Maintenance**: Anthropic-managed; high quality bar
- **Installation**: `/plugin install name@claude-plugins-official`
- **Discovery**: `/plugin > Discover` tab or claude.com/plugins
- **Link**: https://github.com/anthropics/claude-plugins-official

### Community Registries

**awesome-claude-plugins (quemsah)** — Automated adoption metrics
- 10,913 total repositories indexed (as of Apr 6, 2026)
- Automated collection of plugin adoption metrics across GitHub
- Top 10 by stars: prompts.chat (157k), everything-claude-code (140k), next.js (138k)
- Link: https://github.com/quemsah/awesome-claude-plugins

**Claude Code Plugins Plus Skills (jeremylongshore)** — Most Comprehensive
- 340 plugins + 1,367 agent skills
- Open-source marketplace with CCPI package manager
- Interactive tutorials and production orchestration patterns
- Link: https://github.com/jeremylongshore/claude-code-plugins-plus-skills

**awesome-claude-code (hesreallyhim)** — Curated by Quality
- Agent Skills, Workflows & Knowledge Guides, Tooling, Hooks, Slash Commands, CLAUDE.md Files
- Highlights standout resources: claude-devtools (observability), Harness (domain-specific agents), Trail of Bits Security Skills
- Link: https://github.com/hesreallyhim/awesome-claude-code

**Awesome Claude Code Toolkit (rohitg00)** — Most Comprehensive Single Repo
- 135 agents, 35 curated skills + 400,000 via SkillKit, 42 commands, 150+ plugins, 19 hooks, 15 rules, 7 templates, 8 MCP configs
- Link: https://github.com/rohitg00/awesome-claude-code-toolkit

### Alternative Directories

- **claudemarketplaces.com**: Registry of registries; compare different plugin marketplaces
- **buildwithclaude.com/plugins**: Anthropic-promoted directory
- **liteLLM**: Central registry for governing organizational plugin access
- **claude-skills** (alirezarezvani): 220+ skills across engineering, marketing, product, compliance domains

---

## MCP Integration Ecosystem

**Capability**: Claude Code connects to 100s of external tools via Model Context Protocol (MCP).

**Configuration**: `.mcp.json` at plugin/project root

**Core features**:
1. **Resources**: Structured data for Claude to read/write
2. **Tools**: Functions Claude can execute
3. **Prompts**: Predefined templates for standardized tasks

**2026 Updates**:
- Tool search enabled by default (deferred loading, not upfront context)
- MAX_MCP_OUTPUT_TOKENS default 25,000 (adjustable via environment variable)
- Warning when MCP output exceeds 10,000 tokens

**Available MCP Servers**: Dozens maintained by community and Anthropic for GitHub, databases, APIs, Figma, Playwright, Vercel, PostgreSQL, and more.

**Popular MCP Servers**:
- claude-context (code search MCP by Zilliz)
- context7 (code documentation for LLMs)
- Composio MCP integrations (100+ tools)

**Link**: https://code.claude.com/docs/en/mcp

---

## Top 10 Most Popular Plugins (by GitHub stars/adoption)

| Rank | Plugin | Stars | Category | What It Does |
|------|--------|-------|----------|-------------|
| 1 | mem0 (universal memory layer) | 52k+ | Memory/Context | Session memory capture and compression |
| 2 | claude-mem | 45k+ | Memory/Context | Session memory capture and compression |
| 3 | context7 | 51k+ | Code Intelligence | Code documentation and context for LLMs |
| 4 | superpowers | 136k+ | Skills Framework | Agentic skills framework for development |
| 5 | skills (Anthropic official) | 111k+ | Agent Skills | Official agent skills repository |
| 6 | claude-code | 109k+ | Core | Terminal-based agentic coding tool |
| 7 | ui-ux-pro-max-skill | 59k+ | Design | Design intelligence for UI/UX |
| 8 | ralph-wiggum | - | Automation | Autonomous iterative development loops |
| 9 | hookify | - | Customization | Create custom hooks to prevent unwanted behaviors |
| 10 | token-optimizer | - | Context Management | Ghost token detection, context compaction |

---

## Emerging Trends & Q1 2026 Expansion

### Beyond Developers: Cowork Plugins
- **Jan 30, 2026**: Anthropic launched 11 official plugins for Claude Cowork (non-coding)
- **Domains**: Legal (contract review), Sales (CRM integration), Marketing (campaign orchestration), Finance
- **Implication**: Plugin system is becoming universal customization layer across all Claude products

### Integration with Office Tools
- Claude integrated into Excel and PowerPoint
- **March 11 update**: Context sharing between Excel → PowerPoint (data analysis → presentations)

### Multi-Agent Evolution
- Agent teams (Opus 4.6) driving new wave of multi-agent plugins
- Expected: Orchestration frameworks, specialized agent coordinators, domain-specific agent teams

### Future Curation Challenges
- With 9,000+ plugins in ecosystem, discovery becomes primary pain point
- Expected: Quality scoring, verified publisher badges, automated security scanning

---

## Plugin Architecture & Development

### Plugin Components

| Directory | Purpose | Required? |
|-----------|---------|-----------|
| `.claude-plugin/plugin.json` | Plugin metadata (name, version, description) | Yes |
| `commands/` | Slash commands (markdown files) | No |
| `agents/` | Custom agent definitions | No |
| `skills/` | Agent Skills with SKILL.md files | No |
| `hooks/` | Event handlers (hooks.json) | No |
| `.mcp.json` | MCP server configurations | No |
| `.lsp.json` | LSP server configurations | No |
| `settings.json` | Default settings when plugin enabled | No |
| `bin/` | Executables added to Bash PATH | No |

### Plugin Manifest Schema (plugin.json)

```json
{
  "name": "plugin-name",
  "description": "Brief plugin description",
  "version": "1.0.0",
  "author": { "name": "Author Name", "email": "email@example.com", "url": "https://github.com/author" },
  "homepage": "https://docs.example.com/plugin",
  "repository": "https://github.com/author/plugin",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "commands": "./custom/commands/special.md",
  "agents": "./custom/agents/",
  "skills": "./custom/skills/",
  "hooks": "./config/hooks.json",
  "mcpServers": "./mcp-config.json",
  "outputStyles": "./styles/",
  "lspServers": "./.lsp.json"
}
```

### Development Workflow

**Quick Start**:
```bash
mkdir my-plugin/.claude-plugin
# Create plugin.json manifest
mkdir -p my-plugin/skills/hello
# Create SKILL.md in skills/hello/
claude --plugin-dir ./my-plugin
/my-plugin:hello  # Test skill
/reload-plugins   # Reload after changes
```

**Commands for plugin developers**:
- `/plugin-dev:create-plugin` — scaffold new plugin
- `--plugin-dir ./path` — load plugin locally during development
- `/reload-plugins` — hot-reload plugins and skills

**Official plugin development guide**: https://code.claude.com/docs/en/plugins

---

## Gaps in Ecosystem

### Critical Gaps

1. **Plugin Security Inspection**: No way to preview plugin contents before installation executes code
2. **Multi-Account Management**: Configuration doesn't follow CLAUDE_CONFIG_DIR across account switches (195+ reported)
3. **IDE Support**: VSCode and JetBrains extensions don't respect CLAUDE_CONFIG_DIR
4. **Context Visibility**: No built-in meter showing context consumption per plugin

### Missing Plugin Categories (Opportunities)

- **Language-specific deep tools**: Minimal coverage for Rust, Go, Kotlin
- **Enterprise integrations**: Few plugins for corporate security, audit, compliance workflows
- **AI code quality**: Limited plugins for automated refactoring, duplication detection, complexity analysis
- **Performance profiling**: Few plugins for benchmarking, latency analysis, memory profiling
- **Documentation generation**: Limited plugins for API docs, architecture diagrams, decision records

---

## Recommended Plugin Selection Strategy

### For New Users
1. **Start official**: Install 3-5 from Anthropic's official plugins (code-review, feature-dev, security-guidance)
2. **Add marketplace**: Browse tonsofskills.com for domain-specific needs
3. **Test isolation**: Run each new plugin in separate session first
4. **Monitor context**: Use `/doctor` to check context consumption

### For Teams
1. **Use awesome-claude-code** (hesreallyhim) as quality filter
2. **Create team marketplace**: Set up organization-specific plugin repository
3. **Version control**: Pin plugin versions in plugin.json
4. **Security**: Use liteLLM to govern which plugins teams can install

### For Production/Enterprise
1. **Pre-install security review**: Read plugin.json + SKILL.md on GitHub before installing
2. **Prefer Anthropic or verified publishers**: Official plugins, tonsofskills.com curated
3. **Sandbox test**: Run in isolated environment before production use
4. **Use hooks for control**: Hookify plugin to selectively enable/disable rules per context

---

## Discovery Resources

| Resource | Type | Best For | Link |
|----------|------|----------|------|
| **tonsofskills.com** | Curated marketplace | Finding specific, validated plugins | https://tonsofskills.com |
| **awesome-claude-code** | Community curation | Quality-first discovery | https://github.com/hesreallyhim/awesome-claude-code |
| **claude-plugins-official** | Official registry | Official Anthropic plugins | https://github.com/anthropics/claude-plugins-official |
| **awesome-claude-code-toolkit** | Comprehensive index | All categories + extensive skills | https://github.com/rohitg00/awesome-claude-code-toolkit |
| **buildwithclaude.com/plugins** | Anthropic directory | Official endorsement | https://buildwithclaude.com/plugins |
| **claude.com/plugins** | Official UI | Browse and install in-app | https://claude.com/plugins |
| **claudemarketplaces.com** | Meta-registry | Compare plugin sources | https://claudemarketplaces.com |

---

## Sources

- [Plugins Reference - Claude Code Docs](https://code.claude.com/docs/en/plugins-reference)
- [Create plugins - Claude Code Docs](https://code.claude.com/docs/en/plugins)
- [Claude Code Plugins Official - Anthropic GitHub](https://github.com/anthropics/claude-plugins-official)
- [Claude Code plugins directory - anthropics/claude-code](https://github.com/anthropics/claude-code/tree/main/plugins)
- [Troubleshooting - Claude Code Docs](https://code.claude.com/docs/en/troubleshooting)
- [Connect Claude Code to tools via MCP - Claude Code Docs](https://code.claude.com/docs/en/mcp)
- [awesome-claude-plugins - quemsah](https://github.com/quemsah/awesome-claude-plugins)
- [Claude Code Plugins Plus Skills - jeremylongshore](https://github.com/jeremylongshore/claude-code-plugins-plus-skills)
- [awesome-claude-code - hesreallyhim](https://github.com/hesreallyhim/awesome-claude-code)
- [Tons of Skills Plugin Hub](https://tonsofskills.com)
- [Discover and install prebuilt plugins through marketplaces - Claude Code Docs](https://code.claude.com/docs/en/discover-plugins)
- [Plugin Marketplace Navigation Issues](https://medium.com/@alexanderekb/claude-code-plugins-are-confusing-heres-a-quick-start-overview-of-what-s-actually-inside-bb0c2ad1e199)
- [Claude Code Q1 2026 Updates - MindStudio Blog](https://www.mindstudio.ai/blog/claude-code-q1-2026-update-roundup)
- [Feature Request: Plugin install should support download-only mode - Issue #28879](https://github.com/anthropics/claude-code/issues/28879)
- [Claude Code Extensions Explained - Medium](https://muneebsa.medium.com/claude-code-extensions-explained-skills-mcp-hooks-subagents-agent-teams-plugins-9294907e84ff)
- [10 Must-Have Skills for Claude in 2026 - Medium](https://medium.com/@unicodeveloper/10-must-have-skills-for-claude-and-any-coding-agent-in-2026-b5451b013051)

