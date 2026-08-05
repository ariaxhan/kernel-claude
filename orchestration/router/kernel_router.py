#!/usr/bin/env python3
"""KERNEL 9 adaptive execution router.

Chooses the smallest process capable of safely completing a task, across three
independent dimensions: domain, work_shape, safety.

Design constraints this file is built against:

- Deterministic. Same input, same classification. This is what the router test
  suite pins; model judgment layers on top but never replaces the floor.
- Fail-closed on safety. A protected signal is never averaged away by normal
  signals. Safety is independent of work shape by construction: they are scored
  in separate passes that cannot read each other's totals.
- Inspectable. Every verdict carries the reasons that produced it, and every
  reason names an observation about the task rather than restating the verdict.
- Small. The classification must not become another giant ontology; signals are
  a flat table, not a hierarchy.

Stdlib only. No third-party imports, so it runs on a clean cloud checkout.
"""

from __future__ import annotations

import argparse
import json
import re
import sys

SCHEMA_ID = "kernel.classification/v1"

# Below this, the router must say it is unsure rather than proceed silently.
LOW_CONFIDENCE_FLOOR = 0.55

DEFAULT_DOMAIN = "software"

# --------------------------------------------------------------------------
# Signals
#
# Each signal is (compiled pattern, weight, reason). Weight is a small integer;
# the absolute scale is meaningless, only the ordering and the margin matter.
# Reasons are written as observations ("touches persistent user data"), never as
# verdicts ("this is protected"), because they are shown to the user by
# /kernel:why and a verdict restated as its own justification is noise.
# --------------------------------------------------------------------------


def _sig(pattern: str, weight: int, reason: str):
    return (re.compile(pattern, re.IGNORECASE), weight, reason)


DOMAIN_SIGNALS = {
    "software": [
        _sig(r"\b(bug|crash|stack ?trace|traceback|exception|regression)\b", 3, "reports a code defect"),
        _sig(r"\b(refactor|migrat\w+|implement|endpoint|api|schema|query)\b", 2, "names an implementation artifact"),
        _sig(r"\b(test|compile|build|lint|type ?check|ci)\b", 2, "names a code verification step"),
        _sig(r"\b(function|class|method|module|package|dependency|import)\b", 2, "names a code construct"),
        _sig(r"\b(deploy|rollback|release|version|changelog)\b", 2, "names a release operation"),
        _sig(r"\.(py|js|ts|tsx|go|rs|rb|java|swift|kt|c|cpp|sh)\b", 3, "names a source file"),
        _sig(r"\b(database|sql|index|cache|queue|server)\b", 2, "names a system component"),
    ],
    "research": [
        _sig(r"\b(research|investigate|survey|literature|synthesi[sz]e?)\b", 3, "asks for investigation rather than change"),
        _sig(r"\b(compare|evaluate|assess|analy[sz]e) (the )?(options|approaches|tools|papers|tradeoffs)\b", 3, "asks for comparative analysis"),
        _sig(r"\b(find out|figure out|what are the|why does|how do(es)? \w+ work)\b", 2, "asks an open question"),
        _sig(r"\b(source|citation|evidence|prior art|state of the art)\b", 2, "asks for sourced findings"),
        _sig(r"\b(summar(y|i[sz]e)) (of|the) (findings|papers|research|literature)\b", 3, "asks for a research summary"),
    ],
    "writing": [
        _sig(r"\b(copy ?edit|proofread|rewrite|reword|rephrase)\b", 3, "asks for text revision"),
        _sig(r"\b(draft|essay|blog|article|post|newsletter|email|letter)\b", 3, "names a prose artifact"),
        _sig(r"\b(tone|voice|prose|wording|phrasing|readab\w+|grammar)\b", 3, "names a prose property"),
        _sig(r"\b(headline|subhead|tagline|caption|copy)\b", 2, "names a copy element"),
        _sig(r"\b(shorten|tighten|expand|punch\w* up) (the |this )?(text|copy|draft|paragraph)\b", 3, "asks for length or force revision"),
    ],
    "design": [
        _sig(r"\b(visual|aesthetic|art direction|mood|palette|typograph\w+)\b", 3, "names a visual property"),
        _sig(r"\b(layout|spacing|hierarchy|composition|contrast)\b", 2, "names a design property"),
        _sig(r"\b(ui|ux|interface|screen|mockup|wireframe|prototype)\b", 2, "names an interface artifact"),
        _sig(r"\b(previews?|screenshots?|rendered artifact|visual comparison)\b", 3, "names a rendered comparison surface"),
        _sig(r"\b(look|feel|style|theme|brand)\b", 2, "names an appearance concern"),
        _sig(r"\b(iterate|tweak|refine|polish) (on )?(the )?(design|visual|look|style|ui)\b", 3, "asks for visual iteration"),
        _sig(r"\b(worldbuild\w*|concept art|illustration|render)\b", 3, "names a visual-worldbuilding artifact"),
    ],
    "operations": [
        _sig(r"\b(provision|infra|infrastructure|terraform|kubernetes|k8s|docker)\b", 3, "names infrastructure"),
        _sig(r"\b(monitor\w*|alert\w*|on ?call|incident|outage|uptime|sre)\b", 3, "names an operational concern"),
        _sig(r"\b(credential|secret|rotate|access|permission|iam|firewall)\b", 3, "names an access-control operation"),
        _sig(r"\b(backup|restore|failover|scale (up|down)|capacity)\b", 3, "names a reliability operation"),
        _sig(r"\b(dns|certificate|tls|ssl|load balancer|cdn)\b", 3, "names network infrastructure"),
    ],
    "strategy": [
        _sig(r"\b(strateg\w+|roadmap|prioriti[sz]\w+|trade ?off|decision)\b", 3, "asks for a directional decision"),
        _sig(r"\b(should we|which (one|option|approach) should|worth (it|doing))\b", 3, "asks for a recommendation"),
        _sig(r"\b(business|market|pricing|positioning|competitive|go.to.market)\b", 3, "names a business concern"),
        _sig(r"\b(plan|scope|milestone|plan out|figure out what to)\b", 2, "asks for planning"),
        _sig(r"\b(pros and cons|options|alternatives)\b", 2, "asks for option analysis"),
    ],
}

