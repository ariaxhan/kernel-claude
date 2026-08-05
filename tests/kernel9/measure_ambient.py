#!/usr/bin/env python3
"""Measure KERNEL's ambient session-start context cost.

"Ambient" means everything the model pays for before it has done anything.

THERE ARE TWO POPULATIONS AND THEY PAY DIFFERENT AMOUNTS. Conflating them is how
this instrument previously produced a misleading headline number.

  plugin      Someone who installs KERNEL as a plugin. This is almost everyone.
              They pay for the SessionStart hook output and for the host-visible
              skill frontmatter. They DO NOT pay for this repo's CLAUDE.md or
              AGENTS.md: Claude Code loads the *user's own* instruction file, and
              .claude-plugin/plugin.json does not reference ours. tests/run-tests.sh
              has said so in a comment for a long time; this instrument disagreed
              with it and the instrument was wrong.

  contributor Someone working inside this repository. They additionally load the
              instruction file for the host they are on, because for them it is a
              project instruction file rather than plugin content.

Reporting only the contributor figure inflated the baseline by ~4x and made
"reduce ambient" look like it required deleting safety rules from CLAUDE.md.
Deleting them would save the plugin population exactly zero tokens. The number
worth driving down is the plugin figure, because every session on every host pays
it.

Token counting is a deterministic approximation (bytes/4), not a tokenizer call.
That is deliberate: the number must be reproducible on a clean cloud checkout
with no network and no third-party packages. A constant-factor bias cancels when
comparing two versions under identical measurement. The approximation is stated
wherever the number is reported; it is never presented as an exact token count.

Usage:
    measure_ambient.py                          # human-readable report, both populations
    measure_ambient.py --json                   # machine-readable
    measure_ambient.py --budget 2500            # gate the PLUGIN figure (the default scope)
    measure_ambient.py --budget 9000 --budget-scope contributor
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

BYTES_PER_TOKEN = 4.0

# The hook is fed a real SessionStart payload on stdin. Without it the script
# blocks indefinitely waiting on a read, which is defect D2 in the inventory;
# measuring with a proper payload is also simply the honest configuration,
# because it is what the host actually sends.
HOOK_PAYLOAD = {
    "hook_event_name": "SessionStart",
    "source": "startup",
    "cwd": REPO,
}


def approx_tokens(n_bytes: int) -> int:
    return int(round(n_bytes / BYTES_PER_TOKEN))


def file_cost(rel: str) -> dict:
    path = os.path.join(REPO, rel)
    if not os.path.exists(path):
        return {"path": rel, "present": False, "bytes": 0, "approx_tokens": 0}
    n = os.path.getsize(path)
    return {"path": rel, "present": True, "bytes": n, "approx_tokens": approx_tokens(n)}


def hook_cost(rel: str, timeout: int = 120) -> dict:
    path = os.path.join(REPO, rel)
    if not os.path.exists(path):
        return {"path": rel, "present": False, "bytes": 0, "approx_tokens": 0}

    try:
        proc = subprocess.run(
            ["bash", path],
            input=json.dumps(HOOK_PAYLOAD),
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd=REPO,
        )
    except subprocess.TimeoutExpired:
        return {
            "path": rel,
            "present": True,
            "bytes": 0,
            "approx_tokens": 0,
            "error": f"hook did not terminate within {timeout}s",
        }

    n = len(proc.stdout.encode("utf-8"))
    out = {
        "path": rel,
        "present": True,
        "bytes": n,
        "approx_tokens": approx_tokens(n),
        "exit_code": proc.returncode,
    }
    if proc.returncode != 0:
        out["error"] = f"hook exited {proc.returncode}"
    return out


def skill_frontmatter_cost() -> dict:
    """Cost of the skill frontmatter the host keeps visible so the model can choose.

    Previously counted as a bare integer, which assigned every skill description
    zero token cost. Skill name+description IS ambient: the host has to show it for
    routing to be possible, so it is paid on every session whether or not the skill
    is ever invoked.
    """
    skills_dir = os.path.join(REPO, "skills")
    if not os.path.isdir(skills_dir):
        return {"count": 0, "bytes": 0, "approx_tokens": 0, "unparsed": []}

    total, count, unparsed = 0, 0, []
    for entry in sorted(os.listdir(skills_dir)):
        path = os.path.join(skills_dir, entry, "SKILL.md")
        if not os.path.isfile(path):
            continue
        count += 1
        try:
            text = open(path, encoding="utf-8").read()
        except OSError:
            unparsed.append(entry)
            continue
        # Frontmatter is the host-visible part. Fall back to charging nothing rather
        # than guessing, but record it, so a parsing change cannot silently shrink
        # the measured cost.
        if text.startswith("---"):
            end = text.find("\n---", 3)
            if end != -1:
                total += len(text[: end + 4].encode("utf-8"))
                continue
        unparsed.append(entry)

    return {
        "count": count,
        "bytes": total,
        "approx_tokens": approx_tokens(total),
        "unparsed": unparsed,
    }


def measure() -> dict:
    instruction_files = [file_cost("CLAUDE.md"), file_cost("AGENTS.md")]
    hooks = [hook_cost(os.path.join("hooks", "scripts", "session-start.sh"))]

    # A session runs on ONE host, so it pays for one instruction file, not both.
    # Charging both would inflate the baseline, so the per-host worst case is used.
    per_host_instruction = max((f["approx_tokens"] for f in instruction_files), default=0)
    hook_total = sum(h["approx_tokens"] for h in hooks)
    skills = skill_frontmatter_cost()

    # The split that matters. See the module docstring for why these are separate.
    plugin_ambient = hook_total + skills["approx_tokens"]
    contributor_ambient = plugin_ambient + per_host_instruction

    return {
        "instruction_files": instruction_files,
        "hooks": hooks,
        "skills": skills,
        "instruction_tokens_per_host": per_host_instruction,
        "hook_tokens": hook_total,
        "skill_frontmatter_tokens": skills["approx_tokens"],
        "plugin_ambient_tokens": plugin_ambient,
        "contributor_ambient_tokens": contributor_ambient,
        "method": "approximate: utf-8 bytes / 4, deterministic and offline",
        "note": (
            "plugin ambient excludes this repo's CLAUDE.md/AGENTS.md: the host loads the "
            "user's own instruction file, and .claude-plugin/plugin.json does not reference ours"
        ),
    }


def main(argv=None):
    ap = argparse.ArgumentParser(description="Measure KERNEL ambient context cost.")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--budget", type=int, help="fail if the scoped ambient figure exceeds this")
    ap.add_argument(
        "--budget-scope",
        choices=("plugin", "contributor"),
        default="plugin",
        help="which population the budget applies to (default: plugin, the one everyone pays)",
    )
    args = ap.parse_args(argv)

    m = measure()
    scope_key = f"{args.budget_scope}_ambient_tokens"

    if args.json:
        print(json.dumps(m, indent=2))
    else:
        print("KERNEL ambient context cost")
        print("=" * 60)
        for h in m["hooks"]:
            err = f"  [{h['error']}]" if h.get("error") else ""
            print(f"  {h['path']:<40} {h['approx_tokens']:>6} tok{err}")
        sk = m["skills"]
        warn = f"  [{len(sk['unparsed'])} unparsed]" if sk["unparsed"] else ""
        print(f"  {'skill frontmatter (' + str(sk['count']) + ' skills)':<40} {sk['approx_tokens']:>6} tok{warn}")
        print("-" * 60)
        print(f"  {'PLUGIN AMBIENT (what users pay)':<40} {m['plugin_ambient_tokens']:>6} tok")
        print()
        for f in m["instruction_files"]:
            state = "" if f["present"] else "  (absent)"
            print(f"  {f['path'] + ' (contributors only)':<40} {f['approx_tokens']:>6} tok{state}")
        print(f"  {'instruction, per host':<40} {m['instruction_tokens_per_host']:>6} tok")
        print("-" * 60)
        print(f"  {'CONTRIBUTOR AMBIENT':<40} {m['contributor_ambient_tokens']:>6} tok")
        print(f"\n  method: {m['method']}")
        print(f"  note:   {m['note']}")

    if args.budget is not None:
        actual = m[scope_key]
        if actual > args.budget:
            print(
                f"\nOVER BUDGET [{args.budget_scope}]: {actual} tok > {args.budget} tok budget",
                file=sys.stderr,
            )
            return 1
        print(f"\nwithin budget [{args.budget_scope}]: {actual} tok <= {args.budget} tok")

    if m["skills"]["unparsed"]:
        print(
            f"\nMEASUREMENT ERROR: skill frontmatter unparsed, cost undercounted: "
            f"{', '.join(m['skills']['unparsed'])}",
            file=sys.stderr,
        )
        return 2

    for probe in m["instruction_files"] + m["hooks"]:
        if probe.get("error"):
            print(f"\nMEASUREMENT ERROR: {probe['path']}: {probe['error']}", file=sys.stderr)
            return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())
