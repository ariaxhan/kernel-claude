---
name: eval
description: "Eval-Driven Development (EDD) for AI workflows. pass@k metrics, capability evals, regression evals. Triggers: eval, edd, pass@k, capability, regression, benchmark."
allowed-tools: Read, Bash, Write, Edit, Grep, Glob
---

<skill id="eval">

<purpose>
Evals are the unit tests of AI development. Define success BEFORE implementation.
pass@k measures reliability: did it succeed within k attempts?
Capability evals test new abilities. Regression evals prevent breakage.
</purpose>

<prerequisite>
AgentDB read-start has run. Check for existing eval definitions.
Understand what behavior you're evaluating before writing evals.
</prerequisite>

<reference>
Skill-specific: skills/eval/reference/eval-research.md
</reference>

<core_principles>
1. DEFINE BEFORE CODE: Evals written first force clear thinking about success criteria.
2. CODE GRADERS > MODEL GRADERS: Deterministic checks beat probabilistic judgments.
3. STRUCTURAL SEPARATION FOR HIGH-STAKES: When stakes are real (security, payments, eval-of-evals, agent quality scoring), use the blind-evaluator agent — never self-score. Self-scoring inflates results ~36% structurally; procedural separation ("I won't peek") does not fix it.
4. TRACK PASS@K: pass@1 (first attempt), pass@3 (within 3 attempts). Target pass@3 > 90%.
5. REGRESSION BEFORE SHIP: Every change must pass existing evals before merge.
6. FAST EVALS GET RUN: Slow evals get skipped. Keep evaluation fast.
</core_principles>

<blind_evaluation_protocol>
For any eval where the implementing agent would otherwise score its own output:

1. Spawn `agents/blind-evaluator.md` as a fresh agent.
2. Pass it ONLY: problem statement, rubric (3-7 criteria with PASS conditions + weights), artifact path.
3. Do NOT pass: implementer's checkpoint, summary, commit message, prompt, or expected solution.
4. The blind evaluator runs a contamination check first; if it sees anything from the forbidden list, it returns `INVALID` and the eval is aborted until inputs are cleaned.
5. Confidence < 0.7 from the blind evaluator = escalate to human grader.

Use a two-phase eval protocol when feasible:
- Run 1: implementing agent solves cold, with no eval feedback. Blind evaluator scores. This is the real number.
- Run 2: implementing agent gets the Run 1 score + rubric breakdown, then optimizes. Useful for iteration but Run 1 is what you report externally.
</blind_evaluation_protocol>

<eval_types>
<!-- Capability Eval: Can it do something new? -->
```markdown
[CAPABILITY EVAL: semantic-search]
Task: Search markets using natural language
Success Criteria:
  - [ ] Returns relevant results for query
  - [ ] Handles empty query gracefully
  - [ ] Falls back when vector DB unavailable
Expected: Top 5 results match query intent
```

<!-- Regression Eval: Does existing functionality still work? -->
```markdown
[REGRESSION EVAL: auth-flow]
Baseline: commit abc123
Tests:
  - login-with-valid-creds: PASS
  - login-with-invalid-creds: PASS
  - session-persistence: PASS
Result: 3/3 passed (unchanged)
```
</eval_types>

<grader_types>
<!-- Code-Based Grader (preferred) -->
```bash
grep -q "export function handleAuth" src/auth.ts && echo "PASS" || echo "FAIL"
npm test -- --testPathPattern="auth" && echo "PASS" || echo "FAIL"
npm run build && echo "PASS" || echo "FAIL"
```

<!-- Model-Based Grader (open-ended outputs) -->
```markdown
[MODEL GRADER]
Evaluate: Does this code solve the stated problem?
Criteria: correctness, structure, edge case handling
Score: 1-5
Reasoning: [required]
```

<!-- Human Grader (security, UX) -->
```markdown
[HUMAN REVIEW REQUIRED]
Change: Added payment processing
Reason: Security-critical, requires human verification
Risk: HIGH
```
</grader_types>

<metrics>
pass@k: "At least one success in k attempts"
- pass@1: First attempt success rate
- pass@3: Success within 3 attempts (typical target: > 90%)

pass^k: "All k trials succeed"
- pass^3: 3 consecutive successes
- Use for critical paths (auth, payments)
</metrics>

<workflow>
1. DEFINE: Write eval criteria before implementation
2. IMPLEMENT: Code to pass defined evals
3. EVALUATE: Run evals, record pass@k
4. REPORT: Document results, identify failures
</workflow>

<eval_report_format>
```markdown
EVAL REPORT: feature-xyz
========================
Capability Evals:
  create-user:     PASS (pass@1)
  validate-email:  PASS (pass@2)
  hash-password:   PASS (pass@1)
  Overall:         3/3

Regression Evals:
  login-flow:      PASS
  session-mgmt:    PASS
  Overall:         2/2

Metrics:
  pass@1: 67% (2/3)
  pass@3: 100% (3/3)

Status: READY FOR REVIEW
```
</eval_report_format>

<anti_patterns>
<block id="eval_after_code">Writing evals after implementation tests existing bugs, not requirements.</block>
<block id="model_grader_overuse">Model-based grading is slow and probabilistic. Prefer code graders.</block>
<block id="skip_regression">Every change must pass regression evals. No exceptions.</block>
<block id="slow_evals">Evals that take > 30s get skipped. Keep them fast.</block>
<block id="no_tracking">Track pass@k over time. Declining reliability is a signal.</block>
<block id="self_score">For any user-facing or high-stakes eval, the implementing agent scoring its own work inflates results ~36%. Spawn blind-evaluator instead.</block>
<block id="post_merge_eval">Evaluating against a codebase that already contains the canonical solution = answer key in the eval set. Use pre-merge snapshots or a separate fixture.</block>
<block id="greenfield_in_golden_dataset">Greenfield tickets in the golden eval set collapse to self=10, blind=3. Greenfields are not evaluable as solved tasks — exclude them from the dataset.</block>
<block id="context_breadth_before_baseline">Optimizing how much context the evaluator gets before establishing a baseline score = can't distinguish signal from noise. Run minimal-context baseline first, then test additions one at a time.</block>
</anti_patterns>

<on_complete>
agentdb write-end '{"skill":"eval","eval_type":"capability|regression","pass_at_1":"<X%>","pass_at_3":"<Y%>","failures":["<list>"]}'

Record eval type, pass rates, and any failures for future reference.
</on_complete>

</skill>
