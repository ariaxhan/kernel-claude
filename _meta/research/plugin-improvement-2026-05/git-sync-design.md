---
name: git-sync-design
description: "OPT-IN /kernel:save and /kernel:pull feature design — modeled on our4cuts save.sh/pull.sh, reconciled with kernel invariants."
type: reference
date: 2026-05-28
---

# /kernel:save — Git Sync Feature Design

## Why this exists

`our4cuts/scripts/save.sh` is the reference implementation: one command
that stages, validates the commit message, rebases against remote, and
pushes — with plain-English failure guidance at every step. Kernel users
currently get none of that UX. The session-end auto-commit exists as a
safety net, but it is not a workflow — it uses `log(auto)` style messages
and fires at the end of a session, not at intentional save points.

This feature adds `/kernel:save` and `/kernel:pull` as opt-in commands
with a matching pre-commit message guard hook. Existing users who do
nothing see zero change.

---

## Invariant reconciliation

| Invariant | Constraint | Resolution |
|---|---|---|
| I0.4 | No AI attribution on commits | `/kernel:save` passes a user-supplied message. The hook blocks AI-generated placeholder messages. No trailer injected. |
| I0.5 | Never `--no-verify` | The sync script calls `git commit` normally. Only session-end.sh and pre-compact-commit.sh carry the documented carve-out. The new script never uses `--no-verify`. |
| I0.8 | Push to `main` requires explicit say-so | By default `/kernel:save` pushes to the **current branch only**. If the current branch IS `main`, the hook prompts for confirmation before pushing (see `guard-commit-msg.sh` behavior in Section 3). The explicit opt-in is `KERNEL_SYNC_ALLOW_MAIN_PUSH=1` in the user's environment or `.claude/settings.json`. |
| I0.9 | No secrets in commits | `detect-secrets.sh` already runs on Write/Edit. The sync script adds a pre-push check: if `git diff origin/$(branch)..HEAD` touches `.env*`/`*key*`/`*secret*`, it blocks and prints recovery steps. |
| I0.15 | Safety via hooks, not honor-system | The placeholder-message guard is a **PreToolUse Bash hook** (`guard-commit-msg.sh`), not a CLAUDE.md rule. The main-push confirmation is enforced in `scripts/kernel-save.sh`, not described to the agent and hoped for. |
| session-end carve-out | session-end.sh already commits with --no-verify | No conflict. `/kernel:save` is a different code path invoked by the user mid-session. session-end still fires at close and still carries its documented carve-out. |

---

## Files to add

```
hooks/scripts/guard-commit-msg.sh    ← PreToolUse: blocks placeholder git commit messages
hooks/scripts/kernel-save.sh         ← script invoked by /kernel:save command
hooks/scripts/kernel-pull.sh         ← script invoked by /kernel:pull command
commands/save.md                     ← /kernel:save command definition
commands/pull.md                     ← /kernel:pull command definition
```

No existing files are modified. `hooks.json` gets one new PreToolUse
entry for `guard-commit-msg.sh` (see Section 4).

---

## Section 1 — Opt-in surface

The feature is off-by-default. A user activates it by invoking
`/kernel:save` or `/kernel:pull`. There is no ambient behavior change.

Optional config (in the user's `.claude/settings.json`, not the plugin's
`hooks.json`):

```jsonc
{
  "env": {
    "KERNEL_SYNC_ALLOW_MAIN_PUSH": "1",     // allow push to main without extra confirmation
    "KERNEL_SYNC_DRY_RUN": "1",             // stage + validate message but don't commit or push
    "KERNEL_SYNC_NO_PULL": "1"              // skip the rebase-pull step (push-only)
  }
}
```

These are environment variables, not plugin config, so they compose with
the user's existing project settings and require no plugin schema changes.

---

## Section 2 — kernel-save.sh

