# Kernel marketing + recall contract

Goal: make frontend work context-led, add reusable marketing/client judgment, keep explicit landing-page shipping simple, and make AgentDB recall easier to use well.

## Scope

- Refactor `skills/frontend/SKILL.md`: product/brand fit, hierarchy, accessibility, responsive behavior, performance, and visual QA are hard bars; specific aesthetics become optional direction.
- Add ambient `skills/marketing-site/`: audience, offer, proof, objections, CTA, privacy, and client handoff. It may advise, never deploy.
- Refactor explicit-only `skills/landing-page/` to compose marketing + frontend and handle scaffold, verification, and provider-neutral deployment.
- Put a compact keyword recipe and rerun triggers in canonical governance and `agentdb read-start --lean`.
- Reinforce recall at high-frequency build/debug/diagnose entry points without copying a long policy everywhere.

## Acceptance

- Normal-language marketing/client website requests can surface `marketing-site`; deployment still requires explicit `landing-page` invocation or direct user authorization.
- Frontend preserves an existing design system and derives art direction from evidence; no universal font/layout/color recipe remains.
- Marketing guidance forbids invented testimonials, customers, metrics, guarantees, or fake urgency.
- Recall says to use feature/subsystem, files/symbols, and exact error/outcome keywords; rerun after discovery, scope/hypothesis change, or a new failure.
- Lean memory output remains compact and generated governance stays byte-synced.
- Targeted regressions and the full suite pass; unrelated dirty files remain unstaged.

## Verification

1. Run focused skill, governance, recall, and migration tests.
2. Generate and check native governance adapters.
3. Run the full test suite and skill validator.
4. Review the exact diff, bump minor version, validate release docs.
5. Merge/tag/push through the repository release flow, upgrade marketplace install, and inspect the installed payload.
