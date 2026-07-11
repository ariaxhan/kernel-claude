#!/usr/bin/env python3
"""Project kernel.context-receipt/v1 JSON into AgentDB graph tables (shadow telemetry).

JSON manifests + receipts remain authoritative for resume and policy. This module
only derives observational co-load patterns for advisory suggestions — never auto-loads
context or mutates manifests.

Usage:
  graph-project.py project <receipt.json>
  graph-project.py project-all [--dir _meta/reports]
  graph-project.py outcome-from-checkpoint '<json>'
  graph-project.py suggest <task_type> [--min-sessions N]
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import sqlite3
import sys
from datetime import datetime, timezone
from itertools import combinations
from typing import Any

MIN_SHADOW_SESSIONS = 50
ALWAYS_SKILLS = ("quality", "testing", "git")
SELECTOR_PATH_RE = re.compile(
    r"^\[(?:required|optional|forbidden)\]\s+(.+?)(?:\s+::\s+|\s*:\s*\d|$)"
)


def find_project_root() -> str:
    if os.environ.get("AGENTDB_ROOT"):
        return os.environ["AGENTDB_ROOT"]
    cur = os.getcwd()
    while cur != "/":
        if os.path.isdir(os.path.join(cur, "_meta")) or os.path.isdir(os.path.join(cur, ".claude")):
            return cur
        cur = os.path.dirname(cur)
    return os.getcwd()


def db_path(root: str) -> str:
    return os.path.join(root, "_meta", "agentdb", "agent.db")


def _reject_duplicate_keys(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    seen: dict[str, Any] = {}
    for key, value in pairs:
        if key in seen:
            raise ValueError(f"duplicate key '{key}'")
        seen[key] = value
    return seen


def load_json_file(path: str) -> Any:
    with open(path, encoding="utf-8") as f:
        return json.load(f, object_pairs_hook=_reject_duplicate_keys)


def load_receipt(path: str) -> dict[str, Any]:
    doc = load_json_file(path)
    if not isinstance(doc, dict):
        raise ValueError(f"empty or unparseable receipt: {path}")
    return doc


def load_manifest(path: str) -> dict[str, Any] | None:
    if not path or not os.path.isfile(path):
        return None
    doc = load_json_file(path)
    return doc if isinstance(doc, dict) else None


def skill_path(name: str) -> str:
    return f"skills/{name}/SKILL.md"


def parse_selector_path(selector: str) -> str | None:
    m = SELECTOR_PATH_RE.match(selector.strip())
    if m:
        return m.group(1).strip()
    if "::" in selector:
        return selector.split("::", 1)[0].strip()
    if re.match(r"^[^\s:]+\.[a-zA-Z0-9]+", selector):
        return selector.split(":", 1)[0].strip()
    return None


def infer_task_type(manifest: dict[str, Any] | None, receipt_path: str) -> str:
    if manifest:
        identity = manifest.get("identity") or {}
        name = str(identity.get("name") or "").strip()
        if name:
            return name
        goal = str((manifest.get("objective") or {}).get("goal") or "").lower()
        for keyword in ("bug", "feature", "refactor", "research", "review", "release", "docs"):
            if keyword in goal:
                return keyword
    base = os.path.basename(receipt_path).lower()
    for keyword in ("bug", "feature", "refactor", "research", "review"):
        if keyword in base:
            return keyword
    return "unknown"


def infer_tier(manifest: dict[str, Any] | None) -> int:
    if not manifest:
        return 1
    tier = (manifest.get("identity") or {}).get("tier")
    try:
        return int(tier)
    except (TypeError, ValueError):
        return 1


def classify_node(path: str) -> str:
    if path.startswith("skills/"):
        return "skill"
    if path.startswith("agents/"):
        return "agent"
    if path.startswith("_meta/research/"):
        return "research"
    if path.endswith("CLAUDE.md") or path.endswith("AGENTS.md"):
        return "config"
    return "code"


def collect_nodes(receipt: dict[str, Any], manifest: dict[str, Any] | None) -> dict[str, str]:
    nodes: dict[str, str] = {}

    def add(path: str, ntype: str | None = None) -> None:
        path = path.strip()
        if not path or path.startswith("frontend/*"):
            return
        nodes[path] = ntype or classify_node(path)

    add("CLAUDE.md", "config")

    if manifest:
        ctx = manifest.get("context") or {}
        for group in ("required", "optional"):
            for sel in ctx.get(group) or []:
                if isinstance(sel, dict) and sel.get("path"):
                    add(str(sel["path"]))
        runtime = manifest.get("runtime") or {}
        for entry in runtime.get("required_skills") or []:
            if isinstance(entry, dict) and entry.get("name"):
                add(skill_path(str(entry["name"])), "skill")
            elif isinstance(entry, str):
                add(skill_path(entry), "skill")
        for entry in runtime.get("optional_skills") or []:
            if isinstance(entry, dict) and entry.get("name"):
                add(skill_path(str(entry["name"])), "skill")
            elif isinstance(entry, str):
                add(skill_path(entry), "skill")

    for name in ALWAYS_SKILLS:
        add(skill_path(name), "skill")

    for sel in receipt.get("selections") or []:
        if not isinstance(sel, dict):
            continue
        parsed = parse_selector_path(str(sel.get("selector") or ""))
        if parsed:
            add(parsed)

    for entry in receipt.get("loads_beyond_manifest") or []:
        if isinstance(entry, dict) and entry.get("path"):
            add(str(entry["path"]))

    manifest_ref = str(receipt.get("manifest") or "")
    if manifest_ref:
        add(manifest_ref, "config")

    return nodes


def ensure_graph_tables(conn: sqlite3.Connection) -> None:
    def has_table(name: str) -> bool:
        return (
            conn.execute(
                "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
                (name,),
            ).fetchone()
            is not None
        )

    if not has_table("context_sessions"):
        mig002 = os.path.join(os.path.dirname(__file__), "migrations", "002_graph_tracking.sql")
        if os.path.isfile(mig002):
            conn.executescript(open(mig002, encoding="utf-8").read())

    if not has_table("graph_receipts"):
        conn.execute(
            """
            CREATE TABLE graph_receipts (
              receipt_path TEXT PRIMARY KEY,
              session_id TEXT NOT NULL UNIQUE,
              manifest_path TEXT,
              projected_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
            )
            """
        )
        conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_graph_receipts_session ON graph_receipts(session_id)"
        )


def session_id_for_receipt(receipt_path: str, created: str) -> str:
    digest = hashlib.sha256(f"{receipt_path}:{created}".encode()).hexdigest()[:16]
    return f"RCP-{digest}"


def sql_escape(value: str) -> str:
    return value.replace("'", "''")


def project_receipt(conn: sqlite3.Connection, receipt_path: str) -> str:
    source_receipt = os.path.abspath(receipt_path)
    abs_receipt = os.path.abspath(os.environ.get("KERNEL_RECEIPT_IDENTITY_PATH") or source_receipt)
    receipt = load_receipt(source_receipt)
    if receipt.get("schema") != "kernel.context-receipt/v1":
        raise ValueError(f"not a context receipt: {receipt_path}")

    created = str(receipt.get("created") or datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"))
    session_id = session_id_for_receipt(abs_receipt, created)

    existing = conn.execute(
        "SELECT session_id FROM graph_receipts WHERE receipt_path = ?",
        (abs_receipt,),
    ).fetchone()
    if existing:
        return str(existing[0])

    manifest_path = str(receipt.get("manifest") or "")
    manifest = load_manifest(manifest_path)
    task_type = infer_task_type(manifest, abs_receipt)
    tier = infer_tier(manifest)
    node_map = collect_nodes(receipt, manifest)
    nodes_json = json.dumps(sorted(node_map.keys()))
    tokens = int(receipt.get("total_estimated_tokens") or 0)
    outcome = json.dumps(
        {
            "receipt": abs_receipt,
            "manifest": manifest_path,
            "status": receipt.get("status"),
            "projected_by": "graph-project",
        }
    )

    conn.execute(
        """
        INSERT INTO context_sessions (id, started_at, task_type, tier, nodes_loaded, tokens_used, outcome)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        (session_id, created, task_type, tier, nodes_json, tokens, outcome),
    )

    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%fZ")
    for path, ntype in node_map.items():
        conn.execute(
            """
            INSERT INTO nodes (path, type, tokens, last_accessed, access_count)
            VALUES (?, ?, 0, ?, 1)
            ON CONFLICT(path) DO UPDATE SET
              last_accessed = excluded.last_accessed,
              access_count = access_count + 1
            """,
            (path, ntype, now),
        )

    node_paths = sorted(node_map.keys())
    for a, b in combinations(node_paths, 2):
        for src, dst in ((a, b), (b, a)):
            conn.execute(
                """
                INSERT INTO edges (source_path, target_path, relation, weight, last_observed)
                VALUES (?, ?, 'loads', 1, ?)
                ON CONFLICT(source_path, target_path, relation) DO UPDATE SET
                  weight = weight + 1,
                  last_observed = excluded.last_observed
                """,
                (src, dst, now),
            )

    conn.execute(
        """
        INSERT INTO graph_receipts (receipt_path, session_id, manifest_path)
        VALUES (?, ?, ?)
        """,
        (abs_receipt, session_id, manifest_path or None),
    )
    conn.commit()
    return session_id


