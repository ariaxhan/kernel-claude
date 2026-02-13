# Claude Code Hooks: Deep Dive

## Summary

Claude Code hooks are user-defined shell commands, LLM prompts, or agent subprocesses that execute automatically at specific points in Claude Code's lifecycle. They provide deterministic control over Claude Code's behavior -- ensuring certain actions always happen rather than relying on the LLM to choose to run them. Hooks support 12 event types spanning the full session lifecycle, communicate via JSON stdin/stdout/stderr with exit codes, and can block actions, modify tool inputs, inject context, and automate workflows. They run with the user's full system permissions, making security hygiene critical.

## Mental Model

Think of hooks as middleware interceptors in a web framework. Each Claude Code lifecycle event (session start, tool call, stop, etc.) is an HTTP request flowing through a pipeline. Your hooks are middleware functions that can:

1. **Inspect** the request (read JSON from stdin)
2. **Block** the request (exit code 2)
3. **Modify** the request (return `updatedInput` in JSON)
4. **Annotate** the request (add context via stdout or `additionalContext`)
5. **Observe** the request (log, notify, audit -- then exit 0)

The key insight: hooks are NOT prompts. They are deterministic code that runs every time. By encoding rules as hooks rather than prompt instructions, you turn suggestions into executable contracts.

---

## Complete Hook Events Reference

### All 12 Events

| Event | When It Fires | Can Block? | Matcher Target |
|-------|--------------|------------|----------------|
| `SessionStart` | Session begins or resumes | No | How session started: `startup`, `resume`, `clear`, `compact` |
| `UserPromptSubmit` | User submits prompt, before Claude processes it | Yes | No matcher support (always fires) |
| `PreToolUse` | Before a tool call executes | Yes | Tool name: `Bash`, `Edit`, `Write`, `Read`, `Glob`, `Grep`, `Task`, `WebFetch`, `WebSearch`, MCP tools |
| `PermissionRequest` | When a permission dialog appears | Yes | Tool name (same as PreToolUse) |
| `PostToolUse` | After a tool call succeeds | No | Tool name (same as PreToolUse) |
| `PostToolUseFailure` | After a tool call fails | No | Tool name (same as PreToolUse) |
| `Notification` | When Claude Code sends a notification | No | Notification type: `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog` |
| `SubagentStart` | When a subagent is spawned | No | Agent type: `Bash`, `Explore`, `Plan`, or custom agent names |
| `SubagentStop` | When a subagent finishes | Yes | Agent type (same as SubagentStart) |
| `Stop` | When Claude finishes responding | Yes | No matcher support (always fires) |
| `PreCompact` | Before context compaction | No | What triggered: `manual`, `auto` |
| `SessionEnd` | When a session terminates | No | Exit reason: `clear`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other` |

### Event Details

#### SessionStart

**Input fields** (beyond common fields):
- `source`: `"startup"`, `"resume"`, `"clear"`, `"compact"`
- `model`: Model identifier string
- `agent_type`: (optional) Agent name if started with `claude --agent <name>`

**Decision control**:
- stdout text is added as context for Claude
- `additionalContext` field in `hookSpecificOutput` is concatenated from multiple hooks
- Has access to `CLAUDE_ENV_FILE` environment variable for persisting env vars

**Environment variable persistence**:
```bash
#!/bin/bash
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo 'export NODE_ENV=production' >> "$CLAUDE_ENV_FILE"
  echo 'export DEBUG_LOG=true' >> "$CLAUDE_ENV_FILE"
