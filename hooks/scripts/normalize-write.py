#!/usr/bin/env python3
"""PreToolUse Write|Edit: make the write correct instead of refusing it.

A guard that knows the deterministic fix and blocks anyway spends a whole turn to
say what it could have done itself. Measured 2026-09-10: ~1,100 blocked calls in
two weeks from three guards that each printed their own remedy.

Fails open, always. A normalization nicety must never break a write: any error,
any surprise, and the original input passes through untouched.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

TEXT_SUFFIXES = {".md", ".mdx", ".txt", ".py", ".sh", ".js", ".ts", ".tsx", ".jsx",
                 ".json", ".yaml", ".yml", ".toml", ".css", ".html", ".svelte"}
PROSE_SUFFIXES = {".md", ".mdx", ".txt"}
FENCE = re.compile(r"^\s*(```|~~~)")
REGISTRY = ".kernel-normalize.json"
MAX_BYTES = 2_000_000


def strip_em_dashes(text: str) -> str:
    """Doctrine: no em dashes. Prose only, and never inside a fenced code block."""
    out, in_fence = [], False
    for line in text.split("\n"):
        if FENCE.match(line):
            in_fence = not in_fence
        elif not in_fence:
            line = line.replace(" — ", " - ").replace("—", "-")
        out.append(line)
    return "\n".join(out)


def builtin(text: str, path: Path) -> str:
    suffix = path.suffix.lower()
    if suffix not in TEXT_SUFFIXES:
        return text
    text = text.replace("\r\n", "\n").replace(" ", " ")
    if suffix in PROSE_SUFFIXES:
        text = strip_em_dashes(text)
    if text and not text.endswith("\n"):
        text += "\n"
    return text


def registered(text: str, path: Path) -> str:
    """Repo-declared normalizers: {"rules":[{"match":"glob","command":["prog","--stdin"]}]}

    The command receives the content on stdin and returns the normalized content on
    stdout. A non-zero exit, a timeout, or empty output leaves the content alone.
    """
    for parent in [path, *path.parents]:
        config = parent / REGISTRY
        if not config.is_file():
            continue
        try:
            rules = json.loads(config.read_text()).get("rules", [])
        except (OSError, ValueError):
            return text
        for rule in rules:
            if not path.match(rule.get("match", "")):
                continue
            command = rule.get("command")
            if not isinstance(command, list) or not command:
                continue
            try:
                done = subprocess.run(command, input=text, text=True, timeout=5,
                                      capture_output=True, cwd=parent, check=False)
            except (OSError, subprocess.SubprocessError):
                continue
            if done.returncode == 0 and done.stdout:
                text = done.stdout
        return text
    return text


def normalize(text: str, path: Path) -> str:
    return registered(builtin(text, path), path)


def main() -> int:
    try:
        event = json.load(sys.stdin)
    except (ValueError, OSError):
        return 0
    tool_input = event.get("tool_input") or {}
    field = {"Write": "content", "Edit": "new_string"}.get(event.get("tool_name"))
    original = tool_input.get(field) if field else None
    raw = tool_input.get("file_path") or ""
    if not isinstance(original, str) or not original or not raw:
        return 0
    if len(original) > MAX_BYTES:
        return 0

    fixed = normalize(original, Path(raw))
    if fixed == original:
        return 0

    json.dump({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "allow",
        "updatedInput": {**tool_input, field: fixed},
    }}, sys.stdout)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:  # fail open, always
        sys.exit(0)
