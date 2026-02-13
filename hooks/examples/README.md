# AgentDB Hooks

Example hooks implementing the AgentDB architecture for persistent agent context.

**Created:** 2026-01-28
**Author:** Aria Han

---

## What This Does

These hooks make agent context durable:

1. **Session tracking** - Agents register on start, deregister on end
2. **Context checkpoints** - Save state before compaction
3. **Multi-agent coordination** - See other active agents
4. **Automatic commits** - Batch and push changes at lifecycle boundaries

---

## Files

| Hook | Event | Purpose |
|------|-------|---------|
| `session-start.sh` | SessionStart | Load context, register agent, set env vars |
| `session-end.sh` | SessionEnd | Deregister, batch commit, push |
| `pre-compact-commit.sh` | PreCompact | Save snapshot, commit checkpoint |

---

## Setup

### 1. Create directories

```bash
mkdir -p _meta/agents _meta/context _meta/logs
echo "# Session Context" > _meta/context/active.md
```

### 2. Copy hooks

```bash
mkdir -p .claude/hooks
cp hooks/examples/*.sh .claude/hooks/
chmod +x .claude/hooks/*.sh
```

### 3. Configure settings

Add to `.claude/settings.local.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/session-start.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/pre-compact-commit.sh",
            "timeout": 60,
            "statusMessage": "Saving checkpoint..."
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/session-end.sh",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

---

## Agent Registry

On session start, each agent registers at `_meta/agents/{name}.json`:

```json
{
  "session_id": "abc123...",
  "model": "claude-opus-4-5-20251101",
  "agent_name": "swift-jade",
  "pid": 12345,
  "started": "2026-02-13T14:30:00Z",
  "cwd": "/path/to/project",
  "branch": "main",
  "source": "startup",
  "status": "active"
}
```

Names are Docker-style (adjective-noun) generated deterministically from session ID.

---

## Checkpoints

Before compaction, agents save snapshots to `_meta/agents/{name}-snapshot.md`:

```markdown
# Context Snapshot: swift-jade
**Saved**: 2026-02-13T14:30:00Z
**Trigger**: auto compact
**Branch**: main

## Recent Commits
abc1234 feat: add user auth
def5678 fix: login redirect

## Uncommitted Changes
M src/auth.ts
A src/login.ts

## Other Active Agents
- deep-mesa (branch: feature/api, since: 2026-02-13T12:00:00Z)
```

---

## Dependencies

- `jq` - JSON parsing (install via `brew install jq` or `apt install jq`)
- `git` - Version control
- Bash 4+ (macOS default is 3.2, may need `brew install bash`)

---

## Architecture Reference

See `_meta/docs/agentdb-architecture.md` for full documentation.

---

*First committed: 2026-01-28 in ariaxhan/Vaults*
