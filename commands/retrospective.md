---
name: kernel:retrospective
description: "Cross-session learning synthesis. Finds patterns, resolves contradictions, promotes insights. Triggers: retrospective, reflect, patterns, learnings, synthesis."
user-invocable: true
allowed-tools: Read, Bash, Grep, Glob
---

<command id="retrospective">

<purpose>
Cross-session learning synthesis. Reviews AgentDB learnings, finds patterns across sessions,
resolves contradictions, merges duplicates, archives stale entries, promotes high-confidence insights.
</purpose>

<execution>
1. Pull all learnings from AgentDB:
   ```bash
   agentdb query "SELECT id, type, content, evidence, reinforced, created_at FROM learnings ORDER BY created_at DESC"
   ```

2. Pull recent checkpoints for session context:
   ```bash
   agentdb recent
   ```

3. Analyze learnings across 5 dimensions:
   - **Clusters**: Group related learnings by theme (e.g., hook loading, git workflow, testing)
   - **Duplicates**: Identify learnings that say the same thing differently — merge into strongest form
   - **Contradictions**: Find learnings that conflict — resolve with evidence, archive the loser
   - **Stale**: Flag learnings not reinforced in 30+ days with no recent evidence
   - **Promotable**: Identify high-confidence patterns (reinforced 2+) worth encoding into rules

4. Take action:
   - Merge duplicates: `agentdb learn {type} "{merged}" "{combined evidence}"`
   - Archive stale: `agentdb query "DELETE FROM learnings WHERE id = {id}"`
   - Promote patterns: Recommend additions to CLAUDE.md or skill reference docs
   - If non-local profile: surface promoted patterns to GitHub Discussions (Learnings category)

5. Write synthesis to AgentDB:
   ```bash
   agentdb write-end '{"did":"retrospective","clusters":N,"merged":N,"archived":N,"promoted":N}'
   ```
</execution>

<output_format>
## Retrospective — {date}

### Clusters
- **{theme}** ({count} learnings): {summary}

### Actions Taken
- Merged: {count} duplicate learnings
- Archived: {count} stale learnings
- Contradictions resolved: {count}

### Promotable Patterns
- {pattern}: reinforced {N}x, evidence: {summary}
  - Recommend: {where to encode}

### Health
- Total learnings: {N}
- Active: {N} | Stale: {N} | Reinforced: {N}
</output_format>

</command>
