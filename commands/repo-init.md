---
description: Generate KERNEL-REPO for any codebase - standalone Claude Code configuration
allowed-tools: Read, Write, Bash, Glob, Grep, LSP, Task, AskUserQuestion, WebFetch
---

# repo-init

**Generate KERNEL-REPO — standalone Claude Code configuration for any codebase.**

Creates a complete, standalone configuration derived from KERNEL. Works for any project. Anyone can clone and use.

---

## Source of Truth

**This command reads from the KERNEL plugin itself:**
```
CLAUDE.md              → Philosophy, session protocol, methodology, agents, rules
kernel/CLAUDE.md       → Project CLAUDE.md template (the distributable template)
kernel/rules/          → Rule templates (assumptions, fail-fast, memory-protocol, etc.)
kernel/banks/          → Methodology banks (PLANNING, DEBUGGING, RESEARCH, etc.)
kernel/project-notes/  → Project memory templates (bugs, decisions, key_facts, issues)
```

**And generates for the target project:**
```
{project}/.claude/CLAUDE.md    → Standalone project config (filled from templates + analysis)
{project}/_meta/               → Session tracking
{project}/_memory/             → Project memory (from analysis or empty templates)
```

**Update KERNEL plugin → repo-init output automatically reflects changes.**

---

## Inputs

**Existing codebase:** Analyze and configure
**Empty repo + vision doc:** Bootstrap from vision
**Empty repo + idea:** Interactive scaffolding

---

## Phase 1: Detection

### 1.1 Determine Mode

```
IF .git exists AND files > 10:
  MODE = "existing"
  → Run full codebase analysis

ELIF vision.md OR blueprint.md OR VISION.md exists:
  MODE = "vision"
  → Bootstrap from vision document

ELSE:
  MODE = "new"
  → Ask what we're building
```

### 1.2 Detect Stack (existing codebases)

**Check for:**
```
package.json       → Node.js (check for Next.js, React, etc.)
requirements.txt   → Python
pyproject.toml     → Python (modern)
Cargo.toml         → Rust
go.mod             → Go
pom.xml            → Java/Maven
build.gradle       → Java/Gradle
*.csproj           → .NET
composer.json      → PHP
Gemfile            → Ruby
```

**Extract:**
- Primary language
- Framework (if any)
- Test framework
- Lint/format tools
- Build system

### 1.3 Detect Existing Config

```
IF .claude/ exists:
  WARN: "Existing config found. Merge or overwrite?"
  → Options: merge | overwrite | abort

IF .cursor/ exists:
  NOTE: "Cursor config found. Will preserve."
```

---

## Phase 2: Analysis (Existing Codebases)

### 2.1 Structure Analysis

**Map the codebase:**
```
1. Directory tree (depth 3, ignore node_modules, venv, etc.)
2. Count files by type
3. Identify entry points (main.*, index.*, app.*)
4. Identify config files
5. Identify test directories
```

**Output → `_memory/architecture.md`**

### 2.2 Pattern Discovery

**Analyze for conventions:**
```
1. File naming: kebab-case? camelCase? snake_case?
2. Function naming: grep for patterns
3. Error handling: search for try/catch, Result, error patterns
4. Logging: what library? what levels?
5. Import organization: stdlib first? grouped?
6. Test patterns: describe/it? test_*?
```

**Output → `_memory/conventions.md`**

### 2.3 Dependency Analysis

**Extract from package files:**
```
1. Runtime dependencies with versions
2. Dev dependencies
3. Identify key frameworks
4. Note external services (AWS, Firebase, Stripe, etc.)
```

**Check for .env.example or similar:**
```
1. Extract environment variable names
2. Categorize: required vs optional
3. Identify secrets (never expose values)
```

**Output → `_memory/dependencies.md`**

### 2.4 Hotspot Analysis

**Find complex areas:**
```
1. File size (large files = complex)
2. If git history available:
   - Most changed files (last 90 days)
   - Files with most contributors
3. Cyclomatic complexity (if tools available)
```

**Output → `_memory/hotspots.md`**

### 2.5 Data Flow Mapping

**Identify:**
```
1. Database/storage (Postgres, MongoDB, Redis, Convex, etc.)
2. API endpoints (routes, handlers)
3. External service integrations
4. Background jobs/workers
5. Event systems
```

**Output → included in `_memory/architecture.md`**

---

## Phase 3: Generation