fi
exit 0
```

Variables written to `CLAUDE_ENV_FILE` are available in all subsequent Bash commands during the session. Use `>>` (append) to preserve variables set by other hooks. Only available in SessionStart hooks.

#### UserPromptSubmit

**Input fields**:
- `prompt`: The text the user submitted

**Decision control**:
- Plain text stdout is added as context
- JSON `additionalContext` field for structured context injection
- `decision: "block"` prevents prompt processing and erases it from context
- `reason` field shown to user when blocked (not added to context)

#### PreToolUse

**Input fields**:
- `tool_name`: Name of the tool
- `tool_input`: Tool-specific parameters (see below)
- `tool_use_id`: Unique identifier for the tool call

**Tool input schemas**:

| Tool | Key Fields |
|------|-----------|
| `Bash` | `command` (string), `description` (optional string), `timeout` (optional number ms), `run_in_background` (optional bool) |
| `Write` | `file_path` (string, absolute), `content` (string) |
| `Edit` | `file_path` (string, absolute), `old_string` (string), `new_string` (string), `replace_all` (optional bool) |
| `Read` | `file_path` (string, absolute), `offset` (optional number), `limit` (optional number) |
| `Glob` | `pattern` (string), `path` (optional string) |
| `Grep` | `pattern` (string), `path` (optional string), `glob` (optional string), `output_mode` (optional string), `-i` (optional bool), `multiline` (optional bool) |
| `WebFetch` | `url` (string), `prompt` (string) |
| `WebSearch` | `query` (string), `allowed_domains` (optional array), `blocked_domains` (optional array) |
| `Task` | `prompt` (string), `description` (string), `subagent_type` (string), `model` (optional string) |

**Decision control** (hookSpecificOutput):
- `permissionDecision`: `"allow"` (bypass permission system), `"deny"` (block tool call), `"ask"` (show permission prompt to user)
- `permissionDecisionReason`: For allow/ask: shown to user not Claude. For deny: shown to Claude
- `updatedInput`: Modifies tool input parameters before execution (v2.0.10+). Combine with `"allow"` to auto-approve with modified input, or `"ask"` to show modified input to user
- `additionalContext`: String added to Claude's context before tool executes

**DEPRECATED**: `decision` and `reason` fields. Use `hookSpecificOutput.permissionDecision` and `hookSpecificOutput.permissionDecisionReason` instead. Legacy `"approve"` maps to `"allow"`, `"block"` maps to `"deny"`.

#### PermissionRequest (v2.0.45+)

**Input fields**:
- `tool_name`: Name of the tool
- `tool_input`: Tool parameters
- `permission_suggestions`: Array of "always allow" options the user would see

**Decision control** (hookSpecificOutput):
- `decision.behavior`: `"allow"` or `"deny"`
- `decision.updatedInput`: (allow only) Modify tool input before execution
- `decision.updatedPermissions`: (allow only) Apply permission rule updates (equivalent to "always allow")
- `decision.message`: (deny only) Tell Claude why permission was denied
- `decision.interrupt`: (deny only) If `true`, stops Claude entirely

**Important**: PermissionRequest hooks do NOT fire in non-interactive mode (`-p`). Use `PreToolUse` hooks instead for automated permission decisions.

#### PostToolUse

**Input fields**:
- `tool_name`, `tool_input`, `tool_use_id`
- `tool_response`: Result returned by the tool (schema varies by tool)

**Decision control**:
- `decision: "block"` with `reason`: Feeds reason back to Claude as error context
- `additionalContext`: Additional context for Claude
- `updatedMCPToolOutput`: (MCP tools only) Replaces the tool's output

**Cannot undo actions** -- the tool has already executed.

#### PostToolUseFailure

**Input fields**:
- `tool_name`, `tool_input`, `tool_use_id`
- `error`: String describing what went wrong
- `is_interrupt`: Optional boolean indicating user interruption

**Decision control**:
- `additionalContext`: Additional context about the failure for Claude

#### Notification

**Input fields**:
- `message`: Notification text
- `title`: Optional title
- `notification_type`: Which type fired

**Decision control**:
- Cannot block or modify notifications
- `additionalContext`: String added to Claude's context

#### SubagentStart

**Input fields**:
- `agent_id`: Unique identifier for the subagent
- `agent_type`: Agent name (built-in or custom)

**Decision control**:
- Cannot block subagent creation
- `additionalContext`: String added to the subagent's context

#### SubagentStop

**Input fields**:
- `stop_hook_active`: Boolean (true if already continuing from a stop hook)
- `agent_id`, `agent_type`
- `agent_transcript_path`: Path to subagent's transcript (in nested `subagents/` folder)

**Decision control**: Same as Stop hooks (below).

#### Stop

**Input fields**:
- `stop_hook_active`: Boolean -- **critical for preventing infinite loops**

**Decision control**:
- `decision: "block"` with `reason` (required): Prevents Claude from stopping, continues conversation
- Check `stop_hook_active` to prevent infinite loops

#### PreCompact

**Input fields**:
- `trigger`: `"manual"` or `"auto"`
- `custom_instructions`: User text from `/compact` (manual only), empty for auto

**Cannot block compaction.**

#### SessionEnd

**Input fields**:
- `reason`: Why session ended (`clear`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other`)

**Cannot block session termination.** Useful for cleanup, logging, saving state.

