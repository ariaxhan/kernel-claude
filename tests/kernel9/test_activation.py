#!/usr/bin/env python3
"""Armed-path tests for KERNEL 9 request routing.

These drive the exact UserPromptSubmit script installed by both host adapters.
The router is not considered active merely because its Python unit tests pass.
"""

from __future__ import annotations

import json
import os
import subprocess
import tempfile
import time
import unittest

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HOOK = os.path.join(REPO, "hooks", "scripts", "route-request.sh")


class ActivationHarness:
    def __init__(self, tmp):
        self.tmp = tmp
        self.state = os.path.join(tmp, "state")
        self.receipt = os.path.join(tmp, "receipts.jsonl")

    def run(self, prompt, session="session-1", field="prompt", extra_env=None):
        payload = {
            field: prompt,
            "session_id": session,
            "cwd": self.tmp,
            "hook_event_name": "UserPromptSubmit",
        }
        env = {
            **os.environ,
            "KERNEL_ROUTER_STATE_DIR": self.state,
            "KERNEL_ROUTER_RECEIPT_PATH": self.receipt,
            "PYTHONDONTWRITEBYTECODE": "1",
        }
        env.update(extra_env or {})
        proc = subprocess.run(
            [HOOK],
            input=json.dumps(payload),
            capture_output=True,
            text=True,
            cwd=self.tmp,
            env=env,
        )
        self.assert_ok(proc)
        with open(self.receipt) as fh:
            receipt = json.loads(fh.readlines()[-1])
        return proc.stdout, receipt

    @staticmethod
    def assert_ok(proc):
        if proc.returncode != 0:
            raise AssertionError(
                f"hook exited {proc.returncode}\nstdout:\n{proc.stdout}\nstderr:\n{proc.stderr}"
            )

    def age_session(self, minutes):
        entries = os.listdir(self.state)
        if len(entries) != 1:
            raise AssertionError(f"expected one state file, found {entries}")
        path = os.path.join(self.state, entries[0])
        with open(path) as fh:
            doc = json.load(fh)
        doc["started_at"] = int(time.time()) - minutes * 60
        with open(path, "w") as fh:
            json.dump(doc, fh)


