# Iteration Bank

## Philosophy
Deep understanding first - you can't improve what you don't understand. Code reduction is king - less code = fewer bugs. Bulletproof, not just working - production-ready handles edge cases. Small improvements compound. Don't try to perfect everything in one go - continuous improvement beats perfection.

## Process Skeleton
1. **Understand** - Deep code analysis, trace execution, map data flow
2. **Identify** - Find code reduction, performance, robustness, UX opportunities
3. **Prioritize** - High priority = immediate user impact, security issues
4. **Implement** - One improvement at a time, minimal focused changes
5. **Document** - Update understanding, log improvements, track history

---

## Slots (Designed to Fill)

### What To Look For (max 10 per category)
[TO EVOLVE: Add patterns discovered in THIS codebase]

**Code Reduction:**
- Duplication (DRY violations)
- Centralization opportunities
- Modularization possibilities
- Unused code
- Over-abstraction (simplify)

**Performance:**
- Unnecessary re-renders/recomputations
- Memory leaks
- Inefficient algorithms
- Bundle size
- Blocking operations

**Robustness:**
- Missing error handling
- Edge cases not handled
- Input validation gaps
- Security vulnerabilities
- Race conditions

**Maintainability:**
- Hard-to-understand code
- Magic numbers/strings
- Poor naming
- Tight coupling
- Missing documentation

**User Experience:**
- Accessibility issues
- Console logs in production
- Error messages (user-friendly?)
- Loading states
- Responsive design

### Understanding Document Structure
[TO EVOLVE: Adapt sections based on codebase type]

```markdown
# Understanding: {Target Name}

**Analyzed:** {timestamp}
**Target:** {file/component path}

---

## Purpose
{What does this code do? What problem does it solve?}

## Architecture
{How is it structured? Main components?}

## Data Flow
{How does data flow through this code?}

## Dependencies
- {Dependency 1}: {Why needed, how used}

## Key Functions/Components
### {Function 1}
- **Purpose:** {What it does}
- **Inputs:** {What it takes}
- **Outputs:** {What it returns}
- **Side effects:** {Any}
- **Complexity:** Simple/Medium/Complex

## Known Issues
- {Issue 1}

## Performance Characteristics
- {Characteristic 1}
```

### Improvement Documentation Structure
[TO EVOLVE: Track improvement types that work well]

```markdown
# Improvements: {Target Name}

**Identified:** {timestamp}

---

## Code Reduction Opportunities

### Duplication 1: {Description}
**Location:** {File:Line}
**Duplicated in:** {File:Line, File:Line}
**Impact:** {Lines reduced}
**Approach:** {How to centralize}
**Priority:** High/Medium/Low

## Performance Improvements
{Same structure}

## Robustness Improvements
{Same structure}

## Prioritized Plan

### High Priority (Immediate UX Impact)
1. {Improvement}: {why, estimated impact}

### Medium Priority (Quality of Life)
1. {Improvement}

### Low Priority (Nice to Have)
1. {Improvement}
```

### Prioritization Criteria
[TO EVOLVE: Adjust based on project priorities]

- **High:** Users notice immediately, security issues, critical bugs
- **Medium:** Code quality, maintainability, non-critical performance
- **Low:** Nice-to-have, future-proofing, minor optimizations

### Implementation Workflow
[TO EVOLVE: Add steps specific to THIS codebase]

```
BEFORE:
1. Read improvement plan
2. Understand current code
3. Check for conflicts
4. Verify approach still valid

DURING:
1. Minimal, focused changes
2. Follow existing patterns
3. Question: simplest way?
4. Document why

AFTER:
1. Verify improvement works
2. Verify no regressions
3. Measure improvement
4. Update understanding.md
5. Commit with clear message
6. Update improvements.md
7. Update history.md
```

---

## Iteration Workspace Structure

```
.claude/iterations/
  {target-name}/
    understanding.md     # Deep understanding
    improvements.md      # Identified improvements
    research.md         # Research findings (if any)
    history.md          # Iteration history
```

---

## Iteration Quality Checklist

- [ ] Deep understanding documented
- [ ] All improvements identified and prioritized
- [ ] High-priority improvements implemented
- [ ] Code is simpler (or complexity justified)
- [ ] No regressions introduced
- [ ] Security issues addressed
- [ ] Console logs removed (production)
- [ ] Understanding.md updated
- [ ] Improvements.md updated
- [ ] History.md updated
- [ ] Changes committed with clear messages

---

## Commit Message Format

```
refactor({scope}): {improvement description}

{What was improved and why}

- {Change 1}
- {Change 2}

Impact: {Lines reduced, performance improved, etc.}
```

---

## Template Notice
This bank is scaffolding. Fill slots as you iterate in this codebase.
Move stable iteration patterns to `.claude/rules/patterns.md` when they repeat.
Respect caps; if full, replace least valuable or promote to rules.
