#!/usr/bin/env python3
"""UserPromptSubmit hook (Claude and Codex): when the user restates an earlier request or says they
already said it, the session has lost context. Inject a recovery order and ledger the event.
Input: hook JSON on stdin with prompt + transcript_path. Output: context text on stdout."""
import json, os, re, sys, time

SAID = re.compile(r"\b(i (already|just) (said|told|asked)|as i (said|mentioned)|like i said|i told you|"
                  r"again,|still (not|wrong|broken)|as (we|i) (already )?agreed|you forgot|we already|i keep (saying|asking))", re.I)
WORD = re.compile(r"[\w가-힣]{3,}")
LEDGER = os.path.expanduser('~/Developer/Vaults/_meta/ledgers/context-loss.jsonl')


def words(text):
    return {w.lower() for w in WORD.findall(text)}


def user_prompts(path):
    """Earlier user-typed prompts, oldest first, from a Claude or Codex transcript."""
    out = []
    with open(path, encoding='utf8', errors='ignore') as f:
        lines = f.readlines()
    for line in lines:
        if '"user"' not in line:
            continue
        try:
            d = json.loads(line)
        except ValueError:
            continue
        msg = d.get('message') if d.get('type') == 'user' else d.get('payload')
        if not isinstance(msg, dict) or msg.get('role') != 'user':
            continue
        c = msg.get('content')
        parts = [c] if isinstance(c, str) else [x.get('text', '') for x in c or [] if isinstance(x, dict)
                                                 and x.get('type') in ('text', 'input_text')]
        text = ' '.join(parts).strip()
        if text and not text.startswith(('<', '#', '[Request', '[Image', 'Stop hook', 'This session is being continued', 'Goal check-in')) and (not out or out[-1] != text):
            out.append(text)
    return out


def detect(prompt, earlier):
    """Return (reason, earlier_text) or None."""
    if len(prompt) < 600 and SAID.search(prompt):
        return 'user says it was already said', earlier[-1] if earlier else ''
    new = words(prompt)
    if len(new) < 6:
        return None
    for old in reversed([e for e in earlier if words(e) != new]):
        ow = words(old)
        if len(ow) >= 6 and len(new & ow) / len(new | ow) >= 0.55:
            return 'user restated an earlier request', old
    return None


def main():
    try:
        hook = json.load(sys.stdin)
    except ValueError:
        return
    prompt, t = hook.get('prompt') or '', hook.get('transcript_path') or ''
    if not prompt:
        return
    hit = detect(prompt, user_prompts(t) if os.path.isfile(t) else [])
    if not hit:
        return
    reason, old = hit
    try:
        os.makedirs(os.path.dirname(LEDGER), exist_ok=True)
        with open(LEDGER, 'a') as f:
            f.write(json.dumps({'ts': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()), 'cwd': os.getcwd(),
                                'transcript': t, 'reason': reason, 'prompt': prompt[:200]}) + '\n')
    except OSError:
        pass
    print(f"CONTEXT LOSS: {reason}. Earlier: \"{old[:300]}\"\n"
          "Before answering: 1) re-read that earlier exchange and what you did with it; "
          "2) name in one line what you dropped; 3) do the dropped thing, without re-explaining; "
          "4) if the session is long or this is the second loss, write a kernel.handoff/v1 "
          "(alternatives_rejected included) and recommend a fresh session. No apology.")


if __name__ == '__main__':
    main()
