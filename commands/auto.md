---
name: kernel:auto
description: "Autonomous execution loop. Tests first, iterate until green. No hand-holding. Triggers: auto, ralph, loop, autonomous, ship it."
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Task, WebSearch, WebFetch
---

<command id="auto">

<mindset>
core: slow down to speed up
paradox: devs think 20% faster, actually 19% slower (METR 2025)
fix: tests first + research first = actually fast

ai_code_reality:
  buggier: 1.7x more issues than human code
  security: 40-62% contain vulnerabilities
  edge_cases: missing by default
  review_burden: 2-3x longer

calibration:  # from research
  boilerplate: 10x speed, low scrutiny
  api_integration: 3-5x speed, check auth/errors
  domain_logic: 2-5x speed, high scrutiny
  architecture: 1x speed, human-led
</mindset>

<mode>
loop: until verified complete
trigger: ralph, auto, "just do it", "ship it"
flow: RESEARCH → TESTS → IMPLEMENT → VERIFY → (loop if red) → SHIP

<when_to_use>
- user trusts iteration
- clear success criteria
- familiar domain
</when_to_use>

<when_not_to_use>
- user wants visibility into each step
- unfamiliar domain
- high-risk/irreversible changes
</when_not_to_use>
</mode>

<phase id="0_setup">
<mandatory>
```bash
agentdb read-start
```
extract:
  - prior_failures: don't repeat
  - testing_patterns: follow existing
  - active_contract: resume or close
</mandatory>

<classify>
goal: what success looks like
type: bug|feature|refactor
tier: 1|2|3
exit_criteria: must be testable
</classify>
</phase>

<phase id="1_research">
<search_order>
anti-patterns FIRST:
  1: "{tech} not working", "{tech} gotchas"
  2: "{tech} best practices 2025 2026"
  3: official docs → github issues → stack overflow
</search_order>

output: _meta/research/{topic}.md

<extract>
- anti_patterns: 3-5 with fixes
- proven_solution: package + stats
- testing_approach: for this domain
</extract>

<rule>spawn researcher agent if complex</rule>
</phase>

<phase id="2_tests_first">
<rule>Tests BEFORE implementation, no exceptions.</rule>

<substep id="2a_identify">
TESTS NEEDED:
- [ ] {behavior} → {expected}
- [ ] {edge_case} → {expected}
- [ ] {error_case} → {expected}
</substep>

<substep id="2b_write_failing">
do: write tests that fail
verify: npm test must FAIL (red)
if_passes: tests are wrong, testing nothing
</substep>

<substep id="2c_philosophy">
<mock_only>
- external HTTP APIs (nock/msw)
- third-party services (Stripe, Auth0)
- time-sensitive operations
</mock_only>

<never_mock>
- internal functions
- database (use test container or in-memory)
- file system (use tmp dirs)
- your own services
</never_mock>
</substep>

<principles>
tests_first: code-then-tests validates bugs
mock_boundaries_only: NOT internal functions
real_deps_preferred: test containers > mocks
edge_cases_first: null, empty, boundary, concurrent, timeout
strong_assertions: specific values, not truthy/exists
graceful_fallbacks: test primary, fallback, AND degraded mode
</principles>
</phase>

<phase id="3_implement" type="loop">
<loop>
3a: write minimal code to pass tests
3b: run tests (npm test --coverage)
3c: evaluate:
  all_pass: → phase 4
  failing: → fix implementation (NOT tests)
  flaky: → fix test (async/race issue)
  coverage_low: → add edge case tests
3d: repeat until green + coverage >= 80%
</loop>

max_iterations: 5
on_max_exceeded: STOP, report blockers to user
</phase>

<phase id="4_verify">
<checks>
build: npm run build
lint: npm run lint
test: npm test --coverage
security: npm audit --audit-level=high
diff: git diff --stat
</checks>

on_any_fail: back to phase 3
</phase>

<phase id="5_ship">
<steps>
commit: git add -A && git commit -m "{type}({scope}): {desc}"
push: git push -u origin HEAD
report:
  goal: what was done
  tests: N added, X% coverage
  files: list
  iterations: N
  branch: name
</steps>

<learn>
do: agentdb learn pattern "what worked"
then: agentdb write-end '{"command":"auto","iterations":N,"tests":N,"coverage":"X%","shipped":true}'
</learn>
</phase>

<parallel_execution name="tier 2+">
<spawn_order>
1: researcher → _meta/research/{topic}.md
2: test_writer → failing tests (parallel with 1)
3: wait for 1,2
4: surgeon → implement to pass tests
5: adversary → find edge cases, add tests
6: validator → full verification
</spawn_order>

<rule>orchestrator reads AgentDB, does NOT write code</rule>
</parallel_execution>

<loop_control>
<continue_if>
- tests failing but progress made
- coverage increasing
- new edge cases discovered
</continue_if>

<stop_if>
- 5 iterations without progress
- blocked on external dependency
- scope creep detected
- security concern found
</stop_if>

<escalate_if>
- architectural decision needed
- trade-off requires human judgment
- risk exceeds autonomous threshold
</escalate_if>
</loop_control>

<graceful_fallbacks>
pattern: |
  try primary
  catch → try fallback
  catch → return cached/default

<test_all_three>
- primary success
- fallback success
- degraded mode
</test_all_three>

example: |
  async function fetch() {
    try { return await primary.fetch() }
    catch {
      try { return await fallback.fetch() }
      catch { return cache.get() ?? DEFAULT }
    }
  }
</graceful_fallbacks>

<anti_patterns>
<dont>
code_then_tests: validates bugs
mock_everything: mock boundaries only
test_implementation: test behavior
happy_path_only: edge cases first
weak_assertions: specific values
loop_forever: max 5, then report
skip_research: prevents 80% of bugs
</dont>

<do>
tests_first: always
mock_boundaries: external APIs, DBs
test_behavior: at public interface
edge_cases: null, empty, boundary, error
strong_assertions: specific values
max_iterations: 5 then stop
research_first: anti-patterns before solutions
</do>

<big_5_check>
input_validation: Zod schema for every endpoint?
edge_cases: null, empty, unicode, timeout handled?
error_handling: no empty catch blocks?
duplication: extracted to utilities?
complexity: functions < 30 lines?
</big_5_check>

reference: _meta/research/ai-code-anti-patterns.md
</anti_patterns>

<quick_start>
example:
  user: "ralph add user authentication"

  agent:
    1: agentdb read-start
    2: research auth anti-patterns, proven packages
    3: write failing tests (login, logout, session, invalid creds, expired token)
    4: implement minimal auth to pass tests
    5: loop until green + 80% coverage
    6: validate (build, lint, test, security)
    7: ship (commit, push)
    8: agentdb write-end

  user_interaction: 0 (unless blocked)
</quick_start>

</command>
