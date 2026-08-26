#!/bin/bash
# PreToolUse hook: block the most dangerous bash commands before they run.
# Events: PreToolUse (matcher: Bash)
#
# SCOPE (honest — this is harm-reduction against accidental agent self-harm, NOT a
# security sandbox). It blocks, on the resulting-state class, three families:
#   1. Repo/VCS destruction  — force-push to main/master, reset --hard, clean -f,
#      branch -D, history rewrite.
#   2. Whole-tree / device destruction — recursive forced rm of root/home, dd/mkfs,
#      raw-disk overwrite, recursive chmod/chown of root/home, find -delete on root/home,
#      mv of root/home itself.
#   3. High-blast external ops — DROP/TRUNCATE SQL, infra teardown (terraform/pulumi/cdk/
#      sst destroy, serverless remove), cloud deletes (wrangler/aws/gcloud/az), and
#      interpreter one-liners that call the same destruction (python -c shutil.rmtree ...).
#   4. (8.2.0) Exfiltration — literal secrets / credential files / keychain reads
#      combined with a network egress tool in one command.
#   5. (8.2.0) Scope escape — --dangerously-skip-permissions spawns, crontab writes,
#      redirects into shell startup files, tampering with the guard or approval tokens.
#   6. (8.2.0) Supply chain — curl|sh, base64|sh, eval-of-download.
# Plus a soft INVESTIGATION gate on rm/rmdir of git submodules and tracked directories.
#
# It does NOT attempt deep deobfuscation (base64|sh, hex/unicode-confusable evasion,
# multi-tool write-then-exec). A determined or prompt-injected agent can evade a text
# guard; the real backstop for that is a sandbox. This gate catches the one-liners an
# LLM emits by accident or when casually working around a block — which is the actual
# failure mode (AgentAbstain 2607.10059: dominant failure is post-hoc irreversible action).
#
# Escape hatches (recovery paths — a block states them so the agent hands off to the
# human instead of reformulating into an evasion):
#   * KERNEL_APPROVE=<code> <cmd> — one-time human approval of a hard block (8.2.0).
#     A block MINTS a code tied to the exact command and writes it to a token file
#     only the human should open; the human re-runs the command with the code. The
#     code never appears in the model-visible stream, so injected instructions
#     cannot forge it. (Replaces DANGER_OK=1, which was a plain substring any
#     injected command could set on itself.)
#   * CONFIRM_DELETE=1 <cmd> — override the rm submodule/tracked-dir investigation gate.
#
# Does NOT source circuit-breaker.sh: a safety gate must always run and must never
# auto-disable itself (I0.15). On a jq-parse failure it WARNS and allows rather than
# blocking every bash command (which would brick the session).

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  # Fail CLOSED. Without a parser this guard cannot tell `ls` from a recursive
  # delete, and kernel's own rule is "when the scanner fails: block". Warning and
  # allowing turned the single most important fence into decor whenever jq went
  # missing -- caught by tests/corpus/run-corpus.py on its first run.
  echo "BLOCKED: destructive-command guard cannot run (jq not found), so no Bash command can be checked." >&2
  echo "  Install jq (brew install jq), then retry. Set KERNEL_GUARD_BASH_DEGRADED_OK=1 to accept an unguarded session." >&2
  [ "${KERNEL_GUARD_BASH_DEGRADED_OK:-0}" = "1" ] && exit 0
  exit 2
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$COMMAND" ] && exit 0

# --- One-time human approval (8.2.0; replaces the forgeable DANGER_OK=1) ---
# On a hard block the guard mints a random code bound to a hash of the exact
# command, stores it under APPROVALS_DIR (0700/0600), and tells the agent to
# surface the block. The HUMAN opens the token file themselves and re-runs the
# command prefixed with KERNEL_APPROVE=<code>. Single-use, short TTL. The token
# path is guarded against agent reads (here, guard-config, guard-context) —
# honest caveat: that is cost-raising, not a sandbox; a multi-step evasion can
# still reach the file. Real containment is the OS sandbox this hook sits inside.
APPROVALS_DIR="${KERNEL_APPROVALS_DIR:-$HOME/.kernel/approvals}"
APPROVAL_TTL_MIN=15

_sha256() { if command -v shasum >/dev/null 2>&1; then shasum -a 256; else sha256sum; fi; }
_cmd_id() { printf '%s' "$1" | _sha256 | awk '{print substr($1,1,16)}'; }

