# CONTEXT HANDOFF
Generated: 2026-03-13

**Summary**: Infrastructure session — got kernel-claude plugin v7.0.2 installed with working symlinks and hooks, now moving to plugin dev machine to implement team sync + hook improvements natively in the plugin source.

**Goal**: Team-wide seamless sync of `_meta/` + `claude/` via GitLab, with hooks that auto-pull on session start and auto-push on session end. Also fix hooks to be natively registered (not manually patched into settings.json).

**Current state**: Plugin installed and working on this machine. Git repo for Vaults sync not yet created. Hook registration workaround in place but not the right long-term solution. Moving to dev machine to do it properly in plugin source.

**Branch**: none (Vaults is not a git repo yet — that's the next step)

**Tier**: 2 — moderate, 3-5 systems touched

---

## Decisions Made

- **Symlink direction**: `.claude → claude` (real dir = visible name). Reverse (`claude → .claude`) fails because Obsidian resolves symlink targets and skips dotfolders.
- **`current` symlink pattern**: `~/.claude/plugins/cache/kernel-marketplace/kernel/current → 7.0.2`. All paths (hooks, settings.json) go through `current` so version bumps = one symlink repoint, nothing else changes.
- **Vault symlinks**: `hooks/`, `rules/`, `skills/`, `commands/`, `docs/`, `orchestration/` all symlinked into Vaults root pointing through `current`. Visible in Obsidian, auto-update on version bump.
- **Hooks in settings.json**: Claude Code does NOT auto-register plugin `hooks/hooks.json`. Must be in `~/.claude/settings.json` with absolute paths. **This is the workaround — the native fix belongs in the plugin.**
- **Sync strategy**: Vaults root as git repo, `.gitignore` allowlists only `_meta/` + `claude/`. Session hooks auto-pull/push. agent.db committed directly (40KB, non-concurrent writes make conflicts unlikely for this team).
- **Rejected**: SQL export/import (too complex). Obsidian Sync (per-user, not team). iCloud/Dropbox (not dev-team appropriate).

---

## Artifacts Created

- `_meta/research/infra/kernel-claude-setup-guide.md` — full setup guide for any teammate
- `_meta/research/infra/mcp-setup-guide.md` — updated (already existed, verified current)
- `~/.claude/settings.json` — hooks section added (7 hooks, absolute paths via `current` symlink)
- `~/.claude/plugins/cache/kernel-marketplace/kernel/current` — symlink → `7.0.2`
- `~/.claude/plugins/cache/kernel-marketplace/kernel/7.0.2/` — installed from marketplace pull
- Vault symlinks: `.claude→claude`, `claude-global→~/.claude`, `hooks`, `rules`, `skills`, `commands`, `docs`, `orchestration`

---

## What Needs To Happen On The Dev Machine

### 1. Fix hooks natively in plugin source

The core issue: Claude Code doesn't auto-load `hooks/hooks.json` from marketplace plugins. This means every user has to manually patch `~/.claude/settings.json`.

**Native fix options (pick one, implement in plugin):**
- **Option A**: Plugin installer copies hooks into global `settings.json` during `plugin install` — requires Claude Code plugin API support for this
- **Option B**: `plugin.json` adds a `hooks` field that Claude Code reads natively — check if Claude Code supports this in plugin manifest spec
- **Option C**: Ship a `kernel-setup.sh` script in the plugin that users run once — it patches their `settings.json` automatically with correct absolute paths. Simplest, works today.
- **Option D**: The hooks use a smarter path resolution — instead of `${CLAUDE_PROJECT_DIR}/hooks/...`, find the plugin binary via `which agentdb` or a known relative path from the script itself (`SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"`)

**Recommended: Option D** — make hook scripts self-locating using `SCRIPT_DIR`. Then hooks.json can use a wrapper that doesn't depend on CLAUDE_PROJECT_DIR at all. This removes the need for any manual settings.json patching.

```bash
# In each hook script, replace:
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-...}"
AGENTDB="${PROJECT_ROOT}/orchestration/agentdb/agentdb"

# With:
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"  # hooks/scripts/ → plugin root
AGENTDB="${PLUGIN_ROOT}/orchestration/agentdb/agentdb"
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
```

And hooks.json command becomes just the script path (which is absolute once Claude Code expands the plugin install path).

### 2. Add git sync to session hooks

In `hooks/scripts/session-start.sh`, add at the very top (before existing content):
```bash
# Team sync: pull latest _meta + claude from GitLab
if [ -d "${PROJECT_ROOT}/.git" ]; then
  git -C "$PROJECT_ROOT" pull --rebase --autostash 2>/dev/null || true
fi
```

In `hooks/scripts/session-end.sh`, add before exit:
```bash
# Team sync: push _meta + claude to GitLab
if [ -d "${PROJECT_ROOT}/.git" ]; then
  git -C "$PROJECT_ROOT" add _meta/ claude/ 2>/dev/null || true
  git -C "$PROJECT_ROOT" commit -m "sync: $(hostname -s) session $(date +%Y%m%d-%H%M)" --no-verify 2>/dev/null || true
  git -C "$PROJECT_ROOT" push 2>/dev/null || true
fi
```

### 3. Create the GitLab repo + init Vaults as git repo

```bash
# On the dev machine (or via MCP from either machine):
# 1. Create repo: sizdevteam1/fun-joiner/vaults-sync (or similar name)
# 2. On this machine:
cd ~/Vaults
git init
cat > .gitignore << 'EOF'
# Only track _meta/ and claude/
/*
!_meta/
!claude/
!.gitignore

# Ignore agentdb temp files
_meta/agentdb/agent.db-wal
_meta/agentdb/agent.db-shm

# Ignore Obsidian workspace state
claude/.obsidian/workspace.json
EOF
git add _meta/ claude/ .gitignore
git commit -m "init: vaults sync repo"
git remote add origin git@gitlab.com:sizdevteam1/.../vaults-sync.git
git push -u origin main
```

### 4. Merge the second machine's AgentDB

On the second machine (dev machine), after cloning:
```bash
# Export learnings from dev machine DB
sqlite3 ~/Vaults/_meta/agentdb/agent.db \
  "SELECT 'INSERT OR IGNORE INTO learnings(id,type,insight,evidence,domain,created_at) VALUES(' || quote(id) || ',' || quote(type) || ',' || quote(insight) || ',' || quote(evidence) || ',' || quote(coalesce(domain,'')) || ',' || quote(created_at) || ');' FROM learnings;" \
  > /tmp/dev-machine-learnings.sql

# On this machine (or after push), import:
sqlite3 ~/Vaults/_meta/agentdb/agent.db < /tmp/dev-machine-learnings.sql
```

### 5. Create Confluence pages (4)

Can be done from either machine via Atlassian MCP:
- **KERNEL Claude Plugin — Setup Guide** (from `_meta/research/infra/kernel-claude-setup-guide.md`)
- **MCP Server Setup Guide** (from `_meta/research/infra/mcp-setup-guide.md`)
- **Obsidian Setup** (brief: install, open Vaults as vault, symlinks handled by KERNEL setup)
- **Team AgentDB + `_meta` Sync** (git repo setup, onboarding steps, hook behavior)

---

## Open Threads

- **BLOCKER**: Hooks still require manual `settings.json` patch — native fix needed in plugin source (see Option D above)
- **TODO**: Create GitLab repo + init Vaults git repo
- **TODO**: Merge dev machine AgentDB into this one (or vice versa)
- **TODO**: Add git pull/push to session-start + session-end in plugin source
- **TODO**: Create 4 Confluence pages
- **TODO**: Test session-start hook fires correctly after Claude Code restart (scripts verified working manually, just needs restart)
- **TODO**: Global `~/.claude/settings.json` hooks reference copy → `claude/settings.global.json` in repo

---

## Warnings

- `claude → .claude` symlink direction FAILS in Obsidian — must be `.claude → claude`
- `${CLAUDE_PROJECT_DIR}` in hook command paths is unreliable for user-scoped plugins — use SCRIPT_DIR self-location instead
- Don't sync `agent.db-wal` and `agent.db-shm` — these are SQLite temp files, gitignore them
- Don't sync `claude/.obsidian/workspace.json` — this is per-user UI state, conflicts constantly
- `plugin.json` must be bumped (version field) for Claude Code to recognize a new install — don't forget this on each release
- Marketplace git clone and plugin cache are separate — `git pull` updates the clone but cache still has old version, must rsync + repoint `current` symlink

---

## Continuation Prompt

> /kernel:ingest — continuing from handoff `_meta/handoffs/kernel-sync-setup-2026-03-13.md`. On dev machine. Goal: (1) fix hooks to be self-locating in plugin source (Option D), (2) add git pull/push to session hooks, (3) create GitLab vaults-sync repo, (4) merge AgentDBs, (5) post 4 Confluence pages. Start with hook native fix — that unblocks everything else.
