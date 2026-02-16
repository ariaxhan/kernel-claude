#!/usr/bin/env python3
"""
PreCompact Hook for Arbiter Context Compression

Automatically extracts logical facts from conversation context before compaction
and compresses them using arbiter propositional logic engine.

This hook fires when Claude Code is about to compact the conversation.
It transforms conversation history into minimal logical facts.
"""

import json
import sys
import subprocess
import tempfile
from pathlib import Path


def extract_facts_from_transcript(transcript_path: str) -> str:
    """
    Read the conversation transcript and extract facts in arbiter syntax.

    This is a simplified v0 implementation that outputs a prompt for Claude
    to extract facts. In future versions, this could parse the transcript
    directly.
    """
    # For v0, we rely on Claude Code's prompt-based hook system
    # This script can be called as a command hook or prompt hook

    # The transcript file contains the full conversation
    if not Path(transcript_path).exists():
        print(f"Warning: Transcript not found at {transcript_path}", file=sys.stderr)
        return ""

    # Read transcript (optional - for logging/debugging)
    # For v0, we'll return a prompt that asks Claude to do the extraction
    return ""


def main():
    """
    PreCompact hook entry point.

    Receives JSON input via stdin:
    {
      "session_id": "...",
      "transcript_path": "/path/to/transcript",
      "cwd": "/current/working/dir",
      "permission_mode": "ask|allow",
      "hook_event_name": "PreCompact"
    }
    """
    try:
        # Read input from stdin
        input_data = json.load(sys.stdin)

        session_id = input_data.get('session_id', 'unknown')
        transcript_path = input_data.get('transcript_path', '')
        cwd = input_data.get('cwd', '.')

        # Log the PreCompact event (for debugging)
        log_dir = Path.home() / '.claude' / 'logs' / 'arbiter'
        log_dir.mkdir(parents=True, exist_ok=True)
        log_file = log_dir / f'{session_id}.log'

        with open(log_file, 'a') as f:
            f.write(f"PreCompact triggered - session: {session_id}\n")
            f.write(f"Transcript: {transcript_path}\n")
            f.write(f"CWD: {cwd}\n")

        # For v0: Output a system message prompting Claude to extract facts
        # This leverages Claude's ability to read the transcript

        output = {
            "systemMessage": """
🔬 ARBITER PRECOMPACT ACTIVATED

Before compaction, extract conversation facts in ARBITER SYNTAX:

1. Read the full conversation history
2. Extract all factual knowledge as logical statements
3. Use arbiter syntax (see .claude/rules/arbiter-syntax.md)
4. Output ONLY arbiter syntax (no prose)

Categories to extract:
- Project setup (use_<tech>, requires_<dep>)
- Architecture decisions (api_is_<type>, pattern_is_<pattern>)
- Coding conventions (use_<style>, require_<practice>)
- Business logic (<condition> -> <result>)
- File locations (tests_in_<dir>, config_in_<loc>)
- Decisions made (decided_<choice>, rejected_<alt>)

Format example:
```
use_python
use_fastapi
authenticated -> can_read
admin & authenticated -> can_write
```

After extraction, the facts will be compressed via arbiter.py and become the new context seed.
"""
        }

        # Output JSON to stdout
        print(json.dumps(output, indent=2))
        sys.exit(0)

    except Exception as e:
        print(f"PreCompact hook error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
