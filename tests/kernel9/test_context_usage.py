#!/usr/bin/env python3
"""Black-box contract for the read-only Codex context-usage hook.

The rollout is private transcript data.  These fixtures therefore contain only the
small structural envelope the meter is allowed to use, plus a deliberately toxic
canary in content-bearing fields.  The command must select its rollout from
``CODEX_THREAD_ID`` and validate line one before it treats any token event as data.

The public command shape is intentionally fixed here before implementation:

    hooks/scripts/context-usage.py --json --sessions-root DIR --archives-root DIR --now ISO8601

There is no current public meter interface to preserve.  If one appears before this
suite is implemented, its incompatibility must be resolved explicitly rather than
silently changing these fixtures.
"""

from __future__ import annotations

import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest


REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SCRIPT = os.path.join(REPO, "hooks", "scripts", "context-usage.py")
GENERATOR = os.path.join(REPO, "scripts", "generate-adapters.py")
# One shared manifest since 2026-08-27. The root hooks.json was a second,
# Codex-tuned copy that Codex never read, so it is gone.
HOOK_FILES = (os.path.join("hooks", "hooks.json"),)
NOW = "2026-08-06T12:00:00Z"
CANARY = "context-meter-canary-NOT-A-REAL-SECRET-7f3a9c"

JSON_KEYS = {
    "thread_id",
    "rollout",
    "observed_at",
    "event_age_seconds",
    "window_number",
    "last",
    "context_window",
    "used_percent",
    "remaining_tokens",
    "cumulative_total_tokens",
    "state",
}
LAST_KEYS = {
    "input_tokens",
    "cached_input_tokens",
    "output_tokens",
    "reasoning_output_tokens",
    "total_tokens",
}


def token_event(
    at,
    total,
    window=1000,
    input_tokens=None,
    cached_input_tokens=0,
    output_tokens=0,
    reasoning_output_tokens=0,
    cumulative_total=None,
):
    """Return the smallest safe token_count record.

    ``total_tokens`` is authoritative, including immediately after compaction when
    all components may be zero.  Cached input and reasoning output are subsets.
    """
    if input_tokens is None:
        input_tokens = total - output_tokens
    if cumulative_total is None:
        cumulative_total = total
    return {
        "type": "event_msg",
        "timestamp": at,
        "payload": {
            "type": "token_count",
            "info": {
                "last_token_usage": {
                    "input_tokens": input_tokens,
                    "cached_input_tokens": cached_input_tokens,
                    "output_tokens": output_tokens,
                    "reasoning_output_tokens": reasoning_output_tokens,
                    "total_tokens": total,
                },
                "total_token_usage": {"total_tokens": cumulative_total},
                "model_context_window": window,
            },
        },
    }


def compacted(at, replacement_history=CANARY):
    """A content-bearing compaction record, which must never be emitted."""
    return {
        "type": "compacted",
        "timestamp": at,
        "payload": {"replacement_history": replacement_history},
    }


class MeterHarness:
    def __init__(self, case, root):
        self.case = case
        self.root = root
        self.sessions = os.path.join(root, "sessions")
        self.archives = os.path.join(root, "archived_sessions")
        os.mkdir(self.sessions)
        os.mkdir(self.archives)

    def write_rollout(self, directory, thread_id, records, metadata_id=None, name=None):
        if metadata_id is None:
            metadata_id = thread_id
        if name is None:
            name = "rollout-fixture-%s.jsonl" % thread_id
        path = os.path.join(directory, name)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(json.dumps({"type": "session_meta", "payload": {"id": metadata_id}}))
            fh.write("\n")
            for record in records:
                fh.write(json.dumps(record, separators=(",", ":")))
                fh.write("\n")
        return path

    def append_truncated_line(self, path):
        with open(path, "a", encoding="utf-8") as fh:
            fh.write('{"type":"event_msg","payload":{"type":"token_count"')

    def run(self, thread_id, json_mode=True, now=NOW):
        self.case.assertTrue(
            os.path.isfile(SCRIPT),
            "context-usage implementation is absent: %s" % SCRIPT,
        )
        env = dict(os.environ)
        env.pop("CODEX_THREAD_ID", None)
        if thread_id is not None:
            env["CODEX_THREAD_ID"] = thread_id
        # A broken implementation must not fall back to a developer's real rollout
        # when the test deliberately supplies both fixture roots.
        env["HOME"] = self.root
        env["PYTHONDONTWRITEBYTECODE"] = "1"
        command = [
            sys.executable,
            SCRIPT,
            "--sessions-root", self.sessions,
            "--archives-root", self.archives,
            "--now", now,
        ]
        if json_mode:
            command.insert(2, "--json")
        proc = subprocess.run(
            command,
            cwd=REPO,
            env=env,
            capture_output=True,
            text=True,
        )
        self.case.assertEqual(
            proc.returncode,
            0,
            "meter failed\nstdout:\n%s\nstderr:\n%s" % (proc.stdout, proc.stderr),
        )
        return proc

    @staticmethod
    def snapshot(root):
        found = {}
        for directory, _, names in os.walk(root):
            for name in names:
                path = os.path.join(directory, name)
                with open(path, "rb") as fh:
                    found[os.path.relpath(path, root)] = fh.read()
        return found


