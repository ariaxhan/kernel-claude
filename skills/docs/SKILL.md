---
name: docs
description: Documentation mode - audit, generate, maintain docs
triggers:
  - docs
  - documentation
  - document this
  - write docs
  - update docs
  - docs audit
---

# Documentation Skill

## Purpose

Every word is a liability. Every missing concept is also a liability. Find the balance.

**Key Concept**: Progressive reveal - scannable surface, depth on demand. Docs are code - treat with same rigor.

---

## Auto-Trigger Signals

This skill activates when detecting:
- "docs", "documentation", "document this"
- "write docs", "update docs"
- "docs audit", "stale docs"
- "README", "CHANGELOG"

---

## State Schema

Record in `kernel/state.md` on first run:

```yaml
docs_style: null          # REFERENCE | PROCEDURAL | NARRATIVE
doc_kinds_enabled: []     # tutorial, how-to, reference, explanation
audiences: []             # end-user, developer, contributor
prose_format: standard    # standard | semantic-line-breaks
last_full_audit: null     # ISO date
```

---

## Two-Axis System

### Axis 1: Doc Kind (Purpose)

| Kind | Purpose | Reader State |
|------|---------|--------------|
| tutorial | Learning by doing | "Teach me" |
| how-to | Solve specific problem | "Help me do X" |
| reference | Technical lookup | "What are the details" |
| explanation | Conceptual understanding | "Help me understand why" |

### Axis 2: Docs Style (Format)

| Style | Best For | Signal Patterns |
|-------|----------|-----------------|
| REFERENCE | APIs, libraries, SDKs | Many exports, JSDoc present |
| PROCEDURAL | CLIs, tools, configs | CLI entry point, config files |
| NARRATIVE | Architecture, concepts | ADRs exist, interconnected concepts |

---

## Universal Rules

### Required Frontmatter

```yaml
---
doc_kind: how-to           # tutorial | how-to | reference | explanation
depends_on:                 # source files this doc describes
  - src/api/auth.ts
review_cadence: 90          # days between forced reviews
last_reviewed: 2025-01-10   # ISO date
owners: ["@username"]       # notification targets
---
```

### Information Scent Header

First two lines after frontmatter:

```markdown
# Title
One-sentence purpose. Use when: X. Avoid when: Y.
```

Reader gets value in 2 seconds. No exceptions.

---

## Budgets

| Metric | Target | Hard Max |
|--------|--------|----------|
| File length | 150 lines | 220 lines |
| Headings per file | 8 | 12 |
| Code block lines | 15 | 30 |
| Paragraph words | 50 | 80 |
| See Also links | 3 | 7 |
| List items | 5 | 9 |

Exceeding hard max requires documented exception.

---

## Structure

```
LINE 1: Title (H1, one per file)
LINE 2: Purpose + Use when / Avoid when
BREAK
BODY: Details in descending importance
FOOTER: See Also (2-5 links)
```

---

## Heading Rules

- H1: one per file (title)
- H2: primary sections
- H3: allowed freely in PROCEDURAL; sparingly elsewhere
- H4+: never; split file instead
- Max 12 headings total

---

## Anti-Patterns

NEVER:
- "This document explains..." (just explain)
- "You might be wondering..." (answer asked questions only)
- Inline version history (use CHANGELOG)
- Roadmap promises in docs
- Prerequisites lists > 3 items (link to setup doc)
- Inline TOCs in leaf pages

---

## Doc Graph Contract

```
docs/
  index.md              # Canonical TOC, links all docs
  MAINTENANCE.md        # Review log
  paths/                # Curated reading paths
    quickstart.md
    concepts.md
    troubleshooting.md
  tutorials/
  how-to/
  reference/
  explanation/
```

---

## Maintenance System

### Staleness Triggers

Doc marked stale when ANY true:
1. Any `depends_on` file modified after `last_reviewed`
2. Days since `last_reviewed` exceeds `review_cadence`
3. Referenced version < current release version
4. Breaking change in CHANGELOG since `last_reviewed`

### Review Process

1. Check content accuracy against dependencies
2. Update `last_reviewed` date in frontmatter
3. Add entry to `docs/MAINTENANCE.md`
4. If no changes needed, log "Verified accurate"

---

## Lint Rules

**Structure Checks:**
```
□ Frontmatter present and complete
□ Information scent header
□ See Also section with 2-5 links
□ No orphan docs
□ Bidirectional links valid
```

**Budget Checks:**
```
□ File length <= 220 lines
□ Heading count <= 12
□ Code blocks <= 30 lines
□ Paragraphs <= 80 words
□ Lists <= 9 items
```

---

## Modes

**Documentation Mode:**
1. Read state.md for docs_style
2. If missing, select using signal patterns
3. Build doc graph, ensure no orphans
4. Generate/refactor using style + budgets
5. Run lint checks

**Docs Audit Mode:**
1. Produce report: orphans, broken links, budget violations, stale docs
2. Output prioritized fix plan

**Maintenance Mode:**
1. Identify stale docs
2. Review against current source
3. Update content and frontmatter
4. Log in MAINTENANCE.md

---

## Anti-Patterns

- Documentation without structure
- No maintenance plan
- Orphan docs
- Stale content
- Violating budgets without exception

---

## Success Metrics

Docs are working well when:
- Every doc has clear purpose
- No orphan docs
- Staleness is tracked
- Budgets are respected
- Links are bidirectional
