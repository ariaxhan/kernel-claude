# Kernel 8 → 9 Capability Inventory

Slice 1 deliverable. Every current Kernel capability, classified.

Classification vocabulary:

- **core** — universal, host- and domain-independent. Stays in the always-loaded layer.
- **pack:<name>** — domain-specific. Moves behind progressive disclosure.
- **safety** — externally enforced invariant. Preserved as-is unless evidence proves a safer replacement.
- **adapter** — host-specific generation or binding.
- **obsolete** — generic ceremony a frontier model already knows, or process the brief instructs us to delete.
- **duplicate** — subsumed by another capability.

Evidence for the "always-loaded cost" column: measured 2026-07-29 on
`8f881ae`, `wc -c` of the generated artifact divided by 4.

---

## 0. Measured baseline

> **CORRECTED 2026-08-05. The original baseline in this section was wrong, and the
> sub-500-token target it produced is withdrawn.** Both are preserved below the corrected
> table, because the error is more instructive than the number.

Measured by `tests/kernel9/measure_ambient.py`, which now separates two populations that
pay different amounts.

| Metric | plugin user | contributor in this repo |
|---|---|---|
| SessionStart hook stdout | **1864 tok** | 1864 tok |
| Skill frontmatter, 26 skills, host-visible for routing | **2732 tok** | 2732 tok |
| Instruction file, per host | **not loaded** | 5784 tok |
| **Ambient total** | **≈ 4596 tok** | ≈ 10380 tok |

Ratchets enforced by `tests/kernel9/test_ambient_budget.py`: plugin 4800, contributor 11000.

### What the original baseline got wrong

It charged this repo's `CLAUDE.md` to every session. **Plugin users never load it.** Claude
Code loads the *user's own* instruction file, and `.claude-plugin/plugin.json` does not
reference ours; `tests/run-tests.sh` has said exactly this in a comment for a long time, and
the instrument disagreed with it. That inflated the baseline about 4x.

The consequence was not cosmetic. It made "reduce ambient context" look like it required
deleting the I0 invariants and anti-patterns from `CLAUDE.md`, which would have saved plugin
users **zero tokens** while removing safety rules from the contributors who do load them.

### Why <500 is withdrawn rather than deferred

Plugin ambient is dominated by **skill frontmatter**, not by any template: ~2732 tok across 26
skills, mean ~105, range 66 to 174. There is no dominant offender to trim, and the host must
keep that frontmatter visible or routing cannot happen at all. Reaching 500 would mean
shipping roughly four skills.

The governance template was never the binding constraint, so wiring the compact
`kernel9.md.tmpl` does not deliver the claimed reduction. **Do not restate the sub-500 figure.**
The honest claim is that the instruction file is no longer the delivery mechanism, and that
ambient is one hook plus the packs actually loaded.

The real lever, if this is revisited, is `session-start.sh` at 1864 tok, paid by every session
on every host.

<details>
<summary>Original (incorrect) baseline, kept for the record</summary>

| Metric | Kernel 8 (measured) | Kernel 9 target |
|---|---|---|
| SessionStart hook stdout | 6808 B ≈ **1702 tok** | part of <500 |
| `CLAUDE.md` (always loaded) | 22531 B ≈ **5632 tok** | part of <500 |
| **Total ambient** | **≈ 7334 tok** | **< 500 tok** |

Required reduction in ambient context: ~93%.
</details>

| Metric | Kernel 8 | Kernel 9 target |
|---|---|---|
| Always-visible skills | 26 | as few as route correctly |
| Canonical governance template | 301 lines | — |
| Lifecycle bindings | 12 | — |
| Hook scripts | 24 | safety subset preserved |
| Agents | 10 | — |
| AgentDB migrations | 17 | all must remain readable |

---

## 1. Skills (26)

