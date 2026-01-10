# KERNEL Plugin Project

TIER: 2
STACK: Python, Markdown, MCP Protocol
DOMAIN: Plugin/Tool (Claude Code Extension Framework)

---

## CODING RULES

### Core Philosophy

```
PARSE, DON'T READ
Treat user requests as objects to decompose programmatically.
Extract: goal, constraints, inputs, outputs, dependencies.

CORRECTNESS > SPEED
Working first attempt beats fast iteration + debug cycles.
Mental simulation catches 80% of bugs before execution.

EVERY LINE IS LIABILITY
Config > code. Native > custom. Existing > new.
Delete code that doesn't earn its place.

CONTEXT IS SCARCE
Lean context prevents rot.
Reference, don't restate.
Compress aggressively.
```

### Execution Laws

```
LAW: INVESTIGATE FIRST
NEVER implement first.
1. Find working example (search, grep, docs)
2. Read every line
3. Copy pattern exactly
4. Adapt minimally

LAW: SINGLE SOURCE OF TRUTH
One location for each concern.
- Config: one file
- Types: one definition
- Validation: one schema

LAW: FAIL FAST
Exit early. Clear messages. No silent failures.
If uncertain: STOP → ASK → WAIT.
```

### Validation Protocol

```
PRE-WRITE:
- [ ] State what, why, dependencies
- [ ] Interfaces defined (inputs/outputs/errors)
- [ ] Done-when criteria explicit
- [ ] Working pattern found

PRE-COMMIT:
- [ ] Matches spec exactly? Nothing more?
- [ ] Connects to adjacent components?
- [ ] 3 edge cases confirmed?
- [ ] Types correct?
```

### Testing Requirements (T2)

```
- [ ] Unit: all components
- [ ] Integration: critical paths
- [ ] Edge: nulls, empty, bounds
- [ ] Error: failures handled
```

### Anti-Patterns

```
AVOID:
- Raw magic values (use constants/config)
- Deprecated syntax
- Console.log in commits
- Duplicating existing components
- Assuming function signatures
- Silent failures
- Fighting framework conventions
```

---

## PROJECT CONSTRAINTS

- MCP servers must follow the MCP protocol specification
- Configuration files use JSON format
- Agent/command definitions use YAML frontmatter in Markdown
- Python code should handle stdin/stdout for MCP communication

---

## KERNEL: Self-Evolving Configuration

KERNEL progressively builds Claude Code config based on observed patterns.

### Pattern → Artifact Mapping

| When You Notice... | Create This |
|-------------------|-------------|
| Same multi-step workflow repeated 2+ times | `.claude/commands/workflow-name.md` |
| Task needing specialized expertise | `.claude/agents/specialist-name.md` |
| External service integration needed | Entry in `.mcp.json` |
| Pre/post processing on tool usage | Hook in `.claude/settings.json` |
| Domain capability used repeatedly | `.claude/skills/capability.md` |
| User states explicit preference | `.claude/rules/topic.md` |

### Artifact Templates

**COMMAND** (`.claude/commands/name.md`):
```md
---
description: One-line description
allowed-tools: Read, Write, Bash
---
Instructions for Claude when /name is invoked.
```

**AGENT** (`.claude/agents/name.md`):
```md
---
name: agent-name
description: Specialization
tools: Read, Write, Grep, Glob, Bash
model: sonnet
---
You are a specialist in X...
```

**MCP** (`.mcp.json`): `{"mcpServers": {"name": {"command": "npx", "args": ["pkg"]}}}`

**HOOK** (`.claude/settings.json`): `{"hooks": {"PostToolUse": [...]}}`

**SKILL** (`.claude/skills/name.md`): Capability description + examples

**RULE** (`.claude/rules/topic.md`): Imperative rules grouped by topic

### Before Completing Tasks

1. Workflow repeated? → Command
2. Specialized expertise? → Agent
3. External service? → MCP config
4. Pre/post processing? → Hook
5. Explicit preference? → Rule

### Guidelines

- Conservative: Clear, repeated patterns only
- Minimal: Start simple
- Ask first: Confirm if unsure
- Check existing: Avoid duplicates
