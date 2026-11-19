# Safety model

- Risk is based on how hard a change is to undo, how quietly it can fail, and how much it can
  affect.
- Tier 2 and 3 work uses bounded contracts, separate agents, and a required budget cap.
- Context manifests can be `sealed`, `bounded`, or `advisory`. Hook enforcement of an active
  manifest (`guard-context.sh`) was removed in 9.10.0; treat the policy as a convention the
  manifest CLI and receipts help you keep.
- Runtime roots, JSON state, selectors, and helper-link ownership are validated before
  mutation.
- KERNEL refuses unsafe filesystem objects instead of overwriting them.
- "Done" requires a real verification command. A commit, push, deploy, and working product are
  different states.

## Hooks (9.11.0)

Four events are bound in `hooks/hooks.json`; `hooks/gates.json` is the authoritative registry.

- **`detect-secrets.sh`** (`PreToolUse`, `Write|Edit`): blocks writes containing API keys,
  tokens, or credentials. Fail-closed: if `jq` is missing it blocks instead of letting a
  possible secret through. It deliberately skips the circuit breaker so it can never
  auto-disable.
- **`auto-approve-safe.sh`** (`PermissionRequest`, `Bash`): auto-approves demonstrably safe
  commands (read-only git, test runners, diagnostics). Its dangerous direction is *yes*, so
  when it cannot evaluate it abstains and the human is asked.
- **`session-start.sh`**, **`post-compact-restore.sh`**, **`repeat-detector.py`**: advisory.
  They inject context and cannot refuse an action.

## Removed in 9.10.0

The destructive-command guard (`guard-bash.sh`), config-write guard, context guard, tool-output
scanner, one-time human approval token (`KERNEL_APPROVE`), `test-gate`, `verdict-gate`, and the
`SessionEnd`/`PreCompact` batch-commit hooks no longer ship. Earlier docs and changelog
entries that describe them are historical.

## Honest scope

These hooks are a tripwire, not a sandbox. Nothing here blocks `rm -rf`, exfiltration, or
`curl | sh`. Real containment is the OS sandbox (Claude Code `/sandbox`, Codex network-off
default) and egress control. Keep the host's own permission prompts or sandbox on for
anything irreversible.
