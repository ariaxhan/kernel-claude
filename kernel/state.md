# Kernel State
<!-- Auto-updated by modes and agents. Do not edit structure. Add content to slots. -->

## Repo Map (max 15 lines)
- Entry: Claude Code plugin (distributed via marketplace, not executable)
- Plugin manifest: .claude-plugin/plugin.json (v1.1.0), .claude-plugin/marketplace.json
- Core templates: kernel/ (copied to projects during /kernel-init)
  - kernel/banks/ (5 banks: PLANNING, DEBUGGING, DISCOVERY, REVIEW, DOCUMENTATION - 698 lines total)
  - kernel/commands/ (9 mode commands: discover, plan, debug, review, docs, branch, ship, parallelize, handoff)
  - kernel/hooks/ (3 hook templates)
  - kernel/rules/ (rule templates)
- All commands: kernel/commands/ (10 total: 2 setup, 4 dev workflow, 4 git workflow)
- Documentation: docs/COMMANDS.md (reference), README.md (overview), SETUP.md (how-to), CONFIG-TYPES.md (guide)
- MCP server: claude-docs-server.py (Python 3.8+, optional)
- Memory: memory/config_registry.jsonl (tracks artifact usage for pruning)
- Sample project: sample-project/ (demo with Python task manager)
- KERNEL's own config: .claude/ (skills, agents, rules, settings)

## Tooling Inventory (max 10 tools)
| Tool | Command | Status |
|------|---------|--------|
| Formatter | N/A (markdown project) | N/A |
| Linter | N/A | N/A |
| Typecheck | N/A | N/A |
| Tests | N/A (documentation project) | N/A |
| Package mgr | npm (for MCP server) | ✓ available |
| Build | N/A | N/A |
| Git | git | ✓ available |
| Python | python3 (for MCP server) | ✓ available |

## Conventions (max 10 bullets)
- **Naming**: kebab-case for commands (discover.md, kernel-init.md), SCREAMING-CAPS for banks (PLANNING-BANK.md)
- **Frontmatter**: All commands have `description:` field, banks have philosophy + slots
- **Structure**: Template notice (⚠️) at bottom of template files, slots marked with caps (max N)
- **Documentation**: PROCEDURAL style, line 2 rule (purpose + use when/avoid when)
- **Versioning**: Semantic versioning in plugin.json (currently 1.1.0)
- **Commands**: Plugin commands in commands/, template commands in kernel/commands/
- **Organization**: kernel/ = templates for distribution, .claude/ = KERNEL's own config
- **Banks**: Token-optimized (500-800 tokens each vs 2000+ before), loaded on-demand only
- **State management**: kernel/state.md is single source of truth, updated by modes
- **Git workflow**: Branch-first (NEVER WORK ON MAIN), conventional commits, ship via PR

## Last Validation
- Date: 2026-01-10
- Status: Discovery complete, documentation mode complete, state fully populated
- Commands: /docs (documentation audit), /discover (full reconnaissance)
- Uncommitted changes: docs/COMMANDS.md added, docs/documentation-files/ removed, README.md updated

## Active Preferences
→ See .claude/rules/preferences.md

## Git Workflow State
- current_branch: main
- branch_type: null      # feat | fix | docs | refactor | test | chore
- branch_created: null   # ISO date
- last_commit: null      # ISO date
- uncommitted: false

## Documentation State
- docs_style: PROCEDURAL  # Plugin with CLI commands, config files, setup workflows
- doc_kinds: [reference, how-to]  # COMMANDS.md (reference), SETUP.md (how-to)
- last_audit: 2026-01-10  # ISO date
- exceptions: []  # budget violations with rationale

## Recent Decisions (max 5, link to decisions.md for full log)
[TO POPULATE: as architecture decisions are made]

1. 2026-01-10: Replaced heavy banks (2000+ tokens) with slotted templates (500-800 tokens)
2. 2026-01-10: Introduced kernel/state.md as single source of truth (prevents drift)
3. 2026-01-10: Modes activate thinking styles (~30 tokens) instead of procedures (~400 tokens)
4. 2026-01-10: Rules start empty, grow from confirmation (not prescriptive)
5. 2026-01-10: Total baseline cost: ~330 tokens (vs ~560 previous, ~6000 original)

## Do Not Touch (max 5 bullets)
- kernel/ directory - template files distributed to all projects via /kernel-init
- kernel/banks/ - token-optimized methodology banks (698 lines total, carefully balanced)
- .claude-plugin/plugin.json - plugin manifest (version, metadata)
- CLAUDE.md, kernel/CLAUDE.md - philosophy anchors (~150 tokens each)
- kernel/state.md - shared world model (update via modes, not manual edits)

---
⚠️ **TEMPLATE NOTICE**
This file is the shared world model. Every mode and agent reads this on activation.
Update when reality changes: discovered tooling, confirmed conventions, new decisions.
Respect slot caps. If full, move oldest/least relevant to .claude/rules/ or replace.
