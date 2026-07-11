#!/usr/bin/env python3
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
GEN = ROOT / "scripts" / "generate-governance.py"
SYNC = ROOT / "scripts" / "governance-sync.py"


def run(*args, cwd=ROOT, env=None):
    return subprocess.run(args, cwd=cwd, text=True, capture_output=True, env=env)


def git_repo(path):
    path.mkdir(parents=True)
    run("git", "init", "-q", str(path))
    return path


def generator_fixture(root, source="shared\n", outputs=None):
    (root / "governance").mkdir(parents=True)
    (root / "hooks/scripts").mkdir(parents=True)
    template = "<!-- KERNEL_AMBIENT_SOURCE_BEGIN\nambient\nKERNEL_AMBIENT_SOURCE_END -->\n" + source
    (root / "governance/kernel.md.tmpl").write_text(template)
    (root / "governance/adapters.json").write_text(json.dumps({
        "tokens": {},
        "outputs": outputs or {"claude": "CLAUDE.md", "codex": "AGENTS.md"},
    }))
    (root / "hooks/scripts/session-start.sh").write_text(
        "# BEGIN GENERATED KERNEL AMBIENT\nold\n# END GENERATED KERNEL AMBIENT\n"
    )


def snapshot_tree(root):
    snapshot = {}
    for path in sorted(root.rglob("*")):
        relative = path.relative_to(root).as_posix()
        stat = path.lstat()
        if path.is_symlink():
            payload = ("symlink", os.readlink(path))
        elif path.is_file():
            payload = ("file", path.read_bytes())
        else:
            payload = ("dir", None)
        snapshot[relative] = (stat.st_mode, stat.st_ino, stat.st_nlink, payload)
    return snapshot


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

    def test_begin_and_end_markers_are_counted_independently(self):
        for extra in ("# BEGIN GENERATED KERNEL AMBIENT\n", "# END GENERATED KERNEL AMBIENT\n"):
            with self.subTest(extra=extra.strip()), tempfile.TemporaryDirectory() as td:
                root = Path(td) / "root"
                generator_fixture(root)
                shell = root / "hooks/scripts/session-start.sh"
                shell.write_text(extra + shell.read_text())
                result = run(sys.executable, str(GEN), "--root", str(root))
                self.assertNotEqual(0, result.returncode)
                self.assertIn("exactly one begin and one end marker", result.stderr)

    def test_output_paths_are_exact_and_cannot_escape_root(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td) / "root"
            generator_fixture(root, outputs={"claude": "../../escape", "codex": "AGENTS.md"})
            result = run(sys.executable, str(GEN), "--root", str(root))
            self.assertNotEqual(0, result.returncode)
            self.assertIn("exact native output paths", result.stderr)
            self.assertFalse((Path(td) / "escape").exists())

    def test_symlinked_source_config_or_output_is_rejected(self):
        for target in ("source", "config", "output"):
            with self.subTest(target=target), tempfile.TemporaryDirectory() as td:
                root = Path(td) / "root"
                generator_fixture(root)
                outside = Path(td) / "outside"
                outside.write_text("outside\n")
                if target == "source":
                    (root / "governance/kernel.md.tmpl").unlink()
                    (root / "governance/kernel.md.tmpl").symlink_to(outside)
                elif target == "config":
                    content = (root / "governance/adapters.json").read_text()
                    (root / "governance/adapters.json").unlink()
                    outside.write_text(content)
                    (root / "governance/adapters.json").symlink_to(outside)
                else:
                    (root / "CLAUDE.md").symlink_to(outside)
                outside_before = outside.read_text()
                result = run(sys.executable, str(GEN), "--root", str(root))
                self.assertNotEqual(0, result.returncode)
                self.assertIn("regular non-symlink file", result.stderr)
                self.assertEqual(outside_before, outside.read_text())

    def test_symlinked_ancestor_and_hardlinked_files_are_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            base = Path(td)
            root = base / "root"
            generator_fixture(root)
            real_governance = root / "real-governance"
            (root / "governance").rename(real_governance)
            (root / "governance").symlink_to(real_governance, target_is_directory=True)
            result = run(sys.executable, str(GEN), "--root", str(root))
            self.assertNotEqual(0, result.returncode)
            self.assertIn("ancestor", result.stderr)
        for relative in ("governance/kernel.md.tmpl", "governance/adapters.json",
                         "hooks/scripts/session-start.sh", "CLAUDE.md"):
            with self.subTest(relative=relative), tempfile.TemporaryDirectory() as td:
                root = Path(td) / "root"
                generator_fixture(root)
                path = root / relative
                if not path.exists():
                    path.write_text("old\n")
                os.link(path, Path(td) / "external-hardlink")
                result = run(sys.executable, str(GEN), "--root", str(root))
                self.assertNotEqual(0, result.returncode)
                self.assertIn("hardlinked", result.stderr)

    def test_preflight_rejects_all_outputs_before_first_write(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td) / "root"
            generator_fixture(root)
            (root / "CLAUDE.md").write_text("keep me\n")
            outside = Path(td) / "outside"
            outside.write_text("outside\n")
            (root / "AGENTS.md").symlink_to(outside)
            result = run(sys.executable, str(GEN), "--root", str(root))
            self.assertNotEqual(0, result.returncode)
            self.assertEqual("keep me\n", (root / "CLAUDE.md").read_text())

    def test_interruption_leaves_full_files_check_reports_drift_and_rerun_repairs(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td) / "root"
            generator_fixture(root)
            (root / "CLAUDE.md").write_text("old claude\n")
            (root / "AGENTS.md").write_text("old agents\n")
            env = os.environ.copy()
            env["KERNEL_TEST_HARD_KILL_AFTER_REPLACE"] = "1"
            self.assertNotEqual(0, run(sys.executable, str(GEN), "--root", str(root), env=env).returncode)
            first = (root / "CLAUDE.md").read_bytes()
            self.assertTrue(first.startswith(b"<!-- GENERATED FILE."))
            before = snapshot_tree(root)
            check = run(sys.executable, str(GEN), "--root", str(root), "--check")
            self.assertNotEqual(0, check.returncode)
            self.assertEqual(before, snapshot_tree(root))
            self.assertEqual(0, run(sys.executable, str(GEN), "--root", str(root)).returncode)
            self.assertEqual(0, run(sys.executable, str(GEN), "--root", str(root), "--check").returncode)

    def test_generation_preserves_modes_and_sets_safe_new_modes(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td) / "root"
            generator_fixture(root)
            shell = root / "hooks/scripts/session-start.sh"
            shell.chmod(0o700)
            (root / "CLAUDE.md").write_text("old\n")
            (root / "CLAUDE.md").chmod(0o600)
            self.assertEqual(0, run(sys.executable, str(GEN), "--root", str(root)).returncode)
            self.assertEqual(0o600, (root / "CLAUDE.md").stat().st_mode & 0o777)
            self.assertEqual(0o644, (root / "AGENTS.md").stat().st_mode & 0o777)
            self.assertEqual(0o700, shell.stat().st_mode & 0o777)

    def test_invalid_failure_env_cleans_own_atomic_temp(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td) / "root"
            generator_fixture(root)
            env = os.environ.copy()
            env["KERNEL_TEST_FAIL_AFTER_REPLACE"] = "not-an-int"
            result = run(sys.executable, str(GEN), "--root", str(root), env=env)
            self.assertNotEqual(0, result.returncode)
            self.assertFalse(list(root.rglob("*.kernel-owned.*")))

    def test_concurrent_same_source_converges_and_source_change_aborts(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td) / "root"
            generator_fixture(root)
            env = os.environ.copy()
            env["KERNEL_TEST_PAUSE_BEFORE_REPLACE_MS"] = "300"
            first = subprocess.Popen([sys.executable, str(GEN), "--root", str(root)],
                                     text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
            time.sleep(0.05)
            second = run(sys.executable, str(GEN), "--root", str(root))
            _first_out, first_err = first.communicate(timeout=5)
            self.assertEqual(0, first.returncode, first_err)
            self.assertEqual(0, second.returncode, second.stderr)
            self.assertEqual(0, run(sys.executable, str(GEN), "--root", str(root), "--check").returncode)
            (root / "AGENTS.md").write_text("stale\n")
            env["KERNEL_TEST_PAUSE_BEFORE_REPLACE_MS"] = "300"
            changed = subprocess.Popen([sys.executable, str(GEN), "--root", str(root)],
                                       text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
            time.sleep(0.05)
            source = root / "governance/kernel.md.tmpl"
            source.write_text(source.read_text() + "changed concurrently\n")
            _out, err = changed.communicate(timeout=5)
            self.assertNotEqual(0, changed.returncode)
            self.assertIn("changed during generation", err)

    def test_check_is_read_only_with_unknown_hostile_files(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td) / "root"
            generator_fixture(root)
            self.assertEqual(0, run(sys.executable, str(GEN), "--root", str(root)).returncode)
            unknown = root / ".CLAUDE.md.kernel-owned.someone-else"
            unknown.write_text("do not delete\n")
            outside = Path(td) / "outside"
            outside.write_text("outside\n")
            (root / "hostile-link").symlink_to(outside)
            before = snapshot_tree(root)
            self.assertEqual(0, run(sys.executable, str(GEN), "--root", str(root), "--check").returncode)
            self.assertEqual(before, snapshot_tree(root))

    def test_ambient_rejects_heredoc_terminator_and_preserves_backslashes(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td) / "root"
            generator_fixture(root)
            source = (root / "governance/kernel.md.tmpl").read_text()
            (root / "governance/kernel.md.tmpl").write_text(source.replace("ambient", "KERNEL_CONTEXT"))
            result = run(sys.executable, str(GEN), "--root", str(root))
            self.assertNotEqual(0, result.returncode)
            self.assertIn("heredoc terminator", result.stderr)
            (root / "governance/kernel.md.tmpl").write_text(source.replace("ambient", r"literal \\1 \\g<1>"))
            self.assertEqual(0, run(sys.executable, str(GEN), "--root", str(root)).returncode)
            shell = (root / "hooks/scripts/session-start.sh").read_text()
            self.assertIn(r"literal \\1 \\g<1>", shell)


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
            backups = repo / ".kernel-backups/phase"
            (repo / "CLAUDE.md").write_text("shared rules\n")
            (repo / "CLAUDE.md").chmod(0o600)
            adopted = run(sys.executable, str(SYNC), "adopt", str(repo),
                          "--source", "CLAUDE.md", "--backup-dir", str(backups))
            self.assertEqual(0, adopted.returncode, adopted.stderr)
            generated = run(sys.executable, str(SYNC), "generate", str(repo),
                            "--backup-dir", str(backups))
            self.assertEqual(0, generated.returncode, generated.stderr)
            self.assertEqual(0o644, (repo / "AGENTS.md").stat().st_mode & 0o777)
            self.assertEqual(0o644, (repo / ".kernel-governance.json").stat().st_mode & 0o777)
            self.assertEqual(0o600, (backups / "repo__CLAUDE.md").stat().st_mode & 0o777)
            self.assertTrue((repo / "AGENTS.md").read_text().endswith("shared rules\n"))
            before_check = snapshot_tree(repo)
            self.assertEqual(0, run(sys.executable, str(SYNC), "check", str(repo)).returncode)
            self.assertEqual(before_check, snapshot_tree(repo))
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
            backups = repo / ".kernel-backups/phase"
            (repo / ".claude").mkdir()
            source = repo / ".claude/CLAUDE.md"
            source.write_text("scoped root rules\n")
            self.assertEqual(0, run(sys.executable, str(SYNC), "adopt", str(repo),
                                    "--source", ".claude/CLAUDE.md",
                                    "--backup-dir", str(backups)).returncode)
            self.assertEqual(0, run(sys.executable, str(SYNC), "generate", str(repo),
                                    "--backup-dir", str(backups)).returncode)
            self.assertTrue((repo / "AGENTS.md").read_text().endswith("scoped root rules\n"))
            self.assertFalse((repo / "CLAUDE.md").exists())
            self.assertEqual("scoped root rules\n", source.read_text())

    def test_conflicting_native_files_are_never_adopted(self):
        with tempfile.TemporaryDirectory() as td:
            repo = git_repo(Path(td) / "repo")
            (repo / "CLAUDE.md").write_text("a\n")
            (repo / "AGENTS.md").write_text("b\n")
            result = run(sys.executable, str(SYNC), "adopt", str(repo),
                         "--source", "CLAUDE.md", "--backup-dir", str(repo / ".kernel-backups/b"))
            self.assertNotEqual(0, result.returncode)
            self.assertEqual("b\n", (repo / "AGENTS.md").read_text())

    def test_symlinked_source_output_and_manifest_are_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            base = Path(td)
            repo = git_repo(base / "repo")
            outside = base / "outside"
            outside.write_text("rules\n")
            (repo / "CLAUDE.md").symlink_to(outside)
            result = run(sys.executable, str(SYNC), "adopt", str(repo), "--source", "CLAUDE.md",
                         "--backup-dir", str(repo / ".kernel-backups/b1"))
            self.assertNotEqual(0, result.returncode)
            (repo / "CLAUDE.md").unlink()
            (repo / "CLAUDE.md").write_text("rules\n")
            self.assertEqual(0, run(sys.executable, str(SYNC), "adopt", str(repo),
                                    "--source", "CLAUDE.md", "--backup-dir", str(repo / ".kernel-backups/b2")).returncode)
            (repo / "AGENTS.md").unlink()
            (repo / "AGENTS.md").symlink_to(outside)
            self.assertNotEqual(0, run(sys.executable, str(SYNC), "generate", str(repo),
                                       "--backup-dir", str(repo / ".kernel-backups/b3")).returncode)
            (repo / "AGENTS.md").unlink()
            (repo / ".kernel-governance.json").unlink()
            (repo / ".kernel-governance.json").symlink_to(outside)
            self.assertNotEqual(0, run(sys.executable, str(SYNC), "check", str(repo)).returncode)

    def test_sync_rejects_symlink_ancestors_and_hardlinks(self):
        with tempfile.TemporaryDirectory() as td:
            base = Path(td)
            repo = git_repo(base / "repo")
            real = repo / "real-claude"
            real.mkdir()
            (real / "CLAUDE.md").write_text("rules\n")
            (repo / ".claude").symlink_to(real, target_is_directory=True)
            result = run(sys.executable, str(SYNC), "adopt", str(repo),
                         "--source", ".claude/CLAUDE.md", "--backup-dir", str(repo / ".kernel-backups/b"))
            self.assertNotEqual(0, result.returncode)
            self.assertIn("symlink", result.stderr)
        for relative, phase in (("CLAUDE.md", "source"), ("AGENTS.md", "output"),
                                (".kernel-governance.json", "manifest")):
            with self.subTest(relative=relative), tempfile.TemporaryDirectory() as td:
                base = Path(td)
                repo = git_repo(base / "repo")
                (repo / "CLAUDE.md").write_text("rules\n")
                self.assertEqual(0, run(sys.executable, str(SYNC), "adopt", str(repo),
                                        "--source", "CLAUDE.md", "--backup-dir", str(repo / ".kernel-backups/adopt")).returncode)
                if relative == "AGENTS.md":
                    (repo / "AGENTS.md").write_text("rules\n")
                path = repo / relative
                os.link(path, base / "external-hardlink")
                command = "check" if phase == "manifest" else ("adopt" if phase == "source" else "generate")
                args = [sys.executable, str(SYNC), command, str(repo)]
                if command == "adopt":
                    args += ["--source", "CLAUDE.md", "--backup-dir", str(repo / ".kernel-backups/again")]
                elif command == "generate":
                    args += ["--backup-dir", str(repo / ".kernel-backups/generate")]
                result = run(*args)
                self.assertNotEqual(0, result.returncode)
                self.assertIn("hardlinked", result.stderr)

    def test_adopt_preflights_every_backup_before_writing_any(self):
        with tempfile.TemporaryDirectory() as td:
            base = Path(td)
            repo = git_repo(base / "repo")
            (repo / "CLAUDE.md").write_text("same\n")
            (repo / "AGENTS.md").write_text("same\n")
            backups = repo / ".kernel-backups/backups"
            backups.mkdir(parents=True)
            (backups / "repo__AGENTS.md").write_text("collision\n")
            result = run(sys.executable, str(SYNC), "adopt", str(repo), "--source", "CLAUDE.md",
                         "--backup-dir", str(backups))
            self.assertNotEqual(0, result.returncode)
            self.assertFalse((backups / "repo__CLAUDE.md").exists())
            self.assertFalse((repo / ".kernel-governance.json").exists())

    def test_audit_reports_nested_scopes_without_flattening(self):
        with tempfile.TemporaryDirectory() as td:
            repo = git_repo(Path(td) / "repo")
            (repo / "CLAUDE.md").write_text("root\n")
            (repo / "packages/a").mkdir(parents=True)
            (repo / "packages/a/CLAUDE.md").write_text("nested claude\n")
            (repo / "packages/b").mkdir(parents=True)
            (repo / "packages/b/AGENTS.md").write_text("nested codex\n")
            result = run(sys.executable, str(SYNC), "audit", str(repo.parent), "--json")
            self.assertEqual(0, result.returncode, result.stderr)
            record = json.loads(result.stdout)["repositories"][0]
            self.assertEqual([
                {"path": "packages/a", "state": "claude_only"},
                {"path": "packages/b", "state": "agents_only"},
            ], record["nested_scopes"])
            self.assertFalse((repo / "packages/a/AGENTS.md").exists())
            self.assertFalse((repo / "packages/b/CLAUDE.md").exists())

    def test_audit_classifies_nested_symlink_without_following_it(self):
        with tempfile.TemporaryDirectory() as td:
            base = Path(td)
            repo = git_repo(base / "repo")
            outside = base / "outside"
            outside.write_text("secret\n")
            (repo / "nested").mkdir()
            (repo / "nested/CLAUDE.md").symlink_to(outside)
            result = run(sys.executable, str(SYNC), "audit", str(base), "--json")
            self.assertEqual(0, result.returncode, result.stderr)
            scopes = json.loads(result.stdout)["repositories"][0]["nested_scopes"]
            self.assertEqual([{"path": "nested", "state": "unsafe_symlink"}], scopes)

    def test_interrupted_adoption_is_auditable_and_rerun_repairs(self):
        with tempfile.TemporaryDirectory() as td:
            repo = git_repo(Path(td) / "repo")
            (repo / "CLAUDE.md").write_text("rules\n")
            env = os.environ.copy()
            env["KERNEL_TEST_HARD_KILL_AFTER_REPLACE"] = "2"  # backup, adapter, then stop before manifest
            result = run(sys.executable, str(SYNC), "adopt", str(repo), "--source", "CLAUDE.md",
                         "--backup-dir", str(repo / ".kernel-backups/adopt"), env=env)
            self.assertNotEqual(0, result.returncode)
            self.assertTrue((repo / "AGENTS.md").read_text().startswith("<!-- GENERATED by KERNEL"))
            self.assertFalse((repo / ".kernel-governance.json").exists())
            audit = run(sys.executable, str(SYNC), "audit", str(repo.parent), "--json")
            self.assertEqual("incomplete_generation", json.loads(audit.stdout)["repositories"][0]["state"])
            self.assertEqual(0, run(sys.executable, str(SYNC), "adopt", str(repo),
                                    "--source", "CLAUDE.md",
                                    "--backup-dir", str(repo / ".kernel-backups/adopt")).returncode)
            self.assertEqual(0, run(sys.executable, str(SYNC), "check", str(repo)).returncode)

    def test_skill_documents_separate_backup_phases(self):
        skill = (ROOT / "skills/governance-sync/SKILL.md").read_text()
        self.assertIn("BACKUPS/adopt", skill)
        self.assertIn("BACKUPS/generate", skill)


if __name__ == "__main__":
    unittest.main()
