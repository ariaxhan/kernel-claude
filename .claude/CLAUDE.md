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

**CRITICAL**: See CONFIG-TYPES.md for FULL decision tree and distinctions between artifact types.

### Pattern → Artifact Mapping

**DECISION TREE** (Use this to choose the right artifact type):

1. **Is this a TASK that needs DELEGATION?**
   - Requires specialized expertise + isolated context?
   - → `.claude/agents/specialist-name.md`
   - Example: tech-debt-scanner, test-runner, security-auditor

2. **Is this TEACHING Claude HOW to do something?**
   - Claude needs to learn a capability/process?
   - Claude should auto-discover based on context?
   - → `.claude/skills/name/SKILL.md`
   - Example: pr-review-standards, commit-message-format, worktree-parallelization

3. **Is this a MANUAL WORKFLOW you invoke?**
   - Repeated 2+ times, you control when it runs?
   - → `.claude/commands/workflow-name.md`
   - Example: /optimize, /explain, /fix-lint, /parallelize

4. **Is this AUTOMATIC on events?**
   - Pre/post tool usage processing?
   - → Hook in `.claude/settings.json`
   - Example: Run prettier after Write, validate before commit

5. **Is this GENERAL BEHAVIOR instruction?**
   - Project-wide fundamental? → Stay in CLAUDE.md
   - Topic/path-specific? → `.claude/rules/topic.md`
   - Example: assumptions.md, testing.md, typescript.md

6. **Is this EXTERNAL SERVICE integration?**
   - → Entry in `.mcp.json`
   - Example: Database server, API server

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

### Critical Distinctions (Read CONFIG-TYPES.md for full details)

**What each artifact type is for**:
- **AGENT**: Task delegation (runs in isolated context)
- **SKILL**: Teaching Claude HOW (auto-discovered)
- **COMMAND**: Manual prompt (you invoke with /name)
- **RULE**: Behavioral instruction (modular, topic-specific)
- **CLAUDE.md**: Project fundamentals (global constitution)
- **HOOK**: Event automation (pre/post tool usage)
- **MCP**: External service integration

### Before Creating ANY Artifact

**STOP and check CONFIG-TYPES.md first.**

Quick validation:
1. Does this already exist? (check existing config)
2. Is this the RIGHT artifact type? (see CONFIG-TYPES.md decision tree)
3. Is the pattern CLEAR and REPEATED? (not one-off)
4. Have I avoided anti-patterns? (CONFIG-TYPES.md lists them)

### Guidelines

- **Read CONFIG-TYPES.md BEFORE creating artifacts** (MANDATORY)
- Conservative: Clear, repeated patterns only
- Minimal: Start simple, expand as needed
- Ask first: Confirm if unsure about type/necessity
- Check existing: Avoid duplicates (SINGLE SOURCE OF TRUTH)
- Validate: Use decision tree, not intuition

### Config Lifecycle: Track & Prune

KERNEL tracks config usage to identify stale entries.

**Registry** (`memory/config_registry.jsonl`):
```json
{"type": "command", "name": "lint", "created": "2025-01-01T00:00:00Z", "last_referenced": "2025-01-09T00:00:00Z", "reference_count": 12}
```

**When you reference existing config** (invoke a command, use a skill, apply a rule):
1. Check if entry exists in registry
2. If exists: update `last_referenced` timestamp, increment `reference_count`
3. If missing: add entry with current timestamp (bootstrap from existing config)

**Remove Actions** - When pruning is appropriate:
```json
{"action": "remove_command", "target": "command-name", "reason": "No references in 30+ sessions"}
{"action": "remove_skill", "target": "skill-name", "reason": "Superseded by native feature"}
{"action": "remove_from_claude_md", "target": "Section Name", "reason": "No longer relevant to project"}
{"action": "remove_rule", "target": "rule-file.md", "reason": "Preference changed"}
{"action": "remove_agent", "target": "agent-name", "reason": "Never invoked"}
```

**Pruning Rules**:
- NEVER auto-delete; always prompt user for confirmation
- Flag entries with zero references after 30 sessions
- Run `/kernel:status` to see config health
- Run `/kernel:prune` to review stale entries
