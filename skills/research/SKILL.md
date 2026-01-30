---
name: research
description: Deep research methodology - auto-triggers on research/investigate/find out signals
---

# Research Skill

## Purpose

This skill provides a systematic methodology for researching unknowns before implementation. It auto-triggers when context suggests investigation is needed.

**Key Concept**: The best code is code you don't write. Research existing solutions before building custom ones.

---

## Auto-Trigger Signals

This skill activates when detecting:
- "research", "find out", "learn about", "investigate"
- "deep dive", "what is", "how does", "explore"
- "best way to...", "how should I..."
- New technologies or libraries not in project
- Integration with external services/APIs

---

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

## The Research Protocol

### PHASE 1: Search for Complaints First

```
SEARCH PATTERNS:
- "[library] not working"
- "[feature] issues"
- "[tool] problems with [your use case]"

WHERE TO SEARCH:
- GitHub Issues (real bugs, real solutions)
- Stack Overflow (common pitfalls)
- Reddit (honest opinions)
- Discord (up-to-date community knowledge)
```

### PHASE 2: Map the Failure Modes

```
BUILD A FAILURE MAP:
- What breaks?
- What are the common misunderstandings?
- What did people try that didn't work?
- What are the version-specific gotchas?
```

### PHASE 3: Then Look for Solutions

```
NOW YOU'RE EQUIPPED:
- You know what to avoid
- You can evaluate if a solution addresses real problems
- You won't waste hours on abandoned approaches
- You can ask better questions
```

---

## Source Hierarchy

Quality of sources (highest to lowest):

1. **Official Docs** - Authoritative but may lack edge cases
2. **GitHub Issues** - Real problems, real solutions
3. **Source Code** - Truth when docs are wrong
4. **Stack Overflow** - Good for common patterns
5. **Blog Posts** - Varying quality, check dates
6. **AI Responses** - Verify everything, training data is old

---

## MCP Server Pattern

When researching external services:

```
ASK CLAUDE:
"Is there an MCP server for [Stripe/Supabase/etc]?
If so, set it up. If not, build a minimal one
that can query their docs."

WHAT HAPPENS:
- Claude searches for existing MCP servers
- Evaluates them for quality
- Installs and configures (or scaffolds custom)
- You get live access to current docs
```

---

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

## Quick Reference

| Phase | Question | Output |
|-------|----------|--------|
| Complaints | What breaks? | Failure map |
| Patterns | What exists? | Codebase matches |
| Solutions | What works? | Vetted approach |
| Synthesis | What's our path? | Implementation plan |

---

## Integration

- **Bank Reference**: Load `kernel/banks/RESEARCH-BANK.md` for complex research
- **Write Findings**: Always persist to `_meta/research/`
- **Cite Sources**: Document where solutions came from

---

## Anti-Patterns

- Jumping to implementation without research
- Searching only for tutorials (happy path)
- Not checking existing codebase patterns
- Trusting one source without verification
- Letting research stay in context (write to files)

---

## Success Metrics

Research is working well when:
- Known pitfalls are documented before coding
- Existing patterns are found and reused
- Sources are cited for future reference
- Implementation plan accounts for edge cases
