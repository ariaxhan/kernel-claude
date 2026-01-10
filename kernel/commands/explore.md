---
description: Before work in unfamiliar code - Map codebase structure and conventions
---

# Explore Codebase

**When to use**: Before starting work in unfamiliar codebase or after significant changes.
**What it does**: Maps repository structure, detects tooling, extracts conventions, and identifies critical paths.

## Process

1. Read `kernel/banks/DISCOVERY-BANK.md` for methodology
2. Read `kernel/state.md` for current context
3. Apply reconnaissance: inventory files, detect tooling, extract conventions, identify risks
4. Update `kernel/state.md` with all discoveries

## What Gets Discovered

**Repo Map**:
- Entrypoints (main files, index files)
- Module boundaries
- Key directories
- Test locations
- Documentation structure

**Tooling Inventory**:
- Formatter (prettier, black, gofmt, rustfmt)
- Linter (eslint, pylint, clippy)
- Type checker (tsc, mypy, go)
- Test runner (jest, pytest, cargo test)
- Package manager (npm, pip, cargo)
- Build system (webpack, make, cargo)

**Conventions**:
- Naming patterns (camelCase, snake_case, kebab-case)
- Error handling patterns (try/catch, Result<T>, if err != nil)
- Logging conventions (logger usage, log levels)
- Config management (.env, config files, environment variables)
- Import/module organization

**Critical Paths** (Do Not Touch):
- Migration files
- Auth/security code
- Database schemas
- API contracts
- Build configuration

## Example Output

```
> /explore

Reading discovery methodology...
Reading current state...

INVENTORY
---------
Files: 1,234
  Code: 856
  Tests: 245
  Docs: 89
  Config: 44

Directories:
  src/ - Main application code
  src/api/ - API endpoints
  src/models/ - Data models
  tests/ - Test suite
  docs/ - Documentation

TOOLING
-------
✓ Formatter: prettier (configured)
✓ Linter: eslint (configured)
✓ Type checker: TypeScript strict mode
✓ Tests: jest (npm test)
✓ Package manager: npm
✓ Build: webpack

CONVENTIONS
-----------
Naming:
  - Files: kebab-case (user-service.ts)
  - Functions: camelCase (getUserById)
  - Classes: PascalCase (UserService)
  - Constants: SCREAMING_SNAKE_CASE (API_BASE_URL)

Error handling:
  - throw Error() for fatal errors
  - return null for not found
  - logger.error() for logging

Config:
  - Environment: .env file (12 vars)
  - Runtime: config/default.json
  - Secrets: AWS Secrets Manager

CRITICAL PATHS
--------------
⚠️ src/auth/ - Authentication logic (security-critical)
⚠️ src/models/schema.ts - Database schema (migration-critical)
⚠️ src/api/payments/ - Payment processing (financial-critical)

STATE UPDATED
-------------
✓ Repo map populated (15 lines)
✓ Tooling inventory complete (6 tools)
✓ Conventions extracted (8 patterns)
✓ Critical paths identified (3 areas)

kernel/state.md updated with discoveries.
Ready to work with full context.
```

## Notes

- Run this first when joining a project
- Run again after major refactors
- Updates kernel/state.md as single source of truth
- Discoveries inform all other commands
