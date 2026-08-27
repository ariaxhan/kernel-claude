#!/usr/bin/env python3
"""autocorrect-bash.py - PreToolUse(Bash) hook that FIXES known-wrong invocations instead of
refusing them.

Why this exists (measured 2026-08-12..26 across one operator's Claude transcripts, 1235 errored
tool calls): the single largest error class was our own guards refusing commands (23%), the second
was agents guessing paths from the wrong cwd (11%), and the deterministic syntax slips (GNU flags on
macOS, `cd X cmd` with the `&&` dropped, `python` on a python3-only host) were retried two to four
times each because the failure text never said what the right form was. A block teaches nothing:
the agent reads "blocked", rewords, and tries again. A rewrite plus a one-line note teaches the
correct form in the same turn, and the corrected command is what the next call copies.

Contract:
  - Rewrites are DETERMINISTIC and SEMANTICS-PRESERVING. If a rewrite could change meaning, it is
    not a rewrite: the hook emits a note (additionalContext) and leaves the command alone.
  - Every rewrite is announced to the model via additionalContext and to the human via
    systemMessage, and appended to $KERNEL_AUTOCORRECT_LOG (default ~/.kernel/autocorrect.jsonl)
    so the retrospective can see which corrections are still needed.
  - Never blocks. Exit 0 always. Guards decide refusal; this hook decides shape.
  - Disable for one call with AUTOCORRECT_OFF=1 anywhere in the command, or globally with the
    env var KERNEL_AUTOCORRECT=0.

Rules (each one names the evidence that earned it):
  R1  `cd <dir> <command...>` on one line with the separator dropped   -> `cd <dir> && <command...>`
      (3 occurrences; the command then ran in the WRONG directory, git add landed in a parent repo)
  R2  `cd <relative>` that does not exist under the tool's cwd but resolves to exactly ONE
      directory under the project root                                  -> absolute path
      (48 occurrences of `cd: no such file or directory`; the Bash tool resets cwd between calls)
  R3  `python <args>` on a host with no `python` on PATH               -> `python3 <args>`
      (bash-guard blocked this 3x here, Codex hit it 3x more; macOS and most brew installs ship
      python3 only)
  R4  `cat -A` (GNU only)                                              -> `cat -vet` (BSD/GNU)
      (8 occurrences, all exit 0 through `| head`, so the model never saw the failure)
  R5  `sed -i 's/...'` GNU in-place form on BSD sed                     -> `sed -i '' 's/...'`
      (2 occurrences: `invalid command code`)
  R6  `grep -P` on BSD grep: NOT rewritten (ERE and PCRE differ), note only, points at `rg -P`.
      Probed, not assumed: silent when `grep -P` works on this host (a shim, GNU grep, ugrep).
      A static note outlived the shim that fixed it and taught a model to rewrite working code
      (kernel #226, 2026-08-27).
  R7  `timeout N`, `shuf`, `tac` missing: NOT rewritten, note only, points at coreutils/gtimeout.
      (42 blocks; the vault fix is `brew install coreutils` + shims, this note is for other hosts)
  R14 `${PIPESTATUS[n]}` at top level when the tool shell is zsh          -> `${pipestatus[n+1]}`
      (zsh spells it lowercase and indexes from 1; `PIPESTATUS` expands to nothing there, so the
      exit code printed blank and a working script got blamed, kernel #226)
"""
import subprocess
import json
import os
import re
import shutil
import sys
import time

ENV_OFF = os.environ.get("KERNEL_AUTOCORRECT", "1") == "0"
LOG = os.environ.get("KERNEL_AUTOCORRECT_LOG") or os.path.join(
    os.path.expanduser("~"), ".kernel", "autocorrect.jsonl"
)

