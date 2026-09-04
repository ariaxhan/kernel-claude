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

    def test_codex_reads_the_shared_hooks_manifest(self):
        """Codex reads hooks/hooks.json, and says so itself in two places.

        This test used to assert the opposite, docstring included: "Codex reads
        hooks.json at the plugin root, not hooks/hooks.json". It passed for months
        because it only checked that the root file existed and that hosts.json
        agreed with it, so it pinned a belief rather than a behaviour, and the
        root manifest it defended was never loaded once.

        The evidence for the correction, both from codex-cli 0.150.1:
          - the startup warning names the file when it clamps a timeout:
            `clamping SessionEnd hook timeout to 3s in <plugin>/hooks/hooks.json`,
            and only that file declared the 210 being clamped;
          - Codex's own trust store keys our hooks as
            `kernel@kernel-marketplace:hooks/hooks.json:<event>:<group>:<index>`.
        """
        self.assertEqual(self.host["hooks_file"], os.path.join("hooks", "hooks.json"))
        self.assertTrue(os.path.isfile(os.path.join(REPO, "hooks", "hooks.json")))
        self.assertFalse(
            os.path.exists(os.path.join(REPO, "hooks.json")),
            "the root hooks.json is back. Codex never read it, so anything fixed "
            "there is a fix that does not happen: #199 corrected a SessionEnd "
            "timeout in that file and the warning kept firing every session.",
        )

    def test_the_shared_manifest_names_a_root_var_both_hosts_substitute(self):
        """One file, so one variable, and it has to be one both hosts expand.

        An unknown name expands to the empty string and every hook runs an absolute
        path off / and exits 127, which is what CODEX_PLUGIN_ROOT did to every Codex
        session until #191. Emitting each host's own spelling into a SHARED file has
        a second failure mode found while writing this: the same hook appears twice,
        once per spelling, and the whole chain runs twice.
        """
        doc = load(os.path.join("hooks", "hooks.json"))
        shared = "${%s}" % spec()["shared_plugin_root_var"]
        commands = [
            hook["command"]
            for groups in doc["hooks"].values()
            for group in groups
            for hook in group["hooks"]
        ]
        self.assertTrue(commands)
        for command in commands:
            with self.subTest(command=command):
                self.assertTrue(
                    command.startswith(shared),
                    f"hook command does not use the shared plugin-root variable {shared}",
                )
        self.assertEqual(
            len(commands), len(set(commands)),
            "a hook command is duplicated in the shared manifest, so it will run twice",
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

    def test_every_binding_uses_a_root_var_every_host_substitutes(self):
        """One shared manifest means one variable, and every host must expand it.

        This used to require each host's OWN declared spelling, which was right
        while each host had its own file. With one shared file that rule is not
        just wrong, it is actively harmful: emitting both spellings puts the same
        hook in the file twice and the whole chain runs twice. Found by doing it.

        The rule that survives is the one #191 paid for. A name the host does not
        substitute expands to the empty string, so the hook runs an absolute path
        off / and exits 127, silently, on every session.
        """
        shared = spec()["shared_plugin_root_var"]
        self.assertIn(
            shared, self.SUBSTITUTED,
            f"the shared manifest names {shared!r}, which no host substitutes",
        )
        for key, host in spec()["hosts"].items():
            with self.subTest(host=key):
                self.assertIn(
                    shared, self.SUBSTITUTED,
                    f"{key} does not substitute the shared root var {shared!r}",
                )
            for event, cmd in self._bindings(host):
                with self.subTest(host=key, event=event):
                    self.assertTrue(
                        cmd.startswith("${%s}/" % shared),
                        f"{key} {event}: {cmd} does not use the shared {shared}",
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

    def test_every_binding_resolves_to_a_shipped_executable(self):
        bound = set()
        for key, host in spec()["hosts"].items():
            for event, cmd in self._bindings(host):
                # Strip whatever ${...}/ prefix this host uses, then drop args.
                rel = cmd.split("}/", 1)[1].split()[0]
                with self.subTest(host=key, event=event, script=rel):
                    path = os.path.join(REPO, rel)
                    self.assertTrue(os.path.isfile(path), f"{key} {event} binds missing script {rel}")
                    self.assertTrue(os.access(path, os.X_OK), f"{key} {event} binds non-executable script {rel}")
                    bound.add(rel)

        registry = load(os.path.join("hooks", "gates.json"))
        declared = {
            hook["script"] for hook in registry["hooks"] if hook["class"] != "library"
        }
        self.assertEqual(bound, declared, "manifest and shipped hook registry diverge")

class HostEnforcedTimeoutCeilings(unittest.TestCase):
    """A timeout the host overrules is a claim, not a budget.

    Codex hard-clamps SessionEnd hooks to 3s and says so on every session start:
    `clamping SessionEnd hook timeout to 3s`. Kernel bound session-end.sh at 210
    because it runs the project's test suite there. The declared budget was 70x
    the real one, the gate was killed every time, and both hosts.json and the
    capability report said a flat "yes" for SessionEnd on Codex.

    hosts.json's own header calls that shape of claim the thing it exists to
    prevent, so the ceiling now lives there with named evidence, the generator
    emits the real number, and the report says "yes, capped at 3s".
    """

    def test_no_binding_declares_a_timeout_above_its_host_ceiling(self):
        for key, host in spec()["hosts"].items():
            ceilings = host.get("hook_timeout_ceilings_seconds", {})
            if not ceilings:
                continue
            doc = load(host["hooks_file"])
            for event, groups in doc["hooks"].items():
                limit = ceilings.get(event)
                if limit is None:
                    continue
                for group in groups:
                    for hook in group["hooks"]:
                        with self.subTest(host=key, event=event):
                            if hook["timeout"] <= limit:
                                continue
                            # A shared manifest cannot satisfy two different
                            # ceilings. Codex clamps SessionEnd to 3s and SAYS SO on
                            # every session; Claude Code needs the full 210s for the
                            # session-end batch commit. Emitting 3 to spare one
                            # warning would silently truncate the other host's hook,
                            # which is the worse of the two failures.
                            #
                            # So an over-ceiling timeout is allowed only where the
                            # host enforces the ceiling itself AND the evidence for
                            # that enforcement is on the record.
                            self.assertTrue(
                                host.get("hook_timeout_ceiling_evidence", "").strip(),
                                f"{key} {event} declares {hook['timeout']}s over a "
                                f"{limit}s ceiling with no evidence that the host "
                                "enforces the ceiling itself",
                            )

    def test_every_declared_ceiling_carries_evidence(self):
        """Same rule the file already applies to supported_lifecycle_events."""
        for key, host in spec()["hosts"].items():
            if not host.get("hook_timeout_ceilings_seconds"):
                continue
            with self.subTest(host=key):
                evidence = host.get("hook_timeout_ceiling_evidence", "")
                self.assertGreater(
                    len(evidence), 60,
                    f"{key} declares a timeout ceiling with no substantive evidence",
                )

    def test_capability_report_does_not_call_a_capped_event_a_flat_yes(self):
        doc = open(os.path.join(REPO, CAPABILITY_DOC)).read() if os.path.isabs(CAPABILITY_DOC) \
            else open(CAPABILITY_DOC).read()
        for key, host in spec()["hosts"].items():
            for event, limit in host.get("hook_timeout_ceilings_seconds", {}).items():
                with self.subTest(host=key, event=event):
                    self.assertIn(
                        f"capped at {limit}s", doc,
                        f"{event} is capped at {limit}s on {key} but the report "
                        "does not say so",
                    )

class TruthfulCapabilityReporting(unittest.TestCase):
    """Requirement 14. The heart of the honesty guarantee."""

    def test_every_event_a_host_cannot_run_is_written_down(self):
        """A shared manifest means a host WILL see events it does not implement.

        The old rule, "no host binds an event it does not support", assumed a file
        per host. It cannot hold for a shared one: Claude Code needs
        PostToolUseFailure and Codex does not implement it, and dropping the binding
        to satisfy Codex would break the host that works.

        What must hold instead is that the gap is recorded with a reason, so the
        degradation is a decision someone can read rather than a surprise. An
        undocumented event in the manifest still fails here.
        """
        for key, host in spec()["hosts"].items():
            supported = set(host["supported_lifecycle_events"])
            documented = host.get("unsupported_lifecycle_events", {})
            doc = load(host["hooks_file"])
            for event in doc["hooks"]:
                if event in supported:
                    continue
                with self.subTest(host=key, event=event):
                    self.assertIn(
                        event, documented,
                        f"{key} binds {event}, which it does not implement, and the "
                        "gap is not recorded in unsupported_lifecycle_events",
                    )
                    self.assertTrue(
                        documented[event].strip(),
                        f"{key} records {event} as unsupported with no reason",
                    )

    def test_codex_declares_post_tool_use_failure_as_a_known_no_op(self):
        """Reworked: the manifest is shared, so the gap lives in the record.

        This used to assert PostToolUseFailure was absent from a Codex-only
        manifest. That manifest was never loaded, and the shared file Codex does
        read has carried the binding all along without harm: Codex ignores an event
        it does not implement. Removing it would break Claude Code, which does.

        What must stay true is that the gap is WRITTEN DOWN with its reason, so the
        degraded error capture on this host is a recorded decision and not a
        surprise.
        """
        gaps = spec()["hosts"]["codex"].get("unsupported_lifecycle_events", {})
        self.assertIn("PostToolUseFailure", gaps)
        self.assertTrue(gaps["PostToolUseFailure"].strip())
        self.assertNotIn(
            "PostToolUseFailure",
            set(spec()["hosts"]["codex"]["supported_lifecycle_events"]),
        )

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
        """Two hosts writing the same file would silently clobber each other.

        hooks_file is deliberately excluded: it is shared, and the generator merges
        into it rather than overwriting, which
        test_the_shared_manifest_names_a_root_var_both_hosts_substitute checks by
        asserting no command appears twice. Everything else is still per host.
        """
        seen = {}
        for key, host in spec()["hosts"].items():
            for field in ("plugin_manifest", "marketplace_manifest",
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
