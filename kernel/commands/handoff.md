---
description: When ending session - Generate context handoff for continuation
allowed-tools: Read, Glob, Bash
---

# Generate Handoff

**When to use**: Ending work session, switching tasks, or preparing team handoff.
**What it does**: Creates structured handoff document with context, decisions, and next steps.

## When to Use

- User says "create a handoff", "context handoff", "prepare handoff"
- User needs to transfer conversation to Claude on web or future session
- User needs to pause work and resume later

## Step 1: Extract Current State

Gather:
- **Goal**: What is the user trying to achieve?
- **Position**: Where are we in the workflow?
- **Decisions**: What choices were made and why?
- **Open Threads**: What's unfinished or unresolved?
- **Artifacts**: What was created (files, code, frameworks)?
- **Context**: Critical background needed to continue
- **Warnings**: Failed approaches, pitfalls to avoid

## Step 2: Check Recent Work

```bash
# Recent file changes
git status --short
git diff --stat

# Recent commits
git log --oneline -5

# Files created this session (if tracked)
find . -type f -mmin -60 | grep -v node_modules | grep -v .git
```

## Step 3: Generate Handoff

Use this format:

```
## CONTEXT HANDOFF

**Summary**: [One sentence capturing entire situation]

**Goal**: [What user is trying to achieve]

**Current state**: [Where things stand now - concrete, specific]

**Decisions made**:
- [Decision 1: choice + rationale if non-obvious]
- [Decision 2]

**Artifacts created**:
- [File/framework 1 with path]
- [File/framework 2 with path]

**Open threads**:
- [Unfinished item 1]
- [Question needing resolution]

**Next steps**:
1. [Recommended action 1 - specific, actionable]
2. [Recommended action 2]

**Context essentials**:
- [Critical background 1 - only what's needed to act]
- [Critical background 2]

**Warnings**:
- [Pitfall/failed approach to avoid]

**File paths to read**:
- [Key file 1]
- [Key file 2]

**Continuation prompt for new session**:
> [Exact text to paste - 2-3 sentences max]
> [Include: goal, current position, immediate next action]
```

## Compression Rules

- **One sentence max per bullet**
- **No redundancy** between sections
- **Omit empty sections**
- **Actionable over descriptive** (focus on what to DO)
- **Concrete over vague** ("Created 6 banks in kernel/banks/" not "Made progress on banks")

## Continuation Prompt Guidelines

The continuation prompt should be 2-3 sentences that:
1. State the goal
2. State current position
3. State immediate next action

Example:
> We're building a knowledge bank architecture for KERNEL to provide baseline coding practices without token bloat. We've created 6 banks + 7 skills + 4 commands with ~560 token cost (vs 6000+ old way). Next: Review and improve baseline artifact design for better universal applicability.

## Validation Check

Before outputting, ask:
- Could a new AI instance continue productively with ONLY this brief?
- Are there gaps that would cause confusion?
- Is the continuation prompt self-contained?

If gaps exist, add missing context or flag as `[NEEDS CLARIFICATION: ...]`

## Output

Present the handoff in a code block for easy copy-paste, then ask:
- "Should I save this handoff to a file?"
- "Ready to continue on Claude web, or need adjustments?"
