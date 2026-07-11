---
query: "Claude Code plugin marketplace update behavior for KERNEL 7.23.0 to 8.0.0"
date: 2026-07-10
ttl: 30
status: verified
---

# KERNEL 8.0.0 user-upgrade audit

## Release decision

KERNEL 8.0.0 can be distributed through the existing `kernel-marketplace` as an explicit version bump, but it is not safe to publish until KERNEL stops pinning its host-side helper links to the version that was current when `/kernel:init` last ran.

Claude Code installs 8.0.0 in a new versioned cache directory. It does not overwrite 7.23.0 in place. KERNEL 7.x init, however, links the AgentDB executable, orchestration directory, and hooks directory to that exact numbered cache directory. A normal marketplace/plugin update and `/reload-plugins` can therefore load v8 plugin components while host-side KERNEL links still execute v7.23.0 code.

The release fix should introduce one stable `current` indirection, point every host-side link through it, and safely repair old exact-version links when v8 first runs. Documentation alone is not enough: third-party marketplace auto-update can activate v8 without a user following a migration page.

## Confirmed Claude Code update mechanics

1. `plugin.json` version is Claude Code's first-choice version and cache key. KERNEL's public release version must be `8.0.0` in `.claude-plugin/plugin.json`. The marketplace entry may repeat it, but Anthropic recommends avoiding two version declarations because `plugin.json` silently wins when they disagree.
2. Refreshing a marketplace and updating an installed plugin are separate operations. The supported explicit sequence for this repository is:

   ```text
   /plugin marketplace update kernel-marketplace
   /plugin update kernel@kernel-marketplace
   /reload-plugins
   ```

3. The exact installed identifier is `kernel@kernel-marketplace`. Public install and recovery docs should use that form rather than bare `kernel`.
4. KERNEL is a third-party marketplace. Third-party marketplace auto-update is disabled by default. Users who enabled it receive marketplace and installed-plugin updates at Claude Code startup; after an update, Claude Code prompts them to run `/reload-plugins`.
5. Marketplace plugins are copied into `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`. Each version has its own directory. The previous version becomes orphaned after update or uninstall and is automatically removed after seven days. Existing sessions may continue using the old directory during that grace period.
6. `/reload-plugins` reloads active plugins, skills, agents, hooks, MCP servers, and LSP servers without restarting the terminal application. This is when v8's new skills become available and removed command files stop being registered in that session. Claude Code monitors still require a session restart. The VS Code plugin interface instead shows a restart banner after changes.
7. Pushing new repository commits without changing the explicit `plugin.json` version does not update installed users. Claude Code considers the cached version current and skips it.

## Mixed-version blocker in the current code

The current paths disagree about how a selected plugin version is followed:

- `skills/init/SKILL.md:43-58` discovers the latest numbered cache directory and links:
  - `$VAULTS/.local/bin/agentdb` directly to `$PLUGIN_CACHE/$LATEST/orchestration/agentdb/agentdb`
  - `$VAULTS/.claude/kernel/orchestration` directly to `$PLUGIN_ROOT/orchestration`
  - `$VAULTS/.claude/kernel/hooks` directly to `$PLUGIN_ROOT/hooks`
- The init one-liner repeats the same exact-version links at `skills/init/SKILL.md:104-108`.
- `hooks/scripts/common.sh:8-47` already maintains `$HOME/.claude/plugins/cache/kernel-marketplace/kernel/current` and moves it to the highest semantic version found in the cache.
- Nothing in init points the host links through `current`.
- The normal update flow in `README.md:105-113` refreshes the marketplace, updates the plugin, and reloads plugins, but does not rerun init or repair the host links.

Observed on the release machine before v8 installation:

```text
claude plugin list --json
kernel@kernel-marketplace  7.23.0

~/.claude/plugins/cache/kernel-marketplace/kernel/current
  -> ~/.claude/plugins/cache/kernel-marketplace/kernel/7.23.0
```

The issue is not that `current` fails to advance. The issue is that initialized host links do not consume it.

### Failure mode after publishing 8.0.0

1. Claude Code creates `.../kernel/8.0.0/` and loads v8 skills/hooks after reload.
2. A v8 hook advances `.../kernel/current` to `8.0.0`.
3. Existing `$VAULTS/.claude/kernel/*` and `$VAULTS/.local/bin/agentdb` links can remain pinned to `7.23.0`.
4. A resumed task can mix v8 manifest/schema expectations with v7 orchestration or AgentDB behavior.
5. Seven days later Claude Code may remove the orphaned 7.23.0 cache directory, turning those stale links into broken links.

