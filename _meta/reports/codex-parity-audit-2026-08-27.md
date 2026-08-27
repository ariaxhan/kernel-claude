---
type: audit-report
status: complete
created: 2026-08-27
---

# ⛔ KERNEL on Codex: the secret scanner was reading a key Codex never sends

Audit of kernel-claude 9.6.1 against codex-cli 0.150.1, 2026-08-27.
Eight findings. Three were live safety holes: a secret scanner reading the wrong key, every
headless lane running with its guards untrusted, and Codex unable to write in the Vaults at all.
All three fixed and verified.
One thing everyone assumes is broken turns out to be fine.

| # | Finding | Consequence | State |
|---|---|---|---|
| 1 | `tool_input.patch` is not what Codex sends | Secret scanner and write allowlist scanned nothing on Codex | ✅ fixed |
| 2 | Codex reads `hooks/hooks.json`, not the root `hooks.json` | The Codex-tuned manifest has never taken effect | 📋 recorded, needs its own change |
| 3 | `writable_roots` pointed at a symlink | Every sandboxed Codex write in the Vaults failed | ✅ fixed |
| 4 | 11 plugin hooks untrusted under `~/.codex-cli` | Every codex-lane ran with no destructive-command guard and no secret scanner | ✅ fixed |
| 5 | `agents/*.md` is a Claude-only surface | All 10 kernel agents absent on Codex | ✅ documented |
| 6 | Project hooks need per-hook trust; edits revoke it | Silent, and a headless run cannot re-grant it | ✅ documented |
| 7 | `[features] hooks = true` is required, off by default | A default Codex install runs zero guards, silently | ✅ documented |
| 8 | Four supported events unbound | PostCompact, SubagentStart, SubagentStop, Interrupt | ✅ recorded |

Non-finding, checked on purpose: Claude-shaped matchers (`Bash`, `Write|Edit`) are **not** dead on Codex.

---

## 1. The secret scanner was reading the wrong key ✅ fixed

`detect-secrets.sh` carried this comment and this parse:

```bash
# Codex maps those hook matchers to apply_patch and sends the complete patch in tool_input.patch.
CONTENT=$(... if (.tool_input.patch | type) == "string" then ... )
[ -z "$CONTENT" ] && exit 0
```

The assumption was wrong. Here is the live payload, captured from codex-cli 0.150.1 by
temporarily instrumenting the installed plugin's `log-write.sh` and running one real session:

```json
{
  "hook_event_name": "PostToolUse",
  "tool_name": "apply_patch",
  "tool_input": {
    "command": "*** Begin Patch\n*** Add File: /abs/path.md\n+PROBE5\n*** End Patch"
  }
}
```

`command`, not `patch`. One key name. The parse yielded empty, `[ -z "$CONTENT" ]` exited 0, and
nothing was scanned. Same blindness in `guard-config.sh` (the write allowlist), `common.sh`
(`kernel_hook_file_records`) and everything downstream of it: `warn-hardcoded.sh`,
`validate-structure.sh`, `validate-json-schema.sh`, `log-write.sh`, `capture-error.sh`.

<details><summary>How long it was broken, and why nothing noticed</summary>

`_meta/logs/actions.jsonl` holds 744 recorded `apply_patch` hook fires between 2026-07-14 and
today. The extracted file path is empty in every one:

```
{"timestamp":"2026-08-27T05:38:45Z","tool":"apply_patch","file":""}
```

Six weeks of a safety gate failing open, and its only visible symptom was an empty string in a
log field. `tests/run-tests.sh` already had two Codex apply_patch tests. Both built their payload
as `{tool_input:{patch:$patch}}` — the shape Codex never sends. They asserted the invention and
stayed green, which is the same failure as the `CODEX_PLUGIN_ROOT` incident in #191.

</details>

**Fix.** All three readers now accept `tool_input.command`, and only when it opens with
`*** Begin Patch`, because a shell tool puts a command line in that same key.

Proved by breaking it on purpose, through the real payload shape:

| case | pre-fix | post-fix |
|---|---|---|
| AWS key in a Codex apply_patch | rc=0, sailed through | **rc=2, blocked** |
| clean Codex apply_patch | rc=0 | rc=0 |
| `.git/hooks/pre-commit` write, Codex shape | rc=0, allowed | **rc=2, blocked** |
| ordinary doc write, Codex shape | rc=0 | rc=0 |
| `echo not-a-patch` in a Bash `command` | n/a | rc=0, not parsed as a patch |

Five regression tests added, all asserting the `command` shape. The old `.patch` tests stay as
the tolerated fallback.

## 2. The Codex manifest is never loaded 📋

Every Codex session prints this, and it is the whole proof:

```
clamping SessionEnd hook timeout to 3s in <plugin>/9.6.1/hooks/hooks.json
```

