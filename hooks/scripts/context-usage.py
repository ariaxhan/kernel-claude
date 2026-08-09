#!/usr/bin/env python3
"""Report last-known Codex context occupancy without exposing rollout content."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
from typing import Any, Dict, Optional, Tuple


STALE_AFTER_SECONDS = 300
THREAD_ID = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
# Codex reorders and adds top-level envelope fields between releases: 0.147.0
# introduced "ordinal" between "timestamp" and "type", which a timestamp-only
# prefix does not span. The meter then matched no event and reported "unknown"
# on every live session while the suite stayed green on pre-0.147.0 fixtures.
#
# So skip ANY run of leading SCALAR fields. Scalars only, deliberately: prompts,
# messages, tool results and reasoning all live in nested objects and arrays,
# which this cannot cross. The envelope stays walkable, content stays unreachable.
JSON_SCALAR = (
    rb'(?:"(?:[^"\\]|\\.)*"'          # string
    rb'|-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?'  # number
    rb'|true|false|null)'
)
TIMESTAMP_PREFIX = (
    rb'(?:"(?:[^"\\]|\\.)*"\s*:\s*' + JSON_SCALAR + rb'\s*,\s*)*'
)
TOP_LEVEL_COMPACTED = re.compile(
    rb'^\s*\{\s*' + TIMESTAMP_PREFIX + rb'"type"\s*:\s*"compacted"\s*[,}]'
)
EVENT_MSG = re.compile(
    rb'^\s*\{\s*' + TIMESTAMP_PREFIX + rb'"type"\s*:\s*"event_msg"\s*[,}]'
)
TOKEN_COUNT = re.compile(
    rb'"payload"\s*:\s*\{\s*"type"\s*:\s*"token_count"\s*[,}]'
)
CONTEXT_COMPACTED = re.compile(
    rb'"payload"\s*:\s*\{\s*"type"\s*:\s*"context_compacted"\s*[,}]'
)
LAST_FIELDS = (
    "input_tokens",
    "cached_input_tokens",
    "output_tokens",
    "reasoning_output_tokens",
    "total_tokens",
)


def empty_status(thread_id: Optional[str], state: str = "unknown") -> Dict[str, Any]:
    return {
        "thread_id": thread_id,
        "rollout": None,
        "observed_at": None,
        "event_age_seconds": None,
        "window_number": None,
        "last": {field: None for field in LAST_FIELDS},
        "context_window": None,
        "used_percent": None,
        "remaining_tokens": None,
        "cumulative_total_tokens": None,
        "state": state,
    }


def parse_time(value: str) -> dt.datetime:
    parsed = dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=dt.timezone.utc)
    return parsed.astimezone(dt.timezone.utc)


def valid_count(value: Any, positive: bool = False) -> bool:
    return (
        isinstance(value, int)
        and not isinstance(value, bool)
        and value >= (1 if positive else 0)
    )


def candidate(root: str, thread_id: str) -> Tuple[Optional[str], bool]:
    """Return the sole exact-name candidate and whether traversal failed."""
    suffix = "-%s.jsonl" % thread_id
    matches = []
    walk_failed = [False]

    def record_error(_error: OSError) -> None:
        walk_failed[0] = True

    try:
        for directory, _, names in os.walk(root, onerror=record_error):
            for name in names:
                if name.endswith(suffix):
                    matches.append(os.path.join(directory, name))
    except OSError:
        return None, True
    if walk_failed[0]:
        return None, True
    if len(matches) != 1:
        return None, bool(matches)
    return matches[0], False


def resolve_rollout(sessions_root: str, archives_root: str, thread_id: str) -> Optional[str]:
    found = []
    for root in (sessions_root, archives_root):
        path, failed = candidate(root, thread_id)
        if failed:
            return None
        if path is not None:
            found.append(path)
    return found[0] if len(found) == 1 else None


def load_metadata(line: bytes, thread_id: str) -> bool:
    try:
        record = json.loads(line.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        return False
    return (
        isinstance(record, dict)
        and record.get("type") == "session_meta"
        and isinstance(record.get("payload"), dict)
        and record["payload"].get("id") == thread_id
    )


def token_usage(record: Any) -> Optional[Tuple[str, Dict[str, int], int, int]]:
    """Validate a token-count event before returning allowlisted numeric fields."""
    if not isinstance(record, dict) or record.get("type") != "event_msg":
        return None
    payload = record.get("payload")
    if not isinstance(payload, dict) or payload.get("type") != "token_count":
        return None
    info = payload.get("info")
    if not isinstance(info, dict):
        return None
    last = info.get("last_token_usage")
    cumulative = info.get("total_token_usage")
    window = info.get("model_context_window")
    timestamp = record.get("timestamp")
    if (
        not isinstance(last, dict)
        or not isinstance(cumulative, dict)
        or not isinstance(timestamp, str)
        or not valid_count(window, positive=True)
        or not valid_count(cumulative.get("total_tokens"))
        or any(not valid_count(last.get(field)) for field in LAST_FIELDS)
    ):
        return None
    try:
        parse_time(timestamp)
    except (TypeError, ValueError):
        return None
    safe_last = {field: last[field] for field in LAST_FIELDS}
    return timestamp, safe_last, window, cumulative["total_tokens"]


def read_status(path: str, thread_id: str, now: dt.datetime) -> Dict[str, Any]:
    status = empty_status(thread_id)
    status["rollout"] = os.path.basename(path)
    last_usage = None
    window_number = 1
    degraded = False

    try:
        with open(path, "rb") as rollout:
            if not load_metadata(rollout.readline(), thread_id):
                return empty_status(thread_id)
            for line in rollout:
                if not line.endswith(b"\n"):
                    degraded = True
                    continue
                if TOP_LEVEL_COMPACTED.match(line):
                    window_number += 1
                    continue
                if not EVENT_MSG.match(line):
                    continue
                if CONTEXT_COMPACTED.search(line):
                    window_number += 1
                    continue
                if not TOKEN_COUNT.search(line):
                    continue
                try:
                    record = json.loads(line.decode("utf-8"))
                except (UnicodeDecodeError, json.JSONDecodeError):
                    degraded = True
                    continue
                usage = token_usage(record)
                if usage is None:
                    degraded = True
                    continue
                last_usage = usage
    except OSError:
        return empty_status(thread_id)

    if last_usage is None:
        return empty_status(thread_id, "stale" if degraded else "unknown")

    observed_at, last, context_window, cumulative = last_usage
    try:
        age = int((now - parse_time(observed_at)).total_seconds())
    except (TypeError, ValueError, OverflowError):
        return empty_status(thread_id, "stale")

    total = last["total_tokens"]
    used_percent = total * 100 / context_window
    if used_percent < 50:
        state = "green"
    elif used_percent < 60:
        state = "checkpoint"
    elif used_percent < 70:
        state = "compact_at_boundary"
    else:
        state = "emergency"
    if degraded or age < 0 or age > STALE_AFTER_SECONDS:
        state = "stale"

    status.update(
        {
            "observed_at": observed_at,
            "event_age_seconds": age,
            "window_number": window_number,
            "last": last,
            "context_window": context_window,
            "used_percent": used_percent,
            "remaining_tokens": max(context_window - total, 0),
            "cumulative_total_tokens": cumulative,
            "state": state,
        }
    )
    return status


def render_hook(status: Dict[str, Any]) -> str:
    if status["used_percent"] is None:
        return "[context] %s" % status["state"]
    line = "[context] %s %.1f%% used, %d tokens remain, window %d" % (
        status["state"],
        status["used_percent"],
        status["remaining_tokens"],
        status["window_number"],
    )
    return line if len(line) <= 240 else "[context] %s" % status["state"]


def main() -> int:
    home = os.path.expanduser("~")
    parser = argparse.ArgumentParser(description="Read Codex context occupancy metadata.")
    parser.add_argument("--json", action="store_true", help="emit allowlisted JSON")
    parser.add_argument("--sessions-root", default=os.path.join(home, ".codex", "sessions"))
    parser.add_argument(
        "--archives-root", default=os.path.join(home, ".codex", "archived_sessions")
    )
    parser.add_argument("--now", help="UTC ISO-8601 time used for freshness checks")
    args = parser.parse_args()

    thread_id = os.environ.get("CODEX_THREAD_ID")
    status = empty_status(thread_id)
    if thread_id and THREAD_ID.fullmatch(thread_id):
        path = resolve_rollout(args.sessions_root, args.archives_root, thread_id)
        if path is not None:
            try:
                now = parse_time(args.now) if args.now else dt.datetime.now(dt.timezone.utc)
            except (TypeError, ValueError):
                now = dt.datetime.now(dt.timezone.utc)
                status = empty_status(thread_id, "stale")
            else:
                status = read_status(path, thread_id, now)

    if args.json:
        print(json.dumps(status, separators=(",", ":"), sort_keys=True))
    else:
        print(render_hook(status))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
