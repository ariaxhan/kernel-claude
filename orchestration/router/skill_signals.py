"""KERNEL skill-level routing signals.

Same shape as DOMAIN_SIGNALS in kernel_router.py, one layer down: skill instead of
domain. Plain tuples (raw regex string, int weight 1-3, reason string) -- no _sig()
calls, no imports -- so this file is standalone-testable and standalone-lintable.
The router wires these in; this file does not import kernel_router.

Weight scale (same as DOMAIN_SIGNALS): 3 = phrasing all but names the skill,
2 = strong corroboration, 1 = weak corroboration.

SKILL_DOMAINS maps each skill to the router domain(s) it is plausible under, so the
router can gate skill suggestion on domain match before spending regex cycles.
"""

from __future__ import annotations

SKILL_SIGNALS: dict[str, list[tuple[str, int, str]]] = {

    # -- app-dev vs ship (both claim "deploy") -----------------------------
    # app-dev owns MOBILE build/store surfaces (fastlane, expo, native store
    # submission); ship owns the git/PR release-gate sequence for any repo.
    # Disambiguator: app-dev requires a mobile/build-tool noun; ship requires a
    # git/PR/branch noun. "deploy" alone (no mobile noun) falls to ship or
    # marketing-site/landing-page depending on other signals.
    "app-dev": [
        (r"\b(testflight|app store|play store|store submission)\b", 3, "names a mobile store submission"),
        # `gym`, `deliver` and `supply` are fastlane lane names AND ordinary
        # English words. Alone they matched "pick this up tomorrow at the gym".
        # fastlane and gradle are unambiguous; the rest need the toolchain named.
        (r"\b(fastlane|gradle)\b", 3, "names the mobile build toolchain"),
        (r"\bfastlane\b.{0,40}\b(gym|deliver|supply|match|pilot)\b", 3, "names a fastlane lane"),
        (r"\b(gym|deliver|supply) lane\b", 2, "names a fastlane lane"),
        (r"\b(expo|react native|flutter|swift ?ui|android studio|xcode)\b", 3, "names a mobile app framework"),
        (r"\b(build|deploy) (the )?(ios|android|mobile) app\b", 3, "asks to build or deploy a mobile app"),
        (r"\bpre-?submission checklist\b", 2, "asks for a store submission checklist"),
    ],

    "architecture": [
        # vs simplify/diagnose (rule 3 cluster 7): architecture is about
        # module boundaries and dependency direction as a design question,
        # not a defect to fix (diagnose) or a complexity number to lower
        # (simplify).
        (r"\b(system|module|service) (architecture|design|boundar\w+)\b", 3, "names a structural design question"),
        (r"\b(coupling|cohesion|dependency (graph|direction|management))\b", 3, "names a dependency-structure concern"),
        (r"\btoo (tightly )?coupled\b", 3, "reports excessive coupling"),
        (r"\b(interface|module|service) boundar\w+\b", 3, "asks where the boundaries belong"),
        (r"\b(interface stability|api surface|layering|separation of concerns)\b", 2, "names an architectural property"),
        (r"\bhow should (this|the) (system|module|service) be structured\b", 3, "asks for structural design guidance"),
        (r"\bwhere should \w+ live\b", 2, "asks for module placement guidance"),
    ],

    "build": [
        # vs ingest (rule 3 cluster 1): build is mid-work, exploring 2-3
        # approaches for a scoped feature; ingest is the START-of-work entry
        # point (scoping/triage, new or resumed task). Disambiguator: build
        # fires on "generate approaches / pick simplest / implement the
        # feature" phrasing; ingest fires on "start/begin/resume/new task"
        # phrasing. Both claim bare "build/implement/create" verbs, so give
        # build the extra weight only when an approach-exploration phrase or
        # a named feature/endpoint noun is present, and let ingest own the
        # bare entry-point phrasing.
        (r"\b(generate|explore|compare) ((2|3|two|three|a few)( or (2|3|two|three))? )?approaches\b", 3, "asks for multiple candidate approaches"),
        (r"\bimplement (a |an |the )?(feature|endpoint|module|integration)\b", 3, "names a scoped implementation deliverable"),
        (r"\badd (a |an )?(new )?(feature|endpoint|button|page|field)\b", 2, "names a scoped feature addition"),
        (r"\bpick the simplest\b", 2, "asks for the simplest of several approaches"),
        (r"\bbuild (a |an |the )\w+ (feature|integration|component)\b", 2, "names a scoped build target"),
    ],

    "checkpoint": [
        # vs handoff vs context-mgmt (rule 3 cluster 4): checkpoint is a
        # BOUNDED resume manifest inside one long task ("save progress before
        # I lose context"). handoff is provenance/decisions for a LATER
        # session/person. context-mgmt is the token-management METHOD itself
        # (compaction strategy), not a state artifact.
        (r"\bcheckpoint\b", 3, "asks to save a checkpoint"),
        (r"\bsave progress\b(?!.{0,20}(for later|for next session|so (he|she|they|someone) can))", 2, "asks to save progress inside the current task"),
        (r"\b(context reset|compact(ing)? soon|about to compact)\b", 3, "names an imminent context reset needing a resume point"),
        (r"\blong[- ]?running task\b.{0,20}\bresume\b", 2, "names a long task that needs a resume point"),
    ],

    "context-mgmt": [
        # vs checkpoint/handoff (see above): context-mgmt is the METHOD, not
        # an artifact. Fires on questions about the token budget or
        # compaction mechanics, not on "save my progress" requests.
        (r"\b(token (budget|window|limit)|context window|context engineering)\b", 3, "asks about the token/context budget itself"),
        (r"\b(compaction|compact\w* strateg\w+|progressive disclosure)\b", 3, "names a compaction or disclosure strategy"),
        (r"\bwhy (is|did) (the )?context (fill|degrade|blow up)\b", 3, "asks why context quality degraded"),
        (r"\bstructured note.?taking\b", 2, "names the agentdb note-taking method"),
    ],

    "debug": [
        # vs diagnose (rule 3 cluster 2): debug is a LIVE defect with a
        # repro/error in hand; diagnose ADDS refactor-mode (map deps, measure
        # coupling) and is invoked before deciding whether to even start
        # fixing. Disambiguator: debug fires on concrete failure evidence
        # (stack trace, crash, "broken"); diagnose fires on "should I refactor
        # this" / dependency-mapping phrasing with no concrete failure.
        (r"\b(stack ?trace|traceback|exception|crash(ed)?)\b", 3, "reports a concrete crash or exception"),
        (r"\b(reproduce|repro) (the )?(bug|issue|crash|failure)\b", 3, "has a reproducible failure in hand"),
        (r"\b(fails?|failing|broken|not working) (when|on|with|because)\b", 2, "reports a specific failure condition"),
        (r"\bwhy (is|does) \w+ (fail|crash|throw|break)\b", 3, "asks for the root cause of a live failure"),
        (r"\bregression test\b", 2, "asks for a regression test tied to a fix"),
    ],

    "diagnose": [
        # vs debug (see above) and vs simplify/architecture (rule 3 cluster
        # 7): diagnose is invoked BEFORE prescribing a fix -- either "is this
        # actually a bug and where" (bug mode, no concrete repro yet) or
        # "should this be refactored, what would break" (refactor mode,
        # dependency mapping without committing to a rewrite).
        (r"\bshould (this|we) refactor\b", 3, "asks whether a refactor is warranted, not committed to it"),
        (r"\bmap (the )?depend\w+\b", 3, "asks for a dependency map before deciding"),
        (r"\bwhat would break if\b", 3, "asks for blast-radius analysis before a decision"),
        (r"\bdiagnos\w+ (the |this )?(bug|issue|problem)\b", 3, "asks for diagnosis before a fix is chosen"),
        (r"\bis this (actually|really) a bug\b", 2, "asks whether a symptom is a real defect"),
    ],

    "dream": [
        (r"\b(brainstorm|diverge|explore the solution space)\b", 2, "asks for divergent idea generation"),
        (r"\bcompeting (perspectives|value systems|approaches)\b", 3, "asks for structured competing viewpoints"),
        (r"\badversarial(ly)? stress[- ]?test\w*\b", 3, "asks for adversarial stress-testing of ideas"),
        (r"\bwhat.?s the (boldest|most creative) (option|approach)\b", 2, "asks for a maximalist creative option"),
    ],

    "eval": [
        (r"\b(eval|evals|eval harness|eval suite)\b", 2, "names an eval"),
        (r"\b(pass@k|eval-?driven|edd)\b", 3, "names eval-driven development terminology"),
        (r"\b(capability eval|regression eval|benchmark suite)\b", 3, "names a specific eval artifact"),
        (r"\bwrite evals? for\b", 3, "asks for evals to be written"),
        (r"\bhow (well|reliably) does \w+ perform\b", 2, "asks for a capability measurement"),
    ],

    "experiment": [
        # disable-model-invocation is NOT set on experiment; still narrow it
        # to hypothesis-testing-about-rules language so it doesn't fire on
        # generic "test this" prompts (that's debug/build's job).
        (r"\btreat (this |the )?rule as a hypothesis\b", 3, "asks to treat a development rule as testable"),
        (r"\b(falsifiable test|graduate|kill) (the )?(rule|hypothesis)\b", 3, "asks to evaluate a rule via falsifiable test"),
        (r"\bprove (this|that) (rule|methodology) (works|holds)\b", 2, "asks for evidence a rule holds"),
    ],

    "forge": [
        # MUST NEVER be auto-suggested: disable-model-invocation: true in
        # SKILL.md. Signals kept for completeness / future explicit-only UI,
        # but the router must filter this key out of any auto-recommendation
        # (Aria/caller-owned filter, per task instructions).
        (r"\bfully autonomous\b.{0,30}\b(no human|no checkpoints)\b", 3, "asks for fully unattended iteration"),
        (r"\biterate until (it.?s |the code is )?antifragile\b", 3, "asks for iterate-until-antifragile loop"),
        (r"\bno human (checkpoints|review) (needed|required)\b", 2, "explicitly waives human review"),
    ],

    "frontend": [
        (r"\b(css|styling|layout|component) (for|of) (the )?(ui|page|screen)\b", 2, "names a UI implementation surface"),
        (r"\b(css|layout|styling)\b.{0,40}\b(breaks?|broken|overflow\w*|misaligned)\b", 3, "reports a broken visual layout"),
        (r"\bat \d{3,4}px\b", 2, "names a viewport breakpoint"),
        (r"\blooks? generic\b", 3, "reports generic visual defaults"),
        (r"\b(art direction|design system|visual (theme|language)|aesthetic)\b", 3, "asks for visual/art direction"),
        (r"\b(responsive|accessibility|a11y|keyboard nav)\b", 2, "names a frontend quality property"),
        (r"\b(animation|motion|micro-?interaction)\b", 2, "names an interaction/motion property"),
        (r"\bmake (this|it) (look|feel) (less generic|distinctive|intentional)\b", 3, "asks to avoid generic AI visual defaults"),
    ],

    "governance-sync": [
        # disable-model-invocation: true. Explicit-only; narrow signals only.
        (r"\b(sync|audit) (claude\.md|agents\.md|governance)\b", 3, "asks to audit or sync instruction files"),
        (r"\binstruction mirror\b", 2, "names the Claude/Codex instruction mirror"),
    ],

    "handoff": [
        (r"\b(next session|another session|whoever picks this up)\b", 2, "names a later session as the reader"),
        # vs checkpoint/context-mgmt (see checkpoint comment). handoff is
        # provenance + decisions + next steps for someone else / a LATER
        # session, phrased as "before I go" / "pass this to the next agent".
        (r"\b(handoff|hand off|hand this off)\b", 3, "asks to hand work to another session or person"),
        (r"\bnext steps for (whoever|the next (agent|session))\b", 3, "names provenance for a future session"),
        (r"\bpause (this )?(for now|and)\b.{0,20}\bcontinue later\b", 2, "asks to pause with a later-resume intent"),
        (r"\bwhat decisions (did we|were) made\b", 2, "asks for a record of decisions made"),
    ],

    "help": [
        (r"\b(kernel )?help\b", 2, "asks for kernel help"),
        (r"\bwhat (kernel )?skills (are there|are available|do you have|exist)\b", 3, "asks for the skill inventory"),
        (r"\bkernel\b", 2, "names kernel itself"),
        (r"\b(list|show) (me )?(the )?(kernel )?(skills|commands)\b", 3, "asks to list the skills"),
        (r"\bhow does kernel work\b", 2, "asks how the kernel system works"),
    ],

    "human-pass": [
        (r"\b(testflight|acceptance test|before we ship|hand it to the user)\b", 3, "asks for a pre-ship human acceptance pass"),
        (r"\bwhat should (i|we) test (by hand|manually)\b", 3, "asks for a manual test checklist"),
        (r"\brelease checklist\b", 2, "asks for a release checklist"),
        (r"\bdevice test\b", 2, "asks for on-device testing"),
    ],

    "ingest": [
        # vs build (see build comment above). ingest owns the entry point:
        # brand-new or resumed work, before scope is settled.
        (r"^\s*(start|begin) (on |with )?(a |the )?(new )?task\b", 3, "starts a brand-new task"),
        (r"\bresume (the|my|this) (task|work|handoff|checkpoint)\b", 3, "asks to resume prior work from a manifest"),
        (r"\bnot sure (what|how) to (start|scope) (this )?yet\b", 2, "needs scoping before work is bounded"),
        (r"\bcontinue (from|where)\b", 2, "asks to continue from a prior state"),
    ],

    "init": [
        # disable-model-invocation: true. Explicit-only, once-per-machine.
        (r"\binit(ialize)? kernel\b", 3, "asks to initialize kernel in this directory"),
        (r"\bset up agentdb\b", 2, "asks to set up agentdb for the first time"),
    ],

    "knowledge-graph": [
        (r"\b(knowledge graph|code graph|graphify)\b", 3, "names the code knowledge graph tool"),
        (r"\b(god nodes?|blast radius|orientation cost)\b", 3, "names a knowledge-graph query concept"),
        (r"\bwhat connects \w+ to \w+\b", 2, "asks for a code-relationship query"),
        (r"\bwho calls \w+\b", 2, "asks for callers of a symbol"),
        (r"\bmap the codebase\b", 2, "asks for a structural map of the codebase"),
    ],

    "landing-page": [
        # vs marketing-site (rule 3 cluster 5): landing-page is the EXPLICIT
        # build-and-DEPLOY operator (disable-model-invocation: true) for one
        # focused page; marketing-site is the METHODOLOGY (audience, offer,
        # proof, objections) that landing-page composes and that applies to
        # multi-page company/product sites too. Disambiguator: landing-page
        # fires on "build and deploy a landing page" (action + deploy
        # target); marketing-site fires on strategy nouns (audience, offer,
        # proof, positioning) without a deploy action.
        (r"\bbuild (and deploy |and ship )?(a |the )?landing page\b", 3, "asks to build and deploy a landing page"),
        (r"\bdeploy (the )?(landing page|site) to\b", 3, "names a landing-page deploy target"),
        (r"\bscaffold (a |the )?(smallest |simple )?site\b", 2, "asks to scaffold a minimal site"),
    ],

    "marketing-site": [
        # Widened 2026-09-01: the {0,20} window meant "positioning and value
        # proposition for the company marketing site" fell outside its own rule,
        # which is the normal way to phrase the request.
        (r"\bmarketing (site|website|page)\b", 3, "names a marketing site"),
        (r"\b(target audience|value proposition|positioning|offer)\b.{0,60}\b(site|page|website|brand|product)\b", 3, "names marketing-site strategy elements"),
        (r"\b(social proof|testimonial|objection handling|cta)\b", 2, "names a conversion-copy element"),
        (r"\bcompany \w*\s?(website|site)\b", 2, "names a company website"),
        (r"\bportfolio (site|page)\b", 2, "names a portfolio site"),
        (r"\bprivacy policy\b", 2, "asks for a site privacy policy"),
    ],

    "metrics": [
        (r"\b(kernel )?(metrics|dashboard|observability)\b", 3, "asks for kernel telemetry"),
        (r"\bsession stats\b", 2, "asks for session statistics"),
        (r"\bhook performance\b", 2, "asks about hook performance"),
        (r"\blearning health\b", 2, "asks about agentdb learning health"),
    ],

    "orchestration": [
        (r"\b(orchestrate|coordinate) (multiple )?agents\b", 3, "asks to coordinate multiple agents"),
        (r"\b(lane contract|worker.?model doctrine|fault toleran\w+)\b", 3, "names an orchestration mechanism"),
        (r"\bspawn (multiple|parallel) (agents|lanes)\b", 3, "asks to spawn parallel agents"),
        (r"\btier (2|3) (work|task)\b", 2, "names a tiered orchestration workload"),
    ],

    "quality": [
        (r"\b(input validation|edge cases?|error handling|duplication)\b", 2, "names a Big-5 quality dimension"),
        # vs review/tearitapart (rule 3 cluster 3): quality is the Big-5
        # CHECKLIST (input validation, edge cases, error handling,
        # duplication, complexity) run standalone during/after implementation
        # -- not a PR verdict (review) and not a pre-implementation plan
        # critique (tearitapart).
        (r"\bbig[- ]?5\b", 3, "names the big-5 quality checklist"),
        (r"\b(input validation|edge cases?|error handling) check\b", 2, "names a big-5 quality dimension"),
        (r"\bcheck (this|the) code for quality\b", 3, "asks for a standalone quality check"),
        (r"\bduplicat\w+ (code|logic)\b", 2, "names code duplication as a quality concern"),
    ],

    "retrospective": [
        (r"\b(retrospective|retro|post-?mortem)\b", 3, "asks for a retrospective"),
        (r"\bwhat did we learn\b", 3, "asks for extracted lessons from a finished run"),
        (r"\b(recurring|repeated) (patterns?|failures?|mistakes?)\b", 3, "asks for recurring patterns across runs"),
        (r"\bacross (recent |the last )?sessions\b", 2, "asks for a cross-session view"),
        (r"\b(belief update|preserved anomal\w+|synthesi[sz]e patterns)\b", 2, "names a retrospective ledger artifact"),
    ],

    "review": [
        (r"\b(pr|pull request|diff|patch)\b", 2, "names a change under review"),
        # vs quality/tearitapart (see quality comment). review is a
        # POST-HOC verdict on a PR or staged diff: APPROVE/REQUEST
        # CHANGES/COMMENT. Requires an existing diff/PR, not a plan.
        (r"\breview (this |the )?(pr|pull request|diff|change(s)?|staged)\b", 3, "asks for a verdict on an existing pr or diff"),
        (r"\b(approve|request changes|comment) on (this|the) (pr|diff)\b", 3, "asks for a formal pr review verdict"),
        (r"\bis this (pr|diff|change) mergeable\b", 2, "asks whether a concrete diff is mergeable"),
    ],

    "ship": [
        # vs app-dev (see app-dev comment). ship is the git/PR release-gate
        # sequence (validate -> review -> push -> tag) for any repo, not
        # specifically mobile.
        (r"\b(push to main|ready to merge|release-?gate)\b", 3, "asks to run the release-gate sequence"),
        (r"\bship (this|it)\b", 2, "asks to ship the current change"),
        (r"\btag (a |the )?release\b", 2, "asks to tag a release"),
        (r"\bvalidate.{0,10}review.{0,10}push\b", 2, "names the ship sequence explicitly"),
    ],

    "simplify": [
        # vs architecture/diagnose (rule 3 cluster 7): simplify is a
        # MEASURED complexity-reduction pass (lizard/cyclomatic-complexity
        # numbers, per-function budget) with a verifier re-measuring --
        # narrower and more mechanical than architecture's structural
        # judgment or diagnose's refactor-mode analysis.
        (r"\b(cyclomatic complexity|lizard|complexity budget)\b", 3, "names a measured complexity metric"),
        (r"\bthis (function|file) is (too )?(spaghetti|a jungle|too complex)\b", 3, "reports unmeasured complexity needing reduction"),
        (r"\blower (the )?complexity\b", 3, "asks to reduce measured complexity"),
        (r"\bper-?function budget\b", 2, "names the per-function complexity budget"),
    ],

    "tearitapart": [
        # vs review/quality (see quality comment). tearitapart is PRE-
        # implementation: critique a PLAN before code exists. Verdict:
        # PROCEED / REVISE / RETHINK.
        (r"\b(tear apart|critique) (this |the )?plan\b", 3, "asks for a pre-implementation plan critique"),
        (r"\bwhat (would|will) (ai|this) break\b", 2, "asks what an approach will break before building"),
        (r"\bproceed, revise,? or rethink\b", 3, "asks for the tearitapart verdict scale explicitly"),
        (r"\bbefore (i|we) (start|implement) this,? (review|critique)\b", 3, "asks for critique before implementation starts"),
    ],
}


