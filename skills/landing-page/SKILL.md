---
name: landing-page
description: "Guided landing page generator. Interview → scaffold → enforce → deploy. Static HTML/CSS optimized for Cloudflare Pages. All architectural decisions are hypotheses until proven by /kernel:experiment."
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, WebSearch, WebFetch
disable-model-invocation: true
kernel:
  kind: operator
  version: 1
  side_effects: deploys
  confirmation: on_side_effect
---

<skill id="landing-page">

<purpose>
Ship a fast, distinctive static landing page. Interview the human for the real inputs,
scaffold a minimal static site, enforce the non-negotiable quality bars, deploy. Explicit
invocation only, it deploys. Keep this skill small: the model already knows how to build a
static page, this just supplies the interview, the guardrails, and the deploy path.
</purpose>

<skill_load>skills/frontend/SKILL.md</skill_load>

<interview>
Ask the human, briefly, before writing anything (skip any the human already gave):
1. What is this page for, one sentence, and who lands on it?
2. The single action you want them to take (the primary CTA).
3. Brand: name, any existing colors/font/logo, and a reference site whose feel you like.
4. Content: headline, subhead, 2-4 value points, social proof if any, footer links.
5. Domain + where it deploys (default: Cloudflare Pages).
Do not invent brand facts. Unknown = ask, never fill with a plausible guess.
</interview>

<build>
- Static only by default: one `index.html`, one `styles.css`, assets in `/assets`. Add JS
  only for a real interaction, never for layout. No framework unless the human asks.
- Follow skills/frontend for aesthetic: no generic AI look, no Inter-by-default, no emoji
  chrome. Pick a distinctive type + color system grounded in the brand answers.
- Responsive by construction: verify at 375 / 768 / 1440. Content never overflows the body.
- One clear CTA above the fold, repeated once lower. Everything serves that action.
- Accessibility: semantic landmarks, alt text, visible focus, keyboard reaches every control,
  contrast passes AA.
</build>

<enforce>
Before deploy, these are hard bars, not suggestions:
- Loads with zero console errors at all three breakpoints.
- Largest Contentful Paint image is sized/compressed; no multi-MB hero.
- No secrets, analytics keys, or tokens in the committed source.
- Every link resolves; the CTA points somewhere real.
- Lighthouse-style sanity: no render-blocking bloat, fonts subset or system.
</enforce>

<deploy>
- Cloudflare Pages by default (`wrangler pages deploy ./` or the project's configured path).
- Confirm the deploy target with the human before pushing (this skill has side_effects: deploys).
- After deploy, VERIFY LIVE: curl the deployed URL, confirm 200 + the headline is in the HTML.
  "Deployed" is not "working" until the served asset is checked. Report the live URL.
</deploy>

<hypotheses>
Architecture choices here (static-first, single CTA, system fonts) are defaults, not dogma.
A repeated better result promotes via /kernel:experiment, it does not get hardcoded as a rule.
</hypotheses>

<hard_stops>
- Never deploy without explicit human confirmation of the target.
- Never commit secrets or a key into the page source.
- Never report the page done off a commit, verify the live URL first.
</hard_stops>

<on_end>
Report: the live URL (verified), the breakpoints checked, and any bar you could not meet
(state it plainly, never claim a green you did not observe).
</on_end>

</skill>
