# Migrating from KERNEL 7.23 to 8.0

KERNEL 8 is a major release because its live state format and plugin architecture
changed. Existing data is preserved, but older code may not understand new state.

## Before updating

Commit or checkpoint current work. Note the current plugin version and run
`agentdb status`. Do not delete old manifests or cache directories.

## Update

Claude Code:

```text
/plugin marketplace update kernel-marketplace
/plugin update kernel@kernel-marketplace
/reload-plugins
```

Codex CLI or app:

```bash
codex plugin marketplace upgrade kernel-marketplace
```

Restart Codex after upgrading. The current CLI refreshes installed cache contents
during marketplace upgrade and does not provide a `codex plugin update` command.

Start a new session if Claude Code says a monitor or component cannot reload. VS Code
may request a restart. Third-party marketplace auto-update is off by default; users
who enabled it still need to reload when prompted.

Codex users continue through its Claude-marketplace compatibility loader in 8.0.
KERNEL does not add a native `.codex-plugin` manifest in this release: Codex's native
validator rejects Claude's explicit-only skill marker, and removing that marker would
let explicit-only skills run without an explicit invocation. Explicit-only skills (5):
`experiment`, `forge`, `governance-sync`, `init`, `landing-page`. The shared hook
file is constrained to the top-level fields accepted by both loaders. If Codex reports
`unknown field version` for `hooks/hooks.json`, it is reading a 7.23 cache; upgrade and
restart Codex rather than editing that cache.

Explicit skill syntax differs by host: Claude Code uses `/kernel:<name>` and Codex
uses `$kernel:<name>`. KERNEL adds Codex-native explicit-only policies for `init`,
`forge`, `experiment`, and `landing-page`; their existing Claude markers remain.

Codex loads KERNEL's SessionStart context and synchronous write guards. It skips
asynchronous command hooks and has no plugin SessionEnd event. The 15 files in
`agents/` remain Claude Code agent definitions rather than native Codex agents;
Codex orchestration applies the same role contracts to available Codex subagents.
Use `$kernel:handoff` explicitly when a Codex session needs durable closing state.

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

Normal errors and catchable signals remove the temporary sibling. `SIGKILL` cannot be
trapped and can leave one `.kernel-tmp.*` symlink. A later matching operation removes
only matching symlink residue; regular files with similar names remain untouched.

## Breaking changes

- Canonical state is JSON: `kernel.handoff/v1`, `kernel.checkpoint/v1`,
  `kernel.retrospective-result/v1`, and `kernel.context-receipt/v1`. Historical YAML
  is retained as history but is not an active KERNEL 8 resume input.
- Workflow/state/validator/operator definitions now all live under `skills/`; the
  old `commands/` layer is removed. Invoke `/kernel:<skill>` in Claude Code or
  `$kernel:<skill>` in Codex.
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
git clone https://github.com/ariaxhan/kernel-claude.git "$HOME/kernel-claude-7.23"
git -C "$HOME/kernel-claude-7.23" checkout 54a0053
V8_SELECTOR="$HOME/.claude/plugins/cache/kernel-marketplace/kernel/current/scripts/select-runtime.sh"
"$V8_SELECTOR" "$HOME/kernel-claude-7.23"
claude --plugin-dir "$HOME/kernel-claude-7.23"
```

To select a trusted local or cached runtime for host helpers:

```bash
scripts/select-runtime.sh /path/to/kernel-runtime
```

The selector uses KERNEL 8's own trusted helper code to validate the target as data;
the older target does not need to contain KERNEL 8 functions. It validates plugin identity, exact semantic version, and required helper
files. It refuses unsafe host objects and reports the selected root. Do not remove the
marketplace or clear the whole plugin cache as normal rollback. If reinstall is needed,
use `/plugin uninstall kernel@kernel-marketplace --keep-data` before reinstalling.

Codex recovery is separate from Claude Code. If upgrade completed but the installed
cache is still wrong, refresh only KERNEL's installed entry:

```bash
codex plugin marketplace upgrade kernel-marketplace
codex plugin remove kernel@kernel-marketplace
codex plugin add kernel@kernel-marketplace
```

Restart Codex afterward. `codex plugin remove` deletes the installed KERNEL cache
entry, not the configured marketplace or project data.

## Contributor development

Run `claude --plugin-dir ./` from a checkout. Reload or restart after plugin-structure
changes. Editing or replacing a numbered installed cache directory is unsupported.