```bash
#!/usr/bin/env bash
# kernel-save.sh — /kernel:save implementation
# Stage → validate message → commit → rebase-pull → push
# Reconciled with I0.4, I0.5, I0.8, I0.9.
set -eo pipefail

source "$(dirname "$0")/common.sh"
_kernel_hook_start

MSG="${1:-}"
DRY_RUN="${KERNEL_SYNC_DRY_RUN:-0}"
ALLOW_MAIN_PUSH="${KERNEL_SYNC_ALLOW_MAIN_PUSH:-0}"
NO_PULL="${KERNEL_SYNC_NO_PULL:-0}"

PROJECT_ROOT="$(get_project_root)"
cd "$PROJECT_ROOT"

BRANCH="$(git branch --show-current 2>/dev/null)"
[ -z "$BRANCH" ] && { echo "✗ detached HEAD — cannot save. Checkout a branch first." >&2; exit 1; }

# ─── 1. Validate commit message (mirrors guard-commit-msg.sh logic) ───
if [ -z "$MSG" ]; then
  echo "✗ /kernel:save requires a commit message." >&2
  echo "  usage: /kernel:save \"feat(scope): what you actually changed\"" >&2
  echo "  format: type(scope): description" >&2
  echo "  types: feat, fix, refactor, docs, chore, style, test, perf" >&2
  exit 1
fi

MSG_LOWER="$(printf '%s' "$MSG" | tr '[:upper:]' '[:lower:]')"
case "$MSG_LOWER" in
  save|wip|update|fix|test|"test message"|misc|changes|stuff|"."|"update files"|"address feedback"|"review pass"|auto*|"log(auto)"*)
    echo "" >&2
    echo "✗ placeholder commit message blocked (W6 rule — these make future archaeology impossible)." >&2
    echo "" >&2
    echo "  use a real message:" >&2
    echo "    /kernel:save \"feat(auth): add rate limiting to login endpoint\"" >&2
    echo "    /kernel:save \"fix(db): prevent N+1 on user query\"" >&2
    echo "    /kernel:save \"refactor(payments): extract stripe client to shared lib\"" >&2
    echo "" >&2
    echo "  format: type(scope): what changed and why (imperative mood)" >&2
    echo "  blocked: save, wip, update, fix, test, misc, changes, stuff, auto*, log(auto)*" >&2
    exit 1
    ;;
esac

# Conventional commit format check (warn, don't block — format is guidance not hard requirement)
if ! echo "$MSG" | grep -qE '^[a-z]+(\([^)]+\))?: .{3,}'; then
  echo "⚠  message doesn't match conventional commit format: type(scope): description" >&2
  echo "   continuing — but consider fixing before pushing to a shared branch." >&2
fi

# ─── 2. Stage everything (respects .gitignore) ───
git add -A

# Unstage files that should never be committed
git reset HEAD -- '*.zip' '*.tar.gz' '*.tar.bz2' '**/.DS_Store' \
  '.env*' '*.pem' '*.key' '*.p12' 'credentials*' 'secrets*' '*.secret' \
  'node_modules/' 2>/dev/null || true

if git diff --cached --quiet; then
  echo "→ nothing staged to commit" >&2
  # Still proceed to pull+push in case remote is ahead
fi

# ─── 3. Main-push confirmation ───
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  if [ "$ALLOW_MAIN_PUSH" != "1" ]; then
    echo "" >&2
    echo "⚠  you are on '$BRANCH'. Push to main requires explicit confirmation (I0.8)." >&2
    echo "   to proceed: set KERNEL_SYNC_ALLOW_MAIN_PUSH=1 in your .claude/settings.json" >&2
    echo "   or use a feature branch: git checkout -b feat/<name> first." >&2
    exit 1
  fi
fi

# ─── 4. Dry-run exit point ───
if [ "$DRY_RUN" = "1" ]; then
  echo "→ dry-run: staged diff follows. No commit or push." >&2
  git diff --cached --stat
  exit 0
fi

# ─── 5. Commit ───
if ! git diff --cached --quiet; then
  echo "→ committing: $MSG"
  if ! git commit -m "$MSG"; then
    echo "" >&2
    echo "✗ commit failed — a pre-commit hook blocked it." >&2
    echo "  scroll up for the reason. fix the listed file, then re-run /kernel:save." >&2
    exit 1
  fi
fi

# ─── 6. Secret leak check on staged → committed diff ───
# Belt-and-suspenders: detect-secrets.sh runs on Write/Edit, but this catches
# files staged outside Claude (e.g. manual git add).
if git diff "origin/$BRANCH"..HEAD -- 2>/dev/null | grep -qiE '(api_key|secret|password|token|private_key)\s*=\s*["\x27][^"\x27]{8,}'; then
  echo "" >&2
  echo "✗ possible secret detected in diff vs remote. Push blocked." >&2
  echo "  run: git log --oneline origin/$BRANCH..HEAD  to review what would push." >&2
  echo "  if this is a false positive, push manually: git push origin $BRANCH" >&2
  exit 1
fi

# ─── 7. Pull (rebase + autostash) ───
if [ "$NO_PULL" != "1" ]; then
  echo "→ syncing with remote..."
  if ! git -c pull.rebase=true -c rebase.autoStash=true pull origin "$BRANCH" 2>&1; then
    echo "" >&2
    echo "════════════════════════════════════════════════════════════════" >&2
    echo "✗ SYNC HIT A CONFLICT" >&2
    echo "" >&2
    echo "  another commit landed on $BRANCH while you were working." >&2
    echo "  git tried to rebase your work on top — it hit a conflict." >&2
    echo "" >&2
    echo "  to resolve:" >&2
    echo "  1. run:  git status" >&2
    echo "     files marked 'both modified' are the conflict points." >&2
    echo "  2. open each file. find the >>>>>>> markers." >&2
    echo "     keep what should stay, delete what shouldn't, remove the markers." >&2
    echo "  3. run:  git add <file>   (for each file you fixed)" >&2
    echo "  4. run:  git rebase --continue" >&2
    echo "  5. run:  /kernel:save \"$MSG\"  (to retry push)" >&2
    echo "" >&2
    echo "  or: git rebase --abort  to cancel and go back to your local state." >&2
    echo "════════════════════════════════════════════════════════════════" >&2
    exit 1
  fi
fi

# ─── 8. Push ───
echo "→ pushing to origin/$BRANCH..."
if ! git push origin "$BRANCH"; then
  echo "" >&2
  echo "✗ push failed." >&2
  echo "  run:  git status          (confirm local state is clean)" >&2
  echo "  run:  git push origin $BRANCH   (to retry)" >&2
  echo "  if you see 'rejected', run /kernel:pull first to sync, then retry." >&2
  exit 1
fi

echo ""
echo "✓ saved and pushed to origin/$BRANCH."

_kernel_hook_end "kernel-save" 0
```