def project_all(root: str, directory: str) -> int:
    count = 0
    if not os.path.isdir(directory):
        return 0
    for name in sorted(os.listdir(directory)):
        if not name.startswith("receipt") or not name.endswith(".json"):
            continue
        path = os.path.join(directory, name)
        try:
            with sqlite3.connect(db_path(root)) as conn:
                ensure_graph_tables(conn)
                project_receipt(conn, path)
            count += 1
        except Exception as exc:  # noqa: BLE001 — best-effort batch ingest
            print(f"graph-project: skip {path}: {exc}", file=sys.stderr)
    return count


def outcome_from_checkpoint(conn: sqlite3.Connection, payload: str) -> int:
    try:
        data = json.loads(payload)
    except json.JSONDecodeError:
        return 0
    if not isinstance(data, dict):
        return 0

    blocked = str(data.get("blocked") or "").strip()
    did = str(data.get("did") or "").strip()
    success = 1 if did and not blocked else 0

    row = conn.execute(
        """
        SELECT id, nodes_loaded FROM context_sessions
        WHERE success IS NULL
        ORDER BY started_at DESC
        LIMIT 1
        """
    ).fetchone()
    if not row:
        return 0

    session_id, nodes_loaded_raw = row[0], row[1]
    conn.execute(
        """
        UPDATE context_sessions
        SET ended_at = strftime('%Y-%m-%dT%H:%M:%fZ','now'), success = ?
        WHERE id = ?
        """,
        (success, session_id),
    )

    try:
        node_paths = json.loads(nodes_loaded_raw or "[]")
    except json.JSONDecodeError:
        node_paths = []

    for path in node_paths:
        conn.execute(
            """
            UPDATE nodes
            SET avg_success_rate = CASE
              WHEN access_count <= 1 THEN ?
              ELSE (avg_success_rate * (access_count - 1) + ?) / access_count
            END
            WHERE path = ?
            """,
            (float(success), float(success), path),
        )

    conn.commit()
    return 1


