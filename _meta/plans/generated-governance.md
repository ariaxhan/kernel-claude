# Generated governance adapters

## Goal
One readable KERNEL governance source deterministically produces `CLAUDE.md`,
`AGENTS.md`, and the static SessionStart guidance; a safe operator audits or
adapts other Git repositories without flattening scoped rules.

## Constraints
- Python standard library only; allowlisted template substitutions.
- Checked-in native files remain readable and byte-checked in CI.
- Existing cross-repo conflicts are reported, never overwritten.
- No writes outside this worktree while implementing or testing.
- Explicit-only operator skill for both Claude and Codex.

## Approaches considered
1. Symlink native files: smallest, but loaders and Windows checkouts vary.
2. Hand-maintained mirrors plus semantic diff: easy initially, guaranteed drift.
3. Canonical template plus generated adapters and manifest-backed operator.

## Choice
Approach 3. It is deterministic, portable, reviewable, and can fail closed.

## Done when
- Generator rejects unknown, missing, or unused tokens and unexplained drift.
- `--check` byte-compares both adapters and exactly one ambient shell region.
- Audit deduplicates linked worktrees/caches and classifies all requested states.
- Adopt/generate/check require provenance hashes and safe backup/refusal behavior.
- Version bump regenerates adapters; CI and full suite enforce freshness.
- Context receipts count both native instruction names once per content hash.
