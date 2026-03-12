---
name: kernel:ingest
description: "Guided entry point. Research → classify → scope → execute. Human confirms each phase. Triggers: start, begin, do, implement, build, fix, create."
user-invocable: true
allowed-tools: Read, Bash, Grep, Glob, Task, WebSearch, WebFetch
---

<command id="ingest">

<mindset>
core: every AI line is liability, most SWE is solved problems
paradox: METR 2025 - devs think 20% faster, actually 19% slower
fix: slow down to speed up

planning_ratio:
  old: 10% planning, 90% coding
  new: 50-70% planning, 30-50% coding
  result: 3x faster overall, 50% fewer refactors

ai_code_reality:  # from research
  buggier: 1.7x more issues than human code
  security: 40-62% contain vulnerabilities
  edge_cases: missing by default
  duplication: 8x increase

why_slow_is_fast:
  - Clear spec = fast implementation
  - Vague spec = endless iteration
  - Research prevents reinventing wheels
  - Tests before code catches bugs early
  - Review before merge is cheaper than prod bugs
</mindset>

<mode>
guided: step-by-step, human confirms each phase
flow: READ → CLASSIFY → RESEARCH → SCOPE → TESTS → EXECUTE → LEARN
vs_auto: ingest is guided; /kernel:auto is autonomous loop (ralph mode)
</mode>

<step id="1_read" name="READ (MANDATORY FIRST)">
```bash
agentdb read-start
ls _meta/research/  # check prior work
```

<output>
failures_to_avoid: [from AgentDB]
patterns_to_follow: [from AgentDB]
active_contracts: resume or close first
prior_research: check _meta/research/ for similar problems
</output>

<rule>If similar task done before, read that research, don't repeat.</rule>
</step>

<step id="2_classify">
<output>
task: what user wants (one sentence)
type: bug|feature|refactor|question|verify|handoff|review
familiar: yes|no
</output>

<search_before_asking>
1: Glob - **/*keyword*, **/*.{json,yaml,ts,py}
2: Grep - error messages, function names, config keys
3: common paths - ~/.config/, ~/.claude/, package.json
</search_before_asking>
</step>

<step id="3_research" name="RESEARCH (NOT OPTIONAL)">
<rule>Every implementation needs research.</rule>

<substep id="3a_check_existing">
do: ls _meta/research/
query: agentdb query "SELECT insight FROM learnings WHERE domain LIKE '%{topic}%'"
</substep>

<substep id="3b_anti_patterns_first">
search BEFORE solutions:
  - "{tech} not working"
  - "{tech} issues production"
  - "{tech} gotchas"
  - "{tech} vs" (alternatives)
record: 3-5 anti-patterns with causes and fixes
</substep>

<substep id="3c_solutions">
order:
  - official docs (authoritative)
  - github issues with solutions (real problems, real fixes)
  - stack overflow high-vote (battle-tested)
threshold: if package needed, npm 100K+/week minimum
</substep>

<substep id="3d_builtin_check">
rule: before ANY new dependency, check if existing stack solves it
preference: framework built-in > standard library > npm package
why: fewer dependencies = fewer liabilities
</substep>

<substep id="3e_output">
write_to: _meta/research/{topic}.md
format: |
  # {Topic} Research
  ## Anti-Patterns (what breaks)
  1. {pattern}: {why} → {fix}
  ## Proven Solution
  - package: {name}@{version}
  - downloads: {weekly}
  - lines: ~{N}
  ## Alternatives Rejected
  - {alt}: {why rejected}
  ## Sources
  - {urls}
</substep>

<rule>tier 2+: spawn kernel:researcher for parallel research</rule>
</step>

<step id="4_scope">
<output>
files:
  1: {path} - {what changes}
  2: {path} - {what changes}
count: N
tier: 1|2|3
</output>

<tier_rules>
1: 1-2 files → execute directly
2: 3-5 files → contract + surgeon
3: 6+ files → contract + surgeon + adversary
ambiguous: assume higher tier
</tier_rules>
</step>

<step id="5_tests" name="TESTS (BEFORE CODE)">
<rule>Define success before coding, tests first always.</rule>
skill_ref: skills/testing/SKILL.md

<acceptance>
done_when:
  - observable outcome 1
  - observable outcome 2
  - edge case handled

evals:
  code_grader: command that returns PASS/FAIL
  manual_check: what to verify
  regression: existing tests that must still pass

fail_if:
  - anti-pattern from research occurs
  - known gotcha manifests
  - regression in existing functionality
</acceptance>

<tests_first>
do: write failing tests before implementation
why: code-then-tests validates bugs not requirements
principles:
  mock_boundaries_only: external APIs, DBs — NOT internal functions
  real_deps_preferred: test containers > mocks
  edge_cases_first: null, empty, boundary, concurrent, timeout
  strong_assertions: specific values, not truthy/exists
