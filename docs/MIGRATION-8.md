# Migrating from KERNEL 7.23 to 8.0

KERNEL 8 is a major release because its live state format and plugin architecture
changed. Existing data is preserved, but older code may not understand new state.

## Before updating

Commit or checkpoint current work. Note the current plugin version and run
`agentdb status`. Do not delete old manifests or cache directories.

## Update

```text
/plugin marketplace update kernel-marketplace
/plugin update kernel@kernel-marketplace
/reload-plugins
```

Start a new session if Claude Code says a monitor or component cannot reload. VS Code
may request a restart. Third-party marketplace auto-update is off by default; users
who enabled it still need to reload when prompted.

## Automatic helper migration

Claude Code installs 8.0 beside 7.23 in a versioned cache. KERNEL validates the root
Claude Code actually loaded and updates a stable `current` selector. Normal loaded
sessions can move it forward only, so an older session cannot silently downgrade a
newer one. An explicit `KERNEL_RUNTIME_ROOT` selection may move it backward for
rollback or development.

Startup examines exactly three Vaults paths: AgentDB, orchestration, and hooks. It
repairs a symlink only when the link text proves it targets the expected suffix below
`kernel-marketplace/kernel/<strict-semver>`. Broken old links can be proven lexically
and repaired. Missing paths remain missing. Regular files, directories, malformed
links, and unrelated links remain untouched and produce a recovery warning.

Replacement uses a collision-safe sibling link and an atomic rename. No updater or
rollback command deletes caches, repositories, AgentDB, manifests, receipts, project
configuration, or user Claude configuration.

## Breaking changes

- Canonical state is JSON: `kernel.handoff/v1`, `kernel.checkpoint/v1`,
  `kernel.retrospective-result/v1`, and `kernel.context-receipt/v1`. Historical YAML
  is retained as history but is not an active KERNEL 8 resume input.
- Workflow/state/validator/operator definitions now all live under `skills/`; the
  old `commands/` layer is removed. Namespaced invocations remain `/kernel:<skill>`.
- `/kernel:design` is renamed `/kernel:frontend`.
- A KERNEL 7 session can keep old code loaded until reload/restart. Cache presence is
  not active-version authority.
- KERNEL 7 may not resume KERNEL 8 JSON state. Rollback preserves files; it does not
  translate them.

Manifest CLI actions:

```text
kernel-manifest validate | latest | divergence | preflight | compile | resume | activate | deactivate
```

## Verify

```bash
agentdb status
readlink "$HOME/.claude/plugins/cache/kernel-marketplace/kernel/current"
readlink "${KERNEL_VAULTS:-$HOME/Documents/Vaults}/.local/bin/agentdb"
```

Validate a live JSON manifest and exercise its preflight/resume path before closing
the migration.

## Rollback

Session-only rollback is least invasive:

```bash
claude --plugin-dir /path/to/kernel-claude-7.23.0
```

To select a trusted local or cached runtime for host helpers:

```bash
scripts/select-runtime.sh /path/to/kernel-runtime
```

The selector validates plugin identity, exact semantic version, and required helper
files. It refuses unsafe host objects and reports the selected root. Do not remove the
marketplace or clear the whole plugin cache as normal rollback. If reinstall is needed,
use `/plugin uninstall kernel@kernel-marketplace --keep-data` before reinstalling.

## Contributor development

Run `claude --plugin-dir ./` from a checkout. Reload or restart after plugin-structure
changes. Editing or replacing a numbered installed cache directory is unsupported.
