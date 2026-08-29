---
type: chronicle
status: active
created: 2026-08-28
---

# The 8.1.2 de-bloat deleted seven skills and left twenty loads pointing at them for six months

**What mattered:** Every `/kernel:dream` run printed "quality subskill missing" because
`skills/quality/` was cut in 4dfb39c while nine skills and agents still loaded it. The same
release orphaned api, backend, testing, security, git and refactor; nothing tested that a
`skills/x/SKILL.md` load resolves.

**Shipped**
- 30cdd70: `skills/quality/` restored as a first-class skill (Big 5 checklist), registered in
  `governance/kernel.md.tmpl`, count 28 -> 29
- 6827144: the other six folded in as reference docs with no frontmatter
  (`skills/build/reference/{testing,refactor,git}*.md`, `skills/tearitapart/reference/security*.md`,
  `skills/architecture/reference/{api,backend}*.md`), all 20 loads repointed, scout's
  `skills/context` ref (renamed context-mgmt in 7.0.2) fixed

**Verified how:** `bash tests/run-tests.sh` 494/494 both commits; dead-ref loop
`grep -rhoE 'skills/[a-z-]+/(reference/[a-z-]+\.md|SKILL\.md)' skills agents | sort -u | while read f; do [ -f $f ] || echo $f; done`
empty; `tests/kernel9/measure_ambient.py` plugin 3960/4000. State: merged to origin/main, not
released (plugin cache still 9.6.5).

**Wrong or surprising**
- Edited generated `CLAUDE.md` directly; governance test flagged it stale. Source is
  `governance/kernel.md.tmpl` + `scripts/generate-governance.py`.
- Restoring the six as skills tripped the ambient ratchet (4490/4000). ~90 tok frontmatter each.
- First grep for dead refs matched only `skills/<name>/SKILL.md` against a hand-typed list and
  missed reference/ paths, `skills/context`, and 8 more files. Negative grep on one pattern is
  not absence.

**Open:** release 9.6.6 so the plugin cache picks this up; a test that every `skills/...`
path mentioned in skills/ and agents/ exists would have caught this in 8.1.2.
