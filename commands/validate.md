<command id="kernel:validate">
<description>Pre-commit/pre-PR verification loop. Build → Types → Lint → Tests → Security → Diff. Blocks on failure.</description>

<!-- ============================================ -->
<!-- PURPOSE                                      -->
<!-- ============================================ -->

<purpose>
Run before shipping. Catches issues before they reach PR review.
Spawns kernel:validator agent for execution.
Stops on first failure - no point running tests if build fails.
</purpose>

<!-- ============================================ -->
<!-- STARTUP                                      -->
<!-- ============================================ -->

<startup>
STEP 1: Read AgentDB
```
agentdb read-start
```

STEP 2: Load skills
```
skills/testing/SKILL.md
skills/security/SKILL.md
```

STEP 3: Detect project type
- Check for: package.json, Cargo.toml, go.mod, pyproject.toml, requirements.txt
- Identify: test runner, linter, type checker
</startup>

<!-- ============================================ -->
<!-- VERIFICATION WORKFLOW                        -->
<!-- ============================================ -->

<workflow>
Execute in order. Stop on first failure.

## 1. Build Check
```bash
# JavaScript/TypeScript
npm run build || pnpm build || yarn build

# Rust
cargo build

# Go
go build ./...

# Python
python -m py_compile $(find . -name "*.py" -not -path "./venv/*")
```

## 2. Type Check
```bash
# TypeScript
npx tsc --noEmit

# Python
mypy . || pyright
```

## 3. Lint Check
```bash
# JS/TS
npx eslint . --max-warnings=0

# Python
ruff check . || flake8

# Go
golangci-lint run
```

## 4. Test Suite
```bash
# JS/TS
npm test -- --coverage

# Python
pytest --cov

# Go
go test -cover ./...

# Rust
cargo test
```

## 5. Security Scan
```bash
# Dependencies
npm audit --audit-level=high || pip-audit || cargo audit || govulncheck ./...

# Secrets in code
hooks/scripts/detect-secrets.sh
```

## 6. Diff Review
```bash
git diff --stat
git diff HEAD~1 --name-only
```
</workflow>

<!-- ============================================ -->
<!-- REPORT FORMAT                                -->
<!-- ============================================ -->

<report_format>
```
VERIFICATION REPORT
===================
Build:     [PASS/FAIL]
Types:     [PASS/FAIL] (X errors)
Lint:      [PASS/FAIL] (X warnings)
Tests:     [PASS/FAIL] (X/Y passed, Z% coverage)
Security:  [PASS/FAIL] (X vulnerabilities)
Diff:      X files changed, +Y/-Z lines

Status:    [READY/NOT READY] for PR

Issues:
1. [file:line] issue description
2. [file:line] issue description
```
</report_format>

<!-- ============================================ -->
<!-- WHEN TO RUN                                  -->
<!-- ============================================ -->

<usage>
Run `/kernel:validate` before:
- Creating a PR
- Merging to main
- Deploying to production
- Handoff to another agent/session

Do NOT skip steps. A "quick validate" is not validate.
</usage>

<!-- ============================================ -->
<!-- ON COMPLETE                                  -->
<!-- ============================================ -->

<on_complete>
agentdb write-end '{"command":"validate","build":"pass|fail","types":"pass|fail","lint":"pass|fail","tests":"X/Y","security":"pass|fail","status":"ready|not_ready"}'

If READY: proceed with intended action (PR, merge, deploy).
If NOT READY: list issues, do not proceed.
</on_complete>

</command>
