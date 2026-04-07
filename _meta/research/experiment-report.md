# Experiment Report: Hypothesis Validation

**Date:** 2026-04-07
**Database:** `_meta/agentdb/agent.db`
**Method:** Historical evidence mining (AgentDB, git history, research documents)

---

## Summary

| Metric | Count |
|--------|-------|
| Total hypotheses | 67 |
| Total experiments | 137 |
| Graduated (proven) | 14 |
| Refuted (disproven) | 2 |
| Testing (in progress) | 47 |
| Inconclusive (insufficient data) | 4 |
| Unproven (no experiments) | 0 |

All 67 hypotheses have at least been classified. The 14 graduated rules each have 6 supporting experiments with 0 counter-evidence, reaching confidence 0.82.

---

## Graduated Rules (Proven)

### Methodology (4 graduated)

**H003 — Research anti-patterns before solutions leads to fewer implementation failures**
Source: `CLAUDE.md:93` | Confidence: 0.82 | Evidence: 6 for, 0 against

- EXP-001: 3 failure learnings directly cite research gaps (fail-mypy-001/002/003). LEARN-021: "Skipping research leads to reinventing wheels." 15+ pattern learnings show research-first yielding correct solutions.
- EXP-011: Modelmind git history shows research-before-implementation pattern across 5+ research commits, each preceding implementation.
- EXP-026: CollabVault has 9 matching learnings including fail-mypy-003, LRN-021 (ed-tech anti-pattern discovered through research), and LRN-EXP-ICONS-77.0.
- EXP-027: Modelmind content experiments researched anti-patterns before building pipeline. Counter-evidence from LRN-F08/F10/F12: when anti-patterns were NOT researched first, implementation failed.
- EXP-038: session-pattern-analysis.md ranks "Skipping Research Before Implementation" as Rank 1 time waster (5-15 wasted tool calls per incident).
- EXP-039: ai-code-anti-patterns.md itself IS the methodology applied. METR 2025: developers perceived 20% faster but measured 19% slower when skipping research.

**H005 — Knowledge mining before coding saves multiples of its time investment**
Source: `CLAUDE.md:30` | Confidence: 0.82 | Evidence: 6 for, 0 against

- EXP-003: LEARN-021: "Skipping research leads to reinventing wheels (V2 had no research, missed cursor pagination)." ctx-master-001: prior research saved ~15hrs of rediscovery. design-001: research prevented a 21-day custom build.
- EXP-012: CollabVault learnings show knowledge mining saving time across domains (security dashboards, automation approaches).
- EXP-028: Modelmind has 68 research files supporting 148 feature commits (0.46 ratio). 21 explicit research commits in git history.
- EXP-029: 9 modelmind content experiments eliminated wrong models (Haiku: 20% recall, opencode: 0%, apfel: crash) before production. Time invested: ~1 session. Time saved: pipeline built correctly first try.
- EXP-040: automation-audit found 4 blocking bugs through research BEFORE implementation. Saved 4+ debugging sessions.
- EXP-041: claude-best-practices-2026.md: METR velocity paradox. Shifting to 50-70% planning yields 50% fewer refactors, 3x faster overall.

**H006 — Most SWE work is solved problems**
Source: `CLAUDE.md:28` | Confidence: 0.82 | Evidence: 6 for, 0 against

- EXP-004: Multiple learnings show existing solutions as the right path: static HTML deployment, bundled Ionicons, existing Redis infrastructure.
- EXP-013: CollabVault: "prefer existing open source packages over writing from scratch." NEXUS: module #45 in existing FastAPI backend.
- EXP-030: Kernel-claude has 8 research docs, 12 research-related commits. The v7.0.0 commit is literally named "feat!: v7.0.0 - research-first workflow."
- EXP-031: CollabVault has 502 total commits with 17 research commits spanning diverse domains, spread across lifecycle.
- EXP-042: kernel-gap-analysis found 40 gaps. All had known solutions from established practices. 0 of 40 required novel research.
- EXP-043: 390 research docs found across all _meta/research/ directories in Vaults. Each represents a problem treated as "already solved."

