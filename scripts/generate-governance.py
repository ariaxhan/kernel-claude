#!/usr/bin/env python3
"""Generate KERNEL's native instruction adapters and ambient hook block."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys

TOKEN_RE = re.compile(r"\{\{([A-Z][A-Z0-9_]*)\}\}")
AMBIENT_RE = re.compile(
    r"<!-- KERNEL_AMBIENT_SOURCE_BEGIN\n(.*?)KERNEL_AMBIENT_SOURCE_END -->\n?",
    re.DOTALL,
)
SHELL_BEGIN = "# BEGIN GENERATED KERNEL AMBIENT"
SHELL_END = "# END GENERATED KERNEL AMBIENT"


def fail(message):
    print(f"generate-governance: {message}", file=sys.stderr)
    raise SystemExit(1)


def load(root):
    source_path = root / "governance/kernel.md.tmpl"
    config_path = root / "governance/adapters.json"
    try:
        source = source_path.read_text(encoding="utf-8")
        config = json.loads(config_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(str(exc))
    tokens = config.get("tokens")
    outputs = config.get("outputs")
    if not isinstance(tokens, dict) or not isinstance(outputs, dict):
        fail("adapters.json requires object fields: tokens and outputs")
    clients = set(outputs)
    if clients != {"claude", "codex"}:
        fail("outputs must declare exactly claude and codex")
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
    return source_path, source, config, ambient[0].rstrip() + "\n"


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
        rendered[root / output] = header + substitute(body, config["tokens"], client)
    if TOKEN_RE.search(ambient):
        fail("ambient source must be client-neutral; template token found")
    shell = root / "hooks/scripts/session-start.sh"
    try:
        shell_text = shell.read_text(encoding="utf-8")
    except OSError as exc:
        fail(str(exc))
    pattern = re.compile(
        re.escape(SHELL_BEGIN) + r"\n.*?\n" + re.escape(SHELL_END), re.DOTALL
    )
    if len(pattern.findall(shell_text)) != 1:
        fail("session-start.sh must contain exactly one generated ambient region")
    block = f"{SHELL_BEGIN}\ncat << 'KERNEL_CONTEXT'\n{ambient}KERNEL_CONTEXT\n{SHELL_END}"
    rendered[shell] = pattern.sub(block, shell_text)
    return source_path, rendered


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    root = args.root.resolve()
    _, outputs = render_outputs(root)
    stale = []
    for path, expected in outputs.items():
        actual = path.read_text(encoding="utf-8") if path.is_file() else None
        if actual != expected:
            stale.append(path.relative_to(root).as_posix())
            if not args.check:
                path.write_text(expected, encoding="utf-8")
    if args.check and stale:
        fail("stale generated file(s): " + ", ".join(stale))
    print("governance current" if args.check else "generated: " + ", ".join(stale or ["no changes"]))


if __name__ == "__main__":
    main()
