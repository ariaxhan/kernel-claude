# KERNEL Plugin Session Context

tokens: ~200 | type: context | evolving

---

**Current state of work on this project.**

## Active Work

| Branch | Status | Next |
|--------|--------|------|
| main | v4.0.0 in progress | Release + GitHub tag |

## Recent Decisions

- 2026-01-28: v4.0.0 — Compact Unicode syntax, full NEXUS feature integration, hooks, design system
- 2026-01-28: Adopted Ψ/→/≠/Σ/Φ/Ω/Ξ/Δ/∇/Γ section markers from ARIA config
- 2026-01-28: Added 5-tier model routing (Ollama → Gemini → Sonnet → Opus → Haiku)
- 2026-01-28: Added hooks system (SessionStart + PostToolUse)
- 2026-01-28: Swapped worktree-parallelization skill for coding-prompt-bank
- 2026-01-28: Added /design and /repo-init commands, frontend-conventions rule
- 2026-01-28: Restructured to .claude/ convention + skills (v3.0.0)
- 2026-01-19: Added benchmark system for performance tracking
- 2026-01-17: Released v2.0.0 with agents, skills, rules, commands

## Blockers

None currently.

## Infrastructure Notes

- Plugin type: Claude Code plugin
- Version: 4.0.0
- Structure: .claude/ convention (agents, commands, rules, skills, hooks)
- Parent vault: CodingVault
- Repo: https://github.com/ariaxhan/kernel-claude

## Component Counts

| Component | Count |
|-----------|-------|
| Commands | 16 |
| Rules | 13 |
| Banks | 10 |
| Agents | 19 |
| Skills | 3 |
| Hooks | 2 |

---

*This is read at session start to restore context. Update before ending sessions.*
