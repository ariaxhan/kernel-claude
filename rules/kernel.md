<!-- ============================================ -->
<!-- RULE: INVARIANTS                             -->
<!-- Always-on contracts. Violations = critical.  -->
<!-- ============================================ -->

<rule id="invariants" type="invariant" load="always">
<description>Non-negotiable contracts. Cannot be violated without explicit user consent. Violations are critical failures.</description>

<!-- Security -->
<invariant id="no_hardcoded_secrets">
  No hardcoded secrets (keys, tokens, credentials, connection strings).
  Environment variables or secure vaults only.
  <detection>Grep for patterns: API_KEY=, token=, password=, secret= in source files.</detection>
  <on_violation>Block commit. Surface to user.</on_violation>
</invariant>

<invariant id="no_data_exposure">
  No PII, internal URLs, or debug info in user-facing output, logs, or error messages.
  <on_violation>Revert. Flag for review.</on_violation>
</invariant>

<!-- Integrity -->
<invariant id="atomic_commits">
  One logical change = one commit. Never mix feature + refactor + fix.
  Never cherry-pick across features without explicit approval.
  <detection>If git diff covers multiple unrelated concerns, split before committing.</detection>
</invariant>

<invariant id="tests_before_merge">
  Tests pass before merge. Breaking changes require migration guides.
  No exceptions. No "tests are flaky" bypass.
</invariant>

<!-- Data Safety -->
<invariant id="no_irreversible_ops">
  No irreversible operations (delete, drop, truncate, overwrite) without explicit user confirmation.
  Rollback must always be possible.
  <on_ambiguous>Pause. Ask user.</on_ambiguous>
</invariant>

<!-- Transparency -->
<invariant id="no_silent_failures">
  Every decision logged. Every change has a reason. No swallowed errors.
  If something fails, surface it. Never hide.
</invariant>

<invariant id="read_only_default">
  Read-only operations always permitted.
  Write operations: pause if ambiguous intent.
</invariant>

<!-- Attribution -->
<invariant id="no_ai_attribution">
  No Co-Authored-By trailers. No "Generated with Claude Code." No tool signatures in commits.
  Commits attributed to human author only.
</invariant>

<!-- Enforcement -->
<enforcement>
  Pre-commit hooks validate: no secrets, commit message format, test status.
  Agents report violations immediately via AgentDB.
  User must explicitly approve any invariant override.
</enforcement>
</rule>

<!-- ============================================ -->
<!-- RULE: DECISION HEURISTICS                    -->
<!-- When to invoke commands, spawn agents, or    -->
<!-- change execution mode.                       -->
<!-- ============================================ -->

<rule id="decision_heuristics" type="invariant" load="always">
<description>Decision rules that trigger command invocation, agent spawning, and execution mode selection. The routing layer.</description>

<!-- Tier Detection -->
<heuristic id="tier_detection">
  Before ANY implementation: count affected files.
  <when files="1-2">Tier 1. Execute directly.</when>
  <when files="3-5">Tier 2. Invoke /kernel:ingest → contract → surgeon.</when>
  <when files="6+">Tier 3. Invoke /kernel:ingest → contract → surgeon → adversary.</when>
  <when files="ambiguous">Assume higher tier. Ask user if still unclear.</when>
</heuristic>

<!-- Review Trigger -->
<heuristic id="review_trigger">
  <when>Tier 2+ feature or refactor, before implementation.</when>
  <when>Circuit breaker: 3 consecutive failures on same feature.</when>
  <when>User says: review, critique, tear apart, find holes, break this.</when>
  <action>Invoke /kernel:tearitapart.</action>
  <rule>If verdict is RETHINK, do NOT proceed. Revise plan first.</rule>
</heuristic>

<!-- Handoff Trigger -->
<heuristic id="handoff_trigger">
  <when>Session ending or user says: handoff, pause, continue later, save state.</when>
  <when>Context window approaching compaction threshold.</when>
  <when>Switching to different agent/system/session.</when>
  <action>Invoke /kernel:handoff.</action>
  <rule>Always capture git state, active contracts, open threads.</rule>
</heuristic>

<!-- Parallel Detection -->
<heuristic id="parallel_detection">
  <when>2+ independent files to create or modify (no shared dependencies).</when>
  <when>2+ independent systems to test or verify.</when>
  <when>Task contains list of independent subtasks.</when>
  <action>Spawn parallel agents. One contract per file group.</action>
  <constraint>Verify no file overlap between parallel contracts.</constraint>
  <constraint>Shared files = sequential, not parallel.</constraint>
  <rule>Default answer is YES to parallelization. Err on the side of parallel.</rule>
