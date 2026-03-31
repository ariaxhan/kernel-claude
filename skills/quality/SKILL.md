---
name: quality
description: "AI code quality checks. The Big 5: input validation, edge cases, error handling, duplication, complexity. Triggers: quality, big 5, ai code, review, validate."
allowed-tools: Read, Grep, Bash
---

<skill id="quality">

<purpose>
AI code is 1.7x buggier. These 5 checks catch 80% of issues.
Load this skill for any review, validation, or implementation work.
</purpose>

<reference>
Verbose research: skills/quality/reference/quality-research.md
</reference>

<big5>
<check id="1" name="input_validation" detection="grep -r 'req\.body' | grep -v 'parse\|validate\|z\.'">
Every endpoint has Zod/Pydantic schema. Parameterized queries only.
</check>

<check id="2" name="edge_cases" detection="search for array access without length check">
Handle: null, empty array, zero-length string, timeout, unicode.
</check>

<check id="3" name="error_handling" detection="grep -r 'catch.*{}'">
No empty catch. Errors logged with context. User messages generic.
</check>

<check id="4" name="duplication" detection="jscpd or manual review">
Same logic in 3+ places = extract to utility.
</check>

<check id="5" name="complexity" detection="eslint complexity rule">
Functions under 30 lines. No nested ternaries > 2 levels.
</check>
</big5>

<quick_checks>
```bash
# 1. Missing validation
grep -r "req\.body" --include="*.ts" --include="*.js" | grep -v "parse\|validate\|z\." | head -5

# 2. Empty catch blocks
grep -r "catch.*{}" --include="*.ts" --include="*.js" | head -5

# 3. String concat in queries (SQL injection)
grep -rE "SELECT.*\$\{|INSERT.*\$\{" --include="*.ts" --include="*.js" | head -5
```
</quick_checks>

<verdict>
Any Big 5 violation = NOT READY
Fix before commit. No exceptions.
</verdict>

<r_factor>
  Composite quality score replacing binary pass/fail.

  R = (0.20 * test_pass_rate) +
      (0.20 * acceptance_rate) +
      (0.15 * scope_accuracy) +
      (0.15 * security_clean_rate) +
      (0.15 * budget_compliance) +
      (0.15 * first_try_rate)

  Range: 0.0 to 1.0

  thresholds:
    >= 0.85: production-ready
    >= 0.70: good (ship with monitoring)
    >= 0.50: acceptable (ship with caveats)
    < 0.50: not ready (fix before shipping)

  measurement:
    test_pass_rate: passing tests / total tests
    acceptance_rate: acceptance criteria met / total criteria
    scope_accuracy: files in contract / files actually changed (1.0 = perfect scope)
    security_clean_rate: 1.0 if no security findings, 0.0 otherwise
    budget_compliance: 1.0 if within budget, decreases proportionally over budget
    first_try_rate: 1.0 if merged without revision, decreases per revision round

  usage:
    - Validator reports R-factor in verdict
    - /kernel:forge uses R-factor in quench phase (>= 0.8 = survived)
    - /kernel:metrics displays R-factor trend
    - agentdb verdict stores R-factor in evidence JSON

  rule: R-factor is informational, not a hard gate. Use thresholds as guidelines.
  rule: Track R-factor over time to measure improvement, not as a one-time score.
</r_factor>

</skill>