---

## Configuration Schema

### Structure

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "regex_pattern",
        "hooks": [
          {
            "type": "command",
            "command": "shell-command-here",
            "timeout": 600,
            "async": false,
            "statusMessage": "Running hook..."
          }
        ]
      }
    ]
  }
}
```

Three levels of nesting:
1. **Hook event** -- the lifecycle point
2. **Matcher group** -- filter when it fires
3. **Hook handler** -- the command/prompt/agent that runs

### Hook Handler Types

#### Command Hooks (`type: "command"`)

| Field | Required | Description |
|-------|----------|-------------|
| `type` | Yes | `"command"` |
| `command` | Yes | Shell command to execute |
| `timeout` | No | Seconds before canceling. Default: 600 |
| `async` | No | If `true`, runs in background without blocking. Default: false |
| `statusMessage` | No | Custom spinner message while running |
| `once` | No | If `true`, runs only once per session (skills only) |

#### Prompt Hooks (`type: "prompt"`)

| Field | Required | Description |
|-------|----------|-------------|
| `type` | Yes | `"prompt"` |
| `prompt` | Yes | Prompt text. Use `$ARGUMENTS` for hook input JSON placeholder |
| `model` | No | Model for evaluation. Default: fast model (Haiku) |
| `timeout` | No | Seconds. Default: 30 |
| `statusMessage` | No | Custom spinner message |
| `once` | No | Skills only |

Response must be: `{"ok": true}` or `{"ok": false, "reason": "explanation"}`

#### Agent Hooks (`type: "agent"`)

| Field | Required | Description |
|-------|----------|-------------|
| `type` | Yes | `"agent"` |
| `prompt` | Yes | Prompt describing what to verify. Use `$ARGUMENTS` placeholder |
| `model` | No | Model to use. Default: fast model |
| `timeout` | No | Seconds. Default: 60 |

Can use tools (Read, Grep, Glob) for up to 50 turns. Same response format as prompt hooks.

### Hook Locations (Scope)

| Location | Scope | Shareable |
|----------|-------|-----------|
| `~/.claude/settings.json` | All projects | No (local to machine) |
| `.claude/settings.json` | Single project | Yes (committable) |
| `.claude/settings.local.json` | Single project | No (gitignored) |
| Managed policy settings | Organization-wide | Yes (admin-controlled) |
| Plugin `hooks/hooks.json` | When plugin enabled | Yes (bundled with plugin) |
| Skill/agent frontmatter | While component active | Yes (defined in component) |

### Matcher System

Matchers are **regex strings** that filter when hooks fire.

- `"*"`, `""`, or omitted: match all occurrences
- Case-sensitive
- Regex patterns supported: `Edit|Write`, `Notebook.*`, `mcp__memory__.*`

**MCP tool naming**: `mcp__<server>__<tool>`
- `mcp__memory__create_entities`
- `mcp__filesystem__read_file`
- `mcp__github__search_repositories`
- `mcp__.*__write.*` matches any write tool from any server

**Events without matcher support**: `UserPromptSubmit` and `Stop` always fire. A matcher field on these is silently ignored.

---

## Hook Input and Output

### Common Input Fields (All Events)

Every hook receives these via stdin as JSON:

| Field | Description |
|-------|-------------|
| `session_id` | Current session identifier |
| `transcript_path` | Path to conversation JSONL file |
| `cwd` | Current working directory |
| `permission_mode` | Current mode: `"default"`, `"plan"`, `"acceptEdits"`, `"dontAsk"`, `"bypassPermissions"` |
| `hook_event_name` | Name of the event that fired |

### Exit Codes

| Exit Code | Meaning | Behavior |
|-----------|---------|----------|
| `0` | Success | Action proceeds. stdout parsed for JSON output. For UserPromptSubmit/SessionStart, stdout added as context |
| `2` | Blocking error | Action blocked (if event supports blocking). stderr fed back to Claude as error. JSON in stdout is ignored |
| Any other | Non-blocking error | Action proceeds. stderr shown in verbose mode only. Not shown to Claude |

### Exit Code 2 Behavior Per Event

| Hook Event | Can Block? | What Happens |
|------------|------------|-------------|
| `PreToolUse` | Yes | Blocks the tool call |
| `PermissionRequest` | Yes | Denies the permission |
| `UserPromptSubmit` | Yes | Blocks prompt processing, erases prompt |
| `Stop` | Yes | Prevents stopping, continues conversation |
| `SubagentStop` | Yes | Prevents subagent from stopping |
| `PostToolUse` | No | Shows stderr to Claude |
| `PostToolUseFailure` | No | Shows stderr to Claude |
| `Notification` | No | Shows stderr to user only |
| `SubagentStart` | No | Shows stderr to user only |
| `SessionStart` | No | Shows stderr to user only |
| `SessionEnd` | No | Shows stderr to user only |
| `PreCompact` | No | Shows stderr to user only |

### JSON Output Fields

Must choose ONE approach per hook: exit codes alone, OR exit 0 with JSON. Claude Code only processes JSON on exit 0.

**Top-level fields** (all events):

| Field | Default | Description |
|-------|---------|-------------|
| `continue` | `true` | If `false`, Claude stops all processing. **Takes precedence over everything** |
| `stopReason` | none | Message to user when `continue` is false. Not shown to Claude |
| `suppressOutput` | `false` | If `true`, hides stdout from verbose mode |
| `systemMessage` | none | Warning message shown to user |

**`hookSpecificOutput` object**: Must include `hookEventName` field. Event-specific fields go here.

**Priority cascade**: `continue: false` > JSON `decision: "block"` > exit code 2

### stdout Requirements

stdout must contain ONLY the JSON object. Shell profile echo statements (from `.zshrc`/`.bashrc`) can break JSON parsing. Fix:

```bash
# In ~/.zshrc or ~/.bashrc
if [[ $- == *i* ]]; then
  echo "Shell ready"  # only in interactive shells
