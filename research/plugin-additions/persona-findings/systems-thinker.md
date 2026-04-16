# Systems Analysis: `ycc` As A Cross-Target Workflow System

## Executive Summary

`ycc` is no longer just a bundle of skills. In practice, it behaves like a cross-target workflow compiler: the source-of-truth lives in [`ycc/`](../../../ycc/), generators translate that source into Cursor and Codex artifacts, validators police drift, and [`install.sh`](../../../install.sh) pushes the resulting state into user environments. That architecture is strategically strong, but it also means the highest-leverage improvements are not "add more skills" or "add more plugins." They are better information flows, stricter generation contracts, and clearer capability boundaries across Claude, Cursor, and Codex. **Confidence**: High. This follows directly from the repo structure, install flow, and generator topology in [`README.md`](../../../README.md), [`install.sh`](../../../install.sh), and the `scripts/generate_*` / `scripts/validate-*` entrypoints.

The main second-order risk is maintenance drag from non-isomorphic targets. Claude, Cursor, and Codex all support reusable instructions and delegation, but they do not expose the same primitives at the same maturity. Anthropic offers mature hooks and subagents; Cursor emphasizes rules, modes, MCP, and background agents; Codex treats `AGENTS.md`, skills, MCP, plugins, and subagents as complementary layers, while hooks remain experimental and partially scoped to Bash interception today ([OpenAI Codex customization](https://developers.openai.com/codex/concepts/customization), [OpenAI Codex hooks](https://developers.openai.com/codex/hooks), [Anthropic subagents](https://code.claude.com/docs/en/sub-agents), [Anthropic hooks](https://code.claude.com/docs/en/hooks), [Cursor Rules](https://docs.cursor.com/ru/context/rules), [Cursor GitHub / background agents](https://docs.cursor.com/en/github), [Cursor Modes](https://docs.cursor.com/zh-Hant/agent/modes)). **Confidence**: High.

The local system already shows this stress. On 2026-04-16, running the existing validators produced drift failures in generated Cursor agents, Cursor skills, Codex skills, and Codex plugin metadata, even before any new feature work. That is strong evidence that additional surface area will amplify coordination cost unless the repo shifts effort toward compiler-like guarantees, installed-state diagnostics, and capability-aware composition. **Confidence**: High.

## System Map

### 1. Authoring Layer

- Canonical source-of-truth lives under [`ycc/`](../../../ycc/), especially [`ycc/skills/`](../../../ycc/skills), [`ycc/agents/`](../../../ycc/agents), and `ycc/.claude-plugin/plugin.json`. The repo instructions explicitly say new workflow logic belongs under `ycc/`, while [`.cursor-plugin/`](../../../.cursor-plugin) and [`.codex-plugin/`](../../../.codex-plugin) are generated outputs. **Confidence**: High.

### 2. Compilation Layer

- Cursor output is synthesized by [`generate_cursor_skills.py`](../../../scripts/generate_cursor_skills.py), [`generate_cursor_agents.py`](../../../scripts/generate_cursor_agents.py), and [`generate_cursor_rules.py`](../../../scripts/generate_cursor_rules.py).
- Codex output is synthesized by [`generate_codex_skills.py`](../../../scripts/generate_codex_skills.py), [`generate_codex_agents.py`](../../../scripts/generate_codex_agents.py), [`generate_codex_plugin.py`](../../../scripts/generate_codex_plugin.py), and shared transforms in [`generate_codex_common.py`](../../../scripts/generate_codex_common.py).
- These scripts already implement target-specific rewriting of names, paths, slash commands, agent references, and platform wording. That means `ycc` is already operating as an intermediate representation compiled into target-specific runtimes, even if the repo does not name it that way. **Confidence**: High.

### 3. Validation Layer

- Generated outputs are checked by target-specific validators such as [`validate-cursor-skills.sh`](../../../scripts/validate-cursor-skills.sh), [`validate-cursor-agents.sh`](../../../scripts/validate-cursor-agents.sh), [`validate-codex-skills.sh`](../../../scripts/validate-codex-skills.sh), [`validate-codex-agents.sh`](../../../scripts/validate-codex-agents.sh), and [`validate-codex-plugin.sh`](../../../scripts/validate-codex-plugin.sh).
- Those validators enforce sync and content policy, but they do not eliminate drift by themselves; they only detect it once a user runs them or when the install path invokes them. **Confidence**: High.

### 4. Distribution Layer

- Cursor distribution is a direct sync into `~/.cursor/{skills,agents,rules}` plus optional `mcp.json` symlink via [`install.sh`](../../../install.sh).
- Codex distribution is split across plugin source in `~/.codex/plugins/ycc`, custom agents in `~/.codex/agents`, and marketplace state in `~/.agents/plugins/marketplace.json` via [`install.sh`](../../../install.sh) and [`.agents/plugins/marketplace.json`](../../../.agents/plugins/marketplace.json).
- Claude uses settings + MCP integration rather than the same native install surface. **Confidence**: High.

### 5. Runtime Layer

- Claude: plugins, skills, hooks, subagents, agent teams, and MCP ([Anthropic subagents](https://code.claude.com/docs/en/sub-agents), [Anthropic hooks](https://code.claude.com/docs/en/hooks)).
- Cursor: rules, AGENTS-style instructions, modes, MCP, GitHub-backed background agents ([Cursor Rules](https://docs.cursor.com/ru/context/rules), [Cursor Modes](https://docs.cursor.com/zh-Hant/agent/modes), [Cursor MCP](https://docs.cursor.com/cli/mcp), [Cursor GitHub](https://docs.cursor.com/en/github)).
- Codex: `AGENTS.md`, skills, plugins, MCP, subagents, optional hooks, per-app approvals, and capability flags ([OpenAI Codex customization](https://developers.openai.com/codex/concepts/customization), [OpenAI Codex config reference](https://developers.openai.com/codex/config-reference), [OpenAI Codex hooks](https://developers.openai.com/codex/hooks), [OpenAI Codex subagents](https://developers.openai.com/codex/concepts/subagents)). **Confidence**: High.

## Feedback Loops

### Reinforcing Loop A: Surface Area -> Drift -> Maintenance Load

- Adding skills, agents, hooks, and install variants increases generator rules, validator cases, and install-state combinations.
- More generated targets create more opportunities for stale artifacts and target-specific exceptions.
- More stale artifacts increase maintainer support cost and user distrust.
- That slows down releases and encourages ad-hoc shortcuts, which creates more drift.

Observed local evidence:

- `validate-cursor-agents.sh` failed on `research-specialist.md`.
- `validate-cursor-skills.sh` failed on `_shared/references/agent-team-dispatch.md`, `implement-plan/SKILL.md`, `prp-spec/SKILL.md`, and `review-fix/SKILL.md`.
- `validate-codex-skills.sh` failed on `shared/references/agent-team-dispatch.md`, `skills/implement-plan/SKILL.md`, and `skills/review-fix/SKILL.md`.
- `validate-codex-plugin.sh` failed on `.codex-plugin/ycc/.codex-plugin/plugin.json`.

**Confidence**: High. This is direct local observation from 2026-04-16.

### Reinforcing Loop B: Better Compilation Contracts -> Lower Drift -> Safer Reuse

- Clearer source metadata and stronger compile-time rules reduce hand-maintained target deltas.
- Lower drift makes install/update behavior more predictable.
- Predictability raises confidence in adding new reusable workflows.
- That increases utility per maintainer-hour without proportional growth in support burden.

This matches platform guidance that favors reusable workflows packaged as skills/plugins and scoped instructions rather than repeated ad-hoc prompts ([OpenAI Codex customization](https://developers.openai.com/codex/concepts/customization), [Cursor Rules](https://docs.cursor.com/ru/context/rules)). **Confidence**: High.

### Balancing Loop: Stronger Hooks/Validation -> More Safety -> More Friction

- Hooks can enforce standards deterministically, which reduces quality variance.
- But more hooks also create latency, debugging complexity, and failure surfaces.
- Anthropic explicitly notes that async hooks cannot block behavior once running in the background, while Codex notes that multiple matching hooks run concurrently and that current `PreToolUse`/`PostToolUse` behavior is still incomplete and Bash-centric ([Anthropic hooks](https://code.claude.com/docs/en/hooks), [OpenAI Codex hooks](https://developers.openai.com/codex/hooks)).
- That means hooks are powerful but not uniform enforcement primitives across targets.

**Confidence**: High.

## Second-Order Effects

### Adding More Skills

- First-order benefit: more explicit workflows.
- Second-order cost: trigger ambiguity, naming collisions, duplicated instructions, and heavier generated outputs.
- OpenAI explicitly positions skills as reusable workflows and plugins as the distribution unit, with progressive disclosure so only metadata is loaded initially; that argues for richer composition around fewer strong skills, not flat proliferation ([OpenAI Codex customization](https://developers.openai.com/codex/concepts/customization)). **Confidence**: High.

### Adding More Plugins

- First-order benefit: shareable packaging.
- Second-order cost: more install surfaces, more permission decisions, more marketplace state, and more user confusion around what is global vs repo-local vs target-specific.
- This repo also has an explicit architectural constraint not to introduce new top-level plugins and to keep the plugin name `ycc` stable. That makes plugin multiplication strategically misaligned even before considering maintenance cost. **Confidence**: High.

### Adding Hooks

- First-order benefit: deterministic enforcement, notifications, post-action validation, policy checks.
- Second-order cost: harder debugging, race conditions, portability gaps, and larger prompt-injection/security blast radius when automation can act on external systems or background processes.
- Anthropic and OpenAI both expose hooks, but with materially different behavior and maturity. Cursor's adjacent automation surface is background agents rather than the same hook model, and those require GitHub app permissions with least-privilege repo access ([Anthropic hooks](https://code.claude.com/docs/en/hooks), [OpenAI Codex hooks](https://developers.openai.com/codex/hooks), [Cursor GitHub](https://docs.cursor.com/en/github)).
- OpenAI's security guidance is relevant here: risks increase as agents access more sensitive data and take on more initiative or longer tasks, which is exactly what broad hooks/background automation can enable ([OpenAI prompt injections](https://openai.com/index/prompt-injections/)). **Confidence**: High.

### Improving Generators / Validators / Install Flows

- First-order benefit: less drift.
- Second-order benefit: higher trust in all future additions, because every new workflow is cheaper to ship and safer to evolve.
- This is the classic high-leverage systems intervention: improving information flows and rules beats tweaking parameters or adding more nodes. Meadows explicitly ranks information flows, rules, self-organization, goals, and paradigms above simple parameter tuning ([Donella Meadows, Leverage Points](https://donellameadows.org/archives/leverage-points-places-to-intervene-in-a-system/)). **Confidence**: High.

## Stakeholder Analysis

### Authors

- Want one authoring model, local preview, and minimal target-specific syntax.
- Lose when they must understand platform-specific rewrite rules, naming aliases, or install quirks before adding a skill.
- Current pain signal: source filenames and generated runtime names already diverge in places such as `systems-enginieering-expert` -> `systems-engineering-expert`, `code-researcher` -> `codebase-research-analyst`, and `turso-database-architect` -> `sql-database-architect`. **Confidence**: High.

### Maintainers

- Want deterministic generation, CI-enforced sync, and a small number of concepts to keep updated as Claude/Cursor/Codex evolve.
- Lose when generated outputs drift, when target parity is assumed but false, and when install flows leave stale global state on user machines.
- Their highest-leverage need is compiler discipline, not more user-facing nouns. **Confidence**: High.

### End Users

- Want discoverability, reliable defaults, minimal setup, and consistent mental models.
- Claude users benefit from richer native automation surfaces.
- Cursor users benefit from scoped rules, custom modes, MCP, and background GitHub automation.
- Codex users benefit from a strong layering model (`AGENTS.md` -> skills/plugins -> MCP -> subagents), but today hooks are still experimental and the platform lacks the same slash-command installation story as Claude ([OpenAI Codex customization](https://developers.openai.com/codex/concepts/customization), [OpenAI Codex config reference](https://developers.openai.com/codex/config-reference), [Anthropic subagents](https://code.claude.com/docs/en/sub-agents), [Cursor Rules](https://docs.cursor.com/ru/context/rules), [Cursor Modes](https://docs.cursor.com/zh-Hant/agent/modes)). **Confidence**: High.

### Security / Admin Stakeholders

- Want least privilege, auditable automation, and bounded external access.
- Background agents, hooks, MCP, and plugins all widen the action surface.
- Official platform guidance converges on approvals, sandboxing, scoped permissions, and explicit user control, which means additions that bypass those controls will raise long-term governance cost ([OpenAI Codex config reference](https://developers.openai.com/codex/config-reference), [OpenAI prompt injections](https://openai.com/index/prompt-injections/), [Cursor GitHub](https://docs.cursor.com/en/github)). **Confidence**: High.

## Causal Chains

### Chain 1: Skill Proliferation -> Selection Ambiguity -> Lower Real Utility

- More narrow skills increase match overlap.
- Overlap makes implicit triggering less predictable.
- Unpredictability drives users toward explicit invocation only.
- That reduces the practical value of the larger catalog.

This is why strong descriptions, progressive disclosure, and bounded roles matter more than raw skill count ([OpenAI Codex customization](https://developers.openai.com/codex/concepts/customization), [OpenAI Codex subagents](https://developers.openai.com/codex/concepts/subagents)). **Confidence**: High.

### Chain 2: Target Exceptions -> Generator Complexity -> Validation Drift -> Install Confusion

- Each target-specific rewrite adds branches in the compiler path.
- More branches create more drift opportunities.
- Drift means user install state may not match source intent.
- That undermines trust in the single-source-of-truth architecture.

Local validation failures and naming divergence are direct evidence. **Confidence**: High.

### Chain 3: More Automation -> More Authority -> More Security Burden

- Hooks, MCP, plugins, and background agents increase what the system can do.
- More authority increases the cost of mistakes, prompt injection, and stale permissions.
- That forces stronger approvals, sandboxing, and policy reviews.
- More policy friction can erase the usability gains of the new automation.

**Confidence**: High.

## Unintended Consequences

- A bigger skill catalog can make the system feel less capable if users stop trusting implicit selection. **Confidence**: High.
- More target-native special cases can turn the generators into an unowned compatibility layer rather than a reliable compiler. **Confidence**: High.
- Hooks intended as quality gates can become hidden state that only maintainers understand, especially when async/background behavior differs by platform. **Confidence**: High.
- Broad automation can unintentionally push the repo toward enterprise policy tooling and permission management rather than developer workflow utility. **Confidence**: Medium.

### What Should Not Be Added

- Do not add new top-level plugins. The repo explicitly rejects that direction and it would fragment install/discovery. **Confidence**: High.
- Do not add target-specific workflow features unless they can be represented in a shared authoring model plus a capability matrix. Otherwise maintenance cost compounds. **Confidence**: High.
- Do not default-enable write-heavy hooks/background automation across all targets. Platform maturity and security controls are too uneven. **Confidence**: High.
- Do not add skills that are just thin wrappers over existing built-ins unless they materially improve composition or enforce repo-specific workflow. **Confidence**: High.

## Leverage Points

The best interventions are not at the parameter level. Following Meadows, `ycc` should prioritize information flows, rules, self-organization, and system goals over adding more nodes to the graph ([Donella Meadows, Leverage Points](https://donellameadows.org/archives/leverage-points-places-to-intervene-in-a-system/)).

| Intervention                                                                             | Why it is high leverage                                                                      | Impact | Feasibility | Strategic fit |
| ---------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- | ------ | ----------- | ------------- |
| Introduce a machine-readable capability matrix for Claude/Cursor/Codex                   | Makes target gaps explicit and lets generators/validators reject unsupported semantics early | High   | High        | High          |
| Treat `ycc/` as a formal intermediate representation with target compilers               | Reduces ad-hoc transforms and centers additions on portable primitives                       | High   | Medium      | High          |
| Add CI + pre-commit drift gates that run generator checks and install smoke tests        | Converts drift from local surprise into immediate feedback                                   | High   | High        | High          |
| Add a `doctor`-style installed-state verifier for user surfaces                          | Improves information flow between repo state and actual runtime state                        | High   | Medium      | High          |
| Rationalize naming so source filenames, frontmatter names, and generated agent ids align | Lowers author confusion and cross-target mismatch                                            | Medium | High        | High          |
| Prefer a few composable primitives over more user-facing wrappers                        | Improves maintainability without reducing real utility                                       | High   | Medium      | High          |
| Add optional policy packs/hooks rather than core default hooks                           | Preserves safety without forcing weakest-target parity                                       | Medium | Medium      | High          |

### Highest-Leverage Recommendation

Define a small, target-agnostic authoring schema for:

- workflow type
- delegation model
- allowed tools / permissions
- external dependencies (MCP, GitHub, scripts)
- installable surfaces
- capability requirements by target

Then compile from that schema into Claude/Cursor/Codex outputs and validate against a target matrix. That would shift `ycc` from "repo with generated copies" to "portable workflow platform." **Confidence**: High.

## System Boundaries

### Inside the System

- `ycc/` source trees
- generators
- validators
- generated target bundles
- install surfaces in user config directories
- marketplace metadata

### Outside the System

- official Claude/Cursor/Codex runtime behavior and feature maturity
- GitHub app permissions and external services
- user machine state and trust configuration
- security environment and prompt-injection threat model

### Hard Constraints

- `ycc/` is the source of truth.
- `.cursor-plugin/` and `.codex-plugin/` are generated.
- plugin name `ycc` must remain stable.
- no new top-level plugins.
- Codex does not install this repo's custom slash-command layer directly; the native install surface is plugin + custom agents + marketplace metadata ([README.md](../../../README.md)). **Confidence**: High.

## Emergent Properties

- `ycc` is emerging as a portability layer across agent ecosystems, not merely a plugin bundle. **Confidence**: High.
- Drift is an architectural symptom, not a cosmetic one; it shows the system is already under compiler/distribution pressure. **Confidence**: High.
- The real competitive advantage of `ycc` is likely to be curated composition and cross-target portability, not raw catalog breadth. **Confidence**: High.
- As automation surfaces grow, the repo will naturally accumulate policy, approval, and security concerns unless those are isolated as optional layers. **Confidence**: High.

## Key Insights

1. The strongest addition is not a new skill or plugin. It is a formal shared model for authoring and validating portable workflows. **Confidence**: High.
2. The current system already proves that source-of-truth + generated targets is the right direction, but the drift failures show the enforcement loop is still too weak. **Confidence**: High.
3. More surface area should be treated as expensive by default; more composition power should be treated as cheap by default. **Confidence**: High.
4. Hooks are best treated as optional policy modules, because target parity and maturity are uneven. **Confidence**: High.
5. The most durable user value will come from stronger install/doctor/validator flows and clearer capability boundaries, because those reduce friction for every future addition. **Confidence**: High.

## Evidence Quality

- **Local repository evidence**: High. Direct inspection of [`README.md`](../../../README.md), [`install.sh`](../../../install.sh), generator/validator scripts, generated trees, and installed surfaces.
- **Official platform documentation**: High for Codex and Anthropic; Medium for some Cursor nuances where the official pages were easiest to access via search snippets rather than stable text extraction.
- **Systems-thinking source**: High for leverage-point framing from Donella Meadows.
- **Security framing**: High from OpenAI's official prompt-injection post; applicability to `ycc` is an inference, but a well-supported one.

Overall evidence quality is **High**, with the main caveat that some Cursor details come from official doc snippets rather than line-extracted pages.

## Contradictions & Uncertainties

- **Contradiction**: More explicit user-facing surface can improve discoverability, but it also raises maintenance cost and skill-selection ambiguity. Both are true.
- **Contradiction**: Hooks increase deterministic enforcement, but cross-target parity is poor. Anthropic hooks are broad, Codex hooks are experimental and partial, and Cursor's analogous surface is not the same mechanism.
- **Contradiction**: A single-plugin strategy reduces product fragmentation, but it increases the need for strong internal modularity. Without stronger composition primitives, "one plugin" can still become an unbounded monolith.
- **Uncertainty**: Cursor's current official docs are harder to extract cleanly via text fetch than Anthropic/OpenAI docs, so some Cursor-specific nuance may be under-captured.
- **Uncertainty**: I did not inspect CI configuration in depth, so I cannot yet say whether drift detection is already enforced outside local scripts.

## Search Queries Executed

1. `Anthropic Claude Code subagents hooks documentation official`
2. `OpenAI Codex custom agents plugins documentation official`
3. `Cursor docs rules agents custom modes official`
4. `VS Code extension architecture contribution points manifest design official`
5. `Claude Code subagents official docs site:docs.anthropic.com`
6. `Claude Code hooks official docs site:docs.anthropic.com`
7. `site:docs.cursor.com rules cursor docs`
8. `site:docs.cursor.com "Background Agents" Cursor`
9. `site:code.visualstudio.com extension manifest package.json contribution points`
10. `Donella Meadows leverage points places to intervene in a system pdf`
11. `OpenAI prompt injection background agents blog official`
12. `Codex hooks AGENTS.md plugins skills customization hooks documentation`
