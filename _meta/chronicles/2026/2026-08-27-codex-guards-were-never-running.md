---
type: chronicle
status: complete
created: 2026-08-27
---

# The Codex guards were not running, in two independent ways

Asked what else was keeping KERNEL from working on Codex the way it works on Claude Code.
The answer was not a parity gap. Two of the safety gates were off.

Findings, evidence and repro: `_meta/reports/codex-parity-audit-2026-08-27.md`.
Code: PR #230, merged to main as `2c5ccb5`. Do not restate either here.

## What this adds beyond the diff

**Both bugs were invisible by construction, and both had a cheap check nobody ran.**

The scanner bug had a symptom sitting in the repo for six weeks: 744 rows in
`_meta/logs/actions.jsonl` with an empty `file` field. Nobody read a log field that was empty on
purpose-looking data. The check that would have caught it is the one that eventually did: capture
one real payload instead of reasoning about its shape.

The trust bug had a symptom too. Three instrumented runs produced nothing, and the honest response
was to write "unexplained" in the report rather than guess. The diagnosis came from applying a
fact already established elsewhere in the same session (project hooks carry trusted_hash entries)
to a place I had assumed was exempt (plugin hooks). The assumption was never tested; I had grepped
for `plugins/cache` in the trust keys, found zero, and concluded plugins need no trust. The keys
are named by plugin, not by path. **A negative grep is evidence about the pattern, not the world**
(root runtime rule 6b, fifth face), and it cost an hour.

**The tests asserted an invention and stayed green.** Two Codex apply_patch tests built their
payload as `tool_input.patch`, a shape codex-cli has never sent. That is the third occurrence of
this species in this repo: `CODEX_PLUGIN_ROOT` (#191) invented a variable name, `measure_ambient`
invented what plugin users load, and these invented a payload. Every one passed its own tests. A
test that constructs the input it asserts on proves the code agrees with the test author, and
nothing else. Cross-host payload tests need a captured fixture, not a hand-written one.

**The instrument repeated its own documented mistake.** `measure_ambient`'s docstring explains at
length that it once charged this repo's CLAUDE.md to plugin users, and pins a test against that
exact regression. It now runs `session-start.sh` against the live repo and charges plugin users
for our git log, our agentdb learnings, our active contract and our code map. Pinning the specific
past error did not prevent the general one. Not fixed here, and deliberately not papered over by
raising the budget.

## Also changed, outside the repo

- `~/.codex-cli/config.toml`: `writable_roots` repointed off `~/Documents/Vaults`, a symlink that
  codex 0.150.1 refuses. Every sandboxed Codex write in the Vaults had been failing since the
  symlink appeared on 2026-08-24.
- `~/.codex-cli/config.toml`: 11 plugin hook trust hashes copied from `~/.codex`. Backup at
  `config.toml.bak-20260827`.

## Still open

The Vaults' own `.codex/hooks.json` was edited earlier in this session, which invalidated its
trust hashes. Those guards need one interactive Codex session to re-approve. The plugin side was
fixable by copying hashes between homes; the project side needs a human.

The fix is on main but not in the installed caches. Until a release ships, both
`~/.codex/plugins` and `~/.codex-cli/plugins` still carry the broken parse.
