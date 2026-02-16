# Discovery Bank

## Philosophy
Reconnaissance before action. Map the terrain. Identify tooling. Extract conventions. Spot risks. Populate `kernel/state.md` with discovered reality, not assumptions.

## Process Skeleton
1. **Inventory** → Find what exists (files, tools, config)
2. **Map** → Identify structure (entrypoints, modules, boundaries)
3. **Extract** → Discover conventions (naming, errors, logging)
4. **Identify Risks** → Flag critical paths and danger zones
5. **Update State** → Populate `kernel/state.md` with findings

---

## Slots (Designed to Fill)

### Repo Map Patterns (max 10)
[TO EVOLVE: Add techniques for finding entrypoints, modules, boundaries in THIS codebase]

- Check for `main.py`, `index.js`, `main.go`, `lib.rs` as likely entrypoints
- Look for `src/`, `lib/`, `pkg/` as code directories
- Check for `tests/`, `test/`, `__tests__/` for test location
- Check `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod` for metadata

### Tooling Detection Commands (max 8)
[TO EVOLVE: Add discovered tool detection commands]

```bash
# Formatter
which prettier || which black || which gofmt || which rustfmt

# Linter
which eslint || which pylint || which flake8 || which golangci-lint || which clippy

# Typecheck
which tsc || which mypy || which pyright || which go

# Tests
npm test --help || pytest --version || go test --help || cargo test --help

# Package manager
which npm || which yarn || which pnpm || which pip || which poetry || which cargo
```

### Convention Extraction Techniques (max 10)
[TO EVOLVE: Add patterns for discovering conventions in THIS codebase]

- **Naming**: Grep for function/class definitions, look for patterns (camelCase, snake_case, PascalCase)
- **Error handling**: Search for `try/catch`, `Result<T>`, `Option<T>`, `if err != nil` patterns
- **Logging**: Find logger imports and usage patterns
- **Config**: Check for `.env`, `config/`, `settings.py`, environment variable usage

### Risk Identification Patterns (max 5)
[TO EVOLVE: Add red flags discovered in THIS codebase]

- Files named `migration`, `schema`, `auth` → critical, do not touch without backup
- Database connection strings → data integrity risk
- External API calls → dependency risk
- Files with `TODO: remove`, `deprecated`, `legacy` → technical debt

### Stack-Specific Discovery (max 10 total across all stacks)
[TO EVOLVE: Add as you encounter language/framework specifics]

**JavaScript/TypeScript:**
- Check `package.json` scripts for available commands
- Look for `tsconfig.json` for TypeScript settings

**Python:**
- Check `pyproject.toml`, `setup.py`, `requirements.txt` for dependencies
- Look for `pytest.ini`, `tox.ini` for test configuration

**Go:**
- Check `go.mod` for module structure
- Look for `Makefile` for build commands

**Rust:**
- Check `Cargo.toml` for workspace structure
- Look for `build.rs` for build scripts

---

## Output Format

After discovery, update `kernel/state.md`:

```markdown
## Repo Map
- Entry: src/main.py
- Core: src/core/, src/services/
- Tests: tests/
- Config: config/settings.py

## Tooling Inventory
| Tool | Command | Status |
|------|---------|--------|
| Formatter | black | ✓ available |
| Linter | flake8 | ✓ available |
| Tests | pytest | ✓ available |

## Conventions
- Naming: snake_case for functions/variables
- Errors: raise custom exceptions, log with logger.error()
- Config: environment variables via python-dotenv

## Do Not Touch
- migrations/ directory - database schema changes
- src/auth/ - authentication logic, security-critical
```

---

⚠️ **TEMPLATE NOTICE**
This bank is scaffolding. Expect gaps. Fill slots as you discover patterns in this codebase.
Move stable discoveries to `.claude/rules/patterns.md` when they solidify.
Respect caps; if full, replace least valuable or promote to rules.
