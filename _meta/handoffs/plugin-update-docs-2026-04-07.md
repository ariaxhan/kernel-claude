## CONTEXT HANDOFF
Generated: 2026-04-07

**Summary**: Added plugin update documentation to README and QUICKSTART, fixed marketplace version mismatch.

**Goal**: Document how to update the KERNEL plugin, fix wrong commands in docs, address users stuck on old versions.

**Current state**: All changes made, uncommitted. 3 files modified, ready to commit and push.

**Branch**: main (dirty — 3 modified files)

**Tier**: 1 - brief (3 file edits, all docs)

**Decisions made**:
- Replaced fake `/plugin marketplace refresh` with real commands: `/plugin marketplace update`, `/plugin update`, `/reload-plugins` — confirmed via Claude Code docs
- Added auto-update toggle instructions — this is the real fix for stuck users going forward
- Added nuclear option (uninstall/reinstall) for badly stuck installs
- Synced marketplace.json 7.10.0 → 7.11.0 to match plugin.json

**Artifacts modified**:
- `.claude-plugin/marketplace.json`: version 7.10.0 → 7.11.0
- `README.md`: new "Updating KERNEL" section + fixed troubleshooting
- `docs/QUICKSTART.md`: replaced update section + fixed all stale commands

**Big 5 Status**:
- [x] Input validation - n/a (docs only)
- [x] Edge cases - covered stuck-version scenario
- [x] Error handling - n/a
- [x] Duplication - same update instructions in both README and QUICKSTART
- [x] Complexity - n/a

**Open threads**:
- TODO: Commit and push these changes so marketplace actually serves 7.11.0
- TODO: Message users you installed KERNEL for — tell them to run the 3-line update + enable auto-update

**Next steps**:
1. Commit the 3 modified files
2. Push to main so marketplace picks up 7.11.0
3. Notify installed users with update instructions

**Warnings**:
- `/plugin marketplace refresh` is NOT a real command — was in our docs incorrectly
- No way to force-push updates to users. Plugin system is pull-based only.
- Auto-update toggle exists per-marketplace but users must enable it themselves

**Continuation prompt**:
> /kernel:ingest Commit and push plugin update docs. 3 files modified: marketplace.json, README.md, QUICKSTART.md. Read _meta/handoffs/plugin-update-docs-2026-04-07.md.
