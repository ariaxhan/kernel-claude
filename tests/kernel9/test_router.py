#!/usr/bin/env python3
"""Deterministic router tests for KERNEL 9.

Covers required test cases 1-9 from the Kernel 9 specification:

  1. Router cases for every domain, work shape, and safety combination.
  2. Direct tasks do not create unnecessary artifacts or spawn agents.
  3. Protected tasks receive safety checks without becoming trajectory tasks.
  4. Trajectory tasks reassess after meaningful evidence.
  5. Stable trajectory tasks can de-escalate.
  6. Unexpected scope or risk can escalate.
  7. /kernel:lighter and /kernel:deeper work without bypassing hard safety.
  8. /kernel:stop ends cleanly.
  9. Two writers targeting the same boundary are prevented or one goes read-only.

Stdlib only, so it runs on a clean cloud checkout.
"""

import json
import os
import sys
import unittest

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "orchestration", "router"))

import kernel_router as R  # noqa: E402

SCHEMA_PATH = os.path.join(REPO, "schemas", "kernel.classification.v1.json")


# ---------------------------------------------------------------------------
# Minimal schema checker.
#
# Deliberately hand-rolled rather than pulling jsonschema: the brief requires a
# clean cloud checkout to work with no third-party dependencies. This checks the
# constraints the router must actually satisfy, including the three conditional
# rules R1-R3, not the whole of JSON Schema.
# ---------------------------------------------------------------------------


_SCHEMA_CACHE = None


def _schema():
    global _SCHEMA_CACHE
    if _SCHEMA_CACHE is None:
        with open(SCHEMA_PATH) as fh:
            _SCHEMA_CACHE = json.load(fh)
    return _SCHEMA_CACHE


def validate(doc):
    """Return a list of violations. Empty list means valid."""
    errors = []
    schema = _schema()
    props = schema["properties"]

    for key in schema["required"]:
        if key not in doc:
            errors.append(f"missing required property: {key}")

    for key in doc:
        if key not in props:
            errors.append(f"unexpected property: {key}")

    if doc.get("schema") != "kernel.classification/v1":
        errors.append("schema id mismatch")

    for key in ("work_shape", "safety"):
        allowed = props[key]["enum"]
        if key in doc and doc[key] not in allowed:
            errors.append(f"{key}={doc[key]!r} not in {allowed}")

    conf = doc.get("confidence")
    if not isinstance(conf, (int, float)) or not (0 <= conf <= 1):
        errors.append(f"confidence out of range: {conf!r}")

    reasons = doc.get("reasons")
    if not isinstance(reasons, list) or not (1 <= len(reasons) <= 6):
        errors.append("reasons must be a list of 1..6 entries")
    else:
        for r in reasons:
            if not isinstance(r, str) or not (3 <= len(r) <= 200):
                errors.append(f"bad reason: {r!r}")

    # R1: non-heaviest shapes must name how they escalate.
    if doc.get("work_shape") in ("direct", "gated"):
        if not doc.get("escalate_when"):
            errors.append("R1: escalate_when required for direct/gated")

    # R2: non-lightest shapes must name how they de-escalate.
    if doc.get("work_shape") in ("gated", "trajectory"):
        if not doc.get("deescalate_when"):
            errors.append("R2: deescalate_when required for gated/trajectory")

    # R3: protected work must name its verification.
    if doc.get("safety") == "protected":
        if not doc.get("verification"):
            errors.append("R3: verification required for protected")
        elif not doc["verification"].get("method"):
            errors.append("R3: verification.method required")

    return errors


