# KERNEL Plugin Learnings

tokens: ~200 | type: log | append-only

---

**Living log of everything we learn while developing this plugin.** Every insight, pattern, gotcha, and fix gets captured here then routed to appropriate configs.

## Format

```markdown
## {date}
**Context:** {feature/component}
**Type:** pattern | gotcha | fix | optimization | problem
**Changed:** {file path or N/A}
**What:** {brief description}
**Why:** {rationale}
**Applied to:** {which rules/banks/configs updated}
```

## Learnings

<!-- append new learnings here, newest at top -->

## 2026-01-17
**Context:** Project structure
**Type:** pattern
**Changed:** Created _meta/ structure
**What:** Aligned with CodingVault _meta system for session tracking and learnings
**Why:** Need centralized logging of changes, problems, decisions. aws-aoh-hackathon reference showed value of research directories and session context.
**Applied to:** _meta/_session.md, _meta/_learnings.md, _meta/context/active.md, _meta/INDEX.md

---

*This file is the source of truth for project evolution. When we learn, we log here FIRST, then update configs.*
