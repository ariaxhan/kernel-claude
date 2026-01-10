---
description: Before committing - Review code quality and documentation
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Audit Code and Documentation

**When to use**: Before committing code to ensure quality and documentation are current.
**What it does**: Reviews code for correctness and audits documentation for completeness.

## Process

### Step 1: Load Methodology

Read both banks:
1. `kernel/banks/REVIEW-BANK.md` - Code review methodology
2. `kernel/banks/DOCUMENTATION-BANK.md` - Documentation standards

Read `kernel/state.md` for:
- Project conventions
- Documentation style
- Known invariants

### Step 2: Code Review

Apply review checklist from REVIEW-BANK:

**Correctness**:
- Logic matches requirements
- Edge cases handled
- Error conditions covered
- No obvious bugs

**Consistency**:
- Follows naming conventions from state.md
- Matches existing patterns
- Uses project idioms

**Completeness**:
- All requirements implemented
- Tests cover new code
- Error messages helpful

**Convention Adherence**:
- Code style matches project
- Imports organized correctly
- Comments where needed (complex logic only)

**Invariants** (check kernel/rules/invariants.md if exists):
- Security requirements met
- Performance constraints satisfied
- Data integrity maintained

### Step 3: Documentation Audit

Check documentation status:

**If docs_style missing in state.md**:
- Scan repo signals (exports → REFERENCE, CLI → PROCEDURAL, ADRs → NARRATIVE)
- Record style in state.md and lock

**Audit docs/ directory**:
- ✓ Frontmatter complete (doc_kind, depends_on, review_cadence, last_reviewed, owners)
- ✓ Line 2 rule (purpose + use when/avoid when)
- ✓ See Also section present (2-5 links)
- ✓ Within budgets (150-220 lines, 8-12 headings, 15-30 code block lines)
- ✓ No staleness (depends_on files not modified after last_reviewed)
- ✓ No orphans (all docs linked from index)
- ✓ Bidirectional links valid

**Check if changed code needs doc updates**:
- API signatures added/removed/modified
- CLI flags added/removed
- Config schema changed
- Error messages changed
- Default values changed

### Step 4: Generate Report

```
Audit Report
============

CODE REVIEW
-----------
Files reviewed: N
Issues found: N

[Severity] file:line - description
...

DOCUMENTATION
-------------
Docs style: PROCEDURAL
Docs audited: N
Issues found: N

[Issue Type] file - description
...

OVERALL STATUS: [PASS | NEEDS FIXES]
```

### Step 5: Fix Issues (If Found)

**For code issues**:
- Show specific fixes needed
- Offer to apply fixes if clear

**For doc issues**:
- Update frontmatter
- Fix budget violations (split or refactor)
- Add missing See Also sections
- Update stale docs based on code changes
- Add bidirectional links

### Step 6: Update State

If review reveals gaps:
- Add newly discovered conventions to state.md
- Update invariants if new rules identified
- Record last_reviewed date for docs

## Example Output

```
> /audit

Loading review methodology...
Loading doc standards...
Reading project state...

CODE REVIEW
-----------
Reviewing src/api/auth.ts...
✓ Correctness: logic sound
✓ Consistency: follows naming conventions
✓ Completeness: tests included
⚠ Convention: missing JSDoc on public function
✓ Invariants: security requirements met

Reviewing src/utils/parser.ts...
✓ All checks passed

Files reviewed: 2
Issues: 1 warning

[WARN] src/api/auth.ts:45 - Public function authenticate() missing JSDoc
  Fix: Add function documentation

DOCUMENTATION
-------------
Style: PROCEDURAL (locked in state.md)

Auditing docs/api-reference.md...
✓ Frontmatter complete
✓ Line 2 rule present
✓ See Also section (3 links)
✗ Stale: depends_on src/api/auth.ts modified after last_reviewed
  Fix: Review doc and update last_reviewed date

Auditing docs/setup.md...
✓ All checks passed

Docs audited: 2
Issues: 1 staleness

OVERALL STATUS: NEEDS FIXES
---
1 code warning
1 doc staleness

Fix these issues? [Y/n]
```

## Workflow Integration

This command runs both code review and documentation audit in one pass.

**Typical usage**:
```
1. Make changes to code
2. Run /audit to check quality + docs
3. Fix any issues found
4. Run /audit again to verify
5. Run /ship to commit and push
```

## Notes

- Runs both code and doc checks automatically
- Issues are prioritized (errors > warnings > info)
- Doc updates are suggested based on code changes
- Updates state.md with any new discoveries
