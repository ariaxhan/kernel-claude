"""Gate the ambient context cost so it can only ratchet down.

The measurement this guards was previously wrong in a way that mattered. It charged
this repo's CLAUDE.md (~5.8k tok) as ambient for everyone, when plugin users never
load it: Claude Code loads the *user's* instruction file, and .claude-plugin/plugin.json
does not reference ours. That inflated the baseline roughly 4x and made "reduce ambient
context" look like it required deleting safety invariants from CLAUDE.md, which would
have saved plugin users exactly zero tokens.

So these budgets are ratchets, not aspirations. They sit just above the measured
present value. Lowering them is a deliberate act; exceeding them fails the build.

On the sub-500-token target in the Kernel 9 brief: it is not reachable and should not
be restated. Plugin ambient is dominated by skill frontmatter, which the host must keep
visible for routing to be possible at all: ~2.7k tok spread evenly across 26 skills at a
~105 tok mean, with no dominant offender to trim. Reaching 500 would mean shipping about
four skills. The template was never the binding constraint.
"""

from __future__ import annotations

import unittest

import measure_ambient


# Ratchets. Measured 2026-08-05: plugin 4596, contributor 10380.
PLUGIN_AMBIENT_BUDGET = 4800
CONTRIBUTOR_AMBIENT_BUDGET = 11000


class AmbientBudgetTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.m = measure_ambient.measure()

    def test_plugin_ambient_within_budget(self):
        actual = self.m["plugin_ambient_tokens"]
        self.assertLessEqual(
            actual,
            PLUGIN_AMBIENT_BUDGET,
            f"plugin ambient {actual} tok exceeds the {PLUGIN_AMBIENT_BUDGET} tok ratchet. "
            "This is what every user pays on every session. Reduce session-start output or "
            "skill frontmatter; do not raise the budget without saying why.",
        )

    def test_contributor_ambient_within_budget(self):
        actual = self.m["contributor_ambient_tokens"]
        self.assertLessEqual(
            actual,
            CONTRIBUTOR_AMBIENT_BUDGET,
            f"contributor ambient {actual} tok exceeds the {CONTRIBUTOR_AMBIENT_BUDGET} tok ratchet.",
        )

    def test_plugin_ambient_excludes_instruction_file(self):
        """The correction itself, pinned.

        If someone reverts measure() to charge CLAUDE.md to plugin users, the headline
        number silently quadruples and the wrong conclusion follows. Assert the split is
        real rather than trusting the docstring.
        """
        per_host = self.m["instruction_tokens_per_host"]
        self.assertGreater(per_host, 0, "expected a non-trivial instruction file to exist")
        self.assertEqual(
            self.m["contributor_ambient_tokens"] - self.m["plugin_ambient_tokens"],
            per_host,
            "the only difference between the two populations must be the instruction file",
        )

    def test_skill_frontmatter_is_counted(self):
        """Skill descriptions were previously counted as zero tokens.

        They are host-visible so the model can route, which makes them ambient. If this
        ever returns 0 with skills present, the measurement is undercounting again.
        """
        skills = self.m["skills"]
        self.assertGreater(skills["count"], 0, "expected skills to exist")
        self.assertGreater(
            skills["approx_tokens"], 0,
            "skill frontmatter cost is zero with skills present: parsing has silently broken",
        )
        self.assertEqual(
            skills["unparsed"], [],
            f"unparsed skill frontmatter undercounts ambient cost: {skills['unparsed']}",
        )


if __name__ == "__main__":
    unittest.main()
