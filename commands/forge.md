---
name: kernel:forge
description: "Autonomous development engine. Heats solutions with adversarial entropy, hammers them through iteration, quenches with quality gates. Runs until antifragile or reports why it can't be. Run overnight, come back to shipped code."
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, WebSearch, WebFetch
---

<command id="forge">

<purpose>
Fully autonomous. No human checkpoints. Iterate until the solution is antifragile.

The forge metaphor is literal:
  HEAT   — generate competing approaches, inject entropy
  HAMMER — iterate implementation against failing tests
  QUENCH — quality gates, adversarial review, convergence check
  ANNEAL — if brittle, reheat and try a different crystalline structure

Run this overnight. Come back to shipped code + full audit trail in agentdb.
</purpose>

<skill_load>
always: skills/quality/SKILL.md, skills/testing/SKILL.md, skills/git/SKILL.md, skills/build/SKILL.md
on_classify:
  bug:      skills/debug/SKILL.md
  refactor: skills/refactor/SKILL.md
on_domain:
  api:      skills/api/SKILL.md, skills/backend/SKILL.md
  auth:     skills/security/SKILL.md
  frontend: skills/design/SKILL.md
  backend:  skills/backend/SKILL.md
on_tier:
  2+:       skills/orchestration/SKILL.md
</skill_load>

<on_start>
```bash
agentdb read-start
agentdb emit command "forge-start" "" '{"goal":"..."}'
```
Load ALL always-skills immediately. Load task/domain skills after classify.
</on_start>

<!-- ============================================ -->
<!-- THE FORGE CYCLE                              -->
<!-- ============================================ -->

<cycle id="forge" max_iterations="10">

  <phase id="heat" name="HEAT — Generate Competing Approaches">
    Raise the temperature. Don't commit to the first idea.

    1. Read agentdb context + _meta/research/ for prior work.
    2. Classify task: type, tier, domain.
    3. Generate 2-3 candidate approaches (not variations — genuinely different strategies).
    4. For each: files affected, tests needed, effort estimate, known risks.

    Tier 1: generate inline.
    Tier 2+: spawn parallel surgeon agents, one per approach.
    Tier 3: spawn full council (researcher + scout in parallel → dreamer → surgeons).

    ```bash
    agentdb emit command "forge-heat" "" '{"approaches":N,"tier":N}'
    ```
  </phase>

  <phase id="hammer" name="HAMMER — Red-Green-Refactor Until Solid">
    Select the strongest approach. Beat it into shape.

    1. Write failing tests FIRST (red). Edge cases before happy paths.
    2. Implement minimal code to pass (green).
    3. Refactor while green.
    4. Run full suite: tests + lint + types.

    Inner loop (max 5 strikes per approach):
      - failing → fix implementation, not tests
      - passing → proceed to quench
      - stuck after 3 strikes → switch to next candidate approach from heat phase

    ```bash
    agentdb emit command "forge-hammer" "" '{"approach":"X","strikes":N,"tests_passing":N}'
    ```
  </phase>

  <phase id="quench" name="QUENCH — Rapid Cooling Under Pressure">
    Harden the solution. Adversarial entropy injection.

    <entropy_injection>
      Spawn adversary (or self-adversary for tier 1). Their mandate:
      DON'T ask "is this valid?" ASK "can I destroy this?"

      Attack vectors:
      - What input breaks this?
      - What race condition exists?
      - What happens at 10x scale?
      - What edge case was missed?
      - What assumption is wrong?
      - What security hole exists?

      The adversary writes a SPECIFIC failing test or proof, not a vague concern.
    </entropy_injection>

    <integrity_measure>
      Score: 0.0 (shattered) to 1.0 (antifragile).
      - >= 0.8: SURVIVED. Solution is robust. Proceed to ship.
      - >= 0.6: CRACKED. Fixable flaws. Back to hammer with adversary feedback.
      - < 0.6: SHATTERED. Approach is fundamentally flawed. Anneal.
    </integrity_measure>

    ```bash
    agentdb emit command "forge-quench" "" '{"integrity":0.X,"verdict":"survived|cracked|shattered"}'
    ```
  </phase>

  <phase id="anneal" name="ANNEAL — Reheat and Restructure" trigger="quench.shattered">
    The current crystalline structure is brittle. Don't patch — remelt.

    1. Record WHY it shattered: agentdb learn failure "approach X failed because Y"
    2. Penalize this approach: mark as explored-and-failed.
    3. Return to HEAT with the shatter reason as new constraint.
    4. The next approach MUST be structurally different.

    This prevents hammering a fundamentally flawed approach into submission.
    Sometimes the metal needs a different alloy, not more force.

    Max anneals: 3. After 3 structural failures → STOP.
    "Tried 3 distinct approaches. All shattered. Here's why. Human decision needed."

    ```bash
    agentdb emit command "forge-anneal" "" '{"reason":"X","approaches_exhausted":N}'
    ```
  </phase>

  <phase id="ship" name="SHIP — Release the Forged Artifact" trigger="quench.survived">
    Solution survived entropy. Ship it.

    Profile-gated:
    - local: commit to main
    - github: commit + push
    - github-oss: feature branch → PR → self-review via /kernel:review
    - github-production: feature branch → PR → request review

    ```bash
    agentdb learn pattern "what worked" "approach X, integrity Y"
    agentdb emit command "forge-ship" "" '{"iterations":N,"integrity":0.X,"approach":"X"}'
    agentdb write-end '{"command":"forge","iterations":N,"tests":N,"integrity":0.X,"shipped":true}'
    # Suggest /kernel:retrospective if learnings accumulated across forge cycles
    ```
  </phase>

</cycle>

<council note="tier 3 only">
  For tier 3 tasks, spawn a full agent council:
  - researcher + scout: parallel reconnaissance
  - dreamer: 3 competing approaches (after recon)
  - surgeon: implement winning approach
  - adversary: entropy testing (quench phase)

  Council communicates via agentdb. Each reads prior agents' output.
  You orchestrate the sequence and handle annealing.
</council>

<loop_control>
  continue_if: making progress (tests improving, integrity increasing)
  anneal_if: integrity < 0.6 (approach is fundamentally flawed)
  stop_if: 3 anneals (3 structurally different approaches all shattered)
  stop_if: 10 total iterations without convergence
  stop_if: scope creep (files growing beyond original scope)
  escalate_if: architectural decision outside original scope

  on_stop: full audit trail:
    - approaches tried (with integrity scores)
    - why each succeeded or shattered
    - tests written
    - learnings captured
    - recommendation for human
</loop_control>

<protocol_fallback>
If session-start hook did not fire:
- AgentDB: read at start, write at end, learn on discovery
- Skills ARE the methodology — load aggressively
- Research anti-patterns BEFORE solutions. Tests BEFORE code.
- Tier 1: execute directly. Tier 2+: orchestrate via agents.
- Built-in beats library. Library beats custom.
</protocol_fallback>

</command>
