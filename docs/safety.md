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

## Hook gates

Two gates ship, registered in `hooks/gates.json`:

- **`detect-secrets`** (PreToolUse, `Write|Edit`): blocks writes that would commit a credential.
- **`auto-approve-safe`** (PermissionRequest, `Bash`): auto-approves read-only git and test
  commands. Any command with a chaining, pipe, redirect, or substitution operator, and anything
  unrecognised, gets no decision, so the human is asked. Uncertainty never becomes consent.

Everything else bound in `hooks/hooks.json` is advisory and cannot refuse: `session-start`,
`post-compact-restore`, `repeat-detector`.

Removed in 9.9.0: the hooks that inferred intent from command text (`guard-bash`, the
autocorrect and routing hooks). The command-reversibility classifier, the one-time
`KERNEL_APPROVE` token, and the prompt-injection tripwire described in 8.x docs no longer ship;
authority comes from structural operations and explicit policy, not words in text.

**Honest scope.** These hooks are a tripwire, not a sandbox. Real containment is the OS sandbox
(Claude Code `/sandbox`, Codex network-off default) and egress control that these hooks sit
inside. They stop the accidental credential commit, not a determined adversary.
