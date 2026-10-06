# KERNEL

Current release: **9.11.0**, as declared in the [plugin manifest](.claude-plugin/plugin.json)
and [Codex manifest](.codex-plugin/plugin.json).

## For agents

If you are an agent deciding whether to install this, the machine-readable summary is
[llms.txt](llms.txt): what it is, what it adds, and when not to use it.

Claude Code (in a session, `/plugin marketplace add ariaxhan/kernel-claude` then
`/plugin install kernel@kernel-marketplace`):

```bash
claude plugin marketplace add ariaxhan/kernel-claude
claude plugin install kernel@kernel-marketplace
~/.claude/plugins/marketplaces/kernel-marketplace/scripts/kernel-setup.sh
```

Codex:

```bash
codex plugin marketplace add ariaxhan/kernel-claude
codex plugin add kernel@kernel-marketplace
```

Gemini CLI (methodology only: the 28 skills and `llms.txt` as ambient context; the hooks and
agentdb do not run on this host):

```bash
gemini extensions install https://github.com/ariaxhan/kernel-claude
```

Restart the host, then run `/kernel:help` on Claude Code or `$kernel:help` on Codex to confirm the
install and list every skill. Requires `git`, `sqlite3`, `jq`, `python3`, `bash`.

---

**Stop approving everything your AI does. It's making you less safe.**