</tests_first>

<ai_test_anti_patterns>
- coverage_theater: 100% coverage with toBeTruthy() catches nothing
- happy_path_only: AI optimizes for common cases, test edges
- implementation_coupling: test behavior, not structure
- ai_test_trust: AI tests validate bugs - review what they assert
</ai_test_anti_patterns>
</step>

<step id="5.5_calibration" name="VELOCITY CALIBRATION">
Before executing, calibrate expectations based on task type:

<task_speed_gains>
boilerplate: 10x (low scrutiny)
config_docker: 8-10x (mostly correct)
api_integration: 3-5x (check auth/errors)
domain_logic: 2-5x (high scrutiny - edge cases)
architecture: 1x (human-led, AI assists)
</task_speed_gains>

<timeline_baselines>
simple_crud: 2-3 days
mvp_with_payment: 5-7 days
saas_custom: 10-14 days
fullstack_complex: 3-4 weeks
</timeline_baselines>

<scrutiny_level>
boilerplate: low - mostly mechanical
api: medium - check auth, error handling
domain_logic: high - edge cases, business rules
security_sensitive: very high - full security review
</scrutiny_level>

<expectation>
- Code review takes 2-3x longer for AI code
- 10.83 findings per AI PR vs 6.45 human
- Quality gates BEFORE review catch 80% of issues
</expectation>

reference: _meta/research/ai-code-anti-patterns.md
</step>

<step id="6_execute">
<tier_1>
1: reference research doc before coding
2: write failing tests first (edge cases!)
3: implement using proven pattern from research
4: check against Big 5 anti-patterns (_meta/research/ai-code-anti-patterns.md)
5: run evals
6: commit when done_when satisfied
</tier_1>

<big_5_check>
input_validation: Zod schema for every endpoint?
edge_cases: null, empty, unicode, timeout handled?
error_handling: no empty catch blocks?
duplication: extracted to utilities?
complexity: functions < 30 lines?
</big_5_check>

<tier_2_plus>
rule: you do NOT write code, you do NOT edit files
steps:
  1: agentdb contract '{"goal":"X","files":["Y"],"research":"_meta/research/Z.md","evals":["cmd"],"tier":N}'
  2: git checkout -b {type}/{name}
  3: spawn surgeon with contract reference
  4: wait for checkpoint
  5: (tier 3) spawn adversary
  6: verify evals pass
  7: report to user
</tier_2_plus>
</step>

<step id="7_learn" name="LEARN (MANDATORY BEFORE STOPPING)">
<rule>Every task teaches, capture it or lose it.</rule>

<what_worked>
do: agentdb learn pattern "{what succeeded}" "{evidence}"
</what_worked>

<what_failed>
do: agentdb learn failure "{what broke}" "{evidence}"
also: agentdb learn gotcha "{unexpected}" "{context}"
</what_failed>

<update_research>
if: discovered new anti-patterns or better solutions
then: append to _meta/research/{topic}.md
</update_research>

<checkpoint>
do: agentdb write-end '{"task":"X","tier":N,"research":"path","learned":["Z"],"pass_at_1":true|false}'
rule: MUST run before session ends
why: skip = next session repeats mistakes
</checkpoint>
</step>

<output_format>
every_response:
  task: one sentence
  type: bug|feature|refactor|question
  tier: 1|2|3
  research: none|existing|new → path if applicable
  tests: defined|pending|written
  status: researching|scoping|testing|executing|complete|blocked
</output_format>

<hard_stops>
ask_file_location: STOP → search first (Glob, Grep)
ask_config_value: STOP → read the file
code_without_research: STOP → do step 3
code_without_tests: STOP → do step 5
code_for_tier_2+: STOP → spawn surgeon
skip_agentdb_read: STOP → go back to step 1
end_without_agentdb_write: STOP → do step 7
implement_without_antipattern_check: STOP → review research

rule: AgentDB read/write is non-negotiable, skip = repeat failures
</hard_stops>

<quick_reference>
<research_triggers>
- new dependency needed
- unfamiliar technology
- "best way to..." questions
- performance-sensitive code
- security-sensitive code
</research_triggers>

<skip_research_only_when>
- trivial change (typo, rename)
- exact same task done before with research doc
- user explicitly says "just do it, I know the approach"
</skip_research_only_when>

<key_references>
ai_anti_patterns: _meta/research/ai-code-anti-patterns.md
testing: skills/testing/SKILL.md
security: skills/security/SKILL.md
architecture: skills/architecture/SKILL.md
</key_references>

<remember>
- 50-70% planning, 30-50% coding
- AI code is 1.7x buggier - scrutinize
- Edge cases missing by default - test them
- Slow down to speed up
</remember>

for_autonomous_mode: /kernel:auto (ralph mode)
</quick_reference>

</command>