`hooks/hooks.json` is the **Claude** manifest and declares `210`. The root `hooks.json` is the
**Codex** one and already declares `3`. Codex clamped the 210, so Codex read the Claude file.
Commit `1264554` ("stop declaring a SessionEnd timeout the host overrules") fixed the root file;
the warning has fired every session since.

<details><summary>The obvious fix makes it worse. Measured, twice.</summary>

The plugin-json spec inside the codex binary lists a `hooks` field and says path values are
"supplemented on top of default component discovery; they do not replace defaults."

Measured on 0.150.1, A/B, one apply_patch per run, counting `log-write` rows:

| `.codex-plugin/plugin.json` | rows added |
|---|---|
| no `hooks` key (control) | **1** |
| `"hooks": "./hooks.json"` | **0** |
| `"hooks": "./hooks.json"`, repeat | **0** |
| back to no key (control) | **1** |

Declaring it did not supplement, and did not switch files either: PostToolUse stopped firing
entirely. **Do not add the declaration.**

</details>

The real fix is one manifest at `hooks/hooks.json` serving both hosts, which means deleting the
root file, changing the generator, and updating ~15 tests that reference it. That is its own
change. Left undone deliberately; the measurement is recorded in `governance/hosts.json` so the
next attempt starts from evidence.

The two manifests differ in exactly two entries: `PostToolUseFailure`/`capture-error.sh`
(Claude only, harmlessly ignored by Codex) and the SessionEnd timeout. So the standing cost today
is a warning line and a dishonest record, not lost behaviour.

## 3. Codex could not write anywhere in the Vaults ✅ fixed

```
UnsupportedOperation("writable root /Users/slowember/Documents/Vaults contains symlink
component; symlinked writable roots are not supported")
```

`~/.codex-cli/config.toml` set `writable_roots = ["/Users/slowember/Documents/Vaults"]`.
`~/Documents/Vaults` became a symlink to `~/Developer/Vaults` on 2026-08-24, and codex 0.150.1
refuses symlinked writable roots. Every sandboxed Codex write in the Vaults has failed since.

Repointed to the real path. A lane that failed on this before the change created its file after it.

## 4. Every headless Codex lane ran with the guards switched off ✅ fixed

Same command, same repo, only `CODEX_HOME` differs:

| CODEX_HOME | hooks ran |
|---|---|
| `~/.codex` | yes |
| `~/.codex-cli` | no, across three instrumented runs |

Not a mystery once finding 6 is applied to plugins as well as projects. Plugin hooks are trusted
individually too, keyed by plugin rather than by path:

```toml
[hooks.state."kernel@kernel-marketplace:hooks/hooks.json:pre_tool_use:2:1"]
```

(That key is also independent proof of finding 2: Codex names `hooks/hooks.json`, never the root
manifest.)

`~/.codex` had 29 of Kernel's hooks trusted. `~/.codex-cli` had 18. The 11 it had never been asked
about, and therefore silently skipped:

| key | hook |
|---|---|
| `pre_tool_use:0:1` | **guard-bash.sh** — the destructive-command fence |
| `pre_tool_use:2:1` | **detect-secrets.sh** — the secret scanner |
| `pre_tool_use:2:2` | validate-structure.sh |
| `pre_tool_use:2:3` | warn-hardcoded.sh |
| `pre_tool_use:2:4` | verdict-gate.sh |
| `pre_tool_use:3:0` | guard-context.sh |
| `post_tool_use:2:0` | log-write.sh |
| `post_tool_use:2:1` | validate-json-schema.sh |
| `user_prompt_submit:0:1` | route-request.sh |
| `user_prompt_submit:0:2` | post-compact-restore.sh |

`codex-lane.sh` forces `CODEX_HOME=~/.codex-cli` on every headless lane, and a headless run can
never grant the approval it is missing. So all delegated Codex work has been running with no
destructive-command guard and no secret scanner, and the mechanism guaranteed it could never
fix itself.

**Fix.** The trusted_hash is over hook content, and both homes carry the identical plugin at the
identical version, so the 11 entries transfer. Copied from `~/.codex`, backup at
`~/.codex-cli/config.toml.bak-20260827`.

Verified live, after the copy: a `codex exec` under `~/.codex-cli` printed `hook: PreToolUse
Completed` and appended a log-write row, where three runs before the copy produced neither.

## 5. Kernel's agents do not exist on Codex ✅ documented

`agents/*.md` at plugin root is a Claude Code surface. In a Codex plugin `agents/` means
`agents/openai.yaml`, per-skill UI metadata and invocation policy, confirmed in the binary
alongside `.codex-plugin/plugin.json` in the same component-discovery string.

Codex has native multi-agent spawn but no plugin-level agent definitions to point it at. So
surgeon, adversary, blind-evaluator, deep-diver and the other six are Claude-only, and the tier-3
`contract → surgeon → adversary` flow has no Codex implementation. Independent verification on
Codex means a human or a second CLI.

