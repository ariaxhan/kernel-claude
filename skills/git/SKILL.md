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
    13. Keep diffs ≤400 lines. >400 lines: split the PR first — AI review accuracy drops significantly above this threshold. <!-- Updated 2026-06-07: https://blog.exceeds.ai/ai-code-review-best-practices/ -->
    14. AI review before human review (sequence: AI → fix → human). Never parallelize.
    15. PR description for AI-assisted work must answer: AI role / prompt / human contribution.
    16. "Nit:" prefix for optional style comments.
    17. Reviewer context matters: reviewer with diff-only context → diff-quality findings; reviewer with full-codebase context → codebase-quality findings. Spawn reviewers with repo access. <!-- Updated 2026-06-04: https://sourcegraph.com/blog/ai-code-review -->
    18. Pre-PR validation for AI-generated code: before raising the PR, verify the implementation against the original spec/intent (not just "does it run?"). Catch intent drift — AI correctly implemented what it inferred, not what was actually needed — before a human reviewer sees it. <!-- Updated 2026-06-05: https://sourcegraph.com/blog/ai-code-review -->
    19. Track AI review acceptance rate: ≥50% of comments accepted = signal of trusted, actionable feedback. Below 50% → tool is misconfigured, noisy, or poorly scoped. <!-- Updated 2026-06-08: https://blog.exceeds.ai/ai-code-review-best-practices/ -->
    20. Small PRs (≤400 lines) + multi-tool guidelines = 30–40% shorter review cycle times. The size rule has measurable throughput impact, not just reviewer comfort. <!-- Updated 2026-06-08: https://blog.exceeds.ai/ai-code-review-best-practices/ -->
    21. Risk hotspot prioritization: use review analytics (change frequency × defect rate per file/subsystem) to identify hotspots. Invest deeper human review at hotspots; lighter AI-only review at low-churn, low-defect areas. <!-- Updated 2026-06-13: https://blog.exceeds.ai/ai-code-review-best-practices/ -->
    22. Non-interactive review in CI/hooks: `claude -p "Review this diff for security issues" --output-format json --allowedTools Read,Bash` runs Claude as a script in pre-commit or pipelines. Scope tools with `--allowedTools` to prevent unintended writes during automated runs. <!-- Updated 2026-06-14: https://code.claude.com/docs/en/best-practices -->
    23. Framework-specific review checks: React → hooks violations (stale closures, missing dependency arrays, conditional hooks); Go → unchecked errors and goroutine leaks; Python → mutable default args and bare except clauses. Generic review misses these; name the framework in the review prompt. <!-- Updated 2026-06-15: https://blog.exceeds.ai/ai-code-review-best-practices/ https://sourcegraph.com/blog/ai-code-review -->
    24. **Measure AI review impact with DORA + AI-specific metrics**: track deployment frequency, change failure rate, and review cycle time (DORA) alongside AI-specific KPIs — AI comment acceptance rate ≥50%, false-positive rate <20%, mean-time-to-resolution per finding. Teams that instrument both catch whether AI tools are improving velocity or just adding noise. By early 2026, 41% of commits are AI-assisted — without measurement you can't tell if review tooling is keeping pace. <!-- Updated 2026-06-17: https://blog.exceeds.ai/ai-code-review-best-practices/ -->
    25. **Context-engine review**: before spawning a reviewer, assemble signal artifacts — cross-repo usages of changed symbols, historical PRs that touched the same modules, relevant architecture docs. Pass them as context. Shifts the reviewer bottleneck from discovery ("what is this?") to judgment ("is this right?"). <!-- Updated 2026-06-24: https://www.metacto.com/blogs/establishing-code-review-standards-for-ai-generated-code -->
    26. **AI-Prompt Playbook + Cautionary Tales wiki**: maintain a "Cautionary Tales" doc of reviewed-and-rejected AI patterns (with reasons), and an "AI-Prompt Playbook" of successful prompt templates for common tasks. Both accumulate as institutional memory across the team and accelerate review quality over time. <!-- Updated 2026-06-24: https://www.metacto.com/blogs/establishing-code-review-standards-for-ai-generated-code -->
    27. **Custom review rules beat default settings**: default AI review model settings generate generic findings; configure custom rules around internal coding standards, deprecated modules, architecture requirements, and known risk patterns. Teams that add custom rules get significantly more relevant, actionable findings from AI reviewers than out-of-box settings. <!-- Updated 2026-06-27: https://blog.exceeds.ai/ai-code-review-best-practices/ https://www.codeant.ai/blogs/code-review-best-practices -->
    28. **Distribute AI review expertise**: don't let knowledge of AI review tooling sit with one specialist. Multiple engineers should understand how to configure AI reviewers, interpret findings, and tune rules. When only one person knows the tooling, review queues back up when they're unavailable. <!-- Updated 2026-06-27: https://blog.exceeds.ai/ai-code-review-best-practices/ -->
    29. **Review time parity = rubber-stamping**: if AI-generated PRs get reviewed in the same wall-clock time as human PRs, you are rubber-stamping. AI PRs contain 1.7× more defects per line — they require proportionally more scrutiny, not equal scrutiny. Signal: if review time matches, either shrink PRs further or add a mandatory checklist item (security + logic sign-off) that forces genuine engagement before merge. <!-- Updated 2026-06-28: https://blog.exceeds.ai/ai-code-review-best-practices/ -->
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
