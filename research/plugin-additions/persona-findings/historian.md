# Historical Research: plugin-additions

## Executive Summary

The relevant history is not "add more expert prompts." The durable pattern across agent ecosystems has been convergence on a small set of primitives: repository instructions, reusable skills/rules, lifecycle hooks, external tool protocols, and specialized subagents. Repos that scale these systems well tend to invest in source-of-truth generation and enforcement before expanding surface area.

## Historical Timeline

### 2019-2023: Prompt packs and dotfile automation

- **Key development**: Developer tooling relied heavily on prompt snippets, shell aliases, and handwritten project conventions.
- **Context**: These approaches were flexible, but drifted easily and were rarely portable.
- **Source**: local repo evidence in `ycc/settings/settings.json`, `install.sh`, and generated compatibility trees.

### 2024: Rules and repo-scoped instructions became first-class

- **Key development**: Cursor formalized rules; Anthropic formalized `AGENTS.md` and Claude Code hooks; Codex formalized `AGENTS.md`, skills, plugins, and config-driven custom agents.
- **Context**: The center of gravity shifted from ad hoc prompt reuse to checked-in, versioned workflow artifacts.
- **Source**: https://docs.cursor.com/context/rules
- **Source**: https://docs.anthropic.com/en/docs/claude-code/hooks-guide
- **Source**: https://developers.openai.com/codex/concepts/customization

### 2025-2026: Agents, hooks, and MCP converged

- **Key development**: GitHub Copilot cloud agent added custom agents, skills, hooks, and MCP; Codex documents skills, plugins, custom agents, and the `features.codex_hooks` config surface; Cursor documents background agents and MCP.
- **Context**: The reusable building blocks across ecosystems now look similar enough that cross-platform workflow abstractions are valuable.
- **Source**: https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/create-custom-agents
- **Source**: https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-skills
- **Source**: https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/use-hooks
- **Source**: https://developers.openai.com/codex/config-reference
- **Source**: https://docs.cursor.com/ko/background-agents

## Failed Attempts

### Hand-maintained compatibility surfaces

- **What was tried**: Keep source, generated output, README counts, and install docs aligned by convention.
- **Why it failed**: Drift accumulates. In this repo, `README.md` still says 34 skills and 34 commands, while the source tree currently has 37 skills and 36 commands; validation also reports generated Cursor/Codex drift.
- **When**: Current repo state as of April 16, 2026.
- **Lessons**: Inventory and generated-surface discipline should be automated, not remembered.
- **Confidence**: High
- **Source**: `README.md`
- **Source**: `scripts/validate-cursor-skills.sh`
- **Source**: `scripts/validate-cursor-agents.sh`
- **Source**: `scripts/validate-codex-skills.sh`
- **Source**: `scripts/validate-codex-plugin.sh`

### Prompt-surface proliferation

- **What was tried**: Large catalogs of narrowly specialized prompts/agents.
- **Why it failed**: Discovery worsens, overlap grows, and maintainers spend time curating names instead of improving workflows.
- **Lessons**: New skills should replace repeated work, not just name another niche expertise area.
- **Confidence**: Medium
- **Source**: https://developers.openai.com/codex/concepts/customization
- **Source**: https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-skills

## Forgotten Alternatives

### Generator-first maintenance

- **Description**: Earlier tooling ecosystems succeeded by generating derived files, manifests, and docs from one canonical source.
- **Why forgotten**: LLM tooling often reintroduces hand-edited mirrors because prompt files feel lightweight.
- **Worth revisiting?**: Yes. This repo is already halfway there; it should lean further into generated inventory and release metadata.
- **Modern relevance**: High for `README`, marketplace metadata, command/skill parity, and drift-proof compatibility bundles.
- **Source**: local repo layout in `scripts/`, `.cursor-plugin/`, `.codex-plugin/`, `README.md`

## Temporal Patterns

- **Pattern**: Convergence, not fragmentation.
- **Triggers**: Once agent platforms expose hooks + MCP + custom agents, user value shifts from more prompts to better orchestration.
- **Current phase**: Mature enough to standardize on meta-workflows.

## Historical Context

The repo's own transition from nine separate plugins to one `ycc` bundle mirrors the broader market lesson: consolidate the surface, then add reusable mechanisms around it.

## Key Insights

1. The winning abstraction is not "more experts"; it is "fewer primitives, better composed."
2. Hook support is becoming normal across platforms, which makes cross-platform hook workflows newly practical.
3. The repo is already at the stage where release, sync, and compatibility automation matter more than another language/domain skill.

## Evidence Quality

- **Primary sources**: 5
- **Secondary sources**: 2
- **Confidence rating**: High

## Contradictions & Uncertainties

Codex hook support appears documented in config but still marked under development, so hook-related investment should be modular and guarded rather than assumed universal today.

## Search Queries Executed

1. Claude Code hooks official docs
2. Claude Code sub agents official docs
3. Cursor rules official docs
4. Cursor background agents official docs
5. OpenAI Codex customization official docs
6. OpenAI Codex config reference codex hooks
7. GitHub Copilot create custom agents official docs
8. GitHub Copilot create agent skills official docs
