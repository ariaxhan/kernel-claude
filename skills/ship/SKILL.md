---
name: kernel:ship
description: "Release-gate sequence: validate → review → push → tag. Wraps kernel:git mechanics with the pre-ship safety chain. Triggers: ship, release, push to main, ready to merge, deploy."
allowed-tools: Read, Bash, Task, Edit
---

<skill id="ship">

## Sequence

1. **Preflight**
   - `git status --porcelain` — clean? If not: ask user to commit, stash, or abandon.
   - `git branch --show-current` — matches intent? Wrong branch → stop.
   - `git log --oneline {main}..HEAD` — commit range matches what you think you're shipping?
   - (gate: any mismatch → AskUserQuestion before continuing)

2. **Validate**
   - Invoke `/kernel:validate` (spawns validator agent, full 9-gate safety chain).
   - If unavailable: run project's nearest configured command (see reference/ship-research.md for equivalents).
   - (gate: any FAIL → stop; report which gate; do NOT push)

3. **Review**
   - Tier 1 (1–2 file changes, low risk): self-review via Big 5 from skills/quality/SKILL.md.
   - Tier 2+: invoke `/kernel:review` (spawns reviewer agent, >80% confidence threshold).
   - (gate: REQUEST CHANGES → stop; address feedback; restart from step 2)
   - (gate: COMMENT → AskUserQuestion: "Address now, ship anyway, or hold?")
   - (gate: APPROVE → continue)

4. **Push**
   - Feature branch (`feat/*`, `fix/*`, `chore/*`, etc.): `git push` (or `git push -u origin {branch}` if upstream not set).
   - `main` / `master`: **STOP. AskUserQuestion required.** (NEXUS I0.8)
   - Detached HEAD or unexpected state: stop; investigate.
   - (gate: push rejected / non-fast-forward → surface to user; do NOT force-push)

5. **Tag** *(only if user explicitly requested a tagged release)*
   - Check: `git tag -l` — confirm tag doesn't already exist.
   - Semver: read version from manifest, confirm next version with user.
   - `git tag -a v{X.Y.Z} -m "{release notes summary}"` → `git push origin v{X.Y.Z}`.
   - Non-versioned: timestamp tag if requested; otherwise skip.

6. **Checkpoint**
   - `agentdb learn pattern "ship: {branch} {commit_range} {sha_pushed}" "validate=pass review=pass push=ok"`
   - Profile-gated: github-oss/github-production → post PR or release note via gh CLI.

## Ask-user gates (mandatory pause points)

| Point | Condition | Question |
|---|---|---|
| Preflight | Branch or commit range is ambiguous | "Shipping {N} commits on {branch}. Confirm?" |
| Review | COMMENT verdict | "Review returned {N} comments. Address now, ship anyway, or hold?" |
| Push | Target is main/master | "About to push to main. NEXUS I0.8 requires explicit say-so. Confirm?" |

## Failure modes

1. `validate FAIL` → block; report which gate; do not loop silently
2. `review REQUEST_CHANGES` → block; address comments; restart from step 2
3. `push rejected (non-fast-forward)` → ask user; never auto-rebase or force-push
4. `tag conflict` → check `git tag -l` first; suggest next version; never overwrite existing tag

## Anti-patterns

- `ship_without_validate` — every step depends on the previous; skipping validate skips type/test/security
- `silent_skip_review` — review FAIL with no surfacing to user = trust violation
- `auto_push_to_main` — NEXUS I0.8; main requires explicit user confirmation
- `force_push_on_rejection` — rejection means remote has work you don't; investigate before overwriting
- `tag_without_release_intent` — tags are durable; casual pushes get no tag
- `skip_checkpoint` — shipped-but-unrecorded work breaks retrospective and learning loops

<on_complete>
agentdb write-end '{"skill":"ship","branch":"X","commits":N,"validate":"pass","review":"approve|comment|skip","pushed":true,"tagged":"X.Y.Z|none"}'
</on_complete>

</skill>
