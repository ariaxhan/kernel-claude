#!/bin/bash
# Hooks run in parallel and are killed on timeout. A read-only `git status` still takes
# .git/index.lock to write the refreshed index, so a killed or racing hook leaves a zero-byte
# orphan behind and the next foreground `git commit` blocks on it. GIT_OPTIONAL_LOCKS=0 makes
# git skip that optional index write; real writes (add/commit) still take the lock normally.
# Reproduced 2026-08-30: 25 parallel hook git reads orphaned a lock; with this set, none did.
export GIT_OPTIONAL_LOCKS=0
# Stop hook: a session that changed source owes an honest account of what happened.
# Events: Stop
#
# Written as you go, a chronicle is a record. Reconstructed at the end, it is a
# summary -- and a summary is where the failures quietly drop out. The rule that
# produced this gate came from three parallel execution reviews finding the same
# thing: the sessions that hurt later were the ones whose story was never written
# down, so the next session started blind and rediscovered the same wall.
#
# Prose asking for a chronicle does not produce chronicles; roughly 40% of prose
# rules are skipped under load. Hence a gate (I0.15).
#
# It is a gate, not a trap. It refuses ONCE per session, tells you exactly what to
# write and where, and always names an escape hatch. A gate you cannot satisfy is
# worse than no gate: people learn to disable the whole hook chain.
#
# Degraded mode: fail-open-loud. If jq or git is missing we cannot tell whether
# source changed, and blocking the end of a session on a missing parser would trap
# it. Warn instead.

INPUT=$(cat)

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
STATE_DIR="$ROOT/_meta/.runtime"
SEEN_MARKER="$STATE_DIR/chronicle-gate-asked"
SCAFFOLD_COUNTER="$STATE_DIR/scaffolding-only-streak"

if ! command -v git >/dev/null 2>&1; then
  echo "chronicle-gate: warning -- git not found, cannot tell whether this session changed source." >&2
  exit 0
fi

if ! git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  exit 0  # not a repo; nothing to chronicle against
fi

# --- what changed, uncommitted and committed, in this working tree ---
CHANGED=$(git -C "$ROOT" status --porcelain --ignore-submodules=dirty 2>/dev/null | awk '{ $1=""; sub(/^ +/,""); print }')
[ -z "$CHANGED" ] && CHANGED=$(git -C "$ROOT" diff --name-only HEAD~1..HEAD 2>/dev/null)

[ -z "$CHANGED" ] && exit 0  # nothing happened; nothing to record

# Records and scaffolding are not the outcome; they are how the outcome is described.
SOURCE_CHANGED=0
SCAFFOLD_ONLY=1
while IFS= read -r path; do
  [ -z "$path" ] && continue
  case "$path" in
    _meta/*|docs/*|*.md|tests/*|.github/*|governance/*) ;;
    *) SOURCE_CHANGED=1; SCAFFOLD_ONLY=0 ;;
  esac
done <<CHANGES
$CHANGED
CHANGES

# --- scaffolding tripwire (advisory): apparatus outrunning outcomes ---
# Urban-atlas halted a whole phase over this: governance, scripts, manifests, and
# proof scaffolding accumulating while nothing landed. Two consecutive sessions of
# it is the signal to stop and re-bound, not to build a third instrument.
mkdir -p "$STATE_DIR" 2>/dev/null
if [ "$SCAFFOLD_ONLY" = "1" ]; then
  STREAK=$(( $(cat "$SCAFFOLD_COUNTER" 2>/dev/null || echo 0) + 1 ))
  echo "$STREAK" > "$SCAFFOLD_COUNTER" 2>/dev/null
  if [ "$STREAK" -ge 2 ]; then
    echo "chronicle-gate: $STREAK consecutive sessions produced only tooling, docs, or tests and no landed outcome." >&2
    echo "  Halt and re-bound rather than building a third instrument. Apparatus outrunning outcomes is the churn signal." >&2
  fi
else
  rm -f "$SCAFFOLD_COUNTER" 2>/dev/null
fi

[ "$SOURCE_CHANGED" = "0" ] && exit 0

# --- does a chronicle exist for today? ---
YEAR=$(date +%Y)
TODAY=$(date +%Y-%m-%d)
CHRONICLE_DIR="$ROOT/_meta/chronicles/$YEAR"
if [ -d "$CHRONICLE_DIR" ] && ls "$CHRONICLE_DIR"/"$TODAY"*.md >/dev/null 2>&1; then
  rm -f "$SEEN_MARKER" 2>/dev/null
  exit 0
fi

if [ "${KERNEL_CHRONICLE_OK:-0}" = "1" ]; then
  echo "chronicle-gate: source changed with no chronicle; proceeding because KERNEL_CHRONICLE_OK=1." >&2
  exit 0
fi

# Refuse once. A second Stop proceeds, so this can never trap a session.
if [ -f "$SEEN_MARKER" ]; then
  echo "chronicle-gate: still no chronicle. Proceeding -- this gate refuses once, never twice." >&2
  rm -f "$SEEN_MARKER" 2>/dev/null
  exit 0
fi
touch "$SEEN_MARKER" 2>/dev/null

cat >&2 <<EOF
This session changed source and has no chronicle.

Write one small file at _meta/chronicles/$YEAR/$TODAY-<slug>.md covering:
  - what was attempted, and what actually changed
  - what was verified LIVE, with the command that proved it
  - what failed, what was deferred, and any disagreement worth inheriting

One file per session, rewritten rather than accumulated. Honest beats complete:
the failures are the part the next session cannot reconstruct on its own.

Skip deliberately with KERNEL_CHRONICLE_OK=1.
EOF
exit 2
