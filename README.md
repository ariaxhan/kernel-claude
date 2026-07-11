# KERNEL 8

KERNEL is a Claude Code plugin that gives coding sessions durable project memory, bounded handoffs, repeatable engineering workflows, and independent checks before risky changes ship. Codex can load the same package through its Claude-marketplace compatibility path.

It is for people who use Claude Code on real repositories and want work to survive session boundaries without turning the agent loose. It does not replace source control, tests, human review, or project-specific instructions. KERNEL records evidence and enforces process; it cannot prove a product is correct by itself.

## Supported surfaces

- Claude Code in a terminal.
- Claude Code Desktop local and SSH sessions. Remote sessions do not support plugins.
- Claude Code in VS Code, which uses the same plugin configuration and may ask for a restart after changes.
- Codex CLI and the Codex app through Codex's legacy Claude-plugin compatibility loader.

KERNEL skills are namespaced. Claude Code invokes `/kernel:ingest`; Codex invokes
`$kernel:ingest`. Cursor and Claude chat Personal plugins are not supported
installation targets here.

KERNEL 8 intentionally does not ship a native `.codex-plugin` manifest yet. Claude's
explicit-only skill marker and Codex's native plugin validator currently disagree;
keeping the compatibility loader preserves the safety rule instead of quietly making
side-effecting skills start on their own. The shared `hooks/hooks.json` is regression-
tested against both loaders.

## Install

### Claude Code

In Claude Code:

```text
/plugin marketplace add ariaxhan/kernel-claude
/plugin install kernel@kernel-marketplace
/reload-plugins
/kernel:init
```

`/kernel:init` is an explicit setup operation. It shows the detected Vaults path and asks before creating directories or links. Requirements: Git, SQLite 3, `jq`, Python 3, and Bash.

Verify:

```bash
agentdb status
readlink "$HOME/.claude/plugins/cache/kernel-marketplace/kernel/current"
```

Then run `/kernel:help` in a new Claude Code session.

### Codex CLI or app

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

Restart Codex after the upgrade. Current Codex refreshes the installed plugin cache
as part of the marketplace upgrade; there is no `codex plugin update` command.

Start a new session if Claude Code says a component or monitor could not reload. VS Code may show a restart banner.

On startup, KERNEL validates the plugin Claude Code actually loaded and advances its `current` runtime selector only forward. It repairs exactly three old KERNEL links when their link text proves they point to a numbered `kernel-marketplace/kernel/<version>` runtime:

- `$KERNEL_VAULTS/.local/bin/agentdb`
- `$KERNEL_VAULTS/.claude/kernel/orchestration`
- `$KERNEL_VAULTS/.claude/kernel/hooks`

Missing paths stay missing. Regular files, directories, malformed links, and unrelated links are never replaced; KERNEL prints a recovery warning instead. Updating does not replace project files, existing manifests, receipts, or AgentDB. Hooks and explicit init still write session records and setup files in the selected Vaults.

Breaking changes:

- Live handoffs, checkpoints, retrospectives, and context receipts use canonical JSON. Historical YAML remains history, but KERNEL 8 does not resume it as live state.
- The old command-file implementation layer is gone. Workflows are skills and keep their namespaced invocations.
- `/kernel:design` became `/kernel:frontend` to avoid a native-name collision.
- A KERNEL 7 session may keep using its loaded 7.23 code until reloaded or restarted. Old cache directories may remain temporarily; their presence does not make them active.
- KERNEL 7 may not resume state created by KERNEL 8 even though that state is preserved.

### Roll back without deleting data

From any directory, clone the repository and check out the verified 7.23 release
commit. Use the installed KERNEL 8 selector before starting the older plugin:

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

That explicit selection may move `current` backward; normal old sessions cannot. It does not convert KERNEL 8 JSON state to KERNEL 7 YAML. Do not delete the plugin cache or remove the marketplace as a normal rollback step.

Runtime link changes clean temporary siblings on normal errors and catchable signals.
An uncatchable process kill can leave a `.kernel-tmp.*` symlink; the next matching
operation removes only KERNEL-shaped symlink residue and never a regular lookalike.

## Daily use

1. Start or resume with `/kernel:ingest`. KERNEL reads AgentDB and the live repository, then defines observable success.
2. Let risk choose the workflow. Easy-to-undo work runs directly; durable or quiet changes use a contract and separate implementation/checking roles.
3. Run `/kernel:validate`, then `/kernel:handoff` when another session needs an exact resume point.

Useful skill groups:

- Workflows: `ingest`, `diagnose`, `dream`, `metrics`, `forge`, `experiment`
- State: `handoff`, `checkpoint`, `retrospective`
- Validation: `validate`, `review`, `tearitapart`
- Methods: `build`, `testing`, `debug`, `security`, `architecture`, `git`, `frontend`, and more
- Setup/reference: `init`, `help`, `landing-page`

