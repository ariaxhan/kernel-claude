---
name: kernel:tearitapart
description: "Critical pre-implementation review. Find problems before coding. Verdict: PROCEED, REVISE, or RETHINK. Triggers: review plan, tear apart, critique, analyze."
user-invocable: true
allowed-tools: Read, Bash, Grep, Glob
---

# ON START

```bash
agentdb read-start
```

Load: skills/architecture/SKILL.md, skills/testing/SKILL.md, skills/security/SKILL.md

**Constraints:**
- Run after planning, before implementing
- If REVISE or RETHINK, update plan and re-run
- Adversarial mindset: "how could this break?"

---

# PHASE 0: GATHER CONTEXT

1. Read the plan/spec being reviewed
2. Identify all files that will be touched
3. Check git status
4. Check AgentDB for prior contracts

---

# PHASE 1: CRITICAL ISSUES

**Must fix before proceeding.**

## Requirements
- Missing requirements?
- Contradictory requirements?
- Unstated assumptions?
- Wrong problem?

## Technical
- Technically impossible?
- Missing infrastructure?
- Data integrity risks?
- Race conditions?
- Breaking changes?

## Security
- Input validation?
- Authentication gaps?
- Authorization gaps?
- Data exposure?
- Injection risks?

---

# PHASE 2: CONCERNS

**Should address before or during implementation.**

- Edge cases (null, empty, unicode)
- Performance (N+1, unbounded fetches)
- Maintenance burden
- Testing difficulty
- Error handling

---

# PHASE 3: QUESTIONS

- Ambiguous requirements?
- Missing context?
- Alternative approaches?
- Scope boundaries?

---

# PHASE 4: ARCHITECTURE

- Separation of concerns?
- Coupling/cohesion?
- Interface stability?
- Pattern consistency?

---

# VERDICT

| Verdict | Meaning |
|---------|---------|
| **PROCEED** | Minor issues only. List caveats. |
| **REVISE** | Addressable issues. List specific changes. |
| **RETHINK** | Fundamental problems. Suggest alternative. |

**Rules:**
- Any critical issue = minimum REVISE
- Multiple criticals = RETHINK
- Security vulnerability = minimum REVISE

---

# OUTPUT

Save to `_meta/reviews/{feature}-teardown.md`:

```markdown
# Tear Down: {feature}
Reviewed: {timestamp}

## Critical Issues
## Security Review
## Concerns
## Questions
## Verdict: PROCEED | REVISE | RETHINK
```

---

# ON END

```bash
agentdb write-end '{"command":"tearitapart","verdict":"X","critical_count":N}'
```
