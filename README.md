# KERNEL 8

KERNEL is a Claude Code plugin that gives coding sessions durable project memory, bounded handoffs, repeatable engineering workflows, and independent checks before risky changes ship.

It is for people who use Claude Code on real repositories and want work to survive session boundaries without turning the agent loose. It does not replace source control, tests, human review, or project-specific instructions. KERNEL records evidence and enforces process; it cannot prove a product is correct by itself.

## Supported surfaces

- Claude Code in a terminal.
- Claude Code Desktop local and SSH sessions. Remote sessions do not support plugins.
- Claude Code in VS Code, which uses the same plugin configuration and may ask for a restart after changes.

KERNEL skills are namespaced: `/kernel:ingest`, `/kernel:validate`, and so on. Cursor and Claude chat Personal plugins are not supported installation targets here.

## Install

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

## Upgrading from 7.23.0

KERNEL 8 is a major release. Update explicitly:

```text
/plugin marketplace update kernel-marketplace
/plugin update kernel@kernel-marketplace
/reload-plugins
```

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

For one session, check out `v7.23.0` separately and run:

```bash
claude --plugin-dir /path/to/kernel-claude-7.23.0
```

To deliberately select a validated local or cached runtime for the helper links:

```bash
scripts/select-runtime.sh /path/to/kernel-claude-7.23.0
```

That explicit selection may move `current` backward; normal old sessions cannot. It does not convert KERNEL 8 JSON state to KERNEL 7 YAML. Do not delete the plugin cache or remove the marketplace as a normal rollback step.

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

There are 33 skills and 15 specialized agent definitions in this release. `/kernel:help` is the live index.

## What KERNEL writes

KERNEL keeps durable data in the selected Vaults, found in this order: valid `KERNEL_VAULTS`, `~/Documents/Vaults`, `~/Vaults`, then `~/Downloads/Vaults`.

- `_meta/agentdb/agent.db`: project memory, contracts, checkpoints, verdicts, and telemetry.
- `_meta/handoffs/`, `_meta/checkpoints/`, `_meta/retrospectives/`, and receipts: JSON state artifacts.
- `_meta/agents/`, `_meta/logs/`, and small session-status files: runtime records.
- `.claude/kernel/` and `.local/bin/agentdb`: links created only by explicit init; startup only repairs recognized old numbered KERNEL links.

KERNEL hooks can inspect repository state, run configured checks, and write these records. Some workflows can use GitHub when the project profile enables it. KERNEL does not promise that all processing stays local when you invoke a workflow that uses external tools. Review Claude Code permissions and the repository's own instructions before granting access.

## Safety model

- Risk is based on how hard a change is to undo, how quietly it can fail, and how much it can affect.
- Tier 2 and 3 work uses bounded contracts, separate agents, and a required budget cap.
- Context manifests can be `sealed`, `bounded`, or `advisory`; hooks enforce active restrictions.
- Runtime roots, JSON state, selectors, and helper-link ownership are validated before mutation.
- KERNEL refuses unsafe filesystem objects instead of overwriting them.
- “Done” requires a real verification command. A commit, push, deploy, and working product are different states.

## Troubleshooting and recovery

Skills missing after update: run `/reload-plugins`; start a new session if prompted.

Helper-link warning: inspect the exact path printed by KERNEL, then run `/kernel:init`. Init will not overwrite a regular file, directory, or unrelated link without a separate manual decision.

Wrong Vaults: set `KERNEL_VAULTS` to the existing Vaults root before init or startup.

Normal reinstall, only after update/reload fails:

```text
/plugin uninstall kernel@kernel-marketplace --keep-data
/plugin install kernel@kernel-marketplace
/reload-plugins
```

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
