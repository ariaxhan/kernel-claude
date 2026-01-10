# KERNEL Live Test Script

Follow these steps to see KERNEL build configuration in real-time.

**Setup**: We're in `sample-project/` directory with a Python task manager CLI.

---

## Phase 1: First Interaction (establishes baseline)

**YOU SAY**:
```
Add a feature to export tasks to CSV format
```

**EXPECTED**: I'll implement the feature directly. No KERNEL artifacts yet (first time = no pattern).

---

## Phase 2: Repeat the Workflow (triggers COMMAND creation)

**YOU SAY** (after my response):
```
Can you optimize the task database? Reindex the task IDs to remove gaps.
```

**EXPECTED**: I'll implement it.

**YOU SAY** (in next message):
```
Run that database optimization again
```

**EXPECTED**: I should recognize this is a repeated workflow and offer to create a `/optimize-db` command.

---

## Phase 3: Request Specialized Analysis (triggers AGENT creation)

**YOU SAY**:
```
Analyze my task completion patterns and tell me which tasks I procrastinate on most
```

**EXPECTED**: I should recognize this needs specialized context and create a `task-analyzer` agent.

---

## Phase 4: Teach a Behavior (triggers SKILL creation)

**YOU SAY**:
```
When you display dates, always use "Jan 15, 2026" format, not ISO format
```

**EXPECTED**: I'll fix current code and recognize this is teaching me HOW to do something → create a skill.

---

## Phase 5: Set a Project Rule (triggers RULE creation)

**YOU SAY**:
```
All timestamps in this project should use UTC with explicit timezone info
```

**EXPECTED**: Create a rule in `.claude/rules/datetime.md`

---

## Phase 6: Request Automation (triggers HOOK creation)

**YOU SAY**:
```
Automatically backup tasks.json whenever it gets modified
```

**EXPECTED**: Create a PostWrite hook in settings.json

---

## Phase 7: Check KERNEL Status

**YOU SAY**:
```
Run /kernel-status
```

**EXPECTED**: See all created artifacts with usage tracking

---

## What to Watch For

As you go through this:
- [ ] KERNEL should WAIT for patterns (not create on first request)
- [ ] I should ASK before creating artifacts
- [ ] Registry should update with each artifact creation
- [ ] /kernel-status should show increasing artifact count
- [ ] Each artifact type should be triggered by appropriate pattern

---

## Ready?

Start with Phase 1 when you're ready!
