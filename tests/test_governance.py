#!/usr/bin/env python3
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
GEN = ROOT / "scripts" / "generate-governance.py"
SYNC = ROOT / "scripts" / "governance-sync.py"


def run(*args, cwd=ROOT):
    return subprocess.run(args, cwd=cwd, text=True, capture_output=True)


def git_repo(path):
    path.mkdir(parents=True)
    run("git", "init", "-q", str(path))
    return path


class GeneratorTests(unittest.TestCase):
    def test_checked_in_outputs_are_current(self):
        result = run(sys.executable, str(GEN), "--check")
        self.assertEqual(0, result.returncode, result.stderr)

    def test_unknown_missing_and_unused_tokens_fail(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            (root / "governance").mkdir()
            (root / "hooks/scripts").mkdir(parents=True)
            (root / "governance/kernel.md.tmpl").write_text("{{UNKNOWN}}\n")
            (root / "governance/adapters.json").write_text(json.dumps({
                "tokens": {"KNOWN": {"claude": "x", "codex": "y"}},
                "outputs": {"claude": "CLAUDE.md", "codex": "AGENTS.md"},
            }))
            result = run(sys.executable, str(GEN), "--root", str(root), "--check")
            self.assertNotEqual(0, result.returncode)
            self.assertIn("unknown template token", result.stderr)

    def test_ambient_region_is_unique(self):
        text = (ROOT / "hooks/scripts/session-start.sh").read_text()
        self.assertEqual(1, text.count("# BEGIN GENERATED KERNEL AMBIENT"))
        self.assertEqual(1, text.count("# END GENERATED KERNEL AMBIENT"))


class SyncTests(unittest.TestCase):
    def test_audit_classifies_and_deduplicates_worktree(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            git_repo(root / "missing")
            one = git_repo(root / "one")
            (one / "CLAUDE.md").write_text("one\n")
            same = git_repo(root / "same")
            (same / "CLAUDE.md").write_text("same\n")
            (same / "AGENTS.md").write_text("same\n")
            drift = git_repo(root / "drift")
            (drift / "CLAUDE.md").write_text("a\n")
            (drift / "AGENTS.md").write_text("b\n")
            scoped = git_repo(root / "scoped")
            (scoped / ".claude").mkdir()
            (scoped / ".claude/CLAUDE.md").write_text("scoped\n")
            run("git", "-C", str(same), "worktree", "add", "-q", "--detach", str(root / "same-wt"))
            result = run(sys.executable, str(SYNC), "audit", str(root), "--json")
            self.assertEqual(0, result.returncode, result.stderr)
            data = json.loads(result.stdout)
            self.assertEqual(1, data["counts"]["missing_both"])
            self.assertEqual(1, data["counts"]["claude_only"])
            self.assertEqual(1, data["counts"]["both_identical"])
            self.assertEqual(1, data["counts"]["drift"])
            self.assertEqual(1, data["counts"]["scoped_claude_only"])
            self.assertEqual(5, data["canonical_repo_count"])

    def test_missing_both_is_noop_until_init(self):
        with tempfile.TemporaryDirectory() as td:
            repo = git_repo(Path(td) / "repo")
            result = run(sys.executable, str(SYNC), "check", str(repo))
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertFalse((repo / "CLAUDE.md").exists())
            self.assertFalse((repo / "AGENTS.md").exists())

    def test_adopt_generate_check_and_tamper_refusal(self):
        with tempfile.TemporaryDirectory() as td:
            repo = git_repo(Path(td) / "repo")
            backups = Path(td) / "backups"
            (repo / "CLAUDE.md").write_text("shared rules\n")
            adopted = run(sys.executable, str(SYNC), "adopt", str(repo),
                          "--source", "CLAUDE.md", "--backup-dir", str(backups))
            self.assertEqual(0, adopted.returncode, adopted.stderr)
            generated = run(sys.executable, str(SYNC), "generate", str(repo),
                            "--backup-dir", str(backups))
            self.assertEqual(0, generated.returncode, generated.stderr)
            self.assertEqual("shared rules\n", (repo / "AGENTS.md").read_text())
            self.assertEqual(0, run(sys.executable, str(SYNC), "check", str(repo)).returncode)
            manifest = json.loads((repo / ".kernel-governance.json").read_text())
            self.assertEqual(hashlib.sha256(b"shared rules\n").hexdigest(), manifest["source_sha256"])
            (repo / "AGENTS.md").write_text("human edit\n")
            refused = run(sys.executable, str(SYNC), "generate", str(repo),
                          "--backup-dir", str(backups))
            self.assertNotEqual(0, refused.returncode)
            self.assertEqual("human edit\n", (repo / "AGENTS.md").read_text())

    def test_scoped_source_is_not_flattened_or_relocated(self):
        with tempfile.TemporaryDirectory() as td:
            repo = git_repo(Path(td) / "repo")
            backups = Path(td) / "backups"
            (repo / ".claude").mkdir()
            source = repo / ".claude/CLAUDE.md"
            source.write_text("scoped root rules\n")
            self.assertEqual(0, run(sys.executable, str(SYNC), "adopt", str(repo),
                                    "--source", ".claude/CLAUDE.md",
                                    "--backup-dir", str(backups)).returncode)
            self.assertEqual(0, run(sys.executable, str(SYNC), "generate", str(repo),
                                    "--backup-dir", str(backups)).returncode)
            self.assertEqual("scoped root rules\n", (repo / "AGENTS.md").read_text())
            self.assertFalse((repo / "CLAUDE.md").exists())
            self.assertEqual("scoped root rules\n", source.read_text())

    def test_conflicting_native_files_are_never_adopted(self):
        with tempfile.TemporaryDirectory() as td:
            repo = git_repo(Path(td) / "repo")
            (repo / "CLAUDE.md").write_text("a\n")
            (repo / "AGENTS.md").write_text("b\n")
            result = run(sys.executable, str(SYNC), "adopt", str(repo),
                         "--source", "CLAUDE.md", "--backup-dir", str(Path(td) / "b"))
            self.assertNotEqual(0, result.returncode)
            self.assertEqual("b\n", (repo / "AGENTS.md").read_text())


if __name__ == "__main__":
    unittest.main()
