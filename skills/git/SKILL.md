---
name: git
description: "Git workflow and version control best practices. Atomic commits, conventional messages, branch strategies, merge protocols. Triggers: commit, branch, merge, rebase, git, push, pull, PR, version control."
allowed-tools: Bash, Read
---

<skill id="git">

<purpose>
Git is the safety net. Every commit is a checkpoint you can return to.
Atomic commits. Descriptive messages. Feature branches for tier 2+.
Never commit broken code to main.
</purpose>

<prerequisite>
Check git status before any work. Note branch, clean/dirty, remote sync.
</prerequisite>

<reference>
Skill-specific: skills/git/reference/git-research.md
</reference>

<core_principles>
1. ATOMIC COMMITS: One logical change per commit. Never mix feature + refactor + fix.
2. CONVENTIONAL FORMAT: {type}({scope}): {description} - feat, fix, refactor, docs, test, chore
3. IMPERATIVE MOOD: "add feature" not "added feature" or "adding feature"
4. BRANCH PER FEATURE: Tier 2+ work gets feature/{name} or fix/{name} branch
5. COMMIT OFTEN: Every working state gets a commit. Max 30 min between commits.
</core_principles>

<branch_strategy>
- main: Always deployable. Never commit directly for tier 2+.
- feature/{name}: New functionality
- fix/{name}: Bug fixes
- refactor/{name}: Code restructuring

Profile-gated workflow:
  local:            direct to main OK, branches optional
  github:           feature branches for tier 2+, PRs optional
  github-oss:       feature branches always, PRs REQUIRED before merge
  github-production: feature branches always, PRs REQUIRED, review REQUIRED
</branch_strategy>

<commit_messages>
Good:
- feat: add user authentication endpoint
- fix: resolve race condition in cache invalidation
- refactor: extract validation logic to separate module

Bad:
- fixed stuff
- WIP
- updates
</commit_messages>

<anti_patterns>
- Committing to main directly for multi-file changes
- "WIP" commits that never get squashed
- Mixing unrelated changes in one commit
- Force pushing to shared branches
- Skipping commit messages
</anti_patterns>

<pr_structure>
<!-- Updated 2026-03-28: https://addyo.substack.com/p/code-review-in-the-age-of-ai -->
As of 2026, 41% of commits are AI-assisted. PRs must include human accountability:

```
## Intent
1-2 sentences: what this changes and why.

## Proof it works
- [ ] Tests added/updated
- [ ] Manual test steps: [describe]

## Risk tier
low | medium | high — and which parts were AI-generated.

## Review focus
1-2 specific areas where human judgment is needed.
```

AI reviewers break down on large diffs (>500 lines). Keep PRs small and focused.
Non-breaking additions (new fields, optional params, new endpoints) don't need a version bump.
</pr_structure>

</skill>