# Commands that commonly follow `cd <dir>` on the same line when the `&&` is dropped. Only these
# trigger R1, so `cd foo bar` (a genuine two-arg cd typo) is left alone.
FOLLOWERS = (
    "git", "ls", "cat", "head", "tail", "sed", "grep", "rg", "find", "echo", "node", "npm", "npx",
    "pnpm", "yarn", "python3", "python", "pytest", "make", "cargo", "go", "bash", "sh", "bun",
    "gh", "wc", "sort", "uniq", "cut", "awk", "jq", "curl", "test", "mkdir", "cp", "mv", "touch",
    "agentdb", "ruff", "black", "tsc", "vitest", "jest", "swift", "xcodebuild",
)
SKIP_DIRS = {".git", "node_modules", ".venv", "venv", "__pycache__", ".next", "dist", "build",
             ".cache", ".graphify", "DerivedData"}


def out(payload):
    sys.stdout.write(json.dumps(payload))
    sys.stdout.flush()


def log(rec):
    try:
        os.makedirs(os.path.dirname(LOG), exist_ok=True)
        with open(LOG, "a") as fh:
            fh.write(json.dumps(rec) + "\n")
    except OSError:
        pass


def have(cmd):
    return shutil.which(cmd) is not None


def grep_has_P():
    """True when `grep -P` works on this host (GNU grep, ugrep, or a shim over rg). Probed,
    because the answer changed under the old static note the day a shim was installed."""
    try:
        r = subprocess.run(["grep", "-P", "a"], input=b"a\n", capture_output=True, timeout=2)
        return r.returncode == 0 and r.stdout.strip() == b"a"
    except Exception:
        return False


def tool_shell_is_zsh():
    return os.path.basename(os.environ.get("SHELL", "")) == "zsh"


def is_macos():
    return sys.platform == "darwin"


def first_line_segments(command):
    """Yield (line_index, line) for lines that look like top-level shell, skipping heredoc bodies."""
    lines = command.split("\n")
    in_doc = None
    for i, line in enumerate(lines):
        if in_doc is not None:
            if line.strip() == in_doc:
                in_doc = None
            continue
        m = re.search(r"<<-?\s*'?([A-Za-z_][A-Za-z0-9_]*)'?", line)
        if m:
            in_doc = m.group(1)
        yield i, line


def rule_cd_missing_separator(command, notes):
    """R1: `cd <dir> <known-command> ...` -> `cd <dir> && <known-command> ...`"""
    lines = command.split("\n")
    changed = False
    for i, line in first_line_segments(command):
        m = re.match(r'^(\s*cd\s+("[^"]+"|\'[^\']+\'|[^\s;&|]+))\s+([A-Za-z0-9_./-]+)(\s.*|$)', line)
        if not m:
            continue
        follower = m.group(3)
        if follower.startswith("-") or os.path.basename(follower) not in FOLLOWERS:
            continue
        # `cd dir VAR=1 cmd` is also a dropped separator; handled by the generic branch above only
        # when the follower is a known command, so an env assignment like `cd d FOO=1 git x` is
        # left alone (rare, and a rewrite there would be a guess).
        lines[i] = f"{m.group(1)} && {follower}{m.group(4)}"
        notes.append(f"R1 inserted `&&` after `cd {m.group(2)}`: without it the directory change "
                     f"silently swallowed `{follower}` as an argument and the command ran in the old cwd.")
        changed = True
    return "\n".join(lines) if changed else command


def resolve_relative_dir(rel, cwd, project_dir):
    """R2 helper: find exactly one directory under project_dir whose path ends with `rel`."""
    rel = rel.strip("\"'")
    if not rel or rel.startswith(("/", "~", "$", "-", ".")):
        return None
    if os.path.isdir(os.path.join(cwd, rel)):
        return None  # exists where the agent said; nothing to fix
    parts = rel.rstrip("/").split("/")
    leaf = parts[-1]
    if not leaf or leaf in ("..", "."):
        return None
    hits = []
    roots = [r for r in (project_dir, cwd) if r and os.path.isdir(r)]
    seen = set()
    for root in roots:
        root = os.path.realpath(root)
        if root in seen:
            continue
        seen.add(root)
        depth0 = root.count(os.sep)
        for dirpath, dirnames, _ in os.walk(root):
            dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and not d.startswith(".")]
            if dirpath.count(os.sep) - depth0 >= 6:
                dirnames[:] = []
                continue
            for d in dirnames:
                if d == leaf:
                    cand = os.path.join(dirpath, d)
                    if cand.endswith(os.sep + rel.rstrip("/")) or cand.endswith(os.sep + rel.rstrip("/").replace("/", os.sep)):
                        hits.append(cand)
            if len(hits) > 8:
                break
    hits = sorted(set(hits))
    return hits


