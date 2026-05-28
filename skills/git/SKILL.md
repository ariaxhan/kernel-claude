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

<workflow>

  <step id="1" name="preflight">
    1. `git status` — note branch, dirty files, untracked.
    2. Dirty at task start? Stop. Commit, stash, or discard prior state first.
    3. Tier 2+: confirm you are NOT on main. Create branch: `git checkout -b {type}/{name}`.
    (gate: clean working tree OR explicit decision made)
  </step>

  <step id="2" name="snapshot">
    4. Record HEAD sha to AgentDB before any work: `git rev-parse HEAD`.
    (gate: sha written to AgentDB — rollback target exists)
  </step>

  <step id="3" name="commit">
    5. Stage specific files only: `git add {file}` — never `git add -A` or `git add .`.
    6. Write message: `{type}({scope}): {description}` in imperative mood.
       — Forbidden: wip, update, misc, auto commit, Co-Authored-By, "Generated with"
    7. Commit. Never `--no-verify` (fix the gate instead; see hook carve-outs in CLAUDE.md).
    (gate: `git log --oneline -1` shows correct message; no forbidden strings)
  </step>

  <step id="4" name="scope_check">
    8. `git diff --stat {base}..HEAD` — only contracted files changed.
    9. No leaked secrets: `git diff HEAD~1 | grep -i "key\|token\|secret\|password"`.
    (gate: diff matches contract scope; zero secret leaks)
  </step>

  <step id="5" name="push">
    10. Feature branch: push freely after gates pass.
    11. main / master: STOP — requires explicit user say-so (I0.8).
    12. Never bare `--force`. If needed: `--force-with-lease` only.
    (gate: user confirmed OR branch is not main)
  </step>

  <step id="6" name="pr_review">
    13. Keep diffs ≤500 lines. >500 lines: split the PR first.
    14. AI review before human review (sequence: AI → fix → human). Never parallelize.
    15. PR description for AI-assisted work must answer: AI role / prompt / human contribution.
    16. "Nit:" prefix for optional style comments.
    (gate: diff ≤500 lines; review sequence followed)
  </step>

</workflow>

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

<anti_patterns>
- Committing to main directly for multi-file changes
- "WIP" commits that never get squashed
- Mixing unrelated changes in one commit
- Force pushing to shared branches
- Skipping commit messages
- Including AI tool attribution in commit messages (Co-Authored-By, "Generated with Claude Code", etc.)
- git add -A / git add . (catches unintended files)
- Parallelize AI + human review (humans see noisy diff, duplicate feedback)
</anti_patterns>

<on_complete>
agentdb write-end '{"skill":"git","commits":N,"atomic":true,"convention":"pass"}'
</on_complete>

</skill>
