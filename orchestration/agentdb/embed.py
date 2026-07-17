#!/usr/bin/env python3
"""agentdb embedding backend — local, private, dependency-graceful.

Produces sentence embeddings for learnings so recall can fuse keyword (FTS bm25)
with semantic (cosine) ranking. Everything here degrades to a no-op if no backend
is installed: the caller (the `agentdb` script) then uses pure FTS, exactly as before.

Backends, tried in order (all yield L2-normalized float32 vectors):
  - hash              : deterministic feature-hashing bag-of-words. NO dependency
                        beyond numpy-optional (falls back to pure-Python). Used by
                        kernel's own tests so CI needs no model download. Forced with
                        AGENTDB_EMBED_BACKEND=hash. Real but weak — plumbing, not quality.
  - fastembed         : ONNX all-MiniLM-L6-v2 (384d). ~50MB, no torch. Preferred real backend.
  - sentence_transformers : torch all-MiniLM-L6-v2 (384d). The heavier locked backend.

Subcommands:
  backend            print "<name> <model> <dim>" and exit 0; exit 3 if none available
  sync   <db>        embed every learning whose vector is missing/stale; write BLOBs
  query  <db> <text> print "<id>\t<cosine>" for every embedded learning, ranked desc

Vectors are stored as little-endian float32 bytes (numpy tobytes, or struct-packed
in the pure-Python path). Model id + timestamp are stored so a model change re-embeds.
"""
import os
import sys
import sqlite3
import struct
import math

MODEL_MINILM = "sentence-transformers/all-MiniLM-L6-v2"
HASH_DIM = 256
HASH_MODEL = "hash-bow-256-v1"

# ---------------------------------------------------------------------------
# numpy is optional. If present we use it (fast); if not, pure-Python fallback
# keeps the hash backend working so the mechanism never hard-depends on numpy.
try:
    import numpy as _np
except Exception:
    _np = None


def _l2_normalize(vec):
    norm = math.sqrt(sum(x * x for x in vec))
    if norm == 0:
        return vec
    return [x / norm for x in vec]


# ---------------------------------------------------------------------------
# Backend: hash (deterministic, dependency-light)
def _hash_embed(texts):
    """Feature-hash each text into a fixed-dim L2-normalized vector. Deterministic:
    same text -> same vector, on any machine, no model. Shared tokens -> nonzero
    cosine, so it clusters related insights well enough to test the plumbing."""
    out = []
    for text in texts:
        vec = [0.0] * HASH_DIM
        toks = "".join(c.lower() if c.isalnum() else " " for c in text).split()
        for tok in toks:
            if len(tok) < 2:
                continue
            # stable hash (not Python's salted hash): FNV-1a
            h = 2166136261
            for ch in tok.encode("utf-8"):
                h = ((h ^ ch) * 16777619) & 0xFFFFFFFF
            idx = h % HASH_DIM
            sign = 1.0 if (h >> 31) & 1 else -1.0
            vec[idx] += sign
        out.append(_l2_normalize(vec))
    return out, HASH_MODEL, HASH_DIM


# ---------------------------------------------------------------------------
# Backend: fastembed (ONNX, no torch)
_FASTEMBED = None


def _fastembed_embed(texts):
    global _FASTEMBED
    if _FASTEMBED is None:
        from fastembed import TextEmbedding
        _FASTEMBED = TextEmbedding(model_name="sentence-transformers/all-MiniLM-L6-v2")
    vecs = [list(map(float, v)) for v in _FASTEMBED.embed(list(texts))]
    vecs = [_l2_normalize(v) for v in vecs]
    dim = len(vecs[0]) if vecs else 384
    return vecs, MODEL_MINILM, dim


# ---------------------------------------------------------------------------
# Backend: sentence-transformers (torch)
_ST = None


def _st_embed(texts):
    global _ST
    if _ST is None:
        from sentence_transformers import SentenceTransformer
        _ST = SentenceTransformer("all-MiniLM-L6-v2")
    embs = _ST.encode(list(texts), normalize_embeddings=True)
    vecs = [list(map(float, row)) for row in embs]
    dim = len(vecs[0]) if vecs else 384
    return vecs, MODEL_MINILM, dim


def _select_backend():
    """Return (embed_fn, name) for the first available backend, or (None, None)."""
    forced = os.environ.get("AGENTDB_EMBED_BACKEND", "").strip().lower()
    if forced == "hash":
        return _hash_embed, "hash"
    if forced == "fastembed":
        return _fastembed_embed, "fastembed"
    if forced in ("sentence_transformers", "sentence-transformers", "st"):
        return _st_embed, "sentence_transformers"
    # auto: prefer the light real backend, then the heavy one. hash is opt-in only
    # (never auto — it must not silently shadow a real model).
    try:
        import fastembed  # noqa: F401
        return _fastembed_embed, "fastembed"
    except Exception:
        pass
    try:
        import sentence_transformers  # noqa: F401
        return _st_embed, "sentence_transformers"
    except Exception:
        pass
    return None, None


