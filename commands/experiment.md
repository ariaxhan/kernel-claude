---
name: kernel:experiment
description: "Autonomous experimentation engine. Every rule is a hypothesis. Seeds from CLAUDE.md, designs experiments, runs them, updates confidence, graduates or kills rules. One command. Walk away."
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, WebSearch, WebFetch
---

<command id="experiment">

<purpose>
Autonomous. One command. No subcommands to memorize.

Invoke /kernel:experiment. It figures out what to do:
  - No hypotheses? Seeds them from CLAUDE.md.
  - Hypotheses exist? Picks the most uncertain, designs an experiment, runs it.
  - Evidence accumulating? Graduates proven rules, kills disproven ones.
  - Everything tested? Reports and stops.

The loop runs until interrupted or all hypotheses have sufficient evidence.
Rules that survive become convictions. Rules that fail become learnings.

Inspired by: prompt-improvement loops (judge → learn → update → loop),
forge (heat/hammer/quench/anneal), and self-configuring agent patterns.
</purpose>

<skill_load>
always: skills/experiment/SKILL.md, skills/quality/SKILL.md, skills/testing/SKILL.md
</skill_load>

<on_start>
```bash
agentdb read-start
agentdb emit command "experiment-start" "" '{}'
```
</on_start>

<!-- ============================================ -->
<!-- THE EXPERIMENT ENGINE                        -->
<!-- ============================================ -->

