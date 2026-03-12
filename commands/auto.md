---
name: kernel:auto
description: "Autonomous execution loop. Tests first, iterate until green. Triggers: auto, ralph, loop, autonomous."
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Task, WebSearch, WebFetch
---

<command id="auto">

<purpose>
Autonomous loop: RESEARCH → TESTS → IMPLEMENT → VERIFY → SHIP
Tests first. Iterate until green. Max 5 iterations then report.
</purpose>

<skill_load>
Load: skills/quality/SKILL.md, skills/testing/SKILL.md, skills/build/SKILL.md
</skill_load>

<on_start>
```bash
agentdb read-start
```
</on_start>

<phase id="0_setup">
Classify: goal, type (bug|feature|refactor), tier, exit criteria.
Check: _meta/research/ for prior work.
</phase>

<phase id="1_research">
Search anti-patterns FIRST: "{tech} not working", "{tech} gotchas"
THEN: "{tech} best practices", official docs
Output: _meta/research/{topic}.md
</phase>

<phase id="2_tests_first">
Write tests BEFORE implementation.
Verify: tests FAIL (red). If they pass, tests are wrong.
Edge cases: null, empty, boundary, timeout.
</phase>

<phase id="3_implement" type="loop">
```
3a: write minimal code to pass tests
3b: run tests
3c: evaluate:
  - all_pass → phase 4
  - failing → fix implementation (NOT tests)
  - coverage_low → add edge case tests
3d: repeat until green + coverage >= 80%

max_iterations: 5
on_max_exceeded: STOP, report blockers
```
</phase>

<phase id="4_verify">
Build, lint, test, security scan. Load skills/quality/SKILL.md for Big 5.
Any fail: back to phase 3.
</phase>

<phase id="5_ship">
Commit, push, report: goal, tests added, coverage, files, iterations.
</phase>

<on_complete>
```bash
agentdb learn pattern "what worked"
agentdb write-end '{"command":"auto","iterations":N,"tests":N,"coverage":"X%","shipped":true}'
```
</on_complete>

<loop_control>
continue_if: tests failing but progress, coverage increasing
stop_if: 5 iterations without progress, blocked, scope creep
escalate_if: architectural decision needed, risk exceeds threshold
</loop_control>

</command>
