---
name: kernel:handoff
description: "Generate context handoff brief for session continuation. Saves state, decisions, next steps. Triggers: handoff, save, pause, context, continue later."
user-invocable: true
allowed-tools: Read, Bash, Grep, Glob
---

# ON START

```bash
agentdb read-start
```

---

# PHASE 1: EXTRACT STATE

- **Goal**: What is the user trying to achieve?
- **Position**: Where are we in the workflow?
- **Decisions**: Choices made and why (include rejected alternatives)
- **Open threads**: Unfinished items
- **Artifacts**: Files created (with paths)
- **Warnings**: Failed approaches to avoid

---

# PHASE 2: GATHER EVIDENCE

```bash
git status --short
git diff --stat
git log --oneline -10
git stash list
find . -type f -mmin -120 | grep -v node_modules | grep -v .git | head -20
agentdb query "SELECT * FROM context WHERE type IN ('contract','checkpoint') ORDER BY ts DESC LIMIT 5"
```

---

# PHASE 3: GIT HYGIENE

- Uncommitted changes? Commit with "wip: checkpoint before handoff" or stash
- Push current branch to remote
- Document any stashed work

---

# OUTPUT FORMAT

```markdown
## CONTEXT HANDOFF
Generated: {timestamp}

**Summary**: [One sentence]

**Goal**: [What user is trying to achieve]

**Current state**: [Where things stand]

**Branch**: [branch name, clean/dirty]

**Decisions made**:
- [Decision: choice + rationale]

**Artifacts created**:
- [path: purpose]

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

---

# DELIVERY

1. Save to `_meta/handoffs/{feature}-{date}.md`
2. Commit: "docs: context handoff for {feature}"
3. Push to remote

---

# ON END

```bash
agentdb write-end '{"command":"handoff","saved_to":"path","branch":"X"}'
```