---

## Section 3 — kernel-pull.sh

```bash
#!/usr/bin/env bash
# kernel-pull.sh — /kernel:pull implementation
# Safe fetch + rebase --autostash. Never destroys uncommitted work.
set -eo pipefail

source "$(dirname "$0")/common.sh"
_kernel_hook_start

PROJECT_ROOT="$(get_project_root)"
cd "$PROJECT_ROOT"

BRANCH="$(git branch --show-current 2>/dev/null)"
[ -z "$BRANCH" ] && { echo "✗ detached HEAD — checkout a branch first." >&2; exit 1; }

echo "→ fetching origin..."
git fetch origin

echo "→ rebasing onto origin/$BRANCH (autostash active)..."
if ! git -c pull.rebase=true -c rebase.autoStash=true pull origin "$BRANCH" 2>&1; then
  echo "" >&2
  echo "════════════════════════════════════════════════════════════════" >&2
  echo "✗ PULL HIT A CONFLICT" >&2
  echo "" >&2
  echo "  remote changes conflict with your local work." >&2
  echo "" >&2
  echo "  to resolve:" >&2
  echo "  1. run:  git status" >&2
  echo "  2. open each 'both modified' file. find the >>>>>>> markers." >&2
  echo "  3. fix the file, then:  git add <file>" >&2
  echo "  4. run:  git rebase --continue" >&2
  echo "  5. run:  /kernel:pull  (to confirm clean)" >&2
  echo "" >&2
  echo "  to abort and return to your prior state:" >&2
  echo "     git rebase --abort" >&2
  echo "════════════════════════════════════════════════════════════════" >&2
  exit 1
fi

echo "✓ up to date with origin/$BRANCH."

_kernel_hook_end "kernel-pull" 0
```

