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


def doc(*findings, cannot_falsify=("conformance only",), evidence=None):
    d = {"cannot_falsify": list(cannot_falsify), "findings": list(findings)}
    if evidence is not None:
        d["evidence"] = list(evidence)
    return d


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


# ---------------------------------------------------------------------------
# Extension: acceptance context and finality.
# The same finding must be blocking in one context and quarantined in another, and an accepted
# commit must survive a fresh reviewer who simply feels differently about it.
# ---------------------------------------------------------------------------

DEMO = {
    "schema": "kernel.acceptance-profile/v1",
    "id": "quantum-demo-2026-08-13",
    "stage": "demo",
    "users": {"who": "two people in a room", "count": 2, "real_people": False},
    "data_sensitivity": "none",
    "lifetime": "days",
    "blast_radius": "self",
    "blocks_at": {
        "correctness": "blocker",
        "privacy": "minor",      # still strict, even on a demo
        "security": "minor",     # still strict, even on a demo
        "performance": "never",
        "availability": "never",
        "maintainability": "never",
    },
    "owner": "aria",
}

PROD = {
    "schema": "kernel.acceptance-profile/v1",
    "id": "matra-production",
    "stage": "production",
    "users": {"who": "pregnant people", "count": "thousands", "real_people": True},
    "data_sensitivity": "regulated",
    "lifetime": "years",
    "blast_radius": "customers",
    "blocks_at": {
        "correctness": "major",
        "privacy": "nit",
        "security": "nit",
        "performance": "major",
        "availability": "major",
        "maintainability": "never",
    },
    "owner": "aria",
}


def profiled(profile, *findings, **kw):
    d = doc(*findings, **kw)
    d["profile"] = profile
    return d


class ContextDecidesSeverity(unittest.TestCase):
    def test_same_finding_blocks_in_production_and_quarantines_on_a_demo(self):
        """The whole point of a profile: one finding, two contexts, two correct answers."""
        slow = finding(summary="first paint takes 4.2s on 3G", severity="major",
                       dimension="performance", observable="LCP 4.2s",
                       repro="$ lighthouse\nLCP 4200ms")
        self.assertEqual(adjudicate.adjudicate(profiled(PROD, slow))["verdict"], "FAIL")
        r = adjudicate.adjudicate(profiled(DEMO, slow))
        self.assertEqual(r["verdict"], "PASS")
        self.assertIn("blocks_at: never", " ".join(r["quarantined"][0]["not_blocking_because"]))

    def test_privacy_still_blocks_a_demo_because_the_profile_says_so(self):
        """The stage label is not authoritative. A demo can require production-grade privacy."""
        leak = finding(summary="patient email written to the analytics log", severity="minor",
                       dimension="privacy", observable="email appears in the log line",
                       repro="$ grep @ analytics.log\nuser=jess@example.com")
        self.assertEqual(adjudicate.adjudicate(profiled(DEMO, leak))["verdict"], "FAIL",
                         "a demo profile that sets privacy:minor must still block on privacy")

    def test_stage_label_alone_never_decides(self):
        """A demo-stage profile with strict dimensions behaves strictly; only blocks_at decides."""
        strict_demo = dict(DEMO, blocks_at=dict(DEMO["blocks_at"], performance="major"))
        slow = finding(summary="4.2s first paint", severity="major", dimension="performance",
                       observable="LCP 4.2s", repro="$ lighthouse\n4200ms")
        self.assertEqual(adjudicate.adjudicate(profiled(strict_demo, slow))["verdict"], "FAIL")

    def test_an_omitted_dimension_defaults_strict_not_permissive(self):
        """Silence in a profile must never quietly widen what ships."""
        bare = {"schema": "kernel.acceptance-profile/v1", "id": "bare", "blocks_at": {}}
        f = finding(summary="crash on empty input", dimension="correctness")
        self.assertEqual(adjudicate.adjudicate(profiled(bare, f))["verdict"], "FAIL")

    def test_an_accepted_failure_mode_quarantines_however_severe(self):
        p = dict(DEMO, acceptable_failure_modes=["loses unsaved state on refresh"])
        f = finding(summary="refresh drops the draft", dimension="correctness",
                    failure_mode="loses unsaved state on refresh")
        r = adjudicate.adjudicate(profiled(p, f))
        self.assertEqual(r["verdict"], "PASS")
        self.assertIn("accepted failure mode", " ".join(r["quarantined"][0]["not_blocking_because"]))

    def test_missing_required_evidence_is_reported_not_swallowed(self):
        p = dict(DEMO, required_evidence=["walk the demo script 3x", "contract tests green"])
        r = adjudicate.adjudicate(profiled(p, evidence=["contract tests green"]))
        self.assertEqual(r["missing_required_evidence"], ["walk the demo script 3x"])

    def test_no_profile_preserves_the_original_behaviour(self):
        """Back-compat: the evidence bar alone still decides when no context is supplied."""
        self.assertEqual(adjudicate.adjudicate(doc(finding()))["verdict"], "FAIL")