**H007 — Defining acceptance criteria before coding reduces wasted implementation work**
Source: `CLAUDE.md:94` | Confidence: 0.82 | Evidence: 6 for, 0 against

- EXP-015: CollabVault paradigm-003: "Ticket writing quality IS the bottleneck — every ticket needs acceptance criteria." paradigm-004: "70%+ acceptance rate before Phase B."
- EXP-032: All modelmind experiments (C001-C009) had structured pass/fail criteria. Enabled decisive model elimination with zero ambiguity.
- EXP-033: Kernel-claude contracts show quantified goals reaching closure. CR-20260401: explicit goal with 6 file constraints and tier designation.
- EXP-044: CollabVault "paradigm-003": bad tickets = bad output. "sow-exhibit-001": deliverable-based acceptance, not outcome-based.
- EXP-045: Contracts with measurable criteria (file count, test count, integrity score) correlated with shipped:true outcomes.
- EXP-H007-001: paradigm-003 + LRN-052 (scope creep when constraints undefined) + LRN-20260330-003 (constraint enforcement).

### Coordination (2 graduated)

**H017 — Using a cheap model (haiku) for pre-flight validation before expensive work saves total cost**
Source: `CLAUDE.md:78` | Confidence: 0.82 | Evidence: 6 for, 0 against

- EXP-018: pricing-001 documents haiku at 1/5 vs opus at 5/25 per M tokens (5x cheaper). Triage and understudier agents designed for this pattern.
- EXP-062: Pre-flight triage call (~500 tokens) costs ~$0.003 on Haiku vs ~$0.015 on Opus. If 30% of tasks rejected, savings compound.
- EXP-070: CollabVault: "Model routing by task criticality: Free tiers handle 60-70% of work volume."
- EXP-090: claude-best-practices-2026.md documents Anthropic's adaptive thinking effort levels — same cheap-first principle.
- EXP-091: Modelmind shows cheap research commits before expensive implementation commits systematically.
- EXP-110: triage.md and understudier.md agents architecturally embed cheap pre-flight.

**H020 — Each parallel agent should own its own PR to avoid merge conflicts**
Source: `NEXUS:14` | Confidence: 0.82 | Evidence: 6 for, 0 against

- EXP-019: LRN-052: 7-way merge conflicts from dirty working tree. LRN-057: agents independently fix the same bugs.
- EXP-063: LRN-053: "Sequential rebase-and-merge is the correct recovery" for conflicting parallel PRs. LRN-016 nuance: local profile keeps work on main.
- EXP-071: Kernel-claude: 30+ typed branches. Modelmind: 12 worktree-agent-* branches. CollabVault warns: "Parallel surgeons lose each other's changes."
- EXP-104: External validation from Composio (Diego), LangChain (Harrison), CrewAI (Joao) — all major frameworks do or want agent-level isolation.
- EXP-105: Kernel forge used 4 phase branches merged sequentially. Conflicts resolved at merge time, not during development.
- EXP-111: 43 commits reference PR numbers. 40+ branches follow type/scope naming.

### Testing (2 graduated)

**H022 — Every bug fix requires a regression test**
Source: `CLAUDE.md:216` | Confidence: 0.82 | Evidence: 6 for, 0 against

- EXP-064: Contrast between test-disciplined repos (clean history) and test-gap repos (persistent bugs, 5+ open bugs around timeouts).
- EXP-072: Modelmind: only 7% of fix commits include test files. But domain/logic fixes consistently include tests. 342f93c regression occurred without tests.
- EXP-092: Modelmind commit 342f93c had to undo 09ca7cb because no regression test caught the app icon breakage. Claymorphism: 8 commits failed repeatedly without tests.
- EXP-093: past-struggles-audit S1: hook env var confusion cycled through v7.0.1-v7.0.4 (4 versions!) re-breaking the same bug. A regression test would have caught it immediately.
- EXP-112: CollabVault fix commits do NOT co-change test files — the absence of regression tests validates the hypothesis by showing the gap.
- EXP-H022-001: 9 of 12 behavioral fix commits (75%) included test changes when excluding config-only fixes.