---

## Section 4 — guard-commit-msg.sh (PreToolUse hook, I0.15)

This hook fires whenever the agent runs a `git commit` Bash command. It
intercepts placeholder messages before they reach git — encoding the W6
forbidden-messages list as a machine-enforced rule, not a CLAUDE.md
instruction the agent might skip.

```bash
#!/bin/bash
# PreToolUse hook: Block W6 forbidden commit messages in git commit calls.
# Events: PreToolUse (matcher: Bash)
# I0.15: safety via hooks, not honor-system.

source "$(dirname "$0")/circuit-breaker.sh"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$COMMAND" ] && exit 0

# Only trigger on git commit commands
echo "$COMMAND" | grep -qE '^\s*git\s+commit\b' || exit 0

# Extract the -m message value if present
MSG=$(echo "$COMMAND" | grep -oE '\-m\s+"[^"]*"|\-m\s+'"'"'[^'"'"']*'"'" | head -1 | sed "s/-m //; s/^[\"']//; s/[\"']$//")
[ -z "$MSG" ] && exit 0  # HEREDOC or --file forms: skip (can't parse safely)

MSG_LOWER="$(printf '%s' "$MSG" | tr '[:upper:]' '[:lower:]')"

case "$MSG_LOWER" in
  save|wip|update|fix|test|"test message"|misc|changes|stuff|"."|"update files"|"address feedback"|"review pass"|auto*|"log(auto)"*)
    # Allow the session-end and pre-compact carve-outs (they use --no-verify, never reach this hook)
    echo "BLOCKED: W6 placeholder commit message rejected: \"$MSG\"" >&2
    echo "  format: type(scope): description (imperative mood)" >&2
    echo "  types: feat, fix, refactor, docs, chore, style, test, perf" >&2
    exit 2
    ;;
esac

_cb_record_success
exit 0
```

**Carve-out compatibility**: session-end.sh and pre-compact-commit.sh use
`--no-verify`, which skips PreToolUse hooks entirely. Their auto-generated
`chore(session-end):` and `chore(pre-compact):` messages would not match
the blocklist anyway — but the carve-out means this hook never sees them.
Zero interference with existing auto-commit behavior.

---

## Section 5 — commands/save.md

```markdown
---
name: kernel:save
description: "One-command save: stage, validate message, commit, pull-rebase, push. OPT-IN. Modeled on our4cuts save.sh."
user-invocable: true
allowed-tools: Bash
---

# /kernel:save

Stage all changes, commit with a validated message, sync with remote
(rebase + autostash), and push to the current branch.

## Usage

  /kernel:save "feat(auth): add rate limiting to login endpoint"
  /kernel:save "fix(db): prevent N+1 on user query"

## Message rules (W6 + I0.4)

- Must be non-empty and non-placeholder.
- Blocked: save, wip, update, fix, test, misc, changes, stuff, auto*, log(auto)*
- Recommended format: type(scope): description (imperative mood)

## Invariant gates

- I0.8: push to main/master is blocked unless KERNEL_SYNC_ALLOW_MAIN_PUSH=1 is set.
- I0.9: secret patterns in the diff vs remote block the push.
- I0.5: never uses --no-verify.
- I0.4: no AI attribution injected.

## Config (optional, in .claude/settings.json env block)

  KERNEL_SYNC_ALLOW_MAIN_PUSH=1    allow push to main/master
  KERNEL_SYNC_DRY_RUN=1            validate only, no commit/push
  KERNEL_SYNC_NO_PULL=1            skip the rebase-pull step

## Implementation

Bash: ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/kernel-save.sh "$1"
```

---

