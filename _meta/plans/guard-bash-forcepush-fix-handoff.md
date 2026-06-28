# Handoff: guard-bash force-push false-positive fix (uncommitted)

**Status:** fix WRITTEN to disk, NOT committed. Blocked by the session wall-clock
killswitch (~21h budget exceeded) — git is refused this session. Finish in a fresh session.

## What the bug was
`hooks/scripts/guard-bash.sh` force-push-to-main block grep'd the *whole* command string
independently for three things — the push verb, a force flag (`-f`/`--force`/`--force-with-lease`),
and `main`/`master`. So a force flag ANYWHERE in a compound command false-tripped it. Real case
that bit us: `git worktree add … ; git am … ; git push origin HEAD:main ; rm -f patch` →
the `rm -f` supplied the "force flag", `push` + `main` were present → "BLOCKED: Force push to
main/master not allowed" on a non-force push.

## The fix (already applied to the file)
Segment the command on shell separators (`tr ';|&' '\n'`, matching the rm-gate style lower in
the same file) and only block when the force flag (or a `+refspec`) appears in the SAME
`git push` segment as `main`/`master`. See the `while IFS= read -r _seg … done < <(…)` block
that replaced the old 3-grep `if`.

Traced (not live-run — killswitch blocked Bash):
- `rm -f x && git push origin main` → push segment has no force flag → PASS ✓
- `git push origin HEAD:main && rm -f y` → PASS ✓
- `git push --force origin main` / `-f` / `--force-with-lease` → BLOCK ✓
- `git push origin +main` (+refspec force) → BLOCK ✓
- `git push --force origin feature` (non-main) → PASS ✓

## To finish (fresh session)
1. Canonical source (`CodingVault/kernel-claude/hooks/scripts/guard-bash.sh`) is already edited.
   Commit + push it:
   `cd CodingVault/kernel-claude && git add hooks/scripts/guard-bash.sh && git commit && git push`
   (kernel-claude is a submodule of CodingVault → then bump the pointer:
   `cd CodingVault && git add kernel-claude && git commit -m "chore: bump kernel-claude (guard fix)" && git push`)
2. The LIVE copy that actually runs is
   `~/.claude/plugins/marketplaces/kernel-marketplace/hooks/scripts/guard-bash.sh` — a SEPARATE
   installed copy (not a symlink). It still has the OLD buggy block. Edit was blocked by the
   `.claude/` config guard. Sync it by reinstalling/refreshing the kernel plugin, or copy the
   fixed block over manually. Until then the false-positive persists at runtime.
3. Live-test after syncing: confirm `rm -f x && git push origin main` PASSES and
   `git push --force origin main` is BLOCKED.

## Related work this session (all committed + pushed already)
- project-atlas → own private repo + submodule of CodingVault; SQLite → atlas.db.json mirror.
- Vaults `main`: `.claude/rules/sqlite-mirror.md` + invariants bullet; `_meta/services/`
  sqlite-guard-precommit + install-sqlite-guard.sh (pre-commit guard, hook-enforced, SessionStart-wired).
