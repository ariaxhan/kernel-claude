#!/usr/bin/env python3
"""syntax-coach.py - PostToolUse(Bash) hook that turns a wrong invocation into a lesson the model
reads in the same turn.

Measured 2026-08-12..26: of 98 Bash calls whose OUTPUT contained a usage banner, an
`illegal option`, or an `unknown command`, 91 returned exit 0 (the bad command sat behind
`| head`, `2>&1 | tail`, `;`, or `|| true`), so the tool result was not flagged as an error and
the agent carried on as if the call had worked. Those are the silent ones. The loud ones were
retried with a different guess because the failure text names the problem, not the fix.

This hook reads the tool response, recognises the failure shapes below, and appends ONE line
of additionalContext that says (a) the call did not do what you think, and (b) the exact form
that would have. It never blocks (PostToolUse cannot), never rewrites, and stays silent on a
clean run.

Shapes it recognises:
  - BSD/GNU flag mismatch on macOS  (cat -A, grep -P, sed -i, basename -c, date -d, ls --color=...)
  - a usage banner from a command the agent RAN (not one it asked for with --help)
  - `command not found` for the usual suspects (python, timeout, shuf, tac, pytest, curl, wrangler)
  - git: `unknown option`, `ambiguous argument` (missing `--`), `Needed a single revision`,
    `cannot pull with rebase`
  - `cd: no such file or directory` (paired with the cwd the tool actually used)
  - a house CLI printing its usage (agentdb, jobctl, codex-lane.sh, graphify, claude plugin)

Disable globally with KERNEL_SYNTAX_COACH=0.
"""
import json
import os
import re
import shutil
import sys

if os.environ.get("KERNEL_SYNTAX_COACH", "1") == "0":
    sys.exit(0)

MACOS = sys.platform == "darwin"

# (regex over the OUTPUT, fix text). Output-anchored so a --help read never triggers the flag rules.
FLAG_FIXES = [
    (r"cat: illegal option -- A", "`cat -A` is GNU-only; on macOS use `cat -vet` (same output)."),
    (r"grep: invalid option -- P", "macOS grep has no -P. Use `rg -P '<pcre>'` or `grep -E '<ere>'`."),
    (r"sed: 1: .*: invalid command code|sed: -i may not be used with stdin", "BSD sed in-place form is `sed -i '' 's/a/b/' file` (empty backup suffix is required)."),
    (r"basename: illegal option -- c", "BSD basename has no -c; use `${var##*/}` or `basename \"$p\"`."),
    (r"date: illegal option -- d", "BSD date has no -d. Use `date -j -f '%Y-%m-%d' '<date>' +%s`, or `gdate -d` (coreutils)."),
    (r"ls: (illegal|unrecognized) option -- -?color", "BSD ls uses `-G` for colour, not `--color`. Prefer no colour in tool output."),
    (r"readlink: illegal option -- f", "BSD readlink has no -f; use `python3 -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' <p>` or `greadlink -f`."),
    (r"stat: illegal option -- c", "BSD stat uses `-f '%z'` style, not `-c`. `stat -f '%z' file` for size, `%m` for mtime."),
    (r"xargs: illegal option -- d", "BSD xargs has no -d. Use `tr '\\n' '\\0' | xargs -0`."),
    (r"find: -printf: unknown primary", "BSD find has no -printf. Use `-exec stat -f '...' {} +` or `-print0 | xargs -0`."),
    (r"\bunknown option `cached'", "`git status --cached` does not exist. Use `git diff --cached --stat` (staged) or `git status --short`."),
    (r"fatal: ambiguous argument '.*': unknown revision or path", "git could not tell a path from a revision. Put `--` before paths: `git diff -- <path>`."),
    (r"fatal: Needed a single revision", "A ref in that command does not exist (often `origin/main` before `git fetch`, or a branch name typo). `git fetch origin` then `git rev-parse --verify <ref>`."),
    (r"error: cannot pull with rebase: You have unstaged changes", "`git pull --rebase` refuses with a dirty tree. Commit first (`git add <files> && git commit`), then pull. Never stash someone else's tree."),
    (r"fatal: Unable to create '.*index\.lock': File exists", "Another git process holds the index. Wait a few seconds and retry the same command; do not delete the lock unless `pgrep -fl git` shows nothing."),
    (r"error: unknown option '--file'", "`next lint` has no --file; pass paths positionally or run `npx eslint <file>`."),
    (r"error: unknown command 'graph_stats'|Unknown command: graph_stats", "graphify's CLI is `graphify stats`; `graph_stats` is the MCP tool name, not a subcommand."),
    (r"error: unknown option '--marketplace'|error: unknown command 'info'", "`claude plugin` syntax: `claude plugin marketplace add <owner/repo>` then `claude plugin install <name>@<marketplace>`; there is no `info` subcommand."),
    (r"jobctl: error: unrecognized arguments: --job", "`jobctl resolve` takes the job id positionally: `jobctl resolve <id>`. `jobctl --help` lists subcommands."),
    (r"unrecognized arguments: --no-window", "That server has no `--no-window`; run `<script> --help` and use the flag it lists (`--no-browser`)."),
]

