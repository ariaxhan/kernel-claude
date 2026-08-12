#!/usr/bin/env python3
"""Tests for scripts/adjudicate.py, the acceptance function.

These are written fails-before: each one names a defect that was live in the review loop before
this script existed, and would go red if the corresponding rule were removed. Refs #204.
"""

import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import adjudicate  # noqa: E402


def finding(**kw):
    base = {
        "summary": "s",
        "severity": "blocker",
        "distance": 0,
        "validated": "proven",
        "on_objective": True,
        "observable": "the request 500s",
        "repro": "$ curl /x\n500",
    }
    base.update(kw)
    return base


def doc(*findings, cannot_falsify=("conformance only",)):
    return {"cannot_falsify": list(cannot_falsify), "findings": list(findings)}


class BlockBar(unittest.TestCase):
    def test_a_complete_blocker_blocks(self):
        r = adjudicate.adjudicate(doc(finding()))
        self.assertEqual(r["verdict"], "FAIL")
        self.assertEqual(r["counts"]["blocking"], 1)

    def test_criticism_is_not_evidence(self):
        """Reviewer says 'possible race condition' and the coder fixes it. The defect."""
        r = adjudicate.adjudicate(doc(finding(validated="pending")))
        self.assertEqual(r["verdict"], "PASS")
        self.assertIn("criticism is not evidence", " ".join(
            r["quarantined"][0]["not_blocking_because"]))

    def test_no_observable_no_block(self):
        """The stopping wager: a blocker must predict what breaks and how we would see it."""
        r = adjudicate.adjudicate(doc(finding(observable="")))
        self.assertEqual(r["verdict"], "PASS")

    def test_nits_never_block(self):
        """Flat severity is the pressure that selects for weak instruments."""
        for sev in ("major", "minor", "nit"):
            self.assertEqual(adjudicate.adjudicate(doc(finding(severity=sev)))["verdict"], "PASS")

    def test_off_objective_never_blocks_however_real(self):
        """Production hardening on a demo: real, proven, distance-0, and still not a blocker."""
        r = adjudicate.adjudicate(doc(finding(on_objective=False)))
        self.assertEqual(r["verdict"], "PASS")
        self.assertIn("off-objective", " ".join(r["quarantined"][0]["not_blocking_because"]))


class DistanceIsAProofThreshold(unittest.TestCase):
    """The 2026-08-03 genre pivot was distance-3 and is the highest-value review on record.
    A hard 'distance >= 2 cannot block' cutoff auto-closes it. These tests pin the fix."""

    def test_distance_three_with_real_evidence_blocks(self):
        r = adjudicate.adjudicate(doc(finding(
            distance=3, evidence_kind="observed_outcome",
            summary="the genre is wrong", observable="5/5 playtesters quit at 4 min")))
        self.assertEqual(r["verdict"], "FAIL", "a distance-3 finding with real evidence must block")

    def test_distance_three_on_taste_does_not_block(self):
        r = adjudicate.adjudicate(doc(finding(distance=3, summary="prefer a strategy pattern")))
        self.assertEqual(r["verdict"], "PASS")

    def test_distance_two_needs_a_user_visible_consequence(self):
        self.assertEqual(adjudicate.adjudicate(doc(finding(distance=2)))["verdict"], "PASS")
        self.assertEqual(adjudicate.adjudicate(doc(finding(
            distance=2, consequence="users lose custom rooms on restore")))["verdict"], "FAIL")

    def test_distance_saturates_rather_than_rising_forever(self):
        r = adjudicate.adjudicate(doc(finding(distance=9, evidence_kind="cited_prior_failure")))
        self.assertEqual(r["verdict"], "FAIL")

    def test_malformed_distance_does_not_block(self):
        self.assertEqual(adjudicate.adjudicate(doc(finding(distance="soon")))["verdict"], "PASS")


class SilenceAboutCoverage(unittest.TestCase):
    def test_empty_cannot_falsify_is_invalid_not_pass(self):
        """Two flagship gates printed PASS for weeks because ripgrep was missing."""
        r = adjudicate.adjudicate(doc(finding(severity="nit"), cannot_falsify=()))
        self.assertEqual(r["verdict"], "INVALID")

    def test_whitespace_does_not_count_as_a_declaration(self):
        r = adjudicate.adjudicate(doc(finding(severity="nit"), cannot_falsify=("   ",)))
        self.assertEqual(r["verdict"], "INVALID")

    def test_a_fail_also_needs_declared_blind_spots(self):
        """A FAIL with unknown coverage is still a claim about the world."""
        self.assertEqual(adjudicate.adjudicate(doc(finding(), cannot_falsify=()))["verdict"],
                         "INVALID")


class Unverifiable(unittest.TestCase):
    def test_unverifiable_escalates_rather_than_vanishing(self):
        """'We could not reproduce it' and 'it is not a problem' are different sentences."""
        r = adjudicate.adjudicate(doc(finding(validated="unverifiable")))
        self.assertEqual(r["verdict"], "PASS")
        self.assertEqual(r["counts"]["escalate"], 1)
        self.assertEqual(r["counts"]["quarantined"], 0)


class Termination(unittest.TestCase):
    def test_a_clean_run_terminates(self):
        """The whole point: review must be able to say it is fine."""
        r = adjudicate.adjudicate(doc())
        self.assertEqual(r["verdict"], "PASS")

    def test_pass_survives_a_pile_of_nits(self):
        """Nine nits do not add up to a blocker, however many passes produced them."""
        r = adjudicate.adjudicate(doc(*[finding(severity="nit", summary=f"n{i}") for i in range(9)]))
        self.assertEqual(r["verdict"], "PASS")
        self.assertEqual(r["counts"]["quarantined"], 9)


class Cli(unittest.TestCase):
    def _run(self, payload, *args):
        return subprocess.run(
            [sys.executable, str(ROOT / "scripts" / "adjudicate.py"), "-", *args],
            input=json.dumps(payload), capture_output=True, text=True)

    def test_strict_exit_codes(self):
        self.assertEqual(self._run(doc(), "--strict").returncode, 0)
        self.assertEqual(self._run(doc(finding()), "--strict").returncode, 1)
        self.assertEqual(self._run(doc(cannot_falsify=()), "--strict").returncode, 2)

    def test_malformed_json_is_refused_not_ignored(self):
        p = subprocess.run(
            [sys.executable, str(ROOT / "scripts" / "adjudicate.py"), "-", "--strict"],
            input="{not json", capture_output=True, text=True)
        self.assertEqual(p.returncode, 2)


if __name__ == "__main__":
    unittest.main(verbosity=2)
