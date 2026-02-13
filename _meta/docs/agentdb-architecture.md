# AgentDB: Agent Context as First-Class Versioned Data

**Author:** Aria Han
**Created:** 2026-01-27
**Repository:** Vaults (private), kernel-claude (public)

---

## Abstract

AgentDB is an architecture for treating AI agent context as a first-class, versioned primitive that lives alongside code in Git. Rather than letting agent sessions disappear when terminals close, AgentDB captures session state, reasoning, mutations, and coordination data as structured files that persist across sessions and enable multi-agent collaboration.

This document establishes the architectural principles and implementation details of the system, as committed to the Vaults repository starting January 27, 2026.

---

## Timeline

| Date | Commit | Description |
|------|--------|-------------|
| 2026-01-27 | `c1025f0` | `feat: initialize NEXUS unified orchestrator` |
| 2026-01-28 | `03b58bd` | `feat(hooks): implement native Claude Code hooks` |
| 2026-01-28 | `92358cb` | `feat(hooks): add post-execution pipeline + emphasize _meta` |
| 2026-01-30 | `a11466c` | Agent registry + multi-agent coordination |
| 2026-02-01 | `9c44440` | Full hooks system operational (10 files changed) |
| 2026-02-10 | External | Entire Inc. announces similar system with $60M seed |

All commits verifiable in `ariaxhan/Vaults` git history.

---

## Core Thesis

**Agent context is not ephemeral.** The prompts, reasoning, tool calls, and decisions that produce code are as valuable as the code itself. Without context, agents:

- Retrace steps across sessions
- Duplicate reasoning and waste tokens
- Lose the thread of decisions made hours or days earlier
- Cannot coordinate effectively in multi-agent scenarios

AgentDB makes agent context durable by:

1. **Capturing session state** at lifecycle boundaries
2. **Versioning context** alongside code in Git
3. **Enabling multi-agent coordination** through a shared registry
4. **Automating checkpoints** before context compaction

---

## Architecture

### 1. Agent Registry (`_meta/agents/`)

Every agent session registers itself on startup with:

```json
{
  "session_id": "abc123...",
  "model": "claude-opus-4-5-20251101",
  "agent_name": "swift-jade",
  "pid": 12345,
  "started": "2026-02-13T14:30:00Z",
  "cwd": "/Users/aria/projects/vaults",
  "branch": "main",
  "source": "startup",
  "status": "active"
}
```

**Key features:**
- Docker-style memorable names (adjective-noun) from session ID hash
- PID tracking for stale agent cleanup
- Branch awareness for multi-branch coordination
- Auto-deregistration on session end

**Implementation:** `session-start.sh` (lines 17-53)

### 2. Context Persistence (`_meta/context/active.md`)

The current session state document, loaded at startup and updated throughout:

- What the agent is working on
- Recent decisions and their rationale
- Blockers and open questions
- Git state summary

**Staleness detection:** Hook warns if active.md > 48 hours old.

### 3. Checkpoint Snapshots (`_meta/agents/{name}-snapshot.md`)

Before context compaction, each agent saves its state:

- Recent commits
- Uncommitted changes
- Other active agents
- Timestamp and trigger type

**Implementation:** `pre-compact-commit.sh`

### 4. Action Logging (`_meta/logs/`)

- `actions.jsonl` - File mutations with timestamps
- `costs.jsonl` - Model routing and token usage
- Per-agent logging enables cost attribution

---

## Hooks System

10 hooks covering the full session lifecycle:

| Hook | Event | Purpose |
|------|-------|---------|
| `session-start.sh` | SessionStart | Load context, register agent, set env vars |
| `guard-claude-dir.sh` | PreToolUse (Write\|Edit) | Block writes to .claude/ (READ-ONLY invariant) |
| `guard-bash.sh` | PreToolUse (Bash) | Block destructive git ops |
| `auto-approve-safe.sh` | PermissionRequest (Bash) | Auto-approve read-only commands |
| `log-write.sh` | PostToolUse (Write\|Edit) | Async write logging |
| `log-routing.sh` | PostToolUse (Task) | Agent routing/cost logging |
| Stop prompt | Stop | Verify task completion |
| `pre-compact-commit.sh` | PreCompact | Save snapshot, commit checkpoint |
| `session-end.sh` | SessionEnd | Deregister agent, batch commit, push |
| `agentdb-track-mutation.sh` | PostToolUse | Track file mutations per-agent |

