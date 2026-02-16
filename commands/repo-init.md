---
description: Analyze codebase and generate context - no templates, just intelligence
allowed-tools: Read, Bash, Glob, Grep, Task, AskUserQuestion
---

# repo-init

**Analyze codebase and bootstrap context. No templates - the plugin IS the config.**

---

## What It Does

1. Detect stack (language, framework, tools)
2. Map architecture (entry points, patterns, hotspots)
3. Create `_meta/` for session tracking
4. Output findings - you're ready to work

---

## Phase 1: Detection

### Stack Detection
```
package.json       → Node.js (check for Next.js, React, etc.)
requirements.txt   → Python
pyproject.toml     → Python (modern)
Cargo.toml         → Rust
go.mod             → Go
pom.xml            → Java
```

**Extract:**
- Primary language
- Framework
- Test framework
- Lint/format tools
- Build system

---

## Phase 2: Analysis

### Structure
1. Directory tree (depth 3)
2. Count files by type
3. Identify entry points
4. Identify config files
5. Identify test directories

### Patterns
1. File naming convention
2. Error handling patterns
3. Test patterns
4. Import organization

### Hotspots
1. Large files (complexity indicators)
2. Most changed files (if git history available)

---

## Phase 3: Bootstrap

### Create _meta/
```
_meta/
├── context/
│   └── active.md      # Current session state
└── _learnings.md      # Pattern log
```

### Output Report
```
Detected:
  Stack: {STACK}
  Files: {COUNT}

Entry points: {LIST}
Key patterns: {LIST}
Hotspots: {COUNT} areas

Ready to work. Plugin provides agents, rules, banks.
```

---

## Usage

```
/repo-init              # Analyze current directory
/repo-init --minimal    # Just create _meta/, skip analysis
```

---

## Philosophy

The plugin IS the configuration. No templates to copy. No project-specific CLAUDE.md to generate.

Just analyze, understand, and start working.
