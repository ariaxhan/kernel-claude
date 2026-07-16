#!/usr/bin/env python3
"""Generate KERNEL's native instruction adapters and ambient hook block."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import os
import sys
import tempfile
import time


TOKEN_RE = re.compile(r"\{\{([A-Z][A-Z0-9_]*)\}\}")
AMBIENT_RE = re.compile(
    r"<!-- KERNEL_AMBIENT_SOURCE_BEGIN\n(.*?)KERNEL_AMBIENT_SOURCE_END -->\n?",
    re.DOTALL,
)
SHELL_BEGIN = "# BEGIN GENERATED KERNEL AMBIENT"
SHELL_END = "# END GENERATED KERNEL AMBIENT"
EXACT_OUTPUTS = {"claude": "CLAUDE.md", "codex": "AGENTS.md"}


def fail(message):
    print(f"generate-governance: {message}", file=sys.stderr)
    raise SystemExit(1)


def require_regular(path, label, missing_ok=False):
    if path.is_symlink() or (path.exists() and not path.is_file()):
        fail(f"{label} must be a regular non-symlink file: {path}")
    if not missing_ok and not path.is_file():
        fail(f"{label} must be a regular non-symlink file: {path}")
    if path.is_file() and path.stat(follow_symlinks=False).st_nlink != 1:
        fail(f"{label} must not be hardlinked: {path}")


def require_contained(root, path, label):
    try:
        relative = path.relative_to(root)
        cursor = root
        if cursor.is_symlink() or not cursor.is_dir():
            fail(f"plugin root must be a real directory, not a symlink: {root}")
        for part in relative.parts[:-1]:
            cursor = cursor / part
            if cursor.is_symlink() or not cursor.is_dir():
                fail(f"{label} ancestor must be a real directory, not a symlink: {cursor}")
        if path.parent.resolve(strict=True) != path.parent or root not in (path.parent, *path.parent.parents):
            fail(f"{label} resolves outside the plugin root: {path}")
    except (OSError, ValueError) as exc:
        fail(f"cannot resolve {label}: {exc}")


def identity(path):
    if not path.exists():
        return None
    stat = path.stat(follow_symlinks=False)
    return (stat.st_dev, stat.st_ino, stat.st_size, stat.st_mtime_ns, stat.st_nlink, stat.st_mode)


def fsync_dir(path):
    try:
        fd = os.open(path, os.O_RDONLY)
        try:
            os.fsync(fd)
        finally:
            os.close(fd)
    except OSError:
        pass


def atomic_replace(root, path, content, expected_identity, mode, validate_inputs, replace_number,
                   fail_after, hard_after):
    require_contained(root, path, "atomic output")
    require_regular(path, "atomic output", missing_ok=True)
    current_identity = identity(path)
    if current_identity != expected_identity:
        if path.is_file() and path.read_bytes() == content:
            return False
        fail(f"concurrent target change detected: {path}")
    validate_inputs()
    fd, temp_name = tempfile.mkstemp(prefix=f".{path.name}.kernel-owned.", dir=path.parent)
    temp = Path(temp_name)
    try:
        with os.fdopen(fd, "wb") as handle:
            handle.write(content)
            handle.flush()
            os.fchmod(handle.fileno(), mode)
            os.fsync(handle.fileno())
        validate_inputs()
        require_contained(root, path, "atomic output")
        require_regular(path, "atomic output", missing_ok=True)
        if identity(path) != expected_identity:
            if path.is_file() and path.read_bytes() == content:
                return False
            fail(f"concurrent target change detected before replace: {path}")
        os.replace(temp, path)
        fsync_dir(path.parent)
        if hard_after and replace_number == hard_after:
            os._exit(97)
        if fail_after and replace_number == fail_after:
            fail(f"injected failure after replace {replace_number}")
        return True
    finally:
        temp.unlink(missing_ok=True)


def load(root):
    source_path = root / "governance/kernel.md.tmpl"
    config_path = root / "governance/adapters.json"
    require_contained(root, source_path, "canonical source")
    require_contained(root, config_path, "adapter config")
    require_regular(source_path, "canonical source")
    require_regular(config_path, "adapter config")
    try:
        source = source_path.read_text(encoding="utf-8")
        config = json.loads(config_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(str(exc))
    tokens = config.get("tokens")
    outputs = config.get("outputs")
    if not isinstance(tokens, dict) or not isinstance(outputs, dict):
        fail("adapters.json requires object fields: tokens and outputs")
    # VERSION is DERIVED from the canonical manifest (plugin.json), never hand-authored
    # in adapters.json or the template. Single source of truth: bump plugin.json only,
    # regenerate, and every {{VERSION}} in the governance docs follows. Injected only when
    # the template actually references {{VERSION}}, so minimal templates aren't forced to.
    if "{{VERSION}}" in source:
        try:
            version = json.loads(
                (root / ".claude-plugin/plugin.json").read_text(encoding="utf-8"))["version"]
        except (OSError, json.JSONDecodeError, KeyError, TypeError) as exc:
            fail(f"cannot read version from .claude-plugin/plugin.json: {exc}")
        tokens["VERSION"] = {client: version for client in EXACT_OUTPUTS}
    if outputs != EXACT_OUTPUTS:
        fail("outputs must use exact native output paths: CLAUDE.md and AGENTS.md")
    clients = set(EXACT_OUTPUTS)
    found = set(TOKEN_RE.findall(source))
    unknown = found - set(tokens)
    unused = set(tokens) - found
    if unknown:
        fail(f"unknown template token(s): {', '.join(sorted(unknown))}")
    if unused:
        fail(f"unused configured token(s): {', '.join(sorted(unused))}")
    for name, values in tokens.items():
        if not isinstance(values, dict) or set(values) != clients:
            fail(f"token {name} must define exactly claude and codex")
        if not all(isinstance(value, str) and value for value in values.values()):
            fail(f"token {name} values must be non-empty strings")
    ambient = AMBIENT_RE.findall(source)
    if len(ambient) != 1:
        fail("canonical source must contain exactly one ambient source block")
    ambient_text = ambient[0].rstrip() + "\n"
    unsafe_lines = {"KERNEL_CONTEXT", SHELL_BEGIN, SHELL_END}
    if "\x00" in ambient_text or "\r" in ambient_text or any(
            line in unsafe_lines for line in ambient_text.splitlines()):
        fail("ambient source contains an unsafe heredoc terminator or marker line")
    return source_path, source, config, ambient_text


def substitute(text, tokens, client):
    return TOKEN_RE.sub(lambda match: tokens[match.group(1)][client], text)


def render_outputs(root):
    source_path, source, config, ambient = load(root)
    source_hash = hashlib.sha256(source.encode()).hexdigest()
    body = AMBIENT_RE.sub("", source)
    rendered = {}
    for client, output in config["outputs"].items():
        header = (
            "<!-- GENERATED FILE. Edit governance/kernel.md.tmpl, then run "
            "scripts/generate-governance.py.\n"
            f"     source-sha256: {source_hash}; adapter: {client} -->\n"
        )
        output_path = root / output
        require_contained(root, output_path, "native output")
        rendered[output_path] = header + substitute(body, config["tokens"], client)
    if TOKEN_RE.search(ambient):
        fail("ambient source must be client-neutral; template token found")
    shell = root / "hooks/scripts/session-start.sh"
    require_contained(root, shell, "session-start hook")
    require_regular(shell, "session-start hook")
    try:
        shell_text = shell.read_text(encoding="utf-8")
    except OSError as exc:
        fail(str(exc))
    if shell_text.count(SHELL_BEGIN) != 1 or shell_text.count(SHELL_END) != 1:
        fail("session-start.sh must contain exactly one begin and one end marker")
    pattern = re.compile(
        re.escape(SHELL_BEGIN) + r"\n.*?\n" + re.escape(SHELL_END), re.DOTALL
    )
    if len(pattern.findall(shell_text)) != 1:
        fail("session-start.sh must contain exactly one generated ambient region")
    block = f"{SHELL_BEGIN}\ncat << 'KERNEL_CONTEXT'\n{ambient}KERNEL_CONTEXT\n{SHELL_END}"
    rendered[shell] = pattern.sub(lambda _match: block, shell_text)
    return source_path, rendered


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    supplied_root = args.root.absolute()
    if supplied_root.is_symlink() or not supplied_root.is_dir():
        fail(f"plugin root must be a real directory, not a symlink: {supplied_root}")
    root = supplied_root.resolve()
    source = root / "governance/kernel.md.tmpl"
    config = root / "governance/adapters.json"
    _, outputs = render_outputs(root)
    source_identity, config_identity = identity(source), identity(config)
    target_identities = {path: identity(path) for path in outputs}
    for path in outputs:
        require_contained(root, path, "generated output")
        require_regular(path, "generated output", missing_ok=path.name in {"CLAUDE.md", "AGENTS.md"})
    stale = [path.relative_to(root).as_posix() for path, expected in outputs.items()
             if not path.is_file() or path.read_text(encoding="utf-8") != expected]
    if args.check:
        if stale:
            fail("stale generated file(s): " + ", ".join(stale))
        print("governance current")
        return
    try:
        fail_after = int(os.environ.get("KERNEL_TEST_FAIL_AFTER_REPLACE", "0") or 0)
        hard_after = int(os.environ.get("KERNEL_TEST_HARD_KILL_AFTER_REPLACE", "0") or 0)
        pause_ms = int(os.environ.get("KERNEL_TEST_PAUSE_BEFORE_REPLACE_MS", "0") or 0)
    except ValueError:
        fail("invalid test timing/failure value")
    if min(fail_after, hard_after, pause_ms) < 0 or pause_ms > 5000:
        fail("test timing/failure value out of range")
    if pause_ms:
        time.sleep(pause_ms / 1000)

    def validate_inputs():
        require_regular(source, "canonical source")
        require_regular(config, "adapter config")
        if identity(source) != source_identity or identity(config) != config_identity:
            fail("canonical source or adapter config changed during generation")

    replaced = 0
    for path, expected in outputs.items():
        if path.relative_to(root).as_posix() not in stale:
            continue
        original_mode = (target_identities[path][-1] & 0o777) if target_identities[path] else None
        mode = original_mode if original_mode is not None else (0o755 if path.suffix == ".sh" else 0o644)
        changed = atomic_replace(root, path, expected.encode(), target_identities[path], mode,
                                 validate_inputs, replaced + 1, fail_after, hard_after)
        if changed:
            replaced += 1
        target_identities[path] = identity(path)
    print("generated: " + ", ".join(stale or ["no changes"]))


if __name__ == "__main__":
    main()
