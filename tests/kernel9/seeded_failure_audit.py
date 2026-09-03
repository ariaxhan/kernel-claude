#!/usr/bin/env python3
"""Seeded-failure audit for the KERNEL 9 router test suite.

A green instrument proves nothing until it has failed on purpose. This harness
injects known defects into the router and asserts the test suite catches each
one, naming the specific test that must fail.

The seeded failure is applied to an ISOLATED COPY in a temp directory, never to
the live tree. Mutating a live instrument in place contaminates its own output
store; that mistake produced a false verified claim in this repo on 2026-07-29.

Exit 0 means every seeded defect was caught. Exit 1 means the suite has a blind
spot, and any green result from it is inadmissible.
"""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROUTER_REL = os.path.join("orchestration", "router", "kernel_router.py")
TESTS_REL = os.path.join("tests", "kernel9", "test_router.py")
SCHEMA_REL = os.path.join("schemas", "kernel.classification.v1.json")


class Mutation:
    def __init__(
        self,
        name,
        target,
        old,
        new,
        must_fail,
        rationale,
        suite="test_router",
    ):
        self.name = name
        self.target = target      # "router" or "schema"
        self.old = old
        self.new = new
        self.must_fail = must_fail  # test that must catch it
        self.rationale = rationale
        self.suite = suite


MUTATIONS = [
    Mutation(
        "safety-reads-work-shape",
        "router",
        'def classify_safety(text: str, hint: str | None = None) -> tuple[str, float, list[str]]:',
        'def classify_safety(text: str, hint: str | None = None, _shape=None) -> tuple[str, float, list[str]]:\n    if "iterate" in text.lower():\n        return "normal", 0.9, ["seeded: safety leaked into work shape"]',
        "test_protected_and_trajectory_coexist",
        "safety must never be a function of work shape",
    ),
    Mutation(
        "derisking-clears-protected",
        "router",
        "    if protected_score >= PROTECTED_THRESHOLD:",
        "    if protected_score >= PROTECTED_THRESHOLD and not normal_score:",
        "test_derisking_language_cannot_flip_protected",
        "safety must fail closed; de-risking words must not clear a real hazard",
    ),
    Mutation(
        "lighter-downgrades-safety",
        "router",
        '    if direction == "lighter":\n        new_idx = max(0, idx - 1)',
        '    if direction == "lighter":\n        new_idx = max(0, idx - 1)\n        out["safety"] = "normal"',
        "test_lighter_cannot_clear_protected",
        "/kernel:lighter must never bypass the safety overlay",
    ),
    Mutation(
        "always-announce",
        "router",
        '    out["announced"] = bool(\n        shape != "direct"',
        '    out["announced"] = bool(\n        True or shape != "direct"',
        "test_direct_normal_work_is_silent",
        "routine direct work must not narrate internal machinery",
    ),
    Mutation(
        "trajectory-wins-ties",
        "router",
        '    ranked = sorted(scored.items(), key=lambda kv: (-kv[1], ["direct", "gated", "trajectory"].index(kv[0])))',
        '    ranked = sorted(scored.items(), key=lambda kv: (-kv[1], -["direct", "gated", "trajectory"].index(kv[0])))',
        "test_ties_fall_to_the_lighter_shape",
        "trajectory must be earned by repeated feedback, not won on a tie",
    ),
    Mutation(
        "protected-skips-verification",
        "router",
        '    if safety == "protected":\n        out["verification"] = {',
        '    if False and safety == "protected":\n        out["verification"] = {',
        "test_protected_always_names_verification",
        "protected work must name how safe is distinguished from unsafe",
    ),
    Mutation(
        "tests-language-for-non-code",
        "router",
        '    "writing": "read the revised text against the brief; blinded pairwise comparison for tone changes",',
        '    "writing": "run the test suite and check it compiles",',
        "test_verification_language_is_domain_appropriate",
        "non-code domains must never receive tests/git/compile ceremony",
    ),
    Mutation(
        "adjust-mutates-input",
        "router",
        '    out = json.loads(json.dumps(classification))',
        '    out = classification',
        "test_adjust_does_not_mutate_input",
        "mode transitions must not corrupt the caller's classification",
    ),
    Mutation(
        "direct-loses-escalation-exit",
        "router",
        '    if shape in ESCALATE_DEFAULTS:',
        '    if False and shape in ESCALATE_DEFAULTS:',
        "test_direct_still_names_its_escalation_exit",
        "a mode with no exit condition cannot adapt to reality",
    ),
    Mutation(
        "trajectory-loses-deescalation-exit",
        "router",
        '    if shape in DEESCALATE_DEFAULTS:',
        '    if False and shape in DEESCALATE_DEFAULTS:',
        "test_trajectory_names_its_own_exit",
        "trajectory is a gear, not the permanent operating system",
    ),
]