This is a quiet failure: reload appears successful before the helper path breaks or behaves differently.

## User data preservation

Claude Code's plugin update copies plugin code into its versioned user cache. The update operation itself does not migrate or delete host-project `.claude/`, `_meta/`, or AgentDB content.

KERNEL's own runtime is different from Claude Code's installer:

- `/kernel:init` creates or modifies Vaults directories, links under `$VAULTS/.claude/kernel`, a PATH entry, and AgentDB.
- KERNEL session hooks write session and agent records beneath host `_meta/` and may synchronize repositories.
- KERNEL stores AgentDB at `_meta/agentdb/agent.db`, not in `${CLAUDE_PLUGIN_DATA}`.

Therefore the allowed public claim is: **updating the plugin does not replace a user's project files, manifests, or AgentDB.** It is not safe to claim that activating KERNEL performs no host writes; hooks and init intentionally do.

Uninstalling a plugin from its last installed scope deletes `${CLAUDE_PLUGIN_DATA}` by default unless `--keep-data` is used. KERNEL currently stores its durable database outside that directory, but recovery instructions should still use `--keep-data` defensively. Removing the marketplace from its last scope also uninstalls plugins installed from it and must never be presented as a harmless refresh.

## Recommended implementation

### Chosen: stable `current` link plus safe self-heal

1. Keep one cache selector:

   ```text
   ~/.claude/plugins/cache/kernel-marketplace/kernel/current
     -> <highest valid installed semantic version>
   ```

2. Change both init paths so host links target `current`, never a numbered version:

   ```text
   $VAULTS/.local/bin/agentdb
     -> .../kernel/current/orchestration/agentdb/agentdb
   $VAULTS/.claude/kernel/orchestration
     -> .../kernel/current/orchestration
   $VAULTS/.claude/kernel/hooks
     -> .../kernel/current/hooks
   ```

3. On v8 hook startup, inspect only those three KERNEL-owned links. If a link is absent, leave it for explicit init. If it is a symlink into the recognized KERNEL cache and pins an older numbered version, replace it atomically with the `current` target. If it is a regular file, a user-owned directory, a link outside the recognized cache, or cannot be parsed, do not overwrite it; print one actionable migration warning.
4. Validate the selected cache directory before moving `current`: require a semantic-version directory containing the expected KERNEL plugin manifest and helper paths. Do not select `.update_checked`, a broken link, or an arbitrary numeric-looking directory.
5. Make repair idempotent and covered by tests for: clean v7 link migration, already-current links, missing links, user-owned paths, malformed cache entries, broken old links, and rollback to an explicitly selected older cache.
6. Keep a documented manual repair command or `/kernel:init` migration path for environments where hook self-heal cannot write.

This makes automatic and manual updates safe even when users never read the migration guide.

### Alternative A: require `/kernel:init` after every update

This is smaller, but unsafe as the only solution. Auto-update users may load v8 before seeing release notes, and stale links can break after Claude Code's seven-day orphan cleanup. Keep rerunning init as a recovery option, not as the safety boundary.

### Alternative B: resolve the active cache directory independently everywhere

Every hook and helper could rediscover the highest version on every invocation. This duplicates selection logic across shell scripts and entry points, makes rollback harder, and increases disagreement risk. One validated `current` selector is simpler.

### Alternative C: copy helpers into the host Vaults

Copying avoids dangling cache links, but creates a second unmanaged KERNEL installation that plugin updates cannot replace. It makes version drift less visible, not less likely.

## Session behavior and user instructions

### Normal update

```text
/plugin marketplace update kernel-marketplace
/plugin update kernel@kernel-marketplace
/reload-plugins
```

After the implementation above, KERNEL should report that its helper links moved to 8.0.0 or that no migration was necessary. If Claude Code reports that a monitor cannot be reloaded, end the current session and start a new one.

### Auto-update

Users must opt into auto-update for `kernel-marketplace`; it is not the default for a third-party marketplace. When Claude Code says KERNEL updated, run `/reload-plugins`. Existing active sessions may continue using 7.23.0 until reloaded or restarted.

### Recovery by reinstall

Use uninstall only after normal update and reload fail:

```text
/plugin uninstall kernel@kernel-marketplace --keep-data
/plugin install kernel@kernel-marketplace
/reload-plugins
```

Do not remove the marketplace as a refresh step. Do not tell users to delete the entire `~/.claude/plugins/cache`; Anthropic documents that as broad troubleshooting followed by a restart and reinstall, not normal upgrade behavior.

### Rollback

The lowest-risk immediate rollback is session-scoped:

1. Check out tag `v7.23.0` into a separate directory.
2. Start a new session with `claude --plugin-dir /path/to/kernel-claude-v7.23.0`.

Official Claude Code behavior gives a same-name `--plugin-dir` plugin precedence over the installed marketplace plugin for that session. This avoids uninstalling 8.0.0 while a user evaluates or recovers data.

A durable rollback may use a separate marketplace registration pinned to `ariaxhan/kernel-claude@v7.23.0`, then install its exact `plugin@marketplace` identifier. It should not reuse/remove the live marketplace casually because removing the last marketplace scope uninstalls its plugins. KERNEL's `current` self-heal must also respect an intentional rollback instead of blindly selecting 8.0.0 merely because its orphaned cache directory still exists; the selector should follow Claude Code's installed version state or an explicit override, not directory maximum alone.

## Platform claims

### Supported by current official documentation

- Claude Code terminal supports marketplace add/install/update/uninstall and `/reload-plugins`.
- Claude Code Desktop local and SSH sessions can install and manage the same plugin types; plugins are unavailable for remote sessions.
- Claude Code's VS Code interface uses the same CLI commands and plugin configuration underneath, and prompts for a restart after changes.
- Plugin skills are namespaced by plugin name in Claude Code, for example `/kernel:ingest`.

### Unsupported or insufficiently verified

- `README.md:29`: “Cursor shares the same plugin configuration automatically.” No current official Anthropic documentation found supports this claim.
- `README.md:79,85-101`: Desktop/Cursor commands appear without the `kernel:` prefix. Official Claude Code documentation describes plugin skills as namespaced. Do not publish a short-name platform matrix without direct testing and a platform-owned source.
- `README.md:19-25`: the heading “Claude Desktop,” Personal plugins flow, and `/init` mix Claude chat Personal plugins with Claude Code Desktop behavior. These are distinct surfaces in current documentation and need separate, accurately named instructions.
- “All v7 invocations work unchanged.” This needs an actual compatibility test for every formerly command-backed invocation on every claimed surface. The plugin format alone does not prove it.

## Allowed and forbidden release claims

### Allowed

- “KERNEL 8.0.0 installs alongside 7.23.0 in Claude Code's versioned plugin cache.”
- “The plugin update does not overwrite project files, existing manifests, or AgentDB.”
- “Run `/reload-plugins` after updating; restart the session if Claude Code says a component cannot reload.”
- “Third-party marketplace auto-update is off by default and can be enabled for `kernel-marketplace`.”
- “Use `kernel@kernel-marketplace` as the exact plugin identifier.”
- “Old cache versions can remain for seven days so existing sessions do not fail immediately.”
- “KERNEL 8 uses canonical JSON manifests; historical YAML records remain history, not active resume inputs.”

### Forbidden until separately proven

- “Everyone updates automatically.”
- “Updating changes nothing outside the plugin cache.”
- “Uninstall/reinstall cannot remove any data.”
- “Removing and re-adding the marketplace is a safe refresh.”
- “Cursor automatically shares Claude Code plugin configuration.”
- “Desktop and Cursor use unnamespaced KERNEL commands.”
- “All v7 commands work unchanged on every surface.”
- “Edits to an installed plugin take effect immediately.” Official local development uses `claude --plugin-dir` and `/reload-plugins`.
- “The highest version directory is always the active version.” Orphaned and rollback caches make that false.

## Other release-doc corrections found

- `.claude-plugin/plugin.json:4` and `.claude-plugin/marketplace.json:10` still describe v8 as “yaml-first”; v8's canonical live format is JSON.
- `README.md:177` omits the manifest runtime's `preflight` action.
- `skills/init/SKILL.md:20-22`, its executable detection code, and `hooks/scripts/common.sh:50-69` describe three different Vaults search orders. Release docs must not promise one until implementation is unified.
- Contributor instructions should prefer the official `claude --plugin-dir ./` workflow over manually replacing a numbered cache directory with a symlink.

## Official sources

- Claude Code, Discover and install plugins: https://code.claude.com/docs/en/discover-plugins
- Claude Code, Plugins reference: https://code.claude.com/docs/en/plugins-reference
- Claude Code, Create and distribute a plugin marketplace: https://code.claude.com/docs/en/plugin-marketplaces
- Claude Code, Create plugins and local `--plugin-dir` testing: https://code.claude.com/docs/en/plugins
- Claude Code, Desktop: https://code.claude.com/docs/en/desktop
- Claude Code, VS Code integration: https://code.claude.com/docs/en/ide-integrations
