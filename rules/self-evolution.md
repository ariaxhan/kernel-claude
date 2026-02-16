---
paths: "**/*"
---

# Self-Evolution Rule

**ALL agents and sessions MUST evolve the system.** Learning that stays in context is lost.

## The Law

```
WHEN YOU LEARN SOMETHING → UPDATE THE SYSTEM
WHEN SOMETHING BREAKS REPEATEDLY → PATCH THE RULES
WHEN A PATTERN EMERGES → ENCODE IT
WHEN CONFIG IS WRONG → FIX IT NOW
```

## Triggers

Update the system when:
- You find a gotcha (add to rules)
- You solve a problem a certain way (add to patterns)
- You make a mistake twice (add prevention rule)
- You discover infrastructure info (add to _session.md)
- You find a better approach (update relevant agent/skill)
- A tool/framework behaves unexpectedly (document it)

## Process

1. **Identify** the learning
2. **Log** to `_meta/_learnings.md`:
   ```markdown
   ## {date}
   **Context:** {project}
   **Type:** pattern | gotcha | fix | optimization | tool
   **What:** {brief description}
   **Why:** {rationale}
   **Applied to:** {files updated}
   ```
3. **Update** the relevant config:
   - Agent behavior → `.claude/agents/{name}.md`
   - Rule/constraint → `.claude/rules/{topic}.md`
   - Skill/how-to → `.claude/skills/{name}/SKILL.md`
   - Pattern → `_meta/_patterns.md`
   - Infrastructure → `_meta/_session.md`
4. **Tell user** briefly what changed

## Examples

### Bad (learning lost)
```
Claude: "Oh, I see this API returns data in a different shape than expected. Let me handle that..."
[fixes it locally, doesn't update anything]
[next session: makes same mistake]
```

### Good (learning captured)
```
Claude: "Found that this API returns `{data: [...]}` not `[...]`.
Updating rules/api-patterns.md and logging to _meta/_learnings.md."
[next session: rule prevents mistake]
```

## Deletion is Evolution

Remove stale rules. Kill dead patterns. If something no longer applies, delete it. Evolution means pruning, not just adding.

## Commit Protocol

After updating configs:
- Stage the changed files
- Commit with message: `chore(system): {what evolved}`
- Small, atomic commits for each evolution

## Integration with Agents

Every agent in `.claude/agents/` inherits this rule. Before completing any task, agents should ask:
- Did I learn something new?
- Should this be encoded in the system?
- What would prevent this problem next time?
