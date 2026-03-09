---
name: validate
description: "Pre-commit verification. Build, types, lint, tests, security scan. Blocks on failure. Triggers: validate, check, verify, pre-commit, ship."
user-invocable: true
allowed-tools: Read, Bash, Grep, Glob
---

# PURPOSE

Run before shipping. Catches issues before PR review.
Stops on first failure.

---

# STARTUP

```bash
agentdb read-start
```

Detect project type:
- Check for: package.json, Cargo.toml, go.mod, pyproject.toml

---

# VERIFICATION WORKFLOW

Execute in order. Stop on first failure.

## 1. Build Check
```bash
npm run build || pnpm build || cargo build || go build ./...
```

## 2. Type Check
```bash
npx tsc --noEmit || mypy . || pyright
```

## 3. Lint Check
```bash
npx eslint . --max-warnings=0 || ruff check . || golangci-lint run
```

## 4. Test Suite
```bash
npm test -- --coverage || pytest --cov || go test -cover ./... || cargo test
```

## 5. Security Scan
```bash
npm audit --audit-level=high || pip-audit || cargo audit
hooks/scripts/detect-secrets.sh
```

## 6. Diff Review
```bash
git diff --stat
git diff HEAD~1 --name-only
```

---

# REPORT FORMAT

```
VERIFICATION REPORT
===================
Build:     [PASS/FAIL]
Types:     [PASS/FAIL]
Lint:      [PASS/FAIL]
Tests:     [PASS/FAIL] (coverage%)
Security:  [PASS/FAIL]
Diff:      X files, +Y/-Z lines

Status:    [READY/NOT READY] for PR

Issues:
1. [file:line] description
```

---

# ON COMPLETE

```bash
agentdb write-end '{"command":"validate","status":"ready|not_ready"}'
```
