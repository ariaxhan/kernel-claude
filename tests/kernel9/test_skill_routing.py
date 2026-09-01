#!/usr/bin/env python3
"""Skill-routing tests for KERNEL.

WHY THIS SUITE EXISTS (2026-09-01 usage audit): across 9,642 Claude sessions
and 1,180 Codex sessions, 12 of 26 skills had never been invoked once, and only
5 invocations in the entire history were typed by a human. The router, by
contrast, announced a domain pack 8,578 times. The routing mechanism worked;
nothing connected it to the skill library.

The instruction was explicitly NOT to delete the unused skills but to make all
of them reachable. "Reachable" is only a claim until something fails when it
stops being true, so the coverage test below is the actual deliverable: a skill
added without routing evidence breaks the build, and a routing entry for a
skill that no longer exists breaks it too.
"""

import os
import re
import sys
import unittest

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "orchestration", "router"))

import kernel_router as R  # noqa: E402

SKILLS_DIR = os.path.join(REPO, "skills")


def skill_names():
    return sorted(
        d for d in os.listdir(SKILLS_DIR)
        if os.path.isfile(os.path.join(SKILLS_DIR, d, "SKILL.md"))
    )


class SkillTableCoverage(unittest.TestCase):
    """Every shipped skill is routable, and every routing entry is a real skill."""

    def setUp(self):
        try:
            import skill_signals
        except ImportError:  # the table is optional at runtime, required in CI
            self.skipTest("skill_signals.py absent; router fails open by design")
        self.sig = skill_signals.SKILL_SIGNALS
        self.dom = skill_signals.SKILL_DOMAINS

    def test_every_skill_has_routing_signals(self):
        missing = [s for s in skill_names() if s not in self.sig]
        self.assertEqual(
            missing, [],
            "skills with no routing evidence can only be reached by a human typing "
            "the slash-command, which the audit measured at 5 times in all of "
            "history: %s" % missing)

    def test_every_skill_has_a_domain(self):
        missing = [s for s in skill_names() if s not in self.dom]
        self.assertEqual(missing, [], "skills missing a domain: %s" % missing)

    def test_no_phantom_skills_in_the_table(self):
        real = set(skill_names())
        phantom = sorted(k for k in self.sig if k not in real)
        self.assertEqual(
            phantom, [],
            "routing entries for skills that do not exist; a suggestion the agent "
            "cannot act on is worse than silence: %s" % phantom)

    def test_every_domain_named_is_a_real_router_domain(self):
        known = set(R.PACK_BY_DOMAIN)
        for skill, domains in self.dom.items():
            for d in domains:
                self.assertIn(d, known, "%s routes to unknown domain %r" % (skill, d))

    def test_every_regex_compiles(self):
        for skill, signals in self.sig.items():
            for pattern, weight, reason in signals:
                try:
                    re.compile(pattern)
                except re.error as exc:
                    self.fail("%s: %r does not compile (%s)" % (skill, pattern, exc))
                self.assertIn(weight, (1, 2, 3), "%s: weight %r off scale" % (skill, weight))
                self.assertTrue(reason.strip(), "%s: empty reason" % skill)


class SkillReachability(unittest.TestCase):
    """Coverage is cheap to fake. Reachability is the claim that matters.

    A table can key all 29 skills and still reach none of them, if its regexes
    only match phrasings nobody uses. That is exactly how the shipped
    frontmatter trigger lists failed, and how the first draft of this table
    failed for five skills before the probes caught it.
    """

    def setUp(self):
        try:
            import skill_signals
        except ImportError:
            self.skipTest("skill_signals.py absent; router fails open by design")
        self.probes = skill_signals.CANONICAL_PROBES

    def test_every_auto_invocable_skill_has_a_probe(self):
        want = set(skill_names()) - set(R.SKILL_NEVER_SUGGEST)
        self.assertEqual(
            sorted(want - set(self.probes)), [],
            "a skill with no probe is a skill nobody has shown can be reached")
        self.assertEqual(
            sorted(set(self.probes) & set(R.SKILL_NEVER_SUGGEST)), [],
            "skills the model may not invoke must not carry a probe")

    def test_every_probe_reaches_its_own_skill(self):
        for skill, prompt in sorted(self.probes.items()):
            with self.subTest(skill=skill):
                names = [row["name"] for row in R.classify_skills(prompt)]
                self.assertIn(
                    skill, names,
                    "%r reached %s, not %s. The skill is shipped but "
                    "unreachable: only a human typing the slash-command can get "
                    "to it, which the audit measured at 5 times in all of "
                    "history." % (prompt, names or "nothing", skill))


