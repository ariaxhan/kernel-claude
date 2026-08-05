# KERNEL documentation

The [README](../README.md) gets you installed. Everything else is here.

## What KERNEL is

KERNEL is a Claude Code plugin that gives coding sessions durable project memory, bounded
handoffs, repeatable engineering workflows, and independent checks before risky changes ship.
Codex can load the same package through its Claude-marketplace compatibility path.

It is for people who use Claude Code on real repositories and want work to survive session
boundaries without turning the agent loose. It does not replace source control, tests, human
review, or project-specific instructions. KERNEL records evidence and enforces process; it
cannot prove a product is correct by itself.

## Pages

| Page | What it covers |
| --- | --- |
| [install.md](install.md) | Every install path, supported surfaces, what setup writes, how to verify |
| [QUICKSTART.md](QUICKSTART.md) | The longer prose walkthrough of setup and first use |
| [daily-use.md](daily-use.md) | The working loop, skill groups, governance-sync, manifest CLI |
| [data-and-memory.md](data-and-memory.md) | What KERNEL writes to disk, semantic recall, lean session start, the learning graph |
| [safety.md](safety.md) | Risk tiering, the reversibility guard, its six threat classes, and its honest limits |
| [troubleshooting.md](troubleshooting.md) | Symptom-first fixes, reinstall, recovery |
| [upgrading.md](upgrading.md) | Upgrading from 7.23, breaking changes, rolling back without losing data |
| [MIGRATION-8.md](MIGRATION-8.md) | Full 8.0 migration detail |
| [contributing.md](contributing.md) | Running from a checkout, tests, architecture references |
| [skill-template.md](skill-template.md) | Writing a KERNEL skill |
| [BRANCH-PROTECTION.md](BRANCH-PROTECTION.md) | Repository branch protection settings |
| [kernel-9/INVENTORY.md](kernel-9/INVENTORY.md) | KERNEL 9 planning inventory |
| [kernel-9/HOST-CAPABILITIES.md](kernel-9/HOST-CAPABILITIES.md) | Host capability matrix for KERNEL 9 |

## Elsewhere in the repository

- [CLAUDE.md](../CLAUDE.md) and [AGENTS.md](../AGENTS.md): the governance documents KERNEL
  loads.
- [schemas/](../schemas/): manifest schemas.
- [workflows/](../workflows/): declarative workflow definitions.
- [skills/](../skills/): every skill definition.
- [agents/](../agents/): agent definitions.
- [CHANGELOG.md](../CHANGELOG.md): release history.
