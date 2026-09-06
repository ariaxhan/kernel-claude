# Kernel project-health repair — 2026-09-06

Starting revision: `0be950571ccaa817de424d826698a2d9c0946be8` (9.10.3).
Scope: [issue #221](https://github.com/ariaxhan/kernel-claude/issues/221) and the failed [HOL scan run 33836886535](https://github.com/ariaxhan/kernel-claude/actions/runs/33836886535). No version bump or new skill definitions.

## Dependency repair

The missing method blocks had already been restored by `6827144`: quality is a skill, and testing/security/api/backend/git/refactor are canonical reference documents. Every currently shipped concrete skill reference resolves. Restoring extra ambient skills would duplicate those methods and increase the ambient token budget; inlining would duplicate the canonical definitions. The selected repair strengthens the existing reference check and activates an orphaned methodology regression.

The old resolver recognized only lowercase skill names, `SKILL.md`, and singular `reference/<lowercase-name>.md`. A new fixture reproduces five missing targets across inline and conditional skill loads, agent loads, nested paths, numeric/underscore names, and YAML references. With the original expression it detected only two of five missing targets and failed; the expanded resolver detects all five, then passes once their files exist. It also checks every shipped skill/agent document. Sentence punctuation is excluded from paths.

`test_methodology_carries_cross_loader_release_lessons` still referred to deleted testing/security skill paths and was unregistered. It now reads the existing canonical reference documents and runs in the configured `verify` suite. No skill behavior was removed.

Preimplementation review: PROCEED. Extend the existing validator; preserve the canonical methodology, detector behavior, severity gate, and other contributors' dirty files. Use actual scanner findings before selecting a remediation.

## Why the security scan failed

The pinned action uses `plugin-scanner==2.2.126` and `cisco-ai-skill-scanner==2.0.14`. The recorded run wrote SARIF, exited 1 because findings met the high threshold, and skipped both publishing steps. GitHub had no artifact for this run; its code-scanning alerts were from the older revision `5a07dde`, so those alerts did not establish the cause.

A tracked-file archive of the exact starting revision reproduced seven high findings and score 84. The same scanner versions ran locally in an isolated temporary virtual environment, with online probing, submissions, and PR comments disabled. A separate scan of the working directory included its untracked SQLite database and therefore had ten high findings and score 84; that scan was not used as CI baseline evidence.

The seven high findings represent three underlying text matches. Native matches are repeated for the repository's three discovered plugin ecosystems. Every matched credential-shaped value was confirmed equal to the canonical public AWS documentation example; no live credential was identified. The example value is intentionally omitted from this report.

The Cisco rule maps the ordinary multiplication character to ASCII `x` anywhere in a document. It then searches the entire decoded document for a broad instruction expression. Here that expression joins the existing ASCII text “reads checkpoint” to “tracks token” across two sections. The reported line 30 is merely the first non-ASCII line, not the actual matched phrase or changed character. The text describes checkpoint restoration and usage accounting, with no credential-access or exfiltration instruction.

## Static triage ledger

IDs preserve the clean baseline report order. `not_actionable` here classifies the claimed security defect; presentation cleanups can still prevent misleading findings. These findings have no exploitability rank because none establishes a supported attacker-to-protected-operation path. Confidence is high for the exact matched content; this is not an exhaustive security audit.

| ID | Scanner finding | Location | Verdict and evidence |
|---|---|---|---|
| 1 | high / HARDCODED_SECRET | `_meta/agentdb/agent.db.json:2292` | not_actionable: error row 56 records a historical hook rejection of the public AWS example; no credential sink. |
| 2 | high / HARDCODED_SECRET | `hooks/scripts/detect-secrets.sh:80` | not_actionable: explanatory comment quotes the same public example; executable detection patterns are unaffected. |
| 3 | high / HARDCODED_SECRET | `_meta/agentdb/agent.db.json:2292` | not_actionable: same public example, emitted for another discovered ecosystem. |
| 4 | high / HARDCODED_SECRET | `hooks/scripts/detect-secrets.sh:80` | not_actionable: same detector comment, emitted for another discovered ecosystem. |
| 5 | high / UNICODE_OBFUSCATED_INSTRUCTION | `skills/orchestration/reference/orchestration-research.md:30` | not_actionable: multiplication notation plus unrelated checkpoint/token-accounting prose, not an obfuscated instruction. |
| 6 | high / HARDCODED_SECRET | `_meta/agentdb/agent.db.json:2292` | not_actionable: same public example, emitted for the third ecosystem. |
| 7 | high / HARDCODED_SECRET | `hooks/scripts/detect-secrets.sh:80` | not_actionable: same detector comment, emitted for the third ecosystem. |
| 8 | medium / MARKETPLACE_POLICY_FIELDS_MISSING | `.agents/plugins/marketplace.json` | not_actionable: authentication is intentionally absent for this local plugin. `tests/kernel9/test_adapters.py` records the real loader's rejection of invented `NONE`; only `ON_INSTALL` and `ON_USE` are valid when specified. |
| 9 | medium / FILE_MAGIC_MISMATCH | `skills/frontend/variants/arctic.md` | not_actionable: visible XML-tagged design prose, loaded as text; not executable or concealed content. |
| 10 | medium / FILE_MAGIC_MISMATCH | `skills/frontend/variants/verdant.md` | not_actionable: visible XML-tagged design prose, loaded as text; same file-format heuristic. |
| 11 | medium / FILE_MAGIC_MISMATCH | `skills/experiment/agents/openai.yaml` | not_actionable: ordinary YAML interface/policy metadata, including disabled implicit invocation; classified as textproto heuristically. |
| 12 | medium / FILE_MAGIC_MISMATCH | `skills/eval/SKILL.md` | not_actionable: Markdown frontmatter and XML-tagged instructions; no Ruby interpreter path. |
| 13 | info / PLUGIN_JSON_INTERFACE_ASSET_PRIVACYPOLICYURL | `.codex-plugin/plugin.json` | not_actionable: field is absent; there is no unsafe URL value. |
| 14 | info / PLUGIN_JSON_INTERFACE_ASSET_TERMSOFSERVICEURL | `.codex-plugin/plugin.json` | not_actionable: field is absent; there is no unsafe URL value. |
| 15 | info / PLUGIN_JSON_INTERFACE_ASSET_COMPOSERICON | `.codex-plugin/plugin.json` | not_actionable: field is absent; there is no unsafe asset path. |
| 16 | info / PLUGIN_JSON_INTERFACE_ASSET_LOGO | `.codex-plugin/plugin.json` | not_actionable: field is absent; there is no unsafe asset path. |
| 17 | info / PLUGIN_JSON_INTERFACE_ASSET_SCREENSHOTS | `.codex-plugin/plugin.json` | not_actionable: field is absent; there is no unsafe asset path. |

Boundary basis: `SECURITY.md` covers hook bypasses, injection, local memory access, and secrets; it does not claim control of model output. The flagged surfaces above are shipped documentation, detector comments, metadata, and a recorded public test example. Scanner locations alone do not establish a bypass or attacker-controlled execution path. Remaining medium/info findings stay visible; no suppression, baseline exemption, scanner disablement, or fabricated manifest value was added.

## Changes and verification

- Removed the full public example from the detector's explanatory comment. Detection logic is byte-identical after excluding comments; the existing checksum guard now pins the changed comment version.
- Replaced the single known public example in the existing JSON snapshot with a descriptive redaction. Preserved every other byte, including unrelated pending changes. Updated only `errors.id=56` in the local runtime SQLite database with a parameterized transaction and an exact old-content predicate so exports cannot restore it. One row changed; no other rows were touched.
- Replaced multiplication notation with “times” in the budget explanation, preserving its meaning.
- Preserved the workflow's `min_score: 80` and `fail_on_severity: high`. Moved report publication to explicit caller steps that run after failure; SARIF is both archived and sent to code scanning. The scanner failure still fails the job.
- New dependency regression: failed before the resolver change (2 detected versus 5 expected), passed afterward. `verify`: 8 passing tests. Secret-hook suite: 19 passing tests. Full configured suite: 337 passing tests both before and after the final scanner text cleanup. Configured shellcheck, violation corpus, orphan check, generated-governance check, and diff whitespace check also pass.
- Repaired clean archive scanner: score 93, zero critical/high, five medium and five info findings. Those remaining findings are documented above and retained in the report.

Temporary evidence: `/tmp/kernel-health-ci-before.json`, `/tmp/kernel-health-ci-after.json`, `/tmp/kernel-health-final.sarif`, `/tmp/kernel-health-tests.log`, `/tmp/kernel-health-tests-final.log`, `/tmp/kernel-health-security-hooks.log`. A final SARIF scan including all repaired and new files exited 0 and produced valid SARIF 2.1.0 with ten note/warning results. The original CI report was unavailable; reproduction matched its pinned scanner/Cisco versions on macOS rather than the original Ubuntu runner. The repaired workflow still needs a real CI run at the landed revision to prove report upload behavior.

Runtime row evidence: before SHA-256 `dc8603516210a6f7790f9a518bede0b5ece7fbd8473b5134bae9d4cc49e36536`, after SHA-256 `734aac69a027f2387659f0cf57e7a02228354c43a86a7d03e6977bee75d8a741`. These hashes identify only the historical error string, not a credential.

## Landing handoff

The supervising agent owns commit, push, independent review, and merge. Stage only the intended example-redaction hunk in the pre-existing dirty snapshot; do not stage unrelated memory changes or the untracked skipped chronicle. No manifest edits were needed. No live credential was found, so credential rotation is not indicated by these findings.