def suggest(conn: sqlite3.Connection, task_type: str, min_sessions: int) -> int:
    total = conn.execute("SELECT COUNT(*) FROM context_sessions").fetchone()[0]
    scoped = conn.execute(
        "SELECT COUNT(*) FROM context_sessions WHERE task_type = ?",
        (task_type,),
    ).fetchone()[0]

    print("## Context graph suggestions (shadow mode — advisory only)")
    print(f"Task type: {task_type}")
    print(f"Telemetry: {scoped} scoped session(s), {total} total (need {min_sessions}+ before auto-load is considered)")
    print("JSON manifests remain authoritative. These suggestions never change ingest behavior.")
    print("")

    if scoped == 0 and task_type != "unknown":
        scoped = conn.execute(
            "SELECT COUNT(*) FROM context_sessions WHERE task_type = 'unknown'"
        ).fetchone()[0]
        if scoped:
            print(f"(No sessions tagged '{task_type}'; showing global patterns from {scoped} untagged session(s).)")
            print("")

    if total < min_sessions:
        print(f"Insufficient telemetry for confident suggestions ({total}/{min_sessions}).")
        print("Keep using manifest selectors; graph will accumulate from receipts automatically.")
        print("")

    rows = conn.execute(
        """
        SELECT n.path, n.type, n.access_count, n.avg_success_rate
        FROM nodes n
        WHERE n.access_count >= 1
        ORDER BY n.access_count DESC, n.path ASC
        LIMIT 10
        """
    ).fetchall()

    if rows:
        print("Frequently observed context nodes:")
        for path, ntype, access_count, avg_success_rate in rows:
            rate = "n/a" if avg_success_rate is None or avg_success_rate == 0 else f"{avg_success_rate:.2f}"
            print(f"  - {path} ({ntype}, seen {access_count}x, success-rate {rate})")
        print("")

    combos = conn.execute(
        """
        SELECT e.source_path, e.target_path, e.weight
        FROM edges e
        WHERE e.relation = 'loads'
        ORDER BY e.weight DESC, e.source_path ASC
        LIMIT 8
        """
    ).fetchall()

    if combos:
        print("Common co-load pairs (manual manifest review only):")
        seen: set[tuple[str, str]] = set()
        for src, dst, weight in combos:
            key = tuple(sorted((src, dst)))
            if key in seen:
                continue
            seen.add(key)
            print(f"  - {key[0]} + {key[1]} ({weight} co-loads)")
        print("")

    if not rows and not combos:
        print("No graph telemetry yet. Project receipts via ingest deactivate or `agentdb graph-project`.")
        return 0
    return 0


