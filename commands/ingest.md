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
Load: skills/quality/SKILL.md, skills/testing/SKILL.md
Reference: skills/quality/reference/quality-research.md
</skill_load>

<on_start>
```bash
agentdb read-start
ls _meta/research/  # check prior work
```
</on_start>

<step id="1_classify">
task: what user wants (one sentence)
type: bug|feature|refactor|question|verify|handoff|review
familiar: yes|no

Search before asking: Glob, Grep, common paths.
</step>

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
</hard_stops>

</command>
