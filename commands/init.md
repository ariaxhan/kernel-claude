---
name: kernel:init
description: "Initialize KERNEL for a project. Audits codebase, creates _meta, AgentDB, CLAUDE.md, and rules. Run once per project."
user-invocable: true
allowed-tools: Read, Write, Bash, Grep, Glob
---

# FULL PROJECT INITIALIZATION

**Do everything automatically. Audit the project, detect patterns, create everything.**

---

## PHASE 1: Create Structure

```bash
mkdir -p _meta/{agentdb,context,plans,research,handoffs,reviews,agents}
mkdir -p .claude/rules
```

---

## PHASE 2: Initialize AgentDB

```bash
sqlite3 _meta/agentdb/agent.db "
PRAGMA journal_mode=WAL;
CREATE TABLE IF NOT EXISTS learnings (
  id TEXT PRIMARY KEY,
  ts TEXT DEFAULT CURRENT_TIMESTAMP,
  type TEXT CHECK(type IN ('failure','pattern','gotcha','preference')),
  insight TEXT NOT NULL,
  evidence TEXT,
  domain TEXT,
  hit_count INTEGER DEFAULT 0
);
CREATE TABLE IF NOT EXISTS context (
  id TEXT PRIMARY KEY,
  ts TEXT DEFAULT CURRENT_TIMESTAMP,
  type TEXT CHECK(type IN ('contract','checkpoint','handoff','verdict')),
  contract_id TEXT,
  agent TEXT,
  content TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS errors (
  id INTEGER PRIMARY KEY,
  ts TEXT DEFAULT CURRENT_TIMESTAMP,
  tool TEXT,
  error TEXT,
  file TEXT
);
CREATE INDEX IF NOT EXISTS idx_learnings_type ON learnings(type);
CREATE INDEX IF NOT EXISTS idx_context_type ON context(type);
"
```

---

## PHASE 3: Audit Project

**Detect everything about this project. Run these searches:**

### Tech Stack Detection
```bash
# Check for package managers and languages
ls -la package.json requirements.txt pyproject.toml go.mod Cargo.toml Gemfile composer.json pom.xml build.gradle 2>/dev/null
```

### Framework Detection
```bash
# Look for framework indicators
grep -l "next\|react\|vue\|angular\|svelte" package.json 2>/dev/null
grep -l "fastapi\|flask\|django\|express\|nestjs" package.json requirements.txt 2>/dev/null
```

### Project Structure
```bash
# Map top-level directories
ls -d */ 2>/dev/null | head -20
```

### Existing Conventions
```bash
# Check for existing config files
ls -la .eslintrc* .prettierrc* tsconfig.json .editorconfig pyproject.toml 2>/dev/null
```

### Git Info
```bash
git remote -v 2>/dev/null | head -2
git log --oneline -5 2>/dev/null
```

**Read key files to understand the project:**
- README.md (if exists)
- package.json (if exists)
- Any existing .claude/CLAUDE.md

---

## PHASE 4: Create .claude/CLAUDE.md

Based on your audit, create `.claude/CLAUDE.md` with DETECTED information:

```markdown
# {Project Name from package.json or folder name}

## Tech Stack
{List detected technologies - be specific}
- Language: {detected}
- Framework: {detected}
- Package manager: {detected}
- Database: {detected if found}

## Project Structure
{Describe the directory structure you found}

## KERNEL Integration

**Always start with `/ingest`** (or `/kernel:ingest` in terminal)

Routing:
- Tier 1 (1-2 files): Execute directly
- Tier 2 (3-5 files): Spawn surgeon agent
- Tier 3 (6+ files): Surgeon + adversary

**Run `/handoff` before closing** to save progress.

## Conventions
{Detected from eslint, prettier, editorconfig, or inferred from code}

## Commands

| Command | What It Does |
|---------|--------------|
| `/ingest` | Start any task |
| `/validate` | Pre-commit checks |
| `/handoff` | Save progress |
```

---

## PHASE 5: Create Rules

Based on audit, create `.claude/rules/project.md`:

```markdown
# Project Rules

## Tech Stack
- {specific rules based on detected stack}

## File Organization
- {rules based on detected structure}

## Code Style
- {rules based on detected linters/formatters}

## Testing
- {rules based on detected test framework}

## Never Do
- Never commit secrets or .env files
- Never delete _meta/ folder
- {stack-specific warnings}
```

---

## PHASE 6: Seed AgentDB

**Add initial learnings so memory isn't empty:**

```bash
sqlite3 _meta/agentdb/agent.db "
INSERT OR IGNORE INTO learnings (id, type, insight, evidence, domain) VALUES
('init-stack', 'pattern', '{Detected tech stack summary}', 'Detected during init', 'project'),
('init-structure', 'pattern', '{Detected project structure}', 'Detected during init', 'project'),
('init-conventions', 'pattern', '{Detected conventions}', 'Detected during init', 'code-style');
"
```

---

## PHASE 7: Create Context File

Create `_meta/context/active.md`:

```markdown
# {Project Name}

**Initialized**: {current date}
**Tech Stack**: {detected}
**Status**: Ready

## What This Project Is
{Infer from README or package.json description}

## Structure
{Key directories and their purposes}

## Current Focus
Newly initialized - ready for first task.
```

---

# OUTPUT TO USER

After ALL phases complete:

```
✓ KERNEL initialized for {project name}!

Detected:
• Tech stack: {list}
• Framework: {if found}
• Test framework: {if found}
• Linting: {if found}

Created:
• .claude/CLAUDE.md - Project instructions (auto-populated!)
• .claude/rules/project.md - Project-specific rules
• _meta/agentdb/agent.db - Memory (seeded with project info)
• _meta/context/active.md - Current state

AgentDB seeded with:
• Project structure patterns
• Tech stack info
• Detected conventions

Ready to work! Start with /ingest and describe your task.
```
