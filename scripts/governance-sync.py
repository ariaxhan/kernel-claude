#!/usr/bin/env python3
"""Audit and safely create native Claude/Codex governance adapters in Git repos."""

import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

SCHEMA = "kernel.governance/v1"
MANIFEST = ".kernel-governance.json"
SOURCES = {"CLAUDE.md", "AGENTS.md", ".claude/CLAUDE.md"}
IGNORED = {".git", ".cache", "cache", "node_modules", "vendor", ".venv", "venv"}


def die(message):
    print(f"governance-sync: {message}", file=sys.stderr)
    raise SystemExit(1)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def read_bytes(path):
    try:
        return path.read_bytes()
    except OSError as exc:
        die(str(exc))


def git(repo, *args):
    return subprocess.run(["git", "-C", str(repo), *args], text=True, capture_output=True)


def require_repo(path):
    path = path.resolve()
    result = git(path, "rev-parse", "--show-toplevel")
    if result.returncode:
        die(f"not a Git repository: {path}")
    top = Path(result.stdout.strip()).resolve()
    if top != path:
        die(f"operate from canonical Git root {top}, not {path}")
    return path


def common_identity(repo):
    result = git(repo, "rev-parse", "--path-format=absolute", "--git-common-dir")
    return str(Path(result.stdout.strip()).resolve()) if result.returncode == 0 else str(repo.resolve())


def discover(root):
    seen = set()
    repos = []
    for current, dirs, files in os.walk(root):
        has_git = ".git" in dirs or ".git" in files
        dirs[:] = sorted(d for d in dirs if d not in IGNORED and not d.startswith(".codex"))
        if not has_git:
            continue
        repo = Path(current).resolve()
        identity = common_identity(repo)
        dirs[:] = []
        if identity in seen:
            continue
        seen.add(identity)
        repos.append(repo)
    return sorted(repos)


def classify(repo):
    claude = repo / "CLAUDE.md"
    codex = repo / "AGENTS.md"
    scoped = repo / ".claude/CLAUDE.md"
    if claude.is_file() and codex.is_file():
        return "both_identical" if read_bytes(claude) == read_bytes(codex) else "drift"
    if claude.is_file():
        return "claude_only"
    if codex.is_file() and scoped.is_file():
        return "scoped_conflict"
    if codex.is_file():
        return "agents_only"
    if scoped.is_file():
        return "scoped_claude_only"
    return "missing_both"


def audit(args):
    root = args.path.resolve()
    repos = discover(root)
    records = [{"path": str(repo), "state": classify(repo)} for repo in repos]
    payload = {
        "root": str(root),
        "canonical_repo_count": len(records),
        "counts": dict(sorted(Counter(item["state"] for item in records).items())),
        "repositories": records,
    }
    if args.json:
        print(json.dumps(payload, indent=2, sort_keys=True))
    else:
        for item in records:
            print(f"{item['state']:20} {item['path']}")
        print(f"canonical repositories: {len(records)}")


def backup(path, backup_dir, repo):
    if not path.exists() and not path.is_symlink():
        return
    backup_dir.mkdir(parents=True, exist_ok=True)
    relative = path.relative_to(repo).as_posix().replace("/", "__")
    target = backup_dir / f"{repo.name}__{relative}"
    if target.exists():
        die(f"backup already exists, refusing overwrite: {target}")
    if path.is_symlink():
        target.symlink_to(os.readlink(path))
    elif path.is_file():
        shutil.copy2(path, target)
    else:
        die(f"refusing non-file governance path: {path}")


def manifest_path(repo):
    return repo / MANIFEST


def load_manifest(repo):
    path = manifest_path(repo)
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        die(f"valid {MANIFEST} required: {exc}")
    if set(data) != {"schema", "generator_version", "source", "source_sha256", "output", "output_sha256"}:
        die(f"{MANIFEST} has unknown or missing fields")
    if data["schema"] != SCHEMA or data["generator_version"] != 1:
        die(f"unsupported {MANIFEST} schema or generator version")
    if data["source"] not in SOURCES or data["output"] not in {"CLAUDE.md", "AGENTS.md"}:
        die(f"unsafe source/output in {MANIFEST}")
    if data["source"] == data["output"]:
        die("source and output must differ")
    return data


def write_manifest(repo, data):
    manifest_path(repo).write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def output_for(source):
    return "CLAUDE.md" if source == "AGENTS.md" else "AGENTS.md"


