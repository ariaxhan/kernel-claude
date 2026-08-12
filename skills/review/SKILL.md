---
name: review
description: "Code review for PRs or staged changes. >80% confidence threshold. Verdict: APPROVE, REQUEST CHANGES, or COMMENT. Triggers: review, pr, code review."
user-invocable: true
allowed-tools: Read, Bash, Grep, Glob
kernel:
  kind: validator
  version: 1
  side_effects: none
  confirmation: none
---

<skill id="review">

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
Review is finite because its purpose is AUTHORIZATION, not exhaustion. Approve once the change
improves the health of the codebase, not once nothing else can be found. Nothing else can ever
be found. (#204)

- **APPROVE**: no finding clears the block bar. **Open non-blocking comments do NOT prevent
  APPROVE** — say the issue number out loud and approve. Forcing another round to re-check a nit
  costs more than the nit.
- **REQUEST CHANGES**: at least one finding clears the block bar below.
- **COMMENT**: findings worth saying, none blocking, and the author asked for a read rather than
  a decision.

<block_bar>
A finding blocks only with ALL of:
1. pasted output, not a described procedure
2. a distance proof threshold cleared — distance sets how much evidence is needed, never whether
   a finding may block:
   d0 changed code fails · d1 violates a declared invariant · d2 pre-existing defect this change
   exposed, needs a user-visible consequence · d3+ needs outside assumptions, blocks only on an
   executed demonstration or a cited prior failure. Never auto-close d3; taste never clears it,
   a real outcome does.
3. a named observable failure: predict what breaks and how we would see it
4. on-objective: a production-hardening finding on a demo is not a blocker however real it is

Everything else is filed with its `distance:N` label under the `quarantine` milestone. Recurrence
is signal, silence is a verdict.
</block_bar>

Read the acceptance record before reviewing: claims, declared invariants, and tradeoffs already
accepted. Reopening a settled entry takes new evidence of a named kind, never a new opinion.
Never ask a reviewer whether criticism is complete; it cannot answer and will always say no.
</verdict_rules>

<on_complete>
```bash
agentdb write-end '{"command":"review","verdict":"X","critical":N,"high":N,"big5_violations":N}'
```
</on_complete>

</skill>