</heuristic>

<!-- Error Recovery Trigger -->
<heuristic id="error_recovery_trigger">
  <when>Agent checkpoint reports failure or blocked status.</when>
  <when>Adversary verdict is fail.</when>
  <when>Same contract fails 2+ times.</when>
  <action>Classify failure type (transient, scope, test, blocked, divergent) and follow error recovery protocol in /kernel:ingest.</action>
  <circuit_breaker>3 consecutive failures on same feature → stop, invoke /kernel:tearitapart.</circuit_breaker>
</heuristic>

<!-- Agent Spawn Decision -->
<heuristic id="agent_spawn">
  <when type="surgeon">Contract exists, tier 2+, implementation needed.</when>
  <when type="adversary">Surgeon checkpoint complete, tier 3, or user requests verification.</when>
  <when type="researcher">Unfamiliar tech, package selection, new integration. See research_trigger.</when>
  <when type="scout">First codebase interaction, no active.md, stale discovery. See discovery_trigger.</when>
  <when type="validator">Pre-commit, before ship. See validation_trigger.</when>
  <rule>Never spawn agent without a contract in AgentDB.</rule>
  <rule>Never spawn adversary without surgeon checkpoint to verify.</rule>
</heuristic>

<!-- Research Trigger (deterministic, not skill auto-detect) -->
<heuristic id="research_trigger">
  <when>Unfamiliar technology or library encountered.</when>
  <when>Package selection decision needed.</when>
  <when>New external integration.</when>
  <when>No existing _meta/research/ doc covers the topic.</when>
  <action>Spawn researcher agent. Wait for output before proceeding to implementation.</action>
  <rule>Never implement with unfamiliar tech without research agent output.</rule>
  <rule>Researcher writes to _meta/research/{topic}-research.md.</rule>
</heuristic>

<!-- Discovery Trigger (deterministic, not skill auto-detect) -->
<heuristic id="discovery_trigger">
  <when>First session with a codebase.</when>
  <when>No _meta/context/active.md exists or is stale (>7 days).</when>
  <when>User says: explore, discover, what's in this repo, map the code.</when>
  <action>Spawn scout agent. Wait for output before any implementation.</action>
  <rule>Never implement in unfamiliar codebase without scout output.</rule>
  <rule>Scout writes to _meta/context/active.md.</rule>
</heuristic>

<!-- Validation Trigger (deterministic) -->
<heuristic id="validation_trigger">
  <when>Before any commit (automatic).</when>
  <when>Before /kernel:ship (automatic).</when>
  <when>User says: validate, check, pre-commit.</when>
  <action>Spawn validator agent.</action>
  <rule>Nothing ships without validator pass.</rule>
  <rule>Validator writes verdict to AgentDB.</rule>
</heuristic>

<!-- Skill Selection (methodology only, not actors) -->
<heuristic id="skill_selection">
  <when terms="bug,error,fix,broken,regression,exception,crash">Load debug skill (methodology for surgeon).</when>
  <when terms="implement,add,create,build,integrate">Load build skill (methodology for surgeon).</when>
  <when terms="frontend,ui,css,styling,visual,design">Load design skill (aesthetics).</when>
  <!-- research/discovery are now AGENTS, not skills. See research_trigger and discovery_trigger. -->
</heuristic>
</rule>

<!-- ============================================ -->
<!-- RULE: PARALLEL EXECUTION                     -->
<!-- Parallelization is the default.              -->
<!-- ============================================ -->

<rule id="parallel_first" type="invariant" load="always">
<description>Serial execution is the exception. Parallel is the default.</description>

<detection>
  Before taking action, ask: "Can this be split into 2+ independent steps?"
  If yes → spawn parallel agents with separate contracts.
  If no → execute directly.
</detection>

<pattern>
  Single message with multiple Task calls. All agents write files directly.
  Wait for all agents. Merge/review results.
</pattern>

<anti_patterns>
  <block action="serial_independent_tasks">
    WRONG: "Let me create file A... Now file B... Next config C..."
    RIGHT: Spawn 3 agents for A, B, C simultaneously.
  </block>
</anti_patterns>

<exceptions>
  <exception>Task is single file edit or single command.</exception>
  <exception>User explicitly says "just do X" or "quick."</exception>
  <exception>Steps are dependent (output of A feeds into B).</exception>
</exceptions>
</rule>

