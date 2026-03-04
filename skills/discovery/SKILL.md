---
name: discovery
description: >
  Codebase reconnaissance. Map structure, detect tooling, extract conventions,
  identify risks. Use on first interaction with unfamiliar repo or when
  onboarding to a new project.
  Triggers: discover, explore codebase, new codebase, map the code, understand project, what's in this repo.
allowed-tools: Read, Bash, Grep, Glob
---

<skill id="discovery">

<purpose>
Reconnaissance before action. Map terrain. Extract conventions. Spot risks.
Populate state with discovered reality, not assumptions.
</purpose>

<prerequisite>
  KERNEL active. Check AgentDB for prior discovery results before re-exploring.
</prerequisite>

<!-- PROCESS -->

<phase id="inventory" label="What exists?">
  Entry points: main.py, index.js, main.go, lib.rs, etc.
  Directories: src/, lib/, pkg/, tests/, config/.
  Config: package.json, pyproject.toml, Cargo.toml, go.mod, docker-compose.yml.
</phase>

<phase id="tooling" label="What tools are available?">
  Detect: formatter, linter, typechecker, test runner, package manager.
  Run --version or --help to confirm availability.
  Check config files for tool settings (.eslintrc, pyproject.toml, tsconfig.json).
</phase>

<phase id="conventions" label="What patterns are used?">
  Naming: grep function/class definitions, identify casing patterns.
  Error handling: search for try/catch, Result, if err != nil.
  Logging: find logger imports and usage patterns.
  Config: check .env, config/, environment variable patterns.
  Tests: find test files, identify framework and naming conventions.
</phase>

<phase id="risks" label="What's dangerous?">
  Flag: migration files, auth modules, database schemas, external API calls.
  Flag: files marked TODO, deprecated, legacy, hack, workaround.
  Flag: files with high churn (git log --format='%H' -- {file} | wc -l).
</phase>

<!-- OUTPUT -->

<output>
  Update _meta/context/active.md with:
  - Repo map (entry, core, tests, config).
  - Tooling inventory (tool, command, status).
  - Conventions (naming, errors, config, tests).
  - Risk zones (do not touch without understanding).

  <rule>Never assume conventions without verifying against actual code.</rule>
</output>

<on_complete>
  agentdb write-end with skill="discovery", codebase, patterns found, gotchas.
  <rule>Record findings so future sessions don't re-explore from scratch.</rule>
</on_complete>
</skill>