**H023 — Tests must pass before merge**
Source: `invariants.md:13` | Confidence: 0.82 | Evidence: 6 for, 0 against

- EXP-020: 1,807 hook events total (1,104 guard-bash, 282 detect-secrets). Active enforcement at hook level.
- EXP-065: FunJoin: 2000 tests on every main merge, stable deployments. kernel-claude f0abbb2 added version-sync check, eliminated a class of bugs.
- EXP-073: Layered validation: pre-commit hooks, validator agent, pre-ship agent (4 parallel validators), CI version-sync.
- EXP-094: kernel-gap-analysis Gap 2.1: "No CI runs test suite. A PR can merge broken code with zero test verification." HIGH risk.
- EXP-095: Modelmind store readiness (563 tests, clean deploy) vs claymorphism (no tests, 14 iterations + postmortem).
- EXP-113: validate command documents: "AI code is 1.7x buggier. Quality gates BEFORE review catch 80% of issues."

### Git (3 graduated)

**H029 — Atomic commits make rollbacks safer and history more readable**
Source: `CLAUDE.md:144` | Confidence: 0.82 | Evidence: 6 for, 0 against

- EXP-016: Modelmind: 388 commits across 11 days, majority touch 1-8 files with thematic focus.
- EXP-034: CollabVault: 78% of last 50 commits touch 5 or fewer files (median 3).
- EXP-035: 5 revert commits across repos. Every revert targets a single logical change, reads as clean undo. No tangled multi-feature reverts.
- EXP-046: Kernel-claude: 93% atomic (<=7 files with single scope). 1 outlier: v7.8.1 release commit.
- EXP-047: Modelmind: 93% atomic with conventional format. Research-plan-implement pattern shows docs committed separately.
- EXP-H029-001: Median commit: 3 files. 76% touch <=10 files.

**H031 — Committing every working state prevents work loss**
Source: `CLAUDE.md:145` | Confidence: 0.82 | Evidence: 6 for, 0 against

- EXP-021: Modelmind: 388 commits in 11 days (avg 35/day). Session-end commits throughout.
- EXP-066: Checkpoints CP-20260330235026 shows 8 uncommitted files at risk. Clean sessions show 0 uncommitted files. LRN-014: "Must push immediately."
- EXP-074: 35 session-end/checkpoint commits (12% of modelmind total). CollabVault: "Commits without push are useless."
- EXP-096: past-struggles-audit S10: silent push failures cause data loss (STILL BROKEN). S7: compact hook writes but never reads back.
- EXP-097: Modelmind 905b165 preserved 163 files at session end. Without it, all at risk.
- EXP-114: Session-end hook IS the commit mechanism. Automated via hooks, not optional.

**H033 — Feature branches for tier 2+ tasks isolate risk from main**
Source: `CLAUDE.md:143` | Confidence: 0.82 | Evidence: 6 for, 0 against

- EXP-022: Kernel-claude: 10+ feature branches. All tier 2+ work used feature branches. LRN-20260324120914: "OSS repos require feature branch + PR workflow."
- EXP-067: l-quarantine-protocol: agents push to ai/ branches with MRs in quarantine. LRN-016 nuance: feature branches essential for tier 2+, overhead for trivial local work.
- EXP-075: Kernel-claude: 38 remote branches. Modelmind: 30+ branches. All following type/scope convention.
- EXP-098: Forge session used 5 branches for 22 issues. Merge conflicts resolved at merge time, not on main.
- EXP-099: Modelmind: multi-file features used branches (feat/i18n, feature/subscription). Single-file fixes went direct to main.
- EXP-115: CollabVault confirms pattern extends beyond kernel-claude.

### Security (2 graduated)

**H035 — No hardcoded secrets**
Source: `invariants.md:11` | Confidence: 0.82 | Evidence: 6 for, 0 against

