---
name: context
description: "Context engineering and token management. Compaction strategies, progressive disclosure, structured note-taking via AgentDB. Triggers: context, tokens, compaction, memory, handoff, summarize, context window."
allowed-tools: Read, Bash, Task
---

<skill id="context">

<purpose>
Context is finite. Every token competes for attention.
Longer context makes things WORSE (30%+ accuracy drop for middle info).
Progressive disclosure: load what's needed when it's needed.
</purpose>

<prerequisite>
Monitor context usage. Offer handoff proactively at ~70% capacity.
</prerequisite>

<reference>
Skill-specific: skills/context/reference/context-research.md
</reference>

<core_principles>
1. COMPACTION: Summarize and reinitialize. Keep architecture decisions, discard noise.
2. STRUCTURED NOTES: AgentDB + active.md persist across context resets.
3. MULTI-AGENT: Delegate research to subagents. They explore, report summaries.
4. MINIMAL READS: grep/glob to find, then read specific sections.
5. TOOL RESULT CLEARING: Old tool output rarely needs to stay in context.
</core_principles>

<token_budget>
- CLAUDE.md: <150 lines (always loaded)
- rules/: <100 lines (always loaded)
- Skills: metadata only at startup, full content on demand
- Commands: only when invoked
- Reference docs: only when skill explicitly reads them
</token_budget>

<compaction_protocol>
Before compaction:
1. Write critical state to AgentDB
2. Commit any uncommitted changes
3. Generate handoff if complex work in progress

After compaction:
1. Read active.md for project context
2. Run agentdb read-start for failures, patterns, contracts
3. Check for pending checkpoints to review
</compaction_protocol>

<failure_modes>
1. Agent tries too much at once → context exhausted mid-work
   Fix: Incremental progress with commits at each step

2. Later agent assumes done prematurely → work incomplete
   Fix: Explicit done-when criteria with evidence required
</failure_modes>

</skill>