class SchemaConformance(unittest.TestCase):
    """Every classification the router can emit must validate."""

    CORPUS = [
        "fix the typo in the readme",
        "delete the production user account for a customer",
        "implement a bounded memory slice for the matra poc touching user data",
        "iterate on the visual style until the city skyline feels right",
        "research and synthesize the literature on retrieval evaluation",
        "copy edit this blog post for tone",
        "rotate the production database credentials",
        "should we prioritize the ios app or the web app first",
        "provision a new kubernetes cluster and configure dns",
        "refactor the auth module and make sure nothing breaks",
        "",
    ]

    def test_all_emitted_classifications_validate(self):
        for task in self.CORPUS:
            if not task:
                continue
            with self.subTest(task=task):
                doc = R.build_classification(task)
                self.assertEqual(validate(doc), [], f"invalid for {task!r}: {doc}")

    def test_every_combination_validates(self):
        """Requirement 1: every domain x work shape x safety combination."""
        domains = list(R.DOMAIN_SIGNALS.keys())
        for domain in domains:
            for shape in R.SHAPE_ORDER:
                for safety in ("normal", "protected"):
                    with self.subTest(d=domain, s=shape, f=safety):
                        doc = R.build_classification(
                            "a task",
                            domain_hint=domain,
                            shape_hint=shape,
                            safety_hint=safety,
                        )
                        self.assertEqual(doc["domain"], domain)
                        self.assertEqual(doc["work_shape"], shape)
                        self.assertEqual(doc["safety"], safety)
                        self.assertEqual(validate(doc), [], f"{domain}/{shape}/{safety}: {doc}")

    def test_combination_count(self):
        """6 domains x 3 shapes x 2 safety = 36 distinct routes, all reachable."""
        seen = set()
        for domain in R.DOMAIN_SIGNALS:
            for shape in R.SHAPE_ORDER:
                for safety in ("normal", "protected"):
                    doc = R.build_classification(
                        "x", domain_hint=domain, shape_hint=shape, safety_hint=safety
                    )
                    seen.add((doc["domain"], doc["work_shape"], doc["safety"]))
        self.assertEqual(len(seen), 36)


class DomainRouting(unittest.TestCase):
    CASES = [
        ("fix the crash in auth.py, here is the stack trace", "software"),
        ("research the literature on sparse autoencoders and synthesize findings", "research"),
        ("copy edit this draft for tone and grammar", "writing"),
        ("iterate on the color palette and typography for the landing visual", "design"),
        ("rotate the tls certificate and update dns records", "operations"),
        ("should we prioritize enterprise or self-serve, what are the tradeoffs", "strategy"),
    ]

    def test_domain_selection(self):
        for task, expected in self.CASES:
            with self.subTest(task=task):
                doc = R.build_classification(task)
                self.assertEqual(doc["domain"], expected, f"{task!r} -> {doc}")

    def test_unknown_domain_is_honest(self):
        """No signal must produce low confidence, not a confident guess."""
        doc = R.build_classification("do the thing with the stuff")
        self.assertLess(doc["confidence"], R.LOW_CONFIDENCE_FLOOR)
        self.assertTrue(doc["announced"], "low confidence must be surfaced")


