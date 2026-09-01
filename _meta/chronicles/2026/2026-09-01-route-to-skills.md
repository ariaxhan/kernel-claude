---
type: note
status: active
created: 2026-09-01
tier: 2
---

# Routing to skills, after an audit found 12 of 26 had never been invoked

## What was attempted

A usage audit over 9,642 Claude sessions, 1,180 Codex sessions and 90 agentdb files found:

- 12 of 26 skills had never been invoked once, by a human or by the model.
- 5 skill invocations in the entire history of the machine were typed by a person.
- The router, meanwhile, announced a domain pack 8,578 times.

The mechanism that works was never wired to the library that does not. Aria's instruction was
explicit: do not delete any skill, make all of them properly used.

## What actually changed

- `orchestration/router/skill_signals.py`: 114 weighted signals covering all 29 skills, same
  shape as the existing `DOMAIN_SIGNALS`. Plain tuples, zero imports, standalone testable.
- `classify_skills()` in `kernel_router.py`, a `skills` field on the classification, and a
  confident skill match now sets `announced`. Without that last part, suggestions would only
  ever reach gated or protected work, which is the work least in need of a pointer.
- `route-request.sh` prints one imperative line naming the skill and the evidence.
- `tests/kernel9/test_skill_routing.py`: coverage, reachability, disambiguation, fail-open, and
  a never-suggest set checked against the actual frontmatter.
- `scripts/skill-adoption.py`: joins suggestions against invocations to produce an adoption rate.

## Verified live

- Full suite: 509 passed, 1 failed. The failure (`detect_vaults finds primary`, expecting
  `~/Vaults`) reproduces on stashed pre-change code, so it predates this work.
- `python3 -m unittest discover -s tests/kernel9` -> 144 tests, OK.
- End-to-end through the real hook: a crash report reaches `debug`, a plan critique reaches
  `tearitapart`, "what is the weather" reaches nothing.
- **Both gates broken on purpose and confirmed to catch it**, per the runtime's rule 4:
  removing `metrics` from the table failed the coverage test; blanking the `retrospective`
  regexes failed the reachability test with the exact prompt that stopped working.

## What failed

**Coverage is not reachability, and I nearly shipped the difference.** The first table keyed all
29 skills and passed every coverage assertion. Five skills (architecture, build, frontend, help,
retrospective) were still unreachable, because the regexes only matched phrasings nobody uses.
`help` wanted "what skills exist" and missed "what skills are available". That is the same
failure as the frontmatter `Triggers:` lists it was replacing, reproduced one layer down.

The fix is `CANONICAL_PROBES`: each skill declares one prompt phrased the way a person actually
asks, and a test proves that prompt reaches it. A coverage test is cheap to satisfy by adding a
key. A probe is not.

**I also called two skills unreachable that were correctly excluded.** `landing-page` and
`marketing-site` looked broken until I checked the frontmatter: five skills set
`disable-model-invocation: true`, so the model may not invoke them and suggesting one is advice
nobody in the room can take. I had hardcoded that set as `{"forge"}` from a subagent's note
rather than reading the five files. Now derived as data and asserted against the frontmatter.

**A `git stash` during a test run was nearly a real loss.** I stashed to check whether a failing
test predated my change; the command hit its two-minute timeout and was killed before
`git stash pop` ran. Every tracked edit sat in a stash while the working tree looked half-done.
Recovered intact, but the runtime's own warning about stashing exists for exactly this, and the
correct move was `git worktree`-free: read the test, or run it on a copy.

## Deferred

- Three kernel-claude branches (`fix/226-stale-r6-and-noise`,
  `fix/guard-precision-and-autocorrect`, `improve/retrospective-intelligence`) carry unmerged
  commits. `git branch -D` requires Aria's approval token by design; two are on origin so
  nothing is at risk.
- 26 dirty submodules under `CodingVault/`, four of them live client repos under the PR-only
  rule. Not touched; that is 26 decisions, not a cleanup.
- The four highest-leverage audit fixes (trim `session-start.sh`, rewrite `chronicle-gate.sh`,
  teach `guard-bash.sh` that quoting is not running) are still recommendations.

## Disagreement worth inheriting

The adoption rate this ships cannot yet be read as a verdict on the routing. `skill-adoption.py`
credits a skill whose name appears in any Skill call in the same session, which biases the
number up, and there is no pre-period to compare against because suggestions were never logged
before today. The honest reading of the first month is "did anything move at all", not "routing
works". Say that when the number arrives.
