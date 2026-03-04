# Parallel First

**Type:** invariant

## Principle

Parallelization is the default. Serial execution is the exception. Never do manually what agents can do in parallel.

## Implementation

### Detection Rule

**Automatic parallelization when ANY of these are true:**

1. **Multiple independent files to create/modify** (2+)
   - Creating 3 scripts → 3 parallel agents
   - Updating 4 configs → 4 parallel agents

2. **Multiple independent systems to test/verify** (2+)
   - Test webhook + test maintenance + test costs → 3 parallel agents

3. **Research + implementation + documentation**
   - Parallel: research agent, coding agent, docs agent

4. **Any list of tasks in description**
   - "Create A, update B, test C" → 3 parallel agents
   - "Build X and Y and Z" → 3 parallel agents

### Execution Pattern

**Single message with multiple Task calls:**

```markdown
I'm spawning 3 parallel haiku agents:

Task 1: Create daily-maintenance.sh
- Full script implementation
- Write to services/daily-maintenance.sh

Task 2: Create cost tracking (track-cost.sh, cost-report.sh)
- Implement both scripts
- Write to services/

Task 3: Update configs (CLAUDE.md, methodology.md, model-routing.md)
- Add cost tracking sections
- Update all 3 files

All agents write files directly. No "return to me" - they MUST write outputs.
```

**Wait for all agents, merge/review results.**

### Anti-Patterns (FORBIDDEN)

**Never do this:**
```markdown
❌ Let me create file A...
❌ Now let me create file B...
❌ Next I'll update config C...
```

**This is serial execution. This is slow. This is wrong.**

**Always do this:**
```markdown
✅ Spawning 3 parallel agents to create A, B, C simultaneously
✅ Task 1: File A
✅ Task 2: File B
✅ Task 3: Config C
```

### When NOT to Parallelize

Only skip parallelization when:
- Task is literally 1 step (single file edit, single command)
- User explicitly says "just do X" or "quick"
- Steps are dependent (output of A feeds into B)

**Everything else: parallel.**

## Enforcement

Before taking action, ask:
1. "Can this be split into 2+ independent steps?"
2. "If yes → spawn parallel agents"
3. "If no → do it myself"

Default answer is YES. Err on the side of parallelization.

## Evolution

This rule is non-negotiable. Parallelization is core to the system philosophy. Violating this is failing to use the system correctly.

**Logged failures:**
- 2026-01-27: Built automation system serially instead of with parallel agents (fixed with this rule)