| Skill | Class | Rationale |
|---|---|---|
| `ingest` | obsolete (entry) → core (invisible) | Kernel 9's premise is that the user never invokes an entry point. The *routing* it performs becomes the universal core; the *invocation* disappears. Keep `/kernel:ingest` as a backward-compatible alias that just runs the router. |
| `build` | obsolete | "Generate 2-3 approaches, pick simplest" is exactly the mandatory-multiple-solutions ceremony the brief deletes. Frontier models do this unprompted. |
| `debug` | pack:software | Reproduce-first is a real, non-obvious discipline with evidence behind it. Keep, but load only on software+debug routing. |
| `diagnose` | duplicate of `debug` | Overlapping bug-mode methodology. Merge into `debug`; keep refactor-mode analysis in `pack:software`. |
| `architecture` | obsolete | 593 tok of generic modularity guidance. Brief explicitly deletes "generic modularity lectures". |
| `review` | pack:software | Domain-appropriate verification for code. Not universal. |
| `tearitapart` | obsolete as a *gate*, retained as a *tool* | The `IF tier >= 2 run tearitapart` mandate is mandatory-pre-implementation-review ceremony. Keep the skill invocable; delete the mandate. |
| `orchestration` | core (reduced) | Writer-ownership tracking is a non-negotiable core responsibility. The multi-agent/lane/worktree prose is `pack:software` at most, and I0.14 already forbids worktrees. |
| `context-mgmt` | core | Progressive disclosure and compaction are universal. |
| `handoff` | core | Manifest-based bounded resume. Universal, host-independent. |
| `checkpoint` | core | Same. |
| `retrospective` | core (demoted) | Cross-session synthesis is universal but must stop being a mandatory end-of-task deliverable. |
| `metrics` | core (operator) | Observability. Explicit invocation only. |
| `help` | core | Required user control. |
| `init` | core (operator) | Setup. Must become no-op-safe without Vaults. |
| `experiment` | pack:strategy | Hypothesis/graduate/kill methodology generalizes past code, but is not universal. |
| `forge` | pack:software | Autonomous build engine. Explicit + budget-capped. |
| `dream` | pack:strategy | Multi-perspective exploration. Genuinely domain-general decision work. |
| `eval` | pack:software | pass@k / graders. Code+ML specific. |
| `frontend` | pack:design | Art direction, visual iteration. |
| `marketing-site` | pack:writing + pack:design | Positioning/copy is writing; art direction is design. Split. |
| `landing-page` | pack:design (operator) | Explicit generator. |
| `app-dev` | pack:software | Build/store pipeline. |
| `knowledge-graph` | pack:software | Code graph navigation. |
| `ship` | pack:software | Release gate. Git/PR mechanics are software-domain, not universal. |
| `governance-sync` | adapter | Generates native instruction files. Becomes part of the host-adapter layer. |

Counts: **core 9, pack:software 9, pack:design 3, pack:strategy 2, pack:writing 1,
adapter 1, obsolete 4, duplicate 1.** (Sums exceed 26 because `marketing-site` splits.)

---

## 2. Agents (10)

| Agent | Class | Rationale |
|---|---|---|
| `surgeon` | pack:software | Minimal-diff implementation lane. |
| `adversary` | core (on demand) | Independent verification is universal; the *mandate* to spawn it at tier 2+ is obsolete ceremony. |
| `reviewer` | pack:software | Code review. |
| `researcher` | core (on demand) | Domain-neutral. |
| `scout` | pack:software | Codebase recon. |
| `lane-worker` | pack:software | Parallel implementation lane. |
| `transcript-archaeologist` | core (on demand) | Log forensics, read-only, domain-neutral. |
| `blind-evaluator` | core | Structurally-separate evaluation. Directly required by the brief's "do not let Kernel grade itself". |
| `deep-diver` | pack:software | Failure-mode research gate for native/infra/schema work. The *universal* research-first mandate is obsolete; this targeted one survives. |
| `dreamer` | pack:strategy | Multi-perspective debate. |

---

## 3. Hooks (24 scripts / 12 lifecycle bindings)

### Hard safety — preserve

| Script | Binding | Why it stays |
|---|---|---|
| `guard-bash.sh` | PreToolUse:Bash | Destructive-command protection. Brief: preserve. |
| `detect-secrets.sh` | PreToolUse:Write\|Edit | Secret exposure. Brief: preserve. |
| `scan-output.sh` / `scan-output.py` | PostToolUse:web/mcp | Untrusted-output scanning. |
| `guard-config.sh` | PreToolUse:Write\|Edit | Credential/config write protection. |
| `guard-context.sh` | PreToolUse:Read\|Grep\|Glob | Context/scope escape, manifest-driven. |

These five are the safety overlay. They are independent of work shape, per the brief.

### Core continuity — preserve, make portable

| Script | Class | Note |
|---|---|---|
| `session-start.sh` | core | **1864 tok, paid by every session on every host. The real ambient lever now that the <500 target is withdrawn (see §0).** Also has a latent hang when run without hook JSON on stdin (see §5). |
| `session-end.sh` | core | Documented `--no-verify` carve-out stays. |
| `pre-compact-commit.sh` | core | Same carve-out. |
| `post-compact-restore.sh` | core | |
| `common.sh` | core | Shared lib. |
| `circuit-breaker.sh` | core | Fault tolerance. |

### Reclassify