def adopt(args):
    repo = require_repo(args.repo)
    source_name = args.source
    if source_name not in SOURCES:
        die(f"unsupported source: {source_name}")
    source = repo / source_name
    if not source.is_file() or source.is_symlink():
        die(f"source must be a regular file: {source_name}")
    output_name = output_for(source_name)
    output = repo / output_name
    if output.is_file() and read_bytes(output) != read_bytes(source):
        if not manifest_path(repo).is_file():
            die(f"conflict: {output_name} differs; reconcile manually")
        previous = load_manifest(repo)
        if (previous["source"] != source_name or previous["output"] != output_name
                or previous["output_sha256"] != digest(read_bytes(output))):
            die(f"conflict: {output_name} differs from its recorded generated hash")
    if output.exists() and not output.is_file():
        die(f"conflict: {output_name} is not a regular file")
    backup(source, args.backup_dir.resolve(), repo)
    if output.exists():
        backup(output, args.backup_dir.resolve(), repo)
    if manifest_path(repo).exists():
        backup(manifest_path(repo), args.backup_dir.resolve(), repo)
    source_hash = digest(read_bytes(source))
    output_hash = digest(read_bytes(output)) if output.is_file() else None
    write_manifest(repo, {
        "schema": SCHEMA,
        "generator_version": 1,
        "source": source_name,
        "source_sha256": source_hash,
        "output": output_name,
        "output_sha256": output_hash,
    })
    print(f"adopted {source_name}; adapter target {output_name}")


def generate(args):
    repo = require_repo(args.repo)
    data = load_manifest(repo)
    source = repo / data["source"]
    output = repo / data["output"]
    content = read_bytes(source)
    current_source_hash = digest(content)
    if current_source_hash != data["source_sha256"]:
        die("source hash changed; run adopt with a fresh backup after reviewing the edit")
    if output.exists() or output.is_symlink():
        if not output.is_file() or output.is_symlink():
            die(f"refusing non-regular adapter: {data['output']}")
        current_output_hash = digest(read_bytes(output))
        if data["output_sha256"] is None or current_output_hash != data["output_sha256"]:
            die(f"adapter was edited outside the generator: {data['output']}")
        if read_bytes(output) == content:
            print("adapter current")
            return
        backup(output, args.backup_dir.resolve(), repo)
    output.write_bytes(content)
    data["output_sha256"] = digest(content)
    write_manifest(repo, data)
    print(f"generated {data['output']}")


def check(args):
    repo = require_repo(args.repo)
    state = classify(repo)
    path = manifest_path(repo)
    if state == "missing_both" and not path.exists():
        print("compliant no-op: no governance files")
        return
    if not path.is_file():
        die(f"{state}: {MANIFEST} required to declare source and provenance")
    data = load_manifest(repo)
    source = repo / data["source"]
    output = repo / data["output"]
    if not source.is_file() or digest(read_bytes(source)) != data["source_sha256"]:
        die("source missing or hash stale")
    if not output.is_file() or digest(read_bytes(output)) != data["output_sha256"]:
        die("adapter missing or hash stale")
    if read_bytes(source) != read_bytes(output):
        die("source and adapter drift")
    print("governance check: PASS")


def init_repo(args):
    repo = require_repo(args.repo)
    if classify(repo) != "missing_both" or manifest_path(repo).exists():
        die("init requires a repository with no governance files or manifest")
    args.backup_dir.mkdir(parents=True, exist_ok=True)
    source = repo / "CLAUDE.md"
    source.write_text("# Project governance\n\nAdd shared Claude and Codex instructions here.\n", encoding="utf-8")
    args.source = "CLAUDE.md"
    adopt(args)
    generate(args)


def parser():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="command", required=True)
    a = sub.add_parser("audit")
    a.add_argument("path", type=Path)
    a.add_argument("--json", action="store_true")
    a.set_defaults(func=audit)
    c = sub.add_parser("check")
    c.add_argument("repo", type=Path)
    c.set_defaults(func=check)
    for name, function in (("adopt", adopt), ("generate", generate), ("init", init_repo)):
        command = sub.add_parser(name)
        command.add_argument("repo", type=Path)
        command.add_argument("--backup-dir", type=Path, required=True)
        if name == "adopt":
            command.add_argument("--source", required=True)
        command.set_defaults(func=function)
    return p


if __name__ == "__main__":
    arguments = parser().parse_args()
    arguments.func(arguments)
