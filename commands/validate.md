---
description: Quick pre-commit validation - types, lint, tests in parallel
---

# Validate Command

## ●:ON_START

```bash
agentdb read-start
```

Pre-commit gate: run all checks before committing.

## Behavior

1. **Detect project stack** from files:
   - `tsconfig.json` → TypeScript
   - `pyproject.toml` → Python
   - `Cargo.toml` → Rust
   - `go.mod` → Go

2. **Run checks in parallel**:

   ### TypeScript/JavaScript
   ```bash
   npx tsc --noEmit &        # Types
   npx eslint . &            # Lint
   npm test &                # Tests
   wait
   ```

   ### Python
   ```bash
   mypy . &                  # Types
   ruff check . &            # Lint
   pytest &                  # Tests
   wait
   ```

   ### Rust
   ```bash
   cargo check &             # Types
   cargo clippy &            # Lint
   cargo test &              # Tests
   wait
   ```

   ### Go
   ```bash
   go vet ./... &            # Types/lint
   go test ./... &           # Tests
   wait
   ```

3. **Report results**:
   ```
   VALIDATE: [PASS/FAIL]

   Types:  PASS/FAIL
   Lint:   PASS/FAIL (X auto-fixed)
   Tests:  PASS/FAIL (X passed, X failed)
   ```

4. **Quick fixes** if issues found:
   - Auto-fix lint issues if possible
   - Show specific errors with file:line
   - Suggest fixes for common issues

## Usage

```
/validate
```

Run before every commit. Blocks if any check fails.

## ●:ON_END

```bash
agentdb write-end '{"command":"validate","did":"ran gates","passed":"types,lint,tests","result":"PASS|FAIL"}'
```
