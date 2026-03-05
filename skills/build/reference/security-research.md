# Security Reference: Research & Best Practices

Reference for secure coding, vulnerability prevention, and AI-specific security risks.
Read on demand. Not auto-loaded.

## Sources

OWASP Top 10 2025, OWASP Top 10 for LLM Applications 2025, OWASP Top 10 for
Agentic Applications 2026 (NEW), Veracode State of Software Security 2026
(Feb 26, 2026), IBM X-Force Threat Index 2026 (Feb 25, 2026), Black Duck OSSRA
2026 (Feb 25, 2026), Snyk AI Security Fabric (Feb 3, 2026), Anthropic Opus 4.6
System Card (Feb 5, 2026), NIST SP 800-218r1 (SSDF 1.2), Check Point MCP research.

---

## AI Code Security: The Numbers (Updated Feb 2026)

Veracode 2026: Security debt affects **82%** of organizations (up from 74%).
High-risk vulnerabilities now at **11.3%** (up from 8.3%).
Veracode: 45% of AI-generated code contains known security flaws.
Opsera 2026: AI code has **15-18% more vulnerabilities** than human code.
CodeRabbit: AI PRs have 1.57x more security findings than human PRs.

IBM X-Force 2026: 44% surge in app exploitation, 4x supply chain attacks since 2020.
Black Duck 2026: Open source vulnerabilities doubled; only 24% do comprehensive
AI code evaluation.

Critical: More vulnerabilities are now created than fixed. AI accelerates
code creation but security review can't keep pace.

---

## OWASP Top 10 (2025) - Most Relevant to AI-Generated Code

A01: Broken Access Control. AI generates endpoints without auth checks.
Always verify: is this endpoint protected? Who can access it?

A03: Software Supply Chain Failures (NEW position). AI adds dependencies
without auditing. Each dependency is a trust decision.
Always: npm audit / pip-audit / cargo audit after adding dependencies.

A05: Injection. AI generates string concatenation for SQL, shell commands,
HTML output. Parameterize everything.

A08: Server-Side Request Forgery. AI generates HTTP clients that don't
validate URLs. Always validate and restrict outbound requests.

A10: Mishandling of Exceptional Conditions (NEW). AI swallows errors or
exposes stack traces. Handle errors explicitly with actionable messages.

---

## OWASP Top 10 for LLM Applications (2025)

LLM01: Prompt Injection. Crafted inputs manipulate LLM behavior.
LLM02: Sensitive Information Disclosure. LLMs leak PII or credentials.
LLM03: Supply Chain. Compromised models, poisoned training data.
LLM04: Data and Model Poisoning. Tampered training degrades security.
LLM05: Improper Output Handling. LLM output used without validation.
LLM06: Excessive Agency. LLMs granted unchecked autonomy.
LLM07: System Prompt Leakage. System instructions exposed to users.
LLM08: Vector and Embedding Weaknesses. RAG pipeline vulnerabilities.
LLM09: Misinformation. LLMs generate false but plausible content.
LLM10: Unbounded Consumption. Resource exhaustion via LLM abuse.

---

## OWASP Top 10 for Agentic Applications (2026) — NEW

Distinct from LLM Top 10. Key distinction: "A standard LLM generates content.
An agentic AI takes action. It uses tools, makes decisions, and performs
multi-step tasks autonomously."

ASI01: Agent Behavior Hijacking. Total compromise where agent becomes weaponized.
ASI02: Prompt Injection. Crafted inputs manipulate agent behavior.
ASI03: Tool Misuse. Exploiting agent's tool access for unauthorized actions.

---

## MCP Security (Critical Gap — Feb 2026)

Model Context Protocol vulnerabilities dominate 2026 security research:

Attack vectors:
- Tool Poisoning: Malicious instructions hidden in tool descriptions.
- Rug Pull Attacks: Tool definitions change post-approval (Day 1: safe, Day 7: malicious).
- Session Hijacking: Session IDs in URLs expose credentials in logs.
- Cross-service exploitation: Single compromised MCP server accesses multiple tools.

Critical CVEs:
- CVE-2025-6514 (CVSS 9.6): mcp-remote project
- CVE-2025-68143/68144/68145: Anthropic Git MCP server RCE
- CVE-2026-21852 (CVSS 5.3): Claude Code API key exfiltration
- CVE-2025-59536 (CVSS 8.7): Claude Code user consent bypass for MCP servers
- CVE-2026-22708: Cursor IDE RCE via indirect prompt injection

Mitigations: Sandbox MCP servers, pin tool versions, review tool descriptions,
restrict network access, use capability-based security.

---

## Prompt Injection Quantified (Anthropic Feb 2026)

First quantified metrics from Anthropic's Opus 4.6 System Card (212 pages):

| Surface | Single Attempt | 200 Attempts | With Safeguards |
|---------|---------------|--------------|-----------------|
| GUI-based agent | 17.8% success | 78.6% success | 1.4% success |
| Constrained coding | 0% success | 0% success | N/A |

Key insight: "Defenses degrade under sustained attack." Promptfoo red team found
jailbreak success climbs from 4.3% baseline to 78.5% in multi-turn scenarios.

---

## Security Checklist for Every Feature

### Input Layer
- All user input validated at API boundary (type, length, format)
- All user input sanitized for context (HTML, SQL, shell, path)
- File uploads: validate type, size, scan for malware
- Rate limiting on all public endpoints

### Data Layer
- All queries parameterized (no string concatenation)
- Sensitive data encrypted at rest and in transit
- PII handling: minimal collection, access logging, deletion capability
- No secrets in source code (grep for key=, token=, password=, secret=)

### Auth Layer
- Authentication on every endpoint that needs it
- Authorization checked per-request (not cached)
- Session management: secure cookies, expiry, rotation
- No sensitive data in URLs or query parameters

### Output Layer
- Error messages: no stack traces, no internal details in production
- Response headers: CORS configured, security headers set
- No internal IDs, file paths, or infrastructure details exposed

### Dependency Layer
- npm audit / pip-audit / cargo audit before committing
- Lockfile committed (ensures reproducible builds)
- No dependencies added for trivial functionality (<10 lines)
- Check last update date, open security issues, maintainer status
- **NEW 2026**: Dependency cooldown (7-14 days for new packages)
- **NEW 2026**: 230+ malicious packages confirmed in Feb 2026 alone

### MCP/Agent Layer (NEW 2026)
- Sandbox all MCP servers (container isolation or capability-based)
- Review tool descriptions for hidden instructions
- Pin tool versions; verify no post-approval changes
- Tier agents by risk level; higher tiers need more verification
- Scoped and short-lived credentials for agent tool access

---

## KERNEL Integration

- Adversary agent: security testing is phase 5 (after edge cases, before
  contract verification). Check input validation, auth, data exposure, injection.
- Validator agent: secrets scan is phase 1 (first thing checked, blocks commit).
- Invariants in kernel.md: no hardcoded secrets, no irreversible operations
  without confirmation.
- tearitapart: security review is a dedicated phase in architecture assessment.