# Work shape.
#
# direct    = known solution, one execution pass
# gated     = bounded implementation with explicit verification
# trajectory= repeated observe -> intervene -> measure -> reassess
#
# Trajectory only earns its keep when repeated feedback is genuinely useful. A
# task that is merely large is gated, not trajectory: size is not a feedback loop.
WORK_SHAPE_SIGNALS = {
    "direct": [
        _sig(r"\b(typo|rename|one.?liner|small|quick|trivial|minor)\b", 3, "described as a small change"),
        _sig(r"\b(fix the|update the|change the|add a|remove the|delete the) \w+\b", 2, "names a single bounded edit"),
        _sig(r"\b(bump|increment|set)\s+(the\s+)?\w+\s+to\b", 3, "names a single value change"),
        _sig(r"\b(what is|where is|show me|list|read|print)\b", 2, "asks for information, not change"),
        _sig(r"\b(status|progress|where (are|did) we|what happened)\b", 4, "asks for lightweight status"),
        _sig(r"\b(copy ?edit|proofread|reword)\b", 2, "single revision pass"),
    ],
    "gated": [
        _sig(r"\b(implement|build|add) (a |an |the )?\w+ (feature|endpoint|module|system|integration)\b", 3, "bounded implementation with a named deliverable"),
        _sig(r"\b(migrat\w+|refactor|restructure|rewrite)\b", 3, "structural change needing verification"),
        _sig(r"\b(integrat\w+|wire up|connect) \w+\b", 2, "integration with an external surface"),
        _sig(r"\b(unfamiliar|new to|never used|first time|not sure how)\b", 3, "unfamiliar territory needing a verification step"),
        _sig(r"\b(make sure|verify|ensure|must not break)\b", 2, "explicit verification requested"),
        _sig(r"\b(synthesi[sz]e|write up|produce) (a |the )?(report|summary|analysis)\b", 2, "bounded deliverable with a review step"),
        _sig(r"\b(review|audit|compare|comparison)\b", 3, "asks for a bounded artifact or assessment"),
        _sig(r"\b(clean ?up|tidy|straighten out)\b", 3, "names an ambiguous repair surface needing a scope gate"),
        _sig(r"\b(bounded|local) .{0,24}\b(artifact|comparison|assessment)\b", 3, "bounds an artifact and its evaluation surface"),
    ],
    "trajectory": [
        _sig(r"\b(iterat\w*|keep (going|trying|adjusting|iterat\w+)|until it (looks|feels|works|is right))\b", 4, "asks for repeated adjustment toward a target"),
        _sig(r"\b(tune|tuning|dial in|experiment with|play with|explore)\b", 3, "asks for exploratory adjustment"),
        _sig(r"\b(feedback loop|observe|measure|reassess|re-?evaluate)\b", 3, "names an observe-measure loop"),
        _sig(r"\b(a few (rounds|passes)|several (rounds|passes)|back and forth)\b", 4, "asks for multiple feedback rounds"),
        _sig(r"\b(does ?n.t (look|feel) right|until (i|we|you).re happy|get it right)\b", 3, "success is judged by repeated inspection"),
        _sig(r"\b(optimi[sz]e|improve) \w+ (over time|iterativ\w+|gradually)\b", 3, "asks for incremental improvement"),
    ],
}