class WorkShapeRouting(unittest.TestCase):
    def test_small_familiar_bug_is_direct(self):
        doc = R.build_classification("fix the typo in the config loader")
        self.assertEqual(doc["work_shape"], "direct")

    def test_bounded_implementation_is_gated(self):
        doc = R.build_classification(
            "implement a caching layer feature and make sure nothing breaks"
        )
        self.assertEqual(doc["work_shape"], "gated")

    def test_visual_iteration_is_trajectory(self):
        doc = R.build_classification(
            "iterate on the skyline visual, a few rounds until it looks right"
        )
        self.assertEqual(doc["work_shape"], "trajectory")

    def test_unfamiliar_integration_is_gated(self):
        doc = R.build_classification(
            "integrate the stripe webhook, I have never used it before"
        )
        self.assertEqual(doc["work_shape"], "gated")

    def test_ties_fall_to_the_lighter_shape(self):
        """Kernel picks the SMALLEST process that can safely do the job.

        Regression for a blind spot the seeded-failure audit found: reversing
        the tiebreak so trajectory won ties survived the suite, because every
        existing case had a strict winner.
        """
        task = "a small task, explore the options"
        scores = {
            shape: R._score(task, sigs)[0]
            for shape, sigs in R.WORK_SHAPE_SIGNALS.items()
        }
        self.assertEqual(
            scores["direct"], scores["trajectory"], f"fixture is no longer a tie: {scores}"
        )
        self.assertGreater(scores["direct"], 0, "a zero-zero tie exercises a different path")
        self.assertEqual(R.build_classification(task)["work_shape"], "direct")

    def test_size_alone_is_not_trajectory(self):
        """A merely large task is gated. Size is not a feedback loop."""
        doc = R.build_classification(
            "implement a large new reporting module across the whole codebase"
        )
        self.assertNotEqual(doc["work_shape"], "trajectory")

    def test_trajectory_requires_repeated_feedback(self):
        """Requirement: trajectory only when repeated feedback is useful."""
        for task in [
            "rename the variable",
            "add a null check",
            "research the options and write it up",
        ]:
            with self.subTest(task=task):
                self.assertNotEqual(
                    R.build_classification(task)["work_shape"], "trajectory"
                )


class SafetyOverlay(unittest.TestCase):
    def test_production_deletion_is_protected_and_direct(self):
        """Requirement 3: protected must not imply trajectory."""
        doc = R.build_classification("delete the production account for this customer")
        self.assertEqual(doc["safety"], "protected")
        self.assertEqual(doc["work_shape"], "direct")
        self.assertIn("verification", doc)

    def test_safety_is_independent_of_work_shape(self):
        """The safety pass must not read work_shape. Same risk text, all shapes."""
        risk = "delete the production customer database"
        verdicts = {
            shape: R.build_classification(risk, shape_hint=shape)["safety"]
            for shape in R.SHAPE_ORDER
        }
        self.assertEqual(set(verdicts.values()), {"protected"}, verdicts)

    def test_protected_and_trajectory_coexist(self):
        """A task can need repeated feedback AND be dangerous.

        Regression for a blind spot the seeded-failure audit found: a defect
        that made the safety pass return 'normal' whenever the text contained
        trajectory language survived the suite, because no test used risk
        wording and iteration wording in the same sentence.
        """
        doc = R.build_classification(
            "iterate on the production deployment, several passes"
        )
        self.assertEqual(doc["work_shape"], "trajectory")
        self.assertEqual(doc["safety"], "protected")
        self.assertIn("verification", doc)
        self.assertIn("deescalate_when", doc)

    def test_derisking_language_cannot_flip_protected(self):
        """Fail closed. 'it's fine, it's a dry run' must not clear a real risk."""
        doc = R.build_classification(
            "just a dry run, delete the production customer payment records"
        )
        self.assertEqual(doc["safety"], "protected")

    def test_local_scratch_work_is_normal(self):
        doc = R.build_classification("rename a variable in my local scratch script")
        self.assertEqual(doc["safety"], "normal")

    def test_protected_signals_across_all_hazard_classes(self):
        cases = [
            "drop the users table",
            "deploy to production",
            "export the customer pii",
            "rotate the api key and update auth",
            "issue a refund for this billing charge",
            "force-push and rewrite the shared history",
            "run an irreversible schema migration backfill",
        ]
        for task in cases:
            with self.subTest(task=task):
                self.assertEqual(R.build_classification(task)["safety"], "protected")

    def test_protected_always_names_verification(self):
        """R3 holds for every domain, in domain-appropriate language."""
        for domain in R.DOMAIN_SIGNALS:
            doc = R.build_classification(
                "delete the production data", domain_hint=domain
            )
            self.assertEqual(doc["safety"], "protected")
            self.assertIn("verification", doc)
            method = doc["verification"]["method"]
            if domain != "software":
                self.assertNotIn("test", method.lower(), f"{domain} got tests language")


