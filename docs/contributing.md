# Contributing

Use the checkout directly instead of modifying a numbered cache directory:

```bash
git clone https://github.com/ariaxhan/kernel-claude.git
cd kernel-claude
claude --plugin-dir ./
./tests/run-tests.sh
```

To also set up AgentDB and the helper links against the checkout:

```bash
./scripts/kernel-setup.sh
```

With no installed cache present, setup selects the checkout as the runtime. If you already
have KERNEL installed, setup prefers the installed cache; pass `KERNEL_RUNTIME_ROOT` to force
the checkout.

Reload or start a new development session after plugin-structure changes. Do not replace
installed cache directories with development symlinks.

## Architecture references

- [KERNEL instructions](../CLAUDE.md): the loaded governance document.
- [Setup guide](QUICKSTART.md): the longer prose walkthrough of installation and first use.
- [8.0 migration](MIGRATION-8.md)
- [Manifest schemas](../schemas/)
- [Workflow definitions](../workflows/)
- [Changelog](../CHANGELOG.md)
- [Skill template](skill-template.md)
- [Branch protection](BRANCH-PROTECTION.md)