fi
```

---

## Environment Variables

### Available to All Hooks

| Variable | Description |
|----------|-------------|
| `CLAUDE_PROJECT_DIR` | Project root path. Use with quotes: `"$CLAUDE_PROJECT_DIR"` |
| `CLAUDE_CODE_REMOTE` | Set to `"true"` in remote web environments. Not set in local CLI |

### Available to Plugin Hooks

| Variable | Description |
|----------|-------------|
| `${CLAUDE_PLUGIN_ROOT}` | Plugin's root directory |

### SessionStart Only

| Variable | Description |
|----------|-------------|
| `CLAUDE_ENV_FILE` | File path for persisting environment variables to subsequent Bash commands |

### Documented Environment Variables (Complete List)

| Variable | Where Available |
|----------|----------------|
| `CLAUDE_PROJECT_DIR` | All hooks |
| `CLAUDE_FILE_PATHS` | PostToolUse for file operations |
| `CLAUDE_NOTIFICATION` | Notification hooks |
| `CLAUDE_TOOL_OUTPUT` | PostToolUse hooks |
| `CLAUDE_ENV_FILE` | SessionStart hooks only |
| `CLAUDE_CODE_REMOTE` | All hooks |
| `CLAUDE_PLUGIN_ROOT` | Plugin hooks only |

### NOT Environment Variables (Common Misconception)

These are NOT environment variables (they come via JSON stdin):
- `CLAUDE_TOOL_NAME` -- does NOT exist. Use `jq -r '.tool_name'` from stdin
- `CLAUDE_TOOL_PARAMS` -- does NOT exist. Use `jq -r '.tool_input'` from stdin

This was documented in GitHub issue #5489 (closed as user error).

---

## Async Hooks

Set `"async": true` on command hooks to run in background without blocking.

```json
{
  "type": "command",
  "command": "/path/to/long-running-script.sh",
  "async": true,
  "timeout": 300
}
```

**Behavior**:
- Claude continues working immediately
- Output delivered on next conversation turn
- `systemMessage` and `additionalContext` in JSON output are delivered when process exits
- Default timeout: 10 minutes (configurable)

**Limitations**:
- Only `type: "command"` supports async. Prompt/agent hooks cannot be async
- Cannot block or return decisions (action already proceeded)
- Output waits for next user interaction if session is idle
- Each execution creates a separate background process (no deduplication)

---

## Hooks in Skills and Agents

Hooks defined in skill/agent YAML frontmatter:

```yaml
---
name: secure-operations
description: Perform operations with security checks
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/security-check.sh"
---
```

- All hook events supported
- Scoped to component's lifetime, cleaned up when finished
- For subagents, `Stop` hooks auto-convert to `SubagentStop`
- `once: true` option: runs only once per session (skills only, not agents)
- Supported scoped events: `PreToolUse`, `PostToolUse`, `Stop`

---

## Enterprise Features

### `allowManagedHooksOnly`

Enterprise administrators can set `allowManagedHooksOnly: true` in managed policy settings to block all user, project, and plugin hooks. Only organization-managed hooks will execute.

### `disableAllHooks`

Set `"disableAllHooks": true` in settings or use the `/hooks` menu toggle to temporarily disable all hooks without removing them. No way to disable individual hooks while keeping them configured.

---

## Security Considerations

### Core Facts

- Hooks run with your system user's **full permissions**
- They can modify, delete, or access any files your user account can access
- Malicious or poorly written hooks can cause data loss or system damage
- Hooks run automatically during the agent loop with your environment's credentials

### Configuration Safety

- Direct edits to settings files do NOT take effect immediately
- Claude Code captures a hook snapshot at startup
- External modifications trigger a warning requiring review in `/hooks` menu
- This prevents malicious code from silently adding hooks mid-session

### Best Practices

1. **Validate and sanitize inputs** -- never trust stdin blindly
2. **Always quote shell variables** -- `"$VAR"` not `$VAR`
3. **Block path traversal** -- check for `..` in file paths
4. **Use absolute paths** -- specify full paths, use `"$CLAUDE_PROJECT_DIR"` for project root
5. **Skip sensitive files** -- `.env`, `.git/`, keys, credentials
6. **Test hooks in safe environment** before production use
7. **Use `chmod +x`** on script files (macOS/Linux)
8. **Wrap shell profile echo statements** in interactive checks to prevent JSON parsing failures

---

## Common Pitfalls and Anti-Patterns

### 1. Infinite Stop Hook Loops

The most dangerous pitfall. If a Stop hook always returns `decision: "block"`, Claude will loop forever.

**Fix**: Always check `stop_hook_active`:

```bash
#!/bin/bash
INPUT=$(cat)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0  # Allow Claude to stop
fi
# ... rest of logic
```

Also use `--max-iterations` as a safety net in CI.

### 2. Shell Profile Pollution

`.zshrc` or `.bashrc` echo statements break JSON parsing:

```
Shell ready on arm64      <-- this breaks JSON parsing
{"decision": "allow"}
```

**Fix**: Guard echo statements with interactive shell check.

### 3. Overly Broad Matchers

Matcher `"*"` on PreToolUse fires for EVERY tool call (Read, Glob, Grep, etc.), causing performance drag.

**Fix**: Scope matchers to specific tools: `"Edit|Write"`, `"Bash"`.

### 4. Confusing stdout and stderr

- stdout on exit 0 = JSON output or context text
- stderr on exit 2 = error message fed to Claude
- Many CLI tools write errors to stdout by default

**Fix**: Explicitly redirect: `echo "error message" >&2`

### 5. Expecting Template Variables

There are NO template variables like `{{tool.name}}` or `{{timestamp}}`. All data comes via JSON on stdin.

**Fix**: Parse JSON from stdin with `jq` or your language's JSON parser.

### 6. PostToolUse Trying to Undo

PostToolUse fires AFTER the tool ran. You cannot undo a file write or bash command.

**Fix**: Use PreToolUse to block before execution.

### 7. PermissionRequest in Non-Interactive Mode

PermissionRequest hooks do NOT fire when using `-p` flag (headless/non-interactive mode).

**Fix**: Use PreToolUse hooks for automated permission decisions in CI/headless contexts.

### 8. Exit Code 2 with JSON

If you exit 2, all JSON in stdout is ignored. stderr becomes the feedback.

**Fix**: Choose one approach: exit 2 + stderr message, OR exit 0 + JSON with decision fields.

---

## Debugging

### Methods

1. **`claude --debug`**: Full execution details including matched hooks, exit codes, output
2. **`Ctrl+O`**: Toggle verbose mode to see hook output in transcript
3. **`/hooks`**: Interactive menu to verify configuration
4. **Manual testing**: Pipe sample JSON through your script:

```bash
echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | ./my-hook.sh
echo $?  # Check exit code
```

### Debug Output Format

```
[DEBUG] Executing hooks for PostToolUse:Write
[DEBUG] Getting matching hook commands for PostToolUse with query: Write
[DEBUG] Found 1 hook matchers in settings
[DEBUG] Matched 1 hooks for query "Write"
[DEBUG] Found 1 hook commands to execute
[DEBUG] Executing hook command: <Your command> with timeout 600000ms
[DEBUG] Hook command completed with status 0: <Your stdout>
```

---

## Version History

| Version | Feature |
|---------|---------|
| v1.0.38 | Initial hooks system (had known issues with exit code blocking) |
| v1.0.41+ | SubagentStop event |
| v2.0.10 | PreToolUse `updatedInput` -- modify tool inputs before execution |
| v2.0.45 | PermissionRequest hook event |
| v2.1.0 | Hooks for agents/skills/slash commands, component-scoped hooks |
| Later | SubagentStart event, `tool_use_id` field, `agent_transcript_path` field |
| Later | Async hooks, prompt-based hooks, agent-based hooks |
| Later | SessionEnd event, PostToolUseFailure event |
| Later | `systemMessage` support for SessionEnd hooks |
| Later | Plugin system with `hooks/hooks.json` |

---

## Python SDK Limitations

The Python SDK supports only a subset of hook events:
- `PreToolUse`
- `PostToolUse`
- `UserPromptSubmit`
- `Stop`
- `SubagentStop`
- `PreCompact`

**NOT supported** in Python SDK: `SessionStart`, `SessionEnd`, `Notification`

---

## Known Issues (GitHub)

### Issue #2814: Hooks System Issues (Closed)

Three problems reported on v1.0.38:
1. Template variable interpolation failure (user misunderstanding -- no template variables exist)
2. Configuration changes ignored after restart
3. Exit code blocking not working

**Resolution**: User had incorrect configuration. Proper blocking requires exit code 2 or JSON `permissionDecision: "deny"`. No `"blocking": true` setting exists.

### Issue #5489: Environment Variable Substitution Failure (Closed)

`CLAUDE_TOOL_NAME` and `CLAUDE_TOOL_PARAMS` are not real environment variables. Tool data comes via JSON on stdin.

### Issue #10205: Infinite Loop with Hooks Enabled

Claude enters infinite loop when Stop hooks are configured without `stop_hook_active` guard.

### Issue #3573: GitHub Actions Infinite Loop

Stop hook fails with syntax error in CI, causing infinite "Stop hook feedback" loop preventing GitHub Action completion.

### Issue #6305: Pre/PostToolUse Hooks Not Executing

Various configuration issues causing hooks not to fire.

### Issue #11891: Missing PermissionRequest Documentation

PermissionRequest hook introduced in v2.0.45 but documentation was incomplete -- missing from high-level guide and input schema reference.

### Issue #16592: Image Data Not Exposed to Hooks

When users paste images into Claude Code, there is no way to access raw image data (base64 or file reference) from hooks.

---

## Reference Implementations

### Bash Command Validator (Official)

Full example at: `https://github.com/anthropics/claude-code/blob/main/examples/hooks/bash_command_validator_example.py`