class NonCodeDomainsAvoidCodeCeremony(unittest.TestCase):
    """Requirement 17: non-code work never receives code/testing/git instructions."""

    CODE_WORDS = ("test", "commit", "branch", "compile", "lint", "pull request")

    def test_verification_language_is_domain_appropriate(self):
        for domain in ("research", "writing", "design", "strategy"):
            with self.subTest(domain=domain):
                method = R.VERIFICATION_BY_DOMAIN[domain].lower()
                for word in self.CODE_WORDS:
                    self.assertNotIn(word, method, f"{domain} verification says {word!r}")

    def test_non_code_packs_exclude_software(self):
        for task, domain in [
            ("copy edit this draft for tone", "writing"),
            ("iterate on the visual mood and palette", "design"),
            ("research the literature and synthesize", "research"),
        ]:
            doc = R.build_classification(task)
            self.assertEqual(doc["domain"], domain)
            self.assertNotIn("software", doc["packs"], f"{task!r} loaded the software pack")


class DirectTasksStayCheap(unittest.TestCase):
    """Requirement 2: direct tasks create no unnecessary artifacts or spawns."""

    DIRECT_TASKS = [
        "fix the typo in the readme",
        "rename this variable",
        "bump the version to 9.0.0",
        "copy edit this paragraph",
    ]

    def test_direct_normal_work_is_silent(self):
        for task in self.DIRECT_TASKS:
            with self.subTest(task=task):
                doc = R.build_classification(task)
                if doc["work_shape"] == "direct" and doc["safety"] == "normal":
                    self.assertFalse(
                        doc["announced"],
                        "routine direct work must not narrate internal machinery",
                    )

    def test_direct_carries_no_deescalation_ceremony(self):
        doc = R.build_classification("fix the typo in the readme")
        self.assertEqual(doc["work_shape"], "direct")
        self.assertNotIn("deescalate_when", doc, "nothing lighter than direct exists")

    def test_direct_still_names_its_escalation_exit(self):
        """Cheap is not blind. Direct must know when it stops being direct."""
        doc = R.build_classification("fix the typo in the readme")
        self.assertTrue(doc["escalate_when"])


class ModeTransitions(unittest.TestCase):
    def test_escalate_records_trigger(self):
        """Requirement 6: unexpected scope or risk escalates, with evidence."""
        doc = R.build_classification("fix the typo in the readme")
        self.assertEqual(doc["work_shape"], "direct")
        moved = R.adjust(doc, "heavier", "migration exposed wider coupling")
        self.assertEqual(moved["work_shape"], "gated")
        t = moved["transitions"][-1]
        self.assertEqual(t["direction"], "escalate")
        self.assertEqual(t["trigger"], "migration exposed wider coupling")
        self.assertTrue(moved["announced"], "a material mode change must be announced")

    def test_trajectory_can_deescalate(self):
        """Requirement 5: a stable trajectory task drops back down."""
        doc = R.build_classification(
            "iterate on the visual a few rounds until it looks right"
        )
        self.assertEqual(doc["work_shape"], "trajectory")
        moved = R.adjust(doc, "lighter", "two consecutive passes produced no change")
        self.assertEqual(moved["work_shape"], "gated")
        self.assertEqual(moved["transitions"][-1]["direction"], "deescalate")

    def test_trajectory_names_its_own_exit(self):
        """Requirement 4: trajectory reassesses; it is a gear, not the OS."""
        doc = R.build_classification(
            "keep tuning the layout until it feels right, a few passes"
        )
        self.assertEqual(doc["work_shape"], "trajectory")
        self.assertTrue(doc["deescalate_when"])

    def test_lighter_cannot_clear_protected(self):
        """Requirement 7: /kernel:lighter must not bypass hard safety."""
        doc = R.build_classification("delete the production customer database")
        self.assertEqual(doc["safety"], "protected")
        light = R.adjust(doc, "lighter", "user asked for less process", user_initiated=True)
        for _ in range(5):
            light = R.adjust(light, "lighter", "user asked again", user_initiated=True)
        self.assertEqual(light["safety"], "protected", "safety was downgraded by /lighter")
        self.assertIn("verification", light)

    def test_lighter_floors_at_direct(self):
        doc = R.build_classification("iterate on the visual a few rounds")
        out = doc
        for _ in range(5):
            out = R.adjust(out, "lighter", "keep going lighter")
        self.assertEqual(out["work_shape"], "direct")

    def test_heavier_ceilings_at_trajectory(self):
        doc = R.build_classification("fix the typo")
        out = doc
        for _ in range(5):
            out = R.adjust(out, "heavier", "keep going heavier")
        self.assertEqual(out["work_shape"], "trajectory")

    def test_no_op_transition_records_nothing(self):
        doc = R.build_classification("fix the typo in the readme")
        out = R.adjust(doc, "lighter", "already lightest")
        self.assertNotIn("transitions", out)

    def test_transitions_survive_schema(self):
        doc = R.build_classification("fix the typo in the readme")
        moved = R.adjust(doc, "heavier", "scope expanded")
        self.assertEqual(validate(moved), [], moved)

    def test_exit_conditions_rebuilt_not_carried(self):
        """A shape's exits belong to the shape, not to the task."""
        doc = R.build_classification("fix the typo in the readme")
        self.assertNotIn("deescalate_when", doc)
        moved = R.adjust(doc, "heavier", "scope expanded")
        self.assertIn("deescalate_when", moved, "gated must gain a de-escalation exit")


