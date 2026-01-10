---
description: Export tasks to various formats
allowed-tools: Read, Write, Bash
---

Export tasks from tasks.json to the requested format:

1. Read tasks.json
2. Ask user which format: CSV, Markdown, or JSON (pretty)
3. Generate the export file with appropriate filename (tasks_export_YYYY-MM-DD.{ext})
4. Include all task fields: id, title, priority, due_date, completed, timestamps
5. Confirm export location and record count

Default to CSV if not specified.
