---
description: Critical review mode - world-class developer tears your plan apart before you write code
---

# /kernel:tearitapart

## ●:ON_START

```bash
agentdb read-start
```

Critical review before implementation. Activate your inner senior engineer.

## Purpose

Find problems BEFORE writing code, not after. A plan that survives this review is worth implementing.

## Methodology

### 1. Critical Issues

What will definitely break?
- Missing requirements
- Incorrect assumptions
- Technical impossibilities
- Security vulnerabilities
- Data integrity risks

### 2. Concerns

What might cause problems?
- Edge cases not handled
- Performance at scale
- Maintenance burden
- Testing difficulty
- Integration challenges

### 3. Questions

What's unclear?
- Ambiguous requirements
- Missing context
- Unstated assumptions
- Alternative approaches

### 4. Scale Test

How does this behave at:
- 10x current usage?
- 100x current usage?
- 1000x current usage?

### 5. Maintenance Burden

- How hard to debug?
- How hard to modify?
- How hard to delete?
- What dependencies added?

### 6. Security Review

- Input validation?
- Authentication/authorization?
- Data exposure risks?
- Injection vulnerabilities?

## Output

Write review to `_meta/reviews/{feature-name}-teardown.md`:

```markdown
# Tear Down: {feature name}

## Critical Issues
{must fix before proceeding}

## Concerns
{should address}

## Questions
{need answers}

## Scale Analysis
{10x/100x/1000x}

## Verdict
[ ] PROCEED - Issues minor, plan is sound
[ ] REVISE - Address issues first
[ ] RETHINK - Fundamental problems
```

## Usage

```
/kernel:tearitapart
```

Run after planning, before implementing. If verdict is REVISE or RETHINK, update plan and run again.

## Anti-patterns

- Skipping this step
- Ignoring critical issues
- "We'll fix it later"
- Proceeding with RETHINK verdict

## ●:ON_END

```bash
agentdb write-end '{"command":"tearitapart","did":"critical review complete","verdict":"PROCEED|REVISE|RETHINK","review":"_meta/reviews/<feature-name>-teardown.md"}'
```
