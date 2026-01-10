# KERNEL Usage Simulation

This document captures a realistic user interaction flow that would trigger KERNEL artifact creation.

---

## Session 1: Initial Development

**USER**: Add export functionality to export tasks to CSV

**CLAUDE**: [Implements export_to_csv method]

**USER**: Great! Can you also add import functionality?

**CLAUDE**: [Implements import_from_csv method]

---

## Session 2: Repeated Workflow (→ COMMAND)

**USER**: Can you optimize the task database by reindexing task IDs and removing gaps?

**CLAUDE**: [Implements optimization logic]

**USER**: [Two days later] Can you run that optimization again?

**CLAUDE**: [Runs same optimization]

**USER**: [Week later] Optimize the database again please

**KERNEL TRIGGER**: User has requested "optimize database" 3+ times
→ **Create command**: `.claude/commands/optimize-db.md`

---

## Session 3: Specialized Analysis (→ AGENT)

**USER**: Analyze my task patterns and tell me which tasks I tend to procrastinate on

**CLAUDE**: [This requires: loading tasks, analyzing completion times vs due dates, identifying patterns, generating insights]

**KERNEL TRIGGER**: Task requires specialized analysis + isolated context
→ **Create agent**: `.claude/agents/task-analyzer.md`

---

## Session 4: Teaching a Pattern (→ SKILL)

**USER**: When displaying dates, use format "Jan 15, 2026" not "2026-01-15"

**CLAUDE**: [Updates date formatting]

**USER**: [Later] The date in the stats output is wrong format again

**CLAUDE**: [Fixes it]

**USER**: Remember: dates should always be "MMM DD, YYYY" format

**KERNEL TRIGGER**: User is teaching a capability Claude should auto-discover
→ **Create skill**: `.claude/skills/date-formatting/SKILL.md`

---

## Session 5: Behavioral Preference (→ RULE)

**USER**: Always use UTC timestamps, not local time

**CLAUDE**: [Updates datetime usage]

**USER**: Also, always include timezone info in ISO format

**CLAUDE**: [Updates to use timezone-aware datetimes]

**KERNEL TRIGGER**: Project-wide behavioral instruction
→ **Create rule**: `.claude/rules/datetime.md`

---

## Session 6: Automatic Action (→ HOOK)

**USER**: Can you make it so tasks.json is automatically backed up whenever it changes?

**CLAUDE**: [Implements backup logic]

**KERNEL TRIGGER**: User wants automatic action on Write events
→ **Create hook**: PostWrite hook in `.claude/settings.json`

---

## Session 7: External Service (→ MCP)

**USER**: I want to store tasks in PostgreSQL instead of JSON

**CLAUDE**: [Sets up database connection]

**KERNEL TRIGGER**: External service integration needed
→ **Create MCP entry**: `.mcp.json` with database server

---

## Resulting KERNEL Configuration

After these interactions, KERNEL would have created:

- **Commands**: optimize-db, export-tasks
- **Agents**: task-analyzer
- **Skills**: date-formatting
- **Rules**: datetime.md, python-style.md
- **Hooks**: PostWrite backup
- **MCP**: postgres-server

**Registry entries**: 8 artifacts tracked with creation and usage timestamps
