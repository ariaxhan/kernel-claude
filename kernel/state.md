# Kernel State
<!-- Auto-updated by modes and agents. Do not edit structure. Add content to slots. -->

## Repo Map (max 15 lines)

- Entry: kernel-claude (Claude Code plugin, not executable)
- Plugin interface: commands/, agents/, skills/, hooks/ (root-level, auto-discovered)
- Self-config: .claude/ (rules, settings — KERNEL's own project config)
- Templates: kernel/ (banks, rules, skills, hooks, project-notes — for /repo-init distribution)
- Banks: kernel/banks/ (10 methodology templates)
- Meta: _meta/ (session, learnings, context, benchmark)
- Memory: memory/ (config registry)
- Plugin: .claude-plugin/ (plugin.json, marketplace.json)
- Docs: README.md

## Tooling Inventory (max 10 tools)
| Tool | Command | Status |
|------|---------|--------|
| Formatter | N/A (markdown project) | N/A |
| Linter | N/A | N/A |
| Typecheck | N/A | N/A |
| Tests | N/A (documentation project) | N/A |
| Git | git | available |
| Hooks | hooks/hooks.json + .claude/settings.json | 2 hooks active |

## Conventions (max 10 bullets)

- Naming: kebab-case for files, SCREAMING-CAPS for banks
- Frontmatter: YAML with name, model, description (agents) or description, allowed-tools (commands)
- Structure: root-level for plugin components, .claude/ for self-dev config, kernel/ for distributable templates
- Syntax: Compact Unicode markers (Ψ, →, ≠, Σ, Φ, Ω, Ξ, Δ, ∇, Γ) in CLAUDE.md
- Inline rules: ●rule_name|condition→action
- Slots: Explicit caps (max N items) to prevent bloat
- Template notice: warning at bottom of all template files
- Markdown: GitHub-flavored, code blocks with language tags

## Last Validation
- Date: 2026-01-28
- Status: v4.1.0 — plugin structure fix
- Changes: Moved commands/, agents/, skills/ to root level for plugin discovery

## Active Preferences
→ See .claude/rules/preferences.md

## Git Workflow State
- current_branch: main
- branch_type: null
- branch_created: null
- last_commit: null
- uncommitted: true (v4.0.0 changes)

## Documentation State
- docs_style: REFERENCE
- doc_kinds: [reference, how-to]
- last_audit: 2026-01-28
- exceptions: []

## Recent Decisions (max 5, link to decisions.md for full log)

1. 2026-01-28: Adopted compact Unicode syntax from ARIA/NEXUS config hierarchy
2. 2026-01-28: Integrated NEXUS features (model routing, keywords, autonomy) into standalone plugin
3. 2026-01-28: Added hooks system for auto-detection and auto-validation
4. 2026-01-28: Swapped worktree-parallelization skill for coding-prompt-bank (more foundational)
5. 2026-01-28: Added /design and /repo-init commands from CodingVault

## Do Not Touch (max 5 bullets)

- kernel/banks/ — methodology templates distributed to all projects
- .claude-plugin/ — plugin registration metadata
- _meta/ structure — session tracking contract
- CLAUDE.md compact syntax — carefully crafted token budget

---
This file is the shared world model. Every mode and agent reads this on activation.
Update when reality changes: discovered tooling, confirmed conventions, new decisions.
Respect slot caps. If full, move oldest/least relevant to .claude/rules/ or replace.
