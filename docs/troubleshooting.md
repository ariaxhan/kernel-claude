# Troubleshooting and recovery

**Skills missing after update.** Run `/reload-plugins`; start a new session if prompted.

**Codex reports `unknown field version` for `hooks/hooks.json`.** The session is still loading
an older cached KERNEL release. Upgrade the marketplace, then restart Codex so it reads
KERNEL 8. Do not hand-edit the numbered cache.

**Helper-link warning.** Inspect the exact path printed by KERNEL, then run
`scripts/kernel-setup.sh` or `/kernel:init`. Setup will not overwrite a regular file,
directory, or unrelated link without a separate manual decision.

**Wrong Vaults.** Set `KERNEL_VAULTS` to the existing Vaults root before setup or startup, or
pass `--vaults PATH` to `kernel-setup.sh`.

**`agentdb: command not found`.** `$VAULTS/.local/bin` is not on your `PATH`. Either use the
absolute path `"$VAULTS/.local/bin/agentdb"`, or add the export line setup printed to your
shell config. Nothing edits your shell config for you.

**`agentdb status` reports the wrong database.** Bare `agentdb` resolves its database by
walking up from the working directory. Set `AGENTDB_ROOT="$VAULTS"`, run from inside the
Vaults directory, or call the absolute helper-link path.

**`readlink .../kernel/current` prints nothing.** The `current` selector is created by setup
or by the first session start, not by `plugin install`. Before then there is nothing to read,
which is expected rather than a failure.

**`kernel: refusing invalid runtime root`.** The runtime root was given as the `current`
symlink rather than the directory it points to; validation rejects symlinks at its first
check. Resolve the path first (`python3 -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$CACHE/current"`),
or let `scripts/kernel-setup.sh` do it, which is what it does.

## Reinstall

Only after update and reload have both failed.

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

Restart Codex after reinstalling. `remove` deletes KERNEL's installed cache entry; it does not
remove the marketplace or project data.

Do not remove the marketplace or clear `~/.claude/plugins/cache` as routine maintenance. Those
are destructive recovery steps with wider effects.

## Manifest runtime

```text
kernel-manifest validate | latest | divergence | preflight | compile | resume | activate | deactivate
```