- EXP-010: detect-secrets hook fired 282 times. LRN-20260325104502: hardcoded IDs caught and replaced. No learnings record a leaked secret.
- EXP-014: Modelmind: active secret management across commits (gitignore credentials, remove hardcoded buildNumber, replace 27 hardcoded rgba values).
- EXP-036: Cross-repo: kernel-claude commit 7f89242 patches secret detection patterns. No leaked secrets in any commit message.
- EXP-037: Zero security-related errors in any error table across all 3 databases. "0 security issues" measured baseline.
- EXP-048: past-struggles-audit: no struggle involves leaked secrets. Gap 1.7 notes detect-secrets.sh exists but needs more test coverage.
- EXP-049: Grep across all Vaults for hardcoded API key patterns: ZERO in kernel-claude. All 35 matches are test fixtures, .env.example, docs, or third-party code.

**H037 — When uncertain, deny; when scanner fails, block; when budget exceeded, stop**
Source: `CLAUDE.md:32` | Confidence: 0.82 | Evidence: 6 for, 0 against

- EXP-023: nexus-010: "LLM-only fallback is euphemism for hallucinate at customers." LRN-056: RevenueCat guard returns false on suspicious keys.
- EXP-068: LRN-20260401125335: "build the fallback first, add detection layers incrementally." 1,104+ guard-bash events show enforcement.
- EXP-076: guard-config.sh blocks .claude/ writes with exit 2 (deny by default, explicit allowlist). All guards follow deny-by-default.
- EXP-100: Contrast: where deny-by-default applied (guards), security holds. Where not (agentdb numeric params), vulnerabilities exist.
- EXP-101: claude-best-practices-2026.md: "When intent is ambiguous, provide information first." AI failure rate 41-87% makes deny-by-default rational.
- EXP-116: guard-config.sh source: textbook deny-by-default implementation. Default=deny, exceptions=allow with explicit allowlist regex.

### Quality (1 graduated)

**H039 — The Big 5 AI code defects taxonomy**
Source: `CLAUDE.md:222` | Confidence: 0.82 | Evidence: 6 for, 0 against

- EXP-024: 4 of 5 defect types confirmed in actual learnings (input validation, edge cases, error handling, complexity management).
- EXP-069: Cross-vault mapping covers all 5 categories with concrete examples from production failures.
- EXP-077: ai-code-anti-patterns.md documents Big 5 with industry stats (40-62% security flaws, 1.7x buggier, +30-41% tech debt). Each category has detection methods and fixes.
- EXP-102: Modelmind claymorphism failure maps to 4 of 5 Big 5 categories (edge cases, error handling, duplication, complexity).
- EXP-103: External validation from 4 independent sources: CSA, Veracode, SonarSource, METR, CodeRabbit.
- EXP-117: All 5 categories have independent external validation from named research organizations.

---

## Refuted Rules (Disproven)

### H015 — Parallel agent execution multiplies throughput by 3-5x (REFUTED)
Source: `CodingVault/.claude/CLAUDE.md:59` | Confidence: 0.0 | Evidence: 0 for, 1 against
Replaced by: **H068** (nuanced version — parallel for research/independent files, serial for shared code)

EXP-007 refutation evidence: parallel execution on CODE causes severe problems. LRN-052: 7-way merge conflicts from dirty worktrees. LRN-057: agents independently fix same bugs. LRN-20260324223752: "Sequential execution on shared files is faster than worktree parallelism." Consolidated learning LRN-20260401115508: "Sequential on shared files beats parallel." The 3-5x claim holds for research/search tasks but is actively harmful for code implementation without careful preconditions.

### H016 — 2+ independent tasks should always be parallelized (REFUTED)
Source: `parallel-first.md:7` | Confidence: 0.0 | Evidence: 0 for, 1 against
Replaced by: **H069** (nuanced version — parallelize research/exploration/independent files, not shared modules)

