---
description: Optimize task database by reindexing
allowed-tools: Read, Write, Bash
---

Optimize the tasks.json database:

1. Read the current tasks.json file
2. Reindex all task IDs sequentially (1, 2, 3, ...) to remove gaps
3. Update any references to maintain data integrity
4. Write the optimized database back
5. Report statistics: tasks before/after, gaps removed, file size change

Be concise and show before/after stats.
