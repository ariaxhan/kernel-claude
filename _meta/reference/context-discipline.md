# Context Discipline

**Type:** invariant | **Load:** on-demand

Manage tokens as a scarce resource. Every token competes for attention. Manage ruthlessly.

---

## Progressive Disclosure

Don't load everything upfront. Load what's needed when it's needed.

- Commands load on invocation
- Skills load on demand
- Rules are always-on

If information isn't needed for the current step, don't read it into context.

---

## Compaction Awareness

- Monitor context usage
- Offer /kernel:handoff proactively at ~70% context
- Before long output, ask: "Can this be 50% shorter?"
- If repeating information from earlier in conversation, reference instead of restating

---

## AgentDB as External Memory

AgentDB is external memory. Use it instead of holding state in context.

- Write decisions, findings, and state to AgentDB immediately
- Read from AgentDB when needed; don't carry everything in conversation

---

## Subagent Delegation

Research tasks consume heavy context (file reads, searches).

- Delegate research to subagents
- They explore in separate context, report back summaries
- Main context stays clean for implementation

---

## File Reading Discipline

- Read only files relevant to current task. Not the whole codebase
- Use grep/glob to find specific content instead of reading entire files
- If a file is large, read only the relevant section

---

## Precise Retrieval

Precise retrieval over excessive searching.

- Before searching: know EXACTLY what you're looking for
- One targeted query beats five exploratory ones
- If first search fails, refine the query - don't broaden it
- Ask user for clarification before broad searches