## Section 6 — commands/pull.md

```markdown
---
name: kernel:pull
description: "Safe fetch + rebase --autostash. Never destroys uncommitted work."
user-invocable: true
allowed-tools: Bash
---

# /kernel:pull

Fetch remote and rebase your current branch on top of it.
Uncommitted work is auto-stashed and restored.

## Usage

  /kernel:pull

## Conflict handling

If a conflict occurs, the command prints step-by-step resolution
instructions and exits with a non-zero code. Run the steps, then
re-run /kernel:pull to confirm clean.

## Implementation

Bash: ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/kernel-pull.sh
```

---

## Section 7 — hooks.json addition

Add one entry to the existing `PreToolUse` array in `hooks/hooks.json`:

```jsonc
{
  "matcher": "Bash",
  "hooks": [
    {
      "type": "command",
      "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/guard-commit-msg.sh",
      "timeout": 5
    }
  ]
}
```

This sits alongside the existing `guard-bash.sh` Bash entry. Both fire on
every Bash tool call; each has a narrow trigger (guard-bash.sh: rm -rf /
and force-push; guard-commit-msg.sh: git commit with placeholder message).

---

## Section 8 — Solo-dev vs multi-collaborator modes

| Mode | Behavior |
|---|---|
| Solo, feature branch (default) | Push without confirmation. Pull rebases cleanly. Standard flow. |
| Solo, main branch | Blocked unless `KERNEL_SYNC_ALLOW_MAIN_PUSH=1`. Intended friction. |
| Multi-collaborator | Same as solo-feature-branch but conflicts are more likely. The conflict block prints full resolution steps. No "text aria" — all guidance is generic. |

The original save.sh had "text aria" in the conflict block. Kernel is a
plugin used by multiple people. The conflict block says "Run the steps" and
"git rebase --abort to cancel" — no named person.

---

## Section 9 — Migration-safe rollout

**Phase 1 (v7.14.0 or a minor bump):**
- Ship `kernel-save.sh`, `kernel-pull.sh`, `guard-commit-msg.sh`.
- Add `commands/save.md`, `commands/pull.md`.
- Add `guard-commit-msg.sh` to `hooks.json` PreToolUse.
- No existing hook modified. No existing command touched.
- Users who never type `/kernel:save` or `/kernel:pull` see one new PreToolUse
  hook (guard-commit-msg.sh) fire on `git commit` Bash calls. It only blocks
  if the message matches the W6 blocklist. Legitimate commit messages pass through.

**Phase 2 (optional, future):**
- If demand warrants it: add `KERNEL_SYNC_MODE=solo|collab` to automatically
  tune pull frequency (collab: pull before every save; solo: pull only when
  behind by N commits).
- Wire into session-start.sh: if `KERNEL_SYNC_AUTO_PULL=1`, run kernel-pull.sh
  silently at session open to pick up overnight remote changes.

**Rollback:** removing the three scripts and the hooks.json entry fully
reverts the feature. No DB schema changes, no config migration required.

---

## Failure-mode map

| Failure | Root cause | Fix |
|---|---|---|
| guard-commit-msg blocks a legitimate message | Message accidentally matches blocklist pattern (e.g. "fix" alone) | Expand the message: "fix(scope): description" passes |
| kernel-save exits with conflict | Remote branch diverged during work | Follow printed steps: fix markers → git add → git rebase --continue → re-run /kernel:save |
| Push rejected with "rejected non-fast-forward" | Remote has commits not yet pulled | Run /kernel:pull first, then /kernel:save |
| main-push blocked even with ALLOW_MAIN_PUSH=1 | Env var not set in correct settings scope | Set in `.claude/settings.json` env block, not shell profile |
| session-end auto-commit creates duplicate after /kernel:save | session-end runs on dirty tree; /kernel:save already pushed | session-end checks `git status --porcelain`; clean tree = no-op. No duplicate. |
| guard-commit-msg fires on session-end or pre-compact commit | Those scripts use --no-verify which skips PreToolUse hooks entirely | Non-issue by design. |
