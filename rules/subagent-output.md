---
paths: "**/*"
---

# Subagent Output Rule

**CRITICAL: Subagent work that only returns to you is LOST.**

## The Problem

When you spawn a subagent (via Task tool), it runs in a separate context. If you only ask it to "return results to you," those results exist only in the conversation—they're not persisted anywhere.

Next session? Gone. Context window fills up? Gone. You can't search it, reference it, or build on it.

## The Rule

```
EVERY SUBAGENT MUST WRITE TO FILES.

When spawning ANY subagent:
1. Tell it WHERE to write (absolute path)
2. Tell it WHAT format (.md, structured)
3. Subagent MUST write findings to file BEFORE returning
4. Subagent output in terminal is ALSO required (both, not either/or)
```

## Example Prompts

**BAD:**
```
"Research authentication patterns and tell me what you find."
```
Result: Findings disappear when context closes.

**GOOD:**
```
"Research authentication patterns.
Write findings to /project/_meta/research/auth-patterns.md.
Also return summary to me."
```
Result: Findings persist in file system. Searchable. Referenceable.

## Where to Write

| Content Type | Location |
|--------------|----------|
| Research findings | `_meta/research/{topic}.md` |
| Code analysis | `_meta/analysis/{component}.md` |
| Investigation results | `_meta/debug/{issue}.md` |
| Planning output | `_meta/plans/{feature}.md` |
| General findings | `_meta/context/` |

## Integration with _meta

The `_meta/` folder is designed for this:
- `_meta/research/` — Research outputs
- `_meta/context/active.md` — Current work state
- `_meta/_learnings.md` — Patterns discovered

Subagent outputs feed into the session tracking system. They become searchable context for future sessions.

## Anti-Patterns

- "Just tell me what you find" — No file output
- Writing to `/tmp/` — Not in project, not tracked
- Writing without absolute path — Ambiguous location
- Forgetting terminal output — User can't see progress

## The Loop

```
Spawn subagent → Subagent writes to file → File persists →
Next session reads file → Knowledge compounds
```

Without file output, the loop breaks. Knowledge doesn't compound.
