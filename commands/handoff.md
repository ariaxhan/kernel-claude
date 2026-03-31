---
name: kernel:handoff
description: "Generate context handoff brief for session continuation. Saves state, decisions, next steps. Triggers: handoff, save, pause, context, continue later."
user-invocable: true
allowed-tools: Read, Bash, Grep, Glob
---

<command id="handoff">

<purpose>
Save session state for seamless continuation.
Context = decisions + artifacts + warnings + next steps.
A good handoff lets the next session start working immediately.

Reference: skills/context/SKILL.md
</purpose>

<on_start>
```bash
agentdb read-start
```
</on_start>

<phase id="1_extract" name="EXTRACT STATE">
<capture>
goal: What is the user trying to achieve?
position: Where are we in the workflow?
decisions: Choices made and why (include rejected alternatives)
open_threads: Unfinished items
artifacts: Files created (with paths)
warnings: Failed approaches to avoid
</capture>

<ai_context>
calibration: What tier is this work? (affects handoff detail)
  tier_1: brief handoff (1-2 files, simple)
  tier_2: moderate handoff (3-5 files, orchestrated)
  tier_3: detailed handoff (6+ files, complex)

big5_status: Which of the Big 5 were addressed?
  - input validation
  - edge cases
  - error handling
  - duplication
  - complexity
</ai_context>
</phase>

<phase id="2_gather" name="GATHER EVIDENCE">
```bash
git status --short
git diff --stat
git log --oneline -10
git stash list
find . -type f -mmin -120 | grep -v node_modules | grep -v .git | head -20
agentdb query "SELECT * FROM context WHERE type IN ('contract','checkpoint') ORDER BY ts DESC LIMIT 5"
```
</phase>

<ask_user>
  Use AskUserQuestion when: state extraction complete, before writing handoff
  Ask: "Anything to add to the handoff? Blockers, decisions, or context I might have missed?"
  Options: looks complete, add context, skip handoff
</ask_user>

<phase id="3_hygiene" name="GIT HYGIENE">
<checks>
uncommitted: Commit with "wip: checkpoint before handoff" or stash
push: Push current branch to remote
stashed: Document any stashed work
</checks>
</phase>

<output_format>
```markdown
## CONTEXT HANDOFF
Generated: {timestamp}

**Summary**: [One sentence]

**Goal**: [What user is trying to achieve]

**Current state**: [Where things stand]

**Branch**: [branch name, clean/dirty]

**Tier**: [1/2/3] - [brief/moderate/detailed]

**Decisions made**:
- [Decision: choice + rationale]

**Artifacts created**:
- [path: purpose]

**Big 5 Status**:
- [ ] Input validation - [done/pending/n/a]
- [ ] Edge cases - [done/pending/n/a]
- [ ] Error handling - [done/pending/n/a]
- [ ] Duplication - [done/pending/n/a]
- [ ] Complexity - [done/pending/n/a]

**Open threads**:
- [BLOCKER: item]
- [TODO: item]

**Next steps**:
1. [Specific action]
2. [Second action]

**Warnings**:
- [Failed approach: why]

**Continuation prompt**:
> /kernel:ingest [goal]. [position]. Read _meta/handoffs/{filename}.
```
</output_format>

<delivery>
1. Save to `_meta/handoffs/{feature}-{date}.md`
2. Commit: "docs: context handoff for {feature}"
3. Push to remote
</delivery>

<on_complete>
```bash
agentdb write-end '{"command":"handoff","saved_to":"path","branch":"X","tier":N}'
# Suggest /kernel:retrospective if learnings accumulated across sessions
```
</on_complete>

</command>
