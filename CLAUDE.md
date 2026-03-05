<kernel version="6.0.0">

<!-- ============================================ -->
<!-- PHILOSOPHY                                   -->
<!-- ============================================ -->

<philosophy>
AgentDB-first. Read at start. Write at end.
Skip read → repeat failures. Skip write → lose context.
Orchestrate, don't implement (tier 2+).
Every agent reads AgentDB. Every agent writes AgentDB.
</philosophy>

<!-- ============================================ -->
<!-- AGENTDB                                      -->
<!-- ============================================ -->

<agentdb>
agentdb read-start                                           # ON_START (mandatory)
agentdb write-end '{"did":"X","next":"Y","blocked":"Z"}'    # ON_END (mandatory)
agentdb learn failure|pattern "what" "evidence"              # When discovered
agentdb contract '{"goal":"X","constraints":"Y","tier":N}'  # Tier 2+
agentdb verdict pass|fail '{"tested":[],"evidence":"","issues":[]}'  # Adversary
agentdb query "SELECT ..."                                   # Read agent output

Location: _meta/agentdb/agent.db
</agentdb>

<!-- ============================================ -->
<!-- TIERS                                        -->
<!-- ============================================ -->

<tiers>
  <tier n="1" files="1-2" role="executor">Execute directly. Write code yourself.</tier>
  <tier n="2" files="3-5" role="orchestrator">Contract → surgeon → review.</tier>
  <tier n="3" files="6+" role="orchestrator">Contract → surgeon → adversary → verify.</tier>

  <rule>Count files BEFORE deciding. Ambiguous = assume higher tier.</rule>
  <rule>IF tier >= 2: create contract, spawn agents, read AgentDB. DO NOT write code.</rule>
  <rule>IF tier >= 2: run /kernel:tearitapart before implementation.</rule>
</tiers>

<!-- ============================================ -->
<!-- AGENTS                                       -->
<!-- ============================================ -->

