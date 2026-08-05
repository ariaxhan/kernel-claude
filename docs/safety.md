# Safety model

- Risk is based on how hard a change is to undo, how quietly it can fail, and how much it can
  affect.
- Tier 2 and 3 work uses bounded contracts, separate agents, and a required budget cap.
- Context manifests can be `sealed`, `bounded`, or `advisory`; hooks enforce active
  restrictions.
- Runtime roots, JSON state, selectors, and helper-link ownership are validated before
  mutation.
- KERNEL refuses unsafe filesystem objects instead of overwriting them.
- "Done" requires a real verification command. A commit, push, deploy, and working product are
  different states.

## Security guard (8.2.0)

The command, write, and tool-output guards enforce one line: **reversibility**. An operation
that cannot be undone, or is hard to undo, hard-blocks and *surfaces* the block so a human
decides; a recoverable one warns and lets the model self-correct. The guard is grounded in
real 2025-26 incidents (Replit's production-DB wipe, the Nx s1ngularity supply-chain attack,
EchoLeak/CamoLeak exfiltration, CurXecute/MCPoison MCP attacks), not a hand-made list. It
covers six threat classes:

- **Self-destruct**: `rm -rf` of root/home, `dd`/`mkfs`, disk overwrite, `DROP`/`TRUNCATE`,
  infra teardown, cloud deletes, git history destruction, recursive `chmod`/`chown`.
- **Exfiltration**: a literal secret, a credential file (`~/.ssh`, `~/.aws`, `.env`), or a
  keychain read in the same command as a network egress tool. Env-var references and
  localhost targets pass.
- **Scope escape**: `--dangerously-skip-permissions` spawns (the Nx signature), `crontab`
  writes, redirects into shell startup files, and any tampering with the guard itself.
- **Supply chain**: `curl|sh`, `base64 -d | sh`, `eval $(curl ...)`.
- **Sensitive config writes**: credential roots, `.git/hooks/`, MCP config
  (`.mcp.json`/`.cursor/mcp.json`), launchd/cron persistence.
- **Indirect prompt injection**: a warn-only tripwire on `WebFetch`/`WebSearch`/MCP output
  that flags invisible-character smuggling (Unicode Tags, zero-width, bidi) and
  instruction-override phrasing, then tells the model to treat that output as untrusted data.
  Nothing is blocked; false positives are being tuned on real traffic first.

**Human approval, unforgeable by injection.** When a hard block is genuinely intended, the
guard mints a one-time `KERNEL_APPROVE=<code>` bound to a hash of the exact command and stores
it in `~/.kernel/approvals/` (15-minute TTL, single use). The human reads the token file
out-of-band and re-runs the command with the code. Because the code never enters the
model-visible stream, a prompt-injected command cannot forge it. This replaces the old
`DANGER_OK=1` substring, which any injected command could set on itself. The token store is
unreadable to the agent.

**Honest scope.** These hooks are a tripwire, not a sandbox. Heuristic injection detection is
~40-84% effective in the literature, and a determined multi-step evasion can route around a
text guard. Real containment is the OS sandbox (Claude Code `/sandbox`, Codex network-off
default) and egress control that these hooks sit inside. The guard stops the accidental
catastrophe and raises the cost of the injected one.
