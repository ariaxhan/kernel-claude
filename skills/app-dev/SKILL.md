---
name: app-dev
description: "Mobile/web app build pipeline, EAS, store submission, pre-submission checklists. Triggers: app, mobile, EAS, store submission, build, deploy app, expo, react native, flutter."
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Task
---

# FLOW

1. **Load source files** — Read `eas.json`/`app.config.js`/`build.gradle`/CI config. If none exist, scaffold from EAS defaults. (gate: build tooling identified)
2. **Identify environment** — dev / staging / production. Confirm API endpoints, signing creds, and feature flags are environment-specific. (gate: no hardcoded keys or shared signing certs)
3. **Select build profile** — development (simulator), preview (internal dist), or production (auto-increment). Run `eas build --profile <profile>`. (gate: build completes without error)
4. **OTA vs. store build decision** — JS-only change → `eas update`. Any native change → full store build. (gate: OTA never used for native changes)
5. **Run pre-submission checklist** (gate: all items pass before submitting):
   - [ ] Privacy manifests (iOS): all required API reasons declared
   - [ ] Permissions: only what you use, with clear usage descriptions
   - [ ] Metadata: screenshots current, descriptions accurate
   - [ ] Version/build numbers: incremented correctly
   - [ ] Physical device testing: tested on real device (not simulator)
   - [ ] Deep links: universal links / app links verified
   - [ ] Push notifications: working in production config
   - [ ] Crash-free rate: > 99% on staging before promoting
   - [ ] Bundle size: within limits, no large accidental assets
   - [ ] Offline behavior: handles no-network gracefully
6. **iOS submission** — TestFlight (internal → external) → App Store review. (gate: all metadata complete; privacy manifests present)
7. **Android submission** — Internal testing → closed/open beta → staged production rollout starting at 5-10%. (gate: data safety form complete; crash rate stable)
8. **Monitor rollout** — watch crash rates before expanding staged rollout. OTA rollback: `eas update:rollback`. Store rollback: halt rollout in console. (gate: crash-free rate holds > 99%)

# ANTI-PATTERNS (block on detection)

- Hardcoded API keys in builds → use EAS secrets
- OTA update for native changes → must be a store build
- Skipping physical device testing → simulators miss real-world issues
- 0-to-100% rollout on Android → start at 5-10%
- Shared signing certs across environments → separate keystores

# REFERENCE

Deep rationale, eas.json examples, environment config patterns, iOS/Android submission detail:
`skills/app-dev/reference/app-dev-research.md`

# ON COMPLETE

agentdb write-end '{"skill":"app-dev","platform":"ios|android|both","gate":"submitted|built|blocked","store_ready":true}'
