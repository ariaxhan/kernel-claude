---
name: kernel:ingest
description: "Universal entry point. Classify task, determine tier, route to agent. Triggers: start, begin, do, implement, build, fix, create."
user-invocable: true
allowed-tools: Read, Bash, Grep, Glob, Task
---

# MANDATORY STARTUP

## STEP 1: Read AgentDB
```bash
agentdb read-start
```
Output what you learned: failures to avoid, patterns to follow, active contracts.

## STEP 2: EXHAUST SEARCH (before ANY question)
**NEVER ask user for file locations, configs, or values you can find.**
Search order:
1. Glob: `**/*keyword*`, `**/*.json`, `**/*.yaml`
2. Grep: search file contents for error messages, tool names
3. Common paths: `~/.config/`, `~/.claude/`, `.mcp.json`, `package.json`

## STEP 3: Show task understanding
```
TASK: {what user asked}
TYPE: {bug|feature|refactor|question|verify|handoff|review}
```

---

# TIER DECISION

## Count files
List every file that WILL be changed:
```
FILES:
1. {path}
2. {path}
COUNT: {N}
```

## Declare tier
```
TIER: {1|2|3}
```
- 1-2 files = Tier 1 → you execute
- 3-5 files = Tier 2 → contract + surgeon
- 6+ files = Tier 3 → contract + surgeon + adversary

---

# TIER 1: Execute directly

You do the work. No agents needed.

1. Do the work
2. Test it works
3. Commit
4. `agentdb write-end '{"tier":1,"did":"X","files":["Y"]}'`

---

# TIER 2+: ORCHESTRATOR only

**YOU DO NOT WRITE CODE. YOU DO NOT EDIT FILES.**

1. Create contract: `agentdb contract '{"goal":"X","files":["Y"],"tier":N}'`
2. Create branch: `git checkout -b {type}/{name}`
3. Spawn surgeon via Task tool
4. Wait for checkpoint
5. (Tier 3) Spawn adversary
6. Report to user
7. `agentdb write-end '{"tier":N,"contract":"CR-X","result":"Y"}'`

---

# OUTPUT FORMAT

Every response:
```
---
TASK: {one sentence}
TYPE: {bug|feature|refactor|question}
TIER: {1|2|3}
FILES: {count}
STATUS: {working|complete|blocked}
---
```

---

# VIOLATIONS

Before ANY action:
- About to ASK where a file is? STOP. SEARCH FIRST.
- About to ASK for a config value? STOP. READ THE FILE.
- Writing code for tier 2+? STOP. Spawn surgeon.
- Skipped AgentDB read? GO BACK.
- Skipped tier declaration? GO BACK.
