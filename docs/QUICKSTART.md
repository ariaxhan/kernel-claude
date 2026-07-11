# KERNEL 8 setup guide

KERNEL adds durable memory, resumable JSON state, engineering workflows, and separate
verification roles to Claude Code. It supports Claude Code Terminal, Desktop local/SSH
sessions, and VS Code. Plugin skills always use the `kernel:` namespace.

## Install

Requirements: Git, SQLite 3, `jq`, Python 3, and Bash.

```text
/plugin marketplace add ariaxhan/kernel-claude
/plugin install kernel@kernel-marketplace
/reload-plugins
/kernel:init
```

Init asks you to confirm the Vaults path before it writes. Detection checks a valid
`KERNEL_VAULTS` first, then `~/Documents/Vaults`, `~/Vaults`, and
`~/Downloads/Vaults`. It creates missing KERNEL data directories and three helper
links; it does not move `~/.claude` or overwrite user-owned paths.

Verify in a new session:

```bash
agentdb status
readlink "$HOME/.claude/plugins/cache/kernel-marketplace/kernel/current"
```

Then use `/kernel:help`.

## Daily workflow

1. `/kernel:ingest` starts or resumes work from repository truth and AgentDB.
2. KERNEL chooses direct work or a contract based on reversibility, quiet failure
   risk, and blast radius—not file count.
3. `/kernel:validate` checks the result. `/kernel:handoff` creates a bounded JSON
   resume point when another session must continue.

Common skills:

- Work: `/kernel:ingest`, `/kernel:diagnose`, `/kernel:dream`
- Checks: `/kernel:validate`, `/kernel:review`, `/kernel:tearitapart`
- State: `/kernel:checkpoint`, `/kernel:handoff`, `/kernel:retrospective`
- Setup/reference: `/kernel:init`, `/kernel:help`

## Update from 7.23.0

```text
/plugin marketplace update kernel-marketplace
/plugin update kernel@kernel-marketplace
/reload-plugins
```

Start a new session if Claude Code cannot reload a component; VS Code may request a
restart. Startup validates the loaded KERNEL runtime, advances `current` only forward,
and repairs old numbered KERNEL helper links. Missing links stay missing. Files,
directories, malformed links, and unrelated links are preserved with a warning.

The update does not replace project files, AgentDB, manifests, or receipts. KERNEL 8
uses canonical JSON state and cannot promise that KERNEL 7 will resume KERNEL 8 state.
`/kernel:design` is now `/kernel:frontend`; the old command-file implementation layer
was removed.

For a session-only rollback:

```bash
git worktree add /path/to/kernel-claude-7.23 54a0053
claude --plugin-dir /path/to/kernel-claude-7.23
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
- Reinstall only after update/reload fails:

```text
/plugin uninstall kernel@kernel-marketplace --keep-data
/plugin install kernel@kernel-marketplace
/reload-plugins
```

Contributor setup uses `claude --plugin-dir ./`; never replace a numbered installed
cache directory with a development symlink.

See [README](../README.md), [8.0 migration](MIGRATION-8.md), and
[KERNEL instructions](../CLAUDE.md).
