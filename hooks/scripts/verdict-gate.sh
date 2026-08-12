#!/bin/bash
# PreToolUse hook: refuse to record a review verdict that cannot be relied on.
# Events: PreToolUse (matcher: Write|Edit)
#
# Applicable only to verdict documents: inert unless the payload declares
# "kernel.verdict/v1". Where it applies it is fail-closed, because its dangerous
# direction is YES -- accepting a verdict nobody can trust is the whole defect
# class this exists to kill (#204). Arming is detected without jq or python3 so
# that a missing dependency refuses the write instead of waving it through.
#
# What it refuses:
#   - a verdict with an empty or missing cannot_falsify. Silence about coverage
#     reads as coverage. Two flagship gates in this ecosystem printed PASS for
#     weeks because ripgrep was not installed and nothing said so.
#   - a verdict whose stated outcome disagrees with adjudication, i.e. an agent
#     writing PASS over findings that clear the block bar, or FAIL over findings
#     that do not. The critic proposes; scripts/adjudicate.py decides.
#   - a FAIL written over a commit already frozen by a recorded acceptance with
#     no recognised reopen event. That is a fresh reviewer relitigating settled
#     work, which is the tax itself, and it is refused here rather than argued
#     about downstream.
#
# What it deliberately does NOT do: judge whether the findings are correct. That
# is not a hook's job and pretending otherwise would make it a gate that cannot
# fail honestly.

INPUT=$(cat)

# Arming is detected on the RAW payload with no external dependency. Doing this with jq first
# was a fail-dark bug the violation corpus caught on its first run: with jq missing the extraction
# returned empty, the marker never matched, and a verdict write sailed through the gate meant to
# check it. A fence that fails dark is a leash you think you are holding.
case "$INPUT" in
  *kernel.verdict/v1*) ;;
  *) exit 0 ;;
esac

# Applicable from here on: every failure below is a refusal, never a shrug.
if ! command -v jq >/dev/null 2>&1; then
  echo "BLOCKED: verdict gate cannot run (jq not found). A verdict recorded without its gate is not a verdict." >&2
  exit 2
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "BLOCKED: verdict gate cannot run (python3 not found). Install python3 or do not record a verdict." >&2
  exit 2
fi

CONTENT=$(printf '%s' "$INPUT" | jq -r '
  [.tool_input.content, .tool_input.new_string,
   (if (.tool_input.patch | type) == "string" then
      [.tool_input.patch | split("\n")[] | select(startswith("+"))] | join("\n")
    else empty end)]
  | map(select(type == "string"))
  | join("\n")
' 2>/dev/null)

# The marker was in the payload but not in the written content (a tool_use echo, a log line).
[ -z "$CONTENT" ] && exit 0
case "$CONTENT" in
  *kernel.verdict/v1*) ;;
  *) exit 0 ;;
esac

ADJ="$(dirname "$0")/../../scripts/adjudicate.py"
if [ ! -f "$ADJ" ]; then
  echo "BLOCKED: verdict gate cannot find scripts/adjudicate.py. Refusing rather than waving a verdict through." >&2
  exit 2
fi

# The written document may be the findings input or an already-adjudicated verdict;
# adjudicate.py is idempotent over both because it reads .findings and .cannot_falsify.
RESULT=$(printf '%s' "$CONTENT" | python3 "$ADJ" - 2>/dev/null)
if [ -z "$RESULT" ]; then
  echo "BLOCKED: verdict document declares kernel.verdict/v1 but could not be adjudicated (malformed JSON?)." >&2
  exit 2
fi

ADJUDICATED=$(printf '%s' "$RESULT" | jq -r '.verdict')
ERRORS=$(printf '%s' "$RESULT" | jq -r '.errors[]?' 2>/dev/null)

if [ "$ADJUDICATED" = "INVALID" ]; then
  echo "BLOCKED: this verdict is INVALID, which is not a soft pass -- nobody may rely on the run." >&2
  printf '%s\n' "$ERRORS" >&2
  echo "Fix: declare cannot_falsify. Name what no instrument in this run could structurally see, and every claim whose instrument did not finish. An unfinished instrument is red, never neutral." >&2
  exit 2
fi

# If the author stated an outcome, it must match what adjudication produced.
CLAIMED=$(printf '%s' "$CONTENT" | jq -r '.verdict // empty' 2>/dev/null)
if [ -n "$CLAIMED" ] && [ "$CLAIMED" != "$ADJUDICATED" ]; then
  echo "BLOCKED: verdict says $CLAIMED, adjudication of its own findings says $ADJUDICATED." >&2
  echo "The critic proposes findings; scripts/adjudicate.py decides the verdict. Never ask the critic whether criticism is complete." >&2
  if [ "$(printf '%s' "$RESULT" | jq -r '.frozen')" = "true" ]; then
    echo "This commit was already accepted. Reopening takes new evidence, not a new opinion: one of" >&2
    echo "  new_failing_input · changed_dependency · missed_requirement · disproven_assumption · profile_changed · owner_promotion" >&2
    printf '%s' "$RESULT" | jq -r '.finality[]? | "  \(.)"' >&2
  fi
  printf '%s' "$RESULT" | jq -r '.blocking[]? | "  BLOCK d\(.distance) \(.summary)"' >&2
  exit 2
fi

exit 0
