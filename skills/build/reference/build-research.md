# Build Skill Reference: Research & Best Practices

Reference document for the build skill. Read when deeper context is needed.
Not auto-loaded; read on demand via progressive disclosure.

## Sources

Martin Fowler (Refactoring, Feb 2026 fragments), Sandi Metz, Kent Beck, Ron Jeffries,
Jeff Atwood, Derek Comartin, Anthropic agent building guide, NASA shuttle IID,
ICSE 2026 Cognitive Biases paper (arXiv 2601.08045), DORA 2025 AI Impact Report,
Addy Osmani LLM Workflow (Dec 2025), Sonatype 2026 Supply Chain Report, Thoughtworks
Future of Software Development Retreat (Feb 2026).

---

## AI as Amplifier (DORA 2025)

DORA 2025 AI Impact Report: "AI is an amplifier, not a solution."
- For high-performing teams with solid foundations, AI accelerates.
- For teams with technical debt and chaos, AI magnifies problems.
- 90% of tech professionals now use AI; 80% believe they're more productive.
- BUT: 30% have little to no trust in AI-generated code.
- AI adoption correlates with higher instability: more change failures,
  increased rework, longer cycle times.

Platform quality is the difference-maker. High-quality platforms amplify
AI benefits; low-quality platforms see negligible impact.

---

## Cognitive Debt (Fowler, Feb 2026)

New concept from Thoughtworks retreat: When LLMs handle coding, teams risk
losing deep system understanding. "Cognitive debt" accumulates when developers
don't build mental models of their domains.

TDD and refactoring serve as forcing mechanisms to maintain understanding.
Fowler: "TDD served a critical function: it kept me in the loop."

The "middle loop" concept: A new supervisory engineering loop between inner
(write/test/debug) and outer (CI/CD/deploy), involving directing, evaluating,
and fixing AI agent output.

---

## The Core Principle: Simplicity Wins

Every authoritative source converges on the same finding: simpler solutions
outperform complex ones across every meaningful dimension. Maintenance cost,
bug rate, onboarding time, modification speed, deployment confidence.

Anthropic's own agent building guide (Dec 2024): "The most successful
implementations use simple, composable patterns rather than complex
frameworks." And: "Do the simplest thing that works."

Jeff Atwood (Coding Horror): "Developers tend to be far too optimistic
in assessing the generality of their own solutions, and thus end up
building elaborate frameworks around things that may not justify that
level of complexity."

The evidence is consistent: complexity is the default failure mode of
software. Every line of code is a liability. The build skill exists to
fight this default.

---

## YAGNI: The Most Violated Principle

"You Aren't Gonna Need It." From Extreme Programming (Kent Beck, Ron
Jeffries). Ron Jeffries: "Always implement things when you actually need
them, never when you just foresee that you will need them."

YAGNI is not about being short-sighted. It's about grounding decisions
in evidence rather than speculation. Three costs of violating YAGNI:

1. Cost of building: time/effort spent on unused features.
2. Cost of carry: unused code still needs maintenance, testing, updating.
3. Cost of delay: building speculative features delays real features.

The idatamax engineering guide puts it precisely: "YAGNI violations
usually don't look wrong; they look smart and prepared. That's why
they're dangerous: they accumulate quietly, until the cost of unused
code outweighs its imagined benefit."

Derek Comartin's key insight on premature abstraction: if you create an
interface for a single implementation (e.g., ISmsService for only Twilio),
you're building on insufficient context. When the second provider arrives,
your abstraction is wrong anyway because it was shaped by Twilio's specific
needs. You've added complexity AND you'll need to refactor. Double cost.

Practical rule: "The code you don't write is the easiest to maintain."

---

## The Rule of Three (Fowler, Roberts)

Martin Fowler, "Refactoring" (1999), attributed to Don Roberts:

"The first time you do something, you just do it.
The second time you do something similar, you wince at the duplication,
but you do the duplicate thing anyway.
The third time you do something similar, you refactor."

Why not refactor at two? Because two instances may be similar for
accidental reasons. They might diverge as understanding deepens.
Premature abstraction produces vague, over-general categories that
obscure more than they clarify.

Sandi Metz's corollary: "It is better to have some duplication than
a bad abstraction." A wrong abstraction is more expensive than
duplication because it affects every future consumer of that abstraction
and requires understanding its generalized interface rather than the
specific case.