class ContextUsageContract(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="kernel9-context-usage-")
        self.addCleanup(self.temp.cleanup)
        self.h = MeterHarness(self, self.temp.name)

    def json_status(self, thread_id="thread-a", now=NOW):
        proc = self.h.run(thread_id, json_mode=True, now=now)
        self.assertEqual(proc.stderr, "", "diagnostic mode must not leak transcript data")
        try:
            doc = json.loads(proc.stdout)
        except json.JSONDecodeError as exc:
            self.fail("--json did not emit exactly one JSON object: %s\n%s" % (exc, proc.stdout))
        self.assertEqual(set(doc), JSON_KEYS, "JSON output must remain allowlisted")
        self.assertEqual(set(doc["last"]), LAST_KEYS, "last-token output must remain allowlisted")
        return doc, proc

    def write_fresh(self, thread_id="thread-a", total=499, window=1000, **kwargs):
        return self.h.write_rollout(
            self.h.sessions,
            thread_id,
            [token_event("2026-08-06T11:59:59Z", total, window, **kwargs)],
        )

    def test_command_exists_at_the_documented_hook_path(self):
        self.assertTrue(os.path.isfile(SCRIPT), "missing standalone stdlib meter")

    def test_competing_newer_rollout_cannot_steal_thread_selection(self):
        self.write_fresh("thread-a", total=499)
        newer = self.write_fresh("thread-b", total=700)
        os.utime(newer, (2_000_000_000, 2_000_000_000))
        doc, _ = self.json_status("thread-a")
        self.assertEqual(doc["thread_id"], "thread-a")
        self.assertEqual(doc["last"]["total_tokens"], 499)
        self.assertEqual(doc["state"], "green")

    def test_filename_match_with_metadata_mismatch_is_unknown(self):
        self.h.write_rollout(
            self.h.sessions,
            "thread-a",
            [token_event("2026-08-06T11:59:59Z", 499)],
            metadata_id="a-different-thread",
        )
        doc, _ = self.json_status("thread-a")
        self.assertEqual(doc["state"], "unknown")
        self.assertEqual(doc["thread_id"], "thread-a")

    def test_missing_thread_id_is_unknown(self):
        self.write_fresh()
        doc, _ = self.json_status(thread_id=None)
        self.assertEqual(doc["state"], "unknown")
        self.assertIsNone(doc["thread_id"])

    def test_old_last_event_is_stale_not_green(self):
        self.h.write_rollout(
            self.h.sessions,
            "thread-a",
            [token_event("2026-08-01T12:00:00Z", 100)],
        )
        doc, _ = self.json_status(now=NOW)
        self.assertEqual(doc["state"], "stale")
        self.assertEqual(doc["event_age_seconds"], 432000)

    def test_truncated_final_jsonl_uses_previous_event_and_marks_stale(self):
        path = self.write_fresh(total=499)
        self.h.append_truncated_line(path)
        doc, _ = self.json_status()
        self.assertEqual(doc["last"]["total_tokens"], 499)
        self.assertEqual(doc["state"], "stale")

    def test_archive_only_rollout_is_resolved(self):
        self.h.write_rollout(
            self.h.archives,
            "thread-a",
            [token_event("2026-08-06T11:59:59Z", 499)],
        )
        doc, _ = self.json_status()
        self.assertEqual(doc["state"], "green")
        self.assertEqual(doc["last"]["total_tokens"], 499)

    def test_archive_rotation_between_reads_preserves_status(self):
        path = self.write_fresh(total=499)
        first, _ = self.json_status()
        rotated = os.path.join(self.h.archives, os.path.basename(path))
        os.rename(path, rotated)
        second, _ = self.json_status()
        self.assertEqual(first["state"], "green")
        self.assertEqual(second["state"], "green")
        self.assertEqual(second["last"]["total_tokens"], 499)

    def test_active_and_cumulative_totals_are_separate(self):
        self.write_fresh(total=25000, window=100000, cumulative_total=15000000)
        doc, _ = self.json_status()
        self.assertEqual(doc["last"]["total_tokens"], 25000)
        self.assertEqual(doc["cumulative_total_tokens"], 15000000)
        self.assertEqual(doc["used_percent"], 25.0)
        self.assertEqual(doc["state"], "green")

    def test_cached_and_reasoning_subsets_are_not_double_counted(self):
        self.write_fresh(
            total=105000,
            window=200000,
            input_tokens=100000,
            cached_input_tokens=90000,
            output_tokens=5000,
            reasoning_output_tokens=4000,
        )
        doc, _ = self.json_status()
        self.assertEqual(doc["last"]["input_tokens"], 100000)
        self.assertEqual(doc["last"]["cached_input_tokens"], 90000)
        self.assertEqual(doc["last"]["output_tokens"], 5000)
        self.assertEqual(doc["last"]["reasoning_output_tokens"], 4000)
        self.assertEqual(doc["last"]["total_tokens"], 105000)
        self.assertEqual(doc["used_percent"], 52.5)
        self.assertEqual(doc["state"], "checkpoint")

    def test_post_compaction_explicit_total_beats_zero_components(self):
        self.h.write_rollout(
            self.h.sessions,
            "thread-a",
            [
                compacted("2026-08-06T11:58:00Z"),
                token_event(
                    "2026-08-06T11:59:59Z",
                    21494,
                    window=258400,
                    input_tokens=0,
                    output_tokens=0,
                    cumulative_total=8302072,
                ),
            ],
        )
        doc, _ = self.json_status()
        self.assertEqual(doc["last"]["total_tokens"], 21494)
        self.assertEqual(doc["used_percent"], 8.31811145510836)
        self.assertEqual(doc["cumulative_total_tokens"], 8302072)
        self.assertEqual(doc["state"], "green")

    def test_latest_compaction_sets_second_context_window(self):
        self.h.write_rollout(
            self.h.sessions,
            "thread-a",
            [
                token_event("2026-08-06T11:57:00Z", 900),
                {"type": "event_msg", "timestamp": "2026-08-06T11:58:00Z", "payload": {"type": "context_compacted"}},
                token_event("2026-08-06T11:59:59Z", 200),
            ],
        )
        doc, _ = self.json_status()
        self.assertEqual(doc["window_number"], 2)
        self.assertEqual(doc["last"]["total_tokens"], 200)

    def assert_threshold(self, total, expected_state, expected_percent):
        self.write_fresh(total=total)
        doc, _ = self.json_status()
        self.assertEqual(doc["used_percent"], expected_percent)
        self.assertEqual(doc["state"], expected_state)

    def test_threshold_49_9_is_green(self):
        self.assert_threshold(499, "green", 49.9)

    def test_threshold_50_is_checkpoint(self):
        self.assert_threshold(500, "checkpoint", 50.0)

    def test_threshold_59_9_is_checkpoint(self):
        self.assert_threshold(599, "checkpoint", 59.9)

    def test_threshold_60_is_compact_at_boundary(self):
        self.assert_threshold(600, "compact_at_boundary", 60.0)

    def test_threshold_69_9_is_compact_at_boundary(self):
        self.assert_threshold(699, "compact_at_boundary", 69.9)

    def test_threshold_70_is_emergency(self):
        self.assert_threshold(700, "emergency", 70.0)

    def test_hook_output_is_one_bounded_line(self):
        self.write_fresh(total=499)
        proc = self.h.run("thread-a", json_mode=False)
        lines = proc.stdout.splitlines()
        self.assertEqual(len(lines), 1)
        self.assertTrue(lines[0])
        self.assertLessEqual(len(lines[0]), 240)
        self.assertNotIn(
            lines[0][0],
            "[{",
            "Codex treats stdout beginning with a JSON sigil as structured hook output",
        )
        self.assertIn("green", lines[0])
        self.assertNotIn(CANARY, proc.stdout)
        self.assertNotIn(CANARY, proc.stderr)

    def test_content_canary_never_leaks_to_output_or_json(self):
        self.h.write_rollout(
            self.h.sessions,
            "thread-a",
            [
                {
                    "type": "response_item",
                    "payload": {"prompt": CANARY, "tool_result": CANARY},
                },
                compacted("2026-08-06T11:58:00Z", replacement_history=CANARY),
                token_event("2026-08-06T11:59:59Z", 499),
            ],
        )
        doc, proc = self.json_status()
        self.assertEqual(doc["state"], "green")
        self.assertNotIn(CANARY, proc.stdout)
        self.assertNotIn(CANARY, proc.stderr)
        self.assertNotIn(CANARY, json.dumps(doc, sort_keys=True))

    def test_status_read_does_not_write_fixture_roots(self):
        self.write_fresh(total=499)
        before = self.h.snapshot(self.temp.name)
        self.json_status()
        after = self.h.snapshot(self.temp.name)
        self.assertEqual(after, before, "a status read must not create or modify state")


