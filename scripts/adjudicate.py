#!/usr/bin/env python3
"""KERNEL verdict adjudicator: the critic proposes, this decides.

    python3 scripts/adjudicate.py findings.json          # -> verdict JSON on stdout
    python3 scripts/adjudicate.py findings.json --strict  # exit 1 if the verdict is FAIL

Why this is code and not a prompt
--------------------------------
Review has no natural stopping condition. An agent asked to find problems answers "can I find
anything else?", never "is this shippable?", so the loop never closes. The fix is not a better
reviewer, it is an acceptance function that the reviewer does not get to be.

Three defect classes this exists to kill, each bought with a real incident:

1. Flat severity. Ten review phases each able to veto independently means every finding blocks,
   and when every finding blocks the cheapest way to keep shipping is an instrument that finds
   little. Flat severity selects for weak instruments.
2. A distance cutoff that suppresses the best reviews. The highest-value review in this ecosystem
   (2026-08-03, "buried it under a genre with no market") was distance-3. A hard "distance >= 2
   cannot block" rule auto-closes it. So distance sets a PROOF THRESHOLD, never a veto ceiling.
3. Silent coverage. A gate that passes without declaring what it could not check reads as
   coverage. An unfinished instrument is red, never neutral: "we could not reproduce it" and
   "it is not a problem" are different sentences.

Refs: ariaxhan/kernel-claude#204.
"""

import argparse
import json
import sys

SCHEMA = "kernel.verdict/v1"

# distance -> what that finding must carry before it may block.
# Distance never decides WHETHER a finding may block, only how much proof it needs.
PROOF = {
    0: ("repro",),                        # the changed code fails: pasted output
    1: ("repro",),                        # violates a declared invariant: pasted output
    2: ("repro", "consequence"),          # pre-existing, exposed here: needs a user-visible cost
    3: ("repro", "evidence_kind"),        # outside assumptions: needs hard evidence, not taste
}

# What counts as hard evidence at distance 3+. Taste never clears this bar; a playtest record does.
STRONG_EVIDENCE = {"executed_demonstration", "cited_prior_failure", "observed_outcome"}

BLOCKING_SEVERITY = {"blocker"}


def _norm_distance(value):
    """Distance 4+ is treated as 3: the proof bar does not keep rising, it saturates."""
    try:
        d = int(value)
    except (TypeError, ValueError):
        return None
    return 3 if d > 3 else (d if d >= 0 else None)


def evaluate(finding):
    """Return (blocks: bool, reasons: list[str]). Reasons explain a REFUSAL to block."""
    reasons = []

    if finding.get("severity") not in BLOCKING_SEVERITY:
        reasons.append(f"severity {finding.get('severity')!r} is not blocking")

    if finding.get("on_objective") is not True:
        reasons.append("off-objective: real, but not what this project is for")

    validated = finding.get("validated")
    if validated != "proven":
        reasons.append(f"validated={validated!r}; criticism is not evidence")

    if not str(finding.get("observable") or "").strip():
        reasons.append("no observable failure named (the stopping wager)")

    distance = _norm_distance(finding.get("distance"))
    if distance is None:
        reasons.append("distance missing or malformed")
    else:
        for field in PROOF[distance]:
            value = finding.get(field)
            if field == "evidence_kind":
                if value not in STRONG_EVIDENCE:
                    reasons.append(
                        f"distance {finding.get('distance')} needs evidence_kind in "
                        f"{sorted(STRONG_EVIDENCE)}, got {value!r}"
                    )
            elif not str(value or "").strip():
                reasons.append(f"distance {finding.get('distance')} requires {field}")

    return (not reasons), reasons


def adjudicate(doc):
    findings = doc.get("findings") or []
    cannot_falsify = [c for c in (doc.get("cannot_falsify") or []) if str(c).strip()]

    blocking, quarantined, escalate = [], [], []
    for finding in findings:
        entry = dict(finding)
        if finding.get("validated") == "unverifiable":
            # Neither reproduced nor refuted. It does not block by default and it does not vanish
            # into a backlog either; the signer waives in writing or blocks. Silence is not an
            # option, because that is how an interrupted check becomes a pass.
            entry["routed"] = "escalate"
            escalate.append(entry)
            continue
        blocks, reasons = evaluate(finding)
        if blocks:
            entry["routed"] = "blocking"
            blocking.append(entry)
        else:
            entry["routed"] = "quarantine"
            entry["not_blocking_because"] = reasons
            quarantined.append(entry)

    errors = []
    if not cannot_falsify:
        # Enforced on every verdict, not only on PASS: a FAIL with unknown coverage is still a
        # claim about the world. Silence about coverage reads as coverage.
        errors.append(
            "cannot_falsify is empty. State what no instrument here could see, "
            "or the verdict is not a verdict."
        )

    verdict = "FAIL" if blocking else "PASS"
    if errors:
        verdict = "INVALID"

    return {
        "schema": SCHEMA,
        "verdict": verdict,
        "objective": doc.get("objective"),
        "blocking": blocking,
        "quarantined": quarantined,
        "escalate": escalate,
        "cannot_falsify": cannot_falsify,
        "errors": errors,
        "counts": {
            "proposed": len(findings),
            "blocking": len(blocking),
            "quarantined": len(quarantined),
            "escalate": len(escalate),
        },
        # Yield weighted by consequence, not count: a pass returning one blocker is worth more
        # than one returning nine nits, and a raw count would have stopped the genre review.
        "validation_rate": round(
            sum(1 for f in findings if f.get("validated") == "proven") / len(findings), 3
        ) if findings else None,
    }


def render(result):
    lines = [f"ADVERSARY: {result['verdict']}"]
    for f in result["blocking"]:
        lines.append(f"  BLOCK  d{f.get('distance')} {f.get('summary','(no summary)')}")
    for f in result["escalate"]:
        lines.append(f"  ESCALATE (unverifiable) {f.get('summary','(no summary)')}")
    for f in result["quarantined"]:
        lines.append(f"  quarantine  {f.get('summary','(no summary)')}")
        for r in f.get("not_blocking_because", []):
            lines.append(f"      - {r}")
    lines.append("CANNOT FALSIFY:")
    for c in result["cannot_falsify"] or ["  (NONE DECLARED - this verdict is INVALID)"]:
        lines.append(f"  - {c}")
    for e in result["errors"]:
        lines.append(f"ERROR: {e}")
    return "\n".join(lines)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("findings", help="path to a findings JSON document, or - for stdin")
    ap.add_argument("--strict", action="store_true",
                    help="exit 1 on FAIL, 2 on INVALID (for use as a gate)")
    ap.add_argument("--text", action="store_true", help="human-readable output instead of JSON")
    args = ap.parse_args(argv)

    raw = sys.stdin.read() if args.findings == "-" else open(args.findings).read()
    try:
        doc = json.loads(raw)
    except json.JSONDecodeError as exc:
        print(f"ERROR: findings document is not valid JSON: {exc}", file=sys.stderr)
        return 2

    result = adjudicate(doc)
    print(render(result) if args.text else json.dumps(result, indent=2))

    if args.strict:
        if result["verdict"] == "INVALID":
            return 2
        if result["verdict"] == "FAIL":
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
