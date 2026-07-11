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

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
if [ ! -f "$ROOT/_meta/.active-manifest.json" ]; then
  SEARCH_DIR="$PWD"
  while [ "$SEARCH_DIR" != "/" ]; do
    if [ -f "$SEARCH_DIR/_meta/.active-manifest.json" ]; then
      ROOT="$SEARCH_DIR"
      break
    fi
    SEARCH_DIR="$(dirname "$SEARCH_DIR")"
  done
fi
POINTER="$ROOT/_meta/.active-manifest.json"
LEDGER="$ROOT/_meta/.context-ledger"

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

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

DECISION=$(
  GUARD_ROOT="$ROOT" HOOK_INPUT="$INPUT" python3 - "$POINTER" <<'PY'
import fnmatch
import json
import os
import subprocess
import sys

pointer_path = sys.argv[1]
event = json.loads(os.environ.get("HOOK_INPUT", "{}") or "{}")
pointer = json.load(open(pointer_path, encoding="utf-8"))
tool = event.get("tool_name") or ""
tool_input = event.get("tool_input") or {}
forbidden = [g for g in pointer.get("forbidden") or [] if g]

try:
    root = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        timeout=2,
        check=True,
    ).stdout.strip()
except Exception:
    root = os.environ.get("GUARD_ROOT") or os.getcwd()
root = os.path.realpath(root)

def relpath(path):
    if not path:
        return ""
    raw = os.path.expanduser(str(path))
    abs_path = raw if os.path.isabs(raw) else os.path.join(os.getcwd(), raw)
    norm = os.path.normpath(abs_path)
    real = os.path.realpath(norm)
    out = []
    for candidate in (norm, real):
        if candidate == root:
            rel = "."
        elif candidate.startswith(root + os.sep):
            rel = os.path.relpath(candidate, root)
        else:
            rel = candidate
        out.append(rel.replace(os.sep, "/"))
    return "|".join(dict.fromkeys(out))

def fixed_prefix(glob):
    parts = []
    for part in glob.replace("\\", "/").split("/"):
        if any(ch in part for ch in "*?["):
            break
        if part:
            parts.append(part)
    return "/".join(parts)

def matches_path(rel):
    candidates = [p for p in rel.split("|") if p]
    for candidate in candidates:
        for glob in forbidden:
            clean = glob.replace("\\", "/").lstrip("./")
            if fnmatch.fnmatchcase(candidate, clean):
                return glob, candidate
    return None, None

def scope_contains_forbidden(scope):
    if not forbidden:
        return None
    rel = relpath(scope or ".")
    candidates = [p.rstrip("/") for p in rel.split("|") if p]
    for candidate in candidates:
        if candidate in ("", "."):
            return forbidden[0]
        for glob in forbidden:
            prefix = fixed_prefix(glob)
            if not prefix:
                return glob
            prefix = prefix.rstrip("/")
            if candidate == prefix or prefix.startswith(candidate + "/") or candidate.startswith(prefix + "/"):
                return glob
    return None

target = ""
reason = ""
if tool == "Grep":
    scope = tool_input.get("path")
    if not scope:
        if forbidden:
            print("block\tpathless Grep may scan forbidden context\tGrep:workspace")
            sys.exit(0)
        target = "Grep:workspace"
    else:
        blocked = scope_contains_forbidden(scope)
        target = relpath(scope)
        if blocked:
            print(f"block\tGrep scope '{scope}' may scan forbidden glob '{blocked}'\t{target}")
            sys.exit(0)
elif tool == "Glob":
    target = str(tool_input.get("pattern") or "")
    blocked = scope_contains_forbidden(target)
    if blocked:
        print(f"block\tGlob pattern '{target}' may enumerate forbidden glob '{blocked}'\t{target}")
        sys.exit(0)
else:
    raw = tool_input.get("file_path") or tool_input.get("path") or tool_input.get("pattern") or ""
    target = relpath(raw)
    blocked, candidate = matches_path(target)
    if blocked:
        print(f"block\t'{candidate}' matches forbidden glob '{blocked}'\t{target}")
        sys.exit(0)

print(f"allow\t\t{target}")
PY
)

ACTION=$(printf '%s' "$DECISION" | cut -f1)
REASON=$(printf '%s' "$DECISION" | cut -f2)
TARGET=$(printf '%s' "$DECISION" | cut -f3)

if [ -z "$ACTION" ]; then
  echo "guard-context: manifest active but path policy evaluation failed. Blocking (check python3 and pointer JSON)." >&2
  exit 2
fi

if [ "$MODE" = "sealed" ]; then
  if [ "$ACTION" = "block" ]; then
    echo "BLOCKED by sealed manifest: $REASON" >&2
    echo "  Manifest: $(jq -r '.manifest' "$POINTER")" >&2
    echo "  Sealed runs prohibit contaminating context. Provide a narrower safe path/glob, or amend the manifest and re-activate." >&2
    exit 2
  fi
  exit 0
fi

if [ "$MODE" = "bounded" ]; then
  [ -z "$TARGET" ] && TARGET="${TOOL:-unknown}:workspace"
  # Allow, but ledger the access for receipt accounting.
  printf '{"path":"%s","reason":"unstated (agent must justify in receipt)","ts":"%s"}\n' \
    "$(echo "$TARGET" | sed 's/"/\\"/g')" \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LEDGER" 2>/dev/null || true
  exit 0
fi

exit 0
