# Documentation Bank

## Philosophy

Every word is a liability.
Every missing concept is also a liability.
Find the balance.

Progressive reveal: scannable surface, depth on demand.
Optimize for humans AND tokens.
Docs are code; treat them with the same rigor.

---

## State Schema

Record in `kernel/state.md` on first run. Lock unless user requests change.

```yaml
# Documentation State
docs_style: null          # REFERENCE | PROCEDURAL | NARRATIVE
doc_kinds_enabled: []     # tutorial, how-to, reference, explanation
audiences: []             # end-user, developer, contributor
prose_format: standard    # standard | semantic-line-breaks
ruleset_version: 1
last_full_audit: null     # ISO date
exceptions: []            # documented deviations from budgets
```

---

## Two-Axis System

Separate **purpose** (what the doc is for) from **format** (how it's structured).

### Axis 1: Doc Kind (Purpose)

Every doc declares one `doc_kind` in frontmatter.

| Kind | Purpose | Reader State |
|------|---------|--------------|
| tutorial | Learning by doing | "Teach me" |
| how-to | Solve specific problem | "Help me do X" |
| reference | Technical lookup | "What are the details" |
| explanation | Conceptual understanding | "Help me understand why" |

### Axis 2: Docs Style (Format)

Selected once per repo based on signals. Applies to all docs.

| Style | Best For | Signal Patterns |
|-------|----------|-----------------|
| REFERENCE | APIs, libraries, SDKs | Many exports, JSDoc present, "api" in filenames |
| PROCEDURAL | CLIs, tools, configs | CLI entry point, config files, setup scripts |
| NARRATIVE | Architecture, concepts | ADRs exist, interconnected concepts, "why" in issues |

### Selection Process

```
1. Scan: file count, exports, CLI presence, config schemas
2. Check: existing docs quality, README structure
3. Identify: primary audience from repo signals
4. Match: strongest signal pattern wins
5. Record: docs_style + selection_rationale in state.md
6. Lock: do not revisit unless user says "change docs style"
```

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

First two lines of every doc (after frontmatter):

```markdown
# Title
One-sentence purpose. Use when: X. Avoid when: Y.
```

Reader gets value in 2 seconds. No exceptions.

### Budgets (Not Hard Caps)

| Metric | Target | Hard Max | Escalation |
|--------|--------|----------|------------|
| File length | 150 lines | 220 lines | Split or document exception in state.md |
| Headings per file | 8 | 12 | Restructure or split |
| Code block lines | 15 | 30 | Link to source for longer |
| Paragraph words | 50 | 80 | Break into multiple paragraphs |
| See Also links | 3 | 7 | Must include parent or sibling |
| List items | 5 | 9 | Chunk or restructure |

Exceeding hard max requires documented exception with rationale.

### Structure

```
LINE 1: Title (H1, one per file)
LINE 2: Purpose + Use when / Avoid when
BREAK
BODY: Details in descending importance
FOOTER: See Also (2-5 links)
```

### Heading Rules

- H1: one per file (title)
- H2: primary sections
- H3: allowed freely in PROCEDURAL style; sparingly elsewhere
- H4+: never; split file instead
- Max 12 headings total per file

### Formatting

- No emojis, decorative elements
- No bold within paragraphs (headers do the work)
- Code blocks: language-tagged
- Tables: comparison only, not decoration
- Status badges: max 2, only if they answer user questions (build status, version)

### Linking

- Inline links with descriptive text: `[auth flow](./auth.md)`
- Bidirectional: if A links B, B links A
- No orphan docs (every file reachable from index)
- Footer: `## See Also` required

### Naming

- Lowercase, hyphens: `auth-flow.md`
- Noun or verb-noun: `errors.md`, `configure-auth.md`
- No `-guide`, `-documentation`, `-overview` suffixes

### Prose Format Options

**Standard** (default): Normal paragraphs.

**Semantic line breaks** (opt-in via `prose_format: semantic-line-breaks`):
Each sentence on its own line.
Improves diffs, review, and agent editing.
Renders identically.

---

## Anti-Patterns (Never)

- "This document explains..." (just explain)
- "You might be wondering..." (answer asked questions only)
- Inline version history (use CHANGELOG)
- Roadmap promises in docs
- Prerequisites lists > 3 items (link to setup doc instead)
- Inline TOCs in leaf pages (use index pages as TOCs)

---

## Style Specifications

### REFERENCE Style

For lookup-optimized docs. APIs, libraries, SDKs.

```markdown
---
doc_kind: reference
depends_on: [src/api/module.ts]
review_cadence: 90
last_reviewed: 2025-01-10
owners: ["@maintainer"]
---

# Module Name
One-sentence purpose. Use when: need X capability. Avoid when: Y.

## Overview
Most important information first. 2-3 paragraphs max.

## API

### function_name(params)
Brief description.
- `param`: type, purpose
- Returns: type, meaning

## See Also
- [Related A](./a.md)
- [Parent](../index.md)
```

### PROCEDURAL Style

For task-optimized docs. CLIs, tools, configs.

```markdown
---
doc_kind: how-to
depends_on: [src/cli/main.ts]
review_cadence: 60
last_reviewed: 2025-01-10
owners: ["@maintainer"]
---

# Task Name
One-sentence purpose. Use when: need to accomplish X. Avoid when: Y applies.

## Prerequisites
- Item 1
- Item 2 (max 3; link to setup doc for more)

## Steps

### 1. First Step
Action. Expected result.

### 2. Second Step
Action. Expected result.

## Common Failures

### Error: Message
Cause. Fix.

## See Also
- [Next task](./next.md)
- [Troubleshooting](./troubleshooting.md)
```

### NARRATIVE Style

For understanding-optimized docs. Architecture, concepts.

```markdown
---
doc_kind: explanation
depends_on: []
review_cadence: 120
last_reviewed: 2025-01-10
owners: ["@maintainer"]
---

# Concept Name
One-sentence purpose. Use when: need mental model of X. Avoid when: just need to do Y.

## Key Points
- Point 1 (one line)
- Point 2 (one line)
- Point 3 (one line)

## Context
Why this exists. 2-3 paragraphs.

## How It Works
Mechanics. Diagrams if helpful.

## Tradeoffs
What we chose and why. What we didn't choose.

## See Also
- [Related concept](./related.md)
- [Implementation reference](./api.md)
```

---

## Doc Graph Contract

### Required Structure

```
docs/
├── index.md              # Canonical TOC, links all docs
├── MAINTENANCE.md        # Review log
├── paths/                # Curated reading paths
│   ├── quickstart.md
│   ├── concepts.md
│   └── troubleshooting.md
├── tutorials/
├── how-to/
├── reference/
└── explanation/
```

### index.md Requirements

- Lists every doc in repo
- Shows parent-child relationships
- Orphan = build failure
- Updated automatically or manually on every doc change

### Reading Paths

Short curated entry points for different needs:
- `quickstart.md`: do the thing (links to key how-tos)
- `concepts.md`: mental model (links to explanations)
- `troubleshooting.md`: failure modes (links to error docs)

Each path is < 50 lines, points to leaf pages.

---

## Maintenance System

### Staleness Triggers

Doc marked stale when ANY condition true:
1. Any `depends_on` file modified after `last_reviewed`
2. Days since `last_reviewed` exceeds `review_cadence`
3. Referenced version < current release version
4. Breaking change in CHANGELOG since `last_reviewed`

### Review Process

1. Check content accuracy against dependencies
2. Update `last_reviewed` date in frontmatter
3. Add entry to `docs/MAINTENANCE.md`
4. If no changes needed, log "Verified accurate"

### MAINTENANCE.md Format

```markdown
# Documentation Maintenance Log

## Log

| Date | Doc | Reviewer | Trigger | Changes |
|------|-----|----------|---------|---------|
| 2025-01-10 | auth.md | @aria | dep:auth.ts | Updated token format |
| 2025-01-08 | config.md | @aria | cadence | Verified accurate |

## Upcoming Reviews

Generated by lint. Do not edit manually.

## Exceptions

| Doc | Budget | Actual | Rationale | Approved |
|-----|--------|--------|-----------|----------|
| setup.md | 150 lines | 180 lines | Complex multi-platform setup | 2025-01-05 |
```

### Sync Triggers (Code Changes That Require Doc Updates)

```yaml
triggers:
  immediate:
    - API signature added/removed/modified
    - CLI flag added/removed
    - Config schema changed
    - Error message text changed
    - Default value changed
  
  release:
    - Version bump
    - Breaking change
    - Deprecation notice
  
  external:
    - Dependency major version bump
    - Platform/runtime EOL announcement
```

CI should block merge if triggered files changed without corresponding doc update.

---

## Lint Rules

Automated checks for doc quality. Run on every commit.

### Structure Checks
- [ ] Frontmatter present and complete
- [ ] Information scent header (purpose + use when/avoid when)
- [ ] See Also section present with 2-5 links
- [ ] No orphan docs
- [ ] Bidirectional links valid

### Budget Checks
- [ ] File length ≤ hard max (220 lines)
- [ ] Heading count ≤ 12
- [ ] Code blocks ≤ 30 lines
- [ ] Paragraphs ≤ 80 words
- [ ] Lists ≤ 9 items

### Content Checks
- [ ] No forbidden phrases ("this document explains", "you might be wondering")
- [ ] No broken internal links
- [ ] Code blocks have language tags
- [ ] No inline TOCs in leaf pages

### Maintenance Checks
- [ ] `last_reviewed` within `review_cadence`
- [ ] No `depends_on` files modified after `last_reviewed`
- [ ] MAINTENANCE.md log entry exists for recent reviews

---

## Templates

### README.md

```markdown
# Project Name
One sentence: what this does.

## Quick Start
3-5 steps max.

## Documentation
- [Quickstart guide](./docs/paths/quickstart.md)
- [Core concepts](./docs/paths/concepts.md)
- [API reference](./docs/reference/)

## Install
One code block.

## License
[Type]. See [LICENSE](./LICENSE).
```

### CHANGELOG.md

```markdown
# Changelog
Format: [Keep a Changelog](https://keepachangelog.com/)

## [Unreleased]

## [X.Y.Z] - YYYY-MM-DD
### Added
### Changed
### Fixed
### Removed
```

### CONTRIBUTING.md

```markdown
# Contributing
How to contribute.

## Quick Start
1. Fork and clone
2. Install: `command`
3. Test: `command`
4. Submit PR

## Standards
- [Code style](./docs/reference/style.md)
- [Doc style](./docs/reference/docs.md)

## Questions
Open an issue.
```

---

## Commands

### Documentation Mode

```
---
description: Activate documentation alignment and generation
---

Entering DOCUMENTATION mode.

1. Read `kernel/banks/DOCUMENTATION-BANK.md`
2. Read `kernel/state.md` for existing docs_style
3. Scan repo: files, languages, exports, existing docs
4. If docs_style missing:
   - Select using signal patterns
   - Record in state.md with rationale
   - Lock unless user requests change
5. Build doc graph:
   - Create/update docs/index.md
   - Ensure no orphans
   - Add bidirectional links
6. Generate/refactor docs using style + budgets
7. Run lint checks, fix violations
8. Update state.md with discoveries
```

### Docs Audit Mode

```
---
description: Diagnose documentation health
---

Entering DOCS-AUDIT mode.

1. Read bank and state
2. Produce report:
   - Orphans, broken links
   - Budget violations
   - Missing doc kinds
   - Stale docs (maintenance triggers)
   - Redundancy clusters
3. Output prioritized fix plan with minimal diffs
```

### Docs Lint Mode

```
---
description: Enforce budgets and prevent regressions
---

Entering DOCS-LINT mode.

1. Read bank
2. Validate all lint rules
3. Check maintenance triggers
4. Output actionable diffs only
```

### Maintenance Mode

```
---
description: Process documentation maintenance queue
---

Entering DOCS-MAINTENANCE mode.

1. Read bank and state
2. Identify stale docs:
   - Cadence expired
   - Dependencies modified
   - Version references outdated
3. For each stale doc:
   - Review against current source
   - Update content if needed
   - Update last_reviewed
   - Log in MAINTENANCE.md
4. Update state.md with audit date
```

### Style Selection Mode

```
---
description: One-time style selection and lock
---

Entering DOCS-STYLE-SELECTION mode.

1. Read state.md
2. If docs_style exists: report current style and stop
3. Scan repo signals:
   - Export count, JSDoc presence → REFERENCE
   - CLI entry, config files → PROCEDURAL
   - ADRs, concept docs → NARRATIVE
4. Record docs_style + selection_rationale
5. Lock until user says "change docs style"
```

---

## CI Integration

### Staleness Check Script

```bash
#!/bin/bash
# scripts/docs-staleness-check.sh

STALE=()

for doc in docs/**/*.md; do
  [[ "$doc" == *"index.md"* ]] && continue
  [[ "$doc" == *"MAINTENANCE.md"* ]] && continue
  
  last=$(grep -m1 "last_reviewed:" "$doc" 2>/dev/null | cut -d' ' -f2)
  cadence=$(grep -m1 "review_cadence:" "$doc" 2>/dev/null | cut -d' ' -f2)
  
  [[ -z "$last" ]] && { STALE+=("$doc (missing frontmatter)"); continue; }
  
  days=$(( ($(date +%s) - $(date -d "$last" +%s)) / 86400 ))
  [[ "$days" -gt "${cadence:-90}" ]] && { STALE+=("$doc (${days}d > ${cadence}d cadence)"); continue; }
  
  deps=$(sed -n '/depends_on:/,/^[a-z]/p' "$doc" | grep "^\s*-" | sed 's/.*- //')
  for dep in $deps; do
    [[ -f "$dep" ]] || continue
    dep_date=$(git log -1 --format="%cs" -- "$dep" 2>/dev/null)
    [[ "$dep_date" > "$last" ]] && { STALE+=("$doc (dep $dep changed $dep_date)"); break; }
  done
done

if [[ ${#STALE[@]} -gt 0 ]]; then
  echo "🚨 STALE DOCS:"
  printf '%s\n' "${STALE[@]}"
  exit 1
fi
echo "✓ All docs current"
```

### GitHub Action

```yaml
name: Docs Maintenance

on:
  push:
    paths: ['src/**', 'docs/**']
  schedule:
    - cron: '0 9 * * 1'

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Check staleness
        run: ./scripts/docs-staleness-check.sh
```

---

## Warnings

This bank is methodology, not law.
Adapt to codebase reality.
If a rule doesn't fit, document exception in state.md with rationale.
Budgets exist to guide, hard maxes exist to force conversation.
The goal is clarity, not compliance.