| Script | Class | Note |
|---|---|---|
| `capture-error.sh` | adapter | Bound to `PostToolUseFailure`, **which Codex does not implement** (§4). Needs an honest capability declaration, not a silent no-op. |
| `test-gate.sh` | pack:software | "Tests" language is software-only. Brief forbids mandatory tests language for non-code domains. |
| `validate-structure.sh` | pack:software | Repo-structure validation. |
| `validate-json-schema.sh` | core | Manifest schema validation. Universal. |
| `warn-hardcoded.sh` | safety (soft) | Hardcoded-path warning. Repo-specific executable check — brief says keep these. |
| `log-write.sh` | core | Telemetry. |
| `autopush.sh` / `autopush-postcommit` | pack:software | Git mechanics. |
| `knowledge-graph.sh` / `graphify-postcommit` | pack:software | |
| `github-integration.sh` | pack:software (adapter) | Profile-gated. |
| `auto-approve-safe.sh` | safety | PermissionRequest allowlisting. |

---

## 4. Host compatibility reality (measured)

Verified against Codex CLI 0.145.0 and the installed plugin cache, not documentation.

**Kernel 8.7.2 is already installed and enabled in Codex**, via the Claude-format
compatibility path:

```
kernel@kernel-marketplace   installed, enabled   8.7.2
  .codex/.tmp/marketplaces/kernel-marketplace/.claude-plugin/marketplace.json
```

### Manifest formats

| | Claude Code | Codex native | Kernel 8 has |
|---|---|---|---|
| plugin manifest | `.claude-plugin/plugin.json` | `.codex-plugin/plugin.json` | Claude only |
| marketplace | `.claude-plugin/marketplace.json` | `.agents/plugins/marketplace.json` | Claude only |
| skills | `skills/` | `"skills": "./skills/"` declared | implicit |
| plugin hooks | `hooks/hooks.json` | root `hooks.json` | Claude only |
| extra manifest keys | — | `interface{}`, `apps`, `mcpServers`, structured `source{}`/`policy{}` | none |

Codex native format confirmed by reading shipped OpenAI plugins
(`visualize`, `codex-security`). Plugin-level `hooks.json` confirmed present in
shipped `figma` and `replayio` plugins.

### Lifecycle parity

Extracted by symbol search over the Codex 0.145.0 binary:

| Event | Codex | Kernel 8 binds it? |
|---|---|---|
| SessionStart | yes | yes |
| SessionEnd | yes | yes |
| PreToolUse | yes | yes |
| PostToolUse | yes | yes |
| UserPromptSubmit | yes | yes |
| PreCompact | yes | yes |
| PermissionRequest | yes | yes |
| Stop / SubagentStop | yes | no |
| **PostToolUseFailure** | **absent (0 occurrences)** | **yes — `capture-error.sh`** |

**Consequence:** Kernel 8's error-capture hook is dead on Codex and nothing says so.
This is the exact "do not claim lifecycle parity where a host does not support it"
violation. Kernel 9 must emit a truthful capability declaration per host.

---

## 5. Defects found during inventory

| # | Defect | Evidence | Severity |
|---|---|---|---|
| D1 | `PostToolUseFailure` binding is a silent no-op on Codex | 0 symbol occurrences in Codex 0.145.0 binary; hook is bound unconditionally in `hooks/hooks.json` | truthfulness |
| D2 | `session-start.sh` hangs indefinitely without hook JSON on stdin | killed at 120 s; exits 0 in seconds when fed `{"hook_event_name":"SessionStart",...}` | robustness |
| D3 | No `.codex-plugin/plugin.json` | `find` over repo root | portability |
| D4 | ~~Ambient context is 14.7x the target~~ WITHDRAWN 2026-08-05 | Baseline was wrong: it charged CLAUDE.md to plugin users, who never load it. Real plugin ambient 4596 tok, dominated by skill frontmatter, not by any template. Target retired, ratchets in test_ambient_budget.py instead. | see §0 |

---

## 6. Obsolete ceremony to delete (from the canonical template)

Located in `governance/kernel.md.tmpl`, all always-loaded:

- `<tiers>` block, including `IF tier >= 2: run tearitapart` (file-count/tier-driven escalation)
- `build` skill's "never implement the first idea / generate 2-3 approaches"
- `<block action="skip_research">` — universal research-first requirement
- `<block action="code_without_success_criteria">` — mandatory success criteria for trivial work
- `<block action="skip_tearitapart_tier2+">` — mandatory pre-implementation review
- `<block action="skip_agentdb_write">` — mandatory write on *every* task (addendum §7: do not manufacture a learning from every trivial task)
- `<architecture>` generic modularity guidance
- `<flow>` fixed pipeline — replaced by adaptive routing

**Retained** from the same file, per the brief's "retain" list: AgentDB usage,
git no-attribution rule, hook carve-outs, manifest runtime, LSP navigation
preference, the anti-patterns that encode *executable* checks
(`report_done_off_commit`, `verify_sub_computation_only`, `trust_agent_summary`).