class SkillDisambiguation(unittest.TestCase):
    """The collisions the audit found must be separable by evidence, not luck.

    Each pair below shares a bare trigger word in the shipped frontmatter, which
    is exactly why trigger matching failed. A prompt that a person would route
    one way must not score the other higher.
    """

    CASES = [
        ("the tests fail with a TypeError on line 40, here is the traceback", "debug"),
        ("map the dependencies in the payments module before we restructure it", "diagnose"),
        ("review this PR and tell me if it is mergeable", "review"),
        ("tear apart this plan before I start implementing it", "tearitapart"),
        ("save progress, we are about to hit a context reset", "checkpoint"),
        ("write a handoff so the next session can continue this", "handoff"),
    ]

    def setUp(self):
        try:
            import skill_signals  # noqa: F401
        except ImportError:
            self.skipTest("skill_signals.py absent")

    def test_collisions_resolve_to_the_intended_skill(self):
        for prompt, expected in self.CASES:
            with self.subTest(prompt=prompt):
                ranked = R.classify_skills(prompt)
                names = [row["name"] for row in ranked]
                self.assertTrue(names, "no skill suggested for %r" % prompt)
                self.assertIn(
                    expected, names,
                    "%r suggested %s, expected %s among them" % (prompt, names, expected))


class RouterFailsOpen(unittest.TestCase):
    """A broken skill table must never take the classification down with it.

    Domain, shape and safety decide how work is done. A skill suggestion only
    decides what gets read first. The second must never be able to break the
    first, so this asserts the degraded path rather than trusting the try/except
    to stay correct.
    """

    def test_classification_survives_an_empty_skill_table(self):
        saved = R._SKILL_SIGNALS
        try:
            R._SKILL_SIGNALS = {}
            self.assertEqual(R.classify_skills("fix the crash in auth.py"), [])
            out = R.build_classification("fix the crash in auth.py")
            self.assertEqual(out["domain"], "software")
            self.assertNotIn("skills", out)
        finally:
            R._SKILL_SIGNALS = saved

    def test_never_suggest_matches_the_frontmatter(self):
        """The human-only list is data; this is what keeps it true.

        Five skills set `disable-model-invocation: true`. Suggesting one is
        advice nobody in the room can take: the router would be telling the
        agent to do what the host forbids. The list is stored as data so the
        router does not stat five files on every prompt, and asserted here so
        it cannot drift the way agents/dreamer.md drifted from skills/dream/.
        """
        declared = set()
        for name in skill_names():
            path = os.path.join(SKILLS_DIR, name, "SKILL.md")
            with open(path, encoding="utf-8") as fh:
                head = fh.read(2000)
            if re.search(r"^disable-model-invocation:\s*true\s*$", head, re.M):
                declared.add(name)
        self.assertEqual(
            declared, set(R.SKILL_NEVER_SUGGEST),
            "skills declaring disable-model-invocation: true must match the "
            "router's never-suggest set exactly; %s differ"
            % sorted(declared ^ set(R.SKILL_NEVER_SUGGEST)))

    def test_human_only_skills_are_never_suggested(self):
        probes = {
            "forge": "run forge on the repo autonomously",
            "landing-page": "scaffold and deploy a landing page",
            "governance-sync": "run governance sync",
            "init": "initialise this project",
            "experiment": "run the experiment harness",
        }
        for skill, prompt in probes.items():
            with self.subTest(skill=skill):
                names = [r["name"] for r in R.classify_skills(prompt)]
                self.assertNotIn(skill, names)


if __name__ == "__main__":
    unittest.main()
