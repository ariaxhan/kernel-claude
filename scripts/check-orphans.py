#!/usr/bin/env python3
"""Fail when a library function loses its last caller without a verdict.

KERNEL's features have died twice by erosion rather than decision: the GitHub
layer's posting functions kept working perfectly while the rewrite that removed
their call sites shipped green, and the spec-interview recipe dissolved into a
prose paragraph. Nobody chose either. Both were found months later by reading git
history.

This is the fence for that. A function defined in a library script and called
from nowhere is either dead (retire it, with a line in
governance/retirements.jsonl) or stranded (re-wire it, and track the debt in
governance/orphans-baseline.json with the issue that will). Silence is the one
option it removes.

The baseline records the orphans that already existed when this check landed, so
the check fails only on NEW ones. The baseline is debt: it must shrink, never
grow. Run: python3 scripts/check-orphans.py
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / "hooks" / "gates.json"
BASELINE = ROOT / "governance" / "orphans-baseline.json"
# Only executable code counts as a caller. A function named in a doc, a ledger,
# or this check's own baseline is still orphaned -- being written about is not
# being used, and counting prose would let the baseline mask the debt it records.
SCANNED_SUFFIXES = {".sh", ".py"}
DEFINITION = re.compile(r"^(?:function\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*\(\)\s*\{", re.M)


def library_scripts() -> list[str]:
    registry = json.loads(REGISTRY.read_text())
    return [
        h["script"]
        for h in registry["hooks"]
        if h["class"] == "library" and h["script"].endswith(".sh")
    ]


def repo_texts() -> dict[str, str]:
    texts = {}
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix not in SCANNED_SUFFIXES:
            continue
        rel = str(path.relative_to(ROOT))
        # tests/ is excluded on purpose. A suite that greps for a function name is
        # asserting the wiring exists, not using it, and counting those mentions
        # is how a stranded function hides: the GitHub layer's posting functions
        # kept their tests long after the code that called them was rewritten away.
        if rel.startswith((".git/", "node_modules/", "tests/")):
            continue
        try:
            texts[rel] = path.read_text()
        except (OSError, UnicodeDecodeError):
            continue
    return texts


def find_orphans() -> list[tuple[str, str]]:
    definitions: dict[str, str] = {}
    for rel in library_scripts():
        source = (ROOT / rel).read_text()
        for match in DEFINITION.finditer(source):
            definitions[match.group(1)] = rel

    texts = repo_texts()
    orphans = []
    for name, home in sorted(definitions.items()):
        pattern = re.compile(r"\b" + re.escape(name) + r"\b")
        declaration = re.compile(r"^(?:function\s+)?" + re.escape(name) + r"\s*\(\)")
        calls = 0
        for rel, text in texts.items():
            lines = text.split("\n")
            for match in pattern.finditer(text):
                line_no = text[: match.start()].count("\n")
                line = lines[line_no].strip()
                if rel == home and declaration.match(line):
                    continue  # the definition is not a call
                calls += 1
        if calls == 0:
            orphans.append((name, home))
    return orphans


def prose_references(names: set[str]) -> dict[str, list[str]]:
    """Instruction files that name a function: skills and agents, not history.

    KERNEL's runtime is partly an agent reading markdown, so a function named in
    a SKILL.md is reachable in a way one named in a changelog is not. It is still
    weaker than a call site: prose is followed unreliably under load, which is
    why this is reported and never counted as a caller.
    """
    found: dict[str, list[str]] = {name: [] for name in names}
    for folder in ("skills", "agents", "workflows"):
        base = ROOT / folder
        if not base.is_dir():
            continue
        for path in base.rglob("*.md"):
            text = path.read_text()
            rel = str(path.relative_to(ROOT))
            for name in names:
                if re.search(r"\b" + re.escape(name) + r"\b", text):
                    found[name].append(rel)
    return found


def main() -> int:
    baseline = json.loads(BASELINE.read_text())
    known = {entry["function"]: entry for entry in baseline["orphans"]}
    orphans = find_orphans()
    found = {name for name, _ in orphans}

    new = [(n, h) for n, h in orphans if n not in known]
    healed = [name for name in known if name not in found]

    prose = prose_references({name for name, _ in orphans})
    wired = sorted(name for name, refs in prose.items() if refs)
    print(f"orphan check: {len(orphans)} orphaned library functions, {len(known)} baselined")
    if wired:
        print(
            f"  {len(wired)} are prose-wired (named only in agent/skill instructions, so they "
            "run only when an agent obeys prose):"
        )
        for name in wired:
            print(f"    {name} <- {', '.join(prose[name])}")

    if healed:
        print("\nHEALED (re-wired or retired since the baseline was taken):")
        for name in sorted(healed):
            print(f"  - {name}: {known[name].get('tracked_by', 'untracked')}")
        print(
            "\nRemove these from governance/orphans-baseline.json. The baseline is debt; "
            "it shrinks or the check stops meaning anything."
        )
        return 1

    if new:
        print(f"\nFAILED: {len(new)} function(s) lost their last caller in this change:")
        for name, home in new:
            print(f"  - {name}  ({home})")
        print(
            "\nA function nothing calls is either dead or stranded, and the difference is a\n"
            "decision someone has to make:\n"
            "  dead     -> delete it and append a verdict to governance/retirements.jsonl\n"
            "  stranded -> re-wire the call site in this change\n"
            "  deferred -> add it to governance/orphans-baseline.json with the issue that will\n"
        )
        return 1

    print("  no new orphans; every library function still has a caller or a recorded verdict")
    return 0


if __name__ == "__main__":
    sys.exit(main())
