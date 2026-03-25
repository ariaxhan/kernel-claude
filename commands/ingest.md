---
name: kernel:ingest
description: "Guided entry point. Research → classify → scope → execute. Human confirms each phase. Triggers: start, begin, do, implement, build, fix, create."
user-invocable: true
allowed-tools: Read, Bash, Grep, Glob, Task, WebSearch, WebFetch
---

<command id="ingest">

<purpose>
Guided entry: READ → CLASSIFY → RESEARCH → SCOPE → TESTS → EXECUTE → LEARN
Human confirms each phase. For autonomous loop: /kernel:auto
</purpose>

<skill_load>
always: skills/quality/SKILL.md, skills/testing/SKILL.md, skills/git/SKILL.md
on_classify:
  bug:      skills/debug/SKILL.md, skills/testing/SKILL.md
  feature:  skills/build/SKILL.md, skills/architecture/SKILL.md
  refactor: skills/refactor/SKILL.md, skills/architecture/SKILL.md
  review:   skills/testing/SKILL.md, skills/security/SKILL.md
on_domain:
  api:      skills/api/SKILL.md, skills/backend/SKILL.md
  auth:     skills/security/SKILL.md
  frontend: skills/design/SKILL.md, skills/e2e/SKILL.md
  backend:  skills/backend/SKILL.md
on_tier:
  2+:       skills/orchestration/SKILL.md
reference: skills/quality/reference/quality-research.md
</skill_load>

<on_start>
```bash
agentdb read-start
ls _meta/research/  # check prior work
```

Load /kernel:quality, /kernel:testing, /kernel:git immediately.
After classify: load task-specific skills above. Do NOT proceed without loading them.
After scope: if tier 2+, load /kernel:orchestration.
If any domain detected (API, auth, frontend, backend): load domain skills.
</on_start>

<step id="1_classify">
task: what user wants (one sentence)
type: bug|feature|refactor|question|verify|handoff|review
familiar: yes|no

Search before asking: Glob, Grep, common paths.

After classify: load matching workflow from workflows/{type}.md if it exists.
Workflow steps guide the phase sequence. Human confirms at each step (ingest mode).
</step>

<branch after="classify">
  IF familiar AND tier_likely_1 → skip to step 3 (scope), mark research="skipped (familiar)"
  IF unfamiliar OR complex → proceed to step 2 (research)
  ALWAYS: check _meta/research/ cache regardless (cache != full research)
</branch>

<step id="2_research" mandatory="true">
<substeps>
1. Check existing: ls _meta/research/, agentdb query
2. anti_patterns FIRST: "{tech} not working", "{tech} gotchas"
3. Solutions: official docs, GitHub issues, Stack Overflow
4. Built-in check: framework > stdlib > npm package
5. Write to: _meta/research/{topic}.md
</substeps>

<format>
# {Topic} Research
## Anti-Patterns
1. {pattern}: {why} → {fix}
## Proven Solution
- package: {name}@{version}
## Sources
- {urls}
</format>

tier 2+: spawn kernel:researcher
</step>

<step id="3_scope">
files:
  1: {path} - {what changes}
count: N
tier: 1|2|3

<tiers>
1: 1-2 files → execute directly
2: 3-5 files → contract + surgeon
3: 6+ files → contract + surgeon + adversary
ambiguous: assume higher
</tiers>
</step>

<branch after="scope">
  IF scope reveals unknowns not covered by research → loop to step 2 with narrowed query
  IF scope is clear → proceed to step 4
</branch>

<step id="4_tests" mandatory="true">
<rule>Define success before coding. Tests first.</rule>
skill_ref: skills/testing/SKILL.md

done_when:
  - observable outcome 1
  - edge case handled

evals:
  code_grader: PASS/FAIL command
  regression: existing tests pass

<principles>
mock_boundaries_only: external APIs, DBs
edge_cases_first: null, empty, boundary, timeout
strong_assertions: specific values
</principles>
</step>

<step id="5_execute">
<tier_1>
1. Reference research doc
2. Write failing tests (edge cases!)
3. Implement proven pattern
4. Check Big 5: skills/quality/SKILL.md
5. Run evals
6. Commit when done_when satisfied
</tier_1>

<tier_2_plus>
rule: you do NOT write code
1. agentdb contract '{"goal":"X","files":["Y"],"tier":N}'
2. git checkout -b {type}/{name}
3. Spawn surgeon
4. Wait for checkpoint
5. (tier 3) spawn adversary
6. Verify evals
7. Report
</tier_2_plus>
</step>

<branch after="execute">
  IF adversary rejects (tier 3) → return to execute with adversary feedback, max 3 retries
  IF tests fail → diagnose, fix, re-execute
  IF blocked → checkpoint and STOP, ask human
</branch>

<step id="6_learn" mandatory="true">
<rule>Every task teaches. Capture or lose.</rule>

agentdb learn pattern "{what worked}" "{evidence}"
agentdb learn failure "{what broke}" "{evidence}"
Update _meta/research/ if new findings.

<checkpoint>
agentdb write-end '{"task":"X","tier":N,"learned":["Z"]}'
MUST run before session ends.
</checkpoint>
</step>

<output_format>
task: one sentence
type: bug|feature|refactor
tier: 1|2|3
research: none|existing|new
tests: defined|pending|written
status: researching|scoping|testing|executing|complete
</output_format>

<hard_stops>
- ask_file_location → search first
- code_without_research → step 2
- code_without_tests → step 4
- code_for_tier_2+ → spawn surgeon
- skip_agentdb → go back
- skip_skill_load → load the skill before proceeding
</hard_stops>

<protocol_fallback>
If session-start hook did not fire (no "# KERNEL" in context), this is the ambient protocol:
- AgentDB: read at start, write at end, learn on discovery
- Skills ARE the methodology — load them aggressively before acting
- Research anti-patterns BEFORE solutions. Tests BEFORE code.
- Tier 1: execute directly. Tier 2+: orchestrate via agents.
- Profile-gated git: local=direct, github-oss=PRs required
- Built-in beats library. Library beats custom.
</protocol_fallback>

</command>
