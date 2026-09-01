#!/usr/bin/env python3
"""Measure whether routing to skills actually changed anything.

The 2026-09-01 usage audit could establish that skills were not being used
(12 of 26 never invoked across 9,642 Claude sessions, 5 human invocations in
all of history). It could not establish whether any fix worked, because the
only recorded event was an invocation. A suggestion that was ignored left no
trace, so there was no denominator and therefore no rate.

route-request.sh now writes the suggestion side to _meta/logs/skill-routing.jsonl.
This joins that against the Skill tool calls in the session transcripts and
prints the adoption rate per skill: of the times a skill was suggested, how
often did the agent then actually invoke it in the same session.

Read the output as a diagnosis of the SIGNALS, not of the agent. A skill with
many suggestions and no invocations is usually a regex matching prompts the
skill does not really serve, and the fix is to narrow the regex, not to nag.

Usage:
  scripts/skill-adoption.py [--log PATH] [--transcripts DIR] [--since YYYY-MM-DD]
"""

import argparse
import collections
import json
import os
import sys

DEFAULT_LOG = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "_meta", "logs", "skill-routing.jsonl")
DEFAULT_TRANSCRIPTS = os.path.expanduser("~/.claude/projects")


def load_suggestions(path, since):
    """One row per prompt that produced a suggestion."""
    rows = []
    if not os.path.exists(path):
        return rows
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
            except ValueError:
                continue
            if since and row.get("ts", "") < since:
                continue
            if row.get("suggested"):
                rows.append(row)
    return rows


def invoked_skills_by_session(transcripts):
    """session_id -> set of kernel skills actually invoked via the Skill tool.

    Deliberately a substring scan rather than a full JSON parse of every line:
    the corpus is gigabytes, the transcripts are one JSON object per line with
    no stable schema across host versions, and a false positive here is a
    skill we credit as adopted when it was only mentioned. That biases the
    number UP, so treat the result as a ceiling and say so in any report.
    """
    seen = collections.defaultdict(set)
    if not os.path.isdir(transcripts):
        return seen
    needle = '"skill":"kernel:'
    for root, _dirs, files in os.walk(transcripts):
        for name in files:
            if not name.endswith(".jsonl"):
                continue
            session = os.path.splitext(name)[0]
            try:
                with open(os.path.join(root, name), encoding="utf-8",
                          errors="replace") as fh:
                    for line in fh:
                        start = 0
                        while True:
                            i = line.find(needle, start)
                            if i < 0:
                                break
                            j = i + len(needle)
                            end = line.find('"', j)
                            if end > j:
                                seen[session].add(line[j:end])
                            start = j
            except OSError:
                continue
    return seen


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--log", default=DEFAULT_LOG)
    ap.add_argument("--transcripts", default=DEFAULT_TRANSCRIPTS)
    ap.add_argument("--since", default=None, help="ISO date, e.g. 2026-09-01")
    args = ap.parse_args()

    suggestions = load_suggestions(args.log, args.since)
    if not suggestions:
        print("no suggestions recorded yet at %s" % args.log)
        print("this is the expected state until route-request.sh has run with a "
              "skill table present; it is not an error.")
        return 0

    invoked = invoked_skills_by_session(args.transcripts)

    offered = collections.Counter()
    taken = collections.Counter()
    for row in suggestions:
        session = row.get("session", "")
        got = invoked.get(session, set())
        for skill in row["suggested"]:
            offered[skill] += 1
            if skill in got:
                taken[skill] += 1

    width = max(len(s) for s in offered)
    print("%-*s  %8s  %8s  %7s" % (width, "skill", "suggested", "invoked", "rate"))
    print("-" * (width + 28))
    for skill, n in offered.most_common():
        hit = taken[skill]
        print("%-*s  %8d  %8d  %6.0f%%" % (width, skill, n, hit, 100.0 * hit / n))

    total_n = sum(offered.values())
    total_hit = sum(taken.values())
    print("-" * (width + 28))
    print("%-*s  %8d  %8d  %6.0f%%" % (width, "ALL", total_n, total_hit,
                                       100.0 * total_hit / total_n))
    print()
    print("Invocation counts are a CEILING: the transcript scan credits a skill "
          "whose name appears in a Skill tool call anywhere in the session, not "
          "necessarily one caused by the suggestion.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