NOT_FOUND_FIXES = {
    "python": "this host has `python3` only",
    "timeout": "install coreutils (`brew install coreutils`) and use `gtimeout`, or use the Bash tool's `timeout` parameter",
    "shuf": "install coreutils and use `gshuf`, or `sort -R`",
    "tac": "install coreutils and use `gtac`, or `tail -r`",
    "pytest": "run it through the venv: `.venv/bin/pytest` or `python3 -m pytest`",
    "wrangler": "use `npx wrangler` from the project, or the project's own deploy script",
    "curl": "curl is missing from this shell's PATH (sandbox?); try `/usr/bin/curl`",
    "exiftool": "not installed; `brew install exiftool` or use `sips -g all <file>`",
    "gtimeout": "`brew install coreutils`",
}

HOUSE_USAGE = [
    (r"Usage: agentdb learn <type>", "agentdb learn takes the type FIRST: `agentdb learn gotcha|failure|pattern|preference \"<what>\" \"<why>\" [--global]`."),
    (r"usage: jobctl \[-h\] \{validate,plan,sync,status,adopt,resolve,record\}", "jobctl subcommands: validate, plan, sync, status, adopt, resolve <id>, record. Flags go after the subcommand."),
    (r"usage: codex-lane\.sh \{submit\|status\|reap\|logs\|result\|receipt\}", "codex-lane.sh needs a subcommand: `codex-lane.sh submit <prompt-file>` / `status` / `result <id>`."),
    (r"Usage: graphify <command>", "graphify subcommands: `graphify query \"<q>\"`, `graphify path A B`, `graphify affected X`, `graphify stats`."),
    (r"Usage: buzz messages <COMMAND>", "buzz messages has no `fetch`; the read subcommand is `buzz messages get --channel <uuid> --limit N`."),
]


def text_of(resp):
    if resp is None:
        return ""
    if isinstance(resp, str):
        return resp
    if isinstance(resp, dict):
        parts = []
        for k in ("stdout", "stderr", "output", "content", "text", "error"):
            v = resp.get(k)
            if isinstance(v, str):
                parts.append(v)
            elif isinstance(v, list):
                parts.extend(x.get("text", "") for x in v if isinstance(x, dict))
        return "\n".join(parts)
    if isinstance(resp, list):
        return "\n".join(x.get("text", "") for x in resp if isinstance(x, dict))
    return str(resp)


def asked_for_help(command):
    return bool(re.search(r"(^|\s)(--help|-h|help)(\s|$)", command))


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return
    if data.get("tool_name") not in (None, "Bash"):
        return
    if not isinstance(data, dict):
        return
    ti = data.get("tool_input")
    command = (ti.get("command") if isinstance(ti, dict) else None) or ""
    outp = text_of(data.get("tool_response"))
    if not outp:
        return
    notes = []

    if MACOS:
        for pat, fix in FLAG_FIXES:
            if re.search(pat, outp):
                notes.append(fix)
    else:
        for pat, fix in FLAG_FIXES[10:]:
            if re.search(pat, outp):
                notes.append(fix)

    # Whole-line shapes only. Unanchored, `not found: curl` inside quoted text (an issue body, a
    # transcript excerpt) coached a curl that was never run (kernel #226).
    for m in re.finditer(r"^(?:[A-Za-z0-9_./-]+:(?: ?\d+:)? ?)?(?:command not found: |not found: )([A-Za-z0-9_.-]+)\s*$"
                         r"|^(?:[A-Za-z0-9_./-]+:(?: ?\d+:)? ?)?([A-Za-z0-9_.-]+): (?:command )?not found\s*$", outp, re.M):
        name = m.group(1) or m.group(2)
        if not name:
            continue
        hint = NOT_FOUND_FIXES.get(name)
        if hint:
            notes.append(f"`{name}` is not on PATH: {hint}.")
        elif not shutil.which(name):
            notes.append(f"`{name}` is not installed on this host; check `command -v {name}` before building on it.")

    m = re.search(r"cd:\d*:? ?no such file or directory: (\S+)|cannot change to '([^']+)'", outp)
    if m:
        target = m.group(1) or m.group(2)
        cwd = data.get("cwd") or os.getcwd()
        notes.append(f"`cd {target}` failed: it does not exist relative to the shell's cwd ({cwd}). "
                     f"The Bash tool does not keep cwd between calls; use an absolute path.")

    for pat, fix in HOUSE_USAGE:
        if re.search(pat, outp) and not asked_for_help(command):
            notes.append(fix)

    # A usage banner from a command that was RUN, not asked about.
    if not notes and not asked_for_help(command):
        um = re.search(r"^(?:usage|Usage): ?([A-Za-z0-9_./-]+)", outp, re.M)
        if um and re.search(r"illegal option|invalid option|unknown option|unrecognized|error: (unknown|unexpected|the following)|too many arguments|missing argument|required", outp, re.I):
            notes.append(f"`{um.group(1)}` printed its usage: the invocation was wrong and did NOT run. "
                         f"Read the usage line above and re-issue with the exact syntax it shows.")

    if not notes:
        return
    seen, uniq = set(), []
    for n in notes:
        if n not in seen:
            seen.add(n)
            uniq.append(n)
    ctx = "[syntax-coach] " + " ".join(uniq[:4])
    if len(uniq) > 4:
        ctx += f" (+{len(uniq) - 4} more)"
    sys.stdout.write(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": ctx}}))


if __name__ == "__main__":
    main()
