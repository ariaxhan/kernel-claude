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

Two later additions, same shape:

4. Context-blind severity. A finding's weight depends on what the artifact IS. An acceptance
   profile (kernel.acceptance-profile/v1) states that context in structured dimensions, and a
   finding must clear the evidence bar AND violate the profile to block. The stage label is
   deliberately NOT consulted: a demo handling real people's data still requires production-grade
   privacy.
5. No finality. Every fresh context was a reviewer with amnesia, free to relitigate settled
   questions. An acceptance record (kernel.acceptance/v1) freezes one exact commit under one exact
   profile; reopening takes a recognised event, not a new opinion.

Refs: ariaxhan/kernel-claude#204.
"""

import argparse
import hashlib
import json
import sys

SCHEMA = "kernel.verdict/v1"

# Severity ladder. A profile names the minimum severity that blocks per dimension, so the same
# finding is blocking in one context and quarantined in another without anyone editing the finding.
SEVERITY_ORDER = ["nit", "minor", "major", "blocker"]

# An omitted dimension defaults to the strictest real setting. Silence in a profile must never
# quietly widen what ships, which is the failure mode of every "we'll decide later" severity.
DEFAULT_BLOCKS_AT = "blocker"

# The only events that may reopen a frozen acceptance. A fresh reviewer, a rephrased concern, or a
# different architectural preference is deliberately not on this list: those are exactly what an
# amnesiac critic produces for free, and letting them reopen settled work is the tax.
REOPEN_EVENTS = {
    "new_failing_input",
    "changed_dependency",
    "missed_requirement",
    "disproven_assumption",
    "profile_changed",
    "owner_promotion",
}

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


def profile_hash(profile):
    """Stable hash of the judged-against context. A changed profile voids an old acceptance."""
    if not profile:
        return None
    material = {k: v for k, v in profile.items() if k not in ("schema", "owner")}
    return hashlib.sha256(
        json.dumps(material, sort_keys=True, separators=(",", ":")).encode()
    ).hexdigest()[:16]


def violates_profile(finding, profile):
    """Return (violates: bool, reason: str|None).

    Without a profile this returns True unconditionally, preserving the pre-profile behaviour:
    the bar alone decides. That is deliberate back-compat, not a default-open, because the
    evidence/distance/observable bar still has to be cleared either way.
    """
    if not profile:
        return True, None

    dimension = finding.get("dimension") or "correctness"
    mode = finding.get("failure_mode")
    accepted = profile.get("acceptable_failure_modes") or []
    if mode and mode in accepted:
        # Someone already decided this one, in writing, before the review ran.
        return False, f"failure mode {mode!r} is an accepted failure mode of this profile"

    blocks_at = (profile.get("blocks_at") or {}).get(dimension, DEFAULT_BLOCKS_AT)
    if blocks_at == "never":
        return False, f"profile tolerates any {dimension} finding (blocks_at: never)"

    severity = finding.get("severity")
    if severity not in SEVERITY_ORDER or blocks_at not in SEVERITY_ORDER:
        return False, f"profile requires {dimension} >= {blocks_at}, got severity {severity!r}"

    if SEVERITY_ORDER.index(severity) < SEVERITY_ORDER.index(blocks_at):
        return False, (
            f"profile blocks {dimension} only at {blocks_at} or above; this is {severity}"
        )
    return True, None


def _norm_distance(value):
    """Distance 4+ is treated as 3: the proof bar does not keep rising, it saturates."""
    try:
        d = int(value)
    except (TypeError, ValueError):
        return None
    return 3 if d > 3 else (d if d >= 0 else None)


def evaluate(finding, profile=None):
    """Return (blocks: bool, reasons: list[str]). Reasons explain a REFUSAL to block.

    Two independent gates, both required. The evidence bar asks "is this finding real enough to
    act on"; the profile asks "does it matter for THIS artifact". A proven distance-0 blocker that
    the profile tolerates is still not a blocker, and a finding the profile cares about deeply is
    still not a blocker without evidence.
    """
    reasons = []

    if not profile and finding.get("severity") not in BLOCKING_SEVERITY:
        # With no profile, "only blocker blocks" is the fallback threshold. That constant was
        # always a stand-in for a profile nobody had written: once one exists, the owner declares
        # the blocking threshold per dimension and violates_profile() applies it. Still a
        # threshold, still one level, just a declared one instead of a hardcoded one.
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

    ok, why = violates_profile(finding, profile)
    if not ok:
        reasons.append(why)

    return (not reasons), reasons


def check_finality(doc):
    """Is this commit frozen by a prior acceptance, and if so may this run reopen it?

    Returns (frozen: bool, notes: list[str]). Frozen means ordinary re-review is refused: the
    findings still get adjudicated and reported, but they cannot produce a FAIL, because a fresh
    reviewer with no new evidence is not a new fact about the world.
    """
    acceptance = doc.get("acceptance")
    if not acceptance:
        return False, []

    notes = []
    commit = doc.get("commit")
    if commit and acceptance.get("commit") and commit != acceptance["commit"]:
        # Acceptance is never inherited. A later commit is a different artifact.
        return False, [
            f"acceptance covers {acceptance['commit'][:12]}, this is {commit[:12]}: not frozen"
        ]

    current = profile_hash(doc.get("profile"))
    recorded = acceptance.get("profile_hash")
    if current and recorded and current != recorded:
        # The profile it was judged against no longer exists, so the answer no longer applies.
        return False, [
            f"acceptance profile changed ({recorded} -> {current}): prior acceptance is void, "
            "re-review is required rather than merely permitted"
        ]

    event = (doc.get("reopen") or {}).get("event")
    if event:
        if event in REOPEN_EVENTS:
            detail = (doc.get("reopen") or {}).get("detail") or ""
            if not str(detail).strip():
                return True, [f"reopen event {event!r} carries no detail: refused, still frozen"]
            return False, [f"reopened on {event}: {detail}"]
        return True, [
            f"{event!r} is not a reopen event. Recognised: {sorted(REOPEN_EVENTS)}. "
            "A new reviewer, a rephrased concern, or a different architectural preference is not "
            "new evidence."
        ]

    return True, [
        f"commit {acceptance.get('commit', '?')[:12]} was accepted under profile "
        f"{acceptance.get('profile_id', '?')!r} at {acceptance.get('accepted_at', '?')}. "
        "Frozen from ordinary re-review; reopening requires new evidence, not a new opinion."
    ]


def adjudicate(doc):
    findings = doc.get("findings") or []
    profile = doc.get("profile")
    cannot_falsify = [c for c in (doc.get("cannot_falsify") or []) if str(c).strip()]
    frozen, finality_notes = check_finality(doc)
    settled = {
        str(f.get("summary", "")).strip().lower()
        for f in ((doc.get("acceptance") or {}).get("known_non_blockers") or [])
    }

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
        blocks, reasons = evaluate(finding, profile)
        if blocks and str(finding.get("summary", "")).strip().lower() in settled:
            blocks = False
            reasons = ["already a known non-blocker in the acceptance record for this commit"]
        if blocks and frozen:
            blocks = False
            reasons = ["commit is frozen by a recorded acceptance; no recognised reopen event"]
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

    missing_evidence = []
    if profile:
        supplied = {str(e).strip().lower() for e in (doc.get("evidence") or [])}
        missing_evidence = [
            e for e in (profile.get("required_evidence") or [])
            if str(e).strip().lower() not in supplied
        ]

    verdict = "FAIL" if blocking else "PASS"
    if errors:
        verdict = "INVALID"

    return {
        "schema": SCHEMA,
        "verdict": verdict,
        "objective": doc.get("objective"),
        "profile_id": (profile or {}).get("id"),
        "profile_hash": profile_hash(profile),
        "frozen": frozen,
        "finality": finality_notes,
        "missing_required_evidence": missing_evidence,
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
    if result.get("profile_id"):
        lines.append(f"  profile: {result['profile_id']} ({result.get('profile_hash')})")
    if result.get("frozen"):
        lines.append("  FROZEN: this commit was already accepted. Ordinary re-review refused.")
    for note in result.get("finality") or []:
        lines.append(f"    {note}")
    for missing in result.get("missing_required_evidence") or []:
        lines.append(f"  MISSING REQUIRED EVIDENCE: {missing}")
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