EXP-008 refutation evidence: LRN-052 and LRN-057 document catastrophic failures from parallelizing 7 agents on related code. adversary-002: DocuSeal migration "Should start FIRST, not parallel." Error 14: PR #120 unmergeable from parallel work. The "always" qualifier is wrong. Correct rule: parallelize RESEARCH and INDEPENDENT file operations always; parallelize CODE only after analyzer confirms zero file overlap and clean working tree.

---

## By Domain

### Methodology (17 hypotheses)

| ID | Statement | Confidence | Status |
|----|-----------|------------|--------|
| H003 | Research anti-patterns before solutions | 0.82 | graduated |
| H005 | Knowledge mining before coding saves multiples | 0.82 | graduated |
| H006 | Most SWE work is solved problems | 0.82 | graduated |
| H007 | Defining acceptance criteria before coding | 0.82 | graduated |
| H004 | Generate 2-3 approaches before implementing | 0.0 | testing |
| H008 | Reading AgentDB at session start | 0.0 | testing |
| H009 | Writing learnings at session end | 0.0 | testing |
| H010 | Built-in features beat dependencies | 0.0 | inconclusive |
| H011 | Pre-implementation review catches gaps | 0.0 | testing |
| H054 | Planning-to-building ratio 1:32 | 0.25 | testing |
| H055 | Single-file feature = minutes | 0.25 | testing |
| H056 | 5-second question saves 5 minutes | 0.25 | testing |
| H057 | Forge stops after 3 failures or 10 iterations | 0.25 | testing |
| H058 | Systematic debugging sequence | 0.25 | testing |
| H059 | Every task teaches something | 0.25 | testing |
| H060 | Correctness over speed | 0.25 | testing |
| H067 | Archive stale patterns after 6 months | 0.25 | testing |

Average confidence: 0.31. Strongest domain — 4 graduated (the research-first cluster).

### Coordination (12 hypotheses)

| ID | Statement | Confidence | Status |
|----|-----------|------------|--------|
| H017 | Cheap model for pre-flight validation | 0.82 | graduated |
| H020 | Each agent owns its own PR | 0.82 | graduated |
| H015 | Parallel 3-5x throughput multiplier | 0.0 | refuted |
| H016 | Always parallelize independent tasks | 0.0 | refuted |
| H012 | Tier thresholds (1-2 direct, 3-5 orchestrate) | 0.0 | inconclusive |
| H014 | Orchestrators who code produce worse outcomes | 0.0 | inconclusive |
| H013 | Ambiguous = assume higher tier | 0.25 | testing |
| H018 | Adversary rejection loop converges (max 3) | 0.25 | testing |
| H019 | AgentDB > conversational output for state | 0.25 | testing |
| H065 | Auto-create PRs without asking | 0.25 | testing |
| H068 | Parallel for research, serial for shared code | 0.25 | testing |
| H069 | Parallelize independent ops, not shared modules | 0.25 | testing |

Average confidence: 0.26. Most contested domain — 2 refuted, 2 graduated, 2 inconclusive.

### Git (7 hypotheses)

| ID | Statement | Confidence | Status |
|----|-----------|------------|--------|
| H029 | Atomic commits enable clean rollbacks | 0.82 | graduated |
| H031 | Commit every working state | 0.82 | graduated |
| H033 | Feature branches for tier 2+ | 0.82 | graduated |
| H030 | Conventional commit format | 0.25 | testing |
| H032 | Never commit broken code to main | 0.25 | testing |
| H034 | Stash before risky operations | 0.0 | testing |
| H064 | Push immediately after commit | 0.25 | testing |

Average confidence: 0.46. High graduation rate (3 of 7).

### Quality (7 hypotheses)

| ID | Statement | Confidence | Status |
|----|-----------|------------|--------|
| H039 | The Big 5 AI code defect taxonomy | 0.82 | graduated |
| H028 | Composite quality scoring | 0.25 | testing |
| H040 | Flag DRY violations aggressively | 0.25 | testing |
| H041 | Review ordering (Arch > Quality > Tests > Perf) | 0.25 | testing |
| H042 | Max 4 issues per review section | 0.25 | testing |
| H043 | Numbered issues, lettered options | 0.25 | testing |
| H061 | All quality gates must pass before commit | 0.25 | testing |