Wikipedia's page on the Rule of Three notes: "Attempting premature
refactoring risks selecting a wrong abstraction, which can result in
worse code as new requirements emerge."

Research from eoinnoble.com investigating the origins: no empirical
evidence exists for "three" being a magic number. But the underlying
wisdom is sound: wait for enough examples before generalizing.

For our system: this is why KERNEL says "three similar lines beats
abstraction." Duplication is visible and local. Bad abstractions are
hidden and global.

---

## Solution Exploration: Why Multiple Approaches Matter

The build skill's requirement to generate 2-3 solutions before
implementing is grounded in two principles:

1. First-solution bias (anchoring). The first idea anchors your thinking.
   Everything after is evaluated relative to it rather than on absolute
   merit. Generating alternatives forces re-evaluation from scratch.

   **ICSE 2026 validation** (arXiv 2601.08045): First quantitative data on
   first-solution bias with AI: **43.4% reversal rate** for fixation bias.
   **56.4% bias rate** in LLM-related interactions (higher than non-LLM work).
   "Anchoring can be debiased when multiple opinions are given at the same time."

2. Iterative refinement. NASA's shuttle software (1977-1980) used 17
   iterations over 31 months, averaging 8 weeks per iteration. Their
   motivation: "requirements changed during the software development
   process." The DoD's MIL-STD-498 explicitly encourages evolutionary
   acquisition over single-step approaches. If NASA and the DoD found
   that iterating on approaches produces better outcomes, your feature
   can benefit too.

The practical application: don't just compare approaches abstractly.
Evaluate on concrete, ordered criteria:

1. Lines of code (less = fewer bugs, easier to review)
2. Dependency weight (popular + maintained = battle-tested)
3. Edge case surface area (fewer special cases = more reliable)
4. Modification cost (how hard to change when requirements shift)
5. Performance (only if measured bottleneck exists)

Note: performance is LAST. Knuth's "premature optimization is the root
of all evil" remains the most quoted and most violated maxim in computing.

---

## Research Before Implementation

The build skill's research-first approach is grounded in Anthropic's
context engineering philosophy: "Rather than pre-processing all relevant
data up front, agents transition from static, pre-loaded data to
autonomous, dynamic context management."

