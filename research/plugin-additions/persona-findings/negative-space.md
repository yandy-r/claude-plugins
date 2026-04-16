# Negative Space Research: plugin-additions

## Executive Summary

What is missing is more important than what is present. The repo has strong planning, research, PRP, and documentation workflows, but it lacks a first-class authoring/release path for the plugin bundle itself, lacks an operational hook workflow, and lacks an explicit compatibility-audit workflow for its three targets.

## Important Gaps

### No ycc-native bundle authoring workflow

- **Gap**: There is no skill focused on creating a new `ycc` skill/agent/command safely within this repo's source-of-truth model.
- **Why it matters**: Contributors can add artifacts, but the repo does not provide its own best-practice path for doing so.

### No bundle release workflow

- **Gap**: Versioning, regeneration, validation, marketplace sync, and release notes are not wrapped in a dedicated skill.
- **Why it matters**: Release quality is left to convention.

### No compatibility smoke-test workflow

- **Gap**: The repo supports Claude, Cursor, and Codex, but no user-facing skill audits cross-target install/readiness.
- **Why it matters**: Multi-target repos fail in target-specific ways.

### No operational hook workflow

- **Gap**: There is extensive hook guidance under `ycc/rules/*/hooks.md`, but no skill that turns guidance into actual configs/scripts.
- **Why it matters**: The repo documents hooks more than it operationalizes them.

### No generated inventory/reporting layer

- **Gap**: README counts and parity are hand-maintained.
- **Why it matters**: Drift is already visible.

## Under-Discussed Adoption Barriers

- The catalog is large enough that discoverability may be a user problem.
- Generated outputs drifting undermines trust in the bundle.
- Environment-specific helper scripts make "works on my machine" risks more likely.

## Questions the Repo Is Not Explicitly Answering

1. What is the sanctioned way to add a new skill to `ycc` end to end?
2. What is the sanctioned way to release a new version safely?
3. Which targets support which advanced features today?
4. Which generated files are never meant to be edited manually?

## Key Insights

1. The repo's missing capabilities are meta-workflows around the repo itself.
2. The hook opportunity is real because prose guidance already exists.
3. A compatibility-audit skill would close a uniquely important gap for this project.

## Evidence Quality

- **Primary sources**: 5
- **Secondary sources**: 0
- **Confidence rating**: High

## Contradictions & Uncertainties

Some of these gaps can also be addressed by CI or scripts rather than skills. The correct design may be "skill + scripts + CI" rather than a skill alone.

## Search Queries Executed

1. missing capabilities custom agent repos
2. hook setup workflow coding agents
3. release workflow custom agent repos
4. compatibility audit multi target plugin repos
5. generated inventory docs best practices
6. platform capability matrix coding tools
7. MCP audit workflow official docs
8. contributor scaffolding internal platform repos