def rule_cd_relative(command, cwd, project_dir, notes):
    """R2: rewrite a relative `cd X` that does not exist here but resolves uniquely under the project."""
    lines = command.split("\n")
    changed = False
    for i, line in first_line_segments(command):
        m = re.match(r'^(\s*cd\s+)("[^"]+"|\'[^\']+\'|[^\s;&|]+)(.*)$', line)
        if not m:
            continue
        target = m.group(2)
        hits = resolve_relative_dir(target, cwd, project_dir)
        if hits is None:
            continue
        if len(hits) == 1:
            lines[i] = f"{m.group(1)}{hits[0]}{m.group(3)}"
            notes.append(f"R2 `cd {target}` does not exist under the current cwd ({cwd}); rewrote to the one "
                         f"matching directory {hits[0]}. Use absolute paths: the Bash tool's cwd does not persist.")
            changed = True
        elif len(hits) > 1:
            notes.append(f"R2 `cd {target}` does not exist under {cwd} and is ambiguous under the project "
                         f"({len(hits)} matches: {', '.join(hits[:4])}). Not rewritten; pick one by absolute path.")
        else:
            notes.append(f"R2 `cd {target}` does not exist under {cwd} or anywhere under the project root. "
                         f"Not rewritten; `ls` the parent before guessing again.")
    return "\n".join(lines) if changed else command


def rule_python(command, notes):
    """R3: `python ` -> `python3 ` when python is absent and python3 is present."""
    if have("python") or not have("python3"):
        return command
    lines = command.split("\n")
    changed = False
    for i, line in first_line_segments(command):
        new = re.sub(r"(^|[|;&(]\s*|\s)python(\s)", r"\1python3\2", line)
        if new != line:
            lines[i] = new
            changed = True
    if changed:
        notes.append("R3 rewrote `python` -> `python3`: this host has no `python` on PATH.")
        return "\n".join(lines)
    return command


def rule_cat_A(command, notes):
    """R4: BSD cat has no -A; -vet is the portable equivalent (show nonprinting, ends, tabs)."""
    if not is_macos():
        return command
    new = re.sub(r"(^|[|;&(]\s*|\s)cat\s+-A(\s|$)", r"\1cat -vet\2", command)
    if new != command:
        notes.append("R4 rewrote `cat -A` -> `cat -vet`: macOS cat has no -A (GNU only). Same output.")
    return new


def rule_sed_i(command, notes):
    """R5: GNU `sed -i 's/..'` -> BSD `sed -i '' 's/..'`. Only when the next token is a script."""
    if not is_macos():
        return command
    if have("gsed") and re.search(r"(^|\s)gsed\s", command):
        return command
    # The token after -i must LOOK like a sed script (s/, y/, an address, -e), not an empty
    # suffix (`''` or `""`) and not a real suffix like .bak. `-i ""` was double-applied before
    # the 9.5.2 blind verifier caught it.
    pat = re.compile(r"(^|[|;&(]\s*|\s)sed\s+(-[a-zA-Z]*)?-i\s+(?=['\"]?(?:[sy]/|s\||[0-9]+[,!]?|/|\$|-e\b|-E\b|-n\b))")
    new = pat.sub(lambda m: f"{m.group(1)}sed {m.group(2) or ''}-i '' ", command)
    if new != command:
        if re.search(r"""sed\s+(-[a-zA-Z]*)?-i\s+(''|"")\s+(''|"")""", new):
            return command
        notes.append("R5 rewrote `sed -i` -> `sed -i ''`: BSD sed needs an explicit (empty) backup suffix, "
                     "otherwise the script is eaten as the suffix and you get `invalid command code`.")
    return new


