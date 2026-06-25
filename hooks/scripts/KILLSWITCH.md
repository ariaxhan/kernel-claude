# Runaway-Agent Killswitch

A `PreToolUse` hook that hard-caps how much a single Claude Code session can do,
so a stuck/looping agent can't burn money or churn overnight. Runs once per tool
call across every session. Design + research: `_meta/research/runaway-agent-killswitch-2026.md`.

## What it enforces

- **Tool-call count per session** — a counter keyed to `session_id`, atomically
  incremented once per tool call. The reliable, primary signal.
- **Wall-clock duration** — session start epoch recorded on first tool call;
  compared against `KILLSWITCH_MAX_DURATION` on every call (~1s precision).

When **over cap** (count OR duration), new expensive tools are blocked with exit
2, but **save-work tools stay allowed** so the agent can checkpoint and stop
cleanly (see allowlist below). The block message tells the model to commit, write
a handoff, record state via agentdb, and end.

## What it deliberately does NOT enforce: cost

There is no reliable cost signal available to a hook, so this is a tool-call /
time cap, not a dollar cap:

- `transcript_path` JSONL token fields are **broken placeholders** — `input_tokens`
  reports 100–174x lower than actual (claude-code#28197). Using them for a budget
  would be off by two orders of magnitude.
- `_meta/logs/llm-traces.db` only records `traced_claude()` **subprocess** calls
  (automation scripts), not the main interactive agent loop's spend.

So tool-call count is the proxy. A well-scoped session is tens of calls; the
default cap of 500 is ~several-x a heavy forge, catching true runaways without
false-tripping legit long T3/forge sessions.

## Fail-open policy (why a bug here can't brick you)

This hook runs on **every tool call**. A crash that failed *closed* would block
all work. So **any internal error → exit 0 (allow) with a stderr note**: missing
`jq`, unparseable stdin, no `session_id`, unwritable state dir, lock-acquire
timeout, corrupt counter — all fail open. The **only** exit-2 path is a confirmed
over-cap read of a successfully-incremented counter against a non-allowlisted tool.

It does not source `common.sh` or `circuit-breaker.sh` — a safety gate must
always run, never auto-disable, and never inherit a bug from shared code (I0.15).

(macOS note: `flock` is absent here, so atomic increment uses a `mkdir` spinlock —
`mkdir` is atomic on POSIX. Lock-acquire failure fails open.)

## Save-work allowlist (permitted even over-cap)

- `Read`, `Write`, `Edit`, `TodoWrite` — always allowed (read state, write handoff/chronicle).
- `Bash` **only** when the command (after stripping leading `VAR=val` env prefixes) starts with:
  `git commit`, `git add`, `git push`, `git status`, `git diff`, `git log`,
  `agentdb …`, `echo …`, `cat …`.
- Everything else over-cap is **blocked**: general `Bash` (builds, installs, tests,
  `curl`), `WebSearch`, `WebFetch`, `Task`/subagent spawns, etc.
- The match is prefix-anchored, so `git clone` / `git config` do **not** sneak
  through the `git commit` allowance.

## Config (env var > default)

| Env var | Default | Meaning |
|---|---|---|
| `KILLSWITCH_MAX_TOOLS` | `500` | Hard cap: tool calls per session |
| `KILLSWITCH_WARN_PERCENT` | `80` | Soft-warn threshold (% of max) → at 400, one stderr nudge |
| `KILLSWITCH_MAX_DURATION` | `7200` | Wall-clock seconds (2h); `0` disables duration cap |
| `KILLSWITCH_OFF` | unset | `1` disables the killswitch entirely |

At 80% the hook emits a one-time stderr warning (`⚠ killswitch: N/MAX … wrap up`)
so it lands in the model's context without blocking. It warns **once** per
crossing, not every call after.

## State location (project-agnostic)

The kernel plugin is general, so state is **not** under `_meta/`. It's derived
from the environment:

- `${CLAUDE_PROJECT_DIR}/.claude/.killswitch/` if `CLAUDE_PROJECT_DIR` is set,
- else `${TMPDIR:-/tmp}/claude-killswitch/`.

Per session: `<state>/<session_id>.count`, `.start` (start epoch), `.warned` (flag).
New session = new `session_id` UUID = fresh counter, so multiple windows are
naturally isolated (canon: `kill-autopush-multiwindow`).

## SessionStart init + stale sweep

`killswitch-init.sh` (SessionStart) initializes this session's counter to 0
(unless `source == "resume"`, where the counter is preserved) and **sweeps state
files older than 24h**. This is critical: it stops a new session from inheriting a
stale over-cap counter and getting instantly bricked.

## Ops commands

`killswitch-status.sh` (run from a shell; it is not a hook):

```bash
# check current counts (all sessions, or one)
hooks/scripts/killswitch-status.sh check [session_id]
hooks/scripts/killswitch-status.sh list

# reset (all, or one session) — kills the counter file
hooks/scripts/killswitch-status.sh reset [session_id]

# engage / clear the override (bypass) file
hooks/scripts/killswitch-status.sh override on    # bypass killswitch
hooks/scripts/killswitch-status.sh override off   # re-arm

# or escape per-shell without a file:
KILLSWITCH_OFF=1 claude
```

Resetting is rarely needed — just starting a new session gives a fresh counter.

## CRITICAL: stays on PreToolUse, never Stop

This **must** stay wired to `PreToolUse`. Do **not** move it to the `Stop` hook.
A `Stop` hook exiting 2 forces Claude to **keep working** (the opposite of a
killswitch). Blocking forward tool calls at `PreToolUse` is what makes the agent
run out of tools and stop. (Design doc failure #12.)
