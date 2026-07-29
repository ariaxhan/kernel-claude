#!/usr/bin/env python3
"""Measure KERNEL's ambient session-start context cost.

"Ambient" means everything the model pays for before it has done anything: the
always-loaded instruction file plus whatever the SessionStart hook prints into
the context window. This is the headline number Kernel 9 has to move, so it
needs an instrument rather than an estimate.

Token counting is a deterministic approximation (bytes/4), not a tokenizer call.
That is deliberate: the number must be reproducible on a clean cloud checkout
with no network and no third-party packages. It is used to compare Kernel 8
against Kernel 9 under identical measurement, so a constant-factor bias cancels.
The approximation is stated wherever the number is reported; it is never
presented as an exact token count.

Usage:
    measure_ambient.py                 # human-readable report
    measure_ambient.py --json          # machine-readable
    measure_ambient.py --budget 500    # exit 1 if ambient exceeds the budget
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


def measure() -> dict:
    instruction_files = [file_cost("CLAUDE.md"), file_cost("AGENTS.md")]
    hooks = [hook_cost(os.path.join("hooks", "scripts", "session-start.sh"))]

    # A session runs on ONE host, so it pays for one instruction file, not both.
    # Charging both would flatter Kernel 9 by inflating the baseline it is
    # measured against, so the per-host worst case is used instead.
    per_host_instruction = max((f["approx_tokens"] for f in instruction_files), default=0)
    hook_total = sum(h["approx_tokens"] for h in hooks)

    skills_dir = os.path.join(REPO, "skills")
    skill_count = (
        len([d for d in os.listdir(skills_dir)
             if os.path.isfile(os.path.join(skills_dir, d, "SKILL.md"))])
        if os.path.isdir(skills_dir) else 0
    )

    return {
        "instruction_files": instruction_files,
        "hooks": hooks,
        "instruction_tokens_per_host": per_host_instruction,
        "hook_tokens": hook_total,
        "ambient_tokens": per_host_instruction + hook_total,
        "always_visible_skills": skill_count,
        "method": "approximate: utf-8 bytes / 4, deterministic and offline",
    }


def main(argv=None):
    ap = argparse.ArgumentParser(description="Measure KERNEL ambient context cost.")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--budget", type=int, help="fail if ambient tokens exceed this")
    args = ap.parse_args(argv)

    m = measure()

    if args.json:
        print(json.dumps(m, indent=2))
    else:
        print("KERNEL ambient context cost")
        print("=" * 46)
        for f in m["instruction_files"]:
            state = "" if f["present"] else "  (absent)"
            print(f"  {f['path']:<28} {f['approx_tokens']:>6} tok{state}")
        for h in m["hooks"]:
            err = f"  [{h['error']}]" if h.get("error") else ""
            print(f"  {h['path']:<28} {h['approx_tokens']:>6} tok{err}")
        print("-" * 46)
        print(f"  {'instruction (per host)':<28} {m['instruction_tokens_per_host']:>6} tok")
        print(f"  {'session-start hooks':<28} {m['hook_tokens']:>6} tok")
        print(f"  {'AMBIENT TOTAL':<28} {m['ambient_tokens']:>6} tok")
        print(f"  {'always-visible skills':<28} {m['always_visible_skills']:>6}")
        print(f"\n  method: {m['method']}")

    if args.budget is not None:
        if m["ambient_tokens"] > args.budget:
            print(
                f"\nOVER BUDGET: {m['ambient_tokens']} tok > {args.budget} tok budget",
                file=sys.stderr,
            )
            return 1
        print(f"\nwithin budget: {m['ambient_tokens']} tok <= {args.budget} tok")

    for probe in m["instruction_files"] + m["hooks"]:
        if probe.get("error"):
            print(f"\nMEASUREMENT ERROR: {probe['path']}: {probe['error']}", file=sys.stderr)
            return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())
