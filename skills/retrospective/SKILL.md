---
name: retrospective
description: "Turn a finished run into a change to what you know and how the system is built, not a summary. Extracts surprises, belief updates, anomalies, and reusable primitives; compares against prior retrospectives; maintains evolving beliefs/patterns/anomalies/questions ledgers; proposes bounded architecture mutations. Triggers: retrospective, reflect, what did we learn, patterns, synthesis, post-mortem."
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
kernel:
  kind: state_transition
  version: 2
  side_effects: writes_repo
  confirmation: on_side_effect
  produces:
    - kernel.retrospective-result/v1
---

<skill id="retrospective">

<purpose>
Most retrospectives are obsessed with "what went well / badly / next time." That extracts
operational hygiene, not intelligence. The better question is: **what did this work teach us that
we did not know we were learning?**

A retrospective here is not a summary artifact. It is a memory-update process:

`work evidence -> surprises -> belief changes -> extracted patterns -> unresolved anomalies ->
reusable primitives -> new questions -> future experiments -> bounded architecture mutations`

Each run should CHANGE the accumulated model of how you work and what you know, not add one more
markdown gravestone. It does that by comparing against prior retrospectives and by writing to four
evolving ledgers, so a lesson learned twice is caught, a pattern with enough evidence is promoted,
and an old belief that no longer holds is retired.

Anti-convergence rule, load-bearing: AI is extremely eager to explain everything. Sometimes the
highest-value move is keeping a weird result alive, unexplained, long enough for three future
projects to reveal what it means. The `anomalies` ledger exists for exactly that. Do not resolve
an anomaly you cannot yet explain; preserve it.
</purpose>

<on_start>
agentdb read-start   # prior learnings seed the analysis
# Load the four ledgers if they exist; they are the memory this process updates.
for L in beliefs patterns anomalies questions; do
  cat "_meta/ledgers/$L.jsonl" 2>/dev/null | tail -40
done
# Load the last 3 retrospectives to compare against, NOT to re-derive from scratch.
ls -t _meta/reports/retrospective-*.md _meta/reports/retrospective-*.json 2>/dev/null | head -3
</on_start>

<!-- ============================================================ -->
<!-- PHASE 1 — EVIDENCE. The raw material, not opinion about it.  -->
<!-- ============================================================ -->
<phase id="1_evidence" name="Gather the run's real evidence">
The retrospective reasons from what happened, never from the tidy story of what happened. Pull:
- `git log`, the diff, rejected attempts (reverted commits, abandoned branches), and commit
  messages, which are where knowledge hides.
- Debugging sessions, failed test runs, escalations, and anything the run did that nobody
  explicitly designed.
- AgentDB learnings + checkpoints from the run: `agentdb query "SELECT id,type,insight,evidence,hit_count,COALESCE(last_hit,ts) FROM learnings ORDER BY ts DESC"` and `agentdb recent`.
- For a run that produced receipts, the return rows / verdicts / CHECK outputs, not the summary.

Evidence is what you can quote. If a claim in the retrospective cannot be traced to a commit, a
log line, a receipt, or a recorded decision, mark it inference, not finding.
</phase>

<!-- ============================================================ -->
<!-- PHASE 2 — INTELLIGENCE. What did we learn without noticing?  -->
<!-- ============================================================ -->
<phase id="2_intelligence" name="Extract what you did not know you were learning">
Do NOT run every question every time. Run the lens that bites for this run. Three are MANDATORY
(surprise, belief-update, preserve-without-understanding); the rest are drawn on as the evidence
warrants. Answer with evidence, in one or two lines each, never a wall.

<lens id="surprise" mandatory="true">
- What surprised me? What should have surprised me but did not?
- Where was my prediction most wrong? What did reality refuse to behave like?
- What became obvious only after doing the work? What looked hard but was easy, easy but hard?
</lens>

<lens id="belief_update" mandatory="true">
- What did I believe before that I believe less now? What belief got stronger?
- What assumption survived only because nobody tested it?
- What would "me before this project" reject that I now think is true?
Every real answer here is a write to the `beliefs` ledger with a confidence and the evidence.
</lens>

