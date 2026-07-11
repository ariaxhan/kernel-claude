#!/usr/bin/env python3
"""Audit and safely create native Claude/Codex governance adapters in Git repos."""

import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

from governance_transaction import TransactionError, locked_root, transactional_write as durable_write

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


def exists_any(path):
    return path.exists() or path.is_symlink()


def safe_repo_path(repo, relative, label, missing_ok=False):
    if relative not in SOURCES and relative not in {"CLAUDE.md", "AGENTS.md", MANIFEST}:
        die(f"unsafe {label} path: {relative}")
    path = repo / relative
    if repo.is_symlink() or not repo.is_dir():
        die(f"repository root must be a real directory: {repo}")
    cursor = repo
    for part in Path(relative).parts[:-1]:
        cursor = cursor / part
        if cursor.is_symlink() or not cursor.is_dir():
            die(f"{label} ancestor must be a real directory, not a symlink: {cursor}")
    if exists_any(path) and not path.is_file():
        die(f"{label} must be a regular non-symlink file: {relative}")
    if not missing_ok and not path.is_file():
        die(f"{label} must be a regular non-symlink file: {relative}")
    if path.is_file() and path.stat(follow_symlinks=False).st_nlink != 1:
        die(f"{label} must not be hardlinked: {relative}")
    try:
        if os.path.commonpath([str(repo), str(path.resolve(strict=False))]) != str(repo):
            die(f"{label} resolves outside repository: {relative}")
    except (OSError, ValueError) as exc:
        die(f"cannot resolve {label}: {exc}")
    return path


def git(repo, *args):
    return subprocess.run(["git", "-C", str(repo), *args], text=True, capture_output=True)


def require_repo(path):
    supplied = path.absolute()
    if supplied.is_symlink() or not supplied.is_dir():
        die(f"repository root must be a real directory: {supplied}")
    path = supplied.resolve()
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


def nested_scopes(repo):
    scopes = []
    for current, dirs, files in os.walk(repo):
        relative_dir = Path(current).relative_to(repo)
        dirs[:] = sorted(d for d in dirs if d not in IGNORED and not d.startswith(".codex"))
        if relative_dir == Path("."):
            continue
        names = set(files)
        if "CLAUDE.md" not in names and "AGENTS.md" not in names:
            continue
        claude = "CLAUDE.md" in names
        agents = "AGENTS.md" in names
        paths = [Path(current) / name for name in ("CLAUDE.md", "AGENTS.md") if name in names]
        if any(path.is_symlink() or not path.is_file() for path in paths):
            state = "unsafe_symlink"
        elif claude and agents:
            state = "both_identical" if read_bytes(Path(current) / "CLAUDE.md") == read_bytes(Path(current) / "AGENTS.md") else "drift"
        else:
            state = "claude_only" if claude else "agents_only"
        scopes.append({"path": relative_dir.as_posix(), "state": state})
    return scopes


def audit(args):
    root = args.path.resolve()
    repos = discover(root)
    records = []
    for repo in repos:
        with locked_root(repo):
            records.append({"path": str(repo), "state": classify(repo), "nested_scopes": nested_scopes(repo)})
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


def backup_target(path, backup_dir, repo):
    relative = path.relative_to(repo).as_posix().replace("/", "__")
    return backup_dir / f"{repo.name}__{relative}"


def preflight_backups(paths, backup_dir, repo):
    try:
        backup_dir.relative_to(repo)
    except ValueError:
        die(f"backup directory must stay inside repository: {backup_dir}")
    if exists_any(backup_dir) and (backup_dir.is_symlink() or not backup_dir.is_dir()):
        die(f"backup directory must be a regular directory: {backup_dir}")
    plans = []
    for path in paths:
        if not exists_any(path):
            continue
        if path.is_symlink() or not path.is_file():
            die(f"refusing non-regular backup source: {path}")
        target = backup_target(path, backup_dir, repo)
        if exists_any(target):
            if target.is_symlink() or not target.is_file() or read_bytes(target) != read_bytes(path):
                die(f"backup already exists with different content: {target}")
            continue
        plans.append((path, target))
    return plans


def manifest_bytes(data):
    return (json.dumps(data, indent=2, sort_keys=True) + "\n").encode()


