# Upgrading and rolling back

## Upgrading from 7.23.0

KERNEL 8 is a major release. Update explicitly:

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

Restart Codex after the upgrade. Current Codex refreshes the installed plugin cache as part
of the marketplace upgrade; there is no `codex plugin update` command.

Start a new session if Claude Code says a component or monitor could not reload. VS Code may
show a restart banner.

On startup, KERNEL validates the plugin Claude Code actually loaded and advances its
`current` runtime selector only forward. It repairs exactly three old KERNEL links when
their link text proves they point to a numbered `kernel-marketplace/kernel/<version>`
runtime:

- `$KERNEL_VAULTS/.local/bin/agentdb`
- `$KERNEL_VAULTS/.claude/kernel/orchestration`
- `$KERNEL_VAULTS/.claude/kernel/hooks`

Missing paths stay missing. Regular files, directories, malformed links, and unrelated links
are never replaced; KERNEL prints a recovery warning instead. Updating does not replace
project files, existing manifests, receipts, or AgentDB. Hooks and explicit init still write
session records and setup files in the selected Vaults.

## Breaking changes in 8

- Live handoffs, checkpoints, retrospectives, and context receipts use canonical JSON.
  Historical YAML remains history, but KERNEL 8 does not resume it as live state.
- The old command-file implementation layer is gone. Workflows are skills and keep their
  namespaced invocations.
- `/kernel:design` became `/kernel:frontend` to avoid a native-name collision.
- A KERNEL 7 session may keep using its loaded 7.23 code until reloaded or restarted. Old
  cache directories may remain temporarily; their presence does not make them active.
- KERNEL 7 may not resume state created by KERNEL 8 even though that state is preserved.

Full detail: [8.0 migration](MIGRATION-8.md).

## Roll back without deleting data

From any directory, clone the repository and check out the verified 7.23 release commit. Use
the installed KERNEL 8 selector before starting the older plugin:

```bash
git clone https://github.com/ariaxhan/kernel-claude.git "$HOME/kernel-claude-7.23"
git -C "$HOME/kernel-claude-7.23" checkout 54a0053
V8_SELECTOR="$HOME/.claude/plugins/cache/kernel-marketplace/kernel/current/scripts/select-runtime.sh"
"$V8_SELECTOR" "$HOME/kernel-claude-7.23"
claude --plugin-dir "$HOME/kernel-claude-7.23"
```

To deliberately select a validated local or cached runtime for the helper links:

```bash
"$HOME/.claude/plugins/cache/kernel-marketplace/kernel/8.0.2/scripts/select-runtime.sh" /path/to/kernel-claude-7.23
```

That explicit selection may move `current` backward; normal old sessions cannot. It does not
convert KERNEL 8 JSON state to KERNEL 7 YAML. Do not delete the plugin cache or remove the
marketplace as a normal rollback step.

Runtime link changes clean temporary siblings on normal errors and catchable signals. An
uncatchable process kill can leave a `.kernel-tmp.*` symlink; the next matching operation
removes only KERNEL-shaped symlink residue and never a regular lookalike.
