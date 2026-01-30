---
description: Activate documentation mode - audit, generate, maintain docs
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Documentation Mode

1. Read `kernel/banks/DOCUMENTATION-BANK.md`
2. Read `kernel/state.md` for docs_style

## If docs_style missing

Scan repo signals:
- Many exports, JSDoc → REFERENCE
- CLI entry, configs → PROCEDURAL
- ADRs, concepts → NARRATIVE

Record in state.md, lock.

## Audit

Check all docs in `docs/`:
- Frontmatter complete?
- See Also present?
- Within budgets?
- Stale (depends_on modified)?
- Orphaned?

## Generate/Refactor

Apply style templates from bank.
Fix budget violations.
Add missing See Also sections.
Update MAINTENANCE.md log.

## Output

Report:
- Style: [selected]
- Docs audited: N
- Issues found: N
- Fixed: N
- Manual action needed: [list]