def manifest_path(repo):
    return repo / MANIFEST


def load_manifest(repo):
    path = safe_repo_path(repo, MANIFEST, "manifest")
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
    path = safe_repo_path(repo, MANIFEST, "manifest", missing_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def output_for(source):
    return "CLAUDE.md" if source == "AGENTS.md" else "AGENTS.md"


def adopt(args):
    repo = require_repo(args.repo)
    source_name = args.source
    if source_name not in SOURCES:
        die(f"unsupported source: {source_name}")
    source = safe_repo_path(repo, source_name, "source")
    output_name = output_for(source_name)
    output = safe_repo_path(repo, output_name, "output", missing_ok=True)
    if output.is_file() and read_bytes(output) != read_bytes(source):
        if not manifest_path(repo).is_file():
            die(f"conflict: {output_name} differs; reconcile manually")
        previous = load_manifest(repo)
        if (previous["source"] != source_name or previous["output"] != output_name
                or previous["output_sha256"] != digest(read_bytes(output))):
            die(f"conflict: {output_name} differs from its recorded generated hash")
    backup_dir = args.backup_dir.resolve()
    backups = preflight_backups([source, output, manifest_path(repo)], backup_dir, repo)
    source_hash = digest(read_bytes(source))
    output_hash = digest(read_bytes(output)) if output.is_file() else None
    manifest = {
        "schema": SCHEMA,
        "generator_version": 1,
        "source": source_name,
        "source_sha256": source_hash,
        "output": output_name,
        "output_sha256": output_hash,
    }
    writes = {target: read_bytes(source_path) for source_path, target in backups}
    writes[manifest_path(repo)] = manifest_bytes(manifest)
    durable_write(repo, writes)
    print(f"adopted {source_name}; adapter target {output_name}")


def generate(args):
    repo = require_repo(args.repo)
    data = load_manifest(repo)
    source = safe_repo_path(repo, data["source"], "source")
    output = safe_repo_path(repo, data["output"], "output", missing_ok=True)
    content = read_bytes(source)
    current_source_hash = digest(content)
    if current_source_hash != data["source_sha256"]:
        die("source hash changed; run adopt with a fresh backup after reviewing the edit")
    backup_dir = args.backup_dir.resolve()
    backups = []
    if exists_any(output):
        current_output_hash = digest(read_bytes(output))
        if data["output_sha256"] is None or current_output_hash != data["output_sha256"]:
            die(f"adapter was edited outside the generator: {data['output']}")
        if read_bytes(output) == content:
            print("adapter current")
            return
        backups = preflight_backups([output], backup_dir, repo)
    safe_repo_path(repo, MANIFEST, "manifest")
    writes = {target: read_bytes(source_path) for source_path, target in backups}
    data["output_sha256"] = digest(content)
    writes[output] = content
    writes[manifest_path(repo)] = manifest_bytes(data)
    durable_write(repo, writes)
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
    source = safe_repo_path(repo, data["source"], "source")
    output = safe_repo_path(repo, data["output"], "output")
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
    source = safe_repo_path(repo, "CLAUDE.md", "source", missing_ok=True)
    output = safe_repo_path(repo, "AGENTS.md", "output", missing_ok=True)
    safe_repo_path(repo, MANIFEST, "manifest", missing_ok=True)
    backup_dir = args.backup_dir.resolve()
    preflight_backups([], backup_dir, repo)
    content = b"# Project governance\n\nAdd shared Claude and Codex instructions here.\n"
    source_hash = digest(content)
    manifest = {
        "schema": SCHEMA, "generator_version": 1,
        "source": "CLAUDE.md", "source_sha256": source_hash,
        "output": "AGENTS.md", "output_sha256": source_hash,
    }
    durable_write(repo, {source: content, output: content, manifest_path(repo): manifest_bytes(manifest)})
    print("initialized CLAUDE.md and AGENTS.md")


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
    try:
        if arguments.command == "audit":
            arguments.func(arguments)
        else:
            arguments.repo = require_repo(arguments.repo)
            with locked_root(arguments.repo) as locked_repo:
                arguments.repo = locked_repo
                arguments.func(arguments)
    except TransactionError as exc:
        die(str(exc))
