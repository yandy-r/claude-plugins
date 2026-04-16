# Innovation Synthesis: plugin-additions

## Executive Summary

The most promising additions are not "more expertise" but "better productization" of the existing expertise. The strongest proposals combine local repo pain with external platform direction.

## Recommended New Skills / Workflows

### 1. `ycc:bundle-author`

- **Purpose**: Scaffold a new `ycc` skill, optional command, optional agent, and required source-of-truth placement under `ycc/`.
- **Why now**: The repo has enough moving parts that contributor scaffolding now pays back quickly.
- **Expected outputs**: new directories/files, regeneration checklist, README inventory update guidance
- **Confidence**: High

### 2. `ycc:bundle-release`

- **Purpose**: Prepare a release by bumping version, regenerating Cursor/Codex artifacts, validating all targets, updating marketplace metadata, and drafting release notes.
- **Why now**: The repo currently lacks a visible release workflow despite being a packaged multi-target bundle.
- **Confidence**: High

### 3. `ycc:compatibility-audit`

- **Purpose**: Run target-aware checks for Claude, Cursor, and Codex, including install expectations, generated outputs, plugin metadata, and feature support notes.
- **Why now**: Multi-target support is a core repo promise.
- **Confidence**: High

### 4. `ycc:hooks-workflow`

- **Purpose**: Generate and validate target-specific hook configurations/scripts from repo conventions and rule files.
- **Why now**: Hook support is a real market trend, and the repo already has hook guidance waiting to be operationalized.
- **Confidence**: Medium-High

## Recommended Script / Generator Optimizations

1. Generate README inventory counts and parity tables from source.
2. Add an umbrella `generate-all` and `validate-all` path if not already present.
3. Fix the deep-research prerequisite ordering bug.
4. Fix the `systems-enginieering-expert` typo.
5. Make `generate-mcp-catalog.sh` target-aware or explicitly local-only.

## Ideas To Reject

1. Another wave of language/domain skills without usage evidence
2. A new top-level plugin instead of extending `ycc`
3. Cross-platform hook claims that pretend feature parity already exists