SKILL_DOMAINS: dict[str, tuple[str, ...]] = {
    "app-dev": ("software", "operations"),
    "architecture": ("software", "design",),
    "build": ("software",),
    "checkpoint": ("software", "research", "writing", "design", "operations", "strategy"),
    "context-mgmt": ("software", "research", "writing", "design", "operations", "strategy"),
    "debug": ("software",),
    "diagnose": ("software",),
    "dream": ("software", "research", "writing", "design", "strategy"),
    "eval": ("software",),
    "experiment": ("software", "strategy"),
    # forge: disable-model-invocation, never auto-suggested; domain kept for completeness only.
    "forge": ("software",),
    "frontend": ("design", "software"),
    "governance-sync": ("software", "operations"),
    "handoff": ("software", "research", "writing", "design", "operations", "strategy"),
    "help": ("software", "research", "writing", "design", "operations", "strategy"),
    "human-pass": ("software", "operations"),
    "ingest": ("software", "research", "writing", "design", "operations", "strategy"),
    "init": ("software", "operations"),
    "knowledge-graph": ("software",),
    "landing-page": ("design", "software", "strategy"),
    "marketing-site": ("design", "strategy", "writing"),
    "metrics": ("software", "operations"),
    "orchestration": ("software", "operations"),
    "quality": ("software",),
    "retrospective": ("software", "research", "writing", "design", "operations", "strategy"),
    "review": ("software",),
    "ship": ("software", "operations"),
    "simplify": ("software",),
    "tearitapart": ("software", "strategy"),
}


