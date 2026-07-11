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


def transactional_write(changes):
    """Stage every file, then replace all-or-restore exact original bytes."""
    originals = {}
    staged = {}
    for path, content in changes.items():
        require_regular(path, "transaction target", missing_ok=True)
        originals[path] = path.read_bytes() if path.is_file() else None
        handle = tempfile.NamedTemporaryFile("wb", dir=path.parent, prefix=f".{path.name}.stage.", delete=False)
        try:
            handle.write(content.encode("utf-8") if isinstance(content, str) else content)
            handle.flush()
            os.fsync(handle.fileno())
        finally:
            handle.close()
        staged[path] = Path(handle.name)
    replaced = []
    fail_after = int(os.environ.get("KERNEL_TEST_FAIL_AFTER_REPLACE", "0") or 0)
    try:
        for path, stage in staged.items():
            os.replace(stage, path)
            replaced.append(path)
            if fail_after and len(replaced) == fail_after:
                raise OSError(f"injected failure after replace {fail_after}")
    except Exception as exc:
        for path in reversed(replaced):
            original = originals[path]
            if original is None:
                path.unlink(missing_ok=True)
            else:
                rollback = tempfile.NamedTemporaryFile("wb", dir=path.parent, prefix=f".{path.name}.rollback.", delete=False)
                try:
                    rollback.write(original)
                    rollback.flush()
                    os.fsync(rollback.fileno())
                finally:
                    rollback.close()
                os.replace(rollback.name, path)
        for stage in staged.values():
            stage.unlink(missing_ok=True)
        fail(f"transaction rolled back: {exc}")


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
    _, outputs = render_outputs(root)
    stale = []
    for path in outputs:
        require_contained(root, path, "generated output")
        require_regular(path, "generated output", missing_ok=path.name in {"CLAUDE.md", "AGENTS.md"})
    for path, expected in outputs.items():
        actual = path.read_text(encoding="utf-8") if path.is_file() else None
        if actual != expected:
            stale.append(path.relative_to(root).as_posix())
    if args.check and stale:
        fail("stale generated file(s): " + ", ".join(stale))
    if not args.check:
        changes = {path: expected for path, expected in outputs.items()
                   if path.relative_to(root).as_posix() in stale}
        if changes:
            transactional_write(changes)
    print("governance current" if args.check else "generated: " + ", ".join(stale or ["no changes"]))


if __name__ == "__main__":
    main()
