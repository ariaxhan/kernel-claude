# Performance Reference: Research & Best Practices

Reference for when and how to optimize. Read on demand. Not auto-loaded.

## Sources

Donald Knuth, Rob Pike (5 rules), CodeScene code health, Chrome DevTools 2026,
Core Web Vitals (INP) 2026, Bun runtime benchmarks (Jan 2026), Edge computing
research (Cloudflare Workers, Vercel Edge), React 19 performance features,
Vite/Rolldown build tooling.

---

## The Cardinal Rule

Knuth: "We should forget about small efficiencies, say about 97% of the
time: premature optimization is the root of all evil."

Rob Pike's Rule 1: "You can't tell where a program is going to spend its
time. Bottlenecks occur in surprising places, so don't try to second guess
and put in a speed hack until you've proven that's where the bottleneck is."

Rule 2: "Measure. Don't tune for speed until you've measured, and even then
don't unless one part of the code overwhelms the rest."

---

## When to Optimize (Decision Framework)

1. Is there a measured bottleneck? (Not assumed. Measured.)
   No → don't optimize.
2. Does the bottleneck affect user experience or cost?
   No → don't optimize.
3. Is the fix simple (O(1) → O(1), just better constant)?
   Yes → do it. It's not optimization, it's correctness.
4. Does optimization increase code complexity?
   Yes → document why. Complexity must earn its place.

---

## INP (Interaction to Next Paint) — Primary Responsiveness Metric (2026)

INP replaced FID in March 2024 as Core Web Vital. **43% of sites fail** the
200ms INP threshold (most commonly failed metric in 2026).

Three phases: Input Delay + Processing Time + Presentation Delay.

Thresholds: Good < 200ms, Needs improvement 200-500ms, Poor > 500ms.

Fixes:
- `scheduler.yield()`: New browser API for breaking long tasks.
- `useTransition`, `useDeferredValue` in React for non-urgent updates.
- Long Animation Frames (LoAF) API: "Gold standard" for INP debugging.

---

## Common Performance Problems (Ranked by Frequency)

1. N+1 queries: loading a list, then querying each item individually.
   Fix: JOIN, batch query, eager loading.
   **2026**: Use keyset pagination (WHERE id > last_id) over OFFSET.

2. Unbounded data fetches: SELECT * without LIMIT/pagination.
   Fix: always paginate. Always limit. Always stream large results.

3. Missing indexes: queries scan full tables.
   Fix: index columns used in WHERE, JOIN, ORDER BY.
   **2026**: Consider functional indexes for queries using functions on columns.

4. Synchronous blocking: awaiting responses sequentially when they
   could run in parallel. Fix: Promise.all / asyncio.gather.

5. Excessive re-renders (frontend): component re-renders on every
   state change. Fix: memoization, proper key usage, state lifting.
   **React 19**: React Compiler eliminates manual memoization.

6. Large bundle sizes: importing entire libraries for one function.
   Fix: tree-shaking, dynamic imports, replace with native code.
   **2026**: Rolldown coming to unify Vite dev/build experience.

7. Memory leaks: event listeners not cleaned up, closures holding
   references, caches without eviction. Fix: cleanup on unmount,
   WeakRef/WeakMap, bounded caches.

8. Expensive operations in loops: regex compilation, object creation,
   API calls inside iteration. Fix: hoist out of loop, batch.

---

## Profiling Before Optimizing

Never optimize without profiling. The bottleneck is never where you think.

JavaScript: Chrome DevTools Performance tab, Lighthouse.
**2026 Chrome additions**:
- Live Metrics: Real-time Core Web Vitals without recording a profile.
- AI-Powered Insights: Automatic analysis and actionable recommendations.
- Long Animation Frames (LoAF) API for INP debugging.

Python: cProfile, py-spy, line_profiler.
Node.js: --prof flag, clinic.js.
**Bun** (2026): Built-in profiler, 3.7x faster than Node.js, sub-15ms cold starts.

Database: EXPLAIN ANALYZE on slow queries. Set 200ms slow query logging threshold.
General: measure wall-clock time of each phase. Largest phase wins.

---

## Edge Computing (2026)

Cloudflare Workers: 300+ locations, 10-30ms P50 latency globally.
V8 isolates: Sub-1ms cold starts (vs Lambda 100-1000ms).
Vercel Fluid Compute: 2.55x faster for certain workloads.

Design edge-first from start, not as optimization afterthought.

---

## Bun Runtime (2026)

**52,000 req/sec** vs Node.js 14,000 req/sec (3.7x faster).
Cold starts: 8-15ms (vs Node.js 60-120ms).
CPU tasks: 1.7s vs Node.js 3.4s (2x faster).
95%+ Node.js compatibility. Package installation 10x faster than npm.

---

## KERNEL Integration

- Performance is LAST in build skill evaluation criteria. Make it work,
  make it right, THEN make it fast.
- tearitapart: scale test phase asks what happens at 10x/100x/1000x.
  That's the right time to surface performance concerns.
- Only create a performance contract when: measured bottleneck exists,
  user reports slowness, or scale test reveals degradation.