<lens id="hidden_knowledge">
- What do I now know how to do that I could not easily explain? What became instinctive?
- What did I repeatedly notice before I had words for it?
- What knowledge exists only in commits, debugging, conversations, or rejected attempts, and
  would disappear if everyone who worked on this forgot it tomorrow? That goes in a ledger now.
</lens>

<lens id="counterfactual">
- If I restarted knowing what I know now, what would I delete entirely? What would I do 10x earlier?
- Which constraint was actually useful? If the winning approach had been impossible, what next?
- What almost worked, and under what changed condition might it win? (-> `anomalies` if unresolved.)
</lens>

<lens id="anomaly">
- What result does not fit my current explanation? What happened once that deserves investigation
  rather than dismissal? What did the system do that nobody designed?
- Where did two supposedly equivalent approaches diverge?
Unexplained anomalies are PRESERVED in the ledger, not explained away. See the anti-convergence rule.
</lens>

<lens id="abstraction">
- What is the general principle hiding inside this specific problem? Where else does it appear?
- What did I build manually that is secretly a reusable primitive? Can I name the pattern?
- What distinction did this project give me language for that I lacked? What must be true for the
  lesson to generalize? (Weak-evidence generalizations go to `questions`, not `patterns`.)
</lens>

<lens id="novelty_mining">
- What side discovery is more interesting than the thing we built? What problem did solving this
  expose underneath it? What did we accidentally invent?
- What capability exists now that makes a previously impossible idea cheap? What adjacent
  experiment just became cheap enough to try? If this were a research finding, what is the next
  experiment?
</lens>

<lens id="negative_space">
- What never became a problem despite expecting it to? What question did nobody ask?
- What received suspiciously little attention? What are we optimizing only because everyone does?
- What important thing is absent from our metrics? What would an outsider find bizarre about how
  we did this?
</lens>

<lens id="trajectory" note="highest long-term value">
Compare against the last 5 retrospectives, not this run alone:
- What keeps recurring across my last 5 projects? Which mistakes are one mistake in different clothes?
- Which discoveries keep independently reappearing (a signal the problem forces them)?
- What am I becoming unusually good at without choosing to? What problems keep finding me?
- What am I repeatedly building around because I have not named the missing primitive yet?
A convergent-evolution finding here (the same structure invented independently 3+ times) is the
strongest promotion evidence a `pattern` can have.
</lens>
</phase>

<!-- ============================================================ -->
<!-- PHASE 3 — ARCHITECTURE. Questions that can mutate the system. -->
<!-- ============================================================ -->
<phase id="3_architecture" name="What should change about how the system is built" domain="software|architecture|infra">
For architecture/infra/agent-runtime work, ask questions that can mutate the system, not just
describe the work. Draw the ones that bite:

**Autonomy boundary**
- What required human intervention that should become deterministic?
- What decision should have been local instead of escalated, or escalated instead of local?
- Where did autonomy create risk without meaningful speed? Where did a safety constraint create
  friction without meaningful protection?
- What action was reversible enough to allow more autonomy? What irreversible action lacked a gate?

**Information and state**
- What did an agent need but fail to have at decision time? What arrived too late?
- What did we retrieve repeatedly that should become persistent context? What was loaded
  repeatedly but almost never useful?
- What state existed only in someone's head or chat? What should become machine-readable state,
  and what should STOP being machine-readable and remain judgment?
- What source became the real source of truth despite the architecture saying otherwise? Where are
  there competing sources of truth?

**Verification and failure**
- Where did an agent guess instead of verify? Where did verification cost more than the task?
- What failure was detectable earlier? Detectable only by another agent? Invisible until a human
  noticed?
- What did "done" actually mean here? Could completion have been mechanically verified? What
  evidence was missing when it claimed completion?

