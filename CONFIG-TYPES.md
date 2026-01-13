# Claude Code Configuration Types: Complete Reference

**CRITICAL**: This guide defines WHEN to use each config type. Read this BEFORE creating any KERNEL artifacts.

---

## Decision Tree (Start Here)

```
Is this...?
│
├─ A TASK that needs DELEGATION to a specialist?
│  └─→ AGENT (.claude/agents/name.md)
│     Example: Code reviewer, test runner, debugger
│     Key: Runs in ISOLATED CONTEXT
│
├─ TEACHING Claude HOW to do something?
│  └─→ SKILL (.claude/skills/name/SKILL.md)
│     Example: "How to review PRs", "How to write commit messages"
│     Key: Claude AUTO-DISCOVERS based on context
│
├─ A MANUAL PROMPT you invoke explicitly?
│  └─→ COMMAND (.claude/commands/name.md)
│     Example: /optimize, /explain, /fix-lint
│     Key: You control WHEN it runs via /command-name
│
├─ AUTOMATED trigger (before/after tool use)?
│  └─→ HOOK (.claude/settings.json)
│     Example: Run prettier after file write, validate before commit
│     Key: EVENT-DRIVEN automation
│
├─ GENERAL BEHAVIOR you want from Claude?
│  ├─ Applies to ALL tasks in project?
│  │  └─→ CLAUDE.md
│  │     Example: "All code uses TypeScript strict mode"
│  │     Key: PROJECT CONSTITUTION
│  │
│  └─ Specific to a topic/path/domain?
│     └─→ RULE (.claude/rules/topic.md)
│        Example: Testing conventions, frontend patterns
│        Key: MODULAR INSTRUCTIONS
│
└─ EXTERNAL SERVICE integration?
   └─→ MCP (.mcp.json)
      Example: Database, API, tool server
      Key: MCP SERVER REGISTRATION
```

---

## Configuration Type Comparison Table

| Type | Invocation | Context | When to Use | Real Example |
|------|-----------|---------|-------------|--------------|
| **AGENT** | Auto-delegated OR explicit | Isolated | Task needs specialist + separate context | `tech-debt-scanner` - scans before feature work |
| **SKILL** | Auto-discovered | Main | Teach Claude how to do something | "PR Review Standards" - guides review process |
| **COMMAND** | Manual (`/name`) | Main | Reusable prompt you invoke | `/optimize` - run optimization workflow |
| **RULE** | Auto-loaded | Main | Behavioral instructions | `assumptions.md` - extract before executing |
| **CLAUDE.md** | Auto-loaded | Main | Project-wide standards | "Use 2-space tabs", "TIER: 2" |
| **HOOK** | Event-driven | Main | Pre/post tool automation | Run linter after file write |
| **MCP** | Auto-loaded | System | External service integration | Database connection, API server |

---

## Detailed Specifications

### AGENT (`.claude/agents/name.md`)

**Purpose**: Delegate complex tasks to a specialist that runs independently

**Structure**:
```markdown
---
name: agent-name
description: What this agent specializes in (used for auto-delegation)
tools: Read, Write, Grep, Glob, Bash
model: sonnet
---

You are a specialist in [domain].

Your job is to [specific task].

[Detailed instructions for the agent...]
```

