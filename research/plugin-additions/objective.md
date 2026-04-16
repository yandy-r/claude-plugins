# Research Objective: plugin-additions

## Core Research Questions

1. Which additional `ycc` skills, agents, hooks, or plugin-adjacent capabilities would add clear day-to-day utility for real users of this repository, rather than expanding surface area without adoption?
2. Which gaps exist in the current `ycc/skills/`, `ycc/agents/`, `scripts/`, install flows, validation flows, or cross-target generation model for Claude, Cursor, and Codex?
3. Which emerging or current platform capabilities from Claude Code, Codex, Cursor, GitHub, and related agent ecosystems could be translated into practical additions for this repo?
4. Which current skills, agents, generators, validators, or helper scripts appear redundant, fragile, underpowered, or poorly composed, and how should they be optimized?
5. Which additions should be rejected because they would create maintenance burden, duplicate existing built-ins, or break the repository's single-plugin `ycc` design?

## Success Criteria

- [ ] All 8 personas deployed with distinct search strategies
- [ ] Research covers both internal repo analysis and external ecosystem/platform developments
- [ ] Recommendations are filtered for user value, maintenance cost, and strategic fit
- [ ] Existing `ycc` skills, agents, generators, validators, and installation flows are examined for concrete optimization opportunities
- [ ] At least one section explicitly identifies what should _not_ be added
- [ ] Contradictions and ecosystem tradeoffs are preserved rather than smoothed over
- [ ] Final report ranks additions by impact, feasibility, and fit with the repo

## Evidence Standards

- Prefer official documentation, product docs, source repositories, and maintainers' primary materials
- Use repository evidence for claims about current coverage or implementation gaps
- Cite concrete sources for any proposed external-platform-driven addition
- Assign confidence ratings to each major recommendation
- Document overlap with existing skills/agents before proposing anything new

## Perspectives to Consider

- Current `ycc` product surface: skills, agents, rules, generators, validators, install flows
- Cross-target compatibility: Claude, Cursor, Codex
- Platform hooks and automation surfaces: GitHub, CI, MCP, local workflow integrations
- Competitive and adjacent tools: how other agent ecosystems package workflows, prompts, skills, or automation
- Maintenance economics: cost to implement, validate, document, and keep current

## Potential Biases to Guard Against

- Novelty bias: overvaluing new platform features because they are new
- Feature-bloat bias: proposing additions without evidence of repeated user value
- Local-maxima bias: over-optimizing current workflows instead of identifying more useful primitives
- Tool-envy bias: copying features from other ecosystems without fit to `ycc`
