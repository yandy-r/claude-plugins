# Contradiction Mapping: plugin-additions

## Executive Summary

The main contradictions are not about whether opportunities exist; they are about sequence and fit. The ecosystem now supports hooks, MCP, and custom agents strongly enough to justify new `ycc` workflows, but the local repo state argues those additions should be operational and guarded, not broad catalog expansion.

## Major Contradictions

### Contradiction 1: "Add more capabilities" vs "Stabilize first"

**Personas involved**: Journalist, Futurist vs Contrarian  
**Nature**: Strategic sequencing contradiction

- **Position A**: Platform capabilities are expanding quickly, so `ycc` should add more.
- **Position B**: The repo already exhibits drift and inventory issues, so adding more surface now is risky.
- **Assessment**: Both are true. The resolution is sequencing: add a small set of maintenance-multiplying workflows first.

### Contradiction 2: Hooks are valuable vs hooks are unevenly mature

**Personas involved**: Historian, Journalist, Futurist vs Contrarian  
**Nature**: Feature-readiness contradiction

- **Position A**: Hooks are now important across Anthropic, GitHub, and emerging Codex surfaces.
- **Position B**: Codex hook support is still feature-flagged/under development, so a cross-platform hook story cannot assume parity.
- **Assessment**: Ship hook workflows with explicit per-target support and graceful fallbacks.

### Contradiction 3: More agents could help vs more agents create discovery debt

**Personas involved**: Futurist vs Contrarian, Negative Space  
**Nature**: Catalog-size contradiction

- **Position A**: Specialized agents will continue to matter.
- **Position B**: Current catalog scale already creates naming and parity risk.
- **Assessment**: Future agent additions should be rarer and justified by repeated workflow demand.

## Evidence Comparison

| Contradiction                        | Better-supported side                 | Why                                                  |
| ------------------------------------ | ------------------------------------- | ---------------------------------------------------- |
| Add more vs stabilize first          | Stabilize first, then add selectively | Strong local repo evidence                           |
| Hooks valuable vs hooks uneven       | Both                                  | Strong platform evidence plus real maturity variance |
| More agents help vs more agents hurt | "Add selectively" middle ground       | Local scale issues plus platform trend               |

## What These Contradictions Reveal

1. The repo is not short on ideas; it is short on operational slack.
2. Cross-platform opportunity is real, but target asymmetry must shape design.
3. The best additions are ones that make future additions safer.

## Confidence

- **Overall confidence**: High
- **Main unresolved question**: Which operational workflow should ship first: release, sync, hooks, or compatibility audit?
