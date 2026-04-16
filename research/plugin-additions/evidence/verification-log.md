# Evidence Verification Log

## High-Confidence Findings

### The repo currently has inventory and generated-surface drift

- **Claimed by**: Contrarian, Systems Thinker, Negative Space
- **Primary sources**:
  - `README.md`
  - `ycc/skills/`
  - `ycc/commands/`
  - `scripts/validate-cursor-skills.sh`
  - `scripts/validate-cursor-agents.sh`
  - `scripts/validate-codex-skills.sh`
  - `scripts/validate-codex-plugin.sh`
- **Verification status**: Confirmed
- **Confidence**: High
- **Notes**: Local audit on April 16, 2026 found 37 skills, 36 commands, 50 agents; README still states 34/34/50.

### Hooks are now first-class or emerging across multiple agent platforms

- **Claimed by**: Historian, Journalist, Futurist
- **Primary sources**:
  - https://docs.anthropic.com/en/docs/claude-code/hooks-guide
  - https://docs.github.com/en/copilot/reference/hooks-configuration
  - https://developers.openai.com/codex/config-reference
- **Verification status**: Confirmed
- **Confidence**: High

### The repo lacks a first-class release or compatibility workflow for `ycc` itself

- **Claimed by**: Negative Space, Systems Thinker, Analogist
- **Primary sources**:
  - local repo inspection of `ycc/skills/`, `scripts/`, `.github` absence
  - `README.md`
- **Verification status**: Confirmed
- **Confidence**: High

## Medium-Confidence Findings

### A dedicated hook workflow would be more valuable than more domain skills

- **Claimed by**: Historian, Systems Thinker, Futurist
- **Supporting evidence**: Official hook docs plus existing repo hook guidance
- **Conflicting evidence**: Hook maturity varies by target
- **Confidence**: Medium-High

## Contradictions Requiring Resolution

### Hook adoption timing

- **Persona A says**: Hook workflows are timely now.
- **Persona B says**: Cross-platform hook support is uneven, especially on Codex.
- **Evidence for A**: Anthropic and GitHub official hook docs; Codex config reference
- **Evidence for B**: Codex config reference frames `features.codex_hooks` as under development
- **Resolution**: Favor a target-aware hook workflow, not a parity-assuming one.
