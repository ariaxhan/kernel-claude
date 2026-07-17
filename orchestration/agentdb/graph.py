#!/usr/bin/env python3
"""agentdb learning graph + promotion — derived from embeddings, no external deps.

Builds a knowledge graph OVER the learnings (distinct from the context-load telemetry
in the `nodes`/`edges` tables, migration 002): edges connect learnings that are
semantically related (cosine over the migration-015 embeddings) or explicitly linked
(`[[double-bracket]]` references in insight/evidence). On top of that, a promotion
detector clusters recurring failures — the "a failure seen 3x becomes doctrine" idea —
and surfaces candidates for human/agent review (never auto-writes doctrine).

Everything here is DERIVED data: the `learning_edges` table rebuilds from embeddings +
learning text via `agentdb graph build`, so it is excluded from the JSON mirror like the
embedding BLOBs. Degrades gracefully: with no embeddings, only `[[link]]` edges are built.

Subcommands:
  build   <db>            (re)build learning_edges from cosine + [[links]]; print counts
  neighbors <db> <id>     list a learning's edges (traversal / debugging)
  promote <db> [--min N]  cluster recurring failures (default >=3) -> promotion candidates
  stats   <db>            edge/cluster summary

Thresholds (tunable via env): AGENTDB_SIM_EDGE (default 0.45) links "similar";
AGENTDB_SIM_DUP (default 0.80) marks "near_duplicate".
"""
from __future__ import annotations

import os
import re
import sqlite3
import sys

SIM_EDGE = float(os.environ.get("AGENTDB_SIM_EDGE", "0.45"))
SIM_DUP = float(os.environ.get("AGENTDB_SIM_DUP", "0.80"))

try:
    import numpy as _np
except Exception:
    _np = None

DDL = """
CREATE TABLE IF NOT EXISTS learning_edges (
  src      TEXT NOT NULL,
  dst      TEXT NOT NULL,
  relation TEXT NOT NULL,          -- 'similar' | 'near_duplicate' | 'references'
  weight   REAL DEFAULT 1.0,
  ts       TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  PRIMARY KEY (src, dst, relation)
);
CREATE INDEX IF NOT EXISTS idx_ledges_src ON learning_edges(src);
CREATE INDEX IF NOT EXISTS idx_ledges_rel ON learning_edges(relation);
"""


def _ensure(con):
    con.executescript(DDL)


def _unpack(blob):
    n = len(blob) // 4
    if _np is not None:
        return _np.frombuffer(blob, dtype="<f4", count=n)
    import struct
    return list(struct.unpack("<%df" % n, blob))


def _cos(a, b):
    # vectors are L2-normalized at embed time -> cosine is the dot product
    if _np is not None:
        return float(a.dot(b)) if a.shape == b.shape else -1.0
    if len(a) != len(b):
        return -1.0
    return sum(x * y for x, y in zip(a, b))


def _load(con):
    cols = {r[1] for r in con.execute("PRAGMA table_info(learnings)")}
    arch = "AND archived_at IS NULL" if "archived_at" in cols else ""
    rows = con.execute(
        "SELECT id, type, insight, COALESCE(evidence,''), embedding FROM learnings "
        "WHERE 1=1 %s" % arch
    ).fetchall()
    items = []
    for rid, typ, insight, evidence, emb in rows:
        items.append({"id": rid, "type": typ, "insight": insight,
                      "text": insight + " " + evidence,
                      "vec": _unpack(emb) if emb else None})
    return items


_LINK_RE = re.compile(r"\[\[([^\]]+)\]\]")


def cmd_build(db):
    con = sqlite3.connect(db)
    _ensure(con)
    con.execute("DELETE FROM learning_edges")  # full rebuild (idempotent)
    items = _load(con)
    by_id = {it["id"]: it for it in items}

    n_sim = n_dup = n_ref = 0
    # 1) semantic edges (undirected, stored once with src<dst) — needs embeddings
    embedded = [it for it in items if it["vec"] is not None]
    for i in range(len(embedded)):
        for j in range(i + 1, len(embedded)):
            a, b = embedded[i], embedded[j]
            s = _cos(a["vec"], b["vec"])
            if s < SIM_EDGE:
                continue
            rel = "near_duplicate" if s >= SIM_DUP else "similar"
            src, dst = sorted((a["id"], b["id"]))
            con.execute(
                "INSERT OR REPLACE INTO learning_edges(src,dst,relation,weight) VALUES(?,?,?,?)",
                (src, dst, rel, round(s, 4)))
            if rel == "near_duplicate":
                n_dup += 1
            else:
                n_sim += 1
    # 2) explicit [[link]] references (directed) — resolve link text against insights
    for it in items:
        for m in _LINK_RE.findall(it["text"]):
            key = m.strip().lower()
            for other in items:
                if other["id"] == it["id"]:
                    continue
                if key in other["insight"].lower()[:60] or key in other["id"].lower():
                    con.execute(
                        "INSERT OR REPLACE INTO learning_edges(src,dst,relation,weight) VALUES(?,?,?,?)",
                        (it["id"], other["id"], "references", 1.0))
                    n_ref += 1
                    break
    con.commit()
    con.close()
    print("graph build: %d similar, %d near-duplicate, %d reference edge(s) over %d learnings (%d embedded)"
          % (n_sim, n_dup, n_ref, len(items), len(embedded)))
    return 0


