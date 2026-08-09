#!/usr/bin/env python3
"""Host adapter tests for KERNEL 9.

Covers required test cases 12, 13, 14, 19 and 20:

  12. Claude adapter loads and routes correctly.
  13. Codex adapter loads and routes correctly.
  14. Unsupported host features are reported truthfully.
  19. Generated adapters remain synchronized from one canonical source.
  20. A stale or missing plugin is surfaced rather than silently ignored.

The load-bearing property here is honesty. A hook bound to an event the host
does not implement is a silent no-op, and a capability table that claims it
works is worse than no table at all.
"""

import importlib.util
import json
import os
import subprocess
import sys
import unittest

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GENERATOR = os.path.join(REPO, "scripts", "generate-adapters.py")
HOSTS_JSON = os.path.join(REPO, "governance", "hosts.json")
CAPABILITY_DOC = os.path.join(REPO, "docs", "kernel-9", "HOST-CAPABILITIES.md")


def _load_generator():
    spec = importlib.util.spec_from_file_location("generate_adapters", GENERATOR)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


GA = _load_generator()


def load(rel):
    with open(os.path.join(REPO, rel)) as fh:
        return json.load(fh)


def spec():
    return load(os.path.join("governance", "hosts.json"))


class CanonicalSourceSync(unittest.TestCase):
    """Requirement 19."""

    def test_adapters_are_in_sync(self):
        proc = subprocess.run(
            [sys.executable, GENERATOR, "--check"],
            capture_output=True, text=True, cwd=REPO,
        )
        self.assertEqual(
            proc.returncode, 0,
            f"adapters drifted from governance/hosts.json:\n{proc.stdout}{proc.stderr}",
        )

    def test_generation_is_deterministic(self):
        """Same source, same bytes. Otherwise --check can never be trusted."""
        first = GA.targets(spec())
        second = GA.targets(spec())
        self.assertEqual(first, second)

    def test_generated_files_end_with_exactly_one_newline(self):
        """Generated output must pass git's whitespace gate."""
        for rel, content in GA.targets(spec()).items():
            with self.subTest(rel=rel):
                self.assertTrue(content.endswith("\n"), f"{rel}: missing final newline")
                self.assertFalse(content.endswith("\n\n"), f"{rel}: blank line at EOF")

    def test_every_generated_file_exists_on_disk(self):
        for rel in GA.targets(spec()):
            with self.subTest(rel=rel):
                self.assertTrue(
                    os.path.isfile(os.path.join(REPO, rel)), f"{rel} was never written"
                )

    def test_versions_agree_across_manifests(self):
        """Requirement 20: a stale manifest must be detectable, not silent."""
        version = load(os.path.join(".claude-plugin", "plugin.json"))["version"]
        for rel in (
            os.path.join(".codex-plugin", "plugin.json"),
            os.path.join(".claude-plugin", "marketplace.json"),
        ):
            with self.subTest(rel=rel):
                doc = load(rel)
                found = doc.get("version") or doc["plugins"][0].get("version")
                if found is not None:
                    self.assertEqual(found, version, f"{rel} pins a stale version")


class ClaudeAdapter(unittest.TestCase):
    """Requirement 12."""

    def setUp(self):
        self.host = spec()["hosts"]["claude"]

    def test_manifest_parses_and_names_the_plugin(self):
        m = load(self.host["plugin_manifest"])
        self.assertEqual(m["name"], "kernel")
        self.assertTrue(m["version"])
        self.assertTrue(m["description"])

    def test_marketplace_uses_the_claude_shape(self):
        mk = load(self.host["marketplace_manifest"])
        self.assertIn("plugins", mk)
        self.assertTrue(mk.get("description"), "Claude warns when marketplace description is absent")
        entry = mk["plugins"][0]
        self.assertEqual(entry["name"], "kernel")
        # Claude takes a bare string source; the structured Codex form is wrong here.
        self.assertIsInstance(entry["source"], str)

    def test_manifest_omits_codex_only_keys(self):
        """Forcing one host through the other's mental model is the failure mode."""
        m = load(self.host["plugin_manifest"])
        for key in ("interface", "skills", "apps", "mcpServers"):
            self.assertNotIn(key, m, f"Claude manifest carries Codex-only key {key!r}")

    def test_normal_requests_reach_the_adaptive_router(self):
        doc = load(self.host["hooks_file"])
        commands = [
            hook["command"]
            for group in doc["hooks"]["UserPromptSubmit"]
            for hook in group["hooks"]
        ]
        self.assertTrue(
            any(command.endswith("/hooks/scripts/route-request.sh") for command in commands),
            "Claude UserPromptSubmit does not reach the Kernel 9 router",
        )


