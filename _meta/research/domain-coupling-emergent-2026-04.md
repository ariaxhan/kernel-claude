# Domain Coupling & Emergent Pattern Analysis

**Date:** 2026-04-07  
**Data:** 356 learnings, 2726 events, 68 errors, 89 hypotheses, 151 experiments

---

## 1. Domain Co-occurrence Matrix

Co-occurrence measured by domains appearing on the same calendar day (threshold: 2+ co-occurrences).

**Strongest clusters:**

| Cluster | Domains | Co-occurrences |
|---------|---------|---------------|
| System Design | architecture + product, architecture + security, architecture + strategy | 2 each |
| Full-Stack | backend + frontend, backend + infrastructure, backend + compliance | 2 each |
| Onboarding Bundle | compliance + onboarding, frontend + onboarding, infrastructure + onboarding, backend + onboarding | 2 each |
| Discovery Sessions | process + product + research + testing + deployment | 2 each (all pairs) |

**Interpretation:** Two natural loading groups emerge:
1. **Build days** load: backend, frontend, infrastructure, compliance, onboarding (5-domain bundle)
2. **Strategy days** load: architecture, product, security, strategy, research, testing, deployment, process (8-domain bundle)

The onboarding domain co-occurs with 4 other domains every time it appears -- it never appears in isolation. This suggests onboarding is a compound domain that should trigger multi-domain context loading.

---

## 2. Session Fingerprinting

12 active days segmented by event/learning/error ratios:

| Type | Days | Characteristics |
|------|------|----------------|
| **PRODUCTIVE** | Mar 25, 26, 30, Apr 4, 6 | High learning (14-70/day), low errors (0-1). Multi-domain exploration. |
| **STRUGGLING** | Mar 31, Apr 7 | High errors (17-33), low learning (0-3). Hook-heavy (673-1000 events). |
| **NORMAL** | Mar 29, Apr 1, 2, 8 | Mixed signals. Apr 1 is mislabeled -- 47 learnings + 7 errors should be "productive-with-friction". |

**Key finding:** STRUGGLING days correlate with high guard-bash hook fires (1000 events on Apr 7, 673 on Mar 31). These are hook-spinning sessions where the safety infrastructure itself becomes the bottleneck.

**Learning rate:**
- Best day: Mar 26 -- 70 learnings across 17 domains (research/discovery session)
- Worst active day: Apr 7 -- 3 learnings, 33 errors, 1000 hook events

---

## 3. Error-to-Learning Pipeline

| Metric | Value |
|--------|-------|
| Total errors | 68 |
| Errors with ANY learning within 24h | 68 (100%) |
| Errors with SAME-DOMAIN learning within 24h | 0 (0%) |

**Critical finding:** 100% of errors have temporally-adjacent learnings, but 0% have domain-matched learnings. The error `tool` field (Bash: 48, unknown: 20) does not map to learning domains. **Errors and learnings are tracked in completely disconnected taxonomies.** There is no causal link between errors encountered and lessons captured.

This means kernel cannot answer: "Did we learn from error X?" The pipeline is broken at the classification level.

---

## 4. Hook Efficiency

| Metric | Value |
|--------|-------|
| Total guard-bash events | 1888 |
| Total detect-secrets events | 316 |
| Sessions with >200 guard-bash fires | 3 (sess 11, 22, 21) |
| Worst session | sess 22: 349 guard-bash in 0.7 hours = **498/hour** |

**Guard-bash dominance:** 86% of all hook events are guard-bash. The ratio is consistent (60-97% per session), suggesting this is structural overhead, not anomaly detection.

**Spinning detection:** Sessions 21 and 22 (both Apr 7) fired 228 and 349 guard-bash events respectively in under 1 hour each. Combined with 33 errors that day, this points to a feedback loop: hooks fire on every bash invocation during debugging, creating noise that drowns signal.

---

## 5. Hypothesis Ecosystem Map

| Domain | Total | Graduated | Refuted | Testing | Avg Conf | Learning Evidence |
|--------|-------|-----------|---------|---------|----------|-------------------|
| methodology | 23 | 4 | 1 | 17 | 0.3 | 3 learnings |
| coordination | 14 | 2 | 3 | 7 | 0.2 | 0 learnings |
| architecture | 11 | 0 | 0 | 10 | 0.3 | 32 learnings |
| quality | 10 | 1 | 0 | 9 | 0.3 | 1 learning |
| git | 7 | 3 | 0 | 4 | 0.5 | 0 learnings |
| testing | 7 | 2 | 0 | 5 | 0.4 | 4 learnings |
| performance | 5 | 0 | 0 | 4 | 0.2 | 0 learnings |
| security | 5 | 2 | 1 | 2 | 0.4 | 5 learnings |
| style | 3 | 0 | 0 | 3 | 0.3 | 0 learnings |
| tooling | 3 | 0 | 0 | 0 | 0.5 | 0 learnings |
| design | 1 | 0 | 0 | 1 | 0.3 | 1 learning |