def main(argv: list[str]) -> int:
    if len(argv) < 2 or argv[1] in ("-h", "--help", "help"):
        print(__doc__)
        return 0

    root = find_project_root()
    db = db_path(root)
    if not os.path.isfile(db):
        print("graph-project: no AgentDB (run agentdb init)", file=sys.stderr)
        return 1

    cmd = argv[1]
    args = argv[2:]

    with sqlite3.connect(db) as conn:
        ensure_graph_tables(conn)

        if cmd == "project":
            if not args:
                print("usage: graph-project.py project <receipt.json>", file=sys.stderr)
                return 1
            session_id = project_receipt(conn, args[0])
            print(f"projected {args[0]} -> {session_id}")
            return 0

        if cmd == "project-all":
            directory = os.path.join(root, "_meta", "reports")
            idx = 0
            while idx < len(args):
                if args[idx] == "--dir" and idx + 1 < len(args):
                    directory = args[idx + 1]
                    if not os.path.isabs(directory):
                        directory = os.path.join(root, directory)
                    idx += 2
                else:
                    idx += 1
            count = project_all(root, directory)
            print(f"projected {count} receipt(s) from {directory}")
            return 0

        if cmd == "outcome-from-checkpoint":
            if not args:
                print("usage: graph-project.py outcome-from-checkpoint '<json>'", file=sys.stderr)
                return 1
            updated = outcome_from_checkpoint(conn, args[0])
            print("outcome recorded" if updated else "no open graph session to update")
            return 0

        if cmd == "suggest":
            if not args:
                print("usage: graph-project.py suggest <task_type> [--min-sessions N]", file=sys.stderr)
                return 1
            task_type = args[0]
            min_sessions = MIN_SHADOW_SESSIONS
            idx = 1
            while idx < len(args):
                if args[idx] == "--min-sessions" and idx + 1 < len(args):
                    min_sessions = int(args[idx + 1])
                    idx += 2
                else:
                    idx += 1
            return suggest(conn, task_type, min_sessions)

    print(f"unknown subcommand: {cmd}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
