---
type: report
status: complete
created: 2026-08-09
subject: full audit of every branch, PR, and uncommitted change in kernel-claude
---

# Branch and defect audit

Triggered by one symptom: every Codex hook exiting 127. The audit that followed covered
every branch, every open PR, and every uncommitted change in the repo.

## What was actually broken

Five defects, all shipped, all silent, all now merged to `main`.

| # | Defect | Why nothing caught it |
|---|---|---|
| #191 | Every Codex hook exited 127 on every event, since the Kernel 9 adapter shipped | The test asserted the invented variable name as the expected value |
| #194 | Codex bindings were never resolved against the filesystem; Claude's were | The check was written per-host instead of per-hosts.json |
| #192 | Lifecycle hooks died with git-fatal 128 in a repo with no commits | No test ever ran a hook against a repo without history |
| #193 | KERNEL declared a 210s SessionEnd timeout that Codex clamps to 3s | `hosts.json` and the capability report both said a flat "yes" |
| #196 | A finished, verified feature had never been committed | Nothing checks for work that exists only in a working tree |

The common shape: **every one of these was invisible to a green suite.** Four were
self-referential (the test and the code drew on the same assumption), and the fifth was
invisible because uncommitted work is not in scope for any check.

### The one the reports could not have caught

The context usage meter was independently verified with "no blocking findings" and still
did not work. Codex 0.147.0 added an `ordinal` field between `timestamp` and `type`; the
line matcher spanned an optional timestamp and nothing else, so the meter read `unknown`
on every live session.

Every fixture in its 420-line test file serialized `type` first, because that is the order
the parser expects. **Fixtures authored from the parser's expectations can only ever
confirm them.** It was caught by running the meter against a real rollout and cross-checking
with an independent `awk`/`jq` pipeline:

```
meter        40.315402476780186% of 258400, 154225 remaining
independent  40.315402476780186%
```

## Branches

45 remote branches at the start. 2 remain.

| Verdict | Count | Basis |
|---|---|---|
| Deleted, fully merged | 23 | Ancestors of `main`. Zero risk. |
| Deleted, superseded | 19 | Squash-merged or replaced by the 9.x architecture. Verified by content, not by ancestry. |
| Kept | 1 | `dependabot/.../multi-*`, PR #144 still open |
| `main` | 1 | |

**Nothing was destroyed.** All 19 unmerged branches were tagged `archive/<name>` and the
tags pushed before any deletion, confirmed present on the remote first.

Content verification rather than assumption. Git marks squash-merged branches as unmerged,
so ancestry alone would have condemned live work. Instead each branch's signature artifacts
were checked against `main`:

- `hooks/scripts/github-integration.sh` — in main
- `orchestration/agentdb/migrations/004`, `005`, `008` — in main
- `v8.1.3` and `v8.1.4` tags exist, so both 8.1.x fix branches shipped

Two branches were junk rather than work: `feature/phase-4-framework` carried 3,685
committed `node_modules` files, and `backup/dirty-2026-05-28` was a 3,718-file dirty-tree
snapshot.

`chore/kernel-md-review` was the only branch with files genuinely absent from `main`:
`commands/*.md` and `skills/api|backend|design`. Those are pre-9.x architecture that 9.x
deliberately replaced, and the replacement is guarded by two migration tests. Archived, not
merged.

## Pull requests

| PR | Verdict |
|---|---|
| #181 postcss 8.5.15 → 8.5.26 | **Merged.** Lockfile-only, patch level. |
| #144 vite 7 → 8, plugin-svelte 6 → 7 | **Held, with a reason.** Two majors on `frontend/`, which no CI job builds. The green checks are the shell and python suites; they compile nothing. Local verification blocked: node 26 against `better-sqlite3`'s 25 ceiling. |
| #139 remove lifecycle auto-commit | **Closed, superseded.** `session-end.sh` on main has no `git commit` and no `git add`, verified by grep, with the reason written into the file. |

The real fix for #144 is a CI job running `npm ci && npm run build` in `frontend/`. Without
it, every future frontend PR gets a green tick that means nothing.

## Local main had diverged

Local `main` sat at 9.1.2 with two commits `origin/main` did not have, while `origin/main`
was fifteen-plus commits ahead through 9.2.0. Both local commits were superseded upstream
(the 9.1.2 release itself, and a docs file byte-identical to the upstream copy).

Realigned onto `origin/main` without a destructive reset: the old tip is tagged
`local-main-before-realign-20260809`, and every uncommitted file was backed up and verified
byte-identical after restore.

This is why the first fix (#191) was authored in a scratch clone off `origin/main`. Fixing
it in the local tree would have shipped a fix against a version nobody runs.

## Guards that fired, and were right

- `git reset --hard` — refused. A safe detach-and-move sequence was used instead.
- `git branch -D` — refused twice. Local branch cleanup left undone rather than bypassed;
  the remote is clean and every branch is archived, so this is cosmetic.

Both refusals were correct and neither was worked around.

## Open, deliberately

- **#200** — Codex has no red-suite detection. The session-end test gate needs ~100s and
  Codex allows 3. #193 stopped the manifest from claiming time it never had; it did not
  give the mechanism back. Three options are written up in the issue.
- **#144** — needs a frontend build in CI before it can be judged.
- The `tearitapart` skill references `quality`, `testing`, and `security` skills plus a
  research file that are absent from the installed package. Found by the meter's teardown,
  recorded in #196, not fixed there.

## The lesson worth keeping

A test that asserts a value your own generator produced proves only that you agreed with
yourself. For anything a *host* owns — a variable name, a timeout ceiling, a record shape —
the assertion has to be anchored to evidence from the host: the shipped binary, a live run,
an independent pipeline. Four of the five defects here were that same mistake wearing
different clothes.
