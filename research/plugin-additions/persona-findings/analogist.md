# Analogist Findings: `plugin-additions`

## Executive Summary

The strongest cross-domain analogy is that `ycc` now looks less like a single prompt bundle and more like a small platform: one source tree, many capabilities, multiple generated targets, and a growing need for discovery, reuse, and compatibility control. The adjacent systems that handle this well do four things consistently: they use explicit manifests for discovery, they define narrow extension points instead of arbitrary code injection, they package reusable automation blocks separately from top-level workflows, and they enforce compatibility with verifiers or root-scoped overrides rather than ad hoc fixes.

For `ycc`, that points to six high-value additions:

1. A generated capability manifest and discovery index for skills, agents, rules, hooks, and target support.
2. A reusable workflow-block layer so large skills compose smaller typed building blocks.
3. A scoped override and preset model that keeps the single-plugin `ycc` design intact while allowing curated packs and local policy.
4. A first-class lifecycle hook system with explicit stages, opt-in execution, and skip controls.
5. A unified compatibility verifier plus migration engine across Claude, Cursor, and Codex outputs.
6. A versioned prompt/policy asset library for reusable instruction fragments, templates, and schemas.

The common thread is leverage through stronger metadata and composition, not by adding an open-ended marketplace inside `ycc`.

## Local Baseline

- `ycc` already consolidated a wide surface into one bundle: 34 skills and 50 agents, with separate generated compatibility trees for Cursor and Codex. That improves install simplicity, but it also raises the discovery and maintenance burden because the user-facing surface is now much broader than a single plugin normally implies. Source: local repo [`README.md:3-10`](../../../README.md), [`README.md:87-199`](../../../README.md).
- The repo already behaves like a multi-target build system. `install.sh` orchestrates target-specific steps, while generation and validation are split across several scripts. Source: local repo [`install.sh:1-120`](../../../install.sh), [`README.md:91-141`](../../../README.md).
- Some reuse exists, but it is uneven. Codex generation centralizes shared transforms in [`scripts/generate_codex_common.py:14-192`](../../../scripts/generate_codex_common.py), while Cursor generation still repeats transform/sync logic in separate generators such as [`scripts/generate_cursor_skills.py:17-260`](../../../scripts/generate_cursor_skills.py). Source: local repo.
- Discovery is currently narrow and heuristic-driven in places. The `init` skill generates an MCP catalog from filesystem scans and hardcoded categories, but there is no equivalent capability index for skills, agents, rules, or hook surfaces. Source: local repo [`ycc/skills/init/scripts/generate-mcp-catalog.sh:3-18`](../../../ycc/skills/init/scripts/generate-mcp-catalog.sh), [`ycc/skills/init/scripts/generate-mcp-catalog.sh:80-164`](../../../ycc/skills/init/scripts/generate-mcp-catalog.sh).

## Major Findings

### 1. Add a typed capability manifest and generated discovery catalog

**Recommendation**: Add a small schema per skill/agent/rule bundle, then generate a searchable catalog for `ycc` itself and for each target. The schema should cover at least:

- capability category
- use-case tags
- required tools/connectors
- compatible targets (`claude`, `cursor`, `codex`)
- maturity/stability
- optional dependencies
- related skills/agents
- maintenance owner or source-of-truth

This should feed:

- a generated `capabilities.json` or `catalog.json`
- a richer `init`/discovery flow
- docs pages sorted by capability instead of only by folder name
- compatibility checks that fail when metadata and generated outputs drift

**Why this analogy fits**

- npm’s `package.json` treats metadata such as `description`, `keywords`, `exports`, `bin`, and `funding` as first-class package surface, not decoration. That is what allows packages to be discoverable, installable, and safely consumed through a stable manifest rather than README archaeology. Source: npm `package.json` docs, especially the package metadata sections and manifest role in package behavior: <https://docs.npmjs.com/cli/v11/configuring-npm/package-json/>.
- VS Code extensions expose capabilities through the extension manifest, including `activationEvents`, dependency declarations, extension packs, and capability declarations. That lets the platform decide when an extension should wake up and what it contributes. Source: VS Code extension manifest docs: <https://code.visualstudio.com/api/references/extension-manifest>.
- JetBrains uses `plugin.xml` and dependency declarations for plugin capabilities and compatibility boundaries, reinforcing that discoverability and compatibility are manifest problems before they are UX problems. Source: JetBrains Plugin Configuration File docs: <https://plugins.jetbrains.com/docs/intellij/plugin-configuration-file.html>.

**What `ycc` can adapt without copying blindly**

