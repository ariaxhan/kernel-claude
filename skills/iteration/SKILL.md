---
name: iteration
description: Continuous improvement - analyze, improve, iterate on existing code
triggers:
  - iterate
  - improve
  - refactor
  - clean up
  - optimize
  - reduce code
  - technical debt
---

# Iteration Skill

## Purpose

Deep understanding first. Code reduction is king. Bulletproof, not just working. Small improvements compound.

**Key Concept**: You can't improve what you don't understand. Less code = fewer bugs.

---

## Auto-Trigger Signals

This skill activates when detecting:
- "iterate", "improve", "refactor"
- "clean up", "optimize", "reduce"
- "technical debt", "code smell"
- "make this better", "simplify"

---

## Process

```
1. UNDERSTAND → Deep code analysis, trace execution, map data flow
2. IDENTIFY → Find code reduction, performance, robustness opportunities
3. PRIORITIZE → High priority = immediate user impact, security issues
4. IMPLEMENT → One improvement at a time, minimal focused changes
5. DOCUMENT → Update understanding, log improvements, track history
```

---

## What To Look For

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

---

## Understanding Document Structure

```markdown
# Understanding: {Target Name}

**Analyzed:** {timestamp}
**Target:** {file/component path}

## Purpose
{What does this code do? What problem does it solve?}

## Architecture
{How is it structured? Main components?}

## Data Flow
{How does data flow through this code?}

## Dependencies
- {Dependency 1}: {Why needed, how used}

## Key Functions
### {Function 1}
- Purpose: {What it does}
- Inputs: {What it takes}
- Outputs: {What it returns}
- Side effects: {Any}
- Complexity: Simple/Medium/Complex

## Known Issues
- {Issue 1}

## Performance Characteristics
- {Characteristic 1}
```

---

## Prioritization

| Priority | Criteria |
|----------|----------|
| High | Users notice immediately, security issues, critical bugs |
| Medium | Code quality, maintainability, non-critical performance |
| Low | Nice-to-have, future-proofing, minor optimizations |

---

## Implementation Workflow

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
```

---

## Iteration Workspace

```
.claude/iterations/
  {target-name}/
    understanding.md     # Deep understanding
    improvements.md      # Identified improvements
    research.md          # Research findings
    history.md           # Iteration history
```

---

## Quality Checklist

```
□ Deep understanding documented
□ All improvements identified and prioritized
□ High-priority improvements implemented
□ Code is simpler (or complexity justified)
□ No regressions introduced
□ Security issues addressed
□ Console logs removed (production)
□ Changes committed with clear messages
```

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

## Anti-Patterns

- Improving without understanding
- Changing too much at once
- Breaking existing functionality
- Over-engineering simple code
- Not measuring improvement

---

## Success Metrics

Iteration is working well when:
- Code is simpler after iteration
- No regressions introduced
- Changes are documented
- Improvements are measurable