### 3.1 Create Directory Structure

```
{project}/
├── .claude/
│   ├── CLAUDE.md           # Generated, filled in
│   └── settings.json       # Stack-specific hooks
│
├── _meta/
│   ├── context/
│   │   └── active.md       # Session state
│   ├── _session.md         # Session history
│   └── _learnings.md       # Discovered patterns
│
├── _memory/
│   ├── architecture.md     # GENERATED from analysis
│   ├── conventions.md      # GENERATED from analysis
│   ├── dependencies.md     # GENERATED from analysis
│   ├── hotspots.md         # GENERATED from analysis
│   ├── bugs.md             # Empty template
│   └── decisions.md        # Empty template
│
└── .github/                # If GitHub Actions requested
    ├── workflows/
    │   ├── ci.yml
    │   └── security.yml
    └── PULL_REQUEST_TEMPLATE.md
```

### 3.2 Generate CLAUDE.md (KERNEL-REPO)

**Read from the KERNEL plugin's `kernel/CLAUDE.md` template and extract:**
```
FROM kernel/CLAUDE.md (the distributable template):
- Philosophy section (CORRECTNESS > SPEED, etc.)
- LSP-First Navigation section
- Memory Protocol section
- Quality Gates section
- Session Protocol section
- Permissions section
- Self-Evolution section
- GitHub Workflow section
- Configuration Layers section
```

**Also reference the plugin root CLAUDE.md for latest methodology and agent patterns.**

**Fill in project-specific data:**
```
- PROJECT_NAME: from package.json/pyproject.toml/directory name
- ONE_LINE_DESCRIPTION: from README or ask
- STACK_SUMMARY: detected stack
- ARCHITECTURE_OVERVIEW: from analysis
- ENTRY_POINTS: discovered entry points
- DISCOVERED_CONVENTIONS: top 5-7 patterns
- TEST_COMMAND: detected or ask
- TYPE_COMMAND: detected or ask
- LINT_COMMAND: detected or ask
- SECURITY_COMMAND: based on stack
- BRANCH_PREFIX: feature | feat | fix based on existing branches
```

**Result:** Standalone CLAUDE.md with KERNEL principles + project-specific details.

### 3.3 Generate settings.json

**Based on stack:**

**Node.js:**
```json
{
  "hooks": {
    "postSave": ["npm run lint:fix"],
    "preCommit": ["npm test", "npm run lint"]
  }
}
```

**Python:**
```json
{
  "hooks": {
    "postSave": ["black {file}", "ruff check {file} --fix"],
    "preCommit": ["pytest", "mypy ."]
  }
}
```

**Rust:**
```json
{
  "hooks": {
    "postSave": ["cargo fmt"],
    "preCommit": ["cargo test", "cargo clippy"]
  }
}
```

### 3.4 Generate GitHub Actions (if requested)

**Customize based on stack:**
- CI workflow with correct commands
- Security scanning with right audit tools
- PR template

---

## Phase 4: Vision Mode (Empty Repos)

### 4.1 Read Vision Document

**Look for:**
```
vision.md | VISION.md | blueprint.md | BLUEPRINT.md | README.md
```

**Extract:**
- Project name
- Description
- Goals/features
- Technical decisions (if specified)
- Constraints

### 4.2 Ask Clarifying Questions

**If vision unclear, ask:**
```
1. What type of project? (API, web app, CLI, library)
2. Primary language/stack?
3. Any specific frameworks required?
4. External services needed?
5. Deployment target?
```

### 4.3 Generate Scaffold

**Based on answers:**
```
1. Create recommended directory structure
2. Generate starter files (package.json, etc.)
3. Create CLAUDE.md with vision encoded
4. Set up _memory/ with planned architecture
5. Create _meta/ ready for work
```

---

## Phase 5: Validation

### 5.1 Sanity Checks

```
1. CLAUDE.md is < 200 lines (lean check)
2. All template variables filled (no {PLACEHOLDER} remains)
3. Commands in CLAUDE.md are valid for this stack
4. _memory/ files have real content, not just templates
5. No sensitive data exposed
```

### 5.2 Test Configuration

**Quick test:**
```
"Describe this codebase in 3 sentences."
→ Response should match reality
→ If hallucinations, _memory/ needs more detail
```

---

## Phase 6: Report

