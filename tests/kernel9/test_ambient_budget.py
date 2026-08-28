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


# Ratchets, re-derived 2026-08-27 after the measurement was corrected. Measured
# now: plugin 3845, contributor 11027.
#
# These are NOT raised budgets. The instrument changed underneath them. It used to
# run session-start.sh against this repo and count output carrying our branch, our
# commit log, our agentdb learnings, our active contract and our code map, so the
# hook read 8036 / 8005 / 8005 bytes across three runs and the gate disagreed
# between a dirty working copy and clean CI. It now reports on a pinned
# single-commit fixture and reads 3516 bytes every time. The old numbers measured a
# different thing and cannot be compared to these.
#
# Headroom matches the previous convention: a little over the measured value, so
# ordinary editing does not trip the gate but real growth does.
PLUGIN_AMBIENT_BUDGET = 4000
CONTRIBUTOR_AMBIENT_BUDGET = 11400


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

    def test_measurement_is_deterministic(self):
        """The gate has to mean the same thing twice, or it cannot be acted on.

        The previous version measured the hook against this live repo, so the number
        moved with tree dirtiness and agentdb growth: it failed locally and passed in
        CI on the same commit, which is how it sat red and unactioned. If someone
        points the measurement back at real state, this fails before the ratchet does
        and says why.
        """
        second = measure_ambient.measure()
        self.assertEqual(
            self.m["hooks"][0]["bytes"],
            second["hooks"][0]["bytes"],
            "session-start.sh cost changed between two consecutive measurements. The "
            "hook is being measured against live state again (branch, commit log, "
            "agentdb, contracts, code map) instead of the pinned fixture. A ratchet "
            "that moves with the tree cannot be acted on.",
        )
        self.assertEqual(
            self.m["plugin_ambient_tokens"],
            second["plugin_ambient_tokens"],
            "plugin ambient is not reproducible across two runs in one process",
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