**Configuration:** `.claude/settings.local.json`

---

## Multi-Agent Coordination

When multiple agents are active:

1. Each registers in `_meta/agents/`
2. SessionStart hook shows other active agents
3. Each works on own branch/worktree
4. Stale agents (dead PIDs) auto-cleaned

**Example output at session start:**

```
## Active Agents (2 others)
- deep-mesa (branch: feature/auth)
- swift-jade (branch: main)
```

---

## Git Integration

Context is versioned alongside code:

1. **Checkpoint commits** before compaction
2. **Session-end commits** batch pending changes
3. **Agent attribution** in commit messages: `[agent-name]`
4. **Submodule-aware** - handles nested repos

Commit format:
```
chore(session-end): Vaults [swift-jade] (3 files) 2026-02-13 14:30
chore(checkpoint): pre-compact [deep-mesa] (auto, 5 files) 2026-02-13 14:25
```

---

## Comparison to Similar Approaches

### Entire (announced 2026-02-10)

| Feature | AgentDB (Vaults) | Entire |
|---------|-----------------|--------|
| Session capture | `_meta/agents/*.json` | "Checkpoints" |
| Context persistence | `active.md` + snapshots | Checkpoint branches |
| Multi-agent tracking | Agent registry + PID | "Multi-session support" |
| Git integration | Native (hooks) | CLI + separate branch |
| Token tracking | `costs.jsonl` | "Token usage" field |
| Mutation tracking | `actions.jsonl` | "Files touched" field |
| First commit | 2026-01-27 | 2026-02-10 (announce) |

---

## Files

```
Vaults/
├── .claude/
│   ├── settings.local.json    # Hook configuration
│   └── hooks/
│       ├── session-start.sh   # Context load + agent registration
│       ├── session-end.sh     # Deregister + batch commit
│       ├── pre-compact-commit.sh  # Checkpoint before compaction
│       ├── guard-claude-dir.sh    # .claude/ write protection
│       ├── guard-bash.sh          # Destructive command blocking
│       ├── auto-approve-safe.sh   # Read-only auto-approval
│       ├── log-write.sh           # Async mutation logging
│       └── log-routing.sh         # Agent routing logging
├── _meta/
│   ├── agents/                # Agent registry
│   │   ├── {name}.json        # Active agent state
│   │   └── {name}-snapshot.md # Compaction snapshots
│   ├── context/
│   │   └── active.md          # Session state
│   ├── logs/
│   │   ├── actions.jsonl      # Mutation log
│   │   └── costs.jsonl        # Cost tracking
│   └── docs/
│       └── hooks-research.md  # 896-line hooks specification
```

---

## Usage

### Enable AgentDB

1. Copy hooks to `.claude/hooks/`
2. Add hook configuration to `.claude/settings.local.json`
3. Create `_meta/agents/` and `_meta/logs/` directories
4. Initialize `_meta/context/active.md`

### Session Flow

```
SessionStart:
  → session-start.sh runs
  → Loads active.md as context
  → Registers agent in _meta/agents/
  → Sets AGENT_NAME env var
  → Shows other active agents

During Session:
  → Write/Edit mutations logged to actions.jsonl
  → Task routing logged to costs.jsonl
  → .claude/ writes blocked by guard hook

PreCompact (auto or manual):
  → pre-compact-commit.sh runs
  → Saves snapshot to _meta/agents/{name}-snapshot.md
  → Commits all pending changes
  → Pushes to remote

SessionEnd:
  → session-end.sh runs
  → Deregisters agent (removes JSON)
  → Batch commits remaining changes
  → Pushes to remote
  → Cleans stale agents (dead PIDs)
```

---

## References

- `ariaxhan/Vaults` - Private implementation repository
- `ariaxhan/kernel-claude` - Public Claude Code configuration
- `_meta/docs/hooks-research.md` - 896-line hooks specification
- Claude Code hooks documentation: https://code.claude.com/docs/en/hooks

---

*AgentDB: Because agent context is too valuable to throw away.*
