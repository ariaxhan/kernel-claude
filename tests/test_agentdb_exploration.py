"""Exercise the CLI against disposable databases, never the fleet stores."""
import os
from pathlib import Path
import sqlite3
import subprocess
import tempfile
import unittest

CLI = Path(__file__).resolve().parents[1] / 'orchestration/agentdb/agentdb'


class ExplorationTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.env = dict(os.environ, AGENTDB_ROOT=self.tmp.name)
        self.run_cli('init')
        self.db = sqlite3.connect(Path(self.tmp.name) / '_meta/agentdb/agent.db')
        for i in range(12):
            self.db.execute("INSERT INTO learnings(id,type,insight,hit_count,load_count,ts) VALUES(?, 'pattern', ?, ?, 0, datetime('now','-60 days'))", (f'h{i}', f'quartz nebula popular {i}', 1000 + i))
        for i in range(6):
            self.db.execute("INSERT INTO learnings(id,type,insight,hit_count,load_count,ts) VALUES(?, 'pattern', ?, 0, 0, datetime('now','-60 days'))", (f'l{i}', f'quartz nebula tail {i}'))
        self.db.commit()
        self.run_cli('preflight')

    def tearDown(self):
        self.db.close()
        self.tmp.cleanup()

    def run_cli(self, *args):
        return subprocess.check_output([str(CLI), *args], env=self.env, text=True)

    def test_exploration_reaches_tail_without_mutation(self):
        before = self.db.execute('SELECT sum(hit_count) FROM learnings').fetchone()
        ids = self.run_cli('recall', 'quartz nebula', '--ids').splitlines()
        self.assertEqual(8, len(ids))
        self.assertTrue(any(i.startswith('l') for i in ids))
        self.assertEqual(ids, self.run_cli('recall', 'quartz nebula', '--ids').splitlines())
        self.assertEqual(before, self.db.execute('SELECT sum(hit_count) FROM learnings').fetchone())

    def test_no_relevant_tail_leaves_reserved_slot_empty(self):
        self.db.execute("UPDATE learnings SET insight='quartz unrelated' WHERE id LIKE 'l%'")
        self.db.commit()
        self.run_cli('preflight')
        ids = self.run_cli('recall', 'quartz nebula', '--ids').splitlines()
        self.assertEqual(7, len(ids))
        self.assertTrue(all(i.startswith('h') for i in ids))

    def test_preamble_rotates_two_tail_slots(self):
        outputs = [self.run_cli('read-start', '--summary') for _ in range(3)]
        for output in outputs:
            self.assertEqual(2, output.count('quartz nebula tail'))
        self.assertEqual(6, self.db.execute("SELECT count(*) FROM learnings WHERE id LIKE 'l%' AND load_count > 0").fetchone()[0])

    def test_empty_preamble_returns_success(self):
        self.db.execute('DELETE FROM learnings')
        self.db.commit()
        self.assertNotIn('- [pattern]', self.run_cli('read-start', '--summary'))

    def test_exploration_prefers_more_query_terms(self):
        self.db.execute("UPDATE learnings SET insight='quartz nebula' WHERE id LIKE 'l%'")
        self.db.execute("UPDATE learnings SET insight='quartz nebula pulsar' WHERE id='l5'")
        self.db.commit()
        self.run_cli('preflight')
        ids = self.run_cli('recall', 'quartz nebula pulsar', '--ids').splitlines()
        self.assertEqual('l5', ids[-1])

    def test_best_tail_is_not_truncated_before_term_scoring(self):
        self.db.execute("DELETE FROM learnings WHERE id LIKE 'l%'")
        for i in range(60):
            self.db.execute("INSERT INTO learnings(id,type,insight,hit_count) VALUES(?, 'pattern', 'quartz nebula', 0)", (f't{i}',))
        self.db.execute("INSERT INTO learnings(id,type,insight,hit_count) VALUES('best', 'pattern', ?, 0)", ('quartz nebula pulsar ' + 'filler ' * 1000,))
        self.db.commit()
        self.run_cli('preflight')
        self.assertEqual('best', self.run_cli('recall', 'quartz nebula pulsar', '--ids').splitlines()[-1])

    def test_prune_is_reversible_and_respects_loads(self):
        self.db.execute("UPDATE learnings SET load_count=1 WHERE id='l0'")
        self.db.execute("UPDATE learnings SET ts=datetime('now','-20 days') WHERE id='l1'")
        self.db.commit()
        self.run_cli('prune', 'learnings')
        self.assertEqual(18, self.db.execute('SELECT count(*) FROM learnings').fetchone()[0])
        self.assertEqual(4, self.db.execute('SELECT count(*) FROM learnings WHERE archived_at IS NOT NULL').fetchone()[0])
        self.assertEqual(4, self.db.execute("SELECT count(*) FROM memory_events WHERE kind='archived'").fetchone()[0])
        self.run_cli('resurrect', 'l2')
        self.assertIsNone(self.db.execute("SELECT archived_at FROM learnings WHERE id='l2'").fetchone()[0])


if __name__ == '__main__':
    unittest.main()
