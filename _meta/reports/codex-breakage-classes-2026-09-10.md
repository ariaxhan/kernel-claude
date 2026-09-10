---
type: report
status: active
created: 2026-09-10
---

# How KERNEL keeps breaking Codex, and what now stops it

## The record

| When | Break | Class |
|---|---|---|
| #177 / #178 (08-07) | "host-agnostic plugin root" shipped, then reverted the next day | invented contract |
| #191 (08-09) | `${CODEX_PLUGIN_ROOT}` expanded to empty on Codex; every hook ran an absolute path off `/` and exited 127. Dead on every event since the Kernel 9 adapter shipped. | invented contract |
| #193 / #199 (08-09) | KERNEL declared a `SessionEnd` timeout Codex hard-clamps to 3s | declared what the host overrules |
| 9.2.1 (08-09) | Codex red-suite detection lost to that ceiling; documented rather than fixed | capability gap |
| #230 / 9.6.2 (08-27) | detect-secrets read `tool_input.patch`; Codex sends `tool_input.command`. Every Codex write waved through. | wrong payload shape |
| 9.6.2 | `.codex-plugin/plugin.json` left at 9.4.0 by the 9.5.0 release | pin drift |
| 9.6.x | `[context] ...` hook output: square brackets are syntax in Codex hook output, not decoration | wrong output syntax |
| 9.6.6 (08-28) | tagging a release auto-upgraded the Codex plugin cache; hooks exited 127 in every open session | release-time cache swap |

Five distinct classes, one shared property: **the suite stayed green through every one of them.**
Each break was invisible because the tests only ever sent the Claude payload, to a host whose
capability was written down from a reading rather than a measurement.

## What already guards each class

- invented contract: `governance/hosts.json` carries `shared_plugin_root_var` plus the evidence
  that both hosts substitute it, and `plugin_root_var` per host for everything outside the shared file.
- host overrules: `hook_timeout_ceilings_seconds` with captured startup-warning evidence.
- pin drift: `test_version_sync_all`.
- release cache swap: the vault `release-guard` hook, which refuses a bump or tag while Codex is live.
  It fired today at 208 processes and is the reason 9.11.0 is not tagged.
- wrong payload shape: four hand-written detect-secrets tests, added reactively after #230.

That last row was the hole. Nothing made the NEXT hook author send a Codex payload.

## What changed today

1. `hooks/gates.json` gains `host_shapes` on every hook bound to a tool event: the hosts whose
   payload it has actually been proven against.
2. `tests/corpus/run-corpus.py` gains check 3, HOST SHAPES: a declared host with no corpus case
   sending its payload fails the run. Proven red by deleting the Codex cases (rc=1) and green by
   restoring them (rc=0).
3. Codex cases added for detect-secrets (block + allow on the real `apply_patch` shape),
   auto-approve-safe, and normalize-write.
4. `normalize-write.py` exits silently on the Codex `apply_patch` shape, and
   `governance/hosts.json` records `honors_pretooluse_updated_input: false` for Codex with the
   reason: no capture proves Codex applies `updatedInput`. Rewriting a payload on an unverified
   claim is precisely what `CODEX_PLUGIN_ROOT` did. Closing it needs a live codex-cli capture,
   not a reading.

## Still true, and stated rather than implied

- `agents/*.md` has no Codex equivalent: all ten agents are Claude-only, and the tier-3
  contract -> surgeon -> adversary flow has no Codex implementation.
- Codex has no AskUserQuestion equivalent.
- The normalizer repairs writes on Claude Code only. On Codex the write lands exactly as the
  model wrote it, which is the pre-existing behavior, not a regression.
