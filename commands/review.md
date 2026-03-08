<command id="kernel:review">
<description>Code review for PRs or staged changes. >80% confidence threshold. Verdict: APPROVE / REQUEST CHANGES / COMMENT.</description>

<!-- ============================================ -->
<!-- PURPOSE                                      -->
<!-- ============================================ -->

<purpose>
Review code changes for quality, correctness, and security.
Spawns kernel:reviewer agent for execution.
Only reports issues with >80% confidence - no noise, no nitpicks.
</purpose>

<!-- ============================================ -->
<!-- STARTUP                                      -->
<!-- ============================================ -->

<startup>
STEP 1: Read AgentDB
```
agentdb read-start
```

STEP 2: Load skills
```
skills/testing/SKILL.md
skills/security/SKILL.md
```

STEP 3: Identify scope
```bash
# For PRs
gh pr diff {number}

# For staged changes
git diff --staged --name-only

# For recent commits
git diff HEAD~1 --name-only
```
</startup>

<!-- ============================================ -->
<!-- CONFIDENCE THRESHOLD                         -->
<!-- ============================================ -->

<confidence>
## Threshold

**Report if >80% confident** it's a real issue.
**Skip** stylistic preferences unless violating explicit project conventions.
**Skip** issues in unchanged code unless CRITICAL security.
**Consolidate** similar issues into single findings.

## Calibration

| Confidence | Category | Examples |
|------------|----------|----------|
| 95%+ | Definite bug | Null dereference, type error, logic flaw |
| 85-95% | Likely issue | Missing edge case, race condition |
| 70-85% | Possible issue | Code smell, unclear intent |
| <70% | Don't report | Style preference, subjective |
</confidence>

<!-- ============================================ -->
<!-- REVIEW CHECKLIST                             -->
<!-- ============================================ -->

<checklist>
## Logic & Correctness
- [ ] Edge cases handled
- [ ] Error paths covered
- [ ] Null/undefined checks present
- [ ] Type safety maintained

## Security
- [ ] Input validation present
- [ ] No hardcoded secrets
- [ ] SQL injection prevented (parameterized queries)
- [ ] XSS prevented (output encoding)

## Performance
- [ ] No N+1 queries
- [ ] No unnecessary re-renders
- [ ] Appropriate caching

## Maintainability
- [ ] Clear naming
- [ ] Reasonable function length
- [ ] Single responsibility
</checklist>

<!-- ============================================ -->
<!-- OUTPUT FORMAT                                -->
<!-- ============================================ -->

<output_format>
```
CODE REVIEW
===========
Files: X changed
Findings: Y (Z critical)

CRITICAL
--------
[file:line] Issue description (confidence: XX%)
  → Fix: concrete suggestion

HIGH
----
[file:line] Issue description (confidence: XX%)
  → Fix: concrete suggestion

MEDIUM
------
[file:line] Issue description (confidence: XX%)
  → Fix: concrete suggestion

Summary: [APPROVE / REQUEST CHANGES / COMMENT]
```
</output_format>

<!-- ============================================ -->
<!-- VERDICT RULES                                -->
<!-- ============================================ -->

<verdict>
**APPROVE**: No critical or high issues. Minor issues acceptable.
**REQUEST CHANGES**: Any critical or high issue present.
**COMMENT**: Only medium/low issues. Optional improvements only.

CRITICAL issue = automatic REQUEST CHANGES. No exceptions.
</verdict>

<!-- ============================================ -->
<!-- ON COMPLETE                                  -->
<!-- ============================================ -->

<on_complete>
agentdb write-end '{"command":"review","files":<N>,"findings":<N>,"critical":<N>,"high":<N>,"verdict":"approve|request_changes|comment"}'

Write findings to AgentDB `reviews` table for tracking.
</on_complete>

</command>
