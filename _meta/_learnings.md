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
