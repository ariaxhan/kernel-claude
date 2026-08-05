# Installing KERNEL

The short version is on the [README](../README.md) first screen. This page is the full
reference: every supported surface, every install path, and what to check when one fails.

## Requirements

Git, SQLite 3, `jq`, Python 3, and Bash. `scripts/kernel-setup.sh` checks all five and
names the missing ones before it writes anything.

## Supported surfaces

- Claude Code in a terminal.
- Claude Code Desktop local and SSH sessions. Remote sessions do not support plugins.
- Claude Code in VS Code, which uses the same plugin configuration and may ask for a
  restart after changes.
- Codex CLI and the Codex app through Codex's legacy Claude-plugin compatibility loader.

KERNEL skills are namespaced. Claude Code invokes `/kernel:ingest`; Codex invokes
`$kernel:ingest`. Cursor and Claude chat Personal plugins are not supported installation
targets here.

KERNEL 8 intentionally does not ship a native `.codex-plugin` manifest yet. Claude's
explicit-only skill marker and Codex's native plugin validator currently disagree; keeping
the compatibility loader preserves the safety rule instead of quietly making side-effecting
skills start on their own. The shared `hooks/hooks.json` is regression-tested against both
loaders.

## Claude Code, from a shell

The fastest path, and the one the README documents:

```bash
claude plugin marketplace add ariaxhan/kernel-claude
claude plugin install kernel@kernel-marketplace
~/.claude/plugins/marketplaces/kernel-marketplace/scripts/kernel-setup.sh
```

If you set `CLAUDE_CONFIG_DIR`, the marketplace clone lives under that directory instead of
`~/.claude`.

## Claude Code, from inside a session

The same three steps, using slash commands and the `init` skill:

```text
/plugin marketplace add ariaxhan/kernel-claude
/plugin install kernel@kernel-marketplace
/reload-plugins
/kernel:init
```

`/kernel:init` is an explicit setup operation. It shows the detected Vaults path and asks
before creating directories or links. It does the same work as `scripts/kernel-setup.sh`,
but an agent performs each step and reports it, so it takes a couple of minutes and two
turns rather than a few seconds. Use it when you want to watch the reasoning; use the
script when you want to be finished.

## Codex CLI or app

In a terminal:

```bash
codex plugin marketplace add ariaxhan/kernel-claude
codex plugin add kernel@kernel-marketplace
```

Restart the Codex session or app after installation. Verify with:

```bash
codex plugin list
```

Then explicitly invoke `$kernel:init`; use `$kernel:help` for the Codex skill index.

## What setup writes

Detection order for the Vaults directory: a valid `KERNEL_VAULTS`, then
`~/Documents/Vaults`, `~/Vaults`, `~/Downloads/Vaults`, then `~/Documents/Vaults` as the
reported fallback. Pass `--vaults PATH` to `kernel-setup.sh` to choose explicitly.

Directories created when absent:

```text
$VAULTS/_meta/agentdb
$VAULTS/_meta/research
$VAULTS/_meta/plans
$VAULTS/_meta/handoffs
$VAULTS/_meta/checkpoints
$VAULTS/_meta/retrospectives
$VAULTS/_meta/agents
$VAULTS/_meta/logs
$VAULTS/.claude/kernel
$VAULTS/.local/bin
```

Three helper links:

```text
$VAULTS/.local/bin/agentdb           -> $CACHE/current/orchestration/agentdb/agentdb
$VAULTS/.claude/kernel/orchestration -> $CACHE/current/orchestration
$VAULTS/.claude/kernel/hooks         -> $CACHE/current/hooks
```

Missing links may be created. Correct links are left alone. Recognizable numbered KERNEL
links may be repaired. A regular file, directory, malformed link, or unrelated link is
preserved and stops setup with an actionable message. Setup never force-replaces a link and
never edits a shell startup file.

## Verify

`kernel-setup.sh` verifies itself: it writes a learning to AgentDB and reads it back before
it reports success, and exits non-zero if either half fails.

To check by hand afterwards, use the absolute path so the result does not depend on `PATH`
or on which directory you are standing in:

```bash
"$VAULTS/.local/bin/agentdb" status
readlink "$VAULTS/.local/bin/agentdb"
readlink "$HOME/.claude/plugins/cache/kernel-marketplace/kernel/current"
```

Two things that trip people up here:

- The `current` selector does not exist immediately after `plugin install`. It is created by
  setup or by the first session start. Checking it before then reports nothing, which is not
  a failure.
- Bare `agentdb status` resolves its database by walking up from the working directory, so
  it can report a different database than the one you just created. Use the absolute path
  above, set `AGENTDB_ROOT="$VAULTS"`, or run from inside the Vaults directory.

## Putting `agentdb` on your PATH

Optional. Setup prints the exact line; nothing edits your shell config for you.

```bash
export PATH="${KERNEL_VAULTS:-$HOME/Documents/Vaults}/.local/bin:$PATH"
```

## Running from a checkout

For development, or to try a branch without installing:

```bash
git clone https://github.com/ariaxhan/kernel-claude.git
cd kernel-claude
./scripts/kernel-setup.sh
claude --plugin-dir ./
```

With no installed cache present, setup selects the checkout as the runtime. See
[contributing](contributing.md).