# Safety.
#
# Fail-closed: these are scored in an independent pass. Any hit above threshold
# forces protected regardless of how "small" the work looks. The brief's example
# is a production account deletion: software + direct + protected. Direct and
# protected must be able to coexist, so this pass must never read work_shape.
PROTECTED_SIGNALS = [
    _sig(r"\b(delete|drop|truncate|purge|wipe|destroy|remove all)\b", 4, "performs a destructive operation"),
    _sig(r"\b(production|prod\b|live (site|system|server)|customer.facing)\b", 4, "touches a production surface"),
    _sig(r"\b(user data|customer data|personal data|pii|private|confidential)\b", 4, "touches private or user data"),
    _sig(r"\b(secret|credential|api key|token|password|auth|iam|permission)\b", 4, "touches credentials or access control"),
    _sig(r"\b(payment|billing|charge|refund|invoice|financial)\b", 4, "touches money movement"),
    _sig(r"\b(migrat\w+|schema change|backfill|irreversible|cannot be undone)\b", 3, "makes a change that is hard to reverse"),
    _sig(r"\b(force.?push|rebase|reset --hard|history rewrite)\b", 4, "rewrites shared history"),
    _sig(r"\b(deploy|ship|release|publish|push to main)\b", 3, "changes what other people run"),
    _sig(r"\b(expensive|cost|budget|spend|bill)\b", 2, "has a cost consequence"),
    _sig(r"\b(silent\w*|quietly|hard to (notice|detect)|no error)\b", 3, "fails quietly when wrong"),
    _sig(r"\b(account|subscription|tenant|org(ani[sz]ation)?)\b", 2, "operates on an account boundary"),
    # Infrastructure whose failure mode is an outage or a loss of trust, not a bad diff.
    # Added 2026-08-05 after an adversarial review found "change the DNS record for
    # example.com", "rotate the TLS certificate for example.com", and "suspend the customer
    # account" all classifying as normal + silent, while packs/operations/PACK.md states that
    # most operations work should be protected. Weighted at threshold so a single unambiguous
    # mention is sufficient; these are not operations to discover you got wrong.
    _sig(r"\b(dns|nameserver|name server|cname|mx record|a record|zone file|registrar)\b", 3, "changes name resolution, which fails as an outage"),
    _sig(r"\b(tls|ssl|certificate|cert(ificate)? (rotation|renewal)|acme|let.?s encrypt)\b", 3, "changes transport trust material"),
    _sig(r"\b(suspend|deactivate|disable|revoke|ban|lock out|terminate)\b", 3, "removes access from someone"),
    _sig(r"\b(firewall|security group|ingress|egress|acl|port forward|vpn|tunnel)\b", 3, "changes a network boundary"),
    _sig(r"\b(backup|restore|snapshot|failover|disaster recovery)\b", 3, "touches the recovery path"),
    _sig(r"\b(read.only|don.t change|no changes|do not (edit|write|modify)|strictly read)\b", 3, "imposes a no-write boundary"),
]

