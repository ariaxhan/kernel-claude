---
description: Plan implementation using get-it-right-first-time methodology
allowed-tools: Read, AskUserQuestion, Glob, Grep
---

# Plan Command

Apply the PLANNING-BANK methodology to the user's task.

## Step 1: Read Planning Bank

Read the PLANNING-BANK.md from kernel/banks/ (or project root if copied).

## Step 2: Extract Task Details

From user's request, identify:
- **WHAT**: Precise description of what needs to exist
- **WHY**: Business/user value
- **DONE WHEN**: Specific, testable completion criteria

## Step 3: Extract Assumptions

List all assumptions about:
1. **Tech Stack**: Languages, versions, frameworks
2. **File Locations**: Where code lives, where to create new files
3. **Naming Conventions**: Variable/file naming patterns
4. **Error Handling**: Exceptions vs returns, logging strategy
5. **Testing**: What level of coverage expected
6. **Dependencies**: Existing code/systems being used

Use AskUserQuestion to confirm assumptions if ANY are unclear.

## Step 4: Investigate Existing Patterns

Before proposing implementation:
1. Search for similar functionality (Grep, Glob)
2. Read relevant existing code
3. Identify patterns to copy

## Step 5: Define Interfaces

Specify BEFORE implementation:
```
INPUTS:
  - [Type, shape, constraints]

OUTPUTS:
  - [Return type, success/error cases]

ERRORS:
  - [What can fail, how to handle]

SIDE EFFECTS:
  - [DB writes, API calls, file changes]
```

## Step 6: Present Plan

Structure plan as:
```
## Implementation Plan

### Goal
[What/why/done-when from Step 2]

### Confirmed Assumptions
[From Step 3]

### Existing Patterns Found
[From Step 4]

### Interfaces
[From Step 5]

### Implementation Steps
1. [Phase 1: Skeleton - types/interfaces]
2. [Phase 2: Happy path]
3. [Phase 3: Edge cases]
4. [Phase 4: Integration]

### Validation Checklist
- [ ] Matches spec exactly
- [ ] Handles 3+ edge cases
- [ ] Connects to adjacent components
- [ ] Types correct
```

## Step 7: Get Approval

Ask user to confirm plan before implementation.

## Notes

- Reference PLANNING-BANK.md for full methodology
- Prioritize correctness over speed
- Mental simulation before execution
- Stop if ANY assumption is unclear
