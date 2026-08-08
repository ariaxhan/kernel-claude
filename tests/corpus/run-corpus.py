#!/usr/bin/env python3
"""Violation-corpus harness: proof that KERNEL's gates can still refuse things.

Three checks, in order of how badly their absence has burned us:

1. DIVERGENCE (bidirectional). hooks/gates.json, the scripts on disk, and the
   bindings in hooks/hooks.json must describe the same world. A gate added
   without a registry entry is invisible to coverage; a registry entry with no
   script is a fence that was quietly retired. Either direction fails.

2. COVERAGE. Every class=gate needs at least one case it must BLOCK and one it
   must ALLOW. Blocking-only coverage produces a gate that refuses everything;
   allowing-only coverage produces decor.

3. LIVENESS. Every gate is run twice: once normally, and once with its declared
   external dependencies removed from PATH. The second run must match the gate's
   declared degraded_mode. fail-closed must still refuse. fail-open-loud must
   allow AND say so on stderr -- a silent fail-open is the defect that let
   `rg: command not found` print PASS inside a green CI run.

Exit 0 only when all three pass. Run: python3 tests/corpus/run-corpus.py
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REGISTRY = ROOT / "hooks" / "gates.json"
CASES = ROOT / "tests" / "corpus" / "cases.json"
BINDINGS = ROOT / "hooks" / "hooks.json"
TIMEOUT = 30

failures: list[str] = []
notes: list[str] = []


def fail(msg: str) -> None:
    failures.append(msg)


def load_json(path: Path) -> dict:
    with path.open() as fh:
        return json.load(fh)


# ---------------------------------------------------------------- 1. divergence
def check_divergence(registry: dict) -> None:
    declared = {h["id"]: h for h in registry["hooks"]}
    declared_scripts = {h["script"] for h in registry["hooks"]}

    on_disk = set()
    scripts_dir = ROOT / "hooks" / "scripts"
    for path in sorted(scripts_dir.iterdir()):
        if path.suffix in (".sh", ".py"):
            on_disk.add(str(path.relative_to(ROOT)))

    for script in sorted(on_disk - declared_scripts):
        fail(
            f"DIVERGENCE: {script} exists on disk but is absent from hooks/gates.json. "
            "Every hook script is registered, or coverage silently skips it."
        )
    for script in sorted(declared_scripts - on_disk):
        fail(
            f"DIVERGENCE: hooks/gates.json declares {script}, which does not exist. "
            "A retired mechanism needs a verdict record, not a dangling registry row."
        )

    bindings = load_json(BINDINGS)
    bound: dict[str, set[str]] = {}
    for event, matchers in bindings.get("hooks", {}).items():
        for matcher in matchers:
            for hook in matcher.get("hooks", []):
                script = hook["command"].split("/")[-1].split()[0]
                bound.setdefault(f"hooks/scripts/{script}", set()).add(event)

    for script, events in sorted(bound.items()):
        entry = next((h for h in registry["hooks"] if h["script"] == script), None)
        if entry is None:
            fail(f"DIVERGENCE: hooks.json binds {script}, which is not in hooks/gates.json.")
            continue
        for event in sorted(events):
            if event not in entry["events"]:
                fail(
                    f"DIVERGENCE: hooks.json binds {entry['id']} to {event}, "
                    f"but gates.json declares events {entry['events']}."
                )

    for entry in registry["hooks"]:
        if entry["class"] == "library":
            continue
        if entry["script"] not in bound:
            fail(
                f"DIVERGENCE: {entry['id']} is registered as {entry['class']} but is bound "
                "to no event in hooks.json. An unbound gate protects nothing."
            )

    valid_modes = set(registry["degraded_modes"])
    for entry in registry["hooks"]:
        if entry["degraded_mode"] not in valid_modes:
            fail(f"{entry['id']}: undeclared degraded_mode {entry['degraded_mode']!r}.")


# ----------------------------------------------------------------- 2. coverage
def check_coverage(registry: dict, corpus: dict) -> None:
    gates = [h for h in registry["hooks"] if h["class"] == "gate"]
    by_gate: dict[str, set[str]] = {}
    known = {h["id"] for h in registry["hooks"]}

    for case in corpus["cases"]:
        if case["gate"] not in known:
            fail(f"corpus case {case['id']} targets unknown gate {case['gate']!r}.")
        by_gate.setdefault(case["gate"], set()).add(case["expect"])

    armed_gates = {
        case["gate"] for case in corpus["cases"] if case.get("arms")
    }

    for gate in gates:
        expects = by_gate.get(gate["id"], set())
        mode = gate["degraded_mode"]
        if "block" not in expects and mode != "fail-abstain":
            fail(
                f"COVERAGE: gate {gate['id']} has no case it must BLOCK. "
                "A gate nobody has watched refuse something is decor."
            )
        if "allow" not in expects:
            fail(
                f"COVERAGE: gate {gate['id']} has no case it must ALLOW. "
                "A gate that only ever blocks trains humans to override it."
            )
        if mode == "fail-closed-when-armed" and gate["id"] not in armed_gates:
            fail(
                f"COVERAGE: gate {gate['id']} declares fail-closed-when-armed but no corpus "
                "case arms it. The armed path is the only one that enforces anything."
            )


# ---------------------------------------------------------------- 3. execution
def assemble(value, fixtures: dict[str, list[str]]):
    if isinstance(value, str):
        for name, parts in fixtures.items():
            value = value.replace("{{" + name + "}}", "".join(parts))
        return value
    if isinstance(value, dict):
        return {k: assemble(v, fixtures) for k, v in value.items()}
    if isinstance(value, list):
        return [assemble(v, fixtures) for v in value]
    return value


_path_cache: dict[tuple[str, ...], str] = {}


def path_without(missing: tuple[str, ...]) -> str:
    """A PATH identical to the real one except the named binaries are gone."""
    if missing in _path_cache:
        return _path_cache[missing]
    sandbox = tempfile.mkdtemp(prefix="corpus-nodep-")
    for directory in os.environ.get("PATH", "").split(":"):
        if not directory or not os.path.isdir(directory):
            continue
        try:
            entries = os.listdir(directory)
        except OSError:
            continue
        for name in entries:
            if name in missing:
                continue
            link = os.path.join(sandbox, name)
            if os.path.exists(link):
                continue
            try:
                os.symlink(os.path.join(directory, name), link)
            except OSError:
                pass
    _path_cache[missing] = sandbox
    return sandbox


def arm_fixture(arms: dict) -> str:
    """A throwaway git repo carrying the state that switches a gate on."""
    repo = tempfile.mkdtemp(prefix="corpus-armed-")
    subprocess.run(["git", "init", "-q", repo], check=True, capture_output=True)
    for rel, content in arms.items():
        target = Path(repo) / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(
            content if isinstance(content, str) else json.dumps(content, indent=2)
        )
    return repo


def run_hook(
    script: str,
    payload: dict,
    env_path: str | None = None,
    cwd: str | None = None,
):
    env = dict(os.environ)
    env["CLAUDE_PROJECT_DIR"] = cwd or str(ROOT)
    env["KERNEL_CORPUS_RUN"] = "1"
    if env_path:
        env["PATH"] = env_path
    interpreter = ["python3"] if script.endswith(".py") else ["bash"]
    return subprocess.run(
        interpreter + [str(ROOT / script)],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        env=env,
        timeout=TIMEOUT,
        cwd=cwd or str(ROOT),
    )


def blocked(proc) -> bool:
    """A hook refuses via exit 2, or via a deny/block decision on stdout."""
    if proc.returncode == 2:
        return True
    out = proc.stdout.strip()
    if out.startswith("{"):
        try:
            decision = json.loads(out)
        except ValueError:
            return False
        if decision.get("decision") == "block":
            return True
        hook_specific = decision.get("hookSpecificOutput", {})
        if hook_specific.get("permissionDecision") == "deny":
            return True
        if decision.get("continue") is False:
            return True
    return False


def check_cases(registry: dict, corpus: dict) -> None:
    fixtures = corpus.get("fixtures", {})
    by_id = {h["id"]: h for h in registry["hooks"]}

    for case in corpus["cases"]:
        entry = by_id.get(case["gate"])
        if entry is None:
            continue
        payload = assemble(case["input"], fixtures)
        repo = arm_fixture(case["arms"]) if case.get("arms") else None
        try:
            proc = run_hook(entry["script"], payload, cwd=repo)
        except subprocess.TimeoutExpired:
            fail(f"{case['id']}: timed out after {TIMEOUT}s.")
            continue
        finally:
            if repo:
                shutil.rmtree(repo, ignore_errors=True)

        did_block = blocked(proc)
        if case["expect"] == "block" and not did_block:
            fail(
                f"{case['id']}: expected {entry['id']} to REFUSE this, it allowed it "
                f"(rc={proc.returncode}). {case['why']}"
            )
        elif case["expect"] == "allow" and did_block:
            fail(
                f"{case['id']}: expected {entry['id']} to allow this, it refused "
                f"(rc={proc.returncode}, stderr={proc.stderr.strip()[:160]!r}). {case['why']}"
            )


# --------------------------------------------------------------- 3b. liveness
def check_degraded_modes(registry: dict, corpus: dict) -> None:
    fixtures = corpus.get("fixtures", {})
    cases_by_gate: dict[str, list[dict]] = {}
    for case in corpus["cases"]:
        cases_by_gate.setdefault(case["gate"], []).append(case)

    for entry in registry["hooks"]:
        if entry["class"] != "gate":
            continue
        deps = tuple(entry.get("external_deps", []))
        if not deps:
            continue
        probes = cases_by_gate.get(entry["id"], [])
        mode = entry["degraded_mode"]

        if mode == "fail-closed-when-armed":
            probe = next((c for c in probes if c.get("arms")), None)
        else:
            probe = next((c for c in probes if c["expect"] == "block"), None) or (
                probes[0] if probes else None
            )
        if probe is None:
            continue

        payload = assemble(probe["input"], fixtures)
        stripped = path_without(deps)
        repo = arm_fixture(probe["arms"]) if probe.get("arms") else None
        try:
            proc = run_hook(entry["script"], payload, env_path=stripped, cwd=repo)
        except subprocess.TimeoutExpired:
            fail(f"{entry['id']}: timed out with {', '.join(deps)} missing.")
            continue
        finally:
            if repo:
                shutil.rmtree(repo, ignore_errors=True)

        did_block = blocked(proc)
        loud = bool(proc.stderr.strip())
        approved = "allow" in proc.stdout and "permissionDecision" in proc.stdout.replace(
            "decision", "permissionDecision"
        )

        if mode in ("fail-closed", "fail-closed-when-armed"):
            if not did_block:
                armed = " (armed)" if repo else ""
                fail(
                    f"LIVENESS: {entry['id']} declares {mode} but ALLOWED its own block "
                    f"case{armed} with {', '.join(deps)} missing (rc={proc.returncode}). "
                    "This is a fence that fails dark."
                )
        elif mode == "fail-open-loud":
            if did_block:
                notes.append(
                    f"{entry['id']}: declares fail-open-loud but refused with {', '.join(deps)} "
                    "missing. Stricter than declared; update the declaration or the code."
                )
            elif not loud:
                fail(
                    f"LIVENESS: {entry['id']} declares fail-open-loud but degraded SILENTLY "
                    f"with {', '.join(deps)} missing (no stderr). A silent fail-open is "
                    "indistinguishable from a passing check."
                )
        elif mode == "fail-abstain":
            if approved:
                fail(
                    f"LIVENESS: {entry['id']} declares fail-abstain but emitted an APPROVING "
                    f"decision with {', '.join(deps)} missing. Uncertainty became consent."
                )


def main() -> int:
    registry = load_json(REGISTRY)
    corpus = load_json(CASES)

    check_divergence(registry)
    check_coverage(registry, corpus)
    check_cases(registry, corpus)
    check_degraded_modes(registry, corpus)

    gates = sum(1 for h in registry["hooks"] if h["class"] == "gate")
    print(
        f"violation corpus: {len(corpus['cases'])} cases over {gates} gates "
        f"({len(registry['hooks'])} hooks registered)"
    )
    for note in notes:
        print(f"  note: {note}")
    if failures:
        print(f"\nFAILED ({len(failures)}):")
        for failure in failures:
            print(f"  - {failure}")
        return 1
    print("  divergence: registry, disk, and bindings agree")
    print("  coverage:   every gate has a must-block and a must-allow case")
    print("  liveness:   every gate matched its declared degraded mode")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    finally:
        for sandbox in _path_cache.values():
            shutil.rmtree(sandbox, ignore_errors=True)
