# AWS AOH Hackathon Config Analysis

**Research on the aws-aoh-hackathon repository structure for alignment with KERNEL plugin.**

---

## Summary

The aws-aoh-hackathon uses a layered config system that separates:
- **`_meta/`** - Strategic research and planning (design, open-source strategy)
- **`.claude/`** - Active development config (commands, rules, plans, research)

Key insight: `_meta/` is for **human-facing** documentation and long-term artifacts, while `.claude/` is for **Claude-facing** instructions and session outputs.

---

## _meta/ Structure

```
_meta/
├── design-research.md       # Deep dive research (357 lines, comprehensive)
├── open-source-strategy.md  # Strategic planning document
└── research/
    ├── python-packaging-patterns.md
    └── open-source-security-landscape.md
```

**Purpose**: Strategic, long-lived documents. Not session-specific.

**Notable patterns**:
- Research docs are comprehensive with sources cited
- Strategic docs include implementation recommendations
- Subdirectory for investigation outputs

---

## .claude/ Structure

```
.claude/
├── CLAUDE.md            # Project philosophy and rules
├── commands/            # Custom CLI commands
│   ├── my-tests.md
│   ├── demo-check.md
│   └── sync.md
├── rules/               # Project patterns
│   ├── fallback-first.md
│   └── track-ownership.md
├── plans/               # Work plans
│   └── honeypot-coordination.md
├── research/            # Claude investigation outputs
│   ├── bedrock-embeddings-research.md
│   └── s3-vectors-research.md
├── settings.json        # Hook configuration
└── settings.local.json  # Local overrides
```

**Notable patterns**:
- Commands separate from banks
- Research lives in `.claude/research/` (Claude outputs)
- Plans for coordination
- Settings for hooks (PostToolUse auto-compile)

---

## CLAUDE.md Structure

Key sections:
1. **Project Context** - Tier, stack, constraints
2. **Development Tracks** - Ownership table
3. **Coding Rules** - Fallback-first, config-driven, contracts
4. **Commands** - Quick reference
5. **Key Files** - Critical paths
6. **Default Behaviors** - When implementing, debugging, completing

---

## Session/Learnings Tracking

No dedicated session tracking in the hackathon repo. Uses:
- Git commits as change log
- `.claude/research/` for investigation outputs
- Track ownership for parallel work

Parent vault (CodingVault) provides:
- `_meta/_session.md` - Cross-repo session context
- `_meta/_learnings.md` - Learning log

---

## Implications for KERNEL Plugin

1. **Add `_meta/`** - For session tracking, learnings, research (done)
2. **Keep `kernel/state.md`** - Serves different purpose (project reality)
3. **Research outputs** → `_meta/research/` (for persistence)
4. **Consider `commands/`** → Already exists, structure is similar
5. **Add session protocol** to CLAUDE.md (done)

---

## Key Differences

| Aspect | aws-aoh-hackathon | kernel-plugin |
|--------|-------------------|---------------|
| Session tracking | None (hackathon) | `_meta/_session.md` |
| Learnings log | None | `_meta/_learnings.md` |
| Research outputs | `.claude/research/` | `_meta/research/` |
| Project state | N/A | `kernel/state.md` |
| Methodology | Banks in `.claude/` | Banks in `kernel/banks/` |

---

*Research conducted 2026-01-17*
