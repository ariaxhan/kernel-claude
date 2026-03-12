---
name: kernel:ingest
description: "Guided entry point. Research → classify → scope → execute. Human confirms each phase. Triggers: start, begin, do, implement, build, fix, create."
user-invocable: true
allowed-tools: Read, Bash, Grep, Glob, Task, WebSearch, WebFetch
---

# INGEST WORKFLOW (GUIDED)

```yaml
mode: step-by-step, human confirms each phase
flow: READ → CLASSIFY → RESEARCH → SCOPE → TESTS → EXECUTE → LEARN
mindset: every AI line is liability, most SWE is solved problems

vs_auto:
  ingest: guided, confirm each step, hand-holding
  auto: autonomous loop, iterate until green, ralph mode
```

---

## STEP 1: READ (MANDATORY FIRST)

```yaml
do: agentdb read-start
then: ls _meta/research/  # check prior work

output:
  failures_to_avoid: [from AgentDB]
  patterns_to_follow: [from AgentDB]
  active_contracts: resume or close first
  prior_research: check _meta/research/ for similar problems

rule: if similar task done before, read that research, don't repeat
```

---

## STEP 2: CLASSIFY

```yaml
output:
  task: what user wants (one sentence)
  type: bug|feature|refactor|question|verify|handoff|review
  familiar: yes|no

search_before_asking:
  1: Glob - **/*keyword*, **/*.{json,yaml,ts,py}
  2: Grep - error messages, function names, config keys
  3: common paths - ~/.config/, ~/.claude/, package.json
```

---

## STEP 3: RESEARCH (NOT OPTIONAL)

```yaml
rule: every implementation needs research

steps:
  3a_check_existing:
    do: ls _meta/research/
    query: agentdb query "SELECT insight FROM learnings WHERE domain LIKE '%{topic}%'"

  3b_anti_patterns_first:  # BEFORE solutions
    search:
      - "{tech} not working"
      - "{tech} issues production"
      - "{tech} gotchas"
      - "{tech} vs" (alternatives)
    record: 3-5 anti-patterns with causes and fixes

  3c_solutions:
    order:
      - official docs (authoritative)
      - github issues with solutions (real problems, real fixes)
      - stack overflow high-vote (battle-tested)
    threshold: if package needed, npm 100K+/week minimum

  3d_builtin_check:
    rule: before ANY new dependency, check if existing stack solves it
    preference: framework built-in > standard library > npm package
    why: fewer dependencies = fewer liabilities

  3e_output:
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

tier_2+: spawn kernel:researcher for parallel research
```

---

## STEP 4: SCOPE

```yaml
output:
  files:
    1: {path} - {what changes}
    2: {path} - {what changes}
  count: N
  tier: 1|2|3

tier_rules:
  1: 1-2 files → execute directly
  2: 3-5 files → contract + surgeon
  3: 6+ files → contract + surgeon + adversary

ambiguous: assume higher tier
```

---

## STEP 5: TESTS (BEFORE CODE)

```yaml
rule: define success before coding, tests first always

acceptance:
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

tests_first:
  do: write failing tests before implementation
  why: code-then-tests validates bugs not requirements
  principles:
    mock_boundaries_only: external APIs, DBs — NOT internal functions
    real_deps_preferred: test containers > mocks
    edge_cases_first: null, empty, boundary, concurrent, timeout
    strong_assertions: specific values, not truthy/exists
```

---

## STEP 6: EXECUTE

```yaml
tier_1:
  1: reference research doc before coding
  2: write failing tests first
  3: implement using proven pattern from research
  4: check against anti-patterns list
  5: run evals
  6: commit when done_when satisfied

tier_2+:
  rule: you do NOT write code, you do NOT edit files
  steps:
    1: agentdb contract '{"goal":"X","files":["Y"],"research":"_meta/research/Z.md","evals":["cmd"],"tier":N}'
    2: git checkout -b {type}/{name}
    3: spawn surgeon with contract reference
    4: wait for checkpoint
    5: (tier 3) spawn adversary
    6: verify evals pass
    7: report to user
```

---

## STEP 7: LEARN (MANDATORY BEFORE STOPPING)

```yaml
rule: every task teaches, capture it or lose it

what_worked:
  do: agentdb learn pattern "{what succeeded}" "{evidence}"

what_failed:
  do: agentdb learn failure "{what broke}" "{evidence}"
  also: agentdb learn gotcha "{unexpected}" "{context}"

update_research:
  if: discovered new anti-patterns or better solutions
  then: append to _meta/research/{topic}.md

checkpoint:
  do: agentdb write-end '{"task":"X","tier":N,"research":"path","learned":["Z"],"pass_at_1":true|false}'
  rule: MUST run before session ends
  why: skip = next session repeats mistakes
```

---

## OUTPUT FORMAT

```yaml
every_response:
  task: one sentence
  type: bug|feature|refactor|question
  tier: 1|2|3
  research: none|existing|new → path if applicable
  tests: defined|pending|written
  status: researching|scoping|testing|executing|complete|blocked
```

---

## WORKFLOW GATES

```yaml
hard_stops:
  ask_file_location: STOP → search first (Glob, Grep)
  ask_config_value: STOP → read the file
  code_without_research: STOP → do step 3
  code_without_tests: STOP → do step 5
  code_for_tier_2+: STOP → spawn surgeon
  skip_agentdb_read: STOP → go back to step 1
  end_without_agentdb_write: STOP → do step 7
  implement_without_antipattern_check: STOP → review research

rule: AgentDB read/write is non-negotiable, skip = repeat failures
```

---

## QUICK REFERENCE

```yaml
research_triggers:  # always research
  - new dependency needed
  - unfamiliar technology
  - "best way to..." questions
  - performance-sensitive code
  - security-sensitive code

skip_research_only_when:
  - trivial change (typo, rename)
  - exact same task done before with research doc
  - user explicitly says "just do it, I know the approach"

for_autonomous_mode:
  use: /kernel:auto (ralph mode)
  difference: loops until green, no hand-holding
```
