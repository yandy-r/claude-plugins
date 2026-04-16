# Futurist Research: plugin-additions

## Executive Summary

Over the next 6-24 months, agent ecosystems are likely to standardize further around custom agents, skills/rules, hooks, MCP, and background execution. The additions that will age well for `ycc` are the ones that improve authoring, policy enforcement, release quality, and compatibility across those primitives.

## Forward Signals

### Hooks will matter more

- **Signal**: Anthropic and GitHub both position hooks as deterministic lifecycle control; OpenAI exposes `features.codex_hooks` in config.
- **Prediction**: Hook configuration and hook-script packaging will become a standard part of agent repo tooling.
- **Source**: https://docs.anthropic.com/en/docs/claude-code/hooks-guide
- **Source**: https://docs.github.com/en/copilot/reference/hooks-configuration
- **Source**: https://developers.openai.com/codex/config-reference

### Async/background agents will normalize multi-stage workflows

- **Signal**: Cursor documents background agents; GitHub documents cloud-agent research/plan/iterate workflows.
- **Prediction**: More repos will want async-safe planning, research, release, and compatibility audit skills.
- **Source**: https://docs.cursor.com/ko/background-agents
- **Source**: https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent

### MCP and tool governance will get stricter

- **Signal**: Codex config already exposes fine-grained app/tool approval and MCP settings.
- **Prediction**: Skills that install, audit, or curate MCP/tool access will become more valuable than generic "integration" prose.
- **Source**: https://developers.openai.com/codex/config-reference

## Future-Friendly Additions

### `ycc:bundle-author`

- **Why it ages well**: Every future skill/agent addition benefits from standardized scaffolding and repo-aware guidance.
- **Confidence**: High

### `ycc:bundle-release`

- **Why it ages well**: As agent ecosystems professionalize, release testing and packaging become table stakes.
- **Confidence**: High

### `ycc:hooks-workflow`

- **Why it ages well**: Hook surfaces are expanding across platforms.
- **Confidence**: Medium-High

### `ycc:compatibility-audit`

- **Why it ages well**: Multi-target support gets harder, not easier, as features diverge.
- **Confidence**: High

## Speculative but Plausible

- A future `ycc` workflow that generates target-specific hook configs from one source file.
- A model/platform capability matrix generated from config + docs + source inventory.
- Release smoke tests that open a minimal sandbox install for each target automatically.

## Key Insights

1. The safest future bets are scaffolding, release, hooks, and compatibility.
2. Another batch of expert personas is less durable than infrastructure for the authoring system.
3. Investments should assume platform divergence and generate per-target outputs where needed.

## Evidence Quality

- **Primary sources**: 6
- **Secondary sources**: 1
- **Confidence rating**: Medium-High

## Contradictions & Uncertainties

Codex hook support is still framed as a feature flag, so any hook investment should ship with graceful fallbacks and a clear "supported targets today" matrix.

## Search Queries Executed

1. Codex hooks config official docs
2. agent hooks future coding tools official docs
3. Cursor background agents official docs
4. GitHub Copilot cloud agent official docs
5. custom agents roadmap patterns official docs
6. MCP tool governance official docs
7. release management custom agents best practices
8. multi target compatibility testing patterns
