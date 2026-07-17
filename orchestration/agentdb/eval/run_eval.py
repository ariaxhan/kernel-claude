#!/usr/bin/env python3
"""agentdb recall eval — measure retrieval quality, prove hybrid vs FTS-only.

Runs the REAL shipped recall (`agentdb recall --ids`) against a gold set of
task->should-surface-learning pairs, in two arms:
  - baseline : AGENTDB_NO_EMBED=1  (pure FTS keyword recall, the pre-015 behavior)
  - hybrid   : embedding backend enabled (FTS bm25 fused with semantic cosine, RRF)

Metric: recall@k = mean over queries of |relevant ∩ top-k| / |relevant|.
Also reports hit@k (fraction of queries with >=1 relevant id in top-k).

This shells out to the actual agentdb binary so it measures what ships, not a
reimplementation. The gold set is JSON: [{"query": "...", "relevant": ["id", ...]}].

Usage:
  run_eval.py --db <db> --gold <gold.json> [--k 5] [--backend hash|fastembed]
              [--embed-python <python>]

Exit 0 always (it's a measurement, not a gate); prints a JSON summary on the last
line so callers (tests) can parse recall_baseline / recall_hybrid / delta.
"""
import argparse
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
AGENTDB = os.path.normpath(os.path.join(HERE, "..", "agentdb"))


def recall_ids(db, query, env_extra, k):
    env = dict(os.environ)
    # db is <ROOT>/_meta/agentdb/agent.db -> AGENTDB_ROOT is the dir above _meta.
    abs_db = os.path.abspath(db)
    env["AGENTDB_ROOT"] = abs_db.split(os.sep + "_meta" + os.sep)[0]
    env["RECALL_LIMIT"] = str(k)
    env.update(env_extra)
    try:
        out = subprocess.run(
            [AGENTDB, "recall", "--ids", query],
            capture_output=True, text=True, env=env, timeout=60,
        ).stdout
    except Exception as exc:
        sys.stderr.write("recall failed for %r: %s\n" % (query, exc))
        return []
    return [ln.strip() for ln in out.splitlines() if ln.strip()][:k]


K_LIST = (1, 3, 5, 10)


def _reciprocal_rank(got, relevant):
    for i, gid in enumerate(got, 1):
        if gid in relevant:
            return 1.0 / i
    return 0.0


def score(gold, db, env_extra, k):
    # Retrieve top-max(K_LIST) once per query; score recall@k for every k + MRR.
    retrieve_n = max(max(K_LIST), k)
    per_k_recall = {kk: [] for kk in K_LIST}
    rrs = []
    primary_recall, primary_hits = [], []
    per_query = []
    for item in gold:
        relevant = set(item["relevant"])
        if not relevant:
            continue
        got = recall_ids(db, item["query"], env_extra, retrieve_n)
        for kk in K_LIST:
            inter = relevant & set(got[:kk])
            per_k_recall[kk].append(len(inter) / len(relevant))
        rrs.append(_reciprocal_rank(got, relevant))
        inter_k = relevant & set(got[:k])
        r = len(inter_k) / len(relevant)
        primary_recall.append(r)
        primary_hits.append(1.0 if inter_k else 0.0)
        per_query.append({"query": item["query"], "recall": r,
                          "got": got[:k], "relevant": sorted(relevant)})
    mean = lambda xs: (sum(xs) / len(xs)) if xs else 0.0
    metrics = {"recall_at": {kk: round(mean(v), 4) for kk, v in per_k_recall.items()},
               "mrr": round(mean(rrs), 4)}
    return mean(primary_recall), mean(primary_hits), per_query, metrics


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", required=True)
    ap.add_argument("--gold", required=True)
    ap.add_argument("--k", type=int, default=5)
    ap.add_argument("--backend", default="", help="hash|fastembed|sentence_transformers")
    ap.add_argument("--embed-python", default="")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args(argv[1:])

    gold = json.load(open(args.gold))

    base_env = {"AGENTDB_NO_EMBED": "1"}
    hyb_env = {"AGENTDB_NO_EMBED": "0"}
    if args.backend:
        hyb_env["AGENTDB_EMBED_BACKEND"] = args.backend
    if args.embed_python:
        hyb_env["AGENTDB_EMBED_PYTHON"] = args.embed_python

    r_base, h_base, pq_base, m_base = score(gold, args.db, base_env, args.k)
    r_hyb, h_hyb, pq_hyb, m_hyb = score(gold, args.db, hyb_env, args.k)

    if not args.quiet:
        print("=" * 64)
        print("agentdb recall eval  (%d gold queries, backend: %s)" % (len(gold), args.backend or "auto"))
        print("-" * 64)
        print("  %-10s %8s %8s %8s %8s %8s" % ("arm", "r@1", "r@3", "r@5", "r@10", "MRR"))
        for label, m in (("FTS-only", m_base), ("HYBRID", m_hyb)):
            ra = m["recall_at"]
            print("  %-10s %8.3f %8.3f %8.3f %8.3f %8.3f" % (
                label, ra[1], ra[3], ra[5], ra[10], m["mrr"]))
        dra = {kk: m_hyb["recall_at"][kk] - m_base["recall_at"][kk] for kk in K_LIST}
        print("  %-10s %+8.3f %+8.3f %+8.3f %+8.3f %+8.3f" % (
            "delta", dra[1], dra[3], dra[5], dra[10], m_hyb["mrr"] - m_base["mrr"]))
        print("=" * 64)
        # show queries where hybrid changed the outcome
        for b, hq in zip(pq_base, pq_hyb):
            if abs(hq["recall"] - b["recall"]) > 1e-9:
                arrow = "↑" if hq["recall"] > b["recall"] else "↓"
                print("  %s %-52s %.2f -> %.2f" % (arrow, b["query"][:52], b["recall"], hq["recall"]))

    print(json.dumps({
        "k": args.k, "n": len(gold),
        "recall_baseline": round(r_base, 4), "recall_hybrid": round(r_hyb, 4),
        "hit_baseline": round(h_base, 4), "hit_hybrid": round(h_hyb, 4),
        "delta_recall": round(r_hyb - r_base, 4),
        "baseline_metrics": m_base, "hybrid_metrics": m_hyb,
    }))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
