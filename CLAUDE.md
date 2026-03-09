<kernel version="6.1.1">

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
  <agent id="surgeon">agents/surgeon.md. Minimal diff implementation. Only touch contract-listed files. Checkpoint working states to AgentDB. Load: build, refactor, testing skills.</agent>
  <agent id="adversary">agents/adversary.md. QA agent. Assumes code is broken until proven otherwise. >80% confidence threshold. Verdict to AgentDB. Load: testing, security skills.</agent>
  <agent id="reviewer">agents/reviewer.md. PR/code review. Checks logic, security, performance, maintainability. >80% confidence threshold. APPROVE/REQUEST CHANGES/COMMENT verdict. Load: testing, security skills.</agent>
  <agent id="researcher">agents/researcher.md. Pre-implementation research. Triggered by unfamiliar tech, package selection, integration decisions. Load: build skill + build-research.</agent>
  <agent id="scout">agents/scout.md. Codebase reconnaissance. Triggered on first interaction or discovery requests. Maps structure, detects tooling, identifies risk zones. Load: context, architecture skills.</agent>
  <agent id="validator">agents/validator.md. Pre-commit quality gate. Runs: build, types, lint, tests, security scan. Blocks commit on failure. Load: testing, security skills.</agent>
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

<!-- ============================================ -->
<!-- LSP (Language Server Protocol)              -->
<!-- ============================================ -->

<lsp>
Prefer LSP tools over Grep/Glob when available:
- goto_definition: Jump to where function/class is defined (50ms vs 30s grep)
- find_references: Find all usages of a symbol
- hover: Get type info without reading whole file
- document_symbols: List all functions/classes in file

LSP understands code structure. Grep just searches text.
Use Grep only when: LSP unavailable, searching string literals, or pattern matching.

Setup: _meta/reference/lsp-setup.md
</lsp>

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
  <command id="/kernel:ingest" purpose="Universal entry point. Classify task → determine scope → create contract → orchestrate agents." file="commands/ingest.md">
    Load: orchestration, build skills. Reference: orchestration-research, git-research.
  </command>
  <command id="/kernel:validate" purpose="Pre-commit/pre-PR verification loop. Build → types → lint → tests → security → diff. Blocks on failure." file="commands/validate.md">
    Spawns validator agent. Load: testing, security skills.
  </command>
  <command id="/kernel:tearitapart" purpose="Critical pre-implementation review. Finds gaps before coding starts. Verdict: PROCEED/REVISE/RETHINK." file="commands/tearitapart.md">
    Load: architecture, testing, security skills. Reference: architecture-research, testing-research.
  </command>
  <command id="/kernel:handoff" purpose="Context handoff brief for session continuity. Writes to _meta/handoffs/." file="commands/handoff.md">
    Load: context skill. Reference: context-research.md.
  </command>
  <command id="/kernel:review" purpose="Code review for PRs or staged changes. >80% confidence threshold. Verdict: APPROVE/REQUEST CHANGES/COMMENT." file="commands/review.md">
    Spawns reviewer agent. Load: testing, security skills.
  </command>
  <rule>Commands must load relevant skills and reference research before executing.</rule>
</commands>

<!-- ============================================ -->
<!-- SKILLS                                       -->
<!-- ============================================ -->

<skills>
<!-- Skills are methodology (HOW). Agents are actors (WHO). Load from skills/*/SKILL.md; reference skills/*/reference/*-research.md -->

  <!-- IMPLEMENTATION -->
  <skill id="build" triggers="new feature, implementation, coding">Solution exploration. Generate 2-3 approaches, pick simplest. Never implement first idea.</skill>
  <skill id="refactor" triggers="refactor, restructure, clean up">Behavior-preserving transformations. Tests green before AND after. No feature changes.</skill>
  <skill id="backend" triggers="API, database, server, caching, queues">Repository pattern, service layer, N+1 prevention, cache-aside, transactions.</skill>
  <skill id="api" triggers="REST, endpoints, routes">Resource naming, HTTP status codes, cursor pagination, error responses, versioning.</skill>

  <!-- TESTING -->
  <skill id="testing" triggers="test, coverage, assertions">Testing methodology. Edge cases over happy paths. Regression tests for every fix.</skill>
  <skill id="tdd" triggers="TDD, test first, red-green">Test-Driven Development. Red-green-refactor. Includes mock patterns: Supabase, Redis, OpenAI.</skill>
  <skill id="e2e" triggers="E2E, Playwright, integration test">Playwright patterns. Page Object Model. Flaky test strategies. CI/CD integration.</skill>
  <skill id="eval" triggers="eval, benchmark, pass@k">Eval-Driven Development. pass@k metrics, capability evals, regression evals, grader types.</skill>

  <!-- QUALITY -->
  <skill id="debug" triggers="bug, error, broken, not working">Systematic debugging. Reproduce → hypothesize → isolate → fix. Binary search isolation.</skill>
  <skill id="security" triggers="auth, validation, secrets, OWASP">Zod validation, SQL injection prevention, XSS/DOMPurify, CSRF tokens, file upload validation, rate limiting.</skill>
  <skill id="performance" triggers="slow, optimize, latency, profiling">Measure before optimizing. Identify bottlenecks. Avoid premature optimization.</skill>

  <!-- ARCHITECTURE -->
  <skill id="architecture" triggers="system design, structure, modules">Modular design, interface stability, dependency management, coupling analysis.</skill>
  <skill id="orchestration" triggers="multi-agent, parallel, tier 2+">Multi-agent coordination. AgentDB contracts, 4 fault tolerance layers, context transfer.</skill>
  <skill id="context" triggers="context, compaction, handoff, memory">Context engineering. Progressive disclosure, AgentDB offloading, compaction strategies.</skill>

  <!-- WORKFLOW -->
  <skill id="git" triggers="commit, branch, merge, PR">Atomic commits, conventional messages, branch strategies, merge protocols.</skill>
  <skill id="design" triggers="UI, frontend, styling, visual">/design command. Anti-convergence aesthetic. Mood variants: abyss, spatial, verdant, substrate, ember, arctic, void, patina, signal.</skill>

  <rule>Load relevant skill before acting. Match triggers to task. Reference research docs when methodology applies.</rule>
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