# Explicit de-risking phrases. These do not cancel a protected signal (fail
# closed), they only lower confidence in a *normal* verdict being wrong.
NORMAL_SIGNALS = [
    _sig(r"\b(local|localhost|sandbox|scratch|test (env|environment)|dry.?run)\b", 3, "confined to a local or sandbox surface"),
    _sig(r"\b(just (look|read|check))\b", 2, "asks only for observation"),
    _sig(r"\b(draft|prototype|throwaway|experiment(al)?)\b", 2, "explicitly disposable output"),
]

PROTECTED_THRESHOLD = 3

# Request-state signals. Text starts the classification, but normal host
# activation must not pretend the current request is the whole world. These
# signals are used only with observable live-run state supplied by the hook:
# the previous route, elapsed session time, and working-tree change count.
LOW_INFORMATION_CONTINUATION = re.compile(
    r"^\s*(continue|keep going|go on|resume|carry on|same thing|finish it)"
    r"[\s.!?]*$",
    re.IGNORECASE,
)
# Anchored, like LOW_INFORMATION_CONTINUATION above, and for the same reason. Unanchored
# this matched any prompt merely CONTAINING "status" or "progress", so "fix the status
# endpoint and deploy it" and "update the progress dashboard" were treated as transient
# status lookups: classified for the current turn but never stored, so a later "continue"
# resumed a stale route. A status request is a whole short utterance, not a word in passing.
LIGHTWEIGHT_STATUS = re.compile(
    r"^\s*(?:"
    r"(?:what(?:'s|s| is| was)?\s+)?(?:the\s+|our\s+)?(?:current\s+|latest\s+)?status"
    r"|(?:any\s+|what\s+|the\s+)?progress(?: so far)?"
    r"|where (?:are|did) we(?: (?:at|now|leave off|get to))?"
    r"|what happened"
    r"|how(?:'s|s| is)? it going"
    r"|update\??"
    r")[\s.!?]*$",
    re.IGNORECASE,
)
MEANINGFUL_REVISION = re.compile(
    r"\b(actually|instead|new evidence|we found|turns out|was wrong|stale|"
    r"scope (expanded|changed)|back out|revert that|stop the|only produce|"
    r"fresh process|regression)\b",
    re.IGNORECASE,
)
SAFETY_BOUNDARY_RELEASE = re.compile(
    r"\b(you may (edit|write|modify)|writes? (are|is) allowed|"
    r"lift (the )?read.only|new (task|request)|unrelated task)\b",
    re.IGNORECASE,
)
STATE_PRESSURE_SIGNALS = [
    _sig(r"\b(scope (expanded|changed)|expanded into|turned into)\b", 1, "scope changed after execution began"),
    _sig(r"\b(new evidence|we found|turns out|was wrong|stale|false)\b", 1, "new evidence invalidated an assumption"),
    _sig(r"\b(long.?running|still (active|running)|[3-9][0-9]-minute|[1-9][0-9]{2,}-minute)\b", 1, "a live execution remains active"),
    _sig(r"\b(fresh process|save/load|allocation regression|performance regression)\b", 1, "a fresh runtime observation changed the state"),
]

# Domain-appropriate verification. Never hardcoded to "tests": the brief forbids
# tests language for non-code domains.
VERIFICATION_BY_DOMAIN = {
    "software": "run the project's configured checks and exercise the changed path",
    "research": "trace each claim to a primary source and name what would falsify it",
    "writing": "read the revised text against the brief; blinded pairwise comparison for tone changes",
    "design": "render the artifact and inspect it; blinded pairwise comparison against the prior version",
    "operations": "confirm against the running system, not the change record",
    "strategy": "state the decision's falsifier and the evidence that would reverse it",
}

