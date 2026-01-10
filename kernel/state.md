# Kernel State
<!-- Auto-updated by modes and agents. Do not edit structure. Add content to slots. -->

## Repo Map (max 15 lines)
[TO DISCOVER: entrypoints, module boundaries, key directories]

- Entry: kernel-plugin (Claude Code plugin, not executable)
- Core modules: kernel/ (template files), .claude/ (KERNEL's own config)
- Templates: kernel/banks/ (5 banks), kernel/commands/ (10 commands), kernel/hooks/ (3 hooks)
- Docs: README.md, SETUP.md, CONFIG-TYPES.md
- MCP: claude-docs-server.py, .mcp.json
- Config: .claude/rules/ (preferences, invariants, patterns, decisions)

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
[TO DISCOVER: naming patterns, error handling, logging, config management]

- Naming: kebab-case for markdown files (discover.md, plan.md), SCREAMING-CAPS for banks (DISCOVERY-BANK.md)
- Files: Descriptive frontmatter with description field
- Structure: Template notice (⚠️) at bottom of all template files
- Slots: Explicit caps (max N items) to prevent bloat
- Markdown: GitHub-flavored markdown, code blocks with language tags
- Organization: kernel/ for templates, .claude/ for KERNEL's own config

## Last Validation
- Date: 2026-01-10
- Status: Discovery complete, state populated
- Command: /discover

## Active Preferences
→ See .claude/rules/preferences.md

## Git Workflow State
- current_branch: main
- branch_type: null      # feat | fix | docs | refactor | test | chore
- branch_created: null   # ISO date
- last_commit: null      # ISO date
- uncommitted: false

## Documentation State
- docs_style: null  # REFERENCE | PROCEDURAL | NARRATIVE (set once, lock)
- doc_kinds: []     # tutorial, how-to, reference, explanation
- last_audit: null  # ISO date
- exceptions: []    # budget violations with rationale

## Recent Decisions (max 5, link to decisions.md for full log)
[TO POPULATE: as architecture decisions are made]

1. 2026-01-10: Replaced heavy banks (2000+ tokens) with slotted templates (500-800 tokens)
2. 2026-01-10: Introduced kernel/state.md as single source of truth (prevents drift)
3. 2026-01-10: Modes activate thinking styles (~30 tokens) instead of procedures (~400 tokens)
4. 2026-01-10: Rules start empty, grow from confirmation (not prescriptive)
5. 2026-01-10: Total baseline cost: ~330 tokens (vs ~560 previous, ~6000 original)

## Do Not Touch (max 5 bullets)
[TO DISCOVER: migrations, auth, critical paths, data schemas]

- kernel/ directory - template files distributed to all projects via /kernel-init
- .claude/CLAUDE.md - philosophy anchor (150 tokens, carefully crafted)
- kernel/state.md - shared world model (update via modes, not manually)

---
⚠️ **TEMPLATE NOTICE**
This file is the shared world model. Every mode and agent reads this on activation.
Update when reality changes: discovered tooling, confirmed conventions, new decisions.
Respect slot caps. If full, move oldest/least relevant to .claude/rules/ or replace.