TEXT_FLAG = re.compile(
    r'((?:git\s+(?:commit|tag)|gh\s+(?:issue|pr|release|api|repo)\s+[a-z-]+|agentdb\s+learn)[^|;&\n]*?\s-(?:m|b|t|F|-message|-body|-title|-notes)\s+)"((?:[^"\\]|\\.)*)"'
)


def rule_backticks_in_text_args(command, notes):
    """R8: a double-quoted commit/issue message containing an unescaped backtick or $( is a
    shell substitution, not text. `git commit -m "fix \\`foo\\`"` ran `foo` and committed the
    wrong message (operator-reported 2026-08-26). Escaping inside the same double quotes keeps
    the exact intended characters and changes nothing else."""
    def fix(m):
        body = m.group(2)
        new = re.sub(r'(?<!\\)`', r'\\`', body)
        new = re.sub(r'(?<!\\)\$\(', r'\\$(', new)
        if new == body:
            return m.group(0)
        fix.count += 1
        return f'{m.group(1)}"{new}"'
    fix.count = 0
    out_cmd = TEXT_FLAG.sub(fix, command)
    if fix.count:
        notes.append("R8 escaped backticks / $( inside a double-quoted message argument: unescaped they run as "
                     "shell substitution and the text is silently altered. Use single quotes for messages, or "
                     "pass the message from a file (`-F msg.txt`).")
    return out_cmd


# Strictly read-only commands. `sed` is NOT here: `sed -i` writes, and redirecting a write to a
# same-named file elsewhere is a silent clobber (found by the 9.5.2 blind verifier).
READ_CMDS = ("cat", "head", "tail", "wc", "less", "more", "nl", "stat", "file", "md5", "shasum")


def find_by_basename(path, project_dir):
    """Directories or files under project_dir whose basename equals path's basename (bounded walk)."""
    leaf = os.path.basename(path.rstrip("/"))
    if not leaf or len(leaf) < 3:
        return []
    hits = []
    root = os.path.realpath(project_dir)
    depth0 = root.count(os.sep)
    for dirpath, dirnames, files in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and not d.startswith(".")]
        if dirpath.count(os.sep) - depth0 >= 7:
            dirnames[:] = []
            continue
        if leaf in files or leaf in dirnames:
            hits.append(os.path.join(dirpath, leaf))
            if len(hits) > 6:
                break
    return sorted(set(hits))


def rule_read_paths(command, cwd, project_dir, notes):
    """R2b: a path handed to a READ-ONLY command that does not exist. Unique basename match under
    the project -> rewrite; otherwise name the candidates so the next call is not a second guess.
    87 'file guessed wrong' failures in 14 days; most were a wrong directory for a real file."""
    lines = command.split("\n")
    changed = False
    # A file this same command creates (`... > out.txt; wc -l out.txt`) does not exist yet at
    # hook time and must not be reported missing.
    created = set(m.group(1).strip("\"'") for m in re.finditer(r"(?:^|[^<>])>{1,2}\s*([^\s;&|]+)", command))
    for i, line in first_line_segments(command):
        for seg in re.split(r"\s*(?:&&|\|\||;|\|)\s*", line):
            toks = seg.strip().split()
            if not toks or os.path.basename(toks[0]) not in READ_CMDS:
                continue
            skip_next = False
            for tok in toks[1:]:
                if skip_next:
                    skip_next = False
                    continue  # the target of a bare `>` / `>>` / `<`: a write target is never a read path
                if tok in (">", ">>", "<"):
                    skip_next = True
                    continue
                if tok.startswith("-") or "$" in tok or "*" in tok or "{" in tok or tok in ("|", ">", ">>"):
                    continue
                if re.match(r"^[0-9&]*[<>]", tok):
                    continue  # a redirection (`2>/dev/null`, `>out`, `&>x`), not a path
                if not ("/" in tok or tok.endswith((".md", ".py", ".ts", ".js", ".json", ".sh", ".txt", ".yaml", ".yml", ".toml"))):
                    continue
                p = os.path.expanduser(tok.strip("\"'"))
                if tok.strip("\"'") in created:
                    continue
                full = p if os.path.isabs(p) else os.path.join(cwd, p)
                if os.path.exists(full):
                    continue
                hits = find_by_basename(p, project_dir)
                if len(hits) == 1:
                    lines[i] = lines[i].replace(tok, hits[0], 1)
                    notes.append(f"R2b `{p}` does not exist; the only file with that name under the project is {hits[0]}, rewritten.")
                    changed = True
                elif hits:
                    notes.append(f"R2b `{p}` does not exist. Same name elsewhere: {', '.join(hits[:4])}. Not rewritten.")
                else:
                    parent = os.path.dirname(full)
                    sib = sorted(os.listdir(parent))[:8] if os.path.isdir(parent) else []
                    notes.append(f"R2b `{p}` does not exist" + (f"; {parent} holds: {', '.join(sib)}" if sib else f" and neither does {parent}") + ". Not rewritten.")
    return "\n".join(lines) if changed else command


