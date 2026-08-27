#!/usr/bin/env python3
"""autocorrect-tool-input.py - PreToolUse hook for non-Bash tools whose input the model gets
wrong in a fixed, mechanical way. Same contract as autocorrect-bash.py: deterministic,
meaning-preserving rewrites announced via additionalContext; notes only where a rewrite would
be a guess; never blocks.

Evidence (2026-08-12..26, one operator, 1235 errored tool calls):
  WebFetch   53 calls missing the required `prompt` (every one from a headless haiku job) ->
             the fetch never happened and the job wrote "no sources" as if it had looked.
  Chrome     `tabs_close_mcp` with tabIds as a JSON STRING ("[123]") x2, `browser_batch` with
             {tool, params} instead of {name, input} x1, `navigate` to file:// x7 (the extension
             refuses file URLs; the fix is to serve the directory), `tabs_create_mcp` before
             `tabs_context_mcp` x1.
  Read       6 calls on files over the 256KB cap without offset/limit -> add offset=0, limit=400.
"""
import json
import os
import re
import sys

DEFAULT_FETCH_PROMPT = ("Return the page's main content as clean text: title, byline/date if present, "
                        "and the body. Omit navigation, ads and boilerplate.")


def emit(updated, note, tool_input):
    payload = {"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": "[autocorrect] " + note}}
    if updated is not None:
        merged = dict(tool_input)
        merged.update(updated)
        payload["hookSpecificOutput"]["updatedInput"] = merged
        payload["systemMessage"] = "autocorrect: " + note.split(".")[0]
    sys.stdout.write(json.dumps(payload))


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return
    if not isinstance(data, dict):
        return
    tool = data.get("tool_name") or ""
    ti = data.get("tool_input") or {}
    if not isinstance(ti, dict):
        return

    if tool == "WebFetch":
        if ti.get("url") and not ti.get("prompt"):
            emit({"prompt": DEFAULT_FETCH_PROMPT},
                 "WebFetch requires BOTH `url` and `prompt`; a default prompt was added. Pass an explicit "
                 "prompt next time saying what to extract.", ti)
        return

    if tool in ("Read", "Edit") and ti.get("file_path"):
        fp = os.path.expanduser(ti["file_path"])
        if not os.path.exists(fp):
            # 13 Read calls on non-existent paths in 14 days: wrong directory for a real file, or a
            # date-named file that was never written. Resolve unique basename; else list neighbours.
            project = os.environ.get("CLAUDE_PROJECT_DIR") or data.get("cwd") or os.getcwd()
            leaf = os.path.basename(fp)
            hits = []
            root = os.path.realpath(project)
            d0 = root.count(os.sep)
            for dp, dn, fn in os.walk(root):
                dn[:] = [d for d in dn if not d.startswith(".") and d not in ("node_modules", ".venv", "dist", "build")]
                if dp.count(os.sep) - d0 >= 7:
                    dn[:] = []
                    continue
                if leaf in fn:
                    hits.append(os.path.join(dp, leaf))
                    if len(hits) > 6:
                        break
            if len(hits) == 1 and tool == "Read":
                emit({"file_path": hits[0]}, f"{ti['file_path']} does not exist; the only file with that name under the project is {hits[0]}, rewritten.", ti)
                return
            parent = os.path.dirname(fp)
            sib = sorted(os.listdir(parent))[-8:] if os.path.isdir(parent) else []
            msg = f"{ti['file_path']} does not exist."
            if hits:
                msg += f" Same name elsewhere: {', '.join(hits[:4])}."
            elif sib:
                msg += f" {parent} holds (last 8): {', '.join(sib)}."
            else:
                msg += f" {parent} does not exist either."
            emit(None, msg + " Not rewritten.", ti)
            return

    if tool == "Read":
        fp = ti.get("file_path")
        if fp and "offset" not in ti and "limit" not in ti:
            try:
                size = os.path.getsize(os.path.expanduser(fp))
            except OSError:
                return
            if size > 256 * 1024:
                emit({"offset": 1, "limit": 400},
                     f"{os.path.basename(fp)} is {size // 1024}KB, over the 256KB Read cap; added offset=1 limit=400. "
                     f"Page through with offset, or grep for the part you need.", ti)
        return

    if tool == "mcp__claude-in-chrome__tabs_close_mcp":
        ids = ti.get("tabIds")
        if isinstance(ids, str):
            try:
                parsed = json.loads(ids)
            except Exception:
                parsed = [x for x in re.split(r"[^0-9]+", ids) if x]
            if isinstance(parsed, list):
                try:
                    parsed = [int(x) for x in parsed]
                except Exception:
                    return
                emit({"tabIds": parsed}, "tabIds must be a JSON array of integers, not a string; converted.", ti)
        elif isinstance(ids, int):
            emit({"tabIds": [ids]}, "tabIds must be an array; wrapped the single id.", ti)
        return

    if tool == "mcp__claude-in-chrome__navigate":
        url = ti.get("url") or ""
        if url.startswith("file://"):
            path = url[len("file://"):]
            d = os.path.dirname(path) or path
            emit(None, f"the Chrome extension refuses file:// URLs. Serve the directory first "
                       f"(`python3 -m http.server 8765 --directory '{d}' &`) and navigate to "
                       f"http://127.0.0.1:8765/{os.path.basename(path)}.", ti)
        return

    if tool == "mcp__claude-in-chrome__browser_batch":
        actions = ti.get("actions")
        if isinstance(actions, list) and actions and all(isinstance(a, dict) for a in actions):
            fixed, changed = [], False
            for a in actions:
                if "name" not in a and ("tool" in a or "action" in a):
                    fixed.append({"name": a.get("tool") or a.get("action"), "input": a.get("params") or a.get("input") or {}})
                    changed = True
                else:
                    fixed.append(a)
            if changed:
                emit({"actions": fixed}, "browser_batch actions are `{name, input}` objects; converted from `{tool, params}`.", ti)
        return



if __name__ == "__main__":
    main()
