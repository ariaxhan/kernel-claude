#!/usr/bin/env python3
"""Keep every concrete skill dependency reachable, including reference documents."""

from pathlib import Path
import re
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]


def missing_skill_references(root):
    missing = []
    for directory in ("skills", "agents"):
        for source in sorted((root / directory).rglob("*.md")):
            content = source.read_text()
            references = re.findall(r"skills/[A-Za-z0-9_./-]+\.md", content)
            for block in re.findall(r"<skill_load>(.*?)</skill_load>", content, re.S):
                references.extend(reference.rstrip(".") for reference in
                                  re.findall(r"skills/[A-Za-z0-9_./-]+", block))
            for reference in sorted(set(references)):
                if not (root / reference).is_file():
                    missing.append(f"{source.relative_to(root)}: {reference}")
    return missing


class SkillDependencies(unittest.TestCase):
    def test_shipped_dependencies_exist(self):
        self.assertEqual(missing_skill_references(REPO), [])

    def test_all_load_targets_are_checked(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "skills/demo").mkdir(parents=True)
            (root / "agents").mkdir()
            (root / "skills/demo/SKILL.md").write_text(
                "<skill_load>skills/missing/SKILL.md</skill_load>\n"
                "<skill_load>\nalways: skills/demo/SKILL.md\n"
                "on_domain:\n  api: skills/api_v2/references/spec-2.md.\n"
                "Reference: skills/demo/references/rules.yaml\n</skill_load>\n"
                "Load: skills/demo/motion/scene-3.md\n"
            )
            (root / "agents/checker.md").write_text(
                "<skill_load>skills/demo/reference/test.md</skill_load>"
            )
            missing = missing_skill_references(root)
            self.assertEqual(len(missing), 5, missing)
            for target in ("missing/SKILL.md", "api_v2/references/spec-2.md",
                           "demo/references/rules.yaml", "demo/motion/scene-3.md",
                           "demo/reference/test.md"):
                self.assertTrue(any(item.endswith(target) for item in missing), target)
            for item in missing:
                target = root / item.split(": ", 1)[1]
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("methodology\n")
            self.assertEqual(missing_skill_references(root), [])


if __name__ == "__main__":
    unittest.main()