def rule_house_forms(command, notes):
    """R9-R11: deterministic fixes carried over from Vaults bash-guard (which blocked instead).
    R9  bare `recall|learn ...` at command start -> `agentdb recall|learn ...`   (~173 blocks lifetime)
    R10 git pathspec `:!_x` (leading _ parses as pathspec magic) -> `:(exclude)_x`   (~20)
    R11 `rg -h` means --help, not --no-filename -> `rg --no-filename`   (misread of grep -h)"""
    # Line-scoped like every other rule: heredoc BODIES are data and are never rewritten
    # (the 9.5.2 blind verifier caught R9/R10 editing text inside a heredoc).
    lines = command.split("\n")
    hit = set()
    for i, line in first_line_segments(command):
        l2 = re.sub(r"(^|[;&|]\s*)(recall|learn|write-end|read-start)(\s)", r"\1agentdb \2\3", line)
        if l2 != line:
            hit.add("R9")
            line = l2
        l2 = re.sub(r"(?<![A-Za-z0-9_]):!(_[A-Za-z0-9_./-]+)", r":(exclude)\1", line)
        if l2 != line:
            hit.add("R10")
            line = l2
        l2 = re.sub(r"(^|[;&|(]\s*|\s)rg(\s+-[a-zA-Z]*)h(\s|$)", lambda m: f"{m.group(1)}rg{m.group(2).rstrip('-') if m.group(2).strip('-') else ''} --no-filename{m.group(3)}" if m.group(2).strip("-") else f"{m.group(1)}rg --no-filename{m.group(3)}", line)
        if l2 != line:
            hit.add("R11")
            line = l2
        lines[i] = line
    if "R9" in hit:
        notes.append("R9 `recall`/`learn` are agentdb subcommands, rewrote to `agentdb ...`.")
    if "R10" in hit:
        notes.append("R10 git pathspec `:!_x` fails (leading underscore is pathspec magic); rewrote to `:(exclude)_x`.")
    if "R11" in hit:
        notes.append("R11 in ripgrep `-h` is --help; rewrote to `--no-filename`.")
    return "\n".join(lines) if hit else command


def rule_shell_shape_notes(command, notes):
    """R12/R13: shapes that cannot be rewritten safely; say what will happen before it does.
    R12 heredoc inside $(...) (~400 blocks lifetime): both want stdin, the script parses nothing.
    R13 ${x:-{}} closes at the first } and corrupts the payload (~32)."""
    if re.search(r"\$\([^)]*<<", command):
        notes.append("R12 a heredoc inside `$(...)` competes with command substitution for stdin and parses nothing; write the script to a file first, or use `python3 - <<'EOF'` outside the substitution.")
    if re.search(r"\$\{[A-Za-z0-9_]+:-\{\}\}", command):
        notes.append("R13 `${x:-{}}` closes at the first `}` and corrupts the payload; assign the default first (`x=${x:-'{}'}`).")


