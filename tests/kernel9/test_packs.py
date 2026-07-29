#!/usr/bin/env python3
"""Domain pack tests for KERNEL 9.

Covers required test case 17 (non-code work never receives irrelevant code,
testing, or git instructions) and the structural guarantees that make packs
worth having: every routable domain resolves to a real pack, and packs do not
re-state the universal core.
"""

import os
import re
import sys
import unittest

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "orchestration", "router"))

import kernel_router as R  # noqa: E402

PACKS_DIR = os.path.join(REPO, "packs")
CORE_TMPL = os.path.join(REPO, "governance", "kernel9.md.tmpl")

CODE_DOMAINS = {"software"}
NON_CODE_DOMAINS = {"research", "writing", "design", "strategy"}
# operations is deliberately neither: it runs commands but is not code authoring,
# and it legitimately discusses deployment.


def pack_path(domain):
    return os.path.join(PACKS_DIR, domain, "PACK.md")


def read_pack(domain):
    with open(pack_path(domain)) as fh:
        return fh.read()


class PackResolution(unittest.TestCase):
    def test_every_routable_domain_has_a_pack(self):
        """The core instructs the model to load packs/<domain>/PACK.md.

        A domain the router can emit but that has no pack file is a dangling
        instruction: the model is told to read something that is not there.
        """
        for domain in R.DOMAIN_SIGNALS:
            with self.subTest(domain=domain):
                self.assertTrue(
                    os.path.isfile(pack_path(domain)),
                    f"router can emit domain={domain} but packs/{domain}/PACK.md is missing",
                )

    def test_every_pack_mapping_resolves(self):
        for domain, packs in R.PACK_BY_DOMAIN.items():
            for pack in packs:
                with self.subTest(domain=domain, pack=pack):
                    self.assertTrue(
                        os.path.isfile(pack_path(pack)),
                        f"PACK_BY_DOMAIN[{domain}] references missing pack {pack}",
                    )

    def test_no_orphan_packs(self):
        """Every pack on disk must be reachable by the router."""
        on_disk = {
            d for d in os.listdir(PACKS_DIR)
            if os.path.isfile(os.path.join(PACKS_DIR, d, "PACK.md"))
        }
        reachable = set(R.DOMAIN_SIGNALS) | {
            p for packs in R.PACK_BY_DOMAIN.values() for p in packs
        }
        self.assertEqual(on_disk - reachable, set(), "unreachable pack(s) on disk")

    def test_pack_frontmatter_is_well_formed(self):
        for domain in R.DOMAIN_SIGNALS:
            with self.subTest(domain=domain):
                text = read_pack(domain)
                self.assertTrue(text.startswith("---\n"), f"{domain}: missing frontmatter")
                block = text.split("---", 2)[1]
                self.assertRegex(block, rf"name:\s*{domain}\b")
                self.assertRegex(block, r"kind:\s*domain-pack")
                self.assertRegex(block, r"description:\s*\S")


