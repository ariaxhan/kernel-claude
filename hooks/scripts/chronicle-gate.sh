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
# It is a gate, not a trap: it tells you exactly what to write and where, accepts a
# one-line "nothing was owed" note as satisfaction, and yields after three refusals
# so it can never strand a session. A gate you cannot satisfy is worse than no gate.
#
# REVISED 2026-09-01 after a usage audit measured what it was actually doing:
# KERNEL_CHRONICLE_OK=1 appeared 402 times across 262 sessions against 3 real
# first-refusals. Two design choices made it decorative, and both are fixed here.
#
#   1. It refused ONCE PER SESSION and then yielded forever. A Stop hook that
#      cannot refuse twice is a reminder wearing a gate's clothes. It now refuses
#      up to three times, escalating, and says on the last one that it is done.
#   2. Its own refusal text ended with "Skip deliberately with KERNEL_CHRONICLE_OK=1",
#      which taught every agent that read it how to never see the gate again. The
#      variable still works, for automation that legitimately needs it, but the
#      gate no longer advertises it. A guard that hands out its own bypass is
#      running a tutorial for the thing it exists to prevent.
#
# The cheap compliant path matters more than either. Agents overrode because
# overriding was cheaper than complying. A one-line file saying WHY nothing was
# owed is cheaper than setting an env var, and unlike the env var it leaves a
# record the next session can read.
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
# Either a real chronicle or an explicit "nothing was owed" note satisfies this.
# The second is the cheap path: the gate was being bypassed because bypassing cost
# one environment variable and complying cost a document. A single honest line is
# cheaper than the bypass and, unlike the bypass, the next session can read it.
if [ -d "$CHRONICLE_DIR" ] && ls "$CHRONICLE_DIR"/"$TODAY"*.md >/dev/null 2>&1; then
  rm -f "$SEEN_MARKER" 2>/dev/null
  exit 0
fi

# Still honoured, for CI and automation that genuinely cannot write a file. Not
# advertised in the refusal below: see the 402-to-3 note at the top of this file.
if [ "${KERNEL_CHRONICLE_OK:-0}" = "1" ]; then
  echo "chronicle-gate: source changed with no chronicle; proceeding because KERNEL_CHRONICLE_OK=1." >&2
  exit 0
fi

# Refuse up to three times, then yield. Never traps a session; also never lets one
# walk past on the first shrug, which is what "refuses once, never twice" allowed.
MAX_REFUSALS=3
ASKED=$(cat "$SEEN_MARKER" 2>/dev/null || echo 0)
case "$ASKED" in ''|*[!0-9]*) ASKED=0 ;; esac
if [ "$ASKED" -ge "$MAX_REFUSALS" ]; then
  echo "chronicle-gate: $ASKED refusals, still no chronicle. Proceeding, and this is the last time it asks." >&2
  echo "  What happened in this session is now unrecoverable for whoever picks it up next." >&2
  rm -f "$SEEN_MARKER" 2>/dev/null
  exit 0
fi
ASKED=$((ASKED + 1))
echo "$ASKED" > "$SEEN_MARKER" 2>/dev/null

cat >&2 <<EOF
This session changed source and has no chronicle. (Asked $ASKED of $MAX_REFUSALS.)

Write one small file at _meta/chronicles/$YEAR/$TODAY-<slug>.md covering:
  - what was attempted, and what actually changed
  - what was verified LIVE, with the command that proved it
  - what failed, what was deferred, and any disagreement worth inheriting

One file per session, rewritten rather than accumulated. Honest beats complete:
the failures are the part the next session cannot reconstruct on its own.

If this session genuinely owed nothing, say so in one line and that also satisfies
this gate:

  echo 'Nothing owed: <why>' > _meta/chronicles/$YEAR/$TODAY-skipped.md

Size the record to the consequence. A write-up longer than the work is a defect too.
EOF
exit 2