class UserPromptSubmitActivation(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="kernel9-activation-")
        self.addCleanup(self.temp.cleanup)
        self.h = ActivationHarness(self.temp.name)

    def test_direct_normal_status_is_silent_but_receipted(self):
        output, receipt = self.h.run("what is the current status?")
        self.assertEqual(output, "")
        self.assertEqual(receipt["event"], "kernel.route")
        self.assertEqual(receipt["status"], "classified")
        self.assertEqual(receipt["work_shape"], "direct")
        self.assertEqual(receipt["safety"], "normal")

    def test_status_does_not_replace_the_active_route(self):
        self.h.run("iterate on the visual through several passes until it feels right")
        output, status = self.h.run("what is the current status?")
        self.assertEqual(output, "")
        self.assertEqual(status["work_shape"], "direct")
        self.assertTrue(status["transient"])
        self.assertNotIn("transitions", status)
        _, resumed = self.h.run("continue")
        self.assertEqual(resumed["work_shape"], "trajectory")

    def test_status_retains_safety_without_replacing_the_active_route(self):
        self.h.run("strictly read-only: review this classifier and do not modify it")
        output, status = self.h.run("what is the current status?")
        self.assertEqual(status["work_shape"], "direct")
        self.assertEqual(status["safety"], "protected")
        self.assertTrue(status["transient"])
        self.assertIn("Shape: direct | safety: protected", output)
        _, resumed = self.h.run("continue")
        self.assertEqual(resumed["work_shape"], "gated")
        self.assertEqual(resumed["safety"], "protected")

    def test_bounded_comparison_is_gated_not_trajectory(self):
        output, receipt = self.h.run(
            "produce a bounded local comparison artifact for these two previews"
        )
        self.assertIn("Shape: gated", output)
        self.assertEqual(receipt["work_shape"], "gated")
        self.assertEqual(receipt["domain"], "design")
        self.assertIn("/packs/design/PACK.md", output)
        self.assertNotIn("Select the next intervention", output)

    def test_state_heavy_feedback_work_activates_trajectory(self):
        output, receipt = self.h.run(
            "keep iterating on the visual and performance behavior; observe fresh-process "
            "save/load and allocation measurements, then reassess each pass"
        )
        self.assertEqual(receipt["work_shape"], "trajectory")
        self.assertIn("Plans are non-authoritative", output)
        self.assertIn("current objective, verified state, evidence, capability", output)

    def test_read_only_is_an_independent_protected_boundary(self):
        output, receipt = self.h.run(
            "strictly read-only: review the classifier and do not modify anything"
        )
        self.assertEqual(receipt["work_shape"], "gated")
        self.assertEqual(receipt["safety"], "protected")
        self.assertIn("Safety is a separate hard boundary", output)
        self.assertIn("no-write instruction remains binding", output)

    def test_ambiguous_cleanup_reassesses_when_live_state_expands(self):
        _, first = self.h.run("clean up the integrity issues in this project")
        self.assertEqual(first["work_shape"], "gated")
        self.h.age_session(55)
        output, second = self.h.run(
            "new evidence: we found several integrity bugs, the scope expanded into "
            "multiple repairs, and a long-running process is still active"
        )
        self.assertEqual(second["work_shape"], "trajectory")
        self.assertEqual(second["transitions"][-1]["from"], "gated")
        self.assertEqual(second["transitions"][-1]["to"], "trajectory")
        self.assertIn("reassess after every meaningful revision", output)

    def test_meaningful_revision_can_drop_trajectory_to_gated(self):
        _, first = self.h.run(
            "iterate on the visual through several passes until it feels right"
        )
        self.assertEqual(first["work_shape"], "trajectory")
        output, second = self.h.run(
            "actually stop the broad iteration; only produce a bounded local comparison artifact"
        )
        self.assertEqual(second["work_shape"], "gated")
        self.assertEqual(second["transitions"][-1]["direction"], "deescalate")
        self.assertIn("Shape: gated", output)

    def test_low_information_continuation_keeps_current_live_shape(self):
        self.h.run("iterate on the visual through several passes until it feels right")
        _, second = self.h.run("continue")
        self.assertEqual(second["work_shape"], "trajectory")
        self.assertIn(
            "low-information continuation retained the current live-run shape",
            second["reasons"],
        )

    def test_continuation_cannot_silently_clear_safety(self):
        self.h.run("strictly read-only: review this classifier and do not modify it")
        _, second = self.h.run("continue")
        self.assertEqual(second["safety"], "protected")
        self.assertIn("verification", second)

    def test_safety_boundary_requires_explicit_release(self):
        self.h.run("strictly read-only: review this classifier and do not modify it")
        _, retained = self.h.run("actually focus the review on the request parser")
        self.assertEqual(retained["safety"], "protected")
        _, released = self.h.run(
            "new task: local scratch prototype; writes are allowed"
        )
        self.assertEqual(released["safety"], "normal")

    def test_host_payload_aliases_share_one_provider_neutral_path(self):
        _, claude = self.h.run("review this bounded artifact", session="claude", field="prompt")
        _, codex = self.h.run(
            "review this bounded artifact", session="codex", field="user_prompt"
        )
        self.assertEqual(
            (claude["work_shape"], claude["safety"]),
            (codex["work_shape"], codex["safety"]),
        )

    def test_missing_router_fails_closed_with_receipt(self):
        output, receipt = self.h.run(
            "review this bounded artifact",
            extra_env={"KERNEL_ROUTER_PATH": os.path.join(self.temp.name, "missing-router.py")},
        )
        self.assertIn("KERNEL route unavailable", output)
        self.assertEqual(receipt["status"], "fallback")
        self.assertEqual(receipt["work_shape"], "gated")
        self.assertEqual(receipt["safety"], "protected")

    def test_missing_jq_fails_closed_with_receipt(self):
        bin_dir = os.path.join(self.temp.name, "path-without-jq")
        os.mkdir(bin_dir)
        os.symlink("/usr/bin/dirname", os.path.join(bin_dir, "dirname"))
        os.symlink("/bin/cat", os.path.join(bin_dir, "cat"))
        output, receipt = self.h.run(
            "review this bounded artifact",
            extra_env={"PATH": bin_dir},
        )
        self.assertIn("KERNEL route unavailable", output)
        self.assertEqual(receipt["status"], "fallback")
        self.assertEqual(receipt["safety"], "protected")


if __name__ == "__main__":
    unittest.main(verbosity=2)
