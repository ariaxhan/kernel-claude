<skill id="build">

<purpose>
Minimal code through maximum research. The best code is code you don't write.
Your first solution is never right. Explore, compare, choose simplest.
</purpose>

<prerequisite>
  This skill operates within KERNEL. AgentDB read-start has already run.
  Tier classification has already happened via /kernel:ingest.
  If tier 2+, a contract exists. Follow it.
</prerequisite>

<reference>
Skill-specific: skills/build/reference/build-research.md
General: skills/architecture/reference/architecture-research.md, skills/orchestration/reference/orchestration-research.md
</reference>

<!-- GOAL EXTRACTION -->

<goal_template>
GOAL: [What are we building?]
CONSTRAINTS: [Limitations, requirements, must-haves]
INPUTS: [What do we have to work with?]
OUTPUTS: [What should exist when done?]
DONE-WHEN: [How do we know it's complete?]
</goal_template>

<!-- SOLUTION EXPLORATION (NEVER SKIP) -->

<solution_exploration>
  <rule>Generate 2-3 approaches minimum. Never implement first idea.</rule>

  Per solution, document:
  - Approach name and brief description
  - Code required (~lines)
  - Dependencies (name, version, weekly downloads)
  - Pros, cons, complexity (simple/medium/complex)

  Evaluation criteria (ordered):
  1. Minimal code: fewest lines, simplest logic.
  2. Battle-tested package: most downloads = most reliable.
  3. Reliability: fewer edge cases, fewer bugs.
  4. Maintenance: active, clear docs.
  5. Performance: only if bottleneck exists.

  <rule>Write chosen solution + rejected alternatives to _meta/plans/{feature}.md.</rule>
  <rule>Plans under 50 lines. Longer = overthinking.</rule>
</solution_exploration>

<!-- ASSUMPTION VERIFICATION -->

<assumptions>
  Confirm (not guess) max 6 per category:
  - Tech stack (languages, frameworks, versions)
  - File locations (where code lives, where to create)
  - Naming conventions (casing, patterns in existing code)
  - Error handling approach (existing patterns)
  - Test expectations (framework, coverage requirements)
  - Dependencies (approved, version constraints)
</assumptions>

<!-- EXECUTION -->

<execution>
  BEFORE each step: review research doc, check if fewer lines possible.
  DURING: use researched package, minimal changes, follow existing patterns, one commit per logical unit.
  AFTER: verify works, count lines (can reduce?), commit, update plan.

  <rule>If tier 2+, you are the surgeon. Follow contract scope exactly.</rule>
</execution>

<!-- VALIDATION -->

<validation>
  Automated (run what exists):
  - Tests: npm test / pytest / cargo test / go test
  - Lint: eslint / ruff / clippy
  - Types: tsc --noEmit / mypy

  Manual: walk through done-when criteria. Document how verified.

  Edge cases (at least 3): empty/null, boundary, error/failure path.
</validation>

<!-- FAILURE HANDLING -->

<on_failure>
  <step>STOP immediately.</step>
  <step>Check research doc for this error.</step>
  <step>If documented fix exists, apply it.</step>
  <step>If not: question whether simpler solution was missed.</step>
  <step>Rollback to last known good: git checkout or git stash.</step>
  <step>Re-evaluate: still simplest solution?</step>
  <step>If solution feels complex: stop, search for simpler package.</step>
</on_failure>

<!-- COMPLETION -->

<on_complete>
  Report: feature name, branch, files changed (with what changed), validation results, next steps.
  <rule>agentdb write-end with skill="build", feature, files, approach.</rule>
</on_complete>

<flags>
  --quick: skip confirmations, minimal prompts.
  --plan-only: stop after planning.
  --resume: continue in-progress work.
  --validate-only: skip to validation.
</flags>
</skill>