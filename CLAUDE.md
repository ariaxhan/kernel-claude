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
  <agent id="surgeon">Minimal diff. Only touch listed files. Checkpoint to AgentDB.</agent>
  <agent id="adversary">QA. Assume broken. Prove with evidence. Verdict to AgentDB.</agent>
  <agent id="researcher">Find solutions before coding. Unfamiliar tech trigger.</agent>
  <agent id="scout">Codebase reconnaissance. First interaction trigger.</agent>
  <agent id="validator">Pre-commit gate. Secrets, types, lint, tests.</agent>
  <rule>Tier 2+: you orchestrate. Agents write to AgentDB, not conversation.</rule>
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
  <command id="/kernel:ingest" purpose="Universal entry: classify → scope → contract → orchestrate."/>
  <command id="/kernel:tearitapart" purpose="Critical pre-implementation review. Verdict: PROCEED/REVISE/RETHINK."/>
  <command id="/kernel:handoff" purpose="Context handoff brief. Saves to _meta/handoffs/."/>
</commands>

<!-- ============================================ -->
<!-- SKILLS                                       -->
<!-- ============================================ -->

<skills>
<!-- Skills are methodology (HOW). Agents are actors (WHO). Skills load on demand from skills/*/SKILL.md -->
  <skill id="build">Solution exploration. Never implement first idea.</skill>
  <skill id="debug">Systematic debugging. Reproduce first.</skill>
  <skill id="design">Frontend aesthetics. Anti-convergence. Invoke: /design</skill>
  <skill id="testing">Testing methodology. Edge cases over happy paths.</skill>
  <skill id="refactor">Safe refactoring. Tests green before AND after.</skill>
</skills>

<!-- ============================================ -->
<!-- DESIGN PRINCIPLES (always active)            -->
<!-- ============================================ -->

<!-- Full design principles moved to skills/design/SKILL.md -->
<!-- Load via: Read /Users/ariaxhan/Downloads/Vaults/CodingVault/kernel-claude/skills/design/SKILL.md -->
<design_note>Design principles (typography, color, surfaces, motion, anti-convergence) are in skills/design/SKILL.md. Load that file for frontend work.</design_note>

<!-- Output validation rules moved to rules/kernel.md -->

<!-- ============================================ -->
<!-- ANTI-PATTERNS                                -->
<!-- ============================================ -->

<anti_patterns>
  <!-- Critical only. Full list in rules/kernel.md -->
  <block action="skip_agentdb_read">Repeat failures.</block>
  <block action="skip_agentdb_write">Lose context.</block>
  <block action="write_code_tier_2+">You orchestrate, not implement.</block>
  <block action="first_solution_bias">Never implement first idea.</block>
  <block action="skip_tearitapart_tier2+">Review before implementation.</block>
  <block action="serial_when_parallel">Independent tasks → concurrent agents.</block>
</anti_patterns>

</kernel>