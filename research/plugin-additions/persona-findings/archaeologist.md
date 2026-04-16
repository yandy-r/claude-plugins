# Archaeologist Research: Obsolete and Superseded Approaches Relevant to `ycc`

## Executive Summary

The closest historical ancestors to `ycc` are not old AI systems so much as older developer workflow ecosystems: Yeoman generators, Grunt-era task layers, Hubot script packs, Vim plugin managers, Package Control registries, shell mega-bundles, Git hook managers, and Jenkins shared libraries. Those systems solved the same underlying problem as `ycc` does now: packaging reusable workflow behavior, distributing it cheaply, and making it discoverable enough to become habit. [README](../../../README.md), [Yeoman](https://yeoman.io/learning/index.html), [Hubot](https://hubot.github.com/docs/), [Jenkins Shared Libraries](https://www.jenkins.io/doc/book/pipeline/shared-libraries/)

What became obsolete was rarely the idea of reusable workflow bundles. What became obsolete was the combination of plugin sprawl, host-specific DSLs, weak migration paths, uncurated registries, and abstractions that outlived the platform gaps they were invented to fill. The strongest migration lesson for a single-bundle plugin like `ycc` is to act like a curated distribution with explicit deprecation metadata and thin wrappers over durable platform primitives, not like an open-ended plugin marketplace. [Package Control](https://packagecontrol.io/docs/submitting_a_package), [npm scripts](https://docs.npmjs.com/cli/v11/using-npm/scripts/), [Vite](https://vite.dev/guide/), [Slack legacy migration](https://docs.slack.dev/legacy/legacy-custom-integrations/legacy-custom-integrations-migration)

## Old Solutions

### 1. Yeoman + generator packs as the earlier "skills plus generators" model

- **What it was**: Yeoman described itself as a "generic scaffolding system" where `yo` was the front door and `generator-*` packages were the extensibility unit. Generators could scaffold whole projects or sub-generators for smaller project parts. [Yeoman](https://yeoman.io/learning/index.html)
- **How it maps to `ycc`**: This is the clearest pre-agent analogue to `ycc` skills plus generators. `yo <generator>` maps well to `$skill-name` or target-specific generation scripts in this repo. The repo README already treats generation as first-class, with `ycc/` as source and Codex/Cursor outputs as generated compatibility surfaces. [README](../../../README.md)
- **What became obsolete**: The "generic scaffolding hub + many generator packages" model lost primacy as framework-specific CLIs and lighter templates became the default. Vite now makes scaffolding a single `npm create vite@latest` step and ships typed defaults and templates as the main path. [Vite](https://vite.dev/guide/)
- **Why**: Once package managers, templates, and framework-native CLIs got better, a universal generator layer became extra indirection. Yeoman itself notes that generators often depend on `npm scripts`, `Grunt`, or `Gulp`, which is exactly the sign of an ecosystem whose abstraction stack got too tall. [Yeoman](https://yeoman.io/learning/index.html), [npm scripts](https://docs.npmjs.com/cli/v11/using-npm/scripts/)
- **Confidence**: High. The primary sources directly document both the old model and the thinner replacements.

### 2. Grunt and Gulp as CLI workflow layers above simpler primitives

- **What it was**: Grunt sold itself as a task runner for repetitive automation with "literally hundreds of plugins." It centralized minification, compilation, tests, and linting behind a Gruntfile and plugin ecosystem. [Grunt](https://gruntjs.com/)
- **How it maps to `ycc`**: This resembles the repo's higher-order workflow orchestration skills: a single entrypoint coordinating repeatable tasks across projects and teams. [README](../../../README.md)
- **What became obsolete**: For many projects, Grunt-style orchestration stopped being the preferred layer once package managers and framework CLIs covered the common cases directly. npm now treats the `scripts` field as a built-in command surface with pre/post lifecycle hooks. Vite scaffolded projects expose a tiny `dev` / `build` / `preview` script surface by default. [npm scripts](https://docs.npmjs.com/cli/v11/using-npm/scripts/), [Vite](https://vite.dev/guide/)
- **Why**: The extra DSL stopped paying for itself once the host platform had native lifecycle hooks and standard entrypoints. This is the strongest warning for `ycc`: do not invent an internal workflow DSL where a thin wrapper plus generated files is enough.
- **Confidence**: High. This is a well-documented historical migration visible in official docs.

### 3. Hubot script packs and ChatOps bot shells as early "agent packs"

- **What it was**: Hubot documented a model made of a generator, adapters, scripts, and a shell. Creating a bot meant `npm install -g yo generator-hubot`, then `yo hubot`, then choosing an adapter for the chat provider. [Hubot](https://hubot.github.com/docs/)
- **How it maps to `ycc`**: Hubot is an earlier version of "package reusable behavior, install it into a host, and extend it with discrete capabilities." Script packs and adapters strongly resemble skills plus target-specific generators.
- **What became obsolete**: The multi-layer stack of generator -> bot shell -> adapter -> script pack became fragile as chat platforms shifted toward first-party app frameworks, richer auth models, and platform-owned automation primitives. Slack's legacy docs now repeatedly direct developers away from legacy custom integrations toward Slack apps, Events API, and newer automation surfaces. [Slack legacy migration](https://docs.slack.dev/legacy/legacy-custom-integrations/legacy-custom-integrations-migration), [Slack legacy slash commands](https://docs.slack.dev/legacy/legacy-custom-integrations/legacy-custom-integrations-slash-commands/)
- **Why**: Platform churn turned adapter-heavy middleware into maintenance debt. Slack's deprecation language is blunt: legacy features are one day deprecated and then retired; Steps from Apps had "no direct migration path" when retired. [Slack legacy overview](https://docs.slack.dev/legacy/), [Slack Steps from Apps](https://docs.slack.dev/legacy/legacy-steps-from-apps/)
- **Confidence**: High. The host-platform retirement and migration notices are primary evidence.

### 4. Vim plugin managers and runtime-path bundle loaders

- **What it was**: Vundle managed plugins in `.vimrc`, installed them into `~/.vim/bundle/`, adjusted runtime path, and exposed update / clean commands. Official Vim later added native package loading under `pack/*/start` and `pack/*/opt/{name}` via `:packadd`. [Vundle](https://github.com/VundleVim/Vundle.vim), [Vim packages](https://vimhelp.org/repeat.txt.html#packages)
- **How it maps to `ycc`**: This is the same core problem as multi-target plugin generation: a source-of-truth bundle is installed into a host-specific layout, then loaded through host-native discovery rules.
- **What became obsolete**: The older generation of bundle managers became less essential once the host editor gained a native package mechanism and newer managers focused on speed or simpler semantics. The important pattern is not "plugin manager" but "generated layout that matches host-native loading."
- **Why**: Native loading reduced the need for meta-managers. That parallels this repo's move toward native Codex packaging instead of Cursor-style copying for everything. [README](../../../README.md), [Vim packages](https://vimhelp.org/repeat.txt.html#packages)
- **Confidence**: High. The official Vim docs explicitly show the native package structure; Vundle's repo shows the older runtime-path approach.

### 5. Package Control and curated extension registries

- **What it was**: Package Control positioned itself as the default discovery and update channel for Sublime Text packages. Its submission docs explicitly tell authors to look for similar packages first and "try to improve an existing package before adding another," and note that branch-based releases were deprecated in favor of tags. [Package Control](https://packagecontrol.io/docs/submitting_a_package)
- **How it maps to `ycc`**: `ycc` is not trying to become a marketplace, but it already has registry-adjacent concerns: install surfaces, generated marketplace metadata, naming stability, target-specific packaging, and the repo's deliberate move from nine plugins to one bundle. [README](../../../README.md)
- **What became obsolete**: Uncurated proliferation and weak release metadata. Package Control's docs read like a postmortem on extension sprawl: name collisions, duplicate functionality, and release ambiguity all raise user cost.
- **Why**: Registries become product surfaces in their own right. If `ycc` ever grows more visible catalog or discovery metadata, curation and deprecation policy need to be built in from day one.
- **Confidence**: High. The Package Control guidance is primary and directly relevant.

### 6. Oh My Zsh as the "mega-bundle" distribution pattern

- **What it was**: Oh My Zsh markets itself as a community-driven framework that ships "hundreds of powerful plugins" and 150 themes. [Oh My Zsh](https://ohmyz.sh/)
- **How it maps to `ycc`**: This is the closest historical analogue to the repo's 2.0.0 consolidation into a single umbrella bundle. A user gets one install surface, then chooses among many built-in capabilities. [README](../../../README.md)
- **What worked well**: Discoverability, one-step install, batteries included, and a shared community vocabulary.
- **What aged poorly**: Bundle bloat, variable quality across subcomponents, and long-tail maintenance expectations. Big bundles win adoption but accumulate curation burden fast.
- **Confidence**: Medium. The "bundle bloat" point is partly inferred from the scale of the shipped surface and long-lived ecosystem behavior, not from an explicit official postmortem.

### 7. Overcommit and pre-commit as reusable hook ecosystems

- **What it was**: Overcommit presented itself as a configurable Git hook manager, including repo-specific hooks, shared configuration, plugin directories, concurrency, and signature verification because arbitrary plugin code is a security risk. [Overcommit](https://github.com/sds/overcommit)
- **What replaced or outgrew it**: `pre-commit` reframed the space as a multi-language package manager for hooks, with repository mappings, revision pinning, hook stages, and CI parity. [pre-commit](https://pre-commit.com/)
- **How it maps to `ycc`**: This is a direct precedent for repo-local automation manifests that are shareable, versioned, and runnable both locally and in CI. That is especially relevant to `ycc` generators, validators, and install hooks.
- **Confidence**: High. Both projects document the model clearly in primary sources.

### 8. Jenkins Shared Libraries as reusable organization workflow DSLs

- **What it was**: Jenkins Shared Libraries were created because common pipeline patterns emerged across projects, so teams needed to "share parts of Pipelines" from external SCM repositories and even define a more structured DSL on top. [Jenkins Shared Libraries](https://www.jenkins.io/doc/book/pipeline/shared-libraries/)
- **How it maps to `ycc`**: This is the earlier CI/CD version of `ycc` orchestration: centralize reusable workflow logic, version it, and let projects call into it.
- **What became less attractive**: The more these libraries became mini-DSLs, the more teams were locked to a host-specific automation language. Newer systems emphasize reusable workflows and composite actions with clearer boundaries. [GitHub reusable workflows](https://docs.github.com/en/actions/how-tos/sharing-automations/reuse-workflows)
- **Confidence**: High. The official Jenkins docs explicitly describe both the DRY motivation and the higher-level DSL pattern.

## Obsolete Approaches

### Host-specific DSLs layered above maturing native primitives

- **Finding**: Gruntfiles, deep Jenkins Shared Library DSLs, and Hubot adapter stacks all made sense before native lifecycle scripts, reusable workflows, or first-party app frameworks became strong enough. Once the host platform matured, the wrapper layer became the migration burden. [Grunt](https://gruntjs.com/), [npm scripts](https://docs.npmjs.com/cli/v11/using-npm/scripts/), [Jenkins Shared Libraries](https://www.jenkins.io/doc/book/pipeline/shared-libraries/), [Slack legacy migration](https://docs.slack.dev/legacy/legacy-custom-integrations/legacy-custom-integrations-migration)
- **Why it matters for `ycc`**: Prefer stable composition over custom syntax. Skills should orchestrate host-native capabilities, not hide them behind a second language.
- **Confidence**: High.

### Open-ended plugin proliferation without curation

- **Finding**: Package Control explicitly warns against duplicate packages, and Oh My Zsh's appeal is tied to bundling huge numbers of plugins and themes. Those are two sides of the same scaling problem: choice overload and maintenance drift. [Package Control](https://packagecontrol.io/docs/submitting_a_package), [Oh My Zsh](https://ohmyz.sh/)
- **Why it matters for `ycc`**: The repo's move from nine plugins to one bundle was directionally correct. Re-introducing many top-level plugin identities would replay the same fragmentation problem. [README](../../../README.md)
- **Confidence**: High.

### Integration models dependent on legacy host APIs

- **Finding**: Slack now marks legacy custom integrations, legacy tokens, and Steps from Apps as deprecated or retired, with some features having no direct migration path. [Slack legacy overview](https://docs.slack.dev/legacy/), [Slack legacy tokens](https://docs.slack.dev/legacy/legacy-custom-integrations/legacy-custom-integrations-tokens), [Slack Steps from Apps](https://docs.slack.dev/legacy/legacy-steps-from-apps/)
- **Why it matters for `ycc`**: Any target-specific integration surface should have a deprecation ledger and replacement path before it ships.
- **Confidence**: High.

### Loader hacks after hosts gain native packaging

- **Finding**: Vundle's runtime-path management is historically useful, but official Vim packages made `pack/*/start` and `:packadd` first-class. [Vundle](https://github.com/VundleVim/Vundle.vim), [Vim packages](https://vimhelp.org/repeat.txt.html#packages)
- **Why it matters for `ycc`**: Generate what the host naturally loads. Avoid permanent dependence on compatibility shims once a target has a native plugin model.
- **Confidence**: High.

## Discontinued Methods

### Slack legacy custom integrations and classic bot/app models

- **What happened**: Slack now recommends migrating legacy incoming webhooks, outgoing webhooks, slash commands, and tokens to Slack apps, Events API, and newer auth models. It also stopped allowing creation of new classic apps and legacy custom bot users in 2024. [Slack legacy incoming webhooks](https://docs.slack.dev/legacy/legacy-custom-integrations/legacy-custom-integrations-incoming-webhooks), [Slack legacy outgoing webhooks](https://docs.slack.dev/legacy/legacy-custom-integrations/legacy-custom-integrations-outgoing-webhooks/), [Slack legacy slash commands](https://docs.slack.dev/legacy/legacy-custom-integrations/legacy-custom-integrations-slash-commands/), [Slack classic apps and custom bots changelog](https://docs.slack.dev/changelog/2024-04-discontinuing-new-creation-of-classic-slack-apps-and-custom-bots)
- **Lesson**: Migration advice must exist before host platforms force it. `ycc` should ship deprecation metadata, aliases, and validation warnings for renamed or removed skills instead of letting old entrypoints rot.
- **Confidence**: High.

### Slack Steps from Apps

- **What happened**: Slack retired Steps from Apps for legacy Workflow Builder and stated there was "no direct migration path" for existing steps or workflows. [Slack Steps from Apps](https://docs.slack.dev/legacy/legacy-steps-from-apps/)
- **Lesson**: If `ycc` introduces hooks or generated integration points, they need exportable definitions and a replacement model. The repo should never create a user-facing automation surface that cannot be mechanically translated during a host transition.
- **Confidence**: High.

### Branch-based package releases in registries

- **What happened**: Package Control deprecated branch-based releases and pushed packages toward tagged semantic versions. [Package Control](https://packagecontrol.io/docs/submitting_a_package)
- **Lesson**: If `ycc` exposes bundle metadata or marketplace state, release identity should be explicit and stable. Generated artifacts should point to versioned sources, not floating state.
- **Confidence**: High.

## Historical Constraints

- **Platform immaturity**: Before native package systems, reusable workflow behavior had to live in ad hoc bundle directories, runtime-path hacks, or generator packages. [TextMate Bundles](https://macromates.com/manual/en/bundles), [Vim packages](https://vimhelp.org/repeat.txt.html#packages)
- **Distribution limits**: Before modern registries and package managers stabilized, ecosystems leaned on bespoke search indexes, custom channels, and host-specific installers. [Package Control](https://packagecontrol.io/docs/submitting_a_package), [Yeoman](https://yeoman.io/learning/index.html)
- **Automation gaps**: Before lifecycle hooks and reusable workflows were common, teams built workflow layers in Gruntfiles, shell frameworks, chat bots, and Jenkins libraries. [Grunt](https://gruntjs.com/), [npm scripts](https://docs.npmjs.com/cli/v11/using-npm/scripts/), [Jenkins Shared Libraries](https://www.jenkins.io/doc/book/pipeline/shared-libraries/)
- **Security expectations were lower**: Overcommit's need for signature verification is a reminder that repo-local automation executes arbitrary code and therefore needs trust boundaries. [Overcommit](https://github.com/sds/overcommit)
- **Confidence**: High. These constraints are explicit in the primary docs and strongly explain why the old patterns emerged.

## Forgotten Wisdom

### Context-aware activation beats flat command catalogs

- TextMate bundle items were activated through key equivalents, tab triggers, and scope selectors that interpreted current context. That is a sophisticated idea that modern agent bundles often forget. [TextMate Bundles](https://macromates.com/manual/en/bundles)
- **Modernization for `ycc`**: Add richer skill metadata for applicability by file globs, repo traits, tech stack, or task type so discovery can be contextual instead of alphabetical.
- **Confidence**: High.

### Preserve local overrides while updating shared bundles

- TextMate stored local bundle changes separately so upgrades could preserve custom edits. [TextMate Bundles](https://macromates.com/manual/en/bundles)
- **Modernization for `ycc`**: Preserve user-local overrides for generated config or target-specific install surfaces instead of overwriting them silently.
- **Confidence**: Medium. The TextMate model is clear; the fit to `ycc` requires design work.

### Curated registries should fight duplication early

- Package Control's advice to improve an existing package before adding another is unusually direct and correct. [Package Control](https://packagecontrol.io/docs/submitting_a_package)
- **Modernization for `ycc`**: New skills should require an overlap check against existing `ycc` skills, agents, or generators before being added. This aligns with the repo objective's emphasis on rejecting additions that only expand surface area. [../objective.md](../objective.md)
- **Confidence**: High.

### Hooks should be shareable, versioned, and CI-compatible

- `pre-commit` made hooks portable by treating them as versioned repositories with explicit revisions and stage selection. [pre-commit](https://pre-commit.com/)
- **Modernization for `ycc`**: A `ycc` hook-pack manifest for validators, generators, and install checks could mirror this model without becoming a general marketplace.
- **Confidence**: High.

### Reusable workflow layers should stay DRY, but not become a private language

- Jenkins Shared Libraries explicitly support building a higher-level DSL. That is powerful, but historically these DSLs become lock-in when they drift too far from the host platform. [Jenkins Shared Libraries](https://www.jenkins.io/doc/book/pipeline/shared-libraries/)
- **Modernization for `ycc`**: Prefer manifest-driven composition, codegen, and thin wrappers over a private command language.
- **Confidence**: High.

## Revival Candidates

### 1. Context selectors for skills and agents

- **Revive from**: TextMate scope selectors and activation methods. [TextMate Bundles](https://macromates.com/manual/en/bundles)
- **For `ycc`**: Add metadata such as `applies_when`, `stack_tags`, `repo_globs`, `requires_tools`, and `conflicts_with`. That would help discovery and reduce command overload in a large single bundle.
- **Confidence**: Medium. Strong pattern, but implementation details are repo-specific.

### 2. A curated internal registry with deprecation and overlap metadata

- **Revive from**: Package Control's anti-duplication rules and tagged releases. [Package Control](https://packagecontrol.io/docs/submitting_a_package)
- **For `ycc`**: Keep one bundle, but enrich the manifest with fields like `status`, `replacement`, `introduced_in`, `deprecated_in`, `targets`, and `overlaps_with`.
- **Confidence**: High.

### 3. Hook-pack style validation bundles

- **Revive from**: Overcommit and pre-commit. [Overcommit](https://github.com/sds/overcommit), [pre-commit](https://pre-commit.com/)
- **For `ycc`**: Package generator/validator/install checks as named bundles that can run in local development, install time, and CI with the same manifest.
- **Confidence**: High.

### 4. Migration mode and shadow compatibility for bundle restructures

- **Revive from**: Slack's painful example of retiring Steps from Apps without a direct migration path, plus TextMate's preservation of user customizations during upgrades. [Slack Steps from Apps](https://docs.slack.dev/legacy/legacy-steps-from-apps/), [TextMate Bundles](https://macromates.com/manual/en/bundles)
- **For `ycc`**: Add structured aliasing and migration warnings whenever skills, commands, or generated paths are renamed. The 2.0.0 nine-plugin-to-one-bundle consolidation is exactly the kind of change that benefits from durable migration metadata. [README](../../../README.md)
- **Confidence**: High.

### 5. Native-target-first generation

- **Revive from**: Vim's transition from manager hacks to native packages, and Vite's thin scaffold plus native scripts. [Vim packages](https://vimhelp.org/repeat.txt.html#packages), [Vite](https://vite.dev/guide/)
- **For `ycc`**: Keep source-of-truth in `ycc/`, but bias new target support toward native install surfaces rather than compatibility copies unless a target truly lacks them.
- **Confidence**: High.

## Comparative Analysis

| Historical pattern             | What it resembled                 | What superseded it                                 | Migration lesson for `ycc`                         |
| ------------------------------ | --------------------------------- | -------------------------------------------------- | -------------------------------------------------- |
| Yeoman generators              | Skills plus generators            | Framework CLIs and templates                       | Keep generation thin and target-native             |
| Grunt task layers              | Workflow orchestration wrappers   | npm scripts and framework defaults                 | Avoid a private workflow DSL                       |
| Hubot script packs             | Agent packs with adapters         | First-party app frameworks and APIs                | Do not overfit to unstable host integration layers |
| Vundle / Pathogen era managers | Plugin bundle loaders             | Native host packaging                              | Generate what the host naturally loads             |
| Package Control channels       | Extension registry / marketplace  | Curated registries with stronger metadata          | Fight duplication and encode deprecations          |
| Oh My Zsh mega-bundle          | Single umbrella distribution      | Still useful, but quality pressure rises with size | Curate aggressively inside the bundle              |
| Overcommit / pre-commit        | Hook packs and validation bundles | More portable, repo-defined hook manifests         | Make validation portable across local + CI         |
| Jenkins Shared Libraries       | Reusable workflow code            | Reusable workflows / thinner primitives            | Reuse code, but avoid host-locked DSL sprawl       |

## Technology Evolution Impact

- **Package managers got good enough**: npm scripts and `npm create` reduced the need for extra orchestration layers in many cases. [npm scripts](https://docs.npmjs.com/cli/v11/using-npm/scripts/), [Vite](https://vite.dev/guide/)
- **Hosts gained native extension/loading models**: Vim packages are the clearest example, but the same logic applies to Codex-native plugin packaging in this repo. [Vim packages](https://vimhelp.org/repeat.txt.html#packages), [README](../../../README.md)
- **Platforms tightened security and auth**: Slack moved from loose legacy integrations and tokens toward Slack apps, granular scopes, and signed secrets. Overcommit had to add signature verification because local automation is powerful and risky. [Slack legacy tokens](https://docs.slack.dev/legacy/legacy-custom-integrations/legacy-custom-integrations-tokens), [Slack marketplace guidelines](https://docs.slack.dev/slack-marketplace/slack-marketplace-app-guidelines-and-requirements/), [Overcommit](https://github.com/sds/overcommit)
- **Typed APIs and reusable workflows changed the economics**: It is easier now to generate native target artifacts than to maintain generic middleware forever. [Vite](https://vite.dev/guide/), [GitHub reusable workflows](https://docs.github.com/en/actions/how-tos/sharing-automations/reuse-workflows)
- **Confidence**: High.

## Key Insights

1. **`ycc` should behave like a curated distribution, not a marketplace.** The repo's 2.0.0 consolidation into one bundle is historically aligned with what aged best: a single install surface plus internal curation. Reversing that by spawning new top-level plugins would replay old registry fragmentation. [README](../../../README.md), [Package Control](https://packagecontrol.io/docs/submitting_a_package)
2. **The most dangerous pattern to repeat is a host-specific DSL that outlives its reason for existing.** Grunt, deep Jenkins library DSLs, and parts of ChatOps show how wrapper layers turn into migration debt. `ycc` should generate and orchestrate, not bury durable host primitives. [Grunt](https://gruntjs.com/), [Jenkins Shared Libraries](https://www.jenkins.io/doc/book/pipeline/shared-libraries/), [npm scripts](https://docs.npmjs.com/cli/v11/using-npm/scripts/)
3. **The most valuable old pattern to revive is context-aware activation.** TextMate's scope selectors are still smarter than many modern prompt or skill catalogs. `ycc` would benefit from richer applicability metadata for skills, agents, generators, and hooks. [TextMate Bundles](https://macromates.com/manual/en/bundles)
4. **Deprecation metadata is a feature, not documentation debt.** Slack's no-direct-migration example is the clearest warning in this set. A single-bundle plugin needs aliases, replacements, and versioned removal plans baked into manifests and validators. [Slack Steps from Apps](https://docs.slack.dev/legacy/legacy-steps-from-apps/)
5. **Repo-local automation manifests are worth modernizing.** The hook-manager lineage shows a durable pattern: versioned, shareable automation that runs the same way locally and in CI. A narrow `ycc` manifest for validators/generators/hooks could add real utility without turning the repo into an ecosystem platform. [pre-commit](https://pre-commit.com/), [Overcommit](https://github.com/sds/overcommit)

## Evidence Quality

- **Primary sources**: 16
- **Secondary sources**: 1
- **Overall confidence**: High
- **Why**: Most claims are grounded in official project docs, official changelogs, or primary repository documentation. The weaker areas are inference-heavy judgments about why specific ecosystems lost mindshare when no official postmortem exists.

## Contradictions & Uncertainties

- **Not everything here is "dead."** Yeoman, Hubot, Vundle, Oh My Zsh, and pre-commit all still exist in some form. The stronger claim is that several of their patterns are no longer the dominant abstraction layer, not that the projects fully disappeared.
- **Some supersession was partial, not absolute.** npm scripts did not delete the need for orchestration tools; they only absorbed the common path. Likewise, GitHub reusable workflows did not eliminate every Jenkins Shared Library use case.
- **The shell-framework analogy is structurally useful but not exact.** Oh My Zsh is a personalization bundle, not a workflow-orchestration bundle. I include it because the bundle-governance and discoverability problems map well to `ycc`.
- **The TextMate comparison is older than most of the requested 5-15 year window.** I kept it because its scope-selector model is unusually relevant and still underused today.

## Search Queries Executed

1. `Hubot scripts ChatOps history decline Slack apps official`
2. `Yeoman generators history scaffolding decline framework CLI official`
3. `Grunt task runner decline npm scripts official`
4. `Vundle pathogen vim plugin manager archived superseded official`
5. `Package Control Sublime Text channels repository official history`
6. `oh-my-zsh plugins custom directory official wiki`
7. `TextMate bundles commands snippets macros manual official`
8. `pre-commit framework official hooks docs`
9. `Jenkins shared libraries pipeline as code official docs`
10. `site:docs.slack.dev workflow steps from apps deprecated official`
