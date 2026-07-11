---
name: retrospective
description: "Cross-session learning synthesis. Finds patterns, resolves contradictions, promotes insights into project skills, agents, and hooks. Triggers: retrospective, reflect, patterns, learnings, synthesis."
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
kernel:
  kind: state_transition
  version: 1
  side_effects: writes_repo
  confirmation: on_side_effect
  produces:
    - kernel.retrospective-result/v1
---

<skill id="retrospective">

<purpose>
Cross-session learning synthesis. Reviews AgentDB learnings, finds patterns across sessions,
resolves contradictions, merges duplicates, archives stale entries, then promotes surviving
patterns into ARTIFACTS (project hooks, agents, skills), not prose. A learning that stays a
sentence in a doc is honor-system; an artifact fires on its own.
</purpose>

<execution>
1. Pull all learnings from AgentDB:
   ```bash
   agentdb query "SELECT id, type, insight, evidence, hit_count, load_count, ts FROM learnings ORDER BY ts DESC"
   ```

2. Pull recent checkpoints for session context:
   ```bash
   agentdb recent
   ```

3. Analyze learnings across 6 dimensions:
   - **Clusters**: Group related learnings by theme (e.g., hook loading, git workflow, testing)
   - **Duplicates**: Identify learnings that say the same thing differently, merge into strongest form
   - **Contradictions**: Find learnings that conflict, resolve with evidence, archive the loser
   - **Stale**: Flag learnings not reinforced in 30+ days with no recent evidence
   - **Promotable**: Identify patterns worth encoding as artifacts (hit_count 2+, OR hit_count 1x
     when the failure mode is quiet/expensive, don't wait for a third burn on a costly lesson)
   - **Project fit**: Audit the host project's `.claude/` against its actual work. A recurring
     manual pattern with no skill → skill candidate. A repeated safety catch with no hook → hook
     candidate. A skill/agent that never fires → prune candidate.

4. Promote via the artifact ladder (most enforceable form that fits, never default to prose):
   - **Hook**, the pattern is a safety property or a mechanical check (I0.15: hooks, not
     honor-system). Scaffold a PreToolUse/PreCommit script under the project's `.claude/hooks/`.
   - **Agent**, the pattern is a recurring role with its own judgment (a reviewer lens, a
     domain validator). Scaffold `.claude/agents/<name>.md`.
   - **Skill**, the pattern is methodology: a repeatable HOW for this project's work.
     Scaffold `.claude/skills/<name>/SKILL.md` with triggers phrased the way tasks are asked.
   - **CLAUDE.md prose**, last resort, only for context no mechanism can enforce.
   Scaffold means WRITE THE FILE in this session, a draft artifact the human can reject beats
   a recommendation nobody actions. Artifacts land in the host project's `.claude/`, not the
   kernel plugin, unless the lesson is genuinely cross-project.

   <ask_user>
     Use AskUserQuestion when: promotable patterns found.
     Ask: "Found {N} promotable patterns. Scaffolding as {hooks/agents/skills}, approve?"
     Options: scaffold all, review each, skip promotion
     Prune candidates (dormant skills/agents) always require explicit approval before removal.
   </ask_user>

5. Take housekeeping actions:
   - Merge duplicates: `agentdb learn {type} "{merged}" "{combined evidence}"`
   - Archive stale: `agentdb query "DELETE FROM learnings WHERE id = {id}"`
   - If non-local profile: surface promoted patterns to GitHub Discussions (Learnings category)

6. Emit the machine-readable mutation record — MANDATORY, not optional:
   Write `_meta/reports/retrospective-{date}.json` per
   schemas/kernel.retrospective-result.v1.schema.json:
   - analyzed: learnings/clusters/merged/archived/contradictions_resolved counts
   - mutations[]: every artifact created/modified/removed/promoted —
     {op, artifact_type: hook|agent|skill|prose|learning, path, reason, evidence,
     reinforced, status: applied|scaffolded|proposed|rejected}
   - project_fit: missing[] and dormant[] (prune candidates need explicit approval)
   Then validate:
   ```bash
   "${CLAUDE_PLUGIN_ROOT:-.}/orchestration/manifest/kernel-manifest" validate _meta/reports/retrospective-{date}.json
   ```
   Future handoffs reference this file via provenance.retrospective_refs, so resumed
   work knows which infrastructure mutations it depends on.

7. Write synthesis to AgentDB:
   ```bash
   agentdb write-end '{"did":"retrospective","clusters":N,"merged":N,"archived":N,"promoted":N,"artifacts":["path1","path2"],"mutation_record":"_meta/reports/retrospective-{date}.json"}'
   ```
</execution>

<output_format>
## Retrospective, {date}

### Clusters
- **{theme}** ({count} learnings): {summary}

### Actions Taken
- Merged: {count} duplicate learnings
- Archived: {count} stale learnings
- Contradictions resolved: {count}

### Artifacts Promoted
- {pattern} → **{hook|agent|skill|prose}** at `{path}` (reinforced {N}x, evidence: {summary})

### Project Fit
- Missing: {recurring pattern with no artifact} → {proposed artifact}
- Dormant: {skill/agent that never fires} → prune candidate

### Health
- Total learnings: {N}
- Active: {N} | Stale: {N} | Reinforced: {N}

### Mutation Record
- `_meta/reports/retrospective-{date}.json` (kernel.retrospective-result/v1, validated)
</output_format>

</skill>
