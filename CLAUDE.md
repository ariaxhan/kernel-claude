# KERNEL

**The AI Coding OS** | v5.1.0

tokens: ~800 | standalone | self-evolving

---

## Ψ:CORE

```
CORRECTNESS > SPEED
Working first attempt beats iterate + debug.
Think before typing. Simulate before running.

EVERY LINE IS LIABILITY
Config > code. Native > custom. Existing > new.
Delete what doesn't earn its place.

INVESTIGATE BEFORE IMPLEMENT
Never assume. Search for existing patterns first.
Copy what works. Adapt minimally.

LSP-FIRST NAVIGATION
goToDefinition, findReferences, hover.
Never guess APIs. Let the tooling tell you.

MEMORY-FIRST PROTOCOL
Check _memory/ → kernel/project-notes/ → _meta/
before discovering from scratch. 10s vs 10min.

FAIL FAST
Exit early. Clear errors. No silent failures.
If uncertain: STOP → ASK → WAIT.
```

●subagent|MUST:write_to_file+return_summary|path:absolute|format:md

---

## →:AUTONOMY

```
ACT: reversible, allowed_tools, context_reads, code_exploration
PAUSE: destructive, irreversible, security_sensitive
ASK: multi_step, design_decision, ambiguous_intent, uncertain
```

●agents|spawn_proactively|don't_wait_for_permission
●assumptions|STOP→EXTRACT→CONFIRM→PROCEED (see rules/assumptions.md)

---

## ≠:ANTI

●assume_silently|→extract_assumptions+confirm
●implement_before_investigate|→search_patterns_first
●serial_when_parallel|→2+_independent_tasks=parallel_agents
●swallow_errors|→fail_fast+clear_messages
●manual_git|→@git-sync_handles_commits
●work_on_main|→branch/worktree_isolation
●guess_APIs|→LSP_goToDefinition
●rediscover_known|→check_memory_first

---

## Γ:SESSION

```
START:
1. Read _meta/_session.md (context)
2. Read _meta/context/active.md (current work)
3. Check kernel/state.md (project reality)
4. git status (uncommitted work?)

DURING:
- Update active.md as work progresses
- Log learnings to _meta/_learnings.md immediately
- Spawn agents proactively

END:
- @metadata-sync → updates _meta/
- @git-sync → commit + push
Both run in parallel. No manual git from main agent.
```

---

## Σ:METHODOLOGY

Auto-detect task type → load relevant bank. No commands needed.

| context | auto-apply | bank |
|---------|-----------|------|
| "implement","add","create","build" | research→plan→review | PLANNING |
| "bug","error","fix","broken" | reproduce→isolate→root_cause→fix | DEBUGGING |
| "best way to","how should I" | search_packages→3+_sources→decide | RESEARCH |
| "is this right","check this" | correctness→conventions→edge_cases | REVIEW |
| "what's in this codebase" | map_structure→detect_tooling→patterns | DISCOVERY |
| "refactor","improve","optimize" | understand_deeply→identify→prioritize | ITERATION |
| "what could go wrong","critique" | challenge_assumptions→find_risks | TEARITAPART |

---

## Φ:ROUTING

| tier | model | use_for |
|------|-------|---------|
| 1 | ollama | drafts,brainstorm,variations (free,unlimited,local) |
| 2 | gemini | web_search,bulk_read(50+files),research (2M_ctx,free) |
| 3 | sonnet | secondary_impl,synthesis,file_writes (workhorse) |
| 4 | opus | core_impl,planning,design,orchestrate,review (quality>cost) |
| 5 | haiku | test_exec,lint,typecheck (trivial_only) |

●orchestrator|spawns_subagents → model:opus
●draft_refine|ollama:generate_variations → opus:select_best
●research|gemini:analyze → opus|sonnet:synthesize

---

## Ω:KEYWORDS

| keyword | mode | behavior |
|---------|------|----------|
| ulw, fast | ultrawork | spawn 3-5 parallel agents |
| ralph | persistence | loop until verified complete |
| eco | ecomode | route to cheapest capable model |

---

## Ξ:GIT

●atomic_commits|one_logical_change=one_commit
●conventional_format|`{type}({scope}): {subject}`
●push_immediately|no_accumulating_unpushed
●types|feat,fix,refactor,docs,test,chore,perf
●auto_sync|@git-sync + @metadata-sync at end of response

---

## Δ:QUALITY

Before committing:
1. Tests pass
2. Types check
3. Lint clean
4. Security scan (npm audit, pip-audit, etc.)

●block_commit_if_any_gate_fails

---

## ∇:EVOLUTION

●pattern_repeats(2+)|→encode_to_rules
●mistake_repeats|→add_prevention_rule
●discovery|→log:_meta/_learnings.md + update:relevant_config
●deletion_is_evolution|kill_stale_rules
●commit_evolution|`chore(system): {what evolved}`

---

## COMPONENTS

### Commands (16)

| cmd | purpose |
|-----|---------|
| /repo-init | Generate KERNEL config for any codebase |
| /kernel-user-init | Set up user-level defaults (~/.claude/) |
| /kernel-status | Config health and staleness report |
| /kernel-prune | Remove stale config entries |
| /build | research → plan → implement → validate |
| /iterate | analyze → improve → test |
| /tearitapart | critical review → challenge → report |
| /validate | parallel: types, lint, tests |
| /orchestrate | multi-agent coordination for Tier 3 tasks |
| /contract | contract-first scope before work |
| /branch | create worktree for isolated work |
| /ship | commit → push → create PR |
| /parallelize | multi-worktree parallel development |
| /docs | documentation mode |
| /design | load philosophy → audit UI → build |
| /handoff | context brief for session continuity |

### Agents (25)

**Fast (haiku):** test-runner, type-checker, lint-fixer, build-validator, dependency-auditor, git-historian, git-sync, metadata-sync

**Deep (opus):** code-reviewer, security-scanner, test-generator, api-documenter, perf-profiler, refactor-scout, migration-planner, frontend-stylist, media-handler, database-architect, debugger-deep

**Orchestration (opus):** orchestrator, architect, surgeon, adversary, searcher, researcher

### Rules (13)

assumptions, commit-discipline, context-cascade, decisions, fail-fast, frontend-conventions, invariants, investigation-first, memory-protocol, methodology, patterns, preferences, self-evolution

### Banks (10)

PLANNING, DEBUGGING, RESEARCH, REVIEW, DISCOVERY, ITERATION, TEARITAPART, DOCUMENTATION, BUILD, CODING-PROMPT

### Skills (3)

debug (auto: bug/error/fix), research (auto: investigate/learn), coding-prompt-bank (project init/coding rules)

---

## MEMORY

```
_memory/                          # Check FIRST before acting
├── architecture.md               # System structure
├── conventions.md                # Naming, patterns
├── dependencies.md               # External services
├── hotspots.md                   # Complex areas
├── bugs.md                       # Past solutions
└── decisions.md                  # ADRs

kernel/project-notes/             # Persistent knowledge
├── bugs.md                       # Past bug solutions
├── decisions.md                  # Architecture decisions
├── key_facts.md                  # Infrastructure knowledge
└── issues.md                     # Work log
```

---

## FRONTEND

●sophistication_through_restraint|beauty_through_function
●system_fonts_first|never:Inter,Geist
●no_emoji_in_UI|no_AI_aesthetic
●one_signature_element|customize_until_unrecognizable
●see:.claude/rules/frontend-conventions.md

---

*KERNEL = coding OS. LSP-first. Memory-first. Design-intentional. Quality gates enforced. Self-evolving.*