<cycle id="experiment" max_iterations="20">

  <phase id="sense" name="SENSE — Read the State">
    Autonomous entry point. Determine what the system needs.

    ```bash
    agentdb hypothesis list 2>/dev/null
    ```

    Decision tree (no human input needed):
    1. No hypotheses table or empty? → go to SEED phase.
    2. Hypotheses exist but all are unproven? → go to PICK phase.
    3. Mix of tested/untested? → go to PICK phase (prioritize untested).
    4. All have >= 3 experiments? → go to JUDGE phase.
    5. Graduation/kill candidates exist? → go to EVOLVE phase.

    This phase takes 5 seconds. No asking. Just read and decide.
  </phase>

  <phase id="seed" name="SEED — Extract Rules as Hypotheses" trigger="sense.no_hypotheses">
    Scan every CLAUDE.md in the project hierarchy + rules/*.md + skills/*/SKILL.md.

    Parse rule-like patterns:
    - Imperative: "Always X", "Never Y", "Prefer Z", "Must W"
    - Anti-patterns: block actions, "Don't", "Forbidden"
    - Assertions: "X before Y", "X is better than Y"
    - Quantitative claims: "reduces by X%", "takes N minutes"
    - Conditional: "If X then Y", "When X, do Y"

    For each rule:
    ```bash
    agentdb hypothesis add "<statement>" --domain <auto-classify> --source "<file:line>"
    ```

    Domain auto-classification by keyword:
    - research, anti-pattern, prior work → methodology
    - parallel, agent, spawn, tier → coordination
    - test, coverage, edge case, mock → testing
    - commit, branch, merge, PR → git
    - secret, validation, auth, injection → security
    - measure, optimize, latency, profile → performance
    - Big 5, review, quality → quality
    - module, interface, coupling → architecture

    Deduplicate: skip if near-identical statement already exists.
    Log count, then immediately proceed to PICK. No pause.

    ```bash
    agentdb emit command "experiment-seed" "" '{"seeded":N}'
    ```
  </phase>

  <phase id="pick" name="PICK — Select Next Hypothesis">
    Choose the hypothesis that will produce the most information.

    Priority order:
    1. **Most uncertain**: confidence closest to 0.5 (maximum ignorance — any experiment is maximally informative)
    2. **Least tested**: fewest total experiments (break ties)
    3. **Highest impact domain**: methodology > coordination > security > testing > quality > git > architecture > performance

    Query:
    ```sql
    SELECT id, statement, domain, confidence, evidence_for + evidence_against as total_evidence
    FROM hypotheses
    WHERE status NOT IN ('graduated', 'refuted')
    ORDER BY ABS(confidence - 0.5) ASC, total_evidence ASC
    LIMIT 1;
    ```

    Selected hypothesis goes to DESIGN. No pause.
  </phase>

  <phase id="design" name="DESIGN — Create the Experiment">
    Autonomously design the minimum viable experiment. No human input.

    Choose the LIGHTEST experiment type that produces signal:

    1. **HISTORICAL** (cheapest — query existing data):
       Query agentdb learnings, session outcomes, error patterns for evidence.
       "Does the data we already have support or refute this?"
       Use when: agentdb has >= 10 sessions or >= 20 learnings in the domain.

    2. **COMPARATIVE** (medium — run a real task two ways):
       Find a pending task or construct a minimal one.
       Execute WITH the rule applied, then WITHOUT (or find prior without-cases).
       Measure: time, error count, rework, quality.

    3. **ABLATION** (medium — remove the rule, observe):
       Temporarily ignore the rule during a real task.
       Record what breaks, what doesn't, what's different.

    4. **OBSERVATIONAL** (passive — tag next N tasks):
       Don't run anything now. Flag the hypothesis for passive observation.
       Next N relevant tasks automatically collect evidence.
       Use when: active experimentation would be disruptive.

    Record the experiment:
    ```bash
    agentdb experiment add <H_ID> "<method>" "<measurement>" --pass-criteria "<criteria>"
    ```

    Proceed to RUN. No pause.
  </phase>

  <phase id="run" name="RUN — Execute and Observe">
    Run the designed experiment. Record everything.

    For HISTORICAL experiments:
    - Query agentdb with specific SQL
    - Count sessions/learnings that match the hypothesis conditions
    - Calculate ratios, rates, counts
    - Evidence is the query result + interpretation

    For COMPARATIVE experiments:
    - Execute the task (spawn agents if needed)
    - Record wall-clock time, errors, output quality
    - Compare against the control condition
    - Evidence is the measured delta

    For ABLATION experiments:
    - Execute a task with the rule explicitly ignored
    - Record what happens differently
    - Evidence is the observed difference (or lack thereof)

    For OBSERVATIONAL experiments:
    - Record the flag in agentdb
    - Skip to next hypothesis (no blocking)
    - Evidence collected passively in future sessions

    After execution, proceed to CONCLUDE. No pause.
  </phase>

  <phase id="conclude" name="CONCLUDE — Verdict and Confidence Update">
    Compare observations against pass/fail criteria.

    Issue verdict honestly:
    - **supports**: evidence clearly aligns with the hypothesis
    - **refutes**: evidence clearly contradicts the hypothesis
    - **inconclusive**: evidence is ambiguous or insufficient

    ```bash
    agentdb experiment verdict <EXP_ID> <supports|refutes|inconclusive> "<evidence summary>"
    ```

    Confidence update (Bayesian, applied automatically by CLI):
    - supports:     confidence += (1 - confidence) * 0.25
    - refutes:      confidence -= confidence * 0.3
    - inconclusive: no change

    ```bash
    agentdb learn pattern|failure "<what we learned>" "<evidence>"
    agentdb emit command "experiment-conclude" "" '{"H":"ID","EXP":"ID","verdict":"X","confidence":0.XX}'
    ```

    Check: has this hypothesis crossed a threshold?
    - confidence >= 0.8 AND evidence_for >= 3 → candidate for graduation
    - confidence < 0.2 AND evidence_against >= 2 → candidate for kill

    Loop back to PICK for next hypothesis.
  </phase>

  <phase id="judge" name="JUDGE — Review All Evidence" trigger="sense.sufficient_evidence">
    Periodic review when enough experiments have accumulated.

    For each hypothesis with >= 3 experiments:
    - Summarize all evidence (for and against)
    - Calculate final confidence
    - Classify: graduated | refuted | needs-more-evidence | inconclusive

    Generate report:
    ```bash
    agentdb hypothesis export
    ```

    Write detailed report to _meta/research/experiment-report.md.
    Proceed to EVOLVE.
  </phase>

  <phase id="evolve" name="EVOLVE — Self-Reconfigure">
    The emergent part. The system reconfigures based on evidence.

    **Graduate** (confidence >= 0.8, evidence_for >= 3, ratio >= 3:1):
    - Mark hypothesis as graduated
    - Log: "PROVEN: {statement} — {evidence_summary}"
    - Recommend hardening in CLAUDE.md (but don't modify — present to human)

    **Kill** (confidence < 0.2, evidence_against >= 2):
    - Mark hypothesis as refuted
    - Log: "DISPROVEN: {statement} — {evidence_summary}"
    - Recommend removal from CLAUDE.md (present to human)

    **Mutate** (inconclusive after 5+ experiments):
    - The hypothesis may be poorly stated
    - Propose a refined version as a NEW hypothesis
    - Link to original (evolution chain)

    <ask_user>
      Use AskUserQuestion ONCE at the end of the evolve phase:
      Ask: "{graduated} rules proven, {killed} rules disproven, {mutated} rules refined. Apply changes to CLAUDE.md?"
      Options: apply all, review individually, skip for now
    </ask_user>

    ```bash
    agentdb emit command "experiment-evolve" "" '{"graduated":N,"killed":N,"mutated":N}'
    ```
  </phase>

</cycle>

<!-- ============================================ -->
<!-- LOOP CONTROL                                 -->
<!-- ============================================ -->

<loop_control>
  continue_if: untested hypotheses remain OR new evidence changes confidence significantly
  pause_at:    EVOLVE phase (only human checkpoint — graduation/kill decisions)
  stop_if:     all hypotheses have >= 3 experiments AND no graduation/kill candidates
  on_stop:     write final report to _meta/research/experiment-report.md, agentdb write-end

  Iteration budget: max 20 cycles per invocation.
  Each cycle: PICK → DESIGN → RUN → CONCLUDE (typically 2-5 minutes for historical, longer for comparative).
</loop_control>

<!-- ============================================ -->
<!-- EMERGENT BEHAVIOR                            -->
<!-- ============================================ -->

<emergence>
  The experiment engine produces emergent behavior through iteration:

  1. **Rule evolution**: hypotheses mutate when inconclusive, creating refined versions
  2. **Domain clustering**: related hypotheses accumulate evidence together, revealing systemic patterns
  3. **Confidence landscapes**: the full hypothesis set becomes a map of what's proven vs uncertain
  4. **Self-pruning**: disproven rules get killed, reducing noise in the system
  5. **Cross-hypothesis interference**: testing one rule often produces evidence for/against others
  6. **Methodology metabolism**: the system digests its own rules, keeping what works, excreting what doesn't

  Over multiple invocations:
  - First run: seeds + runs historical experiments on easy-to-test hypotheses
  - Second run: picks up where it left off, runs deeper experiments
  - Third run: starts graduating/killing, proposes mutations
  - Nth run: the ruleset has evolved. Only proven rules remain. New rules get tested immediately.
</emergence>

<!-- ============================================ -->
<!-- HARD STOPS                                   -->
<!-- ============================================ -->

<hard_stops>
  - NEVER modify CLAUDE.md autonomously. Present changes at EVOLVE, human decides.
  - NEVER delete hypotheses. Mark as refuted. Audit trail is sacred.
  - NEVER fabricate evidence. If experiment can't run, mark inconclusive with reason.
  - NEVER run destructive experiments without explicit approval.
  - ALWAYS record evidence, even for inconclusive results.
</hard_stops>

<!-- ============================================ -->
<!-- ON_END                                       -->
<!-- ============================================ -->

<on_end>
```bash
agentdb write-end '{"command":"experiment","cycles":N,"experiments_run":N,"graduated":N,"refuted":N,"mutated":N}'
```
</on_end>

</command>
