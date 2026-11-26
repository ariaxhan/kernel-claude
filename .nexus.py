"""Runner workspace for ariaxhan/kernel-claude (interface: nexus-office runner/workspace.py)."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent
NAME = 'kernel'
TITLE = 'KERNEL'
REPOS = ('ariaxhan/kernel-claude',)
INTAKE = ['ariaxhan/kernel-claude']
LANES = 2
PROMPT = ('kernel-claude: the KERNEL plugin (skills, hooks, agents) for Claude, Codex and Gemini. '
          'AGENTS.md and CLAUDE.md are generated: edit governance/kernel.md.tmpl, then run '
          'scripts/generate-governance.py. Verify with tests/run-tests.sh. No em dashes.')


def checkout(repo):
    return ROOT


def prompt(task, body):
    return PROMPT