PACK_BY_DOMAIN = {
    "software": ["software"],
    "research": ["research"],
    "writing": ["writing"],
    "design": ["design"],
    "operations": ["operations"],
    "strategy": ["strategy"],
}


# --------------------------------------------------------------------------
# Scoring
# --------------------------------------------------------------------------


def _score(text: str, signals) -> tuple[int, list[str]]:
    """Sum weights of every matching signal, collecting distinct reasons."""
    total = 0
    reasons: list[str] = []
    for pattern, weight, reason in signals:
        if pattern.search(text):
            total += weight
            if reason not in reasons:
                reasons.append(reason)
    return total, reasons


def _confidence(top: int, runner_up: int, floor: float = 0.5) -> float:
    """Confidence from the margin between the winner and the next candidate.

    A win by a wide margin over a scoring runner-up is confident. A win by one
    point is not. Zero evidence is explicitly low, not neutral: the router must
    be able to say it is guessing.
    """
    if top <= 0:
        return 0.30
    margin = (top - runner_up) / float(top)
    return round(min(0.99, floor + 0.49 * margin), 2)


def classify_domain(text: str, hint: str | None = None) -> tuple[str, float, list[str]]:
    if hint:
        return hint, 0.99, [f"domain pinned to {hint} by caller"]

    scored = {}
    reasons_by_domain = {}
    for domain, signals in DOMAIN_SIGNALS.items():
        total, reasons = _score(text, signals)
        scored[domain] = total
        reasons_by_domain[domain] = reasons

    ranked = sorted(scored.items(), key=lambda kv: (-kv[1], kv[0]))
    top_domain, top_score = ranked[0]
    runner_up = ranked[1][1] if len(ranked) > 1 else 0

    if top_score == 0:
        # No signal at all. Default, but say so honestly and with low confidence
        # rather than inventing a rationale.
        return DEFAULT_DOMAIN, 0.30, ["no domain signal detected; defaulted"]

    return top_domain, _confidence(top_score, runner_up), reasons_by_domain[top_domain]


def classify_work_shape(
    text: str,
    hint: str | None = None,
    state: dict | None = None,
) -> tuple[str, float, list[str]]:
    if hint:
        return hint, 0.99, [f"work shape pinned to {hint} by caller"]

    state = state or {}
    previous_shape = state.get("previous_work_shape")
    if (
        previous_shape in SHAPE_ORDER
        and LOW_INFORMATION_CONTINUATION.fullmatch(text)
    ):
        return (
            previous_shape,
            0.85,
            ["low-information continuation retained the current live-run shape"],
        )

    scored = {}
    reasons_by_shape = {}
    for shape, signals in WORK_SHAPE_SIGNALS.items():
        total, reasons = _score(text, signals)
        scored[shape] = total
        reasons_by_shape[shape] = reasons

    # A meaningful revision is decision-relevant only in the context of an
    # active run. Escalate to trajectory when at least two independent pressure
    # observations say the inherited gated boundary no longer describes
    # reality. No project name or provider identity participates.
    if previous_shape in ("gated", "trajectory") and MEANINGFUL_REVISION.search(text):
        pressure_score, pressure_reasons = _score(text, STATE_PRESSURE_SIGNALS)
        age = max(0, int(state.get("session_age_minutes", 0) or 0))
        changes = max(0, int(state.get("working_tree_changes", 0) or 0))
        if age >= 30:
            pressure_score += 1
            pressure_reasons.append(f"active run is {age} minutes old")
        if changes >= 5:
            pressure_score += 1
            pressure_reasons.append(f"working tree has {changes} changed paths")
        if pressure_score >= 2:
            scored["trajectory"] += 6
            reasons_by_shape["trajectory"].extend(pressure_reasons)

    # Trajectory must genuinely earn selection: repeated feedback has to be
    # useful, not merely possible. It wins only by strictly beating the best
    # alternative, so ties fall to the lighter shape.
    ranked = sorted(scored.items(), key=lambda kv: (-kv[1], ["direct", "gated", "trajectory"].index(kv[0])))
    top_shape, top_score = ranked[0]
    runner_up = ranked[1][1] if len(ranked) > 1 else 0

    if top_score == 0:
        return "direct", 0.40, ["no complexity signal detected; smallest shape chosen"]

    return top_shape, _confidence(top_score, runner_up), reasons_by_shape[top_shape]


