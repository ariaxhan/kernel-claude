# PostToolUseFailure Hook JSON Schema

**Date:** 2026-03-30  
**Status:** Verified from production code + official research  
**Source:** `/Users/ariaxhan/Downloads/Vaults/_meta/docs/hooks-research.md` (line 135-140)

---

## Input Schema (stdin)

Claude Code passes this JSON via stdin to PostToolUseFailure hooks:

```json
{
  "tool_name": "string",
  "tool_input": { ... },
  "tool_use_id": "string",
  "error": "string describing what went wrong",
  "is_interrupt": false
}
```

### Field Definitions

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `tool_name` | string | Yes | Name of the tool that failed (e.g., `Bash`, `Read`, `Write`, `Edit`, `Glob`, `Grep`, `WebFetch`, `WebSearch`, `Task`, or MCP tool name) |
| `tool_input` | object | Yes | The input parameters that were passed to the tool (varies by tool; see tool-specific schemas below) |
| `tool_use_id` | string | Yes | Unique identifier for this tool invocation (for tracking/correlation) |
| `error` | string | Yes | Error message describing the failure. This is the **primary error field**. |
| `is_interrupt` | boolean | No | Optional flag indicating whether the failure was due to user interruption (true) or actual error (false/absent) |

---

## Common Field Values

### `tool_name` Values
- `Bash`
- `Read`
- `Write`
- `Edit`
- `Glob`
- `Grep`
- `WebFetch`
- `WebSearch`
- `Task`
- Any MCP tool name

### `error` Field
- Contains the error message string
- **NOT** `message`, **NOT** `stderr`
- Examples:
  - `"Command failed with exit code 1"`
  - `"File not found: /path/to/file"`
  - `"Permission denied"`

---

## Output Schema (stdout/JSON response)

Your hook can return:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUseFailure",
    "additionalContext": "Optional context to add to Claude's knowledge about the failure"
  }
}
```

Or plain text:
```bash
echo "Failed to read file. Will try alternate approach."
exit 0
```

---

## Example Hook Implementation

```bash
#!/bin/bash

# Read stdin
INPUT=$(cat)

# Extract fields
TOOL=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
ERROR=$(echo "$INPUT" | jq -r '.error // "unknown error"')
TOOL_ID=$(echo "$INPUT" | jq -r '.tool_use_id // ""')
IS_INTERRUPT=$(echo "$INPUT" | jq -r '.is_interrupt // false')

# Log or act on failure
if [ "$TOOL" = "Bash" ]; then
  echo "Bash command failed: $ERROR (tool_use_id: $TOOL_ID)"
  
  if [ "$IS_INTERRUPT" = "true" ]; then
    echo "User interrupted the command"
  fi
fi

# Optional: return additional context
cat << 'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUseFailure",
    "additionalContext": "The tool failed because..."
  }
}
JSON

exit 0
```

---

## Real-World Example from Production

From `/Users/ariaxhan/Downloads/Vaults/CodingVault/kernel-claude/hooks/scripts/capture-error.sh` (line 14-16):

```bash
TOOL=$(echo "$INPUT" | jq -r '.tool // "unknown"' 2>/dev/null)
ERROR=$(echo "$INPUT" | jq -r '.error // .message // "unknown error"' 2>/dev/null)
FILE=$(echo "$INPUT" | jq -r '.file_path // .path // ""' 2>/dev/null)
```

**Note:** The production code includes `.message` as a fallback (`'.error // .message'`), but the official schema specifies `.error` as the canonical field. The fallback is defensive programming.

---

## Field Names: The Definitive Answer

**Question:** Does stdin have `tool`, `tool_name`, `toolName`, or something else?

**Answer:** `tool_name` (official schema) — not `tool` or `toolName`.

**Question:** Is the error field `error`, `message`, `stderr`?

**Answer:** `error` (official schema) — though production code defensively checks `error // .message` for robustness.

---

## References

- [Claude Code Hooks Documentation: PostToolUseFailure Section](https://code.claude.com/docs/en/hooks) (referenced in `/Users/ariaxhan/Downloads/Vaults/_meta/docs/hooks-research.md`)
- Official hooks research: `/Users/ariaxhan/Downloads/Vaults/_meta/docs/hooks-research.md`, lines 135-140
- Production implementation: `/Users/ariaxhan/Downloads/Vaults/CodingVault/kernel-claude/hooks/scripts/capture-error.sh`

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success. Stdout processed. Hook completed normally. |
| 2 | Blocking error. Hook failed critically. |
| Other | Non-blocking error. Shown in verbose mode only. |

For PostToolUseFailure hooks, returning 0 is normal (you're observing, not blocking).

