# Research Bank

## Philosophy
Find existing solutions before writing any code. The best code is code you don't write. Popular = reliable (most downloads means most battle-tested). Diversity beats depth - multiple perspectives reveal simplest solution. If the solution seems complex, you haven't found the right package yet.

## Process Skeleton
1. **Plan** - Create research plan before any searches
2. **Existing Solutions** - Find most popular package (check download stats)
3. **Official Docs** - Check for built-in solutions
4. **Problem Discovery** - Document 3-5 common pitfalls with fixes
5. **Document** - Create comprehensive research doc

---

## Slots (Designed to Fill)

### Research Planning Template
[TO EVOLVE: Adapt based on what works in THIS codebase]

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
- **Purpose:** Find most popular package for {problem}
- **Query:** "{problem} npm package" or "{problem} python library"
- **Expected:** Package name, popularity stats, minimal code

#### Search 2: Official Documentation
- **Purpose:** Check for built-in solution
- **Query:** "{technology} {feature} documentation"
- **Expected:** Built-in API or official pattern

#### Search 3: Common Problems
- **Purpose:** Find common pitfalls/errors
- **Query:** "{technology} {use case} common mistakes"
- **Expected:** 3-5 pitfalls with fixes
```

### Source Diversity Categories (min 3 types)
[TO EVOLVE: Track which sources work best for THIS tech stack]

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

### Pitfall Documentation Structure
[TO EVOLVE: Add common pitfall patterns discovered]

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

### Package Evaluation Criteria (max 8)
[TO EVOLVE: Add criteria relevant to THIS project]

- Weekly/monthly downloads (npm: 1M+, pypi: check)
- Last update (within 6 months)
- Open issues (security issues?)
- Lines of code required
- Bundle size impact
- Maintenance status
- Community size
- Documentation quality

---

## Documentation Structure

Create `.claude/research/{feature-name}-research.md`:

```markdown
# Research: {Feature Name}

**Date:** {date}
**Sources:** {count} across {count} categories

---

## Recommended Solution

**Package:** {name} v{version}
**Why:** {simplest, most reliable}
**Popularity:** {download stats}
**Code Required:** ~{X} lines

**Implementation:**
\`\`\`{language}
{minimal example}
\`\`\`

---

## Alternatives Considered
{Why rejected}

## Common Pitfalls & Fixes
{Documented pitfalls}

## Sources
{Full reference list}
```

---

## Research Quality Checklist

- [ ] Research plan created and followed
- [ ] Token budget respected (~2000-3000 tokens)
- [ ] At least 1 popular package identified
- [ ] At least 3 common pitfalls documented
- [ ] Sources span at least 3 categories
- [ ] All sources cited with URLs
- [ ] Key questions answered

---

## When To Research Again

- Encounter undocumented error
- Different version than researched
- Integrating with new system
- Scaling beyond researched use cases
- Security/performance requirements change

**Update existing research doc, don't start fresh.**

---

## Template Notice
This bank is scaffolding. Fill slots as you research in this codebase.
Move stable research patterns to `.claude/rules/patterns.md` when they repeat.
Respect caps; if full, replace least valuable or promote to rules.