### Complete PreToolUse Block Example

```bash
#!/bin/bash
# block-rm.sh
COMMAND=$(jq -r '.tool_input.command')

if echo "$COMMAND" | grep -q 'rm -rf'; then
  echo '{"decision":"block","reason":"Destructive command blocked by hook"}'
else
  exit 0
fi
```

### Complete PostToolUse Auto-Format Example

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write"
          }
        ]
      }
    ]
  }
}
```

### Complete Protected Files Example

```bash
#!/bin/bash
# protect-files.sh
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

PROTECTED_PATTERNS=(".env" "package-lock.json" ".git/")

for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "Blocked: $FILE_PATH matches protected pattern '$pattern'" >&2
    exit 2
  fi
done

exit 0
```

### Complete updatedInput Example

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Redirected to sandbox",
    "updatedInput": {
      "file_path": "/sandbox/redirected-file.txt",
      "content": "sanitized content"
    }
  }
}
```

### Complete Stop Hook with Loop Guard

```bash
#!/bin/bash
INPUT=$(cat)
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0
fi

# Your actual stop validation logic here
echo '{"decision": "block", "reason": "Tests have not been run yet"}'
```

### Complete Async Test Runner

```bash
#!/bin/bash
# run-tests-async.sh
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ "$FILE_PATH" != *.ts && "$FILE_PATH" != *.js ]]; then
  exit 0
fi

RESULT=$(npm test 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "{\"systemMessage\": \"Tests passed after editing $FILE_PATH\"}"
else
  echo "{\"systemMessage\": \"Tests failed after editing $FILE_PATH: $RESULT\"}"
fi
```

