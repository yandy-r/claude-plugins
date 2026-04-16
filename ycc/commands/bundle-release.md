---
description: Prepare a ycc bundle release — preflight, bump, regenerate, validate, draft notes (no auto-commit)
argument-hint: '<new-version> [--dry-run] [--skip-notes] [--no-publish]'
---

Prepare a `ycc` bundle release. Runs pre-flight, bumps the version in the two hand-edited source-of-truth JSON files, regenerates derived Cursor + Codex bundles, validates all targets, and drafts release notes. **Never auto-commits or publishes.**

Invoke the **bundle-release** skill to:

1. Run pre-flight checks (clean tree, version parity, branch)
2. Bump `ycc/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
3. Run `./scripts/sync.sh` to regenerate Cursor + Codex bundles
4. Run `./scripts/validate.sh` full validator sweep
5. Draft `docs/releases/<new-version>.md` from the template
6. Emit the exact `git add` / `git commit` / `git tag` / `gh release create` commands for the user to run

Pass `$ARGUMENTS` through to the skill. Supported flags:

- `--dry-run`: Run preflight and print the release plan, write nothing
- `--skip-notes`: Do not draft release notes
- `--no-publish`: Accepted for clarity; the skill never publishes automatically

Examples:

```
/ycc:bundle-release 2.1.0                  # minor bump (new skill/command/agent)
/ycc:bundle-release 2.0.1 --dry-run        # preview patch release
/ycc:bundle-release 3.0.0 --skip-notes     # major bump, no notes file
```

See `ycc/skills/bundle-release/references/version-policy.md` for semver rules and `release-checklist.md` for the full manual process.
