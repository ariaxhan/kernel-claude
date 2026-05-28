# Skill-Flow Rewrite Audit — chore/kernel-md-consistency

Date: 2026-05-28
Auditor: adversarial info-loss + regression auditor (fresh context)
Scope: 18 over-cap SKILL.md files converted to numbered flows; removed prose moved to `skills/<id>/reference/<id>-research.md`.

## 1. Hard gate — test suite

```
Results: 242 passed, 0 failed
```

PASS. Exactly the required 242/0.

## 2. Information-loss check (the cardinal failure)

Method: for each skill, `git diff main -- skills/<id>/SKILL.md` to extract removed lines, then verified each removed substantive concept is present EITHER (a) condensed inline in the current SKILL.md, OR (b) in the skill's reference file. Raw line-count deltas (removed > ref-added) were investigated by reading the actual surviving content, because numbered-flow reformatting legitimately compresses verbose prose into fewer lines without losing substance.

Result: **ZERO confirmed information-loss issues.**

Detailed verification of the highest-risk skills (largest removed/ref-added gaps):

- **build** (340→156): RESEARCH CACHE, Interview pattern, Assumption Verification, Solution Exploration, Failure Handling, cache-frontmatter format, LRN-F11 "research without verification is theory fiction" — ALL preserved inline as numbered steps 1–8. Deep-context sections (Context Engineering, Context Window Hygiene, Velocity Calibration, Agentic Build Patterns) confirmed present in build-research.md. No loss.
- **api** (325→114): All status codes (incl. 201/429), response envelope, pagination (cursor/offset), idempotency, versioning, rate-limit headers, agentic client design — preserved inline as numbered methodology 1–10. Verbose TS/Zod implementation + status-code/response-format detail confirmed in api-research.md (201 at line 422/447, status table line 45). No loss.
- **eval** (155→86): blind-evaluator protocol, two-phase eval, contamination check, pass@k/pass^k, all three grader types, self-score 36% inflation, anti-patterns — ALL preserved inline. Grader templates/examples moved to eval-research.md (line 40 "Code-Based"). No loss.
- **security** (334→104): 13 numbered flow steps each with executable gate; all OWASP/secrets/SQLi/XSS/CSRF/rate-limit/supply-chain/prompt-injection concerns preserved. Code examples confirmed in security-research.md (Zod line 192, SQLi line 223). No loss.
- **debug** (248→126): Zeller method, cognitive biases, anti-patterns, when-stuck, escalation, parallel-debug, persistent-truth-file all inline; full templates landed in debug-research.md (line 354/383/420/425). No loss.
- **e2e/tdd/refactor**: code blocks (POM, playwright.config, CI YAML / Supabase-Redis-OpenAI mocks, coverage_config / vibe-coding stats, AI-cleanup, Opus-4.7 literal-instruction) confirmed moved to respective reference files (grep REF>0 for each). No loss.

Note (not loss): build self-report claimed ref "grew 354→487 (+133)" but git shows +91 added lines. Discrepancy is in the self-report's accounting, not actual content — all four named sections verified present in build-research.md. Cosmetic.

## 3. Test-asserted strings

All present in their SKILL.md:
- quality: `r_factor` FOUND · `0.20 * test_pass_rate` FOUND · `0.15 * scope_accuracy` FOUND · `adsr` FOUND
- orchestration: knowledge_injection · progressive_autonomy · budget_awareness · checkpoint_recovery · worktree_safety · constraints.files · "Post-agent validation" — ALL FOUND
- app-dev: "store submission" FOUND · "App Store" FOUND · EAS FOUND · expo FOUND · "react native" FOUND. ("Play Console" not present, but the assertion is an OR with App Store, which is satisfied.)

No missing asserted strings.

## 4. Frontmatter integrity

Diffed the top frontmatter block (lines 1–6, between `---` fences) of every edited SKILL.md against `main`. ALL byte-for-byte IDENTICAL. Grep false-positives on `name:` were inside code examples (Zod schemas, playwright config, GitHub Actions YAML) and `---` horizontal rules in the body — none touched actual frontmatter. (build line-7 diff is `# PURPOSE`→`# BUILD SKILL`, a body heading below the frontmatter, not frontmatter.)

PASS.

## 5. Coherence spot-check (build, security, debug)

- **build**: 8 numbered steps (Goal Extraction → Research Cache → Assumption Verification → Solution Exploration → Execution → Validation → Failure Handling → Completion), each with explicit (gate:) line + flags section. Coherent and executable.
- **security**: 13 numbered flow steps, each with a concrete executable gate (grep commands, presence checks). Pre-deployment checklist + anti-patterns intact. Coherent and executable.
- **debug**: reproduce→hypothesize→isolate→root-cause→fix with gates, plus cognitive-biases, anti-patterns, when-stuck, escalation, parallel-debug, persistent-truth-file. Reference pointers accurate. Coherent and executable.

No garbled flows found.

## Verdict

**PASS.** 242/0 tests. Zero confirmed information loss. All asserted strings present. Frontmatter intact across all 18 files. All three spot-checked flows coherent and executable. The line-count drops reflect prose-to-flow compression + correct relocation to reference files, not deletion.
