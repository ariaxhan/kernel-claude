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

<adsr>
  Proactive deviation detection. Don't wait for bugs — detect behavioral anomalies.

  cycle:
    anomaly:     deviation from baseline (token spike, unusual files, scope creep)
    detection:   automated on every checkpoint (compare to historical averages)
    suppression: block progression, alert human, quarantine work
    recovery:    critical = human review required. medium = auto-retry after fix

  baselines:
    tokens_per_tier: avg from agentdb execution_traces
    files_per_contract: avg from agentdb contracts
    duration_per_task: avg from agentdb events

  thresholds:
    warning: > 1.5x baseline
    anomaly: > 2x baseline
    critical: > 3x baseline

  integration:
    - validator checks baselines during quench phase
    - forge loop checks between iterations
    - orchestrator checks after each agent completes

  rule: anomaly = pause and ask, not auto-abort.
  rule: build baselines from at least 10 historical data points before enforcing.
</adsr>

</skill>
