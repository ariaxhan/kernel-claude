---
name: experiment
description: "Scientific method for development rules. Every rule is a hypothesis. Nothing proven until tested. Triggers: experiment, hypothesis, prove, test rule, validate methodology, scientific, evidence."
allowed-tools: Read, Grep, Bash, Write
---

<skill id="experiment">

<purpose>
Rules without evidence are superstitions. This skill treats every development rule
as a hypothesis and applies the scientific method: register, design experiment,
execute, record evidence, update confidence, graduate or kill.

Load this skill when questioning methodology, validating rules, or running experiments.
</purpose>

<reference>
Verbose research: _meta/research/experiment-report.md (if exists)
</reference>

<sources>
- _meta/research/experiment-report.md (if exists)
</sources>

<triggers>experiment, hypothesis, prove, test rule, validate methodology, scientific, evidence</triggers>

<gates>
  <gate id="hypothesis_registered">Every rule under test must have an AgentDB hypothesis record.</gate>
  <gate id="experiment_designed">Method + measurement + pass/fail criteria defined BEFORE execution.</gate>
  <gate id="evidence_recorded">Every experiment produces a verdict with evidence string.</gate>
  <gate id="no_confirmation_bias">Experiments must be designed to DISPROVE, not confirm.</gate>
</gates>

<output>
  verdict: SUPPORTED | REFUTED | INCONCLUSIVE
  confidence: 0.0-1.0
  evidence: required (specific, measurable)
</output>

<flags>
  --domain <name>: filter to specific rule domain (methodology|coordination|testing|git|security|performance|quality)
  --status <status>: filter by hypothesis status (unproven|testing|supported|refuted|graduated)
  --confidence <threshold>: filter by minimum confidence
</flags>

<anti_patterns>
  <never>Confirm a hypothesis without running a real experiment.</never>
  <never>Use a single data point to graduate a hypothesis.</never>
  <never>Ignore refuting evidence because the rule "feels right".</never>
  <never>Test a hypothesis with a method that can only confirm (design for falsifiability).</never>
  <never>Modify the hypothesis after seeing results (that is a new hypothesis).</never>
</anti_patterns>

<lifecycle>
  The experiment lifecycle governs all hypothesis state transitions.

  ```
  UNPROVEN (0.0) --> TESTING (0.1-0.7) --> SUPPORTED (0.8+) or REFUTED (<0.2)
                                              |                    |
                                          GRADUATED              KILLED
                                         (proven rule)       (remove from rules)
  ```

  transitions:
    unproven --> testing:     first experiment registered
    testing --> supported:    confidence >= 0.8 AND evidence_for >= 3 AND ratio >= 3:1
    testing --> refuted:      confidence < 0.2 AND evidence_against >= 2
    supported --> graduated:  human approval after sustained confidence
    refuted --> killed:       human approval to remove from rules
    any --> unproven:         rule is modified (resets all evidence)
</lifecycle>

<domains>
  Rules cluster into testable domains. Classification guides experiment design.

  <domain id="methodology">Research-first, anti-patterns-before-solutions, slow-down-to-speed-up.</domain>
  <domain id="coordination">Parallel-first, tier system, agent spawning patterns.</domain>
  <domain id="testing">Tests-before-code, edge-cases-first, mock boundaries.</domain>
  <domain id="git">Atomic commits, conventional messages, feature branches.</domain>
  <domain id="security">No hardcoded secrets, input validation boundaries.</domain>
  <domain id="performance">Measure before optimizing, bottleneck identification.</domain>
  <domain id="quality">Big 5 checks, code review protocols, R-factor thresholds.</domain>
</domains>

<experiment_design>
  Six principles. Violating any one invalidates the experiment.

  <principle id="falsifiability">
    Every experiment must be able to disprove the hypothesis.
    If no possible outcome would refute the rule, the experiment is useless.
  </principle>

  <principle id="minimum_viable_test">
    Smallest possible scope that produces signal.
    One task comparison, not a week-long study.
  </principle>

  <principle id="quantitative_preferred">
    Numbers over opinions. Time, error count, recall percentage, rework frequency.
    Qualitative evidence is acceptable only when quantitative is impossible.
  </principle>

  <principle id="control_condition">
    Compare against baseline. What happens WITHOUT the rule?
    No control = no experiment. Just an observation.
  </principle>

  <principle id="reproducibility">
    Another session should be able to repeat the experiment with the same method.
    Record: exact steps, inputs, environment, measurement approach.
  </principle>

  <principle id="independence">
    Test one rule at a time. Control for confounds.
    If two rules interact, test each independently first.
  </principle>
</experiment_design>