Applied to building: don't start implementing until you know:
- What existing packages solve this problem (and their download stats)
- What common pitfalls exist (search "X not working" before "how to X")
- What patterns already exist in the codebase (the scout agent's output)
- Whether the framework/language has a built-in solution

The research inversion (from the research skill) applies here too:
search for problems before solutions. Forums, GitHub issues (closed with
solutions), and Stack Overflow questions reveal the real failure modes
that tutorials and docs omit.

A package with 1M+ weekly npm downloads has had millions of users find
and report its edge cases. Your hand-rolled solution has had one: you.

---

## Incremental Delivery: Build Piece by Piece

From iterative development research (Larman & Basili, IEEE Computer):
iterative and incremental development has a documented history of
success dating to Project Mercury in the 1960s. Key finding: every
successful large-scale project they studied used some form of
incremental delivery.

The RUP (Rational Unified Process) formalized this as "risk-value
lifecycle": tackle the highest-risk, highest-value components first.
If those fail, you fail early and cheaply. If they succeed, you have
confidence to continue.

Applied to our system:
- Build the core feature first. Verify it works.
- Add error handling. Verify it works.
- Add edge case handling. Verify it works.
- Each step is a commit. Each commit is a working state.

The surgeon agent's "commit after each working state" rule comes
directly from this principle. If you can't commit, you haven't
reached a working state. If you've been coding for 30 minutes without
committing, you're building too much at once.

---

## DRY vs. KISS: When They Conflict

DRY ("Don't Repeat Yourself," Hunt & Thomas, The Pragmatic Programmer,
1999) and KISS ("Keep It Simple, Stupid," U.S. Navy, 1960) are both
foundational principles, but they conflict regularly.

The DRY formulation most people know is incomplete. The original:
"Every piece of KNOWLEDGE must have a single, unambiguous, authoritative
representation within a system." Note: knowledge, not code. Two functions
that happen to look similar but represent different domain concepts should
NOT be merged.

When they conflict, community consensus is clear: KISS wins.

From DEV.to discussion with hundreds of reactions: "KISS should take
precedence over DRY when conflicting. DRY is hard, even if it doesn't
seem like that." The reasoning: DRY violations are visible and greppable.
KISS violations are invisible and systemic.

Practical heuristic: if your DRY refactoring makes the code harder to
understand at the call site, you've violated KISS. Revert it.

---

## Package Selection Framework

When the build skill evaluates packages, use these criteria (ordered):

1. Weekly downloads (npm) or monthly downloads (pypi)
   Threshold: 100K+/week npm, or consistent upward trend on pypi.
   Why: download count is a proxy for "how many people have found and
   reported edge cases."

2. Last meaningful update
   Threshold: within 6 months.
   Exception: stable, "finished" packages (e.g., lodash) that don't
   need updates.

3. Open issue count and type
   Check for: security issues (critical), breaking bugs (important),
   feature requests (noise, ignore).

4. Bundle size / dependency weight
   Check: package size, transitive dependencies.
   A package that pulls in 200 sub-dependencies for one function is
   a liability.

5. API surface simplicity
   Less API = easier to use correctly.
   A package that needs 3 lines to do the job beats one that needs 15
   with configuration objects.

6. TypeScript support
   First-class types > DefinitelyTyped > no types.
   Types are documentation that the compiler verifies.

---

## Plan Document: Why 50 Lines Max

The build skill caps plans at 50 lines. This isn't arbitrary.

A plan is a communication artifact. Its audience is: you in 30 minutes,
you tomorrow, the surgeon agent, and the adversary agent. All of them
need to understand what's being built, why, and how to verify it's done.

If the plan exceeds 50 lines, one of three things is true:
1. The feature is too large (split it).
2. The plan contains implementation details (remove them; that's the
   surgeon's job).
3. The plan is hedging (too many alternatives, caveats, contingencies).

A good plan answers five questions in simple language:
- What are we building?
- What does "done" look like?
- Which approach are we using (and why not the alternatives)?
- What are we NOT building (scope boundary)?
- What could go wrong (top 2-3 risks)?

Everything else is implementation detail or anxiety.

---

## Anti-Patterns in Building

### Gold Plating
Adding features beyond requirements to make the code "complete" or
"robust." Every feature added increases surface area for bugs, testing
requirements, and maintenance burden.

### Resume-Driven Development
Choosing technologies because they're impressive, not because they're
appropriate. Kubernetes for a single-server app. GraphQL for a CRUD form.
Microservices for a two-person team.

### Architecture Astronautics
Designing elaborate abstractions for problems that don't exist yet.
Joel Spolsky coined this term for developers who "solve problems they
don't have yet, and create real problems in the process."

### Dependency Hoarding
Adding a package for every small utility. Each dependency is a trust
decision, a supply chain risk, and a maintenance obligation. Left-pad
taught this lesson. If it's 10 lines of code, write it yourself.

### Premature Performance Optimization
Optimizing before measuring. Knuth: "We should forget about small
efficiencies, say about 97% of the time: premature optimization is
the root of all evil." First make it work. Then make it right. Then
(and only then, if measured profiling shows a bottleneck) make it fast.

### Planning Paralysis
Spending more time planning than building. The plan is a starting
point, not a contract. Build something, learn from it, adjust.
Iterative development research consistently shows that the plan
improves as you build, not before.

---

## Integration with KERNEL System

The build skill enhances the surgeon agent and orchestrator during
feature work. Key integration points:

- Research agent runs BEFORE build: researcher outputs the package
  evaluations and pitfall docs that build references. Never build with
  unfamiliar tech without researcher output.

- Planning protocol in CLAUDE.md: requires 2-3 solutions. Build skill
  provides the evaluation criteria for choosing between them.

- Contract scope: if tier 2+, the contract defines what the surgeon
  builds. Build skill methodology applies within contract bounds. The
  surgeon doesn't re-plan; they execute the chosen approach.

- Validation: build skill's validation checklist (tests, lint, types,
  edge cases) feeds into the validator agent's pre-commit gate.

- tearitapart: for tier 2+, the plan is reviewed via tearitapart
  BEFORE the surgeon starts. Build methodology feeds plan creation;
  tearitapart validates it.