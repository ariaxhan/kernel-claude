# Dependency review — 2026-09-06

Baseline: main `2353ae7`. Scope: compatible lock-only remediation of the seven open GitHub dependency alerts. No plugin security scanner rerun, source/manifests changes, production operations, or credentials accessed.

## Findings and changes

All seven open Dependabot alerts belong to the single npm lockfile `frontend/package-lock.json`; no other npm manifest is affected. They comprise three high and two moderate Vite advisories, one low esbuild advisory, and one low cookie advisory. A fresh npm registry audit additionally reported a moderate SvelteKit content-negotiation ReDoS advisory.

`npm audit fix --package-lock-only --ignore-scripts`, under the supported installed Node 22 runtime, produced these changes within the existing direct dependency ranges:

| Package | Before | After | Result |
| --- | --- | --- | --- |
| Vite | 7.3.1 | 7.3.6 | Resolves GitHub alerts #8, #9, #10, #22, #23 |
| esbuild and its platform packages | 0.27.4 | 0.28.2 | Resolves alert #20 through Vite's updated declared dependency |
| SvelteKit | 2.69.2 | 2.70.3 | Resolves [GHSA-29g2-3rmr-qm68](https://github.com/advisories/GHSA-29g2-3rmr-qm68) |
| cookie | 0.6.0 | 0.6.0 | Alert #7 remains; no compatible dependency resolution available |

The lockfile's root manifest record is byte-equivalent as parsed JSON. No package paths were added or removed. No overrides, forced updates, manifest edits, or major direct dependency changes were introduced.

## Reachability

- Vite and esbuild findings concern development-server behavior, including Windows-specific paths. This frontend configures the Vite development server on port 5174. These packages are tooling for the optional frontend, not the installed kernel skill runtime. No claim about a currently running/exposed server is made.
- SvelteKit is listed under devDependencies but supplies the adapter-node server runtime. Its content-negotiation issue is therefore relevant to a served frontend and was fixed; the manifest classification alone is not proof of runtime safety.
- SvelteKit imports cookie parsing/serialization into its server implementation. The remaining [cookie advisory](https://github.com/advisories/GHSA-pxg6-pf52-xh8x) requires untrusted cookie names, paths, or domains to reach serialization. No application `cookies.set`, `cookies.serialize`, or `Set-Cookie` calls were found under `frontend/src`. This limits the demonstrated application attack path; it does not remove the vulnerable dependency.

## Remaining advisory

At review time, the npm registry reports latest stable SvelteKit **2.70.3**, still declaring `cookie: ^0.6.0`. Patched cookie starts at **0.7.0**, outside that declared range. npm's suggested forced remediation downgrades SvelteKit to **0.0.30** and proposes similarly incompatible adapter versions. That is not an acceptable compatible lock-only repair and was not applied.

Final full `npm audit --json` exits 1 with **4 low package entries**, all propagated from that one cookie advisory: cookie, SvelteKit, adapter-auto, adapter-node. It reports **0 moderate, 0 high, 0 critical**. GitHub's alert #7 remains outstanding; the other six initial alerts are addressed by this candidate lock and will require GitHub's post-push reevaluation before their remote status changes. Revisit when upstream adopts a patched cookie range; any override/source remediation is separate work requiring its own compatibility validation.

## Validation

The repository had no frontend node_modules, and remains that way. Validation used an isolated copy of tracked frontend files plus the candidate lock:
`/var/folders/tj/k461cgxs12gcjpxtgwdqsx7c0000gn/T/kernel-health-dependencies-aic5zi2v/frontend`.

| Check | Result |
| --- | --- |
| Node 26 initial lock-only attempt | Refused by better-sqlite3 12.8.0 engine range; no lock change |
| Installed Node 22.22.3 | Supported runtime used for update/install/check/build/audit |
| `npm ci --no-audit --no-fund` | Exit 0; exact candidate lock reproduced |
| `npm run check` | Exit 0; Svelte check 0 errors, 0 warnings |
| `npm run build` | Exit 0; adapter-node production build completed |
| `npm audit --audit-level=moderate` | Exit 0; prints the remaining low advisory without hiding it |
| Full `npm audit --json` | Exit 1; 4 low package entries, no moderate/high/critical |
| `git diff --check` | Passed |

The frontend configures no test script; its relevant configured checks are check and build. No development/preview server was started and no real AgentDB was loaded. The broader plugin scanner's existing green run `34058048870` is separate evidence and was not rerun.

Local logs: `/tmp/kernel-dependency-audit-before.json`, `/tmp/kernel-dependency-audit-after.json`, `/tmp/kernel-health-dependencies-install.log`, `/tmp/kernel-health-dependencies-check.log`, `/tmp/kernel-health-dependencies-build.log`, `/tmp/kernel-health-dependencies-audit-threshold.log`.

Authored repository files: `frontend/package-lock.json` and this report only. Existing dirty `_meta/agentdb/agent.db.json` and untracked skipped chronicle were preserved. No commit, push, or deployment by this lane.