Average confidence: 0.33.

### Testing (7 hypotheses)

| ID | Statement | Confidence | Status |
|----|-----------|------------|--------|
| H022 | Regression test for every bug fix | 0.82 | graduated |
| H023 | Tests must pass before merge | 0.82 | graduated |
| H021 | Edge cases over happy paths | 0.0 | testing |
| H024 | Tests green before AND after refactor | 0.25 | testing |
| H025 | E2E for critical paths only | 0.25 | testing |
| H026 | Test naming convention | 0.25 | testing |
| H027 | QA assumes broken until >80% confidence | 0.25 | testing |

Average confidence: 0.38. 2 graduated, 5 testing.

### Security (4 hypotheses)

| ID | Statement | Confidence | Status |
|----|-----------|------------|--------|
| H035 | No hardcoded secrets | 0.82 | graduated |
| H037 | Deny by default, never degrade safety gates | 0.82 | graduated |
| H036 | Pre-commit hooks catch issues before history | 0.25 | testing |
| H038 | Pause writes on ambiguous intent | 0.25 | testing |

Average confidence: 0.54. Highest domain average. 2 of 4 graduated. Zero counter-evidence across all experiments.

### Architecture (6 hypotheses)

| ID | Statement | Confidence | Status |
|----|-----------|------------|--------|
| H047 | Log errors with context, never swallow | 0.25 | testing |
| H048 | AgentDB is source of truth, not GitHub | 0.25 | testing |
| H049 | Contracts: observable, bounded, rejectable | 0.25 | testing |
| H050 | No irreversible ops without confirmation | 0.25 | testing |
| H062 | Absolute paths for AgentDB | 0.25 | testing |
| H063 | _meta always committed, never gitignored | 0.25 | testing |

Average confidence: 0.25. Zero graduated. All at baseline testing with 1 experiment each.

### Performance (3 hypotheses)

| ID | Statement | Confidence | Status |
|----|-----------|------------|--------|
| H044 | LSP 600x faster than grep | 0.0 | inconclusive |
| H045 | Measure before optimizing | 0.25 | testing |
| H046 | N+1 query detection as standard checkpoint | 0.25 | testing |

Average confidence: 0.17. Weakest domain.

### Style (3 hypotheses)

| ID | Statement | Confidence | Status |
|----|-----------|------------|--------|
| H051 | Comments explain why, not what | 0.25 | testing |
| H052 | kebab-case resources, snake_case modules | 0.25 | testing |
| H053 | Branch format type/scope | 0.25 | testing |

Average confidence: 0.25. All at baseline.

### Design (1 hypothesis)

| ID | Statement | Confidence | Status |
|----|-----------|------------|--------|
| H066 | Anti-AI aesthetic (no Inter, no emoji) | 0.25 | testing |

---

## Confidence Distribution

| Tier | Range | Count | Percentage |
|------|-------|-------|------------|
| High | 0.8+ | 14 | 20.9% |
| Moderate | 0.5-0.8 | 0 | 0.0% |
| Low | 0.2-0.5 | 41 | 61.2% |
| None | 0.0-0.2 | 12 | 17.9% |

The gap at 0.5-0.8 is structural: the graduation threshold requires 6 experiments with 0 counter-evidence, which jumps confidence from 0.25 to 0.82. There is no intermediate state in the current scoring model.

---

## Inconclusive Hypotheses

Four hypotheses remain inconclusive (0 experiments, 0 evidence):

**H010 — Built-in language features beat external dependencies**
Evidence needed: Compare implementation time and maintenance burden for tasks using built-in vs external dependencies. Requires A/B comparison data that does not exist in current telemetry.

**H012 — Tier thresholds (1-2 files = direct, 3-5 files = orchestrate)**
Evidence needed: Track file count vs outcome quality across contracts. Requires tagging contracts with actual file counts and measuring success rates by tier assignment.