Auto mode is the default now, and the data behind that decision is brutal: humans reviewing
per-action permission prompts caught dangerous commands 13.6% of the time; automated checks
caught 89%. People approve 97% of prompts. Attention decays to ~5% blocking after fifty
prompts. Per-action approval is a leash held by someone who stopped looking.
([Anthropic's numbers](https://claude.com/blog/auto-mode-default-in-claude-code); the
[academic result](https://arxiv.org/abs/2606.05647) is worse — 94% of developers miss
deliberate agent sabotage, and 56% accept it even after a warning.)

KERNEL combines local memory, explicit workflows, and a small set of hooks. Sessions recall
past work, record outcomes, and recover context when a request has to be repeated. The current
release scans writes for secrets and handles selected command permissions; destructive-command
blocks and one-time approval tokens described by older releases are no longer bound.
Use the host sandbox and permissions for containment, and review the verified outcome.

For people running Claude Code in auto mode on real repositories. Not for you if you want
an autonomous agent with no boundaries, or a replacement for tests, review, and reading
the diff.

## Install

```bash
claude plugin marketplace add ariaxhan/kernel-claude
claude plugin install kernel@kernel-marketplace
~/.claude/plugins/marketplaces/kernel-marketplace/scripts/kernel-setup.sh
```

Needs `git`, `sqlite3`, `jq`, `python3`, `bash`. Takes about ten seconds. Setup asks once
before it writes, and never touches your shell config.

## What you should see

Setup finishes by writing a real memory and reading it back by keyword:

```text
## Recall: KERNEL installed machine

- [pattern] KERNEL 9.11.0 installed on this machine  ↳ kernel-setup.sh completed at 2026-09-12T23:51:39Z

KERNEL is set up.
  memory:  /Users/you/Documents/Vaults/_meta/agentdb/agent.db
  agentdb: /Users/you/Documents/Vaults/.local/bin/agentdb
```

That round trip is the proof, not a status message. There is now a SQLite database on your
machine that every Claude Code session reads on start and writes on end. If setup could not
write to it or could not read it back, it exits non-zero and tells you which half failed.

Now run `claude` and type `/kernel:help`.

---

## Where things are

**[Full documentation](docs/)** covers install paths and verification, the daily loop, what
KERNEL writes to disk, the safety model, troubleshooting, upgrading, and contributing.

Go to [docs/install.md](docs/install.md) if the three commands above did not work, and
[docs/daily-use.md](docs/daily-use.md) once they did.

## What it actually does

Three things, in the order you notice them.

**Memory.** `agentdb` is a SQLite database in your Vaults directory. Sessions recall from it
before acting and write learnings at the end, so a failure you hit last week does not cost
you the same afternoon twice. Recall is FTS5 keyword search by default; local semantic search
is opt-in and adds nothing to your network. See
[docs/data-and-memory.md](docs/data-and-memory.md).

**Bounded resume.** Handoffs, checkpoints, and retrospectives are validated JSON manifests,
not prose summaries. A new session reconstructs exactly the state the manifest pins rather
than inheriting a whole conversation. The manifest CLI is
`validate | latest | divergence | preflight | compile | resume | activate | deactivate`.

**Minimal hooks.** The current runtime supplies startup context, secret detection on writes,
permission handling for selected commands, and prompt-time context recovery. These hooks
are a tripwire, not a sandbox; [docs/safety.md](docs/safety.md) describes their scope.
Manifest context policies and separate-verifier rules are conventions unless an external
workflow enforces them. This release does not bind the former command, configuration, or
context guards.

On context cost, the number you will see quoted elsewhere is wrong and this is the corrected
one. KERNEL's ambient cost to a plugin user is roughly **4,600 tokens**: about 1,900 from the
SessionStart hook and about 2,700 from skill frontmatter the host keeps visible so routing can
happen. This repo's `CLAUDE.md` is **not** part of that; your host loads your own instruction
file, not ours. An earlier target of "under 500 tokens" came from a measurement that charged our
`CLAUDE.md` to everyone, and it is withdrawn. Detail and the ratchets that now enforce it:
[docs/kernel-9/INVENTORY.md](docs/kernel-9/INVENTORY.md).

## Surfaces, and how Codex differs

Claude Code terminal, Desktop (local and SSH), and VS Code. Remote Claude Code sessions do
not support plugins.

Codex CLI and the Codex app load the same package with its native
`.codex-plugin/plugin.json` manifest:

```bash
codex plugin marketplace add ariaxhan/kernel-claude
codex plugin add kernel@kernel-marketplace
```

Restart Codex afterwards, then invoke `$kernel:init`. Skills are namespaced on both hosts:
Claude Code invokes `/kernel:help`, Codex invokes `$kernel:help`. The native Codex manifest
explicitly declares `skills/`; five setup or costly skills carry a policy forbidding implicit
invocation. Codex requires `[features] hooks = true` in its configuration to run hooks.

The current `hooks/hooks.json` binds SessionStart, PreToolUse, PermissionRequest, and
UserPromptSubmit. It does not bind SessionEnd or tool-error capture on either host; record
end-state explicitly with `agentdb write-end` or a handoff. Codex does not register KERNEL's
ten Claude Code agent definitions as native subagents. See [installation](docs/install.md)
and the [host capability report](docs/kernel-9/HOST-CAPABILITIES.md) for host support; the
checked-in hook manifest determines which supported events this release actually binds.

## Updating

Claude Code:

```text
/plugin marketplace update kernel-marketplace
/plugin update kernel@kernel-marketplace
/reload-plugins
```

Codex, where the marketplace upgrade also refreshes the installed cache:

```bash
codex plugin marketplace upgrade kernel-marketplace
```

Upgrading from 7.23, the breaking changes, and rolling back without losing data:
[docs/upgrading.md](docs/upgrading.md).

If update and reload both fail, reinstall. Claude Code takes
`/plugin uninstall kernel@kernel-marketplace --keep-data` followed by a fresh install; Codex
takes `codex plugin remove kernel@kernel-marketplace` then
`codex plugin add kernel@kernel-marketplace`. Removing the marketplace or clearing the plugin
cache is not routine maintenance.

## Rolling back

Check out the verified 7.23 release commit and point the installed selector at it:

```bash
git clone https://github.com/ariaxhan/kernel-claude.git "$HOME/kernel-claude-7.23"
git -C "$HOME/kernel-claude-7.23" checkout 54a0053
V8_SELECTOR="$HOME/.claude/plugins/cache/kernel-marketplace/kernel/current/scripts/select-runtime.sh"
"$V8_SELECTOR" "$HOME/kernel-claude-7.23"
claude --plugin-dir "$HOME/kernel-claude-7.23"
```

To select a validated runtime explicitly, call a numbered selector directly, for example
`"$HOME/.claude/plugins/cache/kernel-marketplace/kernel/8.0.2/scripts/select-runtime.sh" /path/to/runtime`.
That moves `current` backward on purpose; ordinary old sessions cannot. It selects code only
and does not convert state formats.

## Where your data lives

Everything durable goes in the selected Vaults directory: `_meta/agentdb/agent.db` for
memory, `_meta/handoffs/` and `_meta/checkpoints/` for JSON state, `_meta/logs/` for runtime
records. Detection order and the full list: [docs/data-and-memory.md](docs/data-and-memory.md).

When the active project root exactly matches the Vaults root and a shared continuity engine
with an executable host adapter is present, that service owns compaction checkpoints and
restore injection, and KERNEL's compaction paths cleanly no-op rather than adding a second
restore. Nested repositories retain KERNEL's deterministic generic fallback.

## Contributing

```bash
git clone https://github.com/ariaxhan/kernel-claude.git
cd kernel-claude
./scripts/kernel-setup.sh
claude --plugin-dir ./
./tests/run-tests.sh
```

See [docs/contributing.md](docs/contributing.md). Fix defects here and release; do not edit
an installed cache directory.

MIT licensed.