### Over-indexed (many hypotheses, few learnings)
- **coordination**: 14 hypotheses, 0 learnings. Pure theory, no empirical grounding.
- **methodology**: 23 hypotheses, 3 learnings. Heavily theorized, barely observed.
- **git**: 7 hypotheses, 0 learnings. All graduated on axiom, not evidence.

### Under-indexed (many learnings, no hypotheses)
- **strategy**: 17 learnings, 0 hypotheses
- **infrastructure**: 10 learnings, 0 hypotheses
- **team**: 9 learnings, 0 hypotheses
- **product**: 8 learnings, 0 hypotheses
- **backend**: 6 learnings, 0 hypotheses
- **research**: 6 learnings, 0 hypotheses
- **observability**: 4 learnings, 0 hypotheses

**The biggest gap:** The system has extensive real-world observations about strategy, infrastructure, team dynamics, and product patterns -- but zero hypotheses testing any of them. Meanwhile, methodology and coordination are over-theorized with minimal empirical backing.

---

## 6. Emergent: Cross-Hypothesis Interactions

### Graduated Hypothesis Clusters

The 14 graduated hypotheses form 3 reinforcing clusters:

**Cluster A: Research-Before-Code (methodology)**
- H003: Research anti-patterns first
- H005: Knowledge mining saves time
- H006: Most SWE is solved problems
- H007: Define acceptance criteria first

These 4 form a complete pre-implementation protocol. They reinforce each other but have a gap: none addresses *when research becomes diminishing returns*.

**Cluster B: Safety Infrastructure (security + testing + git)**
- H022: Regression tests for every fix
- H023: Tests pass before merge
- H029: Atomic commits
- H031: Commit every working state
- H033: Feature branches for tier 2+
- H035: No hardcoded secrets
- H037: Fallback-first safety

7 graduated hypotheses that collectively describe a "never ship broken code" philosophy. Self-consistent and well-supported.

**Cluster C: Coordination (coordination)**
- H017: Cheap pre-flight validation
- H020: Each agent owns its own PR

Only 2 graduated, but 3 refuted (H015, H016, H074) in the same domain. The refuted hypotheses all assumed parallelism is always faster. The survivors are more nuanced.

### Refuted Hypothesis Patterns

All 5 refuted hypotheses share a pattern: **they assume a simple more-is-better relationship**.
- H015: More parallelism = more throughput (refuted: merge conflicts)
- H016: Always parallelize (refuted: shared files)
- H070: More scanning = more security (refuted: overhead)
- H074: Lighter loops = faster (refuted: forge has value)
- H077: More phases = better quality (refuted: overhead for familiar codebases)

**Meta-pattern:** Kernel's refuted hypotheses are all "scaling" hypotheses -- the belief that linearly increasing a good thing (parallelism, scanning, phases) yields linear improvement. Reality shows diminishing or negative returns.

### Emergent Hypotheses (Not Yet Captured)

**EH-1: Hook Overhead Dominance**
Guard-bash events constitute 86% of all recorded events. On struggling days, hook fires exceed 500/hour. No hypothesis tests whether this overhead is worth the safety benefit. Proposed: "Guard-bash hooks have a break-even point beyond which their overhead exceeds their safety value."

**EH-2: Error Taxonomy Disconnect**
Errors are classified by tool (Bash/unknown). Learnings are classified by domain (architecture/strategy/etc). No hypothesis addresses whether these taxonomies should be aligned. Proposed: "Errors classified by domain (not tool) would enable causal error-to-learning pipelines."

**EH-3: Observation-Theory Inversion**
The most-observed domains (strategy: 17, infrastructure: 10, team: 9, product: 8) have zero hypotheses. The most-theorized domains (methodology: 23H, coordination: 14H) have near-zero observations. Proposed: "Hypothesis generation should be proportional to empirical observation density, not theoretical interest."

**EH-4: Compound Domain Loading**
Onboarding never appears without backend, frontend, infrastructure, and compliance. Proposed: "Compound domains (onboarding, deployment) should trigger automatic co-loading of their empirically coupled domains."

**EH-5: Session Type Predicts Learning Rate**
Productive days average 35 learnings. Struggling days average 1.5. The difference is not effort -- struggling days have MORE events. Proposed: "High hook-fire rates suppress learning capture, creating an inverse relationship between safety infrastructure activity and knowledge acquisition."

---

## Summary

### Domain Coupling Map
Two natural clusters: **build** (backend/frontend/infrastructure/compliance/onboarding) and **strategy** (architecture/product/security/strategy/research). Onboarding is the strongest compound domain, never appearing alone.

### Session Types
5 productive days, 2 struggling days, 5 normal. Struggling days are defined by hook spinning (500+ guard-bash/hour) and error accumulation, not by lack of activity.

### Biggest Gap
**The hypothesis set is inverted from the evidence.** 23 methodology hypotheses built on 3 observations. 0 strategy hypotheses despite 17 observations. The system theorizes about process but observes product/infrastructure/strategy. These worlds need to meet.

### Emergent Hypotheses
5 new hypotheses discovered. The most actionable: hook overhead may suppress learning (EH-5), and error/learning taxonomies are disconnected making "learn from failure" unmeasurable (EH-2).
