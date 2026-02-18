---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.

name: research
description: Deep research methodology - auto-triggers on research/investigate/find out signals
triggers:
  - research
  - find out
  - learn about
  - investigate
  - deep dive
  - what is
  - how does
  - best way to
---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


# Research Skill

## Purpose

Find existing solutions before writing any code. The best code is code you don't write. Popular = reliable (most downloads means most battle-tested).

**Key Concept**: Diversity beats depth - multiple perspectives reveal simplest solution. If the solution seems complex, you haven't found the right package yet.

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Auto-Trigger Signals

This skill activates when detecting:
- "research", "find out", "learn about", "investigate"
- "deep dive", "what is", "how does", "explore"
- "best way to...", "how should I..."
- New technologies or libraries not in project
- Integration with external services/APIs

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Process

```
1. PLAN → Create research plan before any searches
2. EXISTING SOLUTIONS → Find most popular package (check download stats)
3. OFFICIAL DOCS → Check for built-in solutions
4. PROBLEM DISCOVERY → Document 3-5 common pitfalls with fixes
5. DOCUMENT → Create comprehensive research doc
```

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## The Research Inversion

**Don't look for solutions. Look for problems first.**

```
TRADITIONAL (wrong):
Search "how to implement X"
→ Find tutorials, happy-path examples
→ Hit walls later that tutorials didn't cover

INVERTED (correct):
Search "X not working", "X issues", "X problems"
→ Find forums with real failures
→ Map what breaks before you start
→ THEN find solutions with full context
```

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Research Planning Template

```markdown
## Research Plan

### Goal
{What we're trying to find}

### Key Questions
1. {Question 1}
2. {Question 2}
3. {Question 3}

### Planned Searches (5-8 max)

#### Search 1: Existing Solutions
- Purpose: Find most popular package for {problem}
- Query: "{problem} npm package" or "{problem} python library"
- Expected: Package name, popularity stats, minimal code

#### Search 2: Official Documentation
- Purpose: Check for built-in solution
- Query: "{technology} {feature} documentation"
- Expected: Built-in API or official pattern

#### Search 3: Common Problems
- Purpose: Find common pitfalls/errors
- Query: "{technology} {use case} common mistakes"
- Expected: 3-5 pitfalls with fixes
```

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Source Diversity Categories

**Category 1: Official Sources**
- Official documentation
- Best practices guides
- Migration/upgrade guides
- API reference

**Category 2: Community Problem-Solving**
- GitHub Issues (closed with solutions)
- Stack Overflow (high-vote accepted)
- Reddit r/{technology}
- Discourse forums

**Category 3: Real-World Experiences**
- Developer blogs (war stories)
- Medium/Dev.to (pitfall mentions)
- Company engineering blogs
- Conference talks

**Category 4: Code Examples**
- GitHub repos ("{tech} example")
- Official example repositories
- Community starter projects

**Category 5: Troubleshooting**
- Error message databases
- "Common mistakes" articles
- Debugging guides

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Source Hierarchy

Quality of sources (highest to lowest):

1. **Official Docs** - Authoritative but may lack edge cases
2. **GitHub Issues** - Real problems, real solutions
3. **Source Code** - Truth when docs are wrong
4. **Stack Overflow** - Good for common patterns
5. **Blog Posts** - Varying quality, check dates
6. **AI Responses** - Verify everything, training data is old

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Package Evaluation Criteria

| Criterion | What to Check |
|-----------|---------------|
| Downloads | npm: 1M+/week, pypi: check trends |
| Last update | Within 6 months |
| Open issues | Security issues? |
| Lines required | Less is better |
| Bundle size | Impact on build |
| Maintenance | Active maintainers |
| Community | Size and activity |
| Documentation | Quality and completeness |

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Pitfall Documentation Structure

```markdown
### Pitfall: {Name}

**Error/Symptom:**
{exact error message or behavior}

**Why it happens:**
{root cause explanation}

**Prevention:**
- {preventive measure}
- {best practice}

**Fix:**
1. {step-by-step solution}
2. {code example if needed}

**Sources:** [Link](URL)
**Confidence:** High/Medium/Low
```

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Documentation Structure

Create `_meta/research/{feature-name}-research.md`:

```markdown
# Research: {Feature Name}

**Date:** {date}
**Sources:** {count} across {count} categories

## Recommended Solution

**Package:** {name} v{version}
**Why:** {simplest, most reliable}
**Popularity:** {download stats}
**Code Required:** ~{X} lines

**Implementation:**
\`\`\`{language}
{minimal example}
\`\`\`

## Alternatives Considered
{Why rejected}

## Common Pitfalls & Fixes
{Documented pitfalls}

## Sources
{Full reference list}
```

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Subagent Research Pattern

For parallel research:

```
SPAWN 3 RESEARCH SUBAGENTS:
1. Search GitHub issues for common failures
2. Check codebase for existing patterns
3. Find MCP servers or official integrations

CRITICAL: Each subagent MUST write to files:
- /project/_meta/research/[topic]-github-issues.md
- /project/_meta/research/[topic]-codebase-patterns.md
- /project/_meta/research/[topic]-integrations.md

THEN: Synthesize findings before implementing
```

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Quick Reference

| Phase | Question | Output |
|-------|----------|--------|
| Complaints | What breaks? | Failure map |
| Patterns | What exists? | Codebase matches |
| Solutions | What works? | Vetted approach |
| Synthesis | What's our path? | Implementation plan |

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Research Quality Checklist

```
□ Research plan created and followed
□ Token budget respected (~2000-3000 tokens)
□ At least 1 popular package identified
□ At least 3 common pitfalls documented
□ Sources span at least 3 categories
□ All sources cited with URLs
□ Key questions answered
```

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## When To Research Again

- Encounter undocumented error
- Different version than researched
- Integrating with new system
- Scaling beyond researched use cases
- Security/performance requirements change

**Update existing research doc, don't start fresh.**

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Anti-Patterns

- Jumping to implementation without research
- Searching only for tutorials (happy path)
- Not checking existing codebase patterns
- Trusting one source without verification
- Letting research stay in context (write to files)

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Success Metrics

Research is working well when:
- Known pitfalls are documented before coding
- Existing patterns are found and reused
- Sources are cited for future reference
- Implementation plan accounts for edge cases

---

## ●:ON_END (REQUIRED)

```bash
agentdb write-end '{"discovered":"X","key_files":["a","b"]}'
agentdb learn pattern "what I learned about this codebase" "evidence"
```