def rule_pipestatus_zsh(command, notes):
    """R14: the Bash tool runs the login shell. Under zsh `PIPESTATUS` expands to nothing and the
    array is `pipestatus`, indexed from 1. Literal indexes shift by one; `[@]` and `[*]` pass
    through; a non-literal index gets a note, never a guess. Top-level lines only: a heredoc
    body is a script that will run under bash."""
    if not tool_shell_is_zsh():
        return command
    lines = command.split("\n")
    changed = False
    noted = False
    for i, line in first_line_segments(command):
        def fix(m):
            nonlocal changed, noted
            idx = m.group(1)
            if idx in ("@", "*"):
                changed = True
                return "${pipestatus[" + idx + "]"
            if idx.isdigit():
                changed = True
                return "${pipestatus[" + str(int(idx) + 1) + "]"
            noted = True
            return m.group(0)
        new = re.sub(r"\$\{PIPESTATUS\[([^\]]+)\]", fix, line)
        if new != line:
            lines[i] = new
    if changed:
        notes.append("R14 rewrote `${PIPESTATUS[n]}` -> `${pipestatus[n+1]}`: this tool shell is zsh, where the "
                     "array is lowercase and 1-indexed and `PIPESTATUS` expands to nothing. Inside a script run "
                     "by bash, keep `PIPESTATUS` (0-indexed) or use `set -o pipefail`.")
    if noted:
        notes.append("R14 `${PIPESTATUS[<expr>]}` under zsh expands to nothing; the array is `pipestatus`, 1-indexed. Not rewritten (index is not a literal).")
    return "\n".join(lines) if changed else command


def rule_notes_only(command, notes):
    """R6/R7: things we will not rewrite, but the model should hear about BEFORE the call fails."""
    if is_macos() and re.search(r"(^|[|;&(]\s*|\s)grep\s+-[a-zA-Z]*P", command) and not grep_has_P():
        notes.append("R6 grep on this host has no -P (PCRE) and no shim is installed. Use `rg -P '<pattern>'`, "
                     "or `grep -E` for an ERE pattern.")
    for tool, alt in (("timeout", "gtimeout (brew install coreutils) or the Bash tool's own `timeout` parameter"),
                      ("shuf", "gshuf (brew install coreutils) or `sort -R`"),
                      ("tac", "gtac (brew install coreutils) or `tail -r`")):
        if re.search(rf"(^|[|;&(]\s*|\s){tool}\s", command) and not have(tool):
            notes.append(f"R7 `{tool}` is not installed on this host. Use {alt}.")


def main():
    if ENV_OFF:
        return
    try:
        data = json.load(sys.stdin)
    except Exception:
        return
    if data.get("tool_name") not in (None, "Bash"):
        return
    ti = data.get("tool_input") if isinstance(data, dict) else None
    if not isinstance(ti, dict):
        return
    command = ti.get("command")
    if not isinstance(command, str) or not command.strip():
        return
    if "AUTOCORRECT_OFF=1" in command:
        return
    cwd = data.get("cwd") or os.getcwd()
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR") or cwd

    notes = []
    new = command
    new = rule_cd_missing_separator(new, notes)
    new = rule_cd_relative(new, cwd, project_dir, notes)
    new = rule_python(new, notes)
    new = rule_cat_A(new, notes)
    new = rule_sed_i(new, notes)
    new = rule_backticks_in_text_args(new, notes)
    new = rule_house_forms(new, notes)
    new = rule_read_paths(new, cwd, project_dir, notes)
    new = rule_pipestatus_zsh(new, notes)
    rule_shell_shape_notes(new, notes)
    rule_notes_only(new, notes)

    if not notes:
        return
    rewritten = new != command
    context = "[autocorrect-bash] " + " ".join(notes)
    if rewritten:
        context += " The command was executed in its corrected form; write it that way next time."
    payload = {
        "hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": context},
    }
    if rewritten:
        updated = dict(ti)
        updated["command"] = new
        payload["hookSpecificOutput"]["updatedInput"] = updated
        payload["systemMessage"] = "autocorrect-bash: " + "; ".join(n.split(":")[0] for n in notes)
    log({"ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), "rewritten": rewritten,
         "rules": [n[:2] for n in notes], "before": command[:300], "after": new[:300] if rewritten else None})
    out(payload)


if __name__ == "__main__":
    main()
