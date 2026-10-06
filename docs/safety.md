# Safety model

KERNEL 9.11.0 uses local memory, explicit workflows, and minimal hooks. Risk guidance is
based on how hard a change is to undo, how quietly it can fail, and how much it can affect.
A contract or separate verification role is a workflow requirement, not an OS boundary.

## Current hook bindings

[`hooks/hooks.json`](../hooks/hooks.json) is the source of truth for active plugin bindings:

- **SessionStart:** supplies AgentDB and repository context.
- **PreToolUse (`Write|Edit`):** scans write content for secret patterns. It also understands
  Codex apply-patch payloads. Missing `jq` or malformed input blocks the write.
- **PermissionRequest (`Bash`):** approves selected Git, test, lint, and diagnostic command
  patterns; chained commands defer to the host permission flow. Deferring is not a ban.
- **UserPromptSubmit:** runs prompt-time restore and repeated-request context-loss detection.

Codex requires `[features] hooks = true` in its configuration. KERNEL does not enable that
setting during installation. Host event support is distinct from the events bound here.

## Limits

The current plugin does not bind the former destructive-command, configuration-write,
tool-output injection, or context guards. It does not implement the former one-time
`KERNEL_APPROVE` token gate. A `sealed` or `bounded` manifest records intent and context
budget; activation does not supply a hook that blocks forbidden file reads in this release.
Neither host has a KERNEL SessionEnd binding; persist end-state explicitly.

Secret detection covers patterns in recognized write payloads, not every possible shell,
network, or filesystem operation. Permission auto-approval is pattern-based. These hooks
do not replace the host sandbox, egress controls, source control, tests, or human review.
Runtime-root and helper-link validation still protects setup from replacing unrelated files.

A commit, push, deployment, and verified working result are different states. Report the
state supported by a real verification command.
