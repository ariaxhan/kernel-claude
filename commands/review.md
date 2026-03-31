---
name: kernel:review
description: "Code review for PRs or staged changes. >80% confidence threshold. Verdict: APPROVE, REQUEST CHANGES, or COMMENT. Triggers: review, pr, code review."
user-invocable: true
allowed-tools: Read, Bash, Grep, Glob
---

<command id="review">

<purpose>
Review code changes for quality, correctness, security.
Only report issues with >80% confidence.

Load: skills/testing/SKILL.md, skills/security/SKILL.md
Reference: _meta/research/ai-code-anti-patterns.md
</purpose>

<context>
ai_code_stats:
  buggier: 1.7x more issues than human code
  security: 40-62% contain vulnerabilities
  findings: 10.83 per AI PR vs 6.45 human

priority: check Big 5 first (what AI actually breaks)
</context>

<on_start>
```bash
agentdb read-start
```

<identify_scope>
```bash
gh pr diff {number}        # For PRs
git diff --staged          # For staged
git diff HEAD~1            # For recent
```
</identify_scope>
</on_start>

<confidence_threshold>
| Confidence | Category | Report? |
|------------|----------|---------|
| 95%+ | Definite bug | YES |
| 85-95% | Likely issue | YES |
| 70-85% | Possible issue | MAYBE |
| <70% | Style preference | NO |
</confidence_threshold>

<big5 name="BIG 5: AI-SPECIFIC CONCERNS">
Check these FIRST - what AI actually breaks:

<check id="1_input_validation">
- Zod/Pydantic schema for every API endpoint?
- Parameterized queries (no string concat)?
- File uploads validated (size, type, extension)?
detection: grep -r "req\.body" | grep -v "parse\|validate\|z\."
</check>

<check id="2_edge_cases">
- Null/undefined handling present?
- Empty arrays handled (length check)?
- Zero-length strings rejected?
- Timeout handling for external calls?
</check>

<check id="3_error_handling">
- No empty catch blocks?
- Errors logged with context?
- User-facing messages generic?
detection: grep -r "catch.*{}" (empty catch)
</check>

<check id="4_duplication">
- Same logic repeated in multiple places?
- Should be extracted to shared utility?
</check>

<check id="5_complexity">
- Functions > 30 lines?
- Nested ternaries > 2 levels?
</check>
</big5>

<checklist>
<section name="Logic & Correctness">
- [ ] Edge cases handled
- [ ] Error paths covered
- [ ] Null checks present
- [ ] Type safety
</section>

<section name="Security">
- [ ] Input validation (Zod schema)
- [ ] No hardcoded secrets
- [ ] SQL injection prevented (parameterized queries)
- [ ] XSS prevented (DOMPurify)
- [ ] Auth tokens in httpOnly cookies
</section>

<section name="Performance">
- [ ] No N+1 queries
- [ ] Appropriate caching
</section>
</checklist>

<output_format>
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
</output_format>

<ask_user>
  Use AskUserQuestion when: a finding is between 70-85% confidence (ambiguous)
  Ask: "Found {issue} at {file:line} (confidence {X}%). Intentional, or should I flag it?"
  Options: intentional — skip, flag it, investigate deeper
</ask_user>

<verdict_rules>
- **APPROVE**: No critical or high issues
- **REQUEST CHANGES**: Any critical or high issue
- **COMMENT**: Only medium/low issues
</verdict_rules>

<on_complete>
```bash
agentdb write-end '{"command":"review","verdict":"X","critical":N,"high":N,"big5_violations":N}'
```
</on_complete>

</command>
