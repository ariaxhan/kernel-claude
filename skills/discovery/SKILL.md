---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.

name: discovery
description: Codebase reconnaissance - map terrain before action
triggers:
  - discover
  - explore codebase
  - new codebase
  - what's in this repo
  - map the code
  - understand project
---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


# Discovery Skill

## Purpose

Reconnaissance before action. Map the terrain. Identify tooling. Extract conventions. Spot risks. Populate state with discovered reality, not assumptions.

**Key Concept**: Never assume - always investigate.

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Auto-Trigger Signals

This skill activates when detecting:
- "new codebase", "explore", "discover"
- "what's in this", "understand this"
- "map the code", "learn the codebase"
- First interaction with unfamiliar repo

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Process

```
1. INVENTORY → Find what exists (files, tools, config)
2. MAP → Identify structure (entrypoints, modules, boundaries)
3. EXTRACT → Discover conventions (naming, errors, logging)
4. IDENTIFY RISKS → Flag critical paths and danger zones
5. UPDATE STATE → Populate state.md with findings
```

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Repo Map Patterns

```
Entry Points:
- main.py, index.js, main.go, lib.rs

Code Directories:
- src/, lib/, pkg/

Test Directories:
- tests/, test/, __tests__/

Config Files:
- package.json, pyproject.toml, Cargo.toml, go.mod
```

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Tooling Detection

```bash
# Formatter
which prettier || which black || which gofmt || which rustfmt

# Linter
which eslint || which pylint || which flake8 || which golangci-lint

# Typecheck
which tsc || which mypy || which pyright

# Tests
npm test --help || pytest --version || go test --help || cargo test --help

# Package manager
which npm || which yarn || which pnpm || which pip || which poetry || which cargo
```

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Convention Extraction

| Convention | How to Find |
|------------|-------------|
| Naming | Grep function/class definitions, look for patterns |
| Error handling | Search for try/catch, Result<T>, if err != nil |
| Logging | Find logger imports and usage |
| Config | Check .env, config/, settings.py |

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Risk Identification

**Critical - Do Not Touch Without Backup:**
- Files named migration, schema, auth
- Database connection strings
- External API calls
- Files with TODO: remove, deprecated, legacy

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Stack-Specific Discovery

**JavaScript/TypeScript:**
- Check package.json scripts
- Look for tsconfig.json

**Python:**
- Check pyproject.toml, setup.py, requirements.txt
- Look for pytest.ini, tox.ini

**Go:**
- Check go.mod for module structure
- Look for Makefile

**Rust:**
- Check Cargo.toml for workspace structure
- Look for build.rs

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Output Format

Update `_meta/context/active.md`:

```markdown
## Repo Map
- Entry: src/main.py
- Core: src/core/, src/services/
- Tests: tests/
- Config: config/settings.py

## Tooling Inventory
| Tool | Command | Status |
|------|---------|--------|
| Formatter | black | available |
| Linter | flake8 | available |
| Tests | pytest | available |

## Conventions
- Naming: snake_case for functions/variables
- Errors: raise custom exceptions, log with logger.error()
- Config: environment variables via python-dotenv

## Do Not Touch
- migrations/ directory
- src/auth/ - security-critical
```

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Anti-Patterns

- Assuming conventions without verifying
- Missing critical paths
- Not updating state.md
- Skipping tooling detection
- Touching auth/migration without understanding

---

## ●:ON_START (REQUIRED)

```bash
agentdb read-start
```

Check existing patterns and learnings before exploring.


## Success Metrics

Discovery is working well when:
- State.md reflects actual codebase
- Tooling is identified and documented
- Conventions are explicit, not assumed
- Risk zones are marked and respected

---

## ●:ON_END (REQUIRED)

```bash
agentdb write-end '{"discovered":"X","key_files":["a","b"]}'
agentdb learn pattern "what I learned about this codebase" "evidence"
```