class NonCodeDomainsAreClean(unittest.TestCase):
    """Requirement 17: no irrelevant code/testing/git instructions."""

    # Executable ceremony: an actual command a model would be told to run.
    # Mentioning the word "test" in a sentence explaining that tests do NOT
    # apply is fine; being told to run one is not.
    COMMAND_CEREMONY = [
        r"\bnpm (run |test|install)",
        r"\bpytest\b",
        r"\bmake test\b",
        r"\bgit (commit|push|checkout|branch|rebase)\b",
        r"\byarn (test|build)\b",
        r"\bcargo (test|build)\b",
        r"\bgo test\b",
        r"\bpackage\.json\b",
        r"\bMakefile\b",
    ]

    def test_no_executable_code_ceremony_in_non_code_packs(self):
        for domain in NON_CODE_DOMAINS:
            text = read_pack(domain)
            for pattern in self.COMMAND_CEREMONY:
                with self.subTest(domain=domain, pattern=pattern):
                    self.assertIsNone(
                        re.search(pattern, text, re.IGNORECASE),
                        f"{domain} pack contains code ceremony: {pattern}",
                    )

    def test_non_code_packs_state_their_exclusion(self):
        """Silence is not enough; the pack must say the ceremony does not apply.

        A model that has seen software instructions in a prior turn will
        otherwise carry them over. The exclusion has to be explicit.
        """
        for domain in NON_CODE_DOMAINS:
            with self.subTest(domain=domain):
                text = read_pack(domain).lower()
                self.assertTrue(
                    "do not apply" in text or "does not apply" in text
                    or "no code" in text,
                    f"{domain} pack never states that code ceremony is out of scope",
                )

    def test_software_pack_does_carry_code_guidance(self):
        """Control: the exclusion test above must be capable of failing."""
        text = read_pack("software")
        self.assertRegex(text, r"package\.json|Makefile|justfile")

    def test_non_code_verification_is_domain_appropriate(self):
        for domain in NON_CODE_DOMAINS:
            with self.subTest(domain=domain):
                text = read_pack(domain)
                section = text.split("## Verification", 1)
                self.assertEqual(len(section), 2, f"{domain}: no Verification section")
                body = section[1].split("##", 1)[0].lower()
                for banned in ("run the test", "test suite", "compile", "pull request"):
                    self.assertNotIn(
                        banned, body, f"{domain} verification prescribes {banned!r}"
                    )


class PacksDoNotDuplicateTheCore(unittest.TestCase):
    """The brief forbids duplicating universal rules across packs."""

    def setUp(self):
        with open(CORE_TMPL) as fh:
            self.core = fh.read()

    CORE_ONLY_RULES = [
        "No AI attribution",
        "--no-verify",
        "No worktrees",
        "One writer per",
        "agentdb recall",
        "agentdb learn",
    ]

    def test_core_owns_the_universal_rules(self):
        for rule in self.CORE_ONLY_RULES:
            with self.subTest(rule=rule):
                self.assertIn(rule, self.core, f"core template lost the rule {rule!r}")

    def test_packs_do_not_restate_universal_rules(self):
        for domain in R.DOMAIN_SIGNALS:
            text = read_pack(domain)
            for rule in self.CORE_ONLY_RULES:
                with self.subTest(domain=domain, rule=rule):
                    self.assertNotIn(
                        rule, text, f"{domain} pack duplicates the universal rule {rule!r}"
                    )


class PackStructure(unittest.TestCase):
    REQUIRED_SECTIONS = [
        "## Evidence that matters",
        "## Execution patterns",
        "## Verification",
        "## Hazards",
        "## Optional skills",
    ]

    def test_every_pack_defines_the_required_sections(self):
        """The brief names exactly what a pack must define."""
        for domain in R.DOMAIN_SIGNALS:
            text = read_pack(domain)
            for section in self.REQUIRED_SECTIONS:
                with self.subTest(domain=domain, section=section):
                    self.assertIn(section, text, f"{domain} pack missing {section}")

    def test_every_pack_covers_all_three_work_shapes(self):
        for domain in R.DOMAIN_SIGNALS:
            text = read_pack(domain)
            for shape in R.SHAPE_ORDER:
                with self.subTest(domain=domain, shape=shape):
                    self.assertRegex(
                        text,
                        rf"\*\*{shape}\*\*",
                        f"{domain} pack does not say what {shape} means here",
                    )

    def test_packs_stay_small(self):
        """Packs load on demand but still cost tokens. Keep them lean."""
        for domain in R.DOMAIN_SIGNALS:
            with self.subTest(domain=domain):
                size = os.path.getsize(pack_path(domain))
                self.assertLess(
                    size, 4096, f"{domain} pack is {size} B; packs should stay under 4 KB"
                )


if __name__ == "__main__":
    unittest.main(verbosity=2)
