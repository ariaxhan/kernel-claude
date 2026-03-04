# Code Review Protocol

**Type:** methodology | **When:** Plan mode reviews, PR reviews, architecture assessment

---

## Review Sections (in order)

### 1. Architecture Review
- System design and component boundaries
- Dependency graph and coupling concerns
- Data flow patterns and potential bottlenecks
- Scaling characteristics and single points of failure
- Security architecture (auth, data access, API boundaries)

### 2. Code Quality Review
- Code organization and module structure
- DRY violations — flag aggressively
- Error handling patterns and missing edge cases
- Technical debt hotspots
- Over-engineered or under-engineered areas

### 3. Test Review
- Coverage gaps (unit, integration, e2e)
- Test quality and assertion strength
- Missing edge case coverage
- Untested failure modes and error paths

### 4. Performance Review
- N+1 queries and database access patterns
- Memory-usage concerns
- Caching opportunities
- Slow or high-complexity code paths

---

## For Each Issue Found

1. **Describe concretely** — file:line references
2. **Present 2-3 options** — including "do nothing" where reasonable
3. **For each option specify:**
   - Implementation effort (trivial / moderate / significant)
   - Risk (low / medium / high)
   - Impact on other code
   - Maintenance burden
4. **Give recommended option** — with reasoning mapped to preferences
5. **Ask before proceeding** — user confirms or chooses different direction

---

## Interaction Modes

Before starting review, ask:

**BIG CHANGE:** Work through interactively, one section at a time (Architecture → Code Quality → Tests → Performance). Max 4 issues per section.

**SMALL CHANGE:** Work through one question per review section.

---

## AskUserQuestion Format

When presenting issues:
- NUMBER the issues (Issue 1, Issue 2, etc.)
- LETTER the options (A, B, C)
- Recommended option always FIRST (A)
- Clear labels: "Issue 1, Option A" not ambiguous references

---

## Workflow

- Do not assume priorities on timeline or scale
- After each section, pause and ask for feedback before moving on
- If user says "skip" on a section, move to next
- At end, summarize all decisions made

---

*Source: Adapted from community plan mode prompt (2026-02-04). Integrated with ARIA challenge protocol.*