- Do not build an npm-style public registry inside `ycc`.
- Do adopt the manifest principle: capability discovery should come from generated metadata, not from scanning directories and hoping naming conventions stay stable.

**Confidence**: High. Multiple mature ecosystems use explicit manifests as the control plane for discovery and compatibility, and local repo evidence shows `ycc` currently lacks that control plane beyond raw file layout.

### 2. Add reusable workflow blocks beneath top-level skills

**Recommendation**: Introduce a `ycc/workflows/` or `ycc/blocks/` layer for typed, reusable building blocks that top-level skills compose. Examples:

- `analyze-repo`
- `gather-stack-context`
- `select-validation-matrix`
- `render-report`
- `collect-review-findings`
- `materialize-plan-artifacts`

Each block should declare inputs, outputs, target constraints, and validation hooks. Skills would become orchestrators of blocks rather than long monolithic prompts plus scattered helper scripts.

**Why this analogy fits**

- GitHub Actions explicitly separates reusable workflows from composite actions. Reusable workflows are full-job orchestration; composite actions are step-level reuse. That distinction is valuable because not every repeated pattern should become a full workflow. Source: GitHub reusable workflows docs: <https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows>; composite actions docs: <https://docs.github.com/en/actions/sharing-automations/creating-actions/creating-a-composite-action>.
- Nx plugins differentiate generators, inferred tasks, migrations, and repository presets. The point is not “make everything a plugin”; it is “factor repeated repo behavior into reusable devkit primitives.” Source: Nx “Extending Nx with Plugins”: <https://nx.dev/docs/extending-nx/intro>.
- Buildkite plugins operate at the step level, and multiple plugins can run in a single step in a defined order. That is a strong analogy for small reusable `ycc` workflow units that can be sequenced under a larger skill. Source: Buildkite “Using plugins”: <https://buildkite.com/docs/pipelines/integrations/plugins/using>.

**What `ycc` can adapt without copying blindly**

- Keep top-level skills as the user-facing API.
- Move repeated inner mechanics into typed blocks so skills stop duplicating orchestration prose and validation instructions.
- Generate target-specific translations from the same block metadata, instead of baking target wording directly into many top-level prompts.

**Confidence**: High. The local repo already contains orchestration-heavy skills and generator scripts, so a reusable lower-level block layer would directly reduce duplication and improve consistency.

### 3. Add curated presets and root-scoped overrides instead of a general plugin marketplace

**Recommendation**: Add curated “packs” or “presets” inside `ycc`, plus a root-scoped override file such as `ycc.compat.yaml` or `ycc.overrides.yaml`. Presets could bundle skills, agents, rules, and hooks for common contexts:

- `web-app`
- `github-maintainer`
- `research-heavy`
- `rust-library`
- `docs-first`

Overrides should be root-owned and able to:

- disable or replace specific generated artifacts
- pin target-specific rewrites
- mark skills as hidden/experimental
- redirect capability aliases
- force a specific validation policy for a target

**Why this analogy fits**

- Homebrew draws a boundary between core formulae and external taps, and it namespaces external commands under `brew-<name>`. That curation pattern matters: external growth is allowed, but not at the cost of collapsing maintenance boundaries. Source: Homebrew Taps and External Commands docs: <https://docs.brew.sh/Taps>, <https://docs.brew.sh/External-Commands>.
- Bazel’s Bzlmod keeps version and registry control rooted in the top-level module. Only the root module’s overrides take effect; transitive overrides are ignored. That is exactly the kind of maintenance boundary `ycc` needs as target-specific compatibility logic grows. Source: Bazel modules docs: <https://bazel.build/versions/9.0.0/external/module>.
- VS Code uses workspace recommendations and extension packs to guide adoption without forcing a giant default install. Source: VS Code Extension Marketplace docs: <https://code.visualstudio.com/docs/configure/extensions/extension-marketplace>.

**What `ycc` can adapt without copying blindly**

- Keep `ycc` as the only top-level plugin, consistent with repo policy.
- Add curated internal packs and root-owned overrides rather than user-installable third-party mini-plugins.
- Treat local overrides as authoritative the way Bazel treats root overrides: transitive packs should not silently rewrite repo policy.

**Confidence**: High. The analogy matches both the repo’s explicit “single-plugin `ycc`” constraint and the multi-target compatibility problem already present in the codebase.

### 4. Add a first-class hook lifecycle with explicit stages, logging, and skip controls

**Recommendation**: Define a narrow lifecycle hook API for `ycc`, likely covering:

- `pre-generate`
- `post-generate`
- `pre-validate`
- `post-validate`
- `pre-install`
- `post-install`
- `session-stop`

Each hook should be:

- opt-in
- named
- target-scoped
- dry-run visible
- logged in artifacts
- individually skippable

Do not allow arbitrary hidden hook execution; require explicit registration and execution traces.

**Why this analogy fits**

- Buildkite exposes well-defined hook points and plugins, which create leverage because automation can attach to stable lifecycle moments instead of every team inventing custom shell glue. Plugins run in declared order, which is critical when behavior composes. Source: Buildkite plugin docs: <https://buildkite.com/docs/pipelines/integrations/plugins/using>. Buildkite’s pipeline webhooks also show how event surfaces become integration points once lifecycle is explicit: <https://buildkite.com/docs/apis/webhooks/pipelines>.
- pre-commit shows the value of stage-specific hooks and targeted escape hatches. Its `SKIP` environment variable disables a single hook rather than bypassing the entire enforcement layer, which is a much better ergonomics/safety tradeoff than blanket disablement. Source: <https://pre-commit.com/>.
- Nx exposes task lifecycle hooks and sync generators as explicit automation surfaces rather than requiring every plugin author to patch task execution ad hoc. Source: Nx docs: <https://nx.dev/docs/extending-nx/intro>.

**What `ycc` can adapt without copying blindly**

- Start with repo-local hooks tied to generation/validation/install, not session-global arbitrary execution.
- Support a `YCC_SKIP=hook-a,hook-b` model or equivalent.
- Emit hook execution into reports so automation stays inspectable.

**Confidence**: Medium-High. The external pattern is strong, but hook systems are easy to overdo. The value is real only if `ycc` keeps the lifecycle narrow and observable.

### 5. Add a unified compatibility verifier and migration engine

**Recommendation**: Add a single `ycc:doctor` or `ycc:verify-targets` capability that understands:

- target compatibility matrix
- generated artifact drift
- banned token residue
- manifest/schema drift
- required regeneration steps
- prompt/block compatibility
- deprecations and migrations between `ycc` versions

Pair it with a lightweight migration system so structural changes are encoded as migrations, not README footnotes.

**Why this analogy fits**

- JetBrains runs Plugin Verifier to check binary compatibility across IDE versions and explicitly positions it as a CI quality gate. Source: JetBrains “Verifying Plugin Compatibility”: <https://plugins.jetbrains.com/docs/intellij/verifying-plugin-compatibility.html>.
- Bazel registries can yank versions and the module system enforces explicit override mechanics instead of silently accepting bad states. Source: Bazel modules docs: <https://bazel.build/versions/9.0.0/external/module>.
- Nx explicitly includes migrations as part of plugin design, which is the right mental model for evolving repository automation safely over time. Source: <https://nx.dev/docs/extending-nx/intro>.

**Local fit**

- Today, verification is spread across multiple shell scripts and target-specific checks. That is better than nothing, but it is a fragmented verifier rather than a single compatibility product. Sources: local repo [`scripts/validate-codex-skills.sh:1-57`](../../../scripts/validate-codex-skills.sh), [`scripts/validate-cursor-skills.sh:1-31`](../../../scripts/validate-cursor-skills.sh), [`README.md:182-199`](../../../README.md).

**What `ycc` can adapt without copying blindly**

- Keep existing validators as subchecks.
- Add one top-level compatibility report that explains failures in user terms and suggests the exact regeneration/migration steps.
- Track deprecations and aliases explicitly so target compatibility stops depending on prompt rewrite heuristics alone.

**Confidence**: High. This is directly supported by both adjacent ecosystem practice and the repo’s current shape.

### 6. Add a versioned prompt/policy asset library

**Recommendation**: Add a first-class library for reusable prompt fragments, schemas, rubrics, and policy text, with:

- named assets
- semantic version or tag aliases
- deprecation markers
- optional caching
- usage references from skills and agents

This is not a request for a social prompt marketplace. It is a request for a managed internal asset layer so repeated instruction fragments stop living as copy-paste across dozens of skills and agents.

**Why this analogy fits**

- LangSmith prompt management treats prompts as pullable assets with commit hashes, commit tags, public/private visibility, and SDK-level caching using stale-while-revalidate semantics. That demonstrates a mature model for versioned prompt assets that can evolve safely. Source: LangSmith “Manage prompts programmatically”: <https://docs.langchain.com/langsmith/manage-prompts-programmatically>.
- npm dist-tags and package metadata are a reminder that “latest”, “stable”, and “experimental” are often better expressed as tags on reusable assets than as informal naming in docs. Source: npm docs: <https://docs.npmjs.com/cli/v11/configuring-npm/package-json/>.

**What `ycc` can adapt without copying blindly**