There are 34 skills and 15 specialized Claude Code agent definitions in this release.

`governance-sync` is explicit-only. It audits Git repositories for `CLAUDE.md` /
`AGENTS.md` gaps and can generate a missing native adapter after showing conflicts,
provenance hashes, and a backup destination. It never rewrites a conflict.
Codex loads the skills and SessionStart rules, but it does not register those 15
Claude agent files as native Codex agents; KERNEL maps the same roles onto Codex's
available subagents during orchestration. Use `/kernel:help` in Claude Code or
`$kernel:help` in Codex.

## What KERNEL writes

KERNEL keeps durable data in the selected Vaults, found in this order: valid `KERNEL_VAULTS`, `~/Documents/Vaults`, `~/Vaults`, then `~/Downloads/Vaults`.

- `_meta/agentdb/agent.db`: project memory, contracts, checkpoints, verdicts, and telemetry.
- `_meta/handoffs/`, `_meta/checkpoints/`, `_meta/retrospectives/`, and receipts: JSON state artifacts.
- `_meta/agents/`, `_meta/logs/`, and small session-status files: runtime records.
- `.claude/kernel/` and `.local/bin/agentdb`: links created only by explicit init; startup only repairs recognized old numbered KERNEL links.

KERNEL hooks can inspect repository state, run configured checks, and write these records.
Claude Code runs the full declared lifecycle. Codex runs supported synchronous hook
events, including the write guards and SessionStart context; it skips asynchronous
command hooks and has no plugin SessionEnd event, so end-of-session recording in Codex
must be invoked explicitly with `$kernel:handoff`. Some workflows can use GitHub when
the project profile enables it. KERNEL does not promise that all processing stays
local when you invoke a workflow that uses external tools. Review host permissions
and the repository's own instructions before granting access.

KERNEL 8.0.2 declares its six advisory hooks as synchronous so Codex executes them
instead of skipping them. They remain non-blocking in outcome: an internal logging or
validation failure returns success and cannot reject the tool operation. The critical
secret, configuration, command, and context guards remain separate blocking gates.

When the active project root exactly matches the Vaults root and the shared continuity
engine plus an executable Claude or Codex adapter are present, that Vaults service owns
compaction checkpoints and restore injection. KERNEL's PreCompact and PostCompact paths
cleanly no-op there; SessionStart still supplies AgentDB and governance without adding a
second restore. Nested repositories retain KERNEL's deterministic generic fallback.
Merely finding continuity files above the active project does not disable KERNEL.

## Safety model

- Risk is based on how hard a change is to undo, how quietly it can fail, and how much it can affect.
- Tier 2 and 3 work uses bounded contracts, separate agents, and a required budget cap.
- Context manifests can be `sealed`, `bounded`, or `advisory`; hooks enforce active restrictions.
- Runtime roots, JSON state, selectors, and helper-link ownership are validated before mutation.
- KERNEL refuses unsafe filesystem objects instead of overwriting them.
- “Done” requires a real verification command. A commit, push, deploy, and working product are different states.

## Troubleshooting and recovery

Skills missing after update: run `/reload-plugins`; start a new session if prompted.

Codex reports `unknown field version` for `hooks/hooks.json`: the session is still
loading an older cached KERNEL release. Upgrade the marketplace, then restart Codex so
it reads KERNEL 8. Do not hand-edit the numbered cache.

Helper-link warning: inspect the exact path printed by KERNEL, then run `/kernel:init`. Init will not overwrite a regular file, directory, or unrelated link without a separate manual decision.

Wrong Vaults: set `KERNEL_VAULTS` to the existing Vaults root before init or startup.

Normal reinstall, only after update/reload fails:

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

Restart Codex after reinstalling. `remove` deletes KERNEL's installed cache entry;
it does not remove the marketplace or project data.

Do not remove the marketplace or clear `~/.claude/plugins/cache` as routine maintenance. Those are destructive recovery steps with wider effects.

Manifest runtime:

```text
kernel-manifest validate | latest | divergence | preflight | compile | resume | activate | deactivate
```

## Contributing

Use the checkout directly instead of modifying a numbered cache directory:

```bash
git clone https://github.com/ariaxhan/kernel-claude.git
cd kernel-claude
claude --plugin-dir ./
./tests/run-tests.sh
```

Reload or start a new development session after plugin-structure changes. Do not replace installed cache directories with development symlinks.

Architecture references: [KERNEL instructions](CLAUDE.md), [setup guide](docs/QUICKSTART.md), [8.0 migration](docs/MIGRATION-8.md), [manifest schema](schemas/), [workflows](workflows/), and [changelog](CHANGELOG.md).

MIT licensed.
