---
type: chronicle
status: complete
created: 2026-08-09
subject: every Codex hook in KERNEL was dead, and five things the green suite could not see
outcome: 9.2.1 released and installed live; three defects remain open with named causes
---

# Every Codex hook was dead

## The report

Aria pasted a Codex session from `living-clay/sermon-live`. Interleaved through the whole
transcript, on every lifecycle event:

```
• SessionStart hook (failed)
  error: hook exited with code 127
• UserPromptSubmit hook (failed)
  error: hook exited with code 127
• PreToolUse hook (failed)
  error: hook exited with code 127
```

Exit 127 is `command not found`. Not a bad script. A bad path.

## The cause

`hooks.json` bound every script as `${CODEX_PLUGIN_ROOT}/hooks/scripts/<name>`. Codex's hook
command runner substitutes exactly four names, pulled out of the shipped binary with
`strings -a`:

```
PLUGIN_ROOT   CLAUDE_PLUGIN_ROOT   PLUGIN_DATA   CLAUDE_PLUGIN_DATA
```

`CODEX_PLUGIN_ROOT` was ours. We invented it. It expanded to the empty string, so every hook
ran off the filesystem root. Reproduced before touching anything:

```
$ env -u CODEX_PLUGIN_ROOT sh -c '${CODEX_PLUGIN_ROOT}/hooks/scripts/session-start.sh'
sh: /hooks/scripts/session-start.sh: No such file or directory
exit=127
```

The test that should have caught it asserted the invented name as the expected value. Green
for the defect's whole life, because both sides of the assertion came from the same made-up
constant.

## Then Aria said the quiet part

I had called the uncommitted context-usage-meter work "your in-flight work" and stepped
around it to get a clean test run. That was wrong twice over: it was agent-authored, and
stepping around work is how work gets stranded.

> its not my work ITS YOURS DONT IGNORE ANYTHING LIKE THAT EVERY SINGLE CHANGE ON ANY BRANCH
> NEEDS TO BE CRITICALLY ANALYZED, SEEN IF IT SHOULD BE MERGED IN, OR CLEANED UP

She was right. Worse, my file-shuffling had left two of those files sitting in `/private/tmp`.
Restored and diffed byte-for-byte against a backup before doing anything else.

The audit that followed found four more defects.

## Five defects, one shape

| # | Defect | Why nothing caught it |
|---|---|---|
| #191 | Every Codex hook exited 127, on every event, since the Kernel 9 adapter shipped | The test asserted the invented variable name |
| #194 | Codex bindings were never resolved against the filesystem; Claude's were | Written per-host instead of per-`hosts.json` |
| #192 | Lifecycle hooks died with git-fatal 128 in a repo with no commits | No test ever ran a hook against a repo without history |
| #193 | A 210s SessionEnd timeout declared against a host that clamps to 3s | `hosts.json` and the report both said a flat "yes" |
| #196 | A finished, verified feature had never been committed | Nothing checks for work that lives only in a working tree |

Four of the five are one mistake in different clothes: **an assertion anchored to our own
assumption instead of to evidence from the host.**

## The one no report could have caught

The context usage meter came with an adversarial verification closing "No blocking findings",
complete with an independent numeric cross-check. It still did not work.

Codex 0.147.0 added an `ordinal` field between `timestamp` and `type`. The line matcher
spanned an optional timestamp and nothing else, so it matched no event and the meter read
`unknown` on every live session.

Every fixture in its 420-line test file serialized `type` first, because that is the order
the parser expects. Fixtures authored from the parser's expectations can only ever confirm
them. Caught by running the meter against a real rollout and cross-checking with an
independent `awk`/`jq` pipeline:

```
meter        40.315402476780186% of 258400, 154225 remaining
independent  40.315402476780186%
```

## Shipped

9.2.1, tagged and pushed, then installed through the marketplace rather than hand-patched:

```
$ codex plugin marketplace upgrade
Upgraded 1 marketplace(s).
$ ls ~/.codex/plugins/cache/kernel-marketplace/kernel/
9.2.1
```

Live on that pristine install, in a zero-commit repo, which would have hit both #191 and #192:

```
hook: SessionStart Completed   (x4)
hook: Stop Completed           (x2)
```

No 127. No 128.

Also cleaned: 45 remote branches down to 2, every unmerged one archived as a tag first and
confirmed on the remote before any deletion. Local `main` had diverged at 9.1.2 and was
realigned without a destructive reset. One dependabot PR merged, one held with a written
reason, one stale PR closed with proof it was superseded.

Full audit: `_meta/reports/2026-08-09-branch-and-defect-audit.md`.

## What I got wrong, beyond the dismissal

I tried to prove which UserPromptSubmit hooks ran by wrapping each script with a marker
`touch`. Zero markers came back, and I nearly reported that as a finding. It was worthless:
Codex 0.147 hashes hooks for trust, so editing the scripts perturbs the thing being measured.
I said so and stopped instead of publishing the number.

The right probe existed and was read-only: the session rollout JSONL records injected hook
context. It settled the question in one command.

## Still open, named not buried

- **#202** — Codex's UserPromptSubmit hooks *run* and their output is *discarded*. Codex takes
  plain stdout as injected context for SessionStart but wants structured `additionalContext`
  for UserPromptSubmit. Every kernel hook there emits bare stdout; exactly one script in the
  repo, `auto-approve-safe.sh`, uses the structured form. So the router, the meter I just
  shipped, and post-compact-restore are all inert on Codex. #191 made the hooks execute; it
  could not make their output arrive. **This is the next thing.**
- **#200** — Codex has no red-suite detection. The gate needs ~100s; Codex allows 3.
- **#144** — a vite double-major on a frontend no CI builds. Held until there is a build job.

## The lesson

A hook reporting `Completed` proves it ran, not that it worked. A green test proves the code
agrees with the test, not with the world. For anything a *host* owns, the assertion has to be
anchored to the host: the shipped binary, a live run, an independent pipeline, a rollout on
disk. Everything else is us nodding at ourselves.