class CodexAdapter(unittest.TestCase):
    """Requirement 13."""

    def setUp(self):
        self.host = spec()["hosts"]["codex"]

    def test_native_manifest_exists_and_parses(self):
        m = load(self.host["plugin_manifest"])
        self.assertEqual(m["name"], "kernel")

    def test_native_manifest_declares_skills_explicitly(self):
        """Codex requires an explicit skills path; Claude infers it."""
        m = load(self.host["plugin_manifest"])
        self.assertEqual(m.get("skills"), "./skills/")
        self.assertTrue(
            os.path.isdir(os.path.join(REPO, "skills")), "declared skills dir is missing"
        )

    def test_native_manifest_carries_the_interface_block(self):
        m = load(self.host["plugin_manifest"])
        iface = m.get("interface")
        self.assertIsNotNone(iface, "Codex manifest needs an interface block")
        for key in ("displayName", "shortDescription", "category", "capabilities"):
            self.assertIn(key, iface)

    def test_marketplace_uses_the_codex_shape(self):
        mk = load(self.host["marketplace_manifest"])
        entry = mk["plugins"][0]
        self.assertIsInstance(entry["source"], dict, "Codex needs a structured source")
        self.assertEqual(entry["source"]["source"], "local")
        self.assertIn("policy", entry)

    def test_policy_authentication_uses_only_valid_variants(self):
        """Codex rejects the entire marketplace file for an unknown variant.

        Regression for a defect found by live installation, not by inspection:
        the generator emitted authentication:"NONE", and Codex 0.145.0 failed
        with `unknown variant NONE, expected ON_INSTALL or ON_USE`. Kernel needs
        no auth, so the key is omitted entirely.
        """
        mk = load(self.host["marketplace_manifest"])
        policy = mk["plugins"][0]["policy"]
        if "authentication" in policy:
            self.assertIn(policy["authentication"], ("ON_INSTALL", "ON_USE"))
        self.assertEqual(policy["installation"], "AVAILABLE")

    def test_hooks_live_at_the_repo_root(self):
        """Codex reads hooks.json at the plugin root, not hooks/hooks.json."""
        self.assertEqual(self.host["hooks_file"], "hooks.json")
        self.assertTrue(os.path.isfile(os.path.join(REPO, "hooks.json")))

    def test_normal_requests_reach_the_adaptive_router(self):
        doc = load(self.host["hooks_file"])
        commands = [
            hook["command"]
            for group in doc["hooks"]["UserPromptSubmit"]
            for hook in group["hooks"]
        ]
        self.assertTrue(
            any(command.endswith("/hooks/scripts/route-request.sh") for command in commands),
            "Codex UserPromptSubmit does not reach the Kernel 9 router",
        )



class EveryHostBindsRealScripts(unittest.TestCase):
    """Both hosts, one check. Not one host's bindings and a promise about the other.

    Two separate defects shipped through the gap this class closes.

    The Claude adapter had a binding-resolves-on-disk test; the Codex adapter
    never did. So when the generator emitted ${CODEX_PLUGIN_ROOT} -- a variable
    Codex does not substitute -- every Codex command expanded to the empty
    string, ran `/hooks/scripts/<name>`, and exited 127 on every lifecycle
    event of every session. The Codex test that existed asserted the invented
    name was present, which is the generator agreeing with itself, so it was
    green for the defect's whole life (#191, #194).

    Parameterizing over governance/hosts.json means a third host cannot opt out
    of this by simply never having a test written for it.
    """

    # The names Codex's hook command runner actually substitutes, read out of
    # the shipped binary's codex_hooks::engine::command_runner string block,
    # plus Claude's own. Anything else expands to empty and exits 127.
    SUBSTITUTED = {"CLAUDE_PLUGIN_ROOT", "PLUGIN_ROOT"}

    def _bindings(self, host):
        doc = load(host["hooks_file"])
        for event, groups in doc["hooks"].items():
            for group in groups:
                for hook in group["hooks"]:
                    yield event, hook["command"]

    def test_every_binding_uses_the_root_var_the_host_declares(self):
        for key, host in spec()["hosts"].items():
            declared = "${%s}" % host["plugin_root_var"]
            for event, cmd in self._bindings(host):
                with self.subTest(host=key, event=event):
                    self.assertTrue(
                        cmd.startswith(declared + "/"),
                        f"{key} {event}: {cmd} does not use declared {declared}",
                    )

    def test_declared_root_var_is_one_the_host_substitutes(self):
        """The declaration itself has to be a real name, not a plausible one."""
        for key, host in spec()["hosts"].items():
            with self.subTest(host=key):
                self.assertIn(
                    host["plugin_root_var"], self.SUBSTITUTED,
                    f"{key} declares {host['plugin_root_var']!r}, which no host "
                    "substitutes; every hook would expand to / and exit 127",
                )

    def test_every_binding_resolves_to_a_script_on_disk(self):
        for key, host in spec()["hosts"].items():
            for event, cmd in self._bindings(host):
                # Strip whatever ${...}/ prefix this host uses, then drop args.
                rel = cmd.split("}/", 1)[1].split()[0]
                with self.subTest(host=key, event=event, script=rel):
                    self.assertTrue(
                        os.path.isfile(os.path.join(REPO, rel)),
                        f"{key} {event} binds missing script {rel}",
                    )