### Complete Notification Hook (macOS)

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\"'"
          }
        ]
      }
    ]
  }
}
```

### Complete Prompt-Based Stop Hook

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "You are evaluating whether Claude should stop working. Context: $ARGUMENTS\n\nAnalyze the conversation and determine if:\n1. All user-requested tasks are complete\n2. Any errors need to be addressed\n3. Follow-up work is needed\n\nRespond with JSON: {\"ok\": true} to allow stopping, or {\"ok\": false, \"reason\": \"your explanation\"} to continue working.",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### Complete Agent-Based Verification Hook

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "agent",
            "prompt": "Verify that all unit tests pass. Run the test suite and check the results. $ARGUMENTS",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

---

## Execution Semantics

- All matching hooks run **in parallel**
- Identical hook commands are **deduplicated** automatically
- Hooks run in the **current directory** with Claude Code's environment
- Default timeout: 600 seconds (command), 30 seconds (prompt), 60 seconds (agent)
- A timeout for one hook does NOT affect other hooks
- Hook snapshot captured at startup -- mid-session file edits require `/hooks` review

---

## Open Questions

1. **No individual hook disable**: You can only disable ALL hooks or none. There is no `"enabled": false` per-hook.
2. **No hook ordering**: All matching hooks run in parallel. No way to specify execution order.
3. **No hook chaining**: Output of one hook cannot feed into another hook.
4. **Image data inaccessible**: Pasted images cannot be accessed from hooks (issue #16592).
5. **Python SDK gaps**: SessionStart, SessionEnd, Notification not supported.
6. **PermissionRequest in headless mode**: Does not fire with `-p` flag.
7. **No hook marketplace**: Plugins can bundle hooks, but there is no dedicated hook sharing mechanism.

---

## Sources

- [Hooks Reference (Official)](https://code.claude.com/docs/en/hooks) -- Complete API reference
- [Hooks Guide (Official)](https://code.claude.com/docs/en/hooks-guide) -- Getting started with examples
- [How to Configure Hooks (Anthropic Blog)](https://claude.com/blog/how-to-configure-hooks) -- Best practices from Anthropic
- [GitHub Issue #2814](https://github.com/anthropics/claude-code/issues/2814) -- Hooks system issues (v1.0.38)
- [GitHub Issue #5489](https://github.com/anthropics/claude-code/issues/5489) -- Environment variable misconception
- [GitHub Issue #10205](https://github.com/anthropics/claude-code/issues/10205) -- Infinite loop with hooks
- [GitHub Issue #3573](https://github.com/anthropics/claude-code/issues/3573) -- GitHub Actions infinite loop
- [GitHub Issue #11891](https://github.com/anthropics/claude-code/issues/11891) -- Missing PermissionRequest docs
- [GitHub Issue #16592](https://github.com/anthropics/claude-code/issues/16592) -- Image data not exposed
- [GitHub Issue #4368](https://github.com/anthropics/claude-code/issues/4368) -- Feature request for updatedInput
- [claude-code-hooks-mastery (Community)](https://github.com/disler/claude-code-hooks-mastery) -- All 8 events demonstrated
- [awesome-claude-code (Community)](https://github.com/hesreallyhim/awesome-claude-code) -- Curated hooks collection
- [claude-code-hooks (Community)](https://github.com/karanb192/claude-code-hooks) -- Copy-paste-customize hooks
- [Bash Command Validator (Official Example)](https://github.com/anthropics/claude-code/blob/main/examples/hooks/bash_command_validator_example.py) -- Reference implementation
- [DataCamp Tutorial](https://www.datacamp.com/tutorial/claude-code-hooks) -- Practical guide
- [ClaudeLog](https://claudelog.com/mechanics/hooks/) -- Community docs and best practices

---

## Implications for This Project

For the Vaults system, hooks could be used to:

1. **Enforce the `.claude is READ-ONLY` invariant**: PreToolUse hook on `Write|Edit` that blocks any writes to `.claude/` paths
2. **Auto-push after commit**: PostToolUse hook on `Bash` that detects `git commit` and triggers `git push`
3. **Cost tracking**: PostToolUse hook that logs tool usage to `_meta/logs/costs.jsonl`
4. **Session context injection**: SessionStart hook that loads `_meta/context/active.md` as context
5. **Parallel agent validation**: SubagentStop hook that validates subagent outputs before accepting
6. **Compaction protection**: PreCompact hook that saves critical context to file before compaction
7. **Desktop notifications**: Notification hook for permission prompts when running long tasks
