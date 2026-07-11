#!/bin/bash
# PreToolUse hook: enforce manifest context policy (sealed | bounded | advisory)
# Events: PreToolUse (matcher: Read|Grep|Glob)
#
# The yaml<->hook symbiosis: /kernel:ingest activates a manifest via
# `kernel-manifest activate`, which writes _meta/.active-manifest.json.
# This hook reads that pointer and enforces the manifest's context policy:
#   sealed  -> BLOCK (exit 2) access to paths matching context.forbidden globs
#   bounded -> allow, but append the access to _meta/.context-ledger for
#              receipt accounting (merged at `kernel-manifest deactivate`)
#   advisory-> allow, no enforcement
#
# Fail modes (fallback-first, I0.15):
#   - no pointer file        -> allow (no manifest active; normal session)
#   - pointer unparseable + mode unknown -> BLOCK reads of _meta/.active-manifest
#     is pointless; instead: if the pointer exists but jq fails, we cannot know
#     whether the session is sealed, so we BLOCK with a clear message. A sealed
#     experiment must never silently degrade to unsealed.
#   - jq missing             -> same: pointer present = block with message.

POINTER="_meta/.active-manifest.json"
LEDGER="_meta/.context-ledger"

[ -f "$POINTER" ] || exit 0

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  echo "guard-context: manifest active but jq missing — cannot verify context policy. Blocking (install jq or run kernel-manifest deactivate)." >&2
  exit 2
fi

MODE=$(jq -r '.mode // empty' "$POINTER" 2>/dev/null)
if [ -z "$MODE" ]; then
  echo "guard-context: manifest pointer unreadable — cannot verify context policy. Blocking (re-run kernel-manifest activate, or deactivate)." >&2
  exit 2
fi

[ "$MODE" = "advisory" ] && exit 0

# Extract the target path(s) from the tool input
TARGET=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // .tool_input.pattern // empty' 2>/dev/null)
[ -z "$TARGET" ] && exit 0

if [ "$MODE" = "sealed" ]; then
  # Block access to any forbidden glob
  while IFS= read -r glob; do
    [ -z "$glob" ] && continue
    case "$TARGET" in
      $glob)
        echo "BLOCKED by sealed manifest: '$TARGET' matches forbidden glob '$glob'" >&2
        echo "  Manifest: $(jq -r '.manifest' "$POINTER")" >&2
        echo "  Sealed runs prohibit contaminating context. If this access is genuinely needed, amend the manifest and re-activate." >&2
        exit 2
        ;;
    esac
  done < <(jq -r '.forbidden[]?' "$POINTER" 2>/dev/null)
  exit 0
fi

if [ "$MODE" = "bounded" ]; then
  # Allow, but ledger the access for receipt accounting.
  printf '{"path":"%s","reason":"unstated (agent must justify in receipt)","ts":"%s"}\n' \
    "$(echo "$TARGET" | sed 's/"/\\"/g')" \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LEDGER" 2>/dev/null || true
  exit 0
fi

exit 0
