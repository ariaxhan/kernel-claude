---
name: kernel:ship
description: "Release-gate sequence: validate → review → push → tag. Wraps kernel:git mechanics with the pre-ship safety chain. Triggers: ship, release, push to main, ready to merge, deploy."
allowed-tools: Read, Bash, Task, Edit
---

<skill id="ship">

<purpose>
Shipping is not committing. Committing is one step of shipping.
Ship = the full sequence: validate gates → review → push → optionally tag.
Each step has a fail-fast verdict; the chain stops on first failure.
</purpose>

<prerequisite>
agentdb read-start has run. Working tree is clean OR all uncommitted work is intentional and named.
You know what you are shipping: branch name, commit range, the thing this release changes.
</prerequisite>

<reference>
Pairs with skills/git/SKILL.md (commit mechanics) and skills/quality/SKILL.md (Big 5).
Invokes /kernel:validate (gates) and /kernel:review (PR review). Spawns agents/pre-ship.md
for tier 2+ work.
</reference>

<core_principles>
1. **Validate before review, review before push, push before tag.** The order is fail-fast.
2. **Push to `main` requires explicit user say-so.** Feature branch push is fine after gates pass.
3. **The release is the artifact, not the intent.** Verify by file/diff, not by what you meant to ship.
4. **Tag only when explicitly releasing.** Casual pushes don't get tags.
5. **Hook carve-outs apply to hooks only.** User and agent commits in this skill go through the full gate chain.
</core_principles>

<sequence>

  <phase id="preflight">
    Before anything else:
    - `git status --porcelain` clean? If not: ask user to commit, stash, or abandon.
    - `git branch --show-current` matches the intent? If user said "ship the auth fix" but you're on `main`, stop.
    - Commit range: `git log --oneline {main}..HEAD` — does it match what you think you're shipping?
    - If anything looks wrong, AskUserQuestion before continuing.
  </phase>

  <phase id="validate">
    Invoke /kernel:validate (spawns validator agent with full 9-gate safety chain).
    Block on any FAIL. Do not soft-skip a gate.

    Quick local equivalents if /kernel:validate is unavailable:
    - Tests: project's nearest configured command (`npm test`, `pytest`, `cargo test`, etc.)
    - Types: `tsc --noEmit` / `mypy` / `cargo check`
    - Lint: `eslint` / `ruff` / `cargo clippy`
    - Security: `npm audit` / `pip-audit` / project's configured scanner
    - Diff sanity: `git diff --stat {main}..HEAD` — no unrelated changes, no leaked secrets

    On FAIL: stop. Report which gate failed and why. Do not push.
  </phase>

  <phase id="review">
    Tier 1 (1-2 file changes, low risk): self-review via Big 5 from skills/quality/SKILL.md.
    Tier 2+: invoke /kernel:review (spawns reviewer agent at >80% confidence threshold).

    If review returns REQUEST CHANGES: stop. Address feedback. Re-run from validate.
    If review returns COMMENT: surface the comments to user; ask if they want to proceed or address.
    If review returns APPROVE: continue.
  </phase>

  <phase id="push">
    Branch detection:
    - Feature branch (`feat/*`, `fix/*`, `chore/*`, etc.): push without further confirmation.
    - `main` / `master`: **STOP. AskUserQuestion before pushing.** Push to main requires explicit user say-so (NEXUS I0.8).
    - Detached HEAD or weird state: stop. Investigate.

    Push command: `git push` (or `git push -u origin {branch}` if upstream not set).
    On rejection (non-fast-forward, hook block, auth fail): surface to user. Do NOT force-push.
  </phase>

  <phase id="tag" optional="true">
    Only if the user explicitly asked to tag a release.

    For semver projects: read current version from manifest (`package.json`, `Cargo.toml`,
    `pyproject.toml`, etc.), confirm next version with user, then:
    `git tag -a v{X.Y.Z} -m "{release notes summary}"` and `git push origin v{X.Y.Z}`.

    For non-versioned projects: timestamp tag if requested, otherwise skip.
  </phase>

  <phase id="checkpoint">
    agentdb learn pattern "ship: {branch} {commit_range} {sha_pushed}" "validate=pass review=pass push=ok"
    Profile-gated:
    - github-oss / github-production: post PR or release note via gh CLI / GitHub integration hooks.
    - local: nothing further.
  </phase>

</sequence>

<ask_user>
  Use AskUserQuestion at three points:
  1. Preflight, if branch or commit range is ambiguous: "Shipping {N} commits on {branch}. Confirm?"
  2. Review COMMENT verdict (not REQUEST CHANGES): "Review returned {N} comments. Address now, ship anyway, or hold?"
  3. Push to main: "About to push to main. NEXUS I0.8 requires explicit say-so. Confirm?"
</ask_user>

<failure_modes>
1. validate FAIL → block; report which gate; do not loop silently into "try again"
2. review REQUEST CHANGES → block; address comments; restart from validate (changes invalidate prior gates)
3. push rejected (non-fast-forward) → ask user; never auto-rebase or force-push
4. tag conflict → check `git tag -l` first; suggest next version; never overwrite an existing tag
</failure_modes>

<anti_patterns>
- ship_without_validate: every step depends on the previous; skipping validate skips type/test/security
- silent_skip_review: review FAIL with no surfacing to user = trust violation
- auto_push_to_main: NEXUS I0.8 — main requires explicit user confirmation
- force_push_on_rejection: rejection means the remote has work you don't; investigate before overwriting
- tag_without_release_intent: tags are durable; casual pushes get no tag
- skip_checkpoint: shipped-but-unrecorded work breaks retrospective and learning loops
</anti_patterns>

<on_complete>
agentdb write-end '{"skill":"ship","branch":"X","commits":N,"validate":"pass","review":"approve|comment|skip","pushed":true,"tagged":"X.Y.Z|none"}'
</on_complete>

</skill>