- Keep the asset scope internal to the repo and generated outputs.
- Use versioned prompt/policy assets for repeated rubrics, report templates, research structures, review severity definitions, and target-specific wording.
- Generate an asset usage graph so owners can see when changing a shared prompt will ripple across skills/agents.

**Confidence**: Medium. The leverage is real, but the asset library only pays off if `ycc` first commits to stronger manifesting and reuse boundaries.

## Reusable Abstractions `ycc` Should Introduce

The adjacent ecosystems converge on a small number of abstractions that `ycc` can reuse across skills, agents, and scripts:

1. **Capability manifest**
   Source of truth for discovery, dependencies, target support, maturity, and ownership.

2. **Workflow block**
   Typed reusable unit beneath a skill, analogous to a composite action, Nx generator, or Buildkite step plugin.

3. **Preset/pack**
   Curated bundle of capabilities for a common context, analogous to extension packs, repository presets, or taps.

4. **Root-scoped override**
   Local policy that can pin, replace, or disable generated behavior without letting transitive dependencies rewrite everything.

5. **Hook registration**
   Narrow lifecycle attachment point with logging and skip semantics.

6. **Compatibility verifier**
   One top-level health product that aggregates target-specific validators and migration advice.

7. **Versioned asset registry**
   Shared prompt/policy/template store with tags, deprecations, and reference tracking.

## Where Hooks and Automation Surfaces Create Leverage

The most transferable lesson from CI/build/tooling ecosystems is that hooks create leverage only when they are attached to stable lifecycle boundaries. The high-value hook surfaces for `ycc` are not “run arbitrary code whenever anything happens”; they are the moments that already exist in the repo’s workflow:

- generation start/end
- validation start/end
- install target start/end
- report finalization
- session close

That is where automation can enforce consistency, generate secondary artifacts, or collect telemetry-like diagnostics. Buildkite and pre-commit both show the same principle: explicit stages create reusable leverage; hidden global automation creates confusion. Sources: <https://buildkite.com/docs/pipelines/integrations/plugins/using>, <https://buildkite.com/docs/apis/webhooks/pipelines>, <https://pre-commit.com/>.

## Contradictions and Tensions

### More metadata improves discovery but increases authoring overhead

- npm/VS Code/JetBrains all benefit from richer manifests.
- But richer manifests also create more fields to maintain.
- `ycc` should avoid bloated schemas. Start with the smallest manifest that unlocks discovery, compatibility, and reuse.

**Confidence**: High. This tradeoff appears in every plugin ecosystem.

### Hook systems create leverage but also hidden behavior

- Buildkite and pre-commit succeed because hooks are explicit and scoped.
- Many internal automation systems fail because hooks become invisible policy traps.
- `ycc` should only ship hooks that are named, logged, and individually skippable.

**Confidence**: High. Strong ecosystem evidence and repeated industry experience.

### Versioned prompt assets reduce duplication but can hide prompt drift

- LangSmith-style versioning is compelling.
- But prompt indirection makes it harder to reason about behavior unless usage is visible and versions are pinned.
- `ycc` should not add a prompt asset layer before it adds usage tracing and compatibility metadata.

**Confidence**: Medium. The pattern is strong, but the operational failure mode is real.

### Internal packs fit `ycc`; an open plugin marketplace probably does not

- Homebrew taps and VS Code marketplace patterns show how ecosystems can scale.
- But this repo explicitly treats `ycc` as the stable top-level bundle and warns against introducing new top-level plugins.
- The right adaptation is curated internal packs and overrides, not a second marketplace inside the repo.

**Confidence**: High. Strong fit with repo constraints and adjacent-system lessons.

## What Should Not Be Added

- **Do not add a free-form third-party plugin loader inside `ycc`.** It would fight the repo’s single-plugin design and sharply increase compatibility burden. Source: local repo policy in `AGENTS.md` and repository instructions.
- **Do not add opaque global hooks.** If users cannot tell what ran, when, and why, the hook system becomes maintenance debt faster than it creates leverage.
- **Do not add duplicate target-specific skill forks as the primary reuse model.** The current generator model is already carrying target translation complexity; more divergence would worsen the problem rather than solve it.
- **Do not add a public prompt marketplace before internal asset versioning exists.** That would import trust, provenance, and review problems before `ycc` has the metadata and verification surfaces to manage them.

## Prioritized Additions

