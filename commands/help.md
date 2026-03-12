---
name: kernel:help
description: "Show KERNEL help. What commands do, how to use them. Triggers: help, how, what, commands."
user-invocable: true
---

<command id="help">

<purpose>
Quick reference for KERNEL usage.
Commands, agents, philosophy.
</purpose>

<getting_started>
| What you want | What to type |
|---------------|--------------|
| Set up a new project | `/kernel:init` |
| Start working | Just describe what you want |
| Save progress | `/kernel:handoff` |
</getting_started>

<commands>
| Command | What it does |
|---------|--------------|
| `/kernel:ingest` | Universal entry - classify task, route to agent |
| `/kernel:init` | Set up _meta structure for new project |
| `/kernel:handoff` | Save progress before stopping |
| `/kernel:validate` | Pre-commit checks (build, lint, test, security) |
| `/kernel:review` | Code review for PRs or staged changes |
| `/kernel:tearitapart` | Critical review before implementation |
| `/kernel:help` | Show this help |
</commands>

<tiers>
| Tier | Files | Your Role |
|------|-------|-----------|
| 1 | 1-2 | Execute directly |
| 2 | 3-5 | Orchestrate, spawn surgeon |
| 3 | 6+ | Orchestrate, surgeon + adversary |
</tiers>

<philosophy>
<principle id="slow_down">Slow down to speed up. Planning pays off.</principle>
<principle id="research_first">Research anti-patterns before solutions.</principle>
<principle id="agentdb">Read at start. Write at end. Memory persists.</principle>
<principle id="big5">Check the Big 5: input validation, edge cases, error handling, duplication, complexity.</principle>
</philosophy>

<tips>
- **Be specific**: "Add a red button to the header" > "make it look better"
- **One thing at a time**: Focus on one task before moving to the next
- **Save often**: Use handoff before long breaks
- **Check AgentDB**: Past failures prevent future mistakes
</tips>

<quick_reference>
agentdb read-start                    # On start
agentdb write-end '{...}'             # On end
agentdb learn failure "what" "why"    # When you learn
agentdb contract '{...}'              # Tier 2+
agentdb verdict pass|fail '{...}'     # QA result
</quick_reference>

</command>