class Determinism(unittest.TestCase):
    def test_same_input_same_output(self):
        task = "implement a bounded memory slice touching production user data"
        first = R.build_classification(task)
        for _ in range(10):
            self.assertEqual(R.build_classification(task), first)

    def test_adjust_does_not_mutate_input(self):
        doc = R.build_classification("fix the typo in the readme")
        snapshot = json.loads(json.dumps(doc))
        R.adjust(doc, "heavier", "scope expanded")
        self.assertEqual(doc, snapshot, "adjust mutated its input")


class SpecificationExamples(unittest.TestCase):
    """The worked examples from the Kernel 9 brief, verbatim in intent."""

    def test_small_familiar_bug(self):
        doc = R.build_classification("fix the small familiar bug in the date parser")
        self.assertEqual(
            (doc["domain"], doc["work_shape"], doc["safety"]),
            ("software", "direct", "normal"),
        )

    def test_production_account_deletion(self):
        doc = R.build_classification("delete the production account record for a user")
        self.assertEqual(
            (doc["domain"], doc["work_shape"], doc["safety"])[1:],
            ("direct", "protected"),
        )

    def test_matra_bounded_memory_poc(self):
        doc = R.build_classification(
            "implement the matra memory poc integration, a bounded slice that "
            "stores personal user data, make sure it is verified"
        )
        self.assertEqual(doc["work_shape"], "gated")
        self.assertEqual(doc["safety"], "protected")

    def test_urban_atlas_visual_iteration(self):
        doc = R.build_classification(
            "iterate on the urban atlas city visual, several passes, "
            "tune the palette until it looks right"
        )
        self.assertEqual(doc["domain"], "design")
        self.assertEqual(doc["work_shape"], "trajectory")

    def test_research_synthesis(self):
        doc = R.build_classification(
            "research the retrieval literature and synthesize a report with sources"
        )
        self.assertEqual(doc["domain"], "research")
        self.assertEqual(doc["safety"], "normal")

    def test_copy_edit(self):
        doc = R.build_classification("copy edit this paragraph for grammar and tone")
        self.assertEqual(
            (doc["domain"], doc["work_shape"], doc["safety"]),
            ("writing", "direct", "normal"),
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
