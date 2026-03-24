# Issue Board Review — 2026-03-24

## Summary

30 open issues reviewed. 7 edited, 6 created, 1 closed (superseded). No deletions.

## Revised Issue Map

### Wave 1: P0 Bug Fixes (no dependencies, ship immediately)
| # | Title | What | Effort |
|---|-------|------|--------|
| #19 | capture-error.sh reads env var not stdin | Fix: read from stdin like every other hook | 5 min |
| #27 | CLAUDE.md version 7.0.4 → 7.1.1 | One-line fix | 1 min |
| #23 | Silent push failures lose data | Add warning output when push fails | 15 min |

### Wave 2: P1 Security + Foundation
| # | Title | What | Effort |
|---|-------|------|--------|
| #29 | detect-secrets missing patterns | Add Anthropic, GCP, Azure, certificate patterns | 10 min |
| #43 | **NEW** Telemetry events table | Migration 003 + `agentdb emit` command. Foundation for all monitoring. | 1 hr |
| #34 | Prompt calibration audit | Surgical per-directive audit. Keep strong for safety, soften for over-triggering. | 2 hrs |

### Wave 3: P1 Observability + Features
| # | Title | Depends on | Effort |
|---|-------|-----------|--------|
| #30 | Full observability epic | #43 | 3 hrs |
| #20 | Activate hit_count + learning dedup | #43 | 1 hr |
| #21 | Circuit breaker (project-scoped) | — | 1 hr |
| #33 | Post-compact context restoration | — | 1 hr |
| #35 | /kernel:diagnose command | — | 1.5 hrs |
| #42 | Dreamer agent + /kernel:dream | — | 1.5 hrs |

### Wave 4: P2 Monitoring Stack
| # | Title | Depends on | Effort |
|---|-------|-----------|--------|
| #44 | **NEW** Hook execution timing | #43 | 1 hr |
| #46 | **NEW** agentdb health command | #43, #21 | 1.5 hrs |
| #45 | **NEW** /kernel:metrics command | #43, #30 | 1.5 hrs |
| #48 | **NEW** Session-start telemetry summary | #43, #20, #21 | 1 hr |
| #47 | **NEW** Coroner agent (telemetry-backed) | #43, #30 | 2 hrs |
| #24 | Enrich session-start (revised) | #43, #30, #48 | 1 hr |

### Wave 5: P2 Remaining
| # | Title | Notes |
|---|-------|-------|
| #22 | Convert workflows to skills | Portability improvement |
| #25 | Error replay detector | Depends on #20 |
| #36 | /kernel:retrospective | Cross-session synthesis |
| #38 | Cartographer agent | 1M context whole-codebase reasoning |
| #40 | Understudier agent | Haiku pre-flight |
| #41 | Feature flag system | Nice to have |

### Wave 6: P3 R&D
| # | Title | Notes |
|---|-------|-------|
| #26 | Learning dimensions | Crystal-OS inspired |
| #28 | Session fingerprinting | Auto-resume |
| #31 | Memory cell evolution | Clonal expansion |
| #32 | Standing wave skill activation | Energy propagation |
| #37 | /kernel:focus | Anti-drift bell |

## Issues Edited (7)
- **#20**: Added sql_escape fix from teardown, telemetry integration
- **#21**: Fixed breaker namespace (project-scoped, not /tmp)
- **#24**: Reframed from "strip context" to "enrich with dynamic telemetry"
- **#30**: Expanded from basic telemetry to full observability epic
- **#33**: Fixed marker scope (project path, not PID)
- **#34**: Changed from blanket softening to surgical per-directive audit
- **#35**: Expanded to cover refactor analysis + telemetry
- **#42**: Enhanced dreamer with agent + telemetry + decision pipeline

## Issues Created (6)
- **#43**: Telemetry events table (migration 003) — FOUNDATION
- **#44**: Hook execution timing instrumentation
- **#45**: /kernel:metrics dashboard command
- **#46**: agentdb health command
- **#47**: Coroner agent with telemetry evidence (replaces #39)
- **#48**: Session-start telemetry summary

## Issues Closed (1)
- **#39**: Superseded by #47

## Key Decisions
1. **Don't gut session-start** — it's the only reliable ambient context injection for plugin users. With 1M context, token cost is negligible.
2. **Telemetry is the foundation** — #43 unblocks the entire monitoring stack. Ship it first.
3. **Surgical prompt calibration** — don't blanket-soften directives. Keep strong for safety, soften for over-triggering.
4. **Dreamer + diagnose are real features** — they enforce existing philosophy (never implement first solution, diagnose before fixing).
5. **Coroner needs evidence** — post-mortems without telemetry data are just guessing. #47 waits for #43.
