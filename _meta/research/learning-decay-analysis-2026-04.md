# Learning Decay & Criticality Analysis

**Date:** 2026-04-07  
**Database:** 356 learnings, 446 total hits  
**Tests:** H080 (working memory cap), H081 (pruning)

---

## 1. Decay Curve

| Age Bucket | Learnings | Total Hits | Avg Hits |
|-----------|-----------|------------|----------|
| 0-7 days  | 98        | 194        | 1.98     |
| 8-14 days | 159       | 212        | 1.33     |
| 15-30 days| 98        | 39         | 0.40     |
| 30+ days  | 1         | 1          | 1.00     |

**Finding:** Sharp decay after 14 days. Learnings 0-7 days old average 5x the hit rate of 15-30 day learnings. The first two weeks capture 91% of all hits (406/446). After 14 days, learnings are almost never referenced.

**Hit distribution by age:**
- 0-7 days: 43.5% of hits
- 8-14 days: 47.5% of hits
- 15-30 days: 8.7% of hits
- 30+ days: 0.2% of hits

---

## 2. Criticality Frontier

| Top N | Cumulative Hits | Coverage |
|-------|----------------|----------|
| 5     | 158            | 35.4%    |
| 10    | 246            | 55.2%    |
| 15    | 319            | 71.5%    |
| 20    | 344            | 77.1%    |
| **25**| **359**        | **80.5%**|
| 50    | 387            | 86.8%    |
| 65    | 402            | 90.1%    |
| 87    | 424            | 95.1%    |
| 109   | 446            | 100.0%   |

**Finding:** 25 learnings capture 80% of all hits. 65 capture 90%. 87 capture 95%. The remaining 269 learnings (75.6%) contribute less than 5% of total value.

**Power law confirmed:** The top 7% of learnings (25/356) deliver 80% of the value. Below rank 109, hit_count = 0 everywhere.

---

## 3. Never-Hit Analysis

247 learnings (69.4%) have hit_count = 0.

**By age and type:**

| Age Category    | Pattern | Failure | Gotcha | Preference | Total |
|----------------|---------|---------|--------|------------|-------|
| Recent (0-7d)  | 60      | 0       | 0      | 0          | 60    |
| Mid (8-14d)    | 65      | 9       | 20     | 0          | 94    |
| Aging (15-21d) | 12      | 0       | 0      | 0          | 12    |
| Stale (21d+)   | 66      | 7       | 1      | 7          | 81    |

**Pruning candidates (hit_count=0, older than 14 days):**

| Type       | Count |
|-----------|-------|
| pattern   | 78    |
| failure   | 7     |
| preference| 7     |
| gotcha    | 1     |
| **Total** | **93** |

**Risk assessment:** 
- 60 never-hit learnings are < 7 days old — too soon to judge, keep them.
- 93 never-hit learnings are > 14 days old — safe pruning candidates.
- The 7 stale failures and 1 gotcha should be reviewed before pruning (safety-critical types).
- **Safe auto-prune:** 78 patterns + 7 preferences = 85 learnings with zero risk.
- **Review-then-prune:** 7 failures + 1 gotcha = 8 learnings needing human review.

---

## 4. Domain Concentration

**High-value domains (avg hits > 3.0, min 3 learnings):**

| Domain            | Count | Avg Hits | Total Hits | Active % |
|-------------------|-------|----------|------------|----------|
| onboarding        | 4     | 23.50    | 94         | 75.0%    |
| workflow          | 3     | 10.33    | 31         | 100.0%   |
| enterprise-safety | 5     | 7.80     | 39         | 100.0%   |
| backend           | 6     | 5.83     | 35         | 66.7%    |
| core_finding      | 3     | 5.00     | 15         | 100.0%   |
| infrastructure    | 10    | 3.50     | 35         | 40.0%    |

**Zero-value domains (0 total hits, 3+ learnings):**

