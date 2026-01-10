# TaskMgr - Task Management CLI

A simple command-line task manager with JSON storage.

## Features

- Add, list, complete, and delete tasks
- Priority levels (high, medium, low)
- Due dates
- Statistics and completion tracking

## Usage

```bash
python src/taskmgr.py add "Buy groceries" high 2026-01-15
python src/taskmgr.py list
python src/taskmgr.py complete 1
python src/taskmgr.py stats
```

## KERNEL Integration

This project uses KERNEL to progressively build Claude Code configuration based on observed patterns.
