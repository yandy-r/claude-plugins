# Analysis of Competing Hypotheses: plugin-additions

## Executive Summary

The evidence rejects "add more narrow expert skills first" and favors "improve the plugin-authoring system first." The most viable hypotheses are that `ycc` should add operational/meta-workflow skills now, and that release/sync/compatibility infrastructure should be treated as the prerequisite for any further catalog growth.

## Hypotheses

### Hypothesis 1: Add more domain and language skills first

**Description**: The next biggest user value comes from broadening the skill catalog.  
**Proponents**: Weak local intuition; low direct evidence.  
**Implications**: Catalog size grows faster than platform infrastructure.

### Hypothesis 2: Add operational/meta-workflow skills first

**Description**: The next highest-value additions are skills that improve authoring, release, sync, hooks, and compatibility of the `ycc` bundle itself.  
**Proponents**: Contrarian, Systems Thinker, Analogist, Journalist, Negative Space.  
**Implications**: Better maintenance economics across the whole repo.

### Hypothesis 3: Add more platform connectors and MCP-heavy integrations first

**Description**: The main opportunity is extending external system access.  
**Proponents**: Partial support from current ecosystem direction.  
**Implications**: More integrations, but higher surface churn.

### Hypothesis 4: Freeze additions and only optimize existing infrastructure

**Description**: The repo should stop adding capabilities and focus entirely on cleanup.  
**Proponents**: Contrarian partially.  
**Implications**: Lower churn, but may miss real new opportunities like hooks.

### Hypothesis 5: Build release/sync/compatibility infrastructure first, then selectively add a few platform-aligned workflows

**Description**: Strengthen the authoring system now, then add a small number of high-leverage skills such as hook workflows.  
**Proponents**: Historian, Systems Thinker, Journalist, Futurist, Negative Space.  
**Implications**: Balanced path; avoids bloat while still moving forward.

## Evidence vs Hypotheses Matrix

| Evidence                                                                             | H1  | H2  | H3  | H4  | H5  | Source        | Quality |
| ------------------------------------------------------------------------------------ | --- | --- | --- | --- | --- | ------------- | ------- |
| README count drift vs source inventory                                               | I   | C   | N   | C   | C   | Local repo    | H       |
| Cursor/Codex generated drift detected by validators                                  | I   | C   | N   | C   | C   | Local repo    | H       |
| No command for `karpathy-guidelines`                                                 | I   | C   | N   | C   | C   | Local repo    | H       |
| Official Codex guidance: instructions -> hooks -> plugins/skills -> MCP -> subagents | I   | C   | C   | N   | C   | OpenAI docs   | H       |
| Anthropic and GitHub both expose hooks as first-class lifecycle control              | N   | C   | C   | N   | C   | Official docs | H       |
| Cursor and GitHub document background/cloud agents                                   | N   | C   | C   | N   | C   | Official docs | H       |
| Repo already has 37 skills and 50 agents                                             | I   | C   | N   | C   | C   | Local repo    | H       |
| `init` helper script uses Claude-specific local paths                                | I   | C   | N   | C   | C   | Local repo    | H       |

## Critical Disconfirming Evidence

### Evidence that weakens Hypothesis 1

- **Evidence**: Current repo state already shows inventory drift, generated-output drift, and parity issues.
- **Refutes**: H1
- **Why incompatible**: Growing the catalog before stabilizing source-of-truth workflows increases the exact failure modes already present.
- **Strength**: Strong
- **Source**: Local repo audit and validation results

## Hypothesis Survival Analysis

### Eliminated Hypotheses

#### Hypothesis 1: Add more domain and language skills first

- **Disconfirming evidence count**: 4+
- **Critical contradictions**: Existing catalog size and drift problems
- **Why eliminated**: The repo is already large enough that more breadth is likely to hurt more than help unless infrastructure improves first.

### Surviving Hypotheses

#### Hypothesis 2: Add operational/meta-workflow skills first

- **Disconfirming evidence count**: Low
- **Supporting evidence count**: High
- **Viability**: High
- **Remaining questions**: Which 2-4 workflows are most worth shipping first?

#### Hypothesis 5: Build infrastructure first, then selectively add platform-aligned workflows

- **Disconfirming evidence count**: Low
- **Supporting evidence count**: High
- **Viability**: High
- **Remaining questions**: Whether hook workflows should ship immediately or after compatibility audit/release workflow.

#### Hypothesis 3: Add more platform connectors first

- **Disconfirming evidence count**: Moderate
- **Supporting evidence count**: Moderate
- **Viability**: Medium
- **Remaining questions**: Whether new connectors create enough repeat user value to justify churn.

## Relative Strength Assessment

### Most Viable: Hypothesis 5

- **Evidence score**: Strongly positive
- **Persona consensus**: Broad
- **Uncertainty level**: Medium
- **Confidence**: High

### Second Most Viable: Hypothesis 2

- **Evidence score**: Strongly positive
- **Persona consensus**: Broad
- **Uncertainty level**: Medium
- **Confidence**: High

## Discriminating Evidence Needed

1. **Usage evidence**: Which existing skills are most/least used in practice
2. **Release evidence**: Whether generated drift is common across recent commits
3. **Hook support evidence**: Exact current target support matrix for executable hooks

## Assumptions Challenged

- **Assumption**: "More skills automatically means more value."
- **Evidence**: Current repo issues are around maintenance integrity, not lack of catalog breadth.
- **Implication**: The value frontier has moved from content growth to system robustness.

## Key Insights

1. The repo should treat itself as a product with authoring/release workflows.
2. The next additions should increase control and reliability across the existing bundle.
3. A small number of platform-aligned workflows beats a long tail of expert personas.

## Methodology Notes

- **Total hypotheses generated**: 5
- **Hypotheses eliminated**: 1
- **Hypotheses surviving**: 3
- **Evidence items evaluated**: 8
- **Quality of evidence**: Mostly high-confidence primary sources

## Confidence Assessment

- **Overall confidence in analysis**: High
- **Main uncertainty sources**: Lack of actual usage telemetry for current `ycc` skills
- **Additional research needed**: Commit history + issue history + real user usage signals
