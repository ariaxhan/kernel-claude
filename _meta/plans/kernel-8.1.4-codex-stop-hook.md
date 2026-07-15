# KERNEL 8.1.4: remove lifecycle autopush

## Goal

Publish a patch release where neither Claude nor Codex automatically performs repository-wide
network or push work at lifecycle end, and prove the marketplace-installed Codex payload ends a
real turn without a Stop timeout.

## Scope

- Remove `SessionEnd → autopush.sh sweep` from `hooks/hooks.json`.
- Replace tests that require SessionEnd with tests forbidding lifecycle autopush.
- Bump every canonical declaration through `scripts/bump-version.sh 8.1.4`.
- Update release prose and changelog.
- Validate, review, merge, tag, publish, reinstall, and run live loader proofs.
- Remove the Vaults local cache repair workaround after marketplace proof.

## Alternatives

1. Longer timeout: rejected; hides the bug.
2. Detect Codex inside the script: rejected; brittle loader sniffing and Claude retains auto-push.
3. Remove automatic lifecycle autopush: chosen; smallest and matches explicit-push doctrine.

## Done-when

- Full test suite and cross-loader tests pass within the release ceiling.
- `v8.1.4` and GitHub release exist on the merged release commit.
- Marketplace resolves and installs 8.1.4 into a clean cache.
- Fresh Codex turn in `dify-meta` exits without Stop errors or surviving fetch children.
- No Vaults script mutates Kernel's installed cache.