**Coordination**
- Where did two agents duplicate work? Where did parallelism reduce quality?
- What coordination happened conversationally that should become protocol? What protocol do agents
  routinely work around (a signal the protocol is wrong)?

**The intelligence/structure boundary** (the deepest lens)
- What rule belongs in code, what in prompting, what in evaluation?
- What behavior are we solving with increasingly complicated prompts (an architecture smell)?
- Where are we using intelligence to compensate for missing structure? Where are we using
  structure to compensate for something models now handle reliably?
- What expensive model call could become retrieval, grep, computation, cache, or deterministic
  code? What deterministic stage is preventing useful reasoning?

**Memory**
- What memory should expire, what should compound? What should agents forget automatically, what
  should future agents inherit from this run?
- What did one agent learn that the others should have known? What should propagate globally vs
  stay task-local?

**Proactivity and observability**
- What work could have happened asynchronously or proactively before anyone asked? What trigger
  could have started it automatically?
- What observability would have shortened this incident most? What did logs tell us that outputs
  did not? What happened that telemetry cannot currently explain?

**Complexity honesty**
- Which component earned its complexity? Which exists because of a problem we no longer have?
- If we deleted one layer tomorrow, which would we test first?
- What would we decide differently if models got 3x better next year? If they stopped improving
  tomorrow?

<synthesis>
Force the answers into AT MOST 3 architecture-mutation proposals. Fewer is better. For each:
`evidence | root cause | proposed change | expected benefit | new failure modes | reversibility |
implementation cost | confidence | what future evidence would prove this change wrong`.

Then the ANTI-OVERENGINEERING GATE, mandatory, applied to every proposal before it is recorded:

> Is this a recurring architectural signal, or merely an unusual instance? Find evidence across
> previous runs (the ledgers, prior retrospectives, git history) BEFORE recommending permanent
> infrastructure. One occurrence is an anomaly to preserve, not an architecture to build.

A proposal that cannot cite cross-run evidence is demoted to a `questions` ledger entry with a
"watch for recurrence" note. It does not become a build. This gate is the counterweight to the
model's eagerness to generalize from one dramatic instance.

The loop this closes: `run -> evidence -> anomaly -> root cause -> architecture hypothesis ->
cross-run evidence -> bounded mutation -> measure -> keep/revert`. A mutation ships bounded and
reversible, with the future evidence that would revert it named in advance.
</synthesis>
</phase>

<!-- ============================================================ -->
<!-- PHASE 4 — LEDGERS. The memory this process actually updates.  -->
<!-- ============================================================ -->
<phase id="4_ledgers" name="Update the four evolving ledgers">
Retrospectives stop being a graveyard of summaries only if each one writes to a memory that
accumulates. Four ledgers under `_meta/ledgers/`, one JSONL each. Compare against them, do not
re-derive from zero.

- **`beliefs.jsonl`** — `{id, belief, confidence: 0..1, evidence[], first_seen, last_updated, status: active|weakened|retired, supersedes}`. Current beliefs about the domain and how the work behaves.
- **`patterns.jsonl`** — `{id, name, structure, instances[] (run refs), confidence, status: watching|promoted|principle}`. Recurring structures across projects. A pattern with 3+ independent instances is a promotion candidate to a principle (and to an artifact, phase 5).
- **`anomalies.jsonl`** — `{id, observation, context, why_unexplained, seen_in[], preserve_until_condition}`. Unexplained observations kept ALIVE on purpose. Never delete an anomaly to tidy up; retire it only when an explanation is earned, and record the explanation.
- **`questions.jsonl`** — `{id, question, why_interesting, got_more_interesting_when[], candidate_experiment}`. Questions that became more interesting over time. This is where under-evidenced generalizations and one-instance architecture ideas wait for their third data point.

Then run the cross-retrospective comparison, explicitly, as the core of the phase:

> What is genuinely NEW here? What have we already learned before (a recurrence, not a discovery)?
> What CONTRADICTS previous learning? What recurring pattern now has enough evidence to promote
> into a principle? What old principle should be WEAKENED or RETIRED?