Already correct, so nobody re-fixes it: all six no-ambient skills ship `agents/openai.yaml` with
`allow_implicit_invocation: false`, enforced at `tests/run-tests.sh:1220`.

## 6. Editing a project `.codex/hooks.json` silently revokes its trust ✅ documented

```toml
[hooks.state."/Users/slowember/Documents/Vaults/.codex/hooks.json:pre_tool_use:0:0"]
trusted_hash = "sha256:..."
```

Key is `<path>:<snake_case_event>:<group_index>:<hook_index>`. Change a command or insert one and
the hash no longer matches; the hook stops running until a human re-approves it interactively.

Observed live: a lane wrote a file in the Vaults today and the project's PostToolUse hook did not
fire, because that file was edited earlier in the session. **The eight guards added to
`.codex/hooks.json` today need one interactive Codex session before they do anything.**

The 32 stored entries also include `subagent_start` and `subagent_stop`, events the current file
does not bind, so entries go stale and prove nothing.

## 7. Hooks are off unless a feature flag is on ✅ documented

```toml
[features]
hooks = true
```

Off by default. Without it Codex parses nothing and says nothing: no error, no warning, every
guard simply absent. Nothing in Kernel's install path checks for it.

## 8. Four supported events are unbound ✅ recorded

Lifecycle enum, extracted contiguous from the binary:

```
PreToolUse PermissionRequest PostToolUse PreCompact PostCompact
SessionStart SessionEnd UserPromptSubmit SubagentStart SubagentStop Stop Interrupt
```

`governance/hosts.json` omitted `PostCompact`, `SubagentStart` and `Interrupt`; now added with
evidence. `PostCompact` is the notable miss, the Vaults host config already uses it to reconcile a
context checkpoint after compaction and the plugin does not.

---

## The non-finding

The obvious suspicion is that Claude tool-name matchers never match Codex tool names
(`exec_command`, `apply_patch`), leaving most hooks dead. **They are not dead.**

`log-write.sh` is bound `PostToolUse` / `Write|Edit` in both manifests, is the only writer of
`actions.jsonl`, and recorded 744 events whose own `tool_name` field reads `apply_patch`. A
`Write|Edit` matcher fired for `apply_patch`, 744 times. Of those 744, exactly one
timestamp+file pair repeats, which is also how we know Codex loads one manifest and not both.

The mechanism is unexplained. Do not "fix" the matchers without measuring first.

---

## What changed

| File | Change |
|---|---|
| `hooks/scripts/common.sh` | `kernel_hook_file_records` reads `tool_input.command` when it is a patch |
| `hooks/scripts/detect-secrets.sh` | same, for content |
| `hooks/scripts/guard-config.sh` | same, for paths |
| `tests/run-tests.sh` | 5 regression tests on the real Codex shape, and the two guard hash pins moved with a reason |
| `governance/hosts.json` | read path, declaration measurement, feature flag, trust model, agents, 3 events |
| `scripts/generate-adapters.py` | renders those operator-facing facts |
| `docs/kernel-9/HOST-CAPABILITIES.md` | regenerated |
| `~/.codex-cli/config.toml` | `writable_roots` repointed off the symlink |

## The ambient budget test, diagnosed but not fixed

`test_contributor_ambient_within_budget` is red, and was red before this work. Both ratchets are
over: plugin 4975 against 4800, contributor 12157 against 11000.

It is not actionable as written, because it is not deterministic. `measure_ambient.hook_cost`
executes `hooks/scripts/session-start.sh` with `cwd` set to **this live repo** and counts the
bytes it prints. That output carries the branch, the uncommitted file count, recent commit
subjects, the agentdb learning count, the active contract, blockers, pending review and the code
map. Three consecutive runs measured 8036, 8005 and 8005 bytes; the number moves when the tree
gets dirty or a learning is written.

So the gate charges plugin users for *this repo's accumulated state*. That is the same error its
own docstring documents and pins a test against, committed a second time in a different place:
last time it was CLAUDE.md charged to plugin users, this time it is our git log and our agentdb.

The honest fix is to measure the hook against a fixed fixture repo so the number means something,
then re-derive the ratchet from that. That is a measurement-design change with its own review, so
it is written down here rather than done in passing. **The budgets were not raised.**

## Next

1. **Finding 2.** Collapse to one manifest at `hooks/hooks.json`; delete the root file, update the
   generator and the ~15 tests that reference it.
2. Re-approve `.codex/hooks.json` in an interactive Codex session so today's Vaults guards arm.
   The plugin-side equivalent was fixable by copying hashes; the project-side one needs a human.
3. Make the ambient measurement deterministic, then set the ratchet from the new number.
4. Ship a release so the finding 1 fix reaches the installed plugin. Until then the caches at
   `~/.codex/plugins` and `~/.codex-cli/plugins` still carry the broken parse.