def accepted(profile, commit="abc123def456", **kw):
    rec = {
        "schema": "kernel.acceptance/v1",
        "commit": commit,
        "profile_id": profile["id"],
        "profile_hash": adjudicate.profile_hash(profile),
        "accepted_at": "2026-08-11T00:00:00Z",
        "signer": "aria",
        "cannot_falsify": ["no real device"],
        "known_non_blockers": [],
    }
    rec.update(kw)
    return rec


class Finality(unittest.TestCase):
    def _frozen_doc(self, **kw):
        d = profiled(PROD, finding(summary="auth accepts an expired token"))
        d["commit"] = "abc123def456"
        d["acceptance"] = accepted(PROD)
        d.update(kw)
        return d

    def test_an_accepted_commit_is_not_reopened_by_a_fresh_reviewer(self):
        """The core of res judicata: a new opinion is not a new fact."""
        r = adjudicate.adjudicate(self._frozen_doc())
        self.assertTrue(r["frozen"])
        self.assertEqual(r["verdict"], "PASS")
        self.assertEqual(r["counts"]["blocking"], 0)
        self.assertIn("frozen", " ".join(r["quarantined"][0]["not_blocking_because"]))

    def test_a_recognised_reopen_event_does_reopen_it(self):
        r = adjudicate.adjudicate(self._frozen_doc(
            reopen={"event": "new_failing_input", "detail": "token with nbf in the future"}))
        self.assertFalse(r["frozen"])
        self.assertEqual(r["verdict"], "FAIL")

    def test_an_unrecognised_reopen_event_is_refused(self):
        """'A different reviewer looked at it' is exactly what an amnesiac critic produces free."""
        r = adjudicate.adjudicate(self._frozen_doc(
            reopen={"event": "fresh_reviewer_disagrees", "detail": "I would do it differently"}))
        self.assertTrue(r["frozen"])
        self.assertEqual(r["verdict"], "PASS")

    def test_a_reopen_event_with_no_detail_is_refused(self):
        r = adjudicate.adjudicate(self._frozen_doc(
            reopen={"event": "new_failing_input", "detail": "   "}))
        self.assertTrue(r["frozen"])

    def test_changing_the_acceptance_profile_invalidates_the_old_acceptance(self):
        """The acceptance answered a question nobody is asking any more."""
        d = self._frozen_doc()
        d["profile"] = dict(PROD, data_sensitivity="regulated", blast_radius="irreversible")
        r = adjudicate.adjudicate(d)
        self.assertFalse(r["frozen"], "a changed profile must void the prior acceptance")
        self.assertIn("profile changed", " ".join(r["finality"]))
        self.assertEqual(r["verdict"], "FAIL")

    def test_acceptance_is_not_inherited_by_a_later_commit(self):
        """Every fix invalidates part of the evidence collected for the commit before it."""
        d = self._frozen_doc()
        d["commit"] = "999999999999"
        r = adjudicate.adjudicate(d)
        self.assertFalse(r["frozen"])
        self.assertEqual(r["verdict"], "FAIL")

    def test_a_known_non_blocker_is_named_rather_than_rediscovered(self):
        d = profiled(PROD, finding(summary="naming is inconsistent"))
        d["commit"] = "abc123def456"
        d["acceptance"] = accepted(PROD, known_non_blockers=[{"summary": "naming is inconsistent"}])
        d["reopen"] = {"event": "new_failing_input", "detail": "unrelated"}
        r = adjudicate.adjudicate(d)
        self.assertEqual(r["verdict"], "PASS")
        self.assertIn("known non-blocker", " ".join(r["quarantined"][0]["not_blocking_because"]))

    def test_profile_hash_ignores_owner_so_a_signer_change_is_not_a_reopen(self):
        self.assertEqual(adjudicate.profile_hash(PROD),
                         adjudicate.profile_hash(dict(PROD, owner="someone else")))


class PrinciplesHold(unittest.TestCase):
    """The extension must not erode what was already there."""

    def test_profile_cannot_rescue_a_finding_with_no_evidence(self):
        """Context decides whether it matters; it never decides whether it is real."""
        f = finding(summary="I think auth is broken", validated="pending", dimension="security")
        self.assertEqual(adjudicate.adjudicate(profiled(PROD, f))["verdict"], "PASS")

    def test_cannot_falsify_is_still_mandatory_under_a_profile(self):
        r = adjudicate.adjudicate(profiled(PROD, finding(), cannot_falsify=()))
        self.assertEqual(r["verdict"], "INVALID")

    def test_a_frozen_commit_still_requires_declared_blind_spots(self):
        d = profiled(PROD, finding(), cannot_falsify=())
        d["commit"] = "abc123def456"
        d["acceptance"] = accepted(PROD)
        self.assertEqual(adjudicate.adjudicate(d)["verdict"], "INVALID")

    def test_distance_still_changes_burden_not_scope(self):
        """A distance-3 finding with real evidence blocks, under a profile that cares."""
        f = finding(summary="the genre is wrong", distance=3, evidence_kind="observed_outcome",
                    dimension="correctness", observable="5/5 playtesters quit at 4 min")
        self.assertEqual(adjudicate.adjudicate(profiled(PROD, f))["verdict"], "FAIL")



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
