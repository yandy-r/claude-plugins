---
description: 'Audit cross-target compatibility of the ycc bundle across Claude, Cursor,
  Codex, and opencode targets Usage: [--target=claude|cursor|codex|opencode|all] [--json]
  [--fail-fast] [--dry-run]'
---

Audit the `ycc` bundle for cross-target compatibility. Compares the source-of-truth under `ycc/` against the generated bundles for each target, runs the per-target validator sweep, checks install and packaging assumptions, and reports any features used in source that a given target does not support.

Invoke the **compatibility-audit** skill to:

- Detect drift between `ycc/` source and the generated Claude, Cursor, Codex, and opencode bundles
- Run the full validator sweep for each requested target
- Verify marketplace manifest parity, Codex `.mcp.json` and `.codex-plugin/plugin.json`, and Cursor residue patterns
- Flag skill surfaces that use features unsupported on one or more targets

Pass `$ARGUMENTS` through to the skill. Supported flags:

- `--target=<t>`: Scope the audit to a single target (`claude`, `cursor`, `codex`, or `opencode`). Defaults to `all`.
- `--json`: Emit a machine-readable JSON report instead of human prose.
- `--fail-fast`: Exit on the first compatibility violation found.
- `--dry-run`: Print what would be checked without running validators or writing output.

## What it checks

- Source-to-generated drift across Claude, Cursor, Codex, and opencode (via `report-bundle-drift.sh`)
- Full validator sweep per target (via `./scripts/validate.sh --only <t>`)
- Install and packaging assumptions: marketplace manifest parity, Codex `.mcp.json` + `.codex-plugin/plugin.json`, Cursor residue patterns
- Feature-vs-matrix audit: which source surfaces use features unsupported on a given target

## Examples

```
/compatibility-audit
```

Runs the full audit across all four targets and prints a human-readable summary.

```
/compatibility-audit --target=cursor
```

Audits only the Cursor bundle — drift detection, validator sweep, and Cursor residue check.

```
/compatibility-audit --target=codex --json
```

Audits only the Codex bundle and emits a machine-readable JSON report suitable for CI parsing.

```
/compatibility-audit --target=opencode
```

Audits only the opencode bundle — drift detection, validator sweep, and opencode install-assumption checks.

```
/compatibility-audit --target=all --fail-fast
```

Runs the full audit but exits immediately on the first violation found.

```
/compatibility-audit --dry-run
```

Prints the checks that would run without executing validators or writing any output.

## See also

`.opencode-plugin/skills/compatibility-audit/references/reading-the-report.md` explains how to interpret each section of the audit report, including drift tables, validator output codes, and the feature-vs-matrix grid.