def build_sandbox(tmp):
    """Copy only what the suite needs into an isolated tree."""
    for rel in (ROUTER_REL, TESTS_REL, SCHEMA_REL):
        dst = os.path.join(tmp, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(os.path.join(REPO, rel), dst)


def run_suite(tmp, only=None, suite="test_router"):
    """Run the copied suite inside the sandbox. Returns (returncode, output)."""
    target = suite if only is None else f"{suite}.{only}"
    proc = subprocess.run(
        [sys.executable, "-m", "unittest", target, "-v"],
        cwd=os.path.join(tmp, "tests", "kernel9"),
        capture_output=True,
        text=True,
        env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"},
    )
    return proc.returncode, proc.stdout + proc.stderr


def apply_mutation(tmp, mut):
    rel = {
        "router": ROUTER_REL,
        "schema": SCHEMA_REL,
    }[mut.target]
    path = os.path.join(tmp, rel)
    with open(path) as fh:
        src = fh.read()
    if mut.old not in src:
        return False
    with open(path, "w") as fh:
        fh.write(src.replace(mut.old, mut.new, 1))
    return True


def main():
    results = []

    # Control: the unmutated copy must pass in the sandbox. If it does not, the
    # sandbox itself is broken and every downstream reading is meaningless.
    with tempfile.TemporaryDirectory(prefix="kernel9-audit-control-") as tmp:
        build_sandbox(tmp)
        rc, out = run_suite(tmp)
        if rc != 0:
            print("CONTROL FAILED: clean sandbox does not pass. Audit is invalid.")
            print(out[-3000:])
            return 1
        total = re.search(r"Ran (\d+) tests", out)
        print(f"control: clean sandbox passes ({total.group(1) if total else '?'} tests)\n")

    for mut in MUTATIONS:
        with tempfile.TemporaryDirectory(prefix=f"kernel9-audit-{mut.name}-") as tmp:
            build_sandbox(tmp)

            if not apply_mutation(tmp, mut):
                results.append((mut, "STALE", "anchor text not found; mutation did not apply"))
                print(f"  {mut.name}: STALE (anchor text not found)")
                continue

            rc, out = run_suite(tmp, suite=mut.suite)

            if rc == 0:
                results.append((mut, "MISSED", "suite still passed with the defect present"))
                print(f"  {mut.name}: MISSED - suite passed with the defect present")
                continue

            # Catching the defect is necessary but not sufficient: the *named*
            # test must be the one that fires, otherwise coverage is accidental.
            if mut.must_fail in out:
                results.append((mut, "CAUGHT", mut.must_fail))
                print(f"  {mut.name}: CAUGHT by {mut.must_fail}")
            else:
                results.append((mut, "WRONG-TEST", "suite failed, but not via the named test"))
                print(f"  {mut.name}: WRONG-TEST - failed, but {mut.must_fail} did not fire")

    print()
    caught = sum(1 for _, s, _ in results if s == "CAUGHT")
    print("=" * 60)
    print(f"Seeded-failure audit: {caught}/{len(MUTATIONS)} defects caught by the named test")
    print("=" * 60)

    if caught != len(MUTATIONS):
        print("\nBlind spots:")
        for mut, status, detail in results:
            if status != "CAUGHT":
                print(f"  - {mut.name} [{status}]: {detail}")
                print(f"      invariant: {mut.rationale}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