def classify_safety(text: str, hint: str | None = None) -> tuple[str, float, list[str]]:
    """Independent pass. Never reads domain or work_shape. Fails closed."""
    if hint:
        return hint, 0.99, [f"safety pinned to {hint} by caller"]

    protected_score, protected_reasons = _score(text, PROTECTED_SIGNALS)
    normal_score, normal_reasons = _score(text, NORMAL_SIGNALS)

    if protected_score >= PROTECTED_THRESHOLD:
        # Confidence rises with how far past the threshold we are. Explicit
        # de-risking language lowers confidence but never flips the verdict:
        # "delete the production database, it's fine, it's a dry run" stays
        # protected.
        margin = protected_score - PROTECTED_THRESHOLD
        conf = min(0.99, 0.65 + 0.06 * margin)
        if normal_score:
            conf = max(0.55, conf - 0.10)
            protected_reasons = protected_reasons + ["de-risking language present but not decisive"]
        return "protected", round(conf, 2), protected_reasons

    if normal_score:
        return "normal", round(min(0.95, 0.60 + 0.08 * normal_score), 2), normal_reasons

    if protected_score:
        # Some risk signal, under threshold. Say so.
        return "normal", 0.50, ["weak risk signal below the protected threshold"]

    return "normal", 0.70, ["no destructive, private, production, or cost signal detected"]


# --------------------------------------------------------------------------
# Exit conditions
#
# Every non-heaviest shape must name how it escalates, and every non-lightest
# shape must name how it de-escalates. This is enforced by the schema; the
# router supplies defaults so a classification is never born invalid.
# --------------------------------------------------------------------------

ESCALATE_DEFAULTS = {
    "direct": [
        "the change touches more than the named surface",
        "the first attempt does not work as expected",
        "a risk signal appears that was not in the request",
    ],
    "gated": [
        "verification cannot distinguish the safe outcome from the unsafe one",
        "scope expands beyond the agreed deliverable",
        "repeated attempts fail for different reasons each time",
    ],
}

DEESCALATE_DEFAULTS = {
    "gated": [
        "implementation and checks become deterministic",
        "the remaining work is a single known edit",
    ],
    "trajectory": [
        "two consecutive passes produce no meaningful change",
        "the target becomes specifiable in advance",
        "the remaining work is a single bounded change with a known check",
    ],
}

PROTECTED_ESCALATE = "verification cannot distinguish safe from unsafe outcome"


def build_classification(
    text: str,
    domain_hint=None,
    shape_hint=None,
    safety_hint=None,
    state=None,
    boundary=None,
    role="writer",
    holder=None,
):
    domain, d_conf, d_reasons = classify_domain(text, domain_hint)
    shape, s_conf, s_reasons = classify_work_shape(text, shape_hint, state)
    safety, f_conf, f_reasons = classify_safety(text, safety_hint)

    # Overall confidence is the weakest link, not the average: a classification
    # is only as trustworthy as its least certain dimension.
    confidence = round(min(d_conf, s_conf, f_conf), 2)

    reasons = []
    for r in d_reasons + s_reasons + f_reasons:
        if r not in reasons:
            reasons.append(r)
    reasons = reasons[:6]

    out = {
        "schema": SCHEMA_ID,
        "domain": domain,
        "work_shape": shape,
        "safety": safety,
        "confidence": confidence,
        "reasons": reasons,
        "packs": PACK_BY_DOMAIN.get(domain, [domain]),
    }

    if shape in ESCALATE_DEFAULTS:
        esc = list(ESCALATE_DEFAULTS[shape])
        if safety == "protected" and PROTECTED_ESCALATE not in esc:
            esc.insert(0, PROTECTED_ESCALATE)
        out["escalate_when"] = esc[:6]

    if shape in DEESCALATE_DEFAULTS:
        out["deescalate_when"] = list(DEESCALATE_DEFAULTS[shape])[:6]

    # Protected work must name how it will be checked, in domain-appropriate
    # terms. Schema rule R3 requires this; supplying it here means a protected
    # classification is never born invalid.
    if safety == "protected":
        out["verification"] = {
            "method": VERIFICATION_BY_DOMAIN.get(
                domain, "confirm the outcome against the running system"
            ),
            "seeded_failure_verified": False,
        }

    if boundary:
        ownership = {"boundary": boundary, "role": role}
        if holder:
            ownership["holder"] = holder
        out["ownership"] = ownership

    # Announce only when the mode materially changes behavior. Routine direct +
    # normal work stays silent: the brief's whole point is that Kernel should be
    # nearly invisible.
    #
    # Low confidence is only worth surfacing when it is low in a dimension that
    # selects process. Being unsure whether a typo fix is "software" or
    # "writing" changes nothing about how it gets done, so it is not worth a
    # sentence. Being unsure about shape or safety does change what happens, and
    # is surfaced.
    out["announced"] = bool(
        shape != "direct"
        or safety == "protected"
        or min(s_conf, f_conf) < LOW_CONFIDENCE_FLOOR
    )

    return out