<!-- ============================================ -->
<!-- RULE: CONTEXT DISCIPLINE                     -->
<!-- Manage tokens as a scarce resource.          -->
<!-- ============================================ -->

<rule id="context_discipline" type="invariant" load="always">
<description>Context is finite. Every token competes for attention. Manage ruthlessly.</description>

<!-- Progressive Disclosure -->
<principle id="progressive_disclosure">
  Don't load everything upfront. Load what's needed when it's needed.
  Commands load on invocation. Skills load on demand. Rules are always-on.
  If information isn't needed for the current step, don't read it into context.
</principle>

<!-- Compaction Awareness -->
<principle id="compaction_awareness">
  Monitor context usage. Offer /kernel:handoff proactively at ~70% context.
  Before long output, ask: "Can this be 50% shorter?"
  If repeating information from earlier in conversation, reference instead of restating.
</principle>

<!-- AgentDB as External Memory -->
<principle id="agentdb_over_memory">
  AgentDB is external memory. Use it instead of holding state in context.
  Write decisions, findings, and state to AgentDB immediately.
  Read from AgentDB when needed; don't carry everything in conversation.
</principle>

<!-- Subagent Delegation -->
<principle id="subagent_for_research">
  Research tasks consume heavy context (file reads, searches).
  Delegate research to subagents. They explore in separate context, report back summaries.
  Main context stays clean for implementation.
</principle>

<!-- File Reading Discipline -->
<principle id="minimal_file_reads">
  Read only files relevant to current task. Not the whole codebase.
  Use grep/glob to find specific content instead of reading entire files.
  If a file is large, read only the relevant section.
</principle>
</rule>

<!-- ============================================ -->
<!-- RULE: CODE CONVENTIONS                       -->
<!-- Style and tool preferences.                  -->
<!-- Negotiable defaults; override per-project.   -->
<!-- ============================================ -->

<rule id="conventions" type="preference" load="always">
<description>Negotiable defaults. Override per-task or per-project.</description>

<!-- Formatting -->
<convention id="indentation">2 spaces (JS/YAML), 4 spaces (Python).</convention>
<convention id="line_length">100 soft, 120 hard.</convention>
<convention id="trailing_commas">Yes.</convention>
<convention id="semicolons">Minimal in JS (ASI where safe).</convention>

<!-- Comments -->
<convention id="comment_style">Line comments for WHY, not WHAT. Block comments for complex algorithms. JSDoc/docstrings for public APIs only.</convention>

<!-- Tools -->
<convention id="package_manager">npm (unless project specifies).</convention>
<convention id="testing">Jest (unless project specifies).</convention>
<convention id="linting">ESLint + Prettier (JS), Black (Python).</convention>
<convention id="git_format">Conventional commits: {type}({scope}): {description}. Types: feat, fix, chore, refactor, docs, test, perf, ci.</convention>

<!-- Documentation -->
<convention id="docs">README for setup. Inline comments for non-obvious logic. ARCHITECTURE.md for system design. Changelog from commits.</convention>

<!-- Enforcement -->
<rule>Linter enforces formatting. Code review nudges toward preferences. Override when project context differs.</rule>
</rule>

<!-- ============================================ -->
<!-- RULE: OUTPUT QUALITY                         -->
<!-- Standards for what this system produces.     -->
<!-- ============================================ -->

<rule id="output_quality" type="invariant" load="always">
<description>Quality standards for all output: code, communication, artifacts.</description>

<!-- Code Output -->
<standard id="code_quality">
  <rule>Smallest change that works. No gold plating.</rule>
  <rule>Follow existing patterns in codebase. Don't introduce new patterns without justification.</rule>
  <rule>Error handling: catch, log with context, surface actionable message. Never swallow.</rule>
  <rule>Naming: descriptive, consistent with codebase conventions.</rule>
  <rule>No dead code, no commented-out code, no TODO without ticket/issue reference.</rule>
</standard>

<!-- Communication -->
<standard id="communication">
  <rule>All user-facing output: non-technical, clear, zero code knowledge required.</rule>
  <rule>When presenting issues: numbered, with options lettered (A, B, C). Recommended option first.</rule>
  <rule>Surface failures, blockers, and decisions. Never hide.</rule>
  <rule>After each major section of work, pause and ask for feedback before continuing.</rule>
</standard>

<!-- Evidence -->
<standard id="evidence">
  <rule>Every claim backed by actual output (paste stdout/stderr, not "it works").</rule>
  <rule>Every decision has a stated reason.</rule>
  <rule>Every agent writes evidence to AgentDB, not conversation.</rule>
</standard>
</rule>