**When to Create**:
- ✅ Task requires specialized expertise (security scanning, test running, code review)
- ✅ Task is complex and multi-step
- ✅ Task benefits from isolated context (doesn't pollute main conversation)
- ✅ You want Claude to auto-delegate based on task description

**When NOT to Create**:
- ❌ Simple instructions that don't need isolation
- ❌ General behavioral guidelines (use RULE instead)
- ❌ Manual prompts you invoke (use COMMAND instead)

**Examples**:
- `tech-debt-scanner` - scans codebase for refactoring opportunities before feature work
- `test-runner` - runs tests, analyzes failures, suggests fixes
- `security-auditor` - checks code for vulnerabilities

**Key Trait**: Runs in **separate conversation context**, preserving main context tokens

---

### SKILL (`.claude/skills/name/SKILL.md`)

**Purpose**: Teach Claude how to perform a specific capability

**Structure**:
```
.claude/skills/
└── pr-review/
    ├── SKILL.md          # Main skill definition
    └── checklist.md      # Supporting resources (optional)
```

**SKILL.md format**:
```markdown
---
name: pr-review
description: PR review standards and process
---

# PR Review Skill

When reviewing pull requests, follow this process:

1. Check code quality
2. Verify tests
3. Review security
...

## Examples
[Show examples of good reviews]
```

**When to Create**:
- ✅ Claude needs to know HOW to do something specific
- ✅ Knowledge is reusable across multiple tasks
- ✅ You want Claude to auto-discover based on context
- ✅ Capability has examples/templates/checklists

**When NOT to Create**:
- ❌ Task needs delegation (use AGENT instead)
- ❌ Manual invocation (use COMMAND instead)
- ❌ General rules (use RULE instead)

**Examples**:
- `commit-messages` - how to write good commit messages
- `pr-review` - how to review pull requests
- `api-design` - how to design REST APIs

**Key Trait**: Claude **discovers automatically** when context matches description

---

### COMMAND (`.claude/commands/name.md`)

**Purpose**: Reusable prompts you invoke manually

**Structure**:
```markdown
---
description: One-line description
allowed-tools: Read, Write, Bash, Grep, Glob
---

When user invokes /name, do this:

1. [Step by step instructions]
2. ...
```

**When to Create**:
- ✅ Workflow is repeated 2+ times
- ✅ You want MANUAL control over when it runs
- ✅ Simple, focused prompt (not complex delegation)
- ✅ Self-contained workflow

**When NOT to Create**:
- ❌ Needs automatic triggering (use HOOK instead)
- ❌ Complex task needing isolation (use AGENT instead)
- ❌ General behavioral rule (use RULE instead)

**Examples**:
- `/optimize` - run optimization workflow
- `/explain` - explain codebase architecture
- `/fix-lint` - fix all linting errors

**Key Trait**: YOU invoke with `/command-name`

---

### RULE (`.claude/rules/topic.md`)

**Purpose**: Modular behavioral instructions for specific topics/paths

**Structure**:
```markdown
---
paths: "**/*"              # Or specific paths: "src/frontend/**"
---

# Rule Topic

[Imperative instructions Claude should follow]

## When This Applies

[Context about when this rule is relevant]

## Examples

[Show good/bad examples]
```

**When to Create**:
- ✅ Behavioral instruction for Claude
- ✅ Applies to specific domain/path/language
- ✅ User expresses explicit preference
- ✅ You want modular organization (not monolithic CLAUDE.md)

**When NOT to Create**:
- ❌ Applies to ALL project code (use CLAUDE.md instead)
- ❌ Teaching how to do something (use SKILL instead)
- ❌ Task delegation (use AGENT instead)

**Examples**:
- `assumptions.md` - extract assumptions before executing
- `testing.md` - testing conventions for this project
- `typescript.md` - TypeScript-specific coding standards
- `frontend/react.md` - React component patterns (path-specific)

**Key Trait**: Auto-loaded, **modular topic-based instructions**

---

### CLAUDE.md

**Purpose**: Project constitution - fundamental rules for ALL code

**Structure**:
```markdown
# [PROJECT NAME]

TIER: [1-3]
STACK: [Primary tech stack]
DOMAIN: [api/cli/library/app]

---

## CODING RULES

[Core philosophy, execution laws, validation protocols]

---

## PROJECT CONSTRAINTS

[Technology constraints, architectural decisions]

---

## KERNEL: Self-Evolving Configuration

[Pattern → Artifact mapping, guidelines]
```

**When to Create/Update**:
- ✅ During `/kernel-init`
- ✅ Fundamental project-wide rule changes
- ✅ Stack/tier/domain changes

**What Belongs Here**:
- ✅ Tier, stack, domain metadata
- ✅ Core coding philosophy (CORRECTNESS > SPEED, etc.)
- ✅ Project-wide constraints (tech stack, frameworks)
- ✅ KERNEL artifact creation rules

**What Does NOT Belong**:
- ❌ Topic-specific rules (use `.claude/rules/` instead)
- ❌ Task delegation (use AGENT)
- ❌ Reusable prompts (use COMMAND)

**Key Trait**: **Single source of truth** for project fundamentals

---

### HOOK (`.claude/settings.json`)

**Purpose**: Event-driven automation on tool usage

**Structure**:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "prettier --write {{file_path}}"
          }
        ]
      }
    ],
    "PreToolUse": [...],
    "UserPromptSubmit": [...]
  }
}
```

**When to Create**:
- ✅ Automatic linting after file write
- ✅ Validation before commits
- ✅ Logging/notifications on events
- ✅ Pre-processing inputs

**When NOT to Create**:
- ❌ Manual invocation (use COMMAND)
- ❌ Behavioral instructions (use RULE)
- ❌ Complex task delegation (use AGENT)

**Examples**:
- Run prettier after Write
- Validate schema before Bash commit
- Log session events to file

**Key Trait**: **Triggered by events**, not manual invocation

---

### MCP (`.mcp.json`)

**Purpose**: Register external MCP servers for tool integration

**Structure**:
```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@package/server"]
    }
  }
}
```

**When to Create**:
- ✅ Need to integrate external service (database, API)
- ✅ Tool server provides capabilities Claude needs
- ✅ Custom MCP server for project-specific tools

**Examples**:
- Database server for SQL queries
- Filesystem server for advanced file operations
- Custom API server for domain tools

**Key Trait**: **External service** integration via MCP protocol

---

## Common Confusion Scenarios

### "Should this be an AGENT or a SKILL?"

| Scenario | Use... | Reason |
|----------|--------|--------|
| "Teach Claude our PR review checklist" | SKILL | Teaching HOW, not delegating TASK |
| "Review this PR for me" | AGENT | Task delegation, needs isolation |
| "Learn our commit message format" | SKILL | Teaching HOW to format |
| "Generate a commit message" | COMMAND or AGENT | Task execution (AGENT if complex, COMMAND if simple) |

**Rule of thumb**:
- SKILL = "Here's HOW to do X"
- AGENT = "DO X for me"

### "Should this be a RULE or part of CLAUDE.md?"

| Scenario | Use... | Reason |
|----------|--------|--------|
| "Always use TypeScript strict mode" | CLAUDE.md | Project-wide fundamental |
| "Extract assumptions before executing" | RULE | Behavioral process, modular |
| "React components must use hooks" | RULE (rules/frontend.md) | Domain-specific, path-specific |
| "TIER: 2, STACK: Python/FastAPI" | CLAUDE.md | Project metadata |

**Rule of thumb**:
- CLAUDE.md = Fundamentals, metadata, constitution
- RULE = Modular, topic/path-specific, organized by concern

### "Should this be a COMMAND or a HOOK?"

| Scenario | Use... | Reason |
|----------|--------|--------|
| "Run linter when I ask" | COMMAND | Manual invocation |
| "Run linter after every file write" | HOOK | Automatic on event |
| "Optimize code when I say /optimize" | COMMAND | Explicit control |
| "Validate JSON before committing" | HOOK | Pre-commit event |

**Rule of thumb**:
- COMMAND = Manual, YOU decide when
- HOOK = Automatic, EVENT decides when

---

## KERNEL Pattern Recognition

When observing patterns during work, ask:

1. **Is this a REPEATED WORKFLOW?**
   - Yes, manual invoke → COMMAND
   - Yes, auto-trigger → HOOK or AGENT

2. **Is this SPECIALIZED EXPERTISE?**
   - Yes, needs isolation → AGENT
   - Yes, teaching only → SKILL

3. **Is this a USER PREFERENCE?**
   - Yes, project-wide → CLAUDE.md
   - Yes, topic-specific → RULE

4. **Is this EXTERNAL INTEGRATION?**
   - Yes → MCP

---

## Anti-Patterns (DO NOT DO THIS)

❌ **Creating an AGENT for simple instructions**
```markdown
# BAD: .claude/agents/use-tabs.md
---
name: use-tabs
description: Enforces tab usage
---
Always use tabs instead of spaces.
```
✅ **Use CLAUDE.md or RULE instead** - this is a simple instruction, not a delegated task

---

❌ **Creating a SKILL for task delegation**
```markdown
# BAD: .claude/skills/code-reviewer/SKILL.md
Review pull requests and provide feedback.
```
✅ **Use AGENT instead** - this is task delegation, not teaching

---

❌ **Creating a COMMAND for automatic behavior**
```markdown
# BAD: .claude/commands/extract-assumptions.md
Before executing any task, extract assumptions.
```
✅ **Use RULE instead** - this is behavioral instruction, not manual prompt

---

❌ **Duplicating content across types**
```markdown
# BAD: Same content in CLAUDE.md AND .claude/rules/testing.md
```
✅ **Single source of truth** - choose ONE location per concern

---

## Quick Reference Cheatsheet

| I want Claude to... | Create... | Example |
|---------------------|-----------|---------|
| Auto-delegate tasks to specialist | AGENT | tech-debt-scanner |
| Learn how to do something | SKILL | pr-review-standards |
| Run workflow when I say `/name` | COMMAND | /optimize |
| Auto-run on file write/commit/etc | HOOK | prettier on write |
| Follow rule on all tasks | CLAUDE.md or RULE | assumptions.md |
| Connect to external service | MCP | database server |

---

## Validation Checklist

Before creating ANY KERNEL artifact, check:

- [ ] Is there an EXISTING artifact that does this? (avoid duplicates)
- [ ] Have I chosen the RIGHT type per this guide?
- [ ] Is the pattern CLEAR and REPEATED (not one-off)?
- [ ] Have I checked the ANTI-PATTERNS section?
- [ ] Do I understand WHEN this will trigger/apply?

---

## References

- Claude Code documentation: [claude.ai/claude-code](https://claude.ai/claude-code)
- MCP specification: [modelcontextprotocol.io](https://modelcontextprotocol.io)
- This plugin: `/kernel-init` for setup, `/kernel-status` for health check

---

**Last Updated**: 2026-01-09
**Status**: Canonical reference for KERNEL artifact creation