| Addition                                    | Impact      | Feasibility | Strategic Fit | Why                                                             |
| ------------------------------------------- | ----------- | ----------- | ------------- | --------------------------------------------------------------- |
| Capability manifest + discovery index       | High        | Medium      | High          | Unlocks discovery, compatibility, packs, and verifiers          |
| Unified compatibility verifier + migrations | High        | Medium      | High          | Converts fragmented validation into a user-facing product       |
| Reusable workflow blocks                    | High        | Medium      | High          | Reduces duplication across large skills and scripts             |
| Curated presets + root overrides            | Medium-High | Medium      | High          | Fits single-plugin design while improving onboarding and policy |
| Explicit hook lifecycle                     | Medium      | Medium      | Medium-High   | Creates leverage if kept narrow and observable                  |
| Versioned prompt/policy assets              | Medium      | Medium-Low  | Medium        | Valuable later, after manifests and tracing exist               |

## Sources

### Local repo sources

- `README.md` (local repo), especially installation, target sync, and generation/validation sections.
- `scripts/generate_codex_common.py` (local repo), shared Codex transform logic.
- `scripts/generate_cursor_skills.py` (local repo), Cursor transform/sync logic.
- `scripts/validate-codex-skills.sh` and `scripts/validate-cursor-skills.sh` (local repo), fragmented validation surfaces.
- `ycc/skills/init/scripts/generate-mcp-catalog.sh` (local repo), current discovery/catalog behavior.

### External sources

- npm `package.json` docs: <https://docs.npmjs.com/cli/v11/configuring-npm/package-json/>. Accessed 2026-04-16.
- Homebrew Taps: <https://docs.brew.sh/Taps>. Accessed 2026-04-16.
- Homebrew External Commands: <https://docs.brew.sh/External-Commands>. Accessed 2026-04-16.
- Bazel modules: <https://bazel.build/versions/9.0.0/external/module>. Last updated 2026-02-26 UTC on page.
- Bazel Bzlmod overview: <https://bazel.build/docs/bzlmod>. Accessed 2026-04-16.
- Nx “Extending Nx with Plugins”: <https://nx.dev/docs/extending-nx/intro>. Accessed 2026-04-16.
- VS Code extension manifest: <https://code.visualstudio.com/api/references/extension-manifest>. Accessed 2026-04-16.
- VS Code Extension Marketplace: <https://code.visualstudio.com/docs/configure/extensions/extension-marketplace>. Accessed 2026-04-16.
- JetBrains Plugin Configuration File: <https://plugins.jetbrains.com/docs/intellij/plugin-configuration-file.html>. Accessed 2026-04-16.
- JetBrains Verifying Plugin Compatibility: <https://plugins.jetbrains.com/docs/intellij/verifying-plugin-compatibility.html>. Accessed 2026-04-16.
- GitHub reusable workflows: <https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows>. Accessed 2026-04-16.
- GitHub composite actions: <https://docs.github.com/en/actions/sharing-automations/creating-actions/creating-a-composite-action>. Accessed 2026-04-16.
- Buildkite “Using plugins”: <https://buildkite.com/docs/pipelines/integrations/plugins/using>. Accessed 2026-04-16.
- Buildkite pipeline webhooks: <https://buildkite.com/docs/apis/webhooks/pipelines>. Accessed 2026-04-16.
- LangSmith “Manage prompts programmatically”: <https://docs.langchain.com/langsmith/manage-prompts-programmatically>. Accessed 2026-04-16.
- pre-commit docs: <https://pre-commit.com/>. Accessed 2026-04-16.

## Search Queries Executed

1. `site:docs.npmjs.com package.json keywords discoverability npm official docs`
2. `site:docs.brew.sh Homebrew taps external commands audit official docs`
3. `site:bazel.build bazel bzlmod module extensions registry official docs`
4. `site:nx.dev plugins generators executors inferred tasks official docs`
5. `site:code.visualstudio.com extension manifest activation events contribution points official docs`
6. `site:plugins.jetbrains.com/docs/intellij plugin.xml extension points optional dependencies verifier official docs`
7. `site:docs.github.com reusable workflows composite actions official docs`
8. `site:buildkite.com/docs plugins hooks official docs`
9. `site:docs.langchain.com langsmith prompt hub versioning tags commits official docs`
10. `site:pre-commit.com supported git hooks stages local repository docs`

## Uncertainties and Gaps

- I did not find a perfect one-to-one analogy for “skills + agents + generated target bundles” in a single product, so the recommendations intentionally synthesize across package, plugin, CI, and prompt ecosystems rather than importing one model wholesale.
- Nx and JetBrains provide strong patterns for migrations and compatibility, but mapping those directly onto prompt/agent assets would still require schema design work inside `ycc`.
- The report assumes the repo will continue treating `ycc/` as the sole source of truth and will not pursue a multi-plugin architecture, consistent with current repo instructions. If that architectural constraint changes, the recommendation set would change materially.