class TruthfulCapabilityReporting(unittest.TestCase):
    """Requirement 14. The heart of the honesty guarantee."""

    def test_no_host_binds_an_event_it_does_not_support(self):
        for key, host in spec()["hosts"].items():
            supported = set(host["supported_lifecycle_events"])
            doc = load(host["hooks_file"])
            for event in doc["hooks"]:
                with self.subTest(host=key, event=event):
                    self.assertIn(
                        event, supported,
                        f"{key} binds {event}, which it does not implement: silent no-op",
                    )

    def test_codex_does_not_bind_post_tool_use_failure(self):
        """The specific defect this slice fixes, pinned as a regression."""
        doc = load("hooks.json")
        self.assertNotIn(
            "PostToolUseFailure", doc["hooks"],
            "Codex 0.145.0 does not implement PostToolUseFailure",
        )

    def test_claude_still_binds_post_tool_use_failure(self):
        """Control: the fix must not degrade the host that does support it."""
        doc = load(os.path.join("hooks", "hooks.json"))
        self.assertIn("PostToolUseFailure", doc["hooks"])

    def test_every_gap_is_documented_with_a_reason(self):
        for key, host in spec()["hosts"].items():
            wanted = set(spec()["kernel_lifecycle_bindings"])
            supported = set(host["supported_lifecycle_events"])
            declared_gaps = set(host.get("unsupported_lifecycle_events", {}))
            actual_gaps = wanted - supported
            with self.subTest(host=key):
                self.assertEqual(
                    actual_gaps, declared_gaps,
                    f"{key}: undocumented capability gap {actual_gaps ^ declared_gaps}",
                )

    def test_gap_explanations_are_substantive(self):
        """A one-word 'unsupported' is not a truthful report."""
        for key, host in spec()["hosts"].items():
            for event, why in host.get("unsupported_lifecycle_events", {}).items():
                with self.subTest(host=key, event=event):
                    self.assertGreater(
                        len(why), 60, f"{key}/{event}: explanation is too thin to be useful"
                    )

    def test_capability_report_names_every_gap(self):
        with open(CAPABILITY_DOC) as fh:
            report = fh.read()
        for key, host in spec()["hosts"].items():
            for event in host.get("unsupported_lifecycle_events", {}):
                with self.subTest(host=key, event=event):
                    self.assertIn(event, report)
                    self.assertIn("**no**", report, "report must mark gaps visibly")

    def test_every_host_declares_its_evidence(self):
        """A capability claim with no named instrument is an assertion."""
        for key, host in spec()["hosts"].items():
            with self.subTest(host=key):
                self.assertTrue(host.get("verified_by"), f"{key}: no evidence named")
                self.assertTrue(host.get("verified_on"), f"{key}: no verification date")
                self.assertGreater(len(host["verified_by"]), 30)

    def test_report_does_not_claim_parity(self):
        with open(CAPABILITY_DOC) as fh:
            report = fh.read().lower()
        for phrase in ("full compatibility", "full parity", "identical support"):
            self.assertNotIn(phrase, report, f"report claims {phrase!r}")


class HostSeparation(unittest.TestCase):
    def test_hosts_have_distinct_adapter_targets(self):
        """Two hosts writing the same file would silently clobber each other."""
        seen = {}
        for key, host in spec()["hosts"].items():
            for field in ("plugin_manifest", "marketplace_manifest", "hooks_file",
                          "instruction_file"):
                path = host[field]
                with self.subTest(path=path):
                    self.assertNotIn(
                        path, seen, f"{key} and {seen.get(path)} both target {path}"
                    )
                seen[path] = key

    def test_invoke_prefixes_differ(self):
        prefixes = {h["invoke_prefix"] for h in spec()["hosts"].values()}
        self.assertEqual(len(prefixes), len(spec()["hosts"]))


if __name__ == "__main__":
    unittest.main(verbosity=2)