<confidence_scoring>
  Bayesian-style updates after each experiment run.

  formulas:
    supports:     confidence += (1 - confidence) * 0.25
    refutes:      confidence -= confidence * 0.3
    inconclusive: no change (but recorded in evidence log)

  graduation:
    threshold: confidence >= 0.8
    required:  evidence_for >= 3
    ratio:     for:against >= 3:1

  kill:
    threshold: confidence < 0.2
    required:  evidence_against >= 2

  example:
    H001 starts at 0.0
    experiment 1: supports  --> 0.0 + (1.0 - 0.0) * 0.25 = 0.25
    experiment 2: supports  --> 0.25 + (1.0 - 0.25) * 0.25 = 0.4375
    experiment 3: refutes   --> 0.4375 - 0.4375 * 0.3 = 0.306
    experiment 4: supports  --> 0.306 + (1.0 - 0.306) * 0.25 = 0.480
    experiment 5: supports  --> 0.480 + (1.0 - 0.480) * 0.25 = 0.610
    experiment 6: supports  --> 0.610 + (1.0 - 0.610) * 0.25 = 0.708
    experiment 7: supports  --> 0.708 + (1.0 - 0.708) * 0.25 = 0.781
    experiment 8: supports  --> 0.781 + (1.0 - 0.781) * 0.25 = 0.836  --> GRADUATED
</confidence_scoring>

<seeding>
  Bootstrap hypotheses from existing CLAUDE.md rules.

  Parse rule-like patterns:
    - Imperative statements: "Never X", "Always Y", "Must Z"
    - Convention definitions: "Format: X", "Style: Y"
    - Assertions: "X is better than Y", "X before Y"
    - Quantitative claims: "reduces by X%", "takes N minutes"

  Each becomes a hypothesis record:
    id:         auto-generated (H001, H002, ...)
    statement:  the rule as stated
    source:     file path + line number
    domain:     auto-classified from domains list
    status:     unproven
    confidence: 0.0

  AgentDB schema:
    ```sql
    CREATE TABLE IF NOT EXISTS hypotheses (
      id TEXT PRIMARY KEY,
      statement TEXT NOT NULL,
      source TEXT NOT NULL,
      domain TEXT NOT NULL,
      status TEXT DEFAULT 'unproven',
      confidence REAL DEFAULT 0.0,
      evidence_for INTEGER DEFAULT 0,
      evidence_against INTEGER DEFAULT 0,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS experiments (
      id TEXT PRIMARY KEY,
      hypothesis_id TEXT NOT NULL,
      method TEXT NOT NULL,
      measurement TEXT NOT NULL,
      pass_criteria TEXT NOT NULL,
      fail_criteria TEXT NOT NULL,
      result TEXT CHECK(result IN ('supports', 'refutes', 'inconclusive')),
      evidence TEXT,
      executed_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (hypothesis_id) REFERENCES hypotheses(id)
    );
    ```
</seeding>

<experiment_patterns>
  Common experiment designs by domain.

  <pattern domain="methodology" example="research before coding">
    method:      A/B comparison across similar tasks
    measure:     time to completion, error rate, rework count
    control:     task executed WITHOUT the rule applied
    sample_size: minimum 3 comparisons for signal
  </pattern>

  <pattern domain="coordination" example="parallel beats serial">
    method:      timed execution of same-scope work
    measure:     wall-clock time, merge conflict rate, quality score
    control:     serial execution of identical scope
    sample_size: minimum 3 comparisons for signal
  </pattern>

  <pattern domain="testing" example="tests before code">
    method:      track tasks with test-first vs test-after
    measure:     bug escape rate, rework frequency, coverage delta
    control:     tasks where tests were written after implementation
    sample_size: minimum 5 tasks per condition
  </pattern>

  <pattern domain="quality" example="Big 5 checks prevent bugs">
    method:      compare code reviewed with Big 5 vs without
    measure:     post-merge bug reports, review round-trips
    control:     code merged without Big 5 review
    sample_size: minimum 5 reviews per condition
  </pattern>

  <pattern domain="git" example="atomic commits reduce revert pain">
    method:      track revert complexity for atomic vs bundled commits
    measure:     time to revert, collateral damage (unrelated changes reverted)
    control:     multi-concern commits
    sample_size: minimum 3 revert events per condition
  </pattern>

  <pattern domain="security" example="Zod validation prevents injection">
    method:      fuzz endpoints with and without schema validation
    measure:     injection success rate, malformed input acceptance rate
    control:     endpoint without Zod/Pydantic layer
    sample_size: minimum 50 fuzz inputs per endpoint
  </pattern>

  <pattern domain="performance" example="measure before optimizing saves time">
    method:      compare optimizations guided by profiling vs intuition
    measure:     actual speedup achieved, time spent optimizing
    control:     intuition-guided optimization
    sample_size: minimum 3 optimization tasks per condition
  </pattern>
</experiment_patterns>

<verdict>
  No rule graduates without evidence. No rule dies without a fair trial.
  Gut feelings are hypotheses, not conclusions.
</verdict>

</skill>