```
repo-init complete for {PROJECT_NAME}

Detected:
  Stack: {STACK}
  Files: {FILE_COUNT}
  Complexity: {LOW|MEDIUM|HIGH}

Created:
  .claude/CLAUDE.md      — {LINES} lines, project intelligence
  .claude/settings.json  — {HOOK_COUNT} hooks configured
  _meta/                 — Session state tracking
  _memory/               — {FILE_COUNT} knowledge files
  [.github/]             — CI/security workflows (if enabled)

Analysis:
  Entry points: {LIST}
  Key patterns: {LIST}
  Hotspots: {COUNT} complex areas identified

Recommendations:
  {RECOMMENDATIONS}

Next steps:
  1. Review .claude/CLAUDE.md for accuracy
  2. Review _memory/architecture.md for completeness
  3. Start working - configuration is active
  4. Run /validate before first commit
```

---

## Stack-Specific Configurations

### Node.js / TypeScript

```yaml
test_command: "npm test"
type_command: "npx tsc --noEmit"
lint_command: "npm run lint"
security_command: "npm audit"
coverage_command: "npm run test:coverage"
```

**Additional _memory/ entries:**
- Component patterns (if React/Vue)
- API route patterns (if Next.js/Express)
- State management patterns

### Python

```yaml
test_command: "pytest"
type_command: "mypy ."
lint_command: "ruff check ."
security_command: "pip-audit"
coverage_command: "pytest --cov"
```

**Additional _memory/ entries:**
- Async patterns (if FastAPI/asyncio)
- Model patterns (if Django/SQLAlchemy)

### Rust

```yaml
test_command: "cargo test"
type_command: "cargo check"
lint_command: "cargo clippy"
security_command: "cargo audit"
coverage_command: "cargo tarpaulin"
```

### Go

```yaml
test_command: "go test ./..."
type_command: "go vet ./..."
lint_command: "golangci-lint run"
security_command: "govulncheck ./..."
coverage_command: "go test -cover ./..."
```

---

## Flags

```
--full          Include GitHub Actions (default: skip)
--minimal       Only .claude/CLAUDE.md and _meta/ (skip _memory/ generation)
--force         Overwrite existing config without asking
--analyze-only  Run analysis, output to stdout, don't create files
--vision FILE   Use specific file as vision document
```

---

## Anti-Patterns

- **DON'T create bloated CLAUDE.md** — Target ~150 lines, max 200
- **DON'T leave template variables** — Every {PLACEHOLDER} must be filled
- **DON'T generate empty _memory/** — If analysis found nothing, note that explicitly
- **DON'T assume stack** — Detect or ask
- **DON'T include secrets** — Even in examples

---

## Philosophy (Derived from KERNEL Plugin)

The generated KERNEL-REPO inherits these principles from the KERNEL plugin's `CLAUDE.md`:

```
CORRECTNESS > SPEED
→ Quality gates block bad code

EVERY LINE IS LIABILITY
→ Config > code. Native > custom. Existing > new.

INVESTIGATE BEFORE IMPLEMENT
→ _memory/ protocol requires checking first

LSP-FIRST NAVIGATION
→ Explicit instruction to use tools, not guess

PROTECT STATE
→ Backup before mutation. Confirm before deletion.

FAIL FAST
→ Security and test gates are non-negotiable

SELF-EVOLUTION
→ _meta/_learnings.md captures patterns
```

**These are extracted from the KERNEL plugin at runtime, not hardcoded.**
**Update the plugin's CLAUDE.md → repo-init output automatically reflects changes.**

---

## Example Output: Node.js API

```
repo-init complete for payment-service

Detected:
  Stack: TypeScript, Express, PostgreSQL, Stripe
  Files: 847
  Complexity: HIGH

Created:
  .claude/CLAUDE.md      — 142 lines
  .claude/settings.json  — 3 hooks (lint, test, typecheck)
  _meta/                 — Ready for session tracking
  _memory/               — 6 knowledge files
  .github/               — CI + security workflows

Analysis:
  Entry points: src/index.ts, src/worker.ts
  Key patterns: Service classes, repository pattern, middleware chain
  Hotspots: 4 complex areas (payment processing, webhook handling)

Recommendations:
  - src/services/payment.ts needs more test coverage (43%)
  - Consider splitting src/routes/api.ts (892 lines)
  - Missing error tracking integration

Next steps:
  1. Review .claude/CLAUDE.md
  2. Check _memory/hotspots.md for risk areas
  3. Consider adding Sentry for error tracking
```
