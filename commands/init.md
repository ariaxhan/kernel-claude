---
name: kernel:init
description: "Initialize KERNEL for a project. Audits codebase, seeds AgentDB with detected patterns, creates quality baseline."
user-invocable: true
allowed-tools: Read, Write, Bash, Grep, Glob
---

<command id="init">

<purpose>
Full project initialization. Audit, detect, seed.
Creates project-specific quality baseline from actual code patterns.
</purpose>

<phase id="1_structure">
```bash
mkdir -p _meta/{agentdb,context,plans,research,handoffs}
mkdir -p .claude/rules
```
</phase>

<phase id="2_agentdb">
```bash
sqlite3 _meta/agentdb/agent.db "
PRAGMA journal_mode=WAL;
CREATE TABLE IF NOT EXISTS learnings (id TEXT PRIMARY KEY, ts TEXT DEFAULT CURRENT_TIMESTAMP, type TEXT, insight TEXT NOT NULL, evidence TEXT, domain TEXT, hit_count INTEGER DEFAULT 0);
CREATE TABLE IF NOT EXISTS context (id TEXT PRIMARY KEY, ts TEXT DEFAULT CURRENT_TIMESTAMP, type TEXT, contract_id TEXT, agent TEXT, content TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS errors (id INTEGER PRIMARY KEY, ts TEXT DEFAULT CURRENT_TIMESTAMP, tool TEXT, error TEXT, file TEXT);
CREATE INDEX IF NOT EXISTS idx_learnings_type ON learnings(type);
CREATE INDEX IF NOT EXISTS idx_context_type ON context(type);
"
```
</phase>

<phase id="3_audit">
<detect id="stack">
```bash
ls -la package.json requirements.txt pyproject.toml go.mod Cargo.toml 2>/dev/null
```
</detect>

<detect id="quality_baseline" skill_load="skills/quality/SKILL.md">
Run Big 5 detection on existing code:
```bash
# Input validation
grep -r "req\.body" --include="*.ts" --include="*.js" 2>/dev/null | grep -v "parse\|validate\|z\." | wc -l

# Empty catch blocks
grep -r "catch.*{}" --include="*.ts" --include="*.js" 2>/dev/null | wc -l

# String concat in queries
grep -rE "SELECT.*\$\{|INSERT.*\$\{" --include="*.ts" --include="*.js" 2>/dev/null | wc -l
```
Record baseline counts.
</detect>

<detect id="conventions">
```bash
ls -la .eslintrc* .prettierrc* tsconfig.json 2>/dev/null
```
</detect>
</phase>

<phase id="4_seed">
Seed AgentDB with detected patterns:
```bash
sqlite3 _meta/agentdb/agent.db "
INSERT OR IGNORE INTO learnings (id, type, insight, evidence, domain) VALUES
('init-stack', 'pattern', '{detected stack}', 'Detected during init', 'project'),
('init-quality-baseline', 'pattern', '{Big 5 baseline counts}', 'Detected during init', 'quality'),
('init-conventions', 'pattern', '{detected conventions}', 'Detected during init', 'code-style');
"
```
</phase>

<phase id="5_claude_md">
Create .claude/CLAUDE.md with detected info:
- Tech stack (specific)
- Quality baseline (Big 5 counts)
- Conventions detected
- KERNEL integration instructions
</phase>

<phase id="6_context">
Create _meta/context/active.md:
- Project summary
- Structure
- Quality baseline (reference skills/quality/SKILL.md)
- Current focus: Ready for first task
</phase>

<output>
```
KERNEL initialized for {project}!

Detected:
- Stack: {list}
- Quality baseline: {Big 5 counts}
- Conventions: {list}

Created:
- .claude/CLAUDE.md (project-specific)
- _meta/agentdb/agent.db (seeded)
- _meta/context/active.md

Quality baseline seeded - future changes compared against this.
Start with /ingest and describe your task.
```
</output>

</command>
