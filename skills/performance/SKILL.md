---
name: performance
description: "Performance optimization and profiling. Measure before optimizing, identify bottlenecks, avoid premature optimization. Triggers: performance, speed, slow, optimize, latency, throughput, profiling, benchmark."
allowed-tools: Bash, Read, Grep
---

<skill id="performance">

<purpose>
Measure first. Optimize second. Never guess where the bottleneck is.
Premature optimization is the root of all evil—but so is ignoring real problems.
Performance is a feature. Latency is a bug.
</purpose>

<prerequisite>
Have benchmarks or profiling data before making performance changes.
If no data exists, create minimal reproduction to measure.
</prerequisite>

<reference>
Skill-specific: skills/performance/reference/performance-research.md
</reference>

<core_principles>
1. MEASURE FIRST: Profile before optimizing. Data beats intuition.
2. IDENTIFY BOTTLENECK: Fix the slowest part first. Amdahl's Law applies.
3. ONE CHANGE AT A TIME: Measure after each change. Verify improvement.
4. REGRESSION TESTS: Performance tests prevent future degradation.
5. GOOD ENOUGH: Stop when requirements are met. Don't gold-plate.
</core_principles>

<profiling_checklist>
Before optimizing:
- [ ] Have reproduction case
- [ ] Baseline measurement documented
- [ ] Target performance defined
- [ ] Profiler identified hotspots

After optimizing:
- [ ] New measurement taken
- [ ] Improvement verified
- [ ] No functionality regression
- [ ] Performance test added
</profiling_checklist>

<common_bottlenecks>
- N+1 queries (fetch in loop instead of batch)
- Missing indexes on frequently queried columns
- Synchronous I/O in hot paths
- Excessive serialization/deserialization
- Memory allocations in tight loops
- Blocking operations in async code
</common_bottlenecks>

<anti_patterns>
- Optimizing without profiling data
- Micro-optimizing code that runs once
- Caching everything (cache invalidation is hard)
- Async for CPU-bound work
- Premature parallelization
</anti_patterns>

</skill>
