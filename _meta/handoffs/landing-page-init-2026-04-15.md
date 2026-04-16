# CONTEXT HANDOFF — Landing Page Init Setup

Generated: 2026-04-15
Session: kernel-claude main

**Summary**: Added Phase 0 (INIT) to `/kernel:landing-page` so it bootstraps a proper repo (git init, .gitignore, README, AgentDB tracking) before generating files — not just a raw file dump.

**Goal**: Build an optimized static landing page (HTML/CSS/JS, content in content.js, tokens in tokens.css, deployed to Cloudflare Pages) — and have the command work as a first-class project bootstrapper, mirroring `/kernel:init` style.

**Current state**: Command has 9 phases now (0-8). Phase 0 creates the project directory, runs `git init`, writes `.gitignore` + `README.md`, checks for wrangler, emits AgentDB tracking, and commits the scaffold before Phase 1 interview begins generation.

**Branch**: main, 1 uncommitted file (.envrc, untracked), 1 modified (commands/landing-page.md)

**Tier**: 2 — command design, single-file change, moderate complexity.

**Decisions made**:
- **Add Phase 0 INIT instead of Phase 9 post-setup**: init must run BEFORE generation so all subsequent writes land in a git repo. Rejected: "run git init at the end" (loses the ability to commit each phase).
- **Include README + .gitignore in initial commit**: gives the user a reversible baseline before any generated content lands.
- **Non-blocking wrangler check**: warn if missing but don't fail — npx auto-fetches on first deploy.
- **Keep AgentDB emit lightweight**: one `command landing-page-init` event with project + path, not a full contract (tier 1 command, not orchestration).
- **Hypothesis H-LP-INIT added at 0.7 confidence**: standard pattern but untested specifically for this command.

**Artifacts created**:
- `/Users/ariaxhan/Downloads/Vaults/CodingVault/kernel-claude/commands/landing-page.md` — modified: added Phase 0 INIT (~100 lines), added H-LP-INIT hypothesis, updated Phase 8 handoff output with git status + remote push hint.
- `/Users/ariaxhan/Downloads/Vaults/CodingVault/kernel-claude/_meta/handoffs/landing-page-init-2026-04-15.md` — this file.

**Prior artifacts (from earlier session, still relevant)**:
- `commands/landing-page.md` — 8 phases + 20 hypotheses (now 21 with H-LP-INIT).
- `_meta/tools/convert-site.md` — private Vaults tool for extracting existing sites (10 hypotheses).
- `_meta/research/landing-page-experiments.md` — 11 experiments (A1-A5, B1-B5, C1) designed but not yet run.
- `_meta/research/ai-landing-page-failures-2026.md` — failure mode catalog that informs the enforcement rules.

**Big 5 Status**:
- [x] Input validation — Phase 0 Step 1 checks target dir doesn't exist; interview validates required fields.
- [x] Edge cases — wrangler missing (warn not fail), existing target dir (abort), no npx (warn).
- [x] Error handling — git init and commit surfaced via exit codes; AgentDB emit is fire-and-forget.
- [x] Duplication — Phase 0 explicitly references /kernel:init pattern rather than re-documenting.
- [x] Complexity — Phase 0 is 6 shell steps, no new abstractions, no deps.

**Open threads**:
- [TODO] Test Phase 0 end-to-end by running `/kernel:landing-page` in a fresh directory. Verify git repo initialized, README present, initial commit exists, subsequent generation lands in same repo.
- [TODO] Decide if Phase 0 should also `gh repo create` automatically or leave that as a handoff suggestion (currently suggested, not executed — avoids GitHub API coupling).
- [TODO] Run `/kernel:experiment` against the 21 hypotheses with a real site. Start with H-LP-INIT (easiest to validate: does it actually bootstrap cleanly?).
- [TODO] Source URL for `convert-site` extraction testing — user previously mentioned a WordPress URL but didn't share it yet.
- [DEFERRED] `_meta/research/landing-page-experiments.md` experiments A1-A5 (from-scratch), B1-B5 (conversion), C1 (deployment) — none run yet.

**Next steps (for new-repo session)**:
1. `cd` into the directory where the new project should live (e.g. `~/Projects/` or wherever).
2. Run `/kernel:landing-page` — it will now create a proper git repo, not dump raw files.
3. Phase 0 creates `{project-name}/`, inits git, writes README + .gitignore, commits. Phase 1 interview begins.
4. Answer interview questions (project name, tagline, description, colors, sections, optional: domain, fonts, dark mode).
5. Command generates content.js, tokens.css, main.css, index.html, _headers, _redirects, wrangler.toml, robots.txt, sitemap.xml.
6. Phase 7 audit runs automatic checks (no hardcoded colors, SEO complete, a11y baseline).
7. Phase 8 handoff prints git status + deploy commands.
8. Deploy: `npx wrangler pages deploy . --project-name={project}`.

**Warnings**:
- Phase 0 aborts if target dir exists. If iterating, delete or rename old dir first.
- Don't run `/kernel:landing-page` from inside an existing git repo unless you want a nested repo (common git anti-pattern — the command creates its own subdirectory so this is safe, but be aware).
- Hypothesis confidence on H-LP-INIT (0.7) is asserted, not measured. First real run is also the first test.
- Do NOT put Co-Authored-By or AI attribution in any commits the command generates (kernel-claude invariant).

**Continuation prompt**:
> /kernel:ingest Build a new landing page. I'm in a fresh directory ready for a new repo. Read _meta/handoffs/landing-page-init-2026-04-15.md for context on the init phase I just added. Run /kernel:landing-page — verify Phase 0 actually bootstraps the repo correctly before proceeding to interview.

**Related commands**:
- `/kernel:landing-page` — primary command (now 9 phases).
- `/kernel:experiment` — validate the 21 hypotheses.
- `convert-site` (in `_meta/tools/`) — for WordPress/existing-site extraction.
- `/kernel:init` — reference pattern that Phase 0 mirrors.