def classify_request(
    text: str,
    previous: dict | None = None,
    session_age_minutes: int = 0,
    working_tree_changes: int = 0,
) -> dict:
    """Classify the current request against observable live-run state.

    Previous state is evidence, not authority. A low-information continuation
    retains it because the request supplies no contrary fact. Every substantive
    request is classified afresh, and a changed shape records the reassessment.
    """
    previous = previous or None
    state = {
        "previous_work_shape": previous.get("work_shape") if previous else None,
        "session_age_minutes": max(0, int(session_age_minutes)),
        "working_tree_changes": max(0, int(working_tree_changes)),
    }
    continuing = bool(previous and LOW_INFORMATION_CONTINUATION.fullmatch(text))
    out = build_classification(
        text,
        state=state,
        safety_hint=previous.get("safety") if continuing else None,
    )

    if not previous:
        return out

    transient_status = bool(LIGHTWEIGHT_STATUS.search(text))

    # A hard safety boundary is active-run state. Do not clear it merely
    # because the next revision omits the original hazard words. An explicit
    # release or a named new objective is required.
    if (
        previous.get("safety") == "protected"
        and out["safety"] == "normal"
        and not SAFETY_BOUNDARY_RELEASE.search(text)
    ):
        out["safety"] = "protected"
        out["verification"] = json.loads(
            json.dumps(
                previous.get(
                    "verification",
                    {
                        "method": VERIFICATION_BY_DOMAIN.get(
                            out["domain"],
                            "confirm the outcome against the running system",
                        ),
                        "seeded_failure_verified": False,
                    },
                )
            )
        )
        out["reasons"] = (
            ["existing safety boundary remains active"] + out["reasons"]
        )[:6]
        out["announced"] = True

    # A status lookup is a transient subrequest, not a revision of the active
    # objective. It gets the cheapest work shape but retains any active safety
    # boundary and must not replace the route that "continue" resumes.
    if transient_status:
        out["transient"] = True
        return out

    prior_transitions = json.loads(json.dumps(previous.get("transitions", [])))
    old_shape = previous.get("work_shape")
    new_shape = out["work_shape"]
    if old_shape != new_shape:
        prior_transitions.append(
            {
                "from": old_shape,
                "to": new_shape,
                "trigger": "current request materially revised the active run",
                "direction": (
                    "escalate"
                    if SHAPE_ORDER.index(new_shape) > SHAPE_ORDER.index(old_shape)
                    else "deescalate"
                ),
                "user_initiated": True,
            }
        )
        out["announced"] = True
    if prior_transitions:
        out["transitions"] = prior_transitions
    return out


# --------------------------------------------------------------------------
# Mode transitions
# --------------------------------------------------------------------------

SHAPE_ORDER = ["direct", "gated", "trajectory"]


