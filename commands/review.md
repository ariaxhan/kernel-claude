---
name: kernel:review
description: "Code review for PRs or staged changes. >80% confidence threshold. Verdict: APPROVE, REQUEST CHANGES, or COMMENT. Triggers: review, pr, code review."
user-invocable: true
allowed-tools: Read, Bash, Grep, Glob
---

# PURPOSE

Review code changes for quality, correctness, security.
Only report issues with >80% confidence.

---

# STARTUP

```bash
agentdb read-start
```

## Identify scope
```bash
gh pr diff {number}        # For PRs
git diff --staged          # For staged
git diff HEAD~1            # For recent
```

---

# CONFIDENCE THRESHOLD

| Confidence | Category | Report? |
|------------|----------|---------|
| 95%+ | Definite bug | YES |
| 85-95% | Likely issue | YES |
| 70-85% | Possible issue | MAYBE |
| <70% | Style preference | NO |

---

# CHECKLIST

## Logic & Correctness
- [ ] Edge cases handled
- [ ] Error paths covered
- [ ] Null checks present
- [ ] Type safety

## Security
- [ ] Input validation
- [ ] No hardcoded secrets
- [ ] SQL injection prevented
- [ ] XSS prevented

## Performance
- [ ] No N+1 queries
- [ ] Appropriate caching

---

# OUTPUT FORMAT

```
CODE REVIEW
===========
Files: X changed
Findings: Y (Z critical)

CRITICAL
--------
[file:line] Issue (confidence: XX%)
  → Fix: suggestion

HIGH
----
[file:line] Issue (confidence: XX%)
  → Fix: suggestion

Summary: APPROVE | REQUEST CHANGES | COMMENT
```

---

# VERDICT RULES

- **APPROVE**: No critical or high issues
- **REQUEST CHANGES**: Any critical or high issue
- **COMMENT**: Only medium/low issues

---

# ON COMPLETE

```bash
agentdb write-end '{"command":"review","verdict":"X","critical":N}'
```
