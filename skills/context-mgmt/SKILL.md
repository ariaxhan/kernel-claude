---
name: kernel:context
description: "Context engineering and token management. Compaction strategies, progressive disclosure, structured note-taking via AgentDB. Triggers: tokens, compaction, memory, handoff, summarize, context window."
allowed-tools: Read, Bash, Task
---

<skill id="context-mgmt">

<purpose>
Context is finite. Every token competes for attention.
Longer context makes things WORSE (30%+ accuracy drop for middle info).
Progressive disclosure: load what's needed when it's needed.

**Reasoning fidelity is the real metric, not token count.** Quality degrades at ~60-70% fill, not at the limit. The agent appears to work normally during degradation; only the output gets shallower.
</purpose>

<prerequisite>
Monitor context usage. **Compact or hand off proactively at ~60% capacity** — not 80%, not at limit.
Use native /context command to check usage. This skill is for methodology.

Why 60%, not 70-80%:
- HF Daily Papers research: solve rate drops 65%→21% when architectural mental model gets evicted from context.
- Fidelity shallowing starts at ~60% fill — the agent still produces output, but stops backtracking, exploring alternatives, or maintaining hypothesis depth.
- By the time native compaction fires (typically near limit), the degraded reasoning has already shipped to code.
- Token count is the lagging indicator. Hypothesis depth and step count are leading indicators.
</prerequisite>

<reference>
Skill-specific: skills/context-mgmt/reference/context-research.md
Architecture: _meta/research/context-graph-architecture.md
Graph tracking: orchestration/agentdb/migrations/002_graph_tracking.sql
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
Trigger compaction at ~60% fill, BEFORE reasoning quality degrades. Do not wait for native auto-compact (too late).

Before compaction:
1. Write critical state to AgentDB
2. Commit any uncommitted changes
3. Generate handoff if complex work in progress

After compaction:
1. Read active.md for project context
2. Run agentdb read-start for failures, patterns, contracts
3. Check for pending checkpoints to review
</compaction_protocol>

<fidelity_health_check>
Don't trust token count alone. Watch for these reasoning-fidelity signals before compaction is even visible as a token problem:

- **Hypothesis depth dropping**: agent stops exploring alternatives, defaults to first idea
- **Backtracking absent**: errors get patched in place rather than root-caused
- **Step count contracting**: multi-step plans collapse to one-shot attempts
- **Cross-file awareness fading**: agent forgets earlier files in the same session
- **Inline checks disappearing**: agent stops verifying assumptions before acting

Any one of these = compact or hand off NOW, even if /context shows <60% fill.
The token meter measures bytes, not thinking.
</fidelity_health_check>

<compaction_strategies>

## Progressive Disclosure
- Start with summary, expand on demand
- Use AgentDB for full context, conversation for highlights
- Pattern: "Details in AgentDB:contracts:{id}" or "See AgentDB:findings:{id}"

## What to Preserve (Never Compact Away)
- Current task context and goal
- Active decisions and their rationale
- Blocking issues and error states
- Recent errors and their resolutions
- File paths currently being worked on
- Uncommitted changes description
- Contract IDs and branch names

## What to Aggressively Compact
- Exploratory searches → "searched X, found Y at path:line"
- File reads → "read file, key insight: Z"
- Successful operations → "completed: X"
- Debugging traces → "root cause: X, fix: Y"
- Tool call history → "N tool calls, outcome: X"
- Research context → offload to AgentDB, keep one-line summary

## Compaction Format
Before: [full exploration, multiple tool calls, iterations, dead ends]
After: "Explored X → Found Y at path/to/file:line → Key insight: Z"

Before: [read 5 files, searched patterns, traced imports]
After: "Traced dependency: A→B→C. Issue in B:42. Fix: add null check."

## AgentDB Offloading Pattern
When context grows heavy:
1. Write detailed findings to AgentDB: `agentdb learn pattern "finding" "evidence"`
2. Keep one-line summary in conversation
3. Reference: "See AgentDB:patterns for full trace"

## Phase Transition Compaction

| Transition | Compact? | Why |
|------------|----------|-----|
| Research → Planning | Yes | Research bulk served its purpose; plan is distilled output |
| Planning → Implementation | Yes | Plan is in contract/file; free context for code |
| Implementation → Testing | Maybe | Keep if tests reference recent code |
| Debugging → Next feature | Yes | Debug traces pollute unrelated work |
| Mid-implementation | No | Losing file paths, variable names, partial state is costly |
| After failed approach | Yes | Clear dead-end reasoning before new approach |

</compaction_strategies>

<failure_modes>
1. Agent tries too much at once → context exhausted mid-work
   Fix: Incremental progress with commits at each step

2. Later agent assumes done prematurely → work incomplete
   Fix: Explicit done-when criteria with evidence required
</failure_modes>

</skill>