def _pack(vec):
    if _np is not None:
        return _np.asarray(vec, dtype="<f4").tobytes()
    return struct.pack("<%df" % len(vec), *vec)


def _unpack(blob):
    n = len(blob) // 4
    if _np is not None:
        return _np.frombuffer(blob, dtype="<f4", count=n)
    return list(struct.unpack("<%df" % n, blob))


def _cosine(a, b):
    # vectors are already L2-normalized at embed time -> cosine is the dot product.
    if _np is not None:
        if a.shape != b.shape:
            return -1.0
        return float(a.dot(b))
    if len(a) != len(b):
        return -1.0
    return sum(x * y for x, y in zip(a, b))


def _learning_text(insight, evidence, domain):
    parts = [insight or ""]
    if evidence:
        parts.append(evidence)
    if domain:
        parts.append(domain)
    return "\n".join(parts)


def cmd_backend():
    fn, name = _select_backend()
    if fn is None:
        sys.stderr.write("no embedding backend (install fastembed or sentence-transformers)\n")
        return 3
    # Probe: embed a trivial string to confirm the model actually loads + get dim.
    try:
        _, model, dim = fn(["probe"])
    except Exception as exc:  # model download blocked / broken install
        sys.stderr.write("backend %s present but failed to load: %s\n" % (name, exc))
        return 3
    print("%s %s %d" % (name, model, dim))
    return 0


def cmd_sync(db_path):
    fn, name = _select_backend()
    if fn is None:
        sys.stderr.write("embed sync: no backend available; leaving embeddings NULL (recall stays FTS-only)\n")
        return 3
    con = sqlite3.connect(db_path)
    con.row_factory = sqlite3.Row
    cols = {r[1] for r in con.execute("PRAGMA table_info(learnings)")}
    if "embedding" not in cols:
        sys.stderr.write("embed sync: learnings.embedding column missing (run a recall/preflight first)\n")
        return 4
    arch = "AND archived_at IS NULL" if "archived_at" in cols else ""
    # Re-embed rows with no vector, a different model, or a vector older than the row.
    rows = con.execute(
        "SELECT id, insight, evidence, domain FROM learnings "
        "WHERE (embedding IS NULL OR embedding_model IS NULL OR embedding_model != ? "
        "       OR embedding_ts IS NULL OR embedding_ts < ts) %s" % arch,
        (MODEL_MINILM if name != "hash" else HASH_MODEL,),
    ).fetchall()
    if not rows:
        print("embed sync: 0 to embed (all current) via %s" % name)
        return 0
    texts = [_learning_text(r["insight"], r["evidence"], r["domain"]) for r in rows]
    vecs, model, _dim = fn(texts)
    now = con.execute("SELECT strftime('%Y-%m-%dT%H:%M:%fZ','now')").fetchone()[0]
    for r, v in zip(rows, vecs):
        con.execute(
            "UPDATE learnings SET embedding=?, embedding_model=?, embedding_ts=? WHERE id=?",
            (_pack(v), model, now, r["id"]),
        )
    con.commit()
    con.close()
    print("embed sync: embedded %d learning(s) via %s (%s)" % (len(rows), name, model))
    return 0


def cmd_query(db_path, query_text):
    fn, name = _select_backend()
    if fn is None:
        return 3  # silent: caller falls back to FTS
    con = sqlite3.connect(db_path)
    cols = {r[1] for r in con.execute("PRAGMA table_info(learnings)")}
    if "embedding" not in cols:
        return 4
    arch = "AND archived_at IS NULL" if "archived_at" in cols else ""
    vis = "AND (visibility='agent' OR visibility IS NULL)" if "visibility" in cols else ""
    rows = con.execute(
        "SELECT id, embedding FROM learnings WHERE embedding IS NOT NULL %s %s" % (arch, vis)
    ).fetchall()
    con.close()
    if not rows:
        return 5  # nothing embedded yet -> caller falls back to FTS
    qvec, _model, _dim = fn([query_text])
    q = _np.asarray(qvec[0], dtype="<f4") if _np is not None else qvec[0]
    scored = []
    for rid, blob in rows:
        if not blob:
            continue
        scored.append((rid, _cosine(q, _unpack(blob))))
    scored.sort(key=lambda t: t[1], reverse=True)
    for rid, score in scored:
        sys.stdout.write("%s\t%.6f\n" % (rid, score))
    return 0


def main(argv):
    if len(argv) < 2:
        sys.stderr.write("usage: embed.py {backend|sync <db>|query <db> <text>}\n")
        return 2
    cmd = argv[1]
    if cmd == "backend":
        return cmd_backend()
    if cmd == "sync":
        if len(argv) < 3:
            sys.stderr.write("usage: embed.py sync <db>\n")
            return 2
        return cmd_sync(argv[2])
    if cmd == "query":
        if len(argv) < 4:
            sys.stderr.write("usage: embed.py query <db> <text>\n")
            return 2
        return cmd_query(argv[2], " ".join(argv[3:]))
    sys.stderr.write("unknown subcommand: %s\n" % cmd)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
