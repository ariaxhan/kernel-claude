"""Regression tests for live-run continuation routing."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "orchestration" / "router"))
from kernel_router import build_classification, classify_request


class ContinuationRoutingTests(unittest.TestCase):
    def test_bare_continuation_retains_writing_and_research_routes(self):
        for task, domain in (
            ("Write an essay about public transit", "writing"),
            ("Research peer-reviewed studies and primary sources", "research"),
        ):
            with self.subTest(domain=domain):
                previous = classify_request(task)
                self.assertEqual(previous["domain"], domain)
                resumed = classify_request("  Continue! ", previous=previous)
                for field in ("domain", "packs", "work_shape", "safety"):
                    self.assertEqual(resumed[field], previous[field])
                self.assertGreater(resumed["confidence"], 0.30)

    def test_protected_continuation_preserves_full_records(self):
        previous = self.protected_writing()
        resumed = classify_request("keep going", previous=previous)
        for field in ("domain", "packs", "work_shape", "safety", "verification", "ownership"):
            self.assertEqual(resumed[field], previous[field])
        resumed["verification"]["seeded_failure_verified"] = False
        resumed["ownership"]["holder"] = "someone else"
        self.assertTrue(previous["verification"]["seeded_failure_verified"])
        self.assertEqual(previous["ownership"]["holder"], "editor")

    def test_older_protected_route_without_records_gets_domain_default(self):
        previous = self.protected_writing()
        del previous["verification"], previous["ownership"]
        resumed = classify_request("resume", previous=previous)
        self.assertEqual(resumed["verification"], self.protected_writing_default())
        self.assertNotIn("ownership", resumed)

    def test_substantive_request_reclassifies_even_with_continuation_prefix(self):
        previous = self.protected_writing()
        for task, safety in (
            ("Continue by deploying the production database migration", "protected"),
            ("New task: research peer-reviewed studies and primary sources", "normal"),
        ):
            with self.subTest(task=task):
                fresh = classify_request(task)
                self.assertNotEqual(fresh["domain"], previous["domain"])
                self.assertEqual(fresh["safety"], safety)
                revised = classify_request(task, previous=previous)
                for field in ("domain", "packs", "safety", "verification", "ownership"):
                    self.assertEqual(revised.get(field), fresh.get(field))
                self.assertNotIn("ownership", revised)

    def test_substantive_revision_keeps_active_safety_boundary(self):
        previous = self.protected_writing()
        revised = classify_request("Revise the essay introduction", previous=previous)
        self.assertEqual(revised["safety"], "protected")
        self.assertEqual(revised["verification"], previous["verification"])
        self.assertNotIn("ownership", revised)

    @staticmethod
    def protected_writing():
        previous = build_classification(
            "Write an essay about public transit",
            safety_hint="protected",
            boundary="essay.md",
            role="reader",
            holder="editor",
        )
        previous["verification"].update(instrument="editor checklist", seeded_failure_verified=True)
        return previous

    @staticmethod
    def protected_writing_default():
        return build_classification("", domain_hint="writing", safety_hint="protected")["verification"]


if __name__ == "__main__":
    unittest.main()
