---
name: experiment
description: "Scientific method for development rules. Every rule is a hypothesis. Nothing proven until tested. Triggers: experiment, hypothesis, prove, test rule, validate methodology, scientific, evidence."
allowed-tools: Read, Grep, Bash, Write
---

<skill id="experiment">

<purpose>
Rules without evidence are superstitions. Apply scientific method: register hypothesis, design experiment, execute, record evidence, update confidence, graduate or kill.
</purpose>

<reference>
Deep patterns, SQL schema, domain design templates, confidence-scoring examples: skills/experiment/reference/experiment-research.md
</reference>

<flags>
  --domain <name>: filter to domain (methodology|coordination|testing|git|security|performance|quality)
  --status <status>: filter by status (unproven|testing|supported|refuted|graduated)
  --confidence <threshold>: filter by minimum confidence
</flags>

<flow>

1. **Seed**, parse CLAUDE.md for imperative/assertive statements → register as hypotheses
   - (gate: each hypothesis has id, statement, source, domain, status=unproven, confidence=0.0)
   - Auto-assign H001, H002, … ; classify domain from <domains> list
   - `agentdb learn hypothesis "H{N}: {statement}" "{source}:{line}"`

2. **Design**, for each hypothesis under test, define experiment BEFORE running anything
   - method: what you will do (A/B, timed comparison, fuzz, track-and-count)
   - measurement: quantitative metric preferred (time, error count, rework frequency)
   - control condition: what happens WITHOUT the rule applied
   - pass_criteria: specific observable that supports the hypothesis
   - fail_criteria: specific observable that refutes it
   - (gate: experiment_designed, must be falsifiable; if no outcome could refute, redesign)

3. **Execute**, run the experiment; record raw observations
   - (gate: control condition was actually tested, not just assumed)
   - minimum sample sizes: methodology/coordination/git/quality ≥ 3 comparisons; testing ≥ 5 tasks per condition; security ≥ 50 fuzz inputs

4. **Score**, apply Bayesian update to confidence
   - supports:     `confidence += (1 - confidence) * 0.25`
   - refutes:      `confidence -= confidence * 0.3`
   - inconclusive: no change (record in evidence log)
   - `agentdb learn experiment "H{N} result={supports|refutes|inconclusive}" "{evidence}"`

5. **Transition**, update hypothesis status per lifecycle rules
   - unproven → testing: first experiment registered
   - testing → supported: confidence ≥ 0.8 AND evidence_for ≥ 3 AND ratio ≥ 3:1
   - testing → refuted: confidence < 0.2 AND evidence_against ≥ 2
   - supported → graduated: human approval after sustained confidence
   - refuted → killed: human approval to remove from rules
   - any → unproven: rule is modified (resets all evidence)
   - (gate: evidence_recorded, verdict must include specific, measurable evidence string)

6. **Report**, surface verdict
   - verdict: SUPPORTED | REFUTED | INCONCLUSIVE
   - confidence: current 0.0–1.0 value
   - evidence: required (specific, measurable, not narrative)
   - if GRADUATED: promote via the artifact ladder with human approval, hook if
     enforceable, agent if a role, skill if methodology; CLAUDE.md prose only as last resort
   - if KILLED: propose rule removal from CLAUDE.md with human approval

</flow>

<anti_patterns>
  <never>Confirm a hypothesis without running a real experiment.</never>
  <never>Use a single data point to graduate a hypothesis.</never>
  <never>Ignore refuting evidence because the rule "feels right".</never>
  <never>Test a hypothesis with a method that can only confirm (design for falsifiability).</never>
  <never>Modify the hypothesis after seeing results (that is a new hypothesis).</never>
</anti_patterns>

<on_complete>
agentdb write-end '{"skill":"experiment","hypotheses_tested":N,"graduated":[],"killed":[],"inconclusive":[]}'
</on_complete>

</skill>
