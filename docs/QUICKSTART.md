# KERNEL 8 setup guide

KERNEL adds durable memory, resumable JSON state, engineering workflows, and separate
verification roles to Claude Code. It supports Claude Code Terminal, Desktop local/SSH
sessions, and VS Code. Plugin skills always use the `kernel:` namespace.

Codex CLI and the Codex app can load KERNEL through their Claude-marketplace
compatibility loader. KERNEL 8 does not claim native Codex-manifest support because
the native validator does not preserve Claude's explicit-only marker for the four
side-effecting skills. The compatibility path keeps that safety rule intact.

## Install

Requirements: Git, SQLite 3, `jq`, Python 3, and Bash.

Claude Code:

```text
/plugin marketplace add ariaxhan/kernel-claude
/plugin install kernel@kernel-marketplace
/reload-plugins
/kernel:init
```

Codex CLI or app:

```bash
codex plugin marketplace add ariaxhan/kernel-claude
codex plugin add kernel@kernel-marketplace
```

Restart Codex after installation and verify with `codex plugin list`. Run KERNEL init
explicitly from the installed skill before expecting host helper links.

Init asks you to confirm the Vaults path before it writes. Detection checks a valid
`KERNEL_VAULTS` first, then `~/Documents/Vaults`, `~/Vaults`, and
`~/Downloads/Vaults`. It creates missing KERNEL data directories and three helper
links; it does not move `~/.claude` or overwrite user-owned paths.

Verify in a new session:

```bash
agentdb status
readlink "$HOME/.claude/plugins/cache/kernel-marketplace/kernel/current"
```

Then use `/kernel:help` in Claude Code or `$kernel:help` in Codex.

## Daily workflow

1. `/kernel:ingest` starts or resumes work from repository truth and AgentDB.
2. KERNEL chooses direct work or a contract based on reversibility, quiet failure
   risk, and blast radius—not file count.
3. `/kernel:validate` checks the result. `/kernel:handoff` creates a bounded JSON
   resume point when another session must continue.

Common skills below use Claude Code syntax. In Codex, replace the leading `/` with
`$`, for example `$kernel:validate`.

Common skills:

- Work: `/kernel:ingest`, `/kernel:diagnose`, `/kernel:dream`
- Checks: `/kernel:validate`, `/kernel:review`, `/kernel:tearitapart`
- State: `/kernel:checkpoint`, `/kernel:handoff`, `/kernel:retrospective`
- Setup/reference: `/kernel:init`, `/kernel:help`

## Safe resumes and context limits

Handoffs and checkpoints are canonical JSON: the JSON file is the source of truth,
not a Markdown summary or an old YAML file. On resume, KERNEL discovers the newest
state, validates it, checks whether the repository changed, runs only typed preflight
checks, compiles the allowed context with a receipt, activates its context policy,
and resumes at the recorded operation. Changed inputs invalidate inherited phases
instead of silently treating stale work as complete.

Context policies can be `advisory`, `bounded`, or `sealed`. Bounded mode records extra
file loads in the context receipt. Sealed mode makes hooks block forbidden paths.
Receipts record selected inputs, integrity hashes, and budget status so the next
session can show what it actually loaded.

The underlying runtime commands are:

```text
kernel-manifest validate | latest | divergence | preflight | compile | resume | activate | deactivate
```

Most users should call `/kernel:ingest` (or `$kernel:ingest` in Codex) and let it run
that sequence. A manifest that fails validation or exceeds its maximum context budget
is a stop condition, not permission to fall back to the whole conversation.

## Update from 7.23.0

Claude Code:

```text
/plugin marketplace update kernel-marketplace
/plugin update kernel@kernel-marketplace
/reload-plugins
```

Codex:

```bash
codex plugin marketplace upgrade kernel-marketplace
```

Restart Codex after upgrading. The marketplace upgrade refreshes an installed plugin
cache too; Codex has no separate `plugin update` command.

Start a new session if Claude Code cannot reload a component; VS Code may request a
restart. Startup validates the loaded KERNEL runtime, advances `current` only forward,
and repairs old numbered KERNEL helper links. Missing links stay missing. Files,
directories, malformed links, and unrelated links are preserved with a warning.

The update does not replace project files, AgentDB, manifests, or receipts. KERNEL 8
uses canonical JSON state and cannot promise that KERNEL 7 will resume KERNEL 8 state.
`/kernel:design` is now `/kernel:frontend`; the old command-file implementation layer
was removed.

## Codex behavior boundaries

Codex loads all 33 KERNEL skills, with explicit calls written as `$kernel:<name>`.
The four side-effecting skills (`init`, `forge`, `experiment`, and `landing-page`)
also carry Codex-native policy that forbids automatic invocation.

The 15 files under `agents/` are Claude Code agent definitions. Codex does not
register them as native agents; KERNEL applies their role contracts when coordinating
available Codex subagents. Codex runs supported synchronous hooks, including
SessionStart and the write guards. It skips asynchronous command hooks and has no
plugin SessionEnd event, so finish Codex work with `$kernel:handoff` when durable
end-state is required.

For a session-only rollback:

```bash
git clone https://github.com/ariaxhan/kernel-claude.git "$HOME/kernel-claude-7.23"
git -C "$HOME/kernel-claude-7.23" checkout 54a0053
V8_SELECTOR="$HOME/.claude/plugins/cache/kernel-marketplace/kernel/current/scripts/select-runtime.sh"
"$V8_SELECTOR" "$HOME/kernel-claude-7.23"
claude --plugin-dir "$HOME/kernel-claude-7.23"
```

For an explicit helper-runtime selection:

```bash
scripts/select-runtime.sh /path/to/kernel-runtime
```

Do not clear the plugin cache or remove the marketplace as a normal update step.

## Troubleshooting

- Skills missing: `/reload-plugins`, then start a new session.
- `agentdb` missing: rerun `/kernel:init`; add the printed PATH line yourself.
- Wrong Vaults: export `KERNEL_VAULTS` to the existing root, then rerun init.
- Host-link warning: inspect the exact path. Init refuses regular files, directories,
  malformed links, and unrelated links instead of replacing them.
- Codex `unknown field version` warning for `hooks/hooks.json`: restart Codex after
  upgrading to KERNEL 8; the warning means Codex is still reading a 7.23 cache.
- Reinstall only after update/reload fails:

Claude Code:

```text
/plugin uninstall kernel@kernel-marketplace --keep-data
/plugin install kernel@kernel-marketplace
/reload-plugins
```

Codex:

```bash
codex plugin marketplace upgrade kernel-marketplace
codex plugin remove kernel@kernel-marketplace
codex plugin add kernel@kernel-marketplace
```

Restart Codex after reinstalling. Do not remove the marketplace or project data.

Contributor setup uses `claude --plugin-dir ./`; never replace a numbered installed
cache directory with a development symlink.

See [README](../README.md), [8.0 migration](MIGRATION-8.md), and
[KERNEL instructions](../CLAUDE.md).
