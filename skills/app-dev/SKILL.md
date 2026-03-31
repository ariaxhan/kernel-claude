---
name: app-dev
description: "Mobile/web app build pipeline, EAS, store submission, pre-submission checklists. Triggers: app, mobile, EAS, store submission, build, deploy app, expo, react native, flutter."
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Task
---

# PURPOSE

Ship apps to stores with confidence. Build pipeline patterns, EAS/Expo workflows,
and pre-submission checklists that prevent rejection and downtime.

**Prerequisite**: AgentDB read-start has already run. Project build tooling identified.

---

# BUILD PIPELINE

```
LOCAL DEV -> STAGING -> PRODUCTION
   |            |           |
   v            v           v
 hot reload   OTA test    store build
 simulators   TestFlight   full review
 dev API       staging API  prod API
```

## Environment Separation

Each environment gets its own:
- API endpoints (never hardcode — use env configs)
- Signing credentials (dev, staging, prod keystores)
- Feature flags (staging can enable experimental features)
- Analytics keys (separate dev/prod to avoid polluting data)

---

# EAS / EXPO PATTERNS

## Build Profiles

```json
{
  "build": {
    "development": { "distribution": "internal", "ios": { "simulator": true } },
    "preview": { "distribution": "internal" },
    "production": { "autoIncrement": true }
  }
}
```

## OTA Updates (EAS Update)

- Use `eas update` for JS-only changes (no native code changes).
- Runtime version pinning: tie OTA updates to compatible native builds.
- Never push OTA updates that require native changes — this crashes apps.
- Channel strategy: `production`, `staging`, `preview` channels.
- Rollback: `eas update:rollback` to revert bad OTA pushes.

## Environment Configs

- Use `app.config.js` (dynamic) over `app.json` (static) for environment switching.
- Expo Constants for runtime env detection.
- EAS secrets for build-time environment variables.
- Never commit `.env` files — use EAS secrets or CI/CD env vars.

---

# STORE SUBMISSION

## iOS (App Store Connect)

1. **TestFlight**: internal testing first, then external beta.
2. **App Store Review**: 24-48 hours typical. Plan for rejection cycles.
3. **Required metadata**: screenshots (6.7", 6.5", 5.5"), description, keywords, privacy URL.
4. **Privacy manifests** (required since Spring 2024): declare all API usage reasons.
5. **Signing**: use automatic signing in EAS. Manual = pain.

## Android (Play Console)

1. **Internal testing**: fastest approval, limited testers.
2. **Closed/open testing**: broader beta before production.
3. **Production rollout**: staged rollout (start 5-10%, watch crash rates).
4. **Required metadata**: feature graphic, screenshots, descriptions, content rating.
5. **Data safety form**: declare all data collection and sharing.

---

# PRE-SUBMISSION CHECKLIST

Run before EVERY store submission:

- [ ] **Privacy manifests** (iOS): all required API reasons declared
- [ ] **Permissions**: only request what you use, with clear usage descriptions
- [ ] **Metadata**: all screenshots current, descriptions accurate
- [ ] **Version/build numbers**: incremented correctly
- [ ] **Physical device testing**: tested on real device (not just simulator)
- [ ] **Deep links**: universal links / app links verified
- [ ] **Push notifications**: registered and working in production config
- [ ] **Crash-free rate**: > 99% on staging before promoting
- [ ] **Bundle size**: within acceptable limits, no accidental large assets
- [ ] **Offline behavior**: app handles no-network gracefully

---

# ANTI-PATTERNS

- **Hardcoded API keys in builds**: use EAS secrets or env configs. Keys in source = revoked keys.
- **Skip store review guidelines**: read the guidelines. Rejection wastes days.
- **Deploy without physical device testing**: simulators miss real-world issues (memory, GPS, camera).
- **OTA for native changes**: OTA is JS-only. Native changes need a new store build.
- **Ignore staged rollout**: going 0 to 100% is reckless. Start at 5-10%.
- **Same signing certs for dev and prod**: separate keystores per environment.
- **Skip TestFlight/internal testing**: internal testers catch what automated tests miss.

---

# SOURCE LOADING

Project-specific build configs vary. Load these at start:
- `eas.json` or `eas.config.js` — EAS build profiles
- `app.config.js` or `app.json` — Expo configuration
- `fastlane/Fastfile` — if using Fastlane for native builds
- `android/app/build.gradle` — Android build config
- `ios/*.xcodeproj` or `ios/*.xcworkspace` — iOS project
- CI/CD config (`.github/workflows/`, `bitrise.yml`, etc.)

If none exist, this is likely a new project — scaffold from EAS defaults.