A belief that this run contradicts is weakened or retired with the contradicting evidence, not
silently overwritten. A lesson that appears for the Nth time is flagged as recurrence (a lesson
learned twice was not learned) and escalates toward an enforceable artifact rather than another
note.

Periodically (not every run), ask the long-horizon question, and record the answer as a belief:

> What architecture is the accumulated evidence trying to turn us into?

That is: read the ledgers as a trajectory and infer the target the evidence is pointing at, rather
than deciding the target architecture upfront and bending runs to fit it.
</phase>

<!-- ============================================================ -->
<!-- PHASE 5 — HYGIENE + PROMOTION. The old machinery, kept.       -->
<!-- ============================================================ -->
<phase id="5_hygiene" name="Housekeeping and artifact promotion">
The operational-hygiene pass still runs, demoted below intelligence but not removed. A promoted
pattern that stays a sentence is honor-system; an artifact fires on its own.

1. **Clusters / duplicates / contradictions** in AgentDB: group by theme, merge duplicates into
   the strongest form, resolve contradictions with evidence and archive the loser.

2. **Stale archival, with the protected-set subtraction (do not skip this).** Flag only rows whose
   last recall (or `ts` when never recalled) is older than 30 days:
   `COALESCE(last_hit, ts) < datetime('now','-30 days')`. `last_hit` alone is NOT sufficient to
   delete: an injection rule fires a learning without stamping it, and `agentdb learn`'s dedup
   path bumps `hit_count` and leaves `last_hit` null. Before archiving ANY row, subtract:
   - rows referenced by a `learning_id` in the project's injection rules, and
   - rows with `hit_count >= 5` (a recall record the stamp failed to reflect).
   Measured 2026-08-27 in Vaults: the bare predicate named 22 rows, 11 protected, including the
   most-recalled row (`hit_count` 125). Archiving on the bare predicate is silent and irreversible.
   Reference: `_meta/services/agentdb-archive-guard.py`.

3. **Promote via the artifact ladder** (most enforceable form that fits, never default to prose):
   - **Hook** for a safety property or mechanical check (I0.15: hooks, not honor-system). And per
     the strongest session lesson below: **put the check on the path the work must take.** A hook
     beside the path drifts; a hook on the chokepoint holds.
   - **Agent** for a recurring role with its own judgment.
   - **Skill** for methodology: a repeatable HOW.
   - **CLAUDE.md prose** last resort, only for context no mechanism can enforce.
   Scaffold means WRITE THE FILE this session. A promoted pattern needs 2+ instances OR a single
   quiet/expensive failure mode. Cross-check the anti-overengineering gate: promotion to permanent
   infrastructure requires cross-run evidence, same bar as an architecture mutation.

   <ask_user>
     Use AskUserQuestion when promotable patterns or prune candidates exist.
     Ask: "Found {N} promotable patterns and {M} architecture proposals. Scaffold / propose which?"
     Prune candidates (dormant skills/agents) always require explicit approval.
   </ask_user>
</phase>

<!-- ============================================================ -->
<!-- PHASE 6 — RECORD.                                             -->
<!-- ============================================================ -->
<phase id="6_record" name="Emit the mutation record">
Write `_meta/reports/retrospective-{date}.json` per schemas/kernel.retrospective-result.v1.schema.json:
- identity: {created: ISO 8601, session, scope} — REQUIRED, no top-level `date`.
- analyzed: learnings/clusters/merged/archived/contradictions_resolved counts.
- mutations[]: every artifact touched AND every ledger write —
  {op: create|modify|remove|promote|weaken|retire, artifact_type: hook|agent|skill|prose|learning|belief|pattern|anomaly|question|architecture, path, reason, evidence, reinforced, status: applied|scaffolded|proposed|rejected}.
- intelligence: {surprises[], belief_updates[], anomalies_preserved[], primitives_named[], recurrences[], architecture_proposals[]} — the new payload; empty arrays are allowed but the keys are not.
- project_fit: missing[] and dormant[] as arrays of STRINGS.

