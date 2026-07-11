# {Skill Name} -- TEMPLATE

Copy this file to `skills/{name}/SKILL.md` and fill in sections.

## Frontmatter (required)

Native Claude Code keys: `name`, `description` (with "Triggers:" phrasing),
`allowed-tools`; optional `user-invocable`, `disable-model-invocation` (REQUIRED true
for side-effecting/expensive skills), `context: fork`, `model`, `hooks`.

Kernel taxonomy block (kernel-validated, host-ignored):

```yaml
kernel:
  kind: methodology | workflow | state_transition | validator | operator
  version: 1
  side_effects: none | writes_meta | writes_repo | writes_remote | deploys
  confirmation: none | on_side_effect | always
  produces: [kernel.handoff/v1]      # state transitions only
  consumes: [kernel.checkpoint/v1]   # if the skill reads manifests
```


Every skill needs these sections. Delete this template text after filling in.

### Source Loading

What reference documents to load BEFORE acting:

```yaml
sources:
  - _meta/research/{topic}.md
  - _meta/plans/{plan}.md
```

### Triggers

When should this skill be loaded:

```yaml
triggers: "{keyword1}, {keyword2}, {keyword3}"
```

### Quality Gates

What must be true for output to be valid:

```yaml
gates:
  - gate_1: description
  - gate_2: description
```

### Output Format

What the skill produces:

```yaml
output:
  verdict: CLEAN | FIXED | NEEDS-HUMAN
  evidence: required
```

### Flags (optional)

CLI-style flags for skill variants:

```yaml
flags:
  --dry-run: simulate without writing
  --batch: process multiple items
  --file <path>: target specific file
```

### Anti-Patterns

What this skill should NEVER do:

```yaml
anti_patterns:
  - never: description
```

## Example

See existing skills for reference:
- `skills/quality/SKILL.md` -- general quality checks
- `skills/testing/SKILL.md` -- test methodology
- `skills/build/SKILL.md` -- implementation patterns
