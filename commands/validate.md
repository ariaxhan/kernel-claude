---
name: kernel:validate
description: "Pre-commit verification. Build, types, lint, tests, security scan. Blocks on failure. Triggers: validate, check, verify, pre-commit, ship."
user-invocable: true
allowed-tools: Read, Bash, Grep, Glob
---

<command id="validate">

<purpose>
Run before shipping. Catches issues before PR review.
Stops on first failure.

Reference: _meta/research/ai-code-anti-patterns.md
</purpose>

<context>
why_validate:
  - AI code is 1.7x buggier than human code
  - 40-62% contain security vulnerabilities
  - Quality gates BEFORE review catch 80% of issues
  - Review takes 2-3x longer without pre-validation

principle: slow down to speed up
  - Validation time < debugging time
  - Automated checks cheaper than human review
</context>

<on_start>
```bash
agentdb read-start
```

Detect project type:
- Check for: package.json, Cargo.toml, go.mod, pyproject.toml
</on_start>

<verification_workflow>
Execute in order. Stop on first failure.

<check id="1_build">
```bash
npm run build || pnpm build || cargo build || go build ./...
```
</check>

<check id="2_types">
```bash
npx tsc --noEmit || mypy . || pyright
```
</check>

<check id="3_lint">
```bash
npx eslint . --max-warnings=0 || ruff check . || golangci-lint run
```
</check>

<check id="4_tests">
```bash
npm test -- --coverage || pytest --cov || go test -cover ./... || cargo test
```
</check>

<check id="5_security">
```bash
npm audit --audit-level=high || pip-audit || cargo audit
hooks/scripts/detect-secrets.sh
```
</check>

<check id="6_diff">
```bash
git diff --stat
git diff HEAD~1 --name-only
```
</check>

<check id="7_big5" name="AI Code Quality (Big 5 Check)">
Quick checks for what AI actually breaks:

```bash
# Empty catch blocks
grep -r "catch.*{}" --include="*.ts" --include="*.js" | head -5

# String concatenation in queries (SQL injection risk)
grep -rE "SELECT.*\$\{|INSERT.*\$\{" --include="*.ts" --include="*.js" | head -5

# Functions > 30 lines (complexity smell)
# Manual spot check or use eslint complexity rule

# Missing validation on req.body
grep -r "req\.body" --include="*.ts" --include="*.js" | grep -v "parse\|validate\|z\." | head -5
```

If any Big 5 violations found: NOT READY
</check>

<ask_user>
  Use AskUserQuestion when: a gate fails (build, types, lint, tests, security, big5)
  Ask: "Gate {gate_name} failed: {summary}. Fix and retry, or skip this gate?"
  Options: fix and retry, skip gate (document reason), abort validation
</ask_user>
</verification_workflow>

<report_format>
VERIFICATION REPORT
===================
Build:     [PASS/FAIL]
Types:     [PASS/FAIL]
Lint:      [PASS/FAIL]
Tests:     [PASS/FAIL] (coverage%)
Security:  [PASS/FAIL]
Big 5:     [PASS/FAIL]
Diff:      X files, +Y/-Z lines

Status:    [READY/NOT READY] for PR

Issues:
1. [file:line] description
</report_format>

<on_complete>
```bash
agentdb write-end '{"command":"validate","status":"ready|not_ready","checks":{"build":"pass|fail","types":"pass|fail","lint":"pass|fail","tests":"pass|fail","security":"pass|fail","big5":"pass|fail"}}'
```
</on_complete>

</command>