class RealCodexEnvelopeShape(unittest.TestCase):
    """The envelope Codex actually writes, not the one our fixtures assumed.

    Every other fixture in this file serializes ``{"type": ..., "timestamp": ...}``
    because that is the order the parser was written to expect. Codex writes
    ``{"timestamp": ..., "ordinal": ..., "type": ...}``, and 0.147.0 added that
    ``ordinal`` field between timestamp and type.

    The line-matching prefix spanned an optional timestamp and nothing else, so
    on 0.147.0 it matched no event at all and the meter reported "unknown" on
    every live session. The suite stayed green throughout, because fixtures
    authored from the parser's expectations can only ever confirm them.

    Caught by running the meter against a real rollout and cross-checking the
    number with an independent awk/jq pipeline, not by any test that existed.
    """

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="kernel9-envelope-")
        self.addCleanup(self.temp.cleanup)
        self.root = self.temp.name
        self.meter = MeterHarness(self, self.root)

    def _envelope(self, extra_fields):
        """A token_count record with real Codex field ordering."""
        record = {"timestamp": NOW}
        record.update(extra_fields)
        record["type"] = "event_msg"
        record["payload"] = {
            "type": "token_count",
            "info": {
                "last_token_usage": {
                    "input_tokens": 400,
                    "cached_input_tokens": 0,
                    "output_tokens": 100,
                    "reasoning_output_tokens": 0,
                    "total_tokens": 500,
                },
                "total_token_usage": {"total_tokens": 500},
                "model_context_window": 1000,
            },
        }
        return record

    def _read(self, thread_id):
        return json.loads(self.meter.run(thread_id).stdout)

    def test_timestamp_first_ordering_is_parsed(self):
        self.meter.write_rollout(self.meter.sessions, "t-order", [self._envelope({})])
        status = self._read("t-order")
        self.assertEqual(status["last"]["total_tokens"], 500)
        self.assertEqual(status["context_window"], 1000)

    def test_ordinal_between_timestamp_and_type_is_parsed(self):
        """The exact 0.147.0 regression."""
        self.meter.write_rollout(
            self.meter.sessions, "t-ordinal", [self._envelope({"ordinal": 102})]
        )
        status = self._read("t-ordinal")
        self.assertEqual(
            status["last"]["total_tokens"], 500,
            "an added scalar envelope field silently blanked the meter",
        )
        self.assertEqual(status["used_percent"], 50.0)

    def test_unknown_future_scalar_envelope_fields_are_parsed(self):
        """Codex adds envelope fields between releases. Do not re-break on the next one."""
        self.meter.write_rollout(
            self.meter.sessions,
            "t-future",
            [self._envelope({"ordinal": 7, "seq": 1, "replayed": False, "note": None})],
        )
        self.assertEqual(self._read("t-future")["last"]["total_tokens"], 500)

    def test_envelope_walk_still_cannot_cross_a_nested_object(self):
        """The prefix skips scalars only. Content lives in nested objects.

        If this ever passes with a leading nested object, the meter has gained
        the ability to walk into exactly the structures it is forbidden to read.
        """
        spec = importlib.util.spec_from_file_location("context_usage_module", SCRIPT)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        nested = b'{"payload":{"prompt":"' + CANARY.encode() + b'"},"type":"event_msg"}'
        self.assertIsNone(
            module.EVENT_MSG.match(nested),
            "envelope prefix crossed a nested object and can now reach content",
        )

class ContextUsageWiringContract(unittest.TestCase):
    def test_both_generated_host_hooks_bind_the_meter(self):
        expected = "hooks/scripts/context-usage.py"
        for rel in HOOK_FILES:
            with self.subTest(hooks_file=rel):
                with open(os.path.join(REPO, rel), encoding="utf-8") as fh:
                    doc = json.load(fh)
                commands = [
                    hook["command"]
                    for group in doc["hooks"]["UserPromptSubmit"]
                    for hook in group["hooks"]
                ]
                self.assertTrue(
                    any(command.endswith(expected) for command in commands),
                    "%s must wire the standalone context meter" % rel,
                )

    def test_adapter_generator_declares_the_meter_binding(self):
        with open(GENERATOR, encoding="utf-8") as fh:
            source = fh.read()
        self.assertIn(
            '"script": "context-usage.py"',
            source,
            "generated adapters must own the context-meter binding",
        )


if __name__ == "__main__":
    unittest.main()