def adjust(classification: dict, direction: str, trigger: str, user_initiated: bool = False) -> dict:
    """Move one step lighter or heavier, recording why.

    Hard safety never moves. /kernel:lighter can drop trajectory to gated but it
    can never turn protected into normal, because the safety overlay is
    independent of work shape by construction.
    """
    out = json.loads(json.dumps(classification))
    idx = SHAPE_ORDER.index(out["work_shape"])

    if direction == "lighter":
        new_idx = max(0, idx - 1)
    elif direction == "heavier":
        new_idx = min(len(SHAPE_ORDER) - 1, idx + 1)
    else:
        raise ValueError(f"unknown direction: {direction}")

    old = SHAPE_ORDER[idx]
    new = SHAPE_ORDER[new_idx]

    if old != new:
        out["work_shape"] = new
        out.setdefault("transitions", []).append(
            {
                "from": old,
                "to": new,
                "trigger": trigger,
                "direction": "deescalate" if direction == "lighter" else "escalate",
                "user_initiated": user_initiated,
            }
        )

        # Exit conditions belong to the shape, so they are rebuilt, not carried.
        out.pop("escalate_when", None)
        out.pop("deescalate_when", None)
        if new in ESCALATE_DEFAULTS:
            esc = list(ESCALATE_DEFAULTS[new])
            if out.get("safety") == "protected" and PROTECTED_ESCALATE not in esc:
                esc.insert(0, PROTECTED_ESCALATE)
            out["escalate_when"] = esc[:6]
        if new in DEESCALATE_DEFAULTS:
            out["deescalate_when"] = list(DEESCALATE_DEFAULTS[new])[:6]

        out["announced"] = True

    return out


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------


def main(argv=None):
    parser = argparse.ArgumentParser(
        prog="kernel-router",
        description="Classify a task into domain, work shape, and safety level.",
    )
    sub = parser.add_subparsers(dest="cmd", required=True)

    c = sub.add_parser("classify", help="classify a task description")
    c.add_argument("task", nargs="?", help="task description; reads stdin when omitted")
    c.add_argument("--domain")
    c.add_argument("--work-shape", dest="work_shape", choices=SHAPE_ORDER)
    c.add_argument("--safety", choices=["normal", "protected"])
    c.add_argument("--boundary", help="ownership boundary this task will write to")
    c.add_argument("--role", choices=["writer", "reader"], default="writer")
    c.add_argument("--holder", help="session id claiming the boundary")
    c.add_argument("--previous", help="previous classification JSON file")
    c.add_argument("--session-age-minutes", type=int, default=0)
    c.add_argument("--working-tree-changes", type=int, default=0)
    c.add_argument("--compact", action="store_true", help="single-line JSON")

    a = sub.add_parser("adjust", help="move one step lighter or heavier")
    a.add_argument("direction", choices=["lighter", "heavier"])
    a.add_argument("--trigger", required=True)
    a.add_argument("--user", action="store_true", help="mark as user initiated")
    a.add_argument("--input", help="classification JSON file; reads stdin when omitted")

    args = parser.parse_args(argv)

    if args.cmd == "classify":
        text = args.task if args.task else sys.stdin.read()
        text = (text or "").strip()
        if not text:
            print("kernel-router: empty task description", file=sys.stderr)
            return 2
        if args.previous:
            with open(args.previous) as fh:
                previous = json.load(fh)
            result = classify_request(
                text,
                previous=previous,
                session_age_minutes=args.session_age_minutes,
                working_tree_changes=args.working_tree_changes,
            )
        else:
            result = build_classification(
                text,
                domain_hint=args.domain,
                shape_hint=args.work_shape,
                safety_hint=args.safety,
                state={
                    "session_age_minutes": args.session_age_minutes,
                    "working_tree_changes": args.working_tree_changes,
                },
                boundary=args.boundary,
                role=args.role,
                holder=args.holder,
            )
    else:
        raw = open(args.input).read() if args.input else sys.stdin.read()
        result = adjust(json.loads(raw), args.direction, args.trigger, args.user)

    indent = None if getattr(args, "compact", False) else 2
    print(json.dumps(result, indent=indent, sort_keys=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
