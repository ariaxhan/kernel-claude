---
name: kernel:ingest
description: "Guided entry point. Research → classify → scope → execute. Human confirms each phase. Triggers: start, begin, do, implement, build, fix, create."
user-invocable: true
allowed-tools: Read, Bash, Grep, Glob, Task, WebSearch, WebFetch
---

<command id="ingest">

<purpose>
Guided entry: READ → CLASSIFY → RESEARCH → SCOPE → TESTS → EXECUTE → LEARN
Human confirms each phase. For autonomous loop: /kernel:forge
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

<ask_user>
  Use AskUserQuestion when: classification is ambiguous (could be bug or feature, refactor or rewrite)
  Ask: "This looks like {type_A} but could be {type_B}. Which framing fits your intent?"
  Options: type_A, type_B, or clarify
</ask_user>

After classify: load matching workflow from workflows/{type}.md if it exists.
Workflow steps guide the phase sequence. Human confirms at each step (ingest mode).
</step>

<branch after="classify">
  IF type == handoff → go to HANDOFF RESUME (below)
  IF familiar AND tier_likely_1 → skip to step 3 (scope), mark research="skipped (familiar)"
  IF unfamiliar OR complex → proceed to step 2 (research)
  ALWAYS: check _meta/research/ cache regardless (cache != full research)
</branch>

<step id="1b_handoff_resume" trigger="classify.type == handoff">
  Auto-detect and resume from a handoff file.

  1. **Find the handoff**: If user specified a file path, read it. Otherwise:
     ```bash
     ls -t _meta/handoffs/*.md | head -1
     ```
     Read the most recent handoff file.

  2. **Extract resume context**: Parse the handoff for:
     - **Goal**: What the prior session was doing
     - **Current state**: Where it left off (branch, dirty/clean, artifacts)
     - **Decisions made**: Choices to preserve (don't re-explore rejected alternatives)
     - **Next steps**: The numbered action items — these become the task
     - **Warnings**: Failed approaches to avoid
     - **Tier**: Inherited from handoff

  3. **Verify state matches**: Check that git state matches handoff expectations:
     ```bash
     git branch --show-current    # matches handoff branch?
     git status --short            # matches handoff dirty/clean?
     ```
     If state diverges from handoff (e.g., branch was merged, files already committed),
     note the divergence and adjust next steps accordingly.

  4. **Resume**: Skip classify/research/scope (already done in prior session).
     Jump directly to the appropriate step:
     - If next steps are "commit and push" → go to step 5 (execute)
     - If next steps are "implement X" → go to step 4 (tests) then step 5
     - If next steps are "research X" → go to step 2 (research)
     - If next steps are "review/test" → go to step 4 (tests)

  Output: "Resuming from handoff: {filename}. Goal: {goal}. Next: {first action}."
</step>

<step id="2_research" mandatory="true">
**RULE: Research without verification is theory fiction.** Every research finding must be verified
with a minimal test, prototype, or proof before it drives implementation. 8 research agents and
6 docs mean nothing if nobody built a test to prove the approach works. (LRN-F11)

<substeps>
1. Check existing: ls _meta/research/, agentdb query
2. anti_patterns FIRST: "{tech} not working", "{tech} gotchas"
3. Solutions: official docs, GitHub issues, Stack Overflow
4. Built-in check: framework > stdlib > npm package
5. **Verify**: build minimal proof (test screen, script, unit test) before committing to approach
6. Write to: _meta/research/{topic}.md (include verification result)
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

<ask_user>
  Use AskUserQuestion when: research reveals multiple viable approaches or unknown risks
  Ask: "Research found {N} approaches. Proceed with {recommended}, or explore alternatives?"
  Options: proceed, explore alternatives, skip research
</ask_user>
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

<ask_user>
  Use AskUserQuestion when: tier classification is borderline (e.g., 2-3 files but complex coupling)
  Ask: "Scoped to {N} files — tier {X}. Confirm tier, or should I treat as tier {X+1}?"
  Options: confirm tier {X}, bump to tier {X+1}
</ask_user>
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
5. Run evals → /kernel:validate before commit
6. Commit when done_when satisfied
</tier_1>

<tier_2_plus>
rule: you do NOT write code
1. /kernel:tearitapart — review plan before implementation
2. agentdb contract '{"goal":"X","files":["Y"],"tier":N}'
2b. If non-local profile: _gh_create_issue with contract goal + tier label
3. git checkout -b {type}/{name}
4. Spawn surgeon
5. Wait for checkpoint
6. (tier 3) spawn adversary
7. /kernel:validate → verify evals
8. /kernel:review — self-review before PR
</tier_2_plus>
</step>

<branch after="execute">
  IF adversary rejects (tier 3) → return to execute with adversary feedback, max 3 retries
  IF tests fail → /kernel:diagnose, fix, re-execute
  IF blocked → checkpoint and STOP, ask human
</branch>

<step id="6_learn" mandatory="true">
<rule>Every task teaches. Capture or lose.</rule>

agentdb learn pattern "{what worked}" "{evidence}"
agentdb learn failure "{what broke}" "{evidence}"
Update _meta/research/ if new findings.
Suggest /kernel:retrospective if 5+ learnings accumulated since last synthesis.

<checkpoint>
agentdb write-end '{"task":"X","tier":N,"learned":["Z"]}'
MUST run before session ends.
</checkpoint>
</step>

<output_format>
task: one sentence | type: bug|feature|refactor | tier: 1|2|3 | status: researching|scoping|testing|executing|complete
</output_format>

<hard_stops>
ask_file_location→search | code_without_research→step2 | code_without_tests→step4 | code_tier2+→surgeon | skip_agentdb→go_back
</hard_stops>

</command>
