# Code review: Kernel 8.5.0 marketing + recall

Verdict: APPROVE

## Scope reviewed

- Frontend v2, marketing-site v1, landing-page v2, client-delivery reference.
- Recall recipe/rerun behavior in governance, generated startup, AgentDB lean/guide/help,
  build, debug, and diagnose.
- Version, release docs, inventory, regression tests, and generated adapters.

## Findings resolved

1. Removed duplicate `marketing-site` registration from the workflow registry; it belongs
   once in the methodology registry.
2. Updated stale README/Quickstart skill counts to 35 and kept the Claude/Codex agent
   boundary explicit.
3. Replaced remaining governance/help language that made full `read-start` sound mandatory;
   task recall is primary, full read is for audit/resume.
4. Kept the lean surface bounded (regression max 12 lines) while adding the concrete recipe.
5. Preserved landing-page explicit-only deployment and made existing user deploy intent count.

## Verification

- Focused marketing, read-start, governance, release-doc, version-sync suites: pass.
- Full suite: 426 passed, 0 failed.
- Generated governance: current.
- `git diff --check`: pass.
- `agents/openai.yaml`: parses as YAML.
- Generic skill-creator validator cannot validate Kernel's extended frontmatter keys
  (`kernel`, `user-invocable`, `disable-model-invocation`); Kernel's own taxonomy/frontmatter
  tests pass. Safety metadata was not weakened for generic compatibility.

## Release isolation

- Git ref writes fail with `Operation not permitted` in the nested submodule metadata, so the
  release branch was built in a clean temporary clone from `origin/main`.
- Concurrent user-owned AgentDB graph work is modifying `orchestration/agentdb/agentdb`,
  `tests/run-tests.sh`, eval code, migration 016, and `graph.py`. Those changes are excluded
  from the clean release diff.
- Clean clone: 421/422 in one run; the sole failure was the sandbox refusing to rewrite the
  real installed-plugin selector. The same compaction suite passed 8/8 with a disposable cache
  selector. The source checkout passed 426/426, including the concurrent graph tests.