Validate:
```bash
"${CLAUDE_PLUGIN_ROOT:-.}/orchestration/manifest/kernel-manifest" validate _meta/reports/retrospective-{date}.json
```
Then AgentDB:
```bash
agentdb write-end '{"did":"retrospective","new_beliefs":N,"weakened":N,"anomalies_preserved":N,"patterns_promoted":N,"architecture_proposals":N,"mutation_record":"_meta/reports/retrospective-{date}.json"}'
```
</phase>

<output_format>
## Retrospective, {date} — {what this run was}

### What is genuinely new
{the discoveries, vs what turned out to be recurrence of a known lesson}

### Surprises
{prediction vs reality, with evidence}

### Belief updates
{believe less / believe more / retired, each with the contradicting or confirming evidence}

### Preserved without understanding
{anomalies kept alive on purpose, and the condition under which to revisit}

### Reusable primitives named
{what was built manually that is secretly a primitive, with the name given to it}

### Trajectory
{what recurs across the last 5 runs; the mistake wearing different clothes; the unnamed missing primitive}

### Architecture proposals (<=3, or none)
{each: evidence | root cause | change | benefit | new failure modes | reversibility | cost | confidence | disproving evidence — all past the anti-overengineering gate}

### Ledger writes
- beliefs: +{N} / weakened {N} / retired {N}
- patterns: +{N} / promoted {N}
- anomalies: +{N} preserved
- questions: +{N}

### Hygiene
- Merged {N}, archived {N} (protected-set subtracted), contradictions resolved {N}
- Artifacts promoted: {pattern} -> {hook|agent|skill} at {path}

### Mutation record
- `_meta/reports/retrospective-{date}.json` (validated)
</output_format>

<seeds note="founding lessons from the 2026-09-01 refusal-runtime session; the ledgers start here">
These are the first entries the ledgers should carry, because they were earned across a
234-system survey plus a self-graded build session and already have cross-run evidence.

beliefs:
- "Autonomy comes from mechanical refusal on a chokepoint, not from better reasoning." conf 0.9 —
  234 systems: every one that ran unattended had a scorer outside the agent's authority; the two
  most advanced removed discretion (Bernstein, Paperclip).
- "A rule beside the path drifts; a rule on the path holds." conf 0.9 — two guards out of a whole
  stack had ever refused anything; both sat on chokepoints. The permission gate beside the path
  denied 0 of 1,179.
- "Knowing a failure class does not prevent committing it; only a check does." conf 0.85 — an
  author shipped three self-authorization defects hours after writing three documents against them.
- "Frequency is not consent: never expand authority from a count of past behaviour." conf 0.9 —
  the difference between a corpus grader and graduated autonomy.
- "Storage is not retrieval: a lesson recorded and not fired at the moment of action is a cost."
  conf 0.8 — an agentdb learning was relearned as new 81 days after it was written.

patterns (watching -> promote on the 3rd independent instance):
- "theatre has three kinds: by design (vacuous assertion), by wiring (real check never installed),
  by starvation (installed check, no data)." 3 instances already (TBS, tooling, lane-ledger).
- "the human-at-the-wheel corpus is an oracle: (situation, response, verdict) answers both what to
  do next and whether output is good." 1 strong instance (the Refusal Runtime); watch for reuse.
- "seed the real defect into the instrument in an isolated copy before trusting it." recurring good
  habit (test-capability.sh, instrument-breaker, instruction-surface-check).

anomalies (preserved, not explained):
- "catcher ratio held near 1-in-3 mechanical across four independent defect censuses AND on the
  session author's own 8 mistakes. Why that specific ratio? Unknown. Preserve until a fifth census."

questions:
- "what architecture is the accumulated evidence trying to turn us into?" — the long-horizon
  question; revisit when the ledgers have 5+ runs.
- "objective generation is unbuilt in all 234 systems and in ours. Is it genuinely hard, or just
  gated on a grader nobody had? Watch whether the corpus-grader makes it cheap."
</seeds>

</skill>