# Skills whose frontmatter sets `disable-model-invocation: true`. The model is not
# permitted to invoke these, so suggesting one is advice nobody in the room can
# take: the router would be telling the agent to do something the host forbids.
#
# This is DATA rather than a filesystem scan because the router runs as a
# subprocess on every prompt and should not stat five files to answer a question
# whose answer changes about twice a year. Drift is caught instead by
# test_never_suggest_matches_frontmatter, which reads the actual SKILL.md files.
# That is the same failure that left agents/dreamer.md documenting a design
# skills/dream/ had replaced three months earlier: a copy nothing checked.
NEVER_SUGGEST = frozenset({
    "forge",
    "experiment",
    "governance-sync",
    "init",
    "landing-page",
})


# Canonical probes: for each auto-invocable skill, one prompt phrased the way a
# person actually asks, which MUST reach that skill.
#
# These are the enforcement mechanism for "every skill is reachable", not
# decoration. A signal set can key every skill and still reach none of them if
# the regexes only match phrasings nobody uses -- which is exactly how the
# shipped frontmatter `Triggers:` lists failed, and how the first draft of this
# table failed for five skills (architecture, build, frontend, help,
# retrospective) until the probes caught it. Coverage is cheap to fake; a probe
# is not.
#
# Skills in NEVER_SUGGEST are deliberately absent: the model may not invoke them.
CANONICAL_PROBES: dict[str, str] = {
    "app-dev": "deploy the ios app to testflight via fastlane",
    "architecture": "the modules are too coupled, what should the interface boundaries be",
    "build": "generate two or three approaches for the export feature and pick the simplest",
    "checkpoint": "save a checkpoint, we are about to hit a context reset",
    "context-mgmt": "why is context degrading, what compaction strategy should we use",
    "debug": "the login endpoint crashes with a stack trace on a null token",
    "diagnose": "map the dependencies in the payments module before we restructure it",
    "dream": "explore competing approaches to this and stress test them",
    "eval": "set up pass@k capability evals for this ai workflow",
    "frontend": "the css layout breaks at 375px and the theme looks generic",
    "handoff": "write a handoff so the next session can continue this",
    "help": "what kernel skills are available",
    "human-pass": "what should I test by hand on the testflight build before we ship",
    "ingest": "start a new task: build the csv export feature",
    "knowledge-graph": "build a code knowledge graph to cut agent orientation cost",
    "marketing-site": "positioning and value proposition for the company marketing site",
    "metrics": "show me the session stats and hook performance dashboard",
    "orchestration": "spawn parallel agents with lane contracts for this tier 3 work",
    "quality": "run the big 5 check for input validation and edge cases",
    "retrospective": "look across recent sessions and find the recurring patterns",
    "review": "review this PR and tell me if it is mergeable",
    "ship": "push to main and tag the release",
    "simplify": "lower the cyclomatic complexity, this file is spaghetti",
    "tearitapart": "tear apart this plan before I start implementing it",
}