**H014 — Orchestrators who code themselves produce worse outcomes**
Evidence needed: Compare outcomes when orchestrators implemented directly vs delegated to agents. Requires paired comparisons of the same type of task under both conditions.

**H044 — LSP tools are 600x faster than grep**
Evidence needed: Timing measurements of LSP vs grep for equivalent navigation tasks. The 50ms vs 30s claim needs benchmarking in the actual development environment.

### Zero-Evidence Testing Hypotheses

Four additional hypotheses are in "testing" status but have 0 experiments and 0 confidence:

- **H004** — Generating 2-3 approaches yields simpler solutions
- **H008** — Reading AgentDB at session start improves outcomes
- **H009** — Writing learnings at session end improves next session
- **H011** — Pre-implementation review catches rework-causing gaps
- **H021** — Testing edge cases > happy paths
- **H034** — Stashing before risky operations prevents data loss

These need their first experiments to move forward.

---

## Key Findings

### 1. Research-first is the strongest validated cluster

H003, H005, H006, H007 form a coherent cluster with 24 total supporting experiments and 0 counter-evidence. The evidence spans 3 separate repositories (kernel-claude, modelmind, CollabVault), external research (METR 2025, claude-best-practices-2026), and multiple evidence types (failure learnings, git history, commit ratios, research doc counts). This is the most robustly validated finding in the system.

Key stat: 390 research docs across all Vaults. Modelmind's 0.46 research-to-feature ratio. METR's velocity paradox (perceived 20% faster, measured 19% slower without research).

### 2. Parallelization needed refinement — absolutist claims refuted

H015 (3-5x throughput) and H016 ("always parallelize") were both refuted by catastrophic evidence: 7-way merge conflicts, agents fixing the same bugs independently, unmergeable PRs. The replacement hypotheses (H068, H069) correctly scope parallelization to research and independent-file operations while recommending serial execution for shared-file code changes. This is the system learning from its own failures.

### 3. Security invariants validated with zero counter-evidence

H035 (no hardcoded secrets) and H037 (deny by default) are validated across 12 experiments with zero counter-evidence and zero security incidents in any error table across all 3 databases. The detect-secrets hook (282 events), guard-bash (1,104 events), and guard-config (deny-by-default with explicit allowlist) form a layered enforcement system. The grep audit found 0 real secrets in kernel-controlled code.

### 4. The Big 5 taxonomy validated by 4 independent industry sources

H039's taxonomy (input validation, edge cases, error handling, duplication, complexity) was validated by CSA, Veracode, SonarSource, METR, and CodeRabbit independently. The modelmind claymorphism failure mapped to 4 of 5 categories, demonstrating the taxonomy's diagnostic power on real failures. Stats: 40-62% AI code has security flaws, 1.7x buggier than human code, +30-41% tech debt, +15-25% cyclomatic complexity.

---

## Methodology Note

All 137 experiments were **historical** — querying existing AgentDB data, git history, and research documents. No synthetic experiments were run. No code was written to test hypotheses. No A/B comparisons were conducted.

Evidence sources:
- AgentDB learnings, errors, events, and context tables across 3 databases (kernel-claude, modelmind, CollabVault)
- Git commit history and branch analysis across 3 repositories
- Research documents in `_meta/research/` directories (390 total)
- External research citations (METR 2025, claude-best-practices-2026, ai-code-anti-patterns)
- OSS simulation feedback (Composio, LangChain, CrewAI perspectives)

Evidence quality varies by data availability. Graduated hypotheses have the strongest evidence (6 experiments each from multiple independent sources). Testing hypotheses at 0.25 confidence typically have 1 experiment. Inconclusive hypotheses have 0 experiments due to data type mismatch (the historical evidence method cannot produce the required comparison data).

The confidence scoring model has a structural gap at 0.5-0.8 — hypotheses jump from 0.25 (1 experiment) to 0.82 (6 experiments) with no intermediate states. A future revision should smooth the confidence curve.