def _components(ids, edges):
    """Union-find connected components over an edge list."""
    parent = {i: i for i in ids}

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for a, b in edges:
        if a in parent and b in parent:
            parent[find(a)] = find(b)
    comps = {}
    for i in ids:
        comps.setdefault(find(i), []).append(i)
    return list(comps.values())


# Promotion clusters use a TIGHTER similarity than graph edges: a recurring theme
# worth a doctrine entry means genuinely cohesive failures, not the transitive
# hairball that a loose threshold + single-linkage produces. hit_count is NOT used —
# it measures recall relevance, not recurrence, and is inflated by surfacing.
SIM_PROMOTE = float(os.environ.get("AGENTDB_SIM_PROMOTE", "0.55"))


def cmd_promote(db, min_size=3):
    con = sqlite3.connect(db)
    _ensure(con)
    cols = {r[1] for r in con.execute("PRAGMA table_info(learnings)")}
    arch = "AND archived_at IS NULL" if "archived_at" in cols else ""
    fails = con.execute(
        "SELECT id, insight FROM learnings WHERE type IN ('failure','gotcha') %s" % arch
    ).fetchall()
    fail_ids = {r[0] for r in fails}
    insight = {r[0]: r[1] for r in fails}
    # cohesive edges among failures only: weight >= SIM_PROMOTE (tighter than graph build)
    edges = [(s, d) for s, d, w in con.execute(
        "SELECT src,dst,weight FROM learning_edges WHERE relation IN ('similar','near_duplicate')")
        if s in fail_ids and d in fail_ids and (w or 0) >= SIM_PROMOTE]
    con.close()

    candidates = []
    for comp in _components(list(fail_ids), edges):
        if len(comp) >= min_size:
            candidates.append({"reason": "%d cohesive recurring failures (sim>=%.2f) — candidate doctrine theme"
                               % (len(comp), SIM_PROMOTE),
                               "members": [(i, insight[i]) for i in comp]})
    return candidates


def cmd_neighbors(db, lid):
    con = sqlite3.connect(db)
    _ensure(con)
    rows = con.execute(
        "SELECT src,dst,relation,weight FROM learning_edges WHERE src=? OR dst=? ORDER BY weight DESC",
        (lid, lid)).fetchall()
    con.close()
    if not rows:
        print("no edges for %s (run: agentdb graph build)" % lid)
        return 0
    for s, d, rel, w in rows:
        other = d if s == lid else s
        print("  %-14s %s  (w=%.3f)" % (rel, other, w))
    return 0


def cmd_stats(db):
    con = sqlite3.connect(db)
    _ensure(con)
    for rel in ("similar", "near_duplicate", "references"):
        n = con.execute("SELECT COUNT(*) FROM learning_edges WHERE relation=?", (rel,)).fetchone()[0]
        print("  %-14s %d" % (rel, n))
    con.close()
    return 0


def main(argv):
    if len(argv) < 3:
        sys.stderr.write("usage: graph.py {build|neighbors|promote|stats} <db> [args]\n")
        return 2
    cmd, db = argv[1], argv[2]
    if cmd == "build":
        return cmd_build(db)
    if cmd == "stats":
        return cmd_stats(db)
    if cmd == "neighbors":
        if len(argv) < 4:
            sys.stderr.write("usage: graph.py neighbors <db> <learning-id>\n")
            return 2
        return cmd_neighbors(db, argv[3])
    if cmd == "promote":
        min_size = 3
        if "--min" in argv:
            min_size = int(argv[argv.index("--min") + 1])
        cands = cmd_promote(db, min_size)
        if not cands:
            print("no promotion candidates (no failure cluster >= %d, no failure reinforced >= %dx)"
                  % (min_size, min_size * 2))
            return 0
        print("## Promotion candidates (%d) — recurring failures worth hardening into doctrine\n" % len(cands))
        for c in cands:
            print("- **%s**" % c["reason"])
            for lid, ins in c["members"]:
                print("    - [%s] %s" % (lid, ins[:100]))
            print()
        return 0
    sys.stderr.write("unknown subcommand: %s\n" % cmd)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
