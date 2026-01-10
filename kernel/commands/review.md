---
description: Review code changes using comprehensive checklist
allowed-tools: Read, Bash, Grep, Glob
---

# Review Command

Apply CODE-REVIEW-BANK checklist to recent changes.

## Step 1: Read Review Bank

Read CODE-REVIEW-BANK.md from kernel/banks/ (or project root if copied).

## Step 2: Identify Changes

Get recent changes:
```bash
# Show recent commits
git log --oneline -5

# Show diff
git diff HEAD~1..HEAD

# Or staged changes
git diff --staged
```

Ask user which commit/range/files to review if not specified.

## Step 3: Read Changed Files

Read all files that were modified.

## Step 4: Apply Checklist

Review against:

### Correctness
- Does it solve the stated problem?
- Are edge cases handled?
- Is error handling complete?

### Testing
- Are there tests for new functionality?
- Do tests cover edge cases?
- Do existing tests pass?

### Security
- No SQL injection?
- No XSS vulnerabilities?
- Input validated?
- Secrets not committed?

### Code Quality
- Follows project conventions?
- No duplicated code?
- Clear naming?
- Appropriate complexity?

### Performance
- No N+1 queries?
- Efficient data handling?

### Integration
- Backward compatible?
- API contracts maintained?
- Documentation updated?

## Step 5: Report Findings

Structure as:
```
## Code Review

### Summary
[Brief overview of changes]

### ✅ Strengths
- [What's good]

### 🚫 Critical Issues (Block Merge)
- [Security, breaking changes, no tests]

### ⚠️ Important Issues (Strongly Suggest Fix)
- [Unclear code, missing error handling]

### 💡 Suggestions (Optional)
- [Simplifications, optimizations]

### Verdict
[APPROVED / APPROVED WITH CHANGES / NEEDS WORK]
```

## Notes

- Reference CODE-REVIEW-BANK.md for full checklist
- Use emoji indicators (🚫 ⚠️ 💡) for severity
- Be specific about what to fix and why
- Suggest solutions, not just problems
