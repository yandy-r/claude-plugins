# Strategic Research Report: plugin-additions

**Research Date**: April 16, 2026  
**Output Directory**: `research/plugin-additions/`  
**Research Method**: Asymmetric Research Squad (8 personas + crucible synthesis)

---

## Executive Synthesis

The repo does not primarily need more subject-matter coverage. It already has a large enough catalog that maintenance integrity is now the bottleneck: source inventory has drifted from the README, generated Cursor/Codex outputs are currently out of sync, one skill has no matching command, and at least one agent name appears misspelled. That is exactly the point where successful tooling ecosystems stop adding breadth by default and instead strengthen authoring, release, and validation workflows.

The external ecosystem supports that conclusion. OpenAI's current Codex customization docs explicitly sequence repo instructions, hooks/linters, plugins/skills, MCP, and then subagents. Anthropic and GitHub both now treat hooks as first-class lifecycle control, not a niche feature. Cursor documents rules, MCP, and background agents. In other words: the common primitives are stabilizing across platforms, and the smart move for `ycc` is to invest in workflows that package and enforce those primitives well.

The highest-value additions are therefore "meta-skills" for the bundle itself: a ycc-native skill to author new internal capabilities correctly, a release workflow for regenerating and validating the three targets, a compatibility audit workflow, and a hook workflow that turns existing hook guidance into real configs/scripts. These are not bloat. They address visible local pain and align with where the platforms are going.

## Prioritized Recommendations

### 1. Add `ycc:bundle-author`

- **What it should do**: scaffold a new `ycc` skill and optional command/agent in the source-of-truth tree, explain required generators/validators, and update generated inventory surfaces.
- **Why it matters**: the repo currently lacks a first-class contributor workflow for extending `ycc` itself.
- **Confidence**: High

### 2. Add `ycc:bundle-release`

- **What it should do**: bump version, regenerate Cursor/Codex artifacts, run validators, sync marketplace/plugin metadata, and draft release notes.
- **Why it matters**: the repo is a packaged product but does not expose a release workflow as a first-class skill.
- **Confidence**: High

### 3. Add `ycc:compatibility-audit`

- **What it should do**: verify source vs generated outputs, install assumptions, target feature support, and bundle health across Claude, Cursor, and Codex.
- **Why it matters**: multi-target support is central to the repo's promise.
- **Confidence**: High

### 4. Add `ycc:hooks-workflow`

- **What it should do**: generate and validate target-specific hook configs/scripts from existing repo guidance, with clear support notes per target.
- **Why it matters**: hooks are now platform-relevant, and the repo already has hook documentation that is not operationalized.
- **Confidence**: Medium-High

## Internal Optimizations To Make First

1. Fix the deep-research prerequisite ordering mismatch in `ycc/skills/deep-research/scripts/check-prerequisites.sh`.
2. Fix source inventory drift:
   - `README.md` counts
   - command parity for `karpathy-guidelines`
   - generated Cursor/Codex outputs currently failing validation
3. Fix the likely typo in `ycc/agents/systems-enginieering-expert.md`.
4. Make `ycc/skills/init/scripts/generate-mcp-catalog.sh` target-aware or explicitly local-only.
5. Generate README inventory counts/tables from source instead of hand-maintaining them.
6. Add CI to run the current validator set and block generated drift from landing again.

## What Not To Add

### Do not add another wave of narrow expert skills

- The repo already has substantial breadth.
- The current pain is maintenance integrity, not missing subject coverage.

### Do not create a new top-level plugin

- The repo instructions explicitly say to keep extending `ycc`.

### Do not market hooks as uniform across all targets yet

- Support exists, but maturity differs by platform.

## Evidence Portfolio

### High-confidence findings

- Current repo drift is real and reproducible via local validation.
- Hooks are a genuine multi-platform opportunity now.
- The repo lacks a first-class bundle authoring/release/compatibility workflow.

### Medium-confidence findings

- A hook workflow is likely worth adding soon, but should ship with a target support matrix.

## Strategic Implications

The repo has crossed a threshold: it is no longer just a library of prompts and instructions, but a multi-target product with generated derivatives. That changes what "useful new work" looks like. The next additions should harden the production system around `ycc` itself so that future capability additions become safer, cheaper, and easier to understand.

## Research Gaps

1. Real usage telemetry for current skills and agents
2. Commit-history analysis for how often generated drift recurs
3. Exact current target support matrix for executable hooks

## Recommended Next Step

Implement one small bundle-health milestone before any new domain skill:

1. Fix drift and inventory accuracy
2. Add CI for validators
3. Choose between `bundle-author` and `bundle-release` as the first new skill
4. Add `hooks-workflow` only after defining a target support matrix

## Sources

- <https://developers.openai.com/codex/concepts/customization>
- <https://developers.openai.com/codex/config-reference>
- <https://docs.anthropic.com/en/docs/claude-code/hooks-guide>
- <https://docs.anthropic.com/en/docs/claude-code/sub-agents>
- <https://docs.cursor.com/context/rules>
- <https://docs.cursor.com/cli/mcp>
- <https://docs.cursor.com/ko/background-agents>
- <https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent>
- <https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/create-custom-agents>
- <https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-skills>
- <https://docs.github.com/en/copilot/reference/hooks-configuration>