BARE_COMMAND=$COMMAND
APPROVE_CODE=""
case "$COMMAND" in
  KERNEL_APPROVE=*)
    APPROVE_CODE=${COMMAND#KERNEL_APPROVE=}
    APPROVE_CODE=${APPROVE_CODE%%[[:space:]]*}
    BARE_COMMAND=${COMMAND#KERNEL_APPROVE="$APPROVE_CODE"}
    while [ "${BARE_COMMAND# }" != "$BARE_COMMAND" ]; do BARE_COMMAND=${BARE_COMMAND# }; done
    ;;
esac

if [ -n "$APPROVE_CODE" ]; then
  _tok="$APPROVALS_DIR/$(_cmd_id "$BARE_COMMAND").token"
  if [ -f "$_tok" ] && [ -n "$(find "$_tok" -mmin "-$APPROVAL_TTL_MIN" 2>/dev/null)" ] \
     && [ "$(head -n1 "$_tok" 2>/dev/null)" = "$APPROVE_CODE" ]; then
    rm -f "$_tok"   # single-use: consumed on approval
    exit 0          # human-approved — allow this exact command, once
  fi
  echo "BLOCKED: KERNEL_APPROVE code is invalid, expired (${APPROVAL_TTL_MIN}m), already used, or minted for a different command." >&2
  echo "  Re-attempt the bare command to mint a fresh code, then have the HUMAN read the token file and re-run." >&2
  exit 2
fi

# DANGER_OK=1 is retired: it was a substring an injected command could set on itself.
case "$COMMAND" in
  *DANGER_OK=1*)
    echo "guard-bash: DANGER_OK=1 no longer bypasses (retired in 8.2.0 -- forgeable by prompt injection). Hard blocks now mint a KERNEL_APPROVE one-time code for the human." >&2 ;;
esac

# Lowercased, whitespace-collapsed view for case-insensitive keyword matching. Path
# extraction and the rm gate below still use the raw $COMMAND (paths are case-sensitive).
LOW=$(printf '%s' "$COMMAND" | tr '[:upper:]' '[:lower:]' | tr -s '[:space:]' ' ')

# The code view: $COMMAND with the parts that are DATA removed. Every rule matches
# against this or its lowercased twin, never against the raw command, so a rule that
# needs case sensitivity and a rule that does not cannot disagree about what is code.
COMMAND_CODE="$COMMAND"

# Heredoc bodies that are DATA, not code, are dropped before keyword matching. Writing a
# chronicle that mentions a rewrite tool, or filing an issue that quotes a destructive
# command, tripped this guard on prose describing the very rules it enforces.
#
# The exception is load-bearing: when the heredoc feeds a shell or interpreter
# (`bash <<EOF`, `python3 - <<PY`), the body IS executed, so it is kept and matched. That
# is a real bypass vector, and narrowing noise must never open one.
# Same class, different syntax: a guarded keyword inside a quoted ARGUMENT to a command
# that consumes text. Recording a lesson, writing a commit message, or filing an issue
# ABOUT a destructive operation is not performing one, and refusing the description
# teaches people to reword until the guard shuts up -- a habit that costs more than the
# noise it removes.
#
# The distinguishing signal is the RECEIVING command, never the quoting. An argument to
# `git commit -m`, `gh issue comment -b`, or `agentdb learn` is data. An argument to
# `bash -c` or `python3 -c` is code, and those are matched in full, above and below.
_strip_text_arguments() {
  printf '%s' "$1" | awk '
    {
      line = $0
      # Drop the quoted payload that follows a text-consuming flag, keeping the command
      # itself visible so the guard still sees what is being RUN.
      gsub(/(git[[:space:]]+(commit|tag)[^|;&]*-[a-zA-Z]*m|gh[[:space:]]+[a-z-]+[^|;&]*-[a-zA-Z]*(b|body)|agentdb[[:space:]]+(learn|contract|verdict|write-end)([[:space:]]+[a-z-]+)*)[[:space:]]+"[^"]*"([[:space:]]+"[^"]*")*/, " <text> ", line)
      print line
    }'
}
if printf '%s' "$COMMAND" | grep -qE '(git[[:space:]]+(commit|tag)|gh[[:space:]]+[a-z-]+|agentdb[[:space:]]+(learn|contract|verdict|write-end))'; then
  if ! printf '%s' "$COMMAND" | grep -qE '(bash|sh|zsh|ksh|dash|python[0-9.]*|perl|ruby|node)[[:space:]]+-[ce]'; then
    COMMAND_CODE=$(_strip_text_arguments "$COMMAND_CODE")
    LOW=$(printf '%s' "$COMMAND_CODE" | tr '[:upper:]' '[:lower:]' | tr -s '[:space:]' ' ')
  fi
fi

# (9.5.2) An interpreter-fed heredoc is only CODE if its body can execute a subprocess. A python
# script that analyses transcripts and holds the string 'git branch -D' in a literal cannot
# run git; a script that calls subprocess/os.system/child_process/system()/backticks can. Six
# false positives in two weeks came from analysis scripts quoting the very commands this guard
# watches. Bodies without an execution primitive are stripped like any other data heredoc.
_heredoc_feeds_executor() {
  printf '%s' "$COMMAND" | grep -qE '(bash|sh|zsh|ksh|dash)[^|;&]*<<' && return 0
  printf '%s' "$COMMAND" | grep -qE '(python[0-9.]*|perl|ruby|node)[^|;&]*<<' || return 1
  printf '%s' "$COMMAND" | grep -qE 'subprocess|os\.system|os\.popen|os\.exec|shutil\.rmtree|child_process|execSync|spawnSync|spawn\(|exec\(|system\(|Open3|IO\.popen|`[^`]*(rm|git|curl)' && return 0
  return 1
}
if printf '%s' "$COMMAND" | grep -q '<<'; then
  if ! _heredoc_feeds_executor; then
    COMMAND_CODE=$(printf '%s' "$COMMAND_CODE" | awk '
      BEGIN { in_doc = 0 }
      {
        if (in_doc) { if ($0 == term) { in_doc = 0 }; next }
        line = $0
        if (match(line, /<<-?[[:space:]]*'"'"'?[A-Za-z_][A-Za-z0-9_]*'"'"'?/)) {
          term = substr(line, RSTART, RLENGTH)
          gsub(/<<-?[[:space:]]*/, "", term); gsub(/'"'"'/, "", term)
          in_doc = 1
        }
        print line
      }')
    LOW=$(printf '%s' "$COMMAND_CODE" | tr '[:upper:]' '[:lower:]' | tr -s '[:space:]' ' ')
  fi
fi

# block <reason> <recovery-hint> : print a structured refusal + the human approval
# path, mint a one-time code for this exact command, then exit 2.
block() {
  echo "BLOCKED: $1" >&2
  [ -n "$2" ] && echo "  $2" >&2
  _mint_approval
  exit 2
}

_mint_approval() {
  mkdir -p "$APPROVALS_DIR" 2>/dev/null || return 0
  chmod 700 "$APPROVALS_DIR" 2>/dev/null
  find "$APPROVALS_DIR" -name '*.token' -mmin "+$APPROVAL_TTL_MIN" -delete 2>/dev/null
  local tok code
  tok="$APPROVALS_DIR/$(_cmd_id "$BARE_COMMAND").token"
  if [ ! -f "$tok" ]; then   # keep the same code across repeat attempts within the TTL
    code=$(od -An -N4 -tx4 /dev/urandom 2>/dev/null | tr -d ' \n')
    [ -n "$code" ] || return 0
    ( umask 077; { echo "$code"; echo "# approves exactly: $BARE_COMMAND"; } > "$tok" ) 2>/dev/null
  fi
  {
    echo "  This block SURFACES: report it to the human with the reason above."
    echo "  If the HUMAN truly intends this, they (never the agent) open:  $tok"
    echo "  and re-run the exact command prefixed with the code:  KERNEL_APPROVE=<code> <command>"
    echo "  One-time use, expires in ${APPROVAL_TTL_MIN}m. The agent must NOT read that file -- the path is guarded."
  } >&2
}

# --- Self-preservation: approval tokens and the guard's own scripts are off-limits ---
case "$COMMAND" in
  *"$APPROVALS_DIR"*|*".kernel/approvals"*)
    echo "BLOCKED: command references the kernel approval-token store. Approval codes are for the HUMAN to read; the agent never touches that path." >&2
    exit 2 ;;   # deliberately unmintable — no approval code for reading approval codes
esac
printf '%s' "$COMMAND" | grep -qE '\brm\b[^;|&]*(guard-bash|guard-config|guard-context|detect-secrets|scan-output)\.(sh|py)' \
  && { echo "BLOCKED: attempt to delete a kernel security hook. The guard does not remove itself; hand this to the human." >&2; exit 2; }

# --- Block force push to main/master (any flag form, any position) ---
# Catches: --force, -f, --force-with-lease, +refspec, before or after the refspec.
# The force flag AND the main/master target must appear in the SAME `git push`
# segment. Segmenting on shell separators (;|&, matching the rm-gate style below)
# is what stops a force flag elsewhere in a compound command from false-tripping
# -- e.g. `rm -f x && git push origin main` or `git push origin HEAD:main && rm -f y`
# are NOT force pushes and must pass.
while IFS= read -r _seg; do
  echo "$_seg" | grep -qE 'git[[:space:]].*\bpush\b' || continue
  echo "$_seg" | grep -qE '\b(main|master)\b'        || continue
  if echo "$_seg" | grep -qE '(^|[[:space:]])(-f|--force|--force-with-lease)([[:space:]]|=|$)' \
     || echo "$_seg" | grep -qE '[[:space:]]\+[^[:space:]]*(main|master)'; then
      block "Force push to main/master not allowed." \
            "Push to a feature branch and open a PR, or force-push a non-default branch."
  fi
done < <(echo "$COMMAND_CODE" | tr ';|&' '\n')

# --- Other git history/state destruction (reset --hard, clean -f, branch -D, rewrite) ---
printf '%s' "$LOW" | grep -qE 'git +reset +--hard' \
  && block "git reset --hard discards uncommitted work irreversibly." "git stash first if you might want it back."
printf '%s' "$LOW" | grep -qE 'git +clean +-[a-z]*f' \
  && block "git clean -f deletes untracked files irreversibly." "git clean -n to preview what would be removed."
# Case-SENSITIVE on purpose: $LOW has folded -D into -d, so matching it here made the
# safe delete indistinguishable from the destructive one and blocked `git branch -d`
# five times across three sessions in one day. A guard that cries wolf on the safe form
# of a command teaches people to override it, which costs more than it ever saves.
# (9.5.2) -D on a branch that is already merged into HEAD or its upstream drops nothing, and
# that is what 17 of 17 blocked -D calls in two weeks were: post-merge cleanup, each retried
# with -d. Branches that git would refuse to -d are still blocked. Names are checked against
# the repo the command runs in (a `cd X &&` / `git -C X` prefix is honoured).
_branch_D_unmerged() {
  local _seg _dir _names _n _repo
  while IFS= read -r _seg; do
    printf '%s' "$_seg" | grep -qE 'git +(-C +[^ ]+ +)?branch +(-[a-zA-Z]*D|--delete --force|--force --delete)' || continue
    _repo="$PWD"
    _dir=$(printf '%s' "$_seg" | sed -nE 's/.*git +-C +([^ ]+) +branch.*/\1/p')
    [ -n "$_dir" ] && _repo="$_dir"
    _names=$(printf '%s' "$_seg" | sed -E 's/.*git +(-C +[^ ]+ +)?branch +//' | tr ' ' '\n' | grep -vE '^(-|$)' | sed -E "s/^[\"']//; s/[\"']$//")
    [ -n "$_names" ] || return 0
    for _n in $_names; do
      git -C "$_repo" rev-parse --verify -q "refs/heads/$_n" >/dev/null 2>&1 || return 0   # unknown branch: keep the block
      git -C "$_repo" branch --merged HEAD 2>/dev/null | sed 's/^[* +] *//' | grep -qx "$_n" && continue
      _up=$(git -C "$_repo" rev-parse --abbrev-ref "$_n@{upstream}" 2>/dev/null)
      [ -n "$_up" ] && git -C "$_repo" merge-base --is-ancestor "$_n" "$_up" 2>/dev/null && continue
      return 0
    done
  done < <(printf '%s\n' "$COMMAND_CODE" | tr ';|&' '\n')
  return 1
}
_cd_prefix=$(printf '%s' "$COMMAND_CODE" | sed -nE 's/^[[:space:]]*cd[[:space:]]+("[^"]+"|[^[:space:];&|]+).*/\1/p' | head -1 | sed -E "s/^\"//; s/\"$//")
if printf '%s' "$COMMAND_CODE" | grep -qE 'git +(-C +[^ ]+ +)?branch +(-[a-zA-Z]*D|--delete --force|--force --delete)'; then
  if [ -n "$_cd_prefix" ] && [ -d "$_cd_prefix" ]; then
    ( cd "$_cd_prefix" && _branch_D_unmerged ) && block "git branch -D force-deletes a branch (may drop unmerged commits)." "Confirm it's merged, or use -d (safe delete)."
  else
    _branch_D_unmerged && block "git branch -D force-deletes a branch (may drop unmerged commits)." "Confirm it's merged, or use -d (safe delete)."
  fi
fi
printf '%s' "$LOW" | grep -qE 'filter-repo|filter-branch|(^| )bfg( |$)' \
  && block "git history rewrite (filter-repo/filter-branch/bfg) is destructive + non-collaborative." "Verify a backup ref exists first."

# --- Destructive SQL (also catches wrangler d1 execute --command "DROP ...") ---
printf '%s' "$LOW" | grep -qE 'drop +(table|database|schema|index)|truncate +table' \
  && block "destructive SQL (DROP/TRUNCATE) wipes data with no rollback." "Back up / snapshot the table first, or wrap in a reversible migration."

# --- Cloud + infra teardown ---
printf '%s' "$LOW" | grep -qE 'wrangler[[:space:]].*(delete|destroy)' \
  && block "destructive wrangler op (deletes a worker/db/bucket/namespace)." "Confirm the resource name; export/snapshot data first."
printf '%s' "$LOW" | grep -qE '(cdk|terraform|sst|pulumi)[[:space:]]+destroy|serverless[[:space:]]+remove' \
  && block "infrastructure teardown (destroy/remove) tears down live infra." "Run a plan/preview first and confirm the target stack."
printf '%s' "$LOW" | grep -qE 'aws[[:space:]]+.*(terminate-instances|delete-|[[:space:]]rb[[:space:]]|s3[[:space:]]+rm[[:space:]]+--recursive)' \
  && block "destructive AWS CLI op." "Confirm the resource id/bucket; enable a snapshot/versioning safety net."
printf '%s' "$LOW" | grep -qE '(gcloud|az)[[:space:]]+.* delete( |$)' \
  && block "destructive cloud CLI op (gcloud/az delete)." "Confirm the resource; check for a --dry-run/--quiet you did NOT mean to pass."

# --- Disk-format / dd / fork-bomb / raw-device overwrite ---
# `dd` may sit at the START of the command (no leading space); anchor with (^|space).
printf '%s' "$LOW" | grep -qE 'mkfs|(^|[[:space:]])dd[[:space:]]+(if|of)=|:\(\)\{[[:space:]]*:\|:' \
  && block "disk-format / dd / fork-bomb." "These are almost never what an agent should run; hand to the human."
printf '%s' "$LOW" | grep -qE '>[[:space:]]*/dev/(r?disk|sd|nvme|hd)' \
  && block "overwrite of a raw disk device." "Refusing to redirect into a block device."

# --- Recursive forced rm of root or home (common flag orderings) ---
# (9.5.2) Both tests run on COMMAND_CODE (data heredocs stripped) and on the SAME shell
# segment. The old form grepped the raw command for `rm -rf` anywhere and for a bare ` / `
# anywhere else, so `rm -rf "$SCRATCH" && cat > note.md <<'EOF' ... a / b ... EOF` was
# refused as a root wipe (6 false positives in two weeks, zero true ones).
rm_recursive_force() {
  local _s="$1"
  echo "$_s" | grep -qE '\brm\b' || return 1
  echo "$_s" | grep -qE '\brm\b[^;&|]*(-[a-zA-Z]*[rR][a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*[rR])' && return 0
  { echo "$_s" | grep -qE '\brm\b[^;&|]*-[a-zA-Z]*[rR]([[:space:]]|$)' \
    && echo "$_s" | grep -qE '\brm\b[^;&|]*-[a-zA-Z]*f([[:space:]]|$)'; } && return 0
  { echo "$_s" | grep -qE '\brm\b[^;&|]*--recursive' \
    && echo "$_s" | grep -qE '\brm\b[^;&|]*--force'; } && return 0
  echo "$_s" | grep -qE '\brm\b[^;&|]*--no-preserve-root' && return 0
  return 1
}
# Targets root or home ITSELF (not a subdir): / , /* , ~ , ~/ , ~/* , $HOME .
rm_targets_root_home() {
  # Quotes are optional on both sides: `rm -rf "$HOME"` and `rm -rf '/'` are the same wipe.
  # (Pre-existing miss found by the 9.5.2 blind verifier; the regex had required bare whitespace.)
  echo "$1" | grep -qE '(^|[[:space:]])["'"'"']?(/|/\*|~|~/|~/\*|\$HOME/?|\$\{HOME\}/?)["'"'"']?([[:space:]]|$)'
}
while IFS= read -r _seg; do
  if rm_recursive_force "$_seg" && rm_targets_root_home "$_seg"; then
    block "Refusing recursive forced delete of root or home." "Target a specific subdirectory, not / or ~."
  fi
done < <(printf '%s\n' "$COMMAND_CODE" | tr ';|&' '\n')

# --- Recursive chmod/chown of root or home ITSELF (bricks the account/login) ---
if printf '%s' "$LOW" | grep -qE '(chmod|chown)[[:space:]]+(-[a-z]*r|--recursive)'; then
  printf '%s' "$COMMAND" | grep -qE '(chmod|chown)[[:space:]].*[[:space:]]("?/([[:space:]]|$)|~([[:space:]/]|$)|\$HOME|\$\{HOME\})' \
    && block "recursive chmod/chown on root/home." "Scope it to a specific subdirectory."
fi

# --- find -delete / find -exec rm rooted at / ~ or $HOME (whole-tree deletion) ---
if printf '%s' "$LOW" | grep -qE 'find[[:space:]].*(-delete|-exec[[:space:]]+rm)'; then
  printf '%s' "$COMMAND" | grep -qE 'find[[:space:]]+("?/([[:space:]]|$)|~([[:space:]/]|$)|\$HOME|\$\{HOME\})' \
    && block "find -delete/-exec rm rooted at root/home." "Root the find at a specific subdirectory."
fi

# --- mv of root or home ITSELF (e.g. mv ~ /dev/null) -- not a file inside it ---
printf '%s' "$COMMAND" | grep -qE 'mv[[:space:]]+("?/([[:space:]]|$)|~([[:space:]]|$)|\$HOME([[:space:]]|$)|\$\{HOME\})' \
  && block "mv of root/home itself." "Move a specific path, not / or ~."

# --- Interpreter one-liners that call the same destruction (no rm/dd keyword to catch) ---
# python -c / perl -e / node -e / ruby -e whose body does recursive/tree deletion.
# Narrow to TREE deletion (rmtree/removedirs/rimraf/fs.rm*/rm -rf) -- a single-file
# os.remove is not catastrophic and would over-block legitimate scripting.
# Tested per SEGMENT, not across the whole command line. Matching both patterns anywhere
# in one string meant `rm -rf build && python3 -c "print(1)"` was refused as an indirect
# recursive delete: two unrelated commands, one of them already explicit and reviewable,
# which is precisely what this rule exists to prefer.
_after_interpreter=$(printf '%s' "$LOW" | awk '
  { if (match($0, /(python[0-9.]*|perl|ruby|node)[[:space:]]+(-e|-c)/)) print substr($0, RSTART) }')
if [ -n "$_after_interpreter" ]; then
  printf '%s' "$_after_interpreter" | grep -qE 'rmtree|removedirs|rimraf|rmsync|rmdirsync|fs\.rm|rm[[:space:]]+-[a-z]*r[a-z]*f' \
    && block "interpreter one-liner performing recursive/tree deletion." "Refusing indirect recursive rm via python/perl/node/ruby; do it explicitly so it's reviewable."
fi

# --- T3 EXFILTRATION: secret material + network egress in one command (irreversible) ---
# Egress tools that carry data out. ssh/scp identity flags are excluded from the
# credential-path rule below to avoid false-positives on `scp -i ~/.ssh/key` usage.
if printf '%s' "$LOW" | grep -qE '(^|[[:space:];|&(])(curl|wget|nc|ncat|sftp)([[:space:]]|$)'; then
  # A LITERAL secret token inline with an egress tool. Env-var references ($KEY) pass.
  printf '%s' "$COMMAND" | grep -qE 'AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|-----BEGIN[A-Z ]*PRIVATE KEY|eyJ[A-Za-z0-9_-]{17,}\.eyJ' \
    && block "a literal secret appears in the same command as a network egress tool -- exfiltration cannot be undone." "Reference secrets via environment variables (\$VAR), never inline."
  # Credential files fed into the same command as an egress tool (EchoLeak/Nx class).
  # Localhost-only targets are treated as non-egress (downgraded to a warning).
  if printf '%s' "$COMMAND" | grep -qE '(~|\$HOME|\$\{HOME\}|/Users/[^[:space:]/]+|/home/[^[:space:]/]+)/\.(ssh|aws|gnupg|config/gh)/|(^|[[:space:]/=@])\.env([[:space:].,;)]|$)|id_rsa|id_ed25519|id_ecdsa'; then
    if printf '%s' "$LOW" | grep -qE '(curl|wget|nc|ncat)[^;|&]*(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\])'; then
      echo "guard-bash WARN: credential file + network tool in one command (target looks local, allowed). Verify intent." >&2
    else
      block "a credential file (~/.ssh, ~/.aws, .env, private key) is referenced in the same command as a network egress tool." "This is the exfiltration signature (Nx s1ngularity class). Separate the read from any network call, or hand to the human."
    fi
  fi
  # (9.5.2) A keychain read whose value goes into an Authorization header of an https request
  # is AUTHENTICATION, and it is the sanctioned way to use a secret that lives in the keychain
  # (15 of 15 blocked calls in two weeks were exactly this: `K=$(security find-generic-password
  # -s <svc> -w) && curl -H "Authorization: Bearer $K" https://api.<vendor>/...`). Exfiltration
  # is the secret leaving as a BODY or an UPLOAD, or going to a plaintext / raw-socket target.
  if printf '%s' "$LOW" | grep -qE 'security[[:space:]]+find-(generic|internet)-password'; then
    _kc_exfil=0
    printf '%s' "$LOW" | grep -qE '(^|[[:space:];|&(])(nc|ncat|sftp)([[:space:]]|$)' && _kc_exfil=1
    printf '%s' "$LOW" | grep -qE '(curl|wget)[^;|&]*http://' && ! printf '%s' "$LOW" | grep -qE 'http://(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\])' && _kc_exfil=1
    printf '%s' "$LOW" | grep -qE '(curl|wget)[^;|&]*(-d|--data|--data-binary|--data-raw|--data-urlencode|-f |--form|-t |--upload-file|--post-data|--post-file)[^;|&]*(\$|@-|@/dev/stdin)' && _kc_exfil=1
    printf '%s' "$LOW" | grep -qE 'security[[:space:]]+find-(generic|internet)-password[^;&]*\|[^;&]*(curl|wget|nc|ncat)' && _kc_exfil=1
    # Raw host: dotted IPv4, bracketed IPv6, or an all-digit (decimal-encoded) host.
    printf '%s' "$LOW" | grep -qE '(curl|wget)[^;|&]*https?://(\[|[0-9]+([./:"'"'"' ]|$))' && _kc_exfil=1
    # The secret may only travel in a header. A `$` anywhere inside a URL argument means the
    # value (or a substitution of it) is in the query string or path: that is the exfil shape
    # a header rule must refuse, and the shape the 9.5.2 verifier walked straight through.
    printf '%s' "$COMMAND_CODE" | grep -qE '(curl|wget)[^;|&]*https?://[^[:space:]"'"'"']*\$' && _kc_exfil=1
    printf '%s' "$COMMAND_CODE" | grep -qE '(curl|wget)[^;|&]*"https?://[^"]*\$[^"]*"' && _kc_exfil=1
    if [ "$_kc_exfil" = 1 ]; then
      block "keychain read combined with network egress that carries the secret OUT (body/upload, plaintext http, raw ip, or a raw socket)." "Authenticate with an Authorization header over https; never put a keychain value in a request body."
    fi
  fi
fi

# --- T5 SCOPE ESCAPE: permission bypass, silent persistence, auto-executed config ---
# Spawning an agent with its permission system off is the Nx s1ngularity signature.
printf '%s' "$LOW" | grep -qE '[[:space:]]--(dangerously-skip-permissions|yolo|trust-all-tools)([[:space:]=]|$)' \
  && block "spawning a tool with permission checks disabled (--dangerously-skip-permissions / --yolo / --trust-all-tools)." "This flag is how the Nx supply-chain attack weaponized agent CLIs. Run without it."
# crontab write replaces the ENTIRE crontab silently; prior entries are unrecoverable.
if printf '%s' "$LOW" | grep -qE '(^|[[:space:];|&])crontab([[:space:]]|$)'; then
  printf '%s' "$LOW" | grep -qE 'crontab[[:space:]]+-l([[:space:]]|$)' \
    || block "crontab write (replaces the whole crontab silently; installs scheduled code)." "crontab -l to inspect first; persistence changes go through the human."
fi
# Redirect into a shell startup file = code that auto-runs on every future shell.
printf '%s' "$COMMAND" | grep -qE '>>?[[:space:]]*"?(~|\$HOME|\$\{HOME\}|/Users/[^[:space:]/]+|/home/[^[:space:]/]+)?/?\.(bashrc|zshrc|zshenv|zprofile|profile|bash_profile)"?([[:space:]]|$)' \
  && block "redirect into a shell startup file (auto-executed on every shell -- silent persistence)." "Show the human the exact line; they add it, or approve this command."

# --- T6 SUPPLY CHAIN: pipe-to-shell and obfuscated execution ---
printf '%s' "$LOW" | grep -qE '(curl|wget)[^;|&]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z|da)?sh([[:space:]]|$)' \
  && block "piping a downloaded script straight into a shell (curl|sh) executes unreviewed remote code." "Download to a file first (curl -o install.sh URL), read it, then run it."
printf '%s' "$LOW" | grep -qE 'base64[[:space:]]+(-d|--decode)[^;|&]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z|da)?sh([[:space:]]|$)' \
  && block "piping base64-decoded content into a shell (obfuscated execution)." "Decode to a file and inspect it before running anything."
printf '%s' "$LOW" | grep -qE 'eval[[:space:]]+.?["$(]*(curl|wget)[[:space:]]' \
  && block "eval of downloaded content executes unreviewed remote code." "Fetch to a file, inspect, then run."

# --- Investigation gate: rm/rmdir of git submodules or tracked directories ---
# NOT a hard block. Surfaces what the target actually IS and requires a conscious
# CONFIRM_DELETE=1 re-issue, so an uninitialized submodule (an empty folder is
# uninitialized, NOT junk) or a whole tracked directory can't be removed on a
# tidy-up reflex. Scope is deliberately narrow -- submodules always; tracked
# paths only when it's a directory or a recursive rm -- so routine single-file
# `rm file.ts` (recoverable from git history) is never nagged.
# (vault rule: Vaults/.claude/rules/invariants.md -> "Destructive & structural ops")
if echo "$COMMAND" | grep -qE '(^|[^[:alnum:]_./-])(rm|rmdir)([[:space:]]|$)' \
   && ! echo "$COMMAND" | grep -qE '(^|[[:space:]])CONFIRM_DELETE=1([[:space:]]|$)'; then
  _recursive=0
  echo "$COMMAND" | grep -qE '\brm\b[^;&|]*(-[a-zA-Z]*[rR]|--recursive)' && _recursive=1
  echo "$COMMAND" | grep -qE '\brmdir\b' && _recursive=1
  # Candidate path tokens: per rm/rmdir segment, drop the command word + flags.
  _paths=$(echo "$COMMAND" | tr ';|&' '\n' \
    | grep -E '(^|[^[:alnum:]_./-])(rm|rmdir)([[:space:]])' \
    | sed -E 's/.*\b(rm|rmdir)[[:space:]]+//' \
    | tr ' \t' '\n' \
    | grep -vE '^(-|$)' \
    | sed -E "s/^[\"']//; s/[\"']$//")
  for _p in $_paths; do
    case "$_p" in /tmp/*|/var/folders/*|/private/var/*) continue;; esac
    [ -n "$_p" ] || continue
    # Submodule? mode 160000 is present in the index even for an uninitialized,
    # empty submodule folder -- the exact case that broke modelmind.
    if git ls-files --stage -- "$_p" 2>/dev/null | grep -q '^160000'; then
      echo "HALT -- investigate before deleting: '$_p' is a GIT SUBMODULE." >&2
      echo "  An empty submodule folder is UNINITIALIZED, not junk; deleting it breaks the parent repo." >&2
      echo "  Look:     git ls-files --stage -- '$_p'   (160000 = submodule)   |   cat .gitmodules" >&2
      echo "  Restore:  git submodule update --init -- '$_p'   (populate it in place -- do NOT re-clone elsewhere)" >&2
      echo "  If you have verified and truly intend to remove it, re-run with:  CONFIRM_DELETE=1 <cmd>" >&2
      exit 2
    fi
    # Tracked directory, or recursive rm of tracked content?
    if [ -n "$(git ls-files -- "$_p" 2>/dev/null | head -1)" ] && { [ -d "$_p" ] || [ "$_recursive" = 1 ]; }; then
      echo "HALT -- investigate before deleting: '$_p' is TRACKED in git (directory / recursive rm)." >&2
      echo "  Confirm it's safe:  git ls-files -- '$_p' | head   |   grep -rn '$(basename "$_p")' --include='*.sh' --include='*.ts' --include='*.js' --include='*.json' ." >&2
      echo "  Prefer:  git rm -r '$_p'  (keeps history)  -- or  git restore  if you meant to undo working changes." >&2
      echo "  If verified and intended, re-run with:  CONFIRM_DELETE=1 <cmd>" >&2
      exit 2
    fi
  done
fi

exit 0