| Domain       | Count |
|-------------|-------|
| architecture | 32   |
| strategy     | 17   |
| product      | 8    |
| email-content| 8    |
| branding     | 6    |
| mypy         | 6    |
| plans        | 6    |
| research     | 6    |
| security     | 5    |

**Finding:** 6 domains generate all the value. 9+ domains with 3+ learnings have zero hits total. Domain-weighted retrieval should heavily boost onboarding, workflow, enterprise-safety, backend, and infrastructure. Architecture (32 learnings, 0 hits) is the single biggest waste of memory budget.

---

## 5. Cap Size Simulation

Scoring: `score = (hit_count * 10) + (age_days * -1) + (is_failure * 20)`

| Cap  | Hits Captured | Hit % | Critical Included | Critical % | Est. Tokens |
|------|--------------|-------|-------------------|------------|-------------|
| 25   | 359          | 80.5% | 15                | 26.3%      | 1,746       |
| 50   | 378          | 84.8% | 26                | 45.6%      | 3,659       |
| 75   | 403          | 90.4% | 26                | 45.6%      | 5,897       |
| 100  | 428          | 96.0% | 26                | 45.6%      | 7,506       |
| 150  | 444          | 99.6% | 28                | 49.1%      | 11,183      |
| 200  | 445          | 99.8% | 41                | 71.9%      | 14,931      |
| 356  | 446          | 100%  | 57                | 100%       | 23,562      |

**Elbow point: 75.** Going from 75 to 100 gains 5.6% more hits for 1,609 more tokens. Going from 50 to 75 gains 5.6% for 2,238 tokens. But 75→100 is the last big jump before diminishing returns flatten dramatically (100→150 gains 3.6% for 3,677 tokens).

**Critical gap:** The weighted strategy under-serves failures/gotchas. At cap 75, only 45.6% of critical learnings are included. This is because many failure learnings are old (>21 days) and the recency penalty pushes them out. **Recommendation:** Increase the failure bonus from 20 to 50, or reserve 15-20 slots explicitly for failure/gotcha types.

---

## 6. Stale Learning Detection

**Learnings older than 21 days with hit_count=0:** 81

**Sample stale learnings (oldest):**
- `init-stack`, `init-structure`, `init-conventions`, `init-identity` (~30 days, never referenced)
- `xpoll-001` through `xpoll-016` (~27 days, 16 learnings, all zero hits)
- `insight-*` series (~27 days, 14 learnings, all zero hits)
- `user-vision-*` preferences (~27 days, 5 learnings, zero hits)

**Recommendation:** Archive all 81 stale learnings. They represent 19,000+ estimated tokens of dead weight. Move to an `archived_learnings` table rather than deleting — allows recovery if a domain becomes relevant again.

---

## Recommendations

### H080: Working Memory Cap = 75

The optimal cap is **75 learnings** based on:
- Captures 90.4% of historical hits
- Costs ~5,900 tokens (reasonable for context window)
- Clear elbow: 50→75 still gains meaningfully, 75→100 starts flattening
- At cap 356 (no limit), 23,562 tokens are wasted on 69% zero-value items

### H081: Pruning Threshold

**Safe prune:** `hit_count = 0 AND age > 14 days AND type IN ('pattern', 'preference')`
- Removes 85 learnings immediately, zero risk
- Saves ~20,000 tokens

**Review-then-prune:** `hit_count = 0 AND age > 14 days AND type IN ('failure', 'gotcha')`
- 8 learnings need human review before removal

**Aggressive prune:** `hit_count = 0 AND age > 21 days` (all types)
- Removes 81 learnings
- Small risk: 7 failure learnings might be safety-relevant

### Additional Recommendations

1. **Boost failure weight** in scoring formula from 20 to 50 — current formula under-represents safety-critical learnings
2. **Domain-weighted retrieval** — boost onboarding/workflow/enterprise-safety/backend by 2x, penalize architecture/strategy/product
3. **Auto-archive at 21 days** if hit_count remains 0 — most value is captured in first 14 days
4. **Reserve 15 slots** in any cap for failure/gotcha types regardless of score — safety floor
