<kernel version="7.11.1">

<!-- ============================================ -->
<!-- CONTEXT DELIVERY: READ THIS FIRST            -->
<!-- ============================================ -->
<!--
  THIS FILE IS NOT LOADED FOR PLUGIN USERS.

  When kernel-claude is installed as a Claude Code plugin, this CLAUDE.md
  is NOT injected into conversation context. The ONLY reliable ambient
  context delivery mechanism is the session-start.sh hook output.

  Therefore:
  - session-start.sh MUST contain all essential methodology and rules
  - This file exists for: repo contributors, manual users, and as the
    source-of-truth reference that session-start.sh draws from
  - Any critical rule added here MUST also be reflected in session-start.sh
  - Never assume this file is in context during a plugin user's session
-->

<!-- ============================================ -->
<!-- PHILOSOPHY                                   -->
<!-- ============================================ -->

<philosophy>
Every AI-written line is a liability. Research proves solutions before coding.
AgentDB-first. Read at start, write at end. Continuity depends on it.
Most SWE work is solved problems. Find the solution, don't invent it.
Orchestrate, don't implement (tier 2+). Agents write code, you coordinate.
Slow down to speed up. Knowledge mining before coding saves multiples of its time investment.
Pre-load over ask. Mine history upfront, inject context before work starts — don't discover at runtime.
Fallback-first. When uncertain: deny. When scanner fails: block. When budget exceeded: stop. Never degrade a safety gate.
Composite quality over binary. Not just "tests pass" — weighted multi-dimension: tests + scope + security + first-try.
Ask at decision points. A 5-second question saves 5 minutes of wrong-direction work.
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
  <agent id="triage">agents/triage.md. Haiku complexity classifier. Single fast call before expensive work. Low/medium/high/epic classification.</agent>
  <agent id="understudier">agents/understudier.md. Haiku pre-flight before surgeon. Validates approach viability cheaply before committing expensive resources.</agent>
  <agent id="approval-learner">agents/approval-learner.md. Sonnet observer. Extracts patterns from human review decisions. Progressive rule promotion with confidence scoring.</agent>
  <agent id="analyzer">agents/analyzer.md. Cross-task intelligence. Dependency detection, batch analysis, systemic patterns, priority recommendation.</agent>
  <agent id="cartographer">agents/cartographer.md. Opus whole-codebase mapper. 1M context for holistic understanding. Maps modules, dependencies, risk zones.</agent>
  <agent id="coroner">agents/coroner.md. Sonnet post-mortem analyst. Structured cause-of-death for failed contracts using AgentDB telemetry.</agent>
  <agent id="pre-ship">agents/pre-ship.md. Composite release gate. Spawns 4 parallel validators, aggregates into SHIP/NO-SHIP verdict.</agent>
  <rule>Tier 2+: you orchestrate. Agents write to AgentDB, not conversation.</rule>
  <rule>Every agent must load relevant skills/*/SKILL.md and reference skills/*/reference/*-research.md when applicable.</rule>
</agents>

<flow>
  READ → CLASSIFY → [branch] → SCOPE → DEFINE SUCCESS → EXECUTE → [branch] → LEARN
  <step id="read">agentdb read-start. Check _meta/research/ for prior work.</step>
  <step id="classify">Task type. Familiar? Search before asking.</step>
  <step id="research">Anti-patterns FIRST. Then proven solutions. Built-in beats dependency.</step>
  <step id="scope">Count files → determine tier. Ambiguous = higher tier.</step>
  <step id="define">Acceptance criteria + evals BEFORE coding.</step>
  <step id="execute">Tier 1: implement. Tier 2+: contract → surgeon → verify.</step>
  <step id="learn">agentdb learn. Update research docs. Checkpoint.</step>

  <branches>
    classify.familiar AND scope.tier==1 → skip research, go to scope
    scope.reveals_unknowns → loop back to research
    execute.fails → branch to debug skill, then retry execute
    adversary.rejects → loop to surgeon with feedback (max 3 retries)
  </branches>

  <rule>Never implement first solution. Generate 2-3 approaches, choose simplest.</rule>
  <rule>Never code without research. Most problems are already solved.</rule>
</flow>

<contract>
CONTRACT: {id} | GOAL: {observable} | CONSTRAINTS: {files} | FAILURE: {conditions} | TIER: {2|3} | BRANCH: {name}
  <rule>Observable, bounded, rejectable. Close on: done|confirmed|approved|ship.</rule>
</contract>

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

<github_layer>
GitHub is a supplementary visibility layer. AgentDB is ALWAYS the source of truth for ALL profiles.
Non-local profiles (github, github-oss, github-production) get additive GitHub features:
- Issues: tier 2+ contracts surface as GitHub Issues with agent/tier labels
- Discussions: session summaries → Agent Logs, learnings → Learnings, decisions → Decisions
- Agents post checkpoints and verdicts as issue comments
Library: hooks/scripts/github-integration.sh. All functions profile-gated, fire-and-forget.
<rule>AgentDB first. GitHub after. Never block on GitHub API failures.</rule>
</github_layer>

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
  <command id="/kernel:ingest" purpose="Universal entry. Research → classify → scope → define success → execute → learn." file="commands/ingest.md">
    Load: orchestration, build skills. Spawn researcher for unfamiliar tech.
    Mandatory: Check _meta/research/ before new work. Write research after learning.
  </command>
  <command id="/kernel:forge" purpose="Autonomous engine. Heat/hammer/quench/anneal until antifragile. Run overnight." file="commands/forge.md">
    Entropy-tested development: generate approaches, implement, adversarial attack, iterate.
    Stops after 3 structural failures or 10 iterations. Full audit trail.
  </command>
  <command id="/kernel:validate" purpose="Pre-commit/pre-PR verification loop. Build → types → lint → tests → security → diff. Blocks on failure." file="commands/validate.md">
    Spawns validator agent. Load: testing, security skills.
  </command>
  <command id="/kernel:tearitapart" purpose="Critical pre-implementation review. Finds gaps before coding starts. Verdict: PROCEED/REVISE/RETHINK." file="commands/tearitapart.md">
    Load: architecture, testing, security skills. Reference: architecture-research, testing-research.
  </command>
  <command id="/kernel:handoff" purpose="Context handoff brief for session continuity. Writes to _meta/handoffs/." file="commands/handoff.md">
    Load: context-mgmt skill. Reference: context-research.md.
  </command>
  <command id="/kernel:review" purpose="Code review for PRs or staged changes. >80% confidence threshold. Verdict: APPROVE/REQUEST CHANGES/COMMENT." file="commands/review.md">
    Spawns reviewer agent. Load: testing, security skills.
  </command>
  <command id="/kernel:dream" purpose="Creative exploration. 3 perspectives + 4-persona stress test. Integrity-scored." file="commands/dream.md">
    Minimalist/maximalist/pragmatist perspectives. Council probes each for flaws.
  </command>
  <command id="/kernel:diagnose" purpose="Systematic debugging + refactor analysis. Diagnosis before prescription." file="commands/diagnose.md">
    Bug mode: reproduce → trace → isolate → hypothesize → diagnose.
    Refactor mode: map → trace deps → coupling → risks → diagnose.
  </command>
  <command id="/kernel:retrospective" purpose="Cross-session learning synthesis. Finds patterns, resolves contradictions, promotes insights." file="commands/retrospective.md">
    Groups learnings, merges duplicates, archives stale, promotes high-confidence patterns.
  </command>
  <command id="/kernel:metrics" purpose="Observability dashboard. Sessions, agents, hooks, learnings." file="commands/metrics.md">
    Wraps agentdb metrics + health with actionable insights.
  </command>
  <command id="/kernel:experiment" purpose="Scientific experimentation mode. Every rule is a hypothesis until proven. Seed, test, graduate, or kill rules based on evidence." file="commands/experiment.md">
    Subcommands: seed, list, test, verdict, report, graduate, kill.
    Load: quality skill always. Testing + eval skills for test subcommand.
  </command>
  <rule>Commands must load relevant skills and reference research before executing.</rule>

  <workflows>
    Declarative workflow definitions in workflows/ directory.
    Load workflow matching task type. Steps define agent sequence.
    Each step has: agent, output, skip_if, retry, on_failure.
    See: workflows/feature.md, workflows/bugfix.md, workflows/refactor.md
  </workflows>
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
  <skill id="quality" triggers="Big 5, ai code, review, validate, pre-commit">AI code quality. The Big 5: input validation, edge cases, error handling, duplication, complexity. Load before any review/validate.</skill>
  <skill id="debug" triggers="bug, error, broken, not working">Systematic debugging. Reproduce → hypothesize → isolate → fix. Binary search isolation.</skill>
  <skill id="security" triggers="auth, validation, secrets, OWASP">Zod validation, SQL injection prevention, XSS/DOMPurify, CSRF tokens, file upload validation, rate limiting.</skill>
  <skill id="performance" triggers="slow, optimize, latency, profiling">Measure before optimizing. Identify bottlenecks. Avoid premature optimization.</skill>

  <!-- ARCHITECTURE -->
  <skill id="architecture" triggers="system design, structure, modules">Modular design, interface stability, dependency management, coupling analysis.</skill>
  <skill id="orchestration" triggers="multi-agent, parallel, tier 2+">Multi-agent coordination. AgentDB contracts, 4 fault tolerance layers, context transfer.</skill>
  <skill id="context-mgmt" triggers="compaction, handoff, memory, tokens">Context engineering. Progressive disclosure, AgentDB offloading, compaction strategies. Use native /context for usage check.</skill>

  <!-- WORKFLOW -->
  <skill id="git" triggers="commit, branch, merge, PR">Atomic commits, conventional messages, branch strategies, merge protocols.</skill>
  <skill id="design" triggers="UI, frontend, styling, visual">/design command. Anti-convergence aesthetic. Mood variants: abyss, spatial, verdant, substrate, ember, arctic, void, patina, signal.</skill>
  <skill id="app-dev" triggers="app, mobile, EAS, store submission, build, deploy">Mobile/web build pipeline, EAS, store submission, pre-submission checklists.</skill>

  <!-- EXPERIMENTATION -->
  <skill id="experiment" triggers="experiment, hypothesis, prove, test rule, validate methodology, scientific, evidence">Scientific method for rules. Every rule is a hypothesis until proven. Seed, test, graduate, or kill based on evidence.</skill>

  <rule>Load relevant skill before acting. Match triggers to task. Reference research docs when methodology applies.</rule>
</skills>

<!-- Design: skills/design/SKILL.md. Load for frontend work. -->
<!-- Output validation: rules/kernel.md -->

<anti_patterns>
  <!-- Critical only. Extended rules: _meta/reference/heuristics.md, conventions.md -->
  <block action="skip_agentdb_read">Read at start — prior failures and patterns inform this session.</block>
  <block action="skip_agentdb_write">Write at end — next session needs your learnings.</block>
  <block action="skip_research">Reinvent solved problems. Check _meta/research/ first.</block>
  <block action="solution_before_antipattern">Search what breaks BEFORE what works.</block>
  <block action="code_without_success_criteria">Define done before coding.</block>
  <block action="skip_learning">Every task teaches. Capture it or lose it.</block>
  <block action="write_code_tier_2+">You orchestrate, not implement.</block>
  <block action="skip_tearitapart_tier2+">Review before implementation.</block>
  <block action="new_dependency_without_justification">Built-in beats library. Prove you need it.</block>
</anti_patterns>

</kernel>