<agents>
  <agent id="surgeon">agents/surgeon.md. Minimal diff. Only touch listed files. Checkpoint to AgentDB. Load skills/build, skills/refactor, skills/testing before acting.</agent>
  <agent id="adversary">agents/adversary.md. QA. Assume broken. Prove with evidence. Verdict to AgentDB. Load skills/testing, skills/security before acting.</agent>
  <agent id="researcher">agents/researcher.md. Find solutions before coding. Unfamiliar tech trigger. Load skills/build and reference build-research before searching.</agent>
  <agent id="scout">agents/scout.md. Codebase reconnaissance. First interaction trigger. Load skills/context, skills/architecture before mapping.</agent>
  <agent id="validator">agents/validator.md. Pre-commit gate. Secrets, types, lint, tests. Load skills/testing, skills/security before validating.</agent>
  <rule>Tier 2+: you orchestrate. Agents write to AgentDB, not conversation.</rule>
  <rule>Every agent must load relevant skills/*/SKILL.md and reference skills/*/reference/*-research.md when applicable.</rule>
</agents>

<!-- ============================================ -->
<!-- FLOW                                         -->
<!-- ============================================ -->

<flow>
  READ (agentdb read-start) → CLASSIFY → TIER (count files) → PLAN → EXECUTE or ORCHESTRATE → WRITE (agentdb write-end)
  <rule>Never implement first solution. Generate 2-3 approaches, choose simplest.</rule>
  <rule>Tier 1: implement directly. Tier 2+: contract → surgeon → verify.</rule>
</flow>

<!-- ============================================ -->
<!-- CONTRACT FORMAT                              -->
<!-- ============================================ -->

<contract>
CONTRACT: {id} | GOAL: {observable} | CONSTRAINTS: {files} | FAILURE: {conditions} | TIER: {2|3} | BRANCH: {name}
  <rule>Observable, bounded, rejectable. Close on: done|confirmed|approved|ship.</rule>
</contract>

<!-- ERROR RECOVERY: See rules/kernel.md -->

<!-- ============================================ -->
<!-- GIT                                          -->
<!-- ============================================ -->

<git>
  <rule>No AI attribution. Never: Co-Authored-By, Generated with Claude Code, or tool signatures.</rule>
  <rule>Tier 2+: feature branch. Format: {type}/{name} (feature/auth, fix/timeout).</rule>
  <rule>Atomic commits. One logical change per commit. Imperative mood: "feat: add rate limiting".</rule>
  <rule>Commit every working state. Push before session end or handoff.</rule>
  <rule>Never commit broken code to main. Never auto-resolve merge conflicts silently.</rule>
  <rule>Stash before risky ops. Tag milestones.</rule>
</git>

<!-- ============================================ -->
<!-- COMMANDS                                     -->
<!-- ============================================ -->

<commands>
  <command id="/kernel:ingest" purpose="Universal entry: classify → scope → contract → orchestrate." file="commands/ingest.md">
    Load skills/orchestration/SKILL.md, skills/build/SKILL.md before classifying. Reference orchestration-research, git-research for protocols.
  </command>
  <command id="/kernel:tearitapart" purpose="Critical pre-implementation review. Verdict: PROCEED/REVISE/RETHINK." file="commands/tearitapart.md">
    Load skills/architecture/SKILL.md, skills/testing/SKILL.md, skills/security/SKILL.md before reviewing. Reference architecture-research, testing-research.
  </command>
  <command id="/kernel:handoff" purpose="Context handoff brief. Saves to _meta/handoffs/." file="commands/handoff.md">
    Load skills/context/SKILL.md before generating. Reference context-research.md.
  </command>
  <rule>Commands must load relevant skills and reference research before executing.</rule>
</commands>

<!-- ============================================ -->
<!-- SKILLS                                       -->
<!-- ============================================ -->

<skills>
<!-- Skills are methodology (HOW). Agents are actors (WHO). Load from skills/*/SKILL.md; reference skills/*/reference/*-research.md -->
  <skill id="build">skills/build/SKILL.md | Solution exploration. Never implement first idea. Ref: build-research.md</skill>
  <skill id="debug">skills/debug/SKILL.md | Systematic debugging. Reproduce first. Ref: debug-research.md</skill>
  <skill id="design">skills/design/SKILL.md | Frontend aesthetics. Anti-convergence. Invoke: /design. Ref: design-research.md</skill>
  <skill id="testing">skills/testing/SKILL.md | Testing methodology. Edge cases over happy paths. Ref: testing-research.md</skill>
  <skill id="refactor">skills/refactor/SKILL.md | Safe refactoring. Tests green before AND after. Ref: refactor-research.md</skill>
  <skill id="orchestration">skills/orchestration/SKILL.md | Multi-agent coordination. Ref: orchestration-research.md</skill>
  <skill id="architecture">skills/architecture/SKILL.md | Structural design. Ref: architecture-research.md</skill>
  <skill id="security">skills/security/SKILL.md | Input validation, secrets, OWASP. Ref: security-research.md</skill>
  <skill id="context">skills/context/SKILL.md | Context engineering, handoff. Ref: context-research.md</skill>
  <skill id="git">skills/git/SKILL.md | Git protocols. Ref: git-research.md</skill>
  <skill id="performance">skills/performance/SKILL.md | Performance methodology. Ref: performance-research.md</skill>
  <rule>Load relevant skill before acting. Reference research docs when methodology applies.</rule>
</skills>

<!-- ============================================ -->
<!-- DESIGN PRINCIPLES (always active)            -->
<!-- ============================================ -->

<!-- Full design principles: skills/design/SKILL.md, skills/design/reference/design-research.md -->
<design_note>Design principles (typography, color, surfaces, motion, anti-convergence) are in skills/design/SKILL.md. Load that file for frontend work.</design_note>

<!-- Output validation: rules/kernel.md invariants -->

<!-- ============================================ -->
<!-- ANTI-PATTERNS                                -->
<!-- ============================================ -->

<anti_patterns>
  <!-- Critical only. Extended rules: _meta/reference/heuristics.md, conventions.md -->
  <block action="skip_agentdb_read">Repeat failures.</block>
  <block action="skip_agentdb_write">Lose context.</block>
  <block action="write_code_tier_2+">You orchestrate, not implement.</block>
  <block action="first_solution_bias">Never implement first idea.</block>
  <block action="skip_tearitapart_tier2+">Review before implementation.</block>
  <block action="serial_when_parallel">Independent tasks → concurrent agents.</block>
</anti_patterns>

</kernel>