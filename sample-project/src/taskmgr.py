#!/usr/bin/env python3
"""
TaskMgr - A simple task management CLI
"""
import json
import sys
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Optional


class TaskManager:
    def __init__(self, db_path: str = "tasks.json"):
        self.db_path = Path(db_path)
        self.tasks: List[Dict] = self._load_tasks()

    def _load_tasks(self) -> List[Dict]:
        """Load tasks from JSON file"""
        if self.db_path.exists():
            with open(self.db_path, 'r') as f:
                return json.load(f)
        return []

    def _save_tasks(self):
        """Save tasks to JSON file"""
        with open(self.db_path, 'w') as f:
            json.dump(self.tasks, f, indent=2)

    def add_task(self, title: str, priority: str = "medium", due_date: Optional[str] = None):
        """Add a new task"""
        task = {
            "id": len(self.tasks) + 1,
            "title": title,
            "priority": priority,
            "due_date": due_date,
            "completed": False,
            "created_at": datetime.now().isoformat()
        }
        self.tasks.append(task)
        self._save_tasks()
        print(f"Task added: {title}")

    def list_tasks(self, show_completed: bool = False):
        """List all tasks"""
        filtered = self.tasks if show_completed else [t for t in self.tasks if not t['completed']]

        if not filtered:
            print("No tasks found.")
            return

        for task in filtered:
            status = "✓" if task['completed'] else "○"
            priority_icon = {"high": "🔴", "medium": "🟡", "low": "🟢"}.get(task['priority'], "⚪")
            due = f" (due: {task['due_date']})" if task.get('due_date') else ""
            print(f"{status} [{task['id']}] {priority_icon} {task['title']}{due}")

    def complete_task(self, task_id: int):
        """Mark a task as completed"""
        for task in self.tasks:
            if task['id'] == task_id:
                task['completed'] = True
                task['completed_at'] = datetime.now().isoformat()
                self._save_tasks()
                print(f"Task {task_id} completed!")
                return
        print(f"Task {task_id} not found.")

    def delete_task(self, task_id: int):
        """Delete a task"""
        self.tasks = [t for t in self.tasks if t['id'] != task_id]
        self._save_tasks()
        print(f"Task {task_id} deleted.")

    def stats(self):
        """Show task statistics"""
        total = len(self.tasks)
        completed = len([t for t in self.tasks if t['completed']])
        pending = total - completed

        print(f"\n📊 Task Statistics:")
        print(f"   Total: {total}")
        print(f"   Completed: {completed}")
        print(f"   Pending: {pending}")

        if total > 0:
            print(f"   Completion rate: {(completed/total)*100:.1f}%")


def main():
    """Main CLI interface"""
    if len(sys.argv) < 2:
        print("Usage: taskmgr.py [add|list|complete|delete|stats] [args...]")
        sys.exit(1)

    tm = TaskManager()
    command = sys.argv[1]

    if command == "add":
        if len(sys.argv) < 3:
            print("Usage: taskmgr.py add <title> [priority] [due_date]")
            sys.exit(1)
        title = sys.argv[2]
        priority = sys.argv[3] if len(sys.argv) > 3 else "medium"
        due_date = sys.argv[4] if len(sys.argv) > 4 else None
        tm.add_task(title, priority, due_date)

    elif command == "list":
        show_completed = "--all" in sys.argv
        tm.list_tasks(show_completed)

    elif command == "complete":
        if len(sys.argv) < 3:
            print("Usage: taskmgr.py complete <task_id>")
            sys.exit(1)
        tm.complete_task(int(sys.argv[2]))

    elif command == "delete":
        if len(sys.argv) < 3:
            print("Usage: taskmgr.py delete <task_id>")
            sys.exit(1)
        tm.delete_task(int(sys.argv[2]))

    elif command == "stats":
        tm.stats()

    else:
        print(f"Unknown command: {command}")
        sys.exit(1)


if __name__ == "__main__":
    main()
