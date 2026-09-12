import importlib.util, json, tempfile, unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location('rd', Path(__file__).parents[1] / 'hooks/scripts/repeat-detector.py')
rd = importlib.util.module_from_spec(spec); spec.loader.exec_module(rd)


def transcript(rows):
    f = tempfile.NamedTemporaryFile('w', suffix='.jsonl', delete=False)
    f.write('\n'.join(json.dumps(r) for r in rows)); f.close()
    return f.name


def claude(text):
    return {'type': 'user', 'message': {'role': 'user', 'content': text}}


def codex(text):
    return {'type': 'response_item', 'payload': {'type': 'message', 'role': 'user', 'content': [{'type': 'input_text', 'text': text}]}}


EARLIER = 'ensure we see the full pngs never just html and apply it to codex too'


class RepeatDetector(unittest.TestCase):
    def test_restated_request_claude_and_codex(self):
        for row in (claude, codex):
            earlier = rd.user_prompts(transcript([row(EARLIER), row('rejected is good yes')]))
            self.assertIn(EARLIER, earlier)
            self.assertIsNotNone(rd.detect('make sure we see the full pngs, never just html, codex too', earlier))

    def test_said_phrase(self):
        self.assertIsNotNone(rd.detect('I already said use the tbs cli', ['use the tbs cli']))

    def test_new_request_passes(self):
        self.assertIsNone(rd.detect('add rejected ideas to the handoff schema please', [EARLIER]))
        self.assertIsNone(rd.detect('ok', [EARLIER]))

    def test_hook_system_text_ignored(self):
        self.assertEqual(rd.user_prompts(transcript([claude('<system-reminder>x</system-reminder>')])), [])


if __name__ == '__main__':
    unittest.main()
