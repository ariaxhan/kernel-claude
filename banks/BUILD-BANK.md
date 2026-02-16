# Build Bank

## Philosophy
Minimal code through maximum research. The best code is code you don't write. Your first solution is never right - always explore multiple approaches and choose simplest. Every line of code is liability. Delete code that doesn't earn its place.

## Process Skeleton
1. **Input Detection** - Raw idea? Existing plan? Partial implementation?
2. **Planning** - Goal extraction, research, assumptions, multiple solutions, choose simplest
3. **Execution** - Setup, iterative implementation, integration checkpoints
4. **Validation** - Automated checks, manual verification, edge cases
5. **Completion** - Update state, mark complete, final report

---

## Slots (Designed to Fill)

### Goal Extraction Template
[TO EVOLVE: Add extraction patterns for THIS project type]

```
GOAL: [What are we building?]
CONSTRAINTS: [Limitations, requirements, must-haves]
INPUTS: [What do we have to work with?]
OUTPUTS: [What should exist when done?]
DONE-WHEN: [How do we know it's complete?]
```

### Solution Exploration Template (NEVER SKIP)
[TO EVOLVE: Add solution comparison criteria for THIS tech stack]

**Solution 1: {Approach Name}**
- How: {brief description}
- Code required: ~{X} lines
- Dependencies: {list}
- Pros: {why good}
- Cons: {why might not be best}
- Complexity: simple/medium/complex

**Solution 2: {Approach Name}**
{same structure}

**Solution 3: {Approach Name}**
{same structure}

**Decision:**
- Chosen: Solution {X}
- Why: {simplest, most reliable}
- Rejected: {why others rejected}

**Evaluation Criteria (in order):**
1. Minimal code - fewest lines, simplest logic
2. Popular package - most downloads = battle-tested
3. Reliability - fewer edge cases, fewer bugs
4. Maintenance - active, clear docs
5. Performance - only if bottleneck

### Assumption Categories (max 6 per category)
[TO EVOLVE: Add common assumptions in THIS codebase]

- Tech stack (languages, frameworks, versions)
- File locations (where code lives, where to create)
- Naming conventions (casing, patterns)
- Error handling approach
- Test expectations
- Dependencies

### Plan Document Structure
[TO EVOLVE: Adjust based on what information matters]

```markdown
# Plan: {Feature Name}

## Goal
{one sentence}

## Done-When
- [ ] {criterion 1}
- [ ] {criterion 2}

## Solution
**Chosen:** {package/approach}
**Why:** {simplest}
**Code:** ~{X} lines
**Deps:** {list}

See `.claude/research/{feature-name}-research.md` for alternatives.

## Steps
1. [ ] {step 1}
2. [ ] {step 2}
3. [ ] {step 3}

## Validate
- [ ] {test 1}
- [ ] {test 2}

---
Created: {timestamp}
Status: READY FOR EXECUTION
```

**Keep plans under 50 lines. If longer, overthinking.**

### Execution Workflow
[TO EVOLVE: Add steps specific to THIS codebase]

```
BEFORE each step:
  - Mark in_progress in todo
  - State what you're doing
  - Review research doc
  - Check: fewer lines possible?

DURING:
  - Use recommended package from research
  - Minimal, focused changes
  - One logical unit per commit
  - Follow existing patterns exactly
  - Avoid documented pitfalls

AFTER:
  - Verify change works
  - Count lines - can we reduce?
  - Check if pitfalls occurred
  - Mark completed
  - Commit immediately
  - Update plan with progress
```

### Validation Checklist
[TO EVOLVE: Add validation steps for THIS tech stack]

**Automated:**
```bash
# Tests
[ -f package.json ] && npm test
[ -f pyproject.toml ] && pytest
[ -f Cargo.toml ] && cargo test
[ -f go.mod ] && go test ./...

# Lint
[ -f .eslintrc* ] && npm run lint
[ -f pyproject.toml ] && ruff check .
[ -f rustfmt.toml ] && cargo fmt --check

# Types
[ -f tsconfig.json ] && npx tsc --noEmit
[ -f pyproject.toml ] && mypy .
```

**Manual:**
- Walk through done-when criteria
- Document how verified
- If not met, add remediation step

**Edge Cases (at least 3):**
- Empty/null input
- Boundary conditions
- Error/failure path

---

## Failure Handling

### Implementation Fails
1. STOP immediately
2. Check research doc for this error
3. If documented fix exists, apply it
4. If not documented:
   - Question: simpler solution missed?
   - Search, add to research doc
   - Consider different package/approach
   - Document what failed and why
5. Rollback to last known good state
6. Re-evaluate: still simplest solution?
7. Update plan
8. Ask: continue modified or explore alternative?

### Solution Feels Complex
1. STOP and question: why complex?
2. Check research: miss simpler package?
3. Search: "{problem} simple solution"
4. Can different approach use less code?
5. Re-evaluate all solutions
6. Choose simpler if found

### Tests Fail
1. Identify failing test
2. Diagnose: code or test issue?
3. Fix root cause (not symptoms)
4. Re-run full validation

### Blocked
1. Document blocker
2. List what's needed to unblock
3. Ask user for input
4. Do NOT guess or work around silently

---

## Final Report Structure

```
BUILD COMPLETE

Feature: {name}
Branch: {branch-name}
Commits: {count}

Files Changed:
  - {file1}: {what changed}
  - {file2}: {what changed}

Validation:
  - Tests: {pass/fail/skip}
  - Lint: {pass/fail/skip}
  - Types: {pass/fail/skip}
  - Done-when: {all criteria met}

Next Steps:
  - [ ] Review: git diff main
  - [ ] Create PR: /ship
  - [ ] {follow-up items}
```

---

## Behavior Flags

- **Default**: Full flow with confirmations
- **--quick**: Skip confirmations, minimal prompts
- **--plan-only**: Stop after Phase 1
- **--resume**: Continue in-progress work
- **--validate-only**: Skip to Phase 3

---

## Template Notice
This bank is scaffolding. Fill slots as you build in this codebase.
Move stable build patterns to `.claude/rules/patterns.md` when they repeat.
Respect caps; if full, replace least valuable or promote to rules.
