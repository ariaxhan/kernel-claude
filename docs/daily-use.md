# Daily use

1. Start or resume with `/kernel:ingest`. KERNEL reads AgentDB and the live repository, then
   defines observable success.
2. Let risk choose the workflow. Easy-to-undo work runs directly; durable or quiet changes
   use a contract and separate implementation/checking roles.
3. Run `/kernel:validate`, then `/kernel:handoff` when another session needs an exact resume
   point.

In Codex, replace the leading `/` with `$`, for example `$kernel:validate`.

## Skill groups

- Workflows: `ingest`, `diagnose`, `dream`, `metrics`, `forge`, `experiment`
- State: `handoff`, `checkpoint`, `retrospective`
- Validation: `validate`, `review`, `tearitapart`
- Methods: `build`, `testing`, `debug`, `security`, `architecture`, `git`, `frontend`,
  `marketing-site`, and more
- Setup/reference: `init`, `help`, `landing-page`

There are 28 skills and 10 specialized Claude Code agent definitions in this release. Use
`/kernel:help` in Claude Code or `$kernel:help` in Codex for the live index and plugin
status.

## governance-sync

`governance-sync` is explicit-only. It audits Git repositories for `CLAUDE.md` / `AGENTS.md`
gaps and can generate a missing native adapter after showing conflicts, provenance hashes,
and a backup destination. It never rewrites a conflict.

Codex loads the skills and SessionStart rules, but it does not register the 10 Claude agent
files as native Codex agents; KERNEL maps the same roles onto Codex's available subagents
during orchestration.

## Manifest runtime

```text
kernel-manifest validate | latest | divergence | preflight | compile | resume | activate | deactivate
```

Schemas live in [`schemas/`](../schemas/); declarative workflow definitions live in
[`workflows/`](../workflows/).
