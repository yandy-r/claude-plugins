# Journalist Findings: Current Ecosystem State for New `ycc` Additions

Research date: April 16, 2026

## Executive Summary

- As of April 16, 2026, the strongest opportunity areas for new `ycc` additions are no longer generic "more prompts" or "more wrappers." The market has shifted toward four concrete surfaces that are usable today: repo-local skills/instructions, lifecycle hooks, MCP-backed tool access, and background or cloud agent workflows. `ycc` already covers skills and orchestration well; the largest remaining gaps are hook-centric automation, better packaging for marketplaces/install surfaces, and more explicit support for cloud/background agent workflows. **Confidence**: High. Sources: [Claude Code hooks](https://docs.anthropic.com/en/docs/claude-code/hooks), [Codex skills](https://developers.openai.com/codex/skills#where-to-save-skills), [Codex build plugins](https://developers.openai.com/codex/plugins/build), [Cursor changelog](https://cursor.com/en/changelog), [GitHub Copilot cloud agent](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-cloud-agent)

- Older assumptions are now wrong in material ways. Codex has first-class local skills, curated plugin marketplaces, app-server APIs, and multi-agent features; Cursor is now agent-first, with self-hosted cloud agents, plugin marketplaces, MCP Apps, and parallel worktree-based execution; Claude Code has mature hooks, subagents, slash commands, SDK, and GA GitHub Actions. A `ycc` roadmap built on 2024-era "single-terminal assistant" assumptions would miss current adoption patterns. **Confidence**: High. Sources: [Codex config reference](https://developers.openai.com/codex/config-reference#configtoml), [Codex app server](https://developers.openai.com/codex/app-server#api-overview), [Cursor changelog](https://cursor.com/en/changelog), [Claude Code subagents](https://docs.anthropic.com/en/docs/claude-code/sub-agents), [Claude Code GitHub Actions](https://docs.anthropic.com/en/docs/claude-code/github-actions)

- MCP is now real infrastructure, not a speculative side protocol. The protocol has a current authorization specification dated November 25, 2025, official SDKs and reference servers, and adoption across Codex, Cursor, Claude, GitHub Copilot CLI, and Bugbot. The practical opportunity for `ycc` is not inventing a new abstraction over MCP, but packaging stable MCP defaults, auth guidance, selective toolsets, and cross-target install flows. **Confidence**: High. Sources: [MCP authorization spec](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization), [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk), [MCP reference servers](https://github.com/modelcontextprotocol/servers), [GitHub Copilot CLI MCP docs](https://docs.github.com/copilot/how-tos/copilot-cli/customize-copilot/add-mcp-servers), [Cursor changelog](https://cursor.com/en/changelog)

- The most notable practical trend in developer-agent repos is convergence on a shared pattern: repo-local instructions plus isolated execution plus review/fix loops plus explicit approvals and MCP expansion. Repos differ on UX, but not on the underlying primitives. This favors additions to `ycc` that strengthen packaging, auditability, and lifecycle automation over additions that merely add more persona prompts. **Confidence**: Medium. Sources: [OpenHands](https://github.com/OpenHands/OpenHands), [anthropics/claude-code-action](https://github.com/anthropics/claude-code-action), [Roo Code](https://github.com/RooCodeInc/Roo-Code), [GitHub MCP Server](https://github.com/github/github-mcp-server)

## Current State

- `ycc` already spans a broad local workflow surface: 34 skills, 34 slash commands, 50 agents, and generation pipelines for Claude, Cursor, and Codex. The local context strongly suggests the next additions should solve portability, packaging, and automation gaps instead of raw skill count growth. **Confidence**: High. Sources: [Objective](../objective.md), [README](../../../README.md)

- Claude Code's current extensibility model is mature and local-first. Official docs show support for hooks across `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, `SubagentStop`, `PreCompact`, `SessionStart`, and `SessionEnd`, plus subagents, slash commands, MCP management, and a dedicated SDK. **Confidence**: High. Sources: [Claude Code hooks](https://docs.anthropic.com/en/docs/claude-code/hooks), [Claude Code subagents](https://docs.anthropic.com/en/docs/claude-code/sub-agents), [Claude Code slash commands](https://docs.anthropic.com/en/docs/claude-code/slash-commands), [Claude Code SDK](https://docs.anthropic.com/en/docs/claude-code/sdk)

- Cursor's current product direction is agent-first rather than editor-assistant-first. On April 2, 2026, Cursor 3 introduced the Agents Window, multi-agent parallel work across local/worktree/cloud/remote SSH environments, `/worktree`, `/best-of-n`, an `Await` tool, structured MCP App content, and tighter browser-tool focus. On March 25, 2026, Cursor added self-hosted cloud agents. On April 8, 2026, Bugbot gained MCP support and learned rules. On March 3, 2026, Cursor announced MCP Apps and team marketplaces for plugins. **Confidence**: High. Sources: [Cursor changelog](https://cursor.com/en/changelog)

- Codex now clearly distinguishes local skills from plugins. Current docs say to start with a local skill when iterating on one repo or personal workflow, and to build a plugin when sharing across teams, bundling app integrations or MCP config, or publishing a stable package. Codex also supports repo, user, admin, and system skill locations and scans `.agents/skills` up to repo root. **Confidence**: High. Sources: [Codex skills](https://developers.openai.com/codex/skills#where-to-save-skills), [Codex build plugins](https://developers.openai.com/codex/plugins/build)

- GitHub has also moved beyond chat-only assistance. Current GitHub docs describe Copilot cloud agent as a background agent that can research a repository, create plans, make changes on a branch, and work in an ephemeral GitHub Actions-powered development environment. GitHub Copilot CLI now has MCP configuration in `~/.copilot`, and GitHub documents `/mcp add` plus a GitHub MCP Registry. **Confidence**: High. Sources: [GitHub Copilot cloud agent](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-cloud-agent), [Copilot CLI config directory](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference), [Add MCP servers to Copilot CLI](https://docs.github.com/copilot/how-tos/copilot-cli/customize-copilot/add-mcp-servers)

## Key Players

- Anthropic remains strongest on local coding-agent ergonomics: hooks, subagents, slash commands, repo memory, GitHub Actions integration, and an SDK all map directly onto day-to-day developer workflows. The practical implication for `ycc` is that Claude remains the most natural home for repo-native orchestration and hook-heavy automation. **Confidence**: High. Sources: [Claude Code hooks](https://docs.anthropic.com/en/docs/claude-code/hooks), [Claude Code GitHub Actions](https://docs.anthropic.com/en/docs/claude-code/github-actions), [Claude Code SDK](https://docs.anthropic.com/en/docs/claude-code/sdk)

- OpenAI is pushing Codex toward a more structured platform model: local skills, plugins, curated marketplaces, app-server APIs, apps/connectors, remote MCP, hosted shell, hosted skills, and multi-agent controls. This is a stronger platform story than many older Codex discussions assumed. **Confidence**: High. Sources: [Codex build plugins](https://developers.openai.com/codex/plugins/build), [Codex app server](https://developers.openai.com/codex/app-server#api-overview), [Codex config reference](https://developers.openai.com/codex/config-reference#configtoml), [OpenAI MCP and connectors](https://developers.openai.com/api/docs/guides/tools-connectors-mcp#connectors)

- Cursor is leading on productized agent UX. The recent releases emphasize parallel agents, self-hosted cloud agents, interactive canvases, MCP Apps, plugin marketplaces, and code-review automation. That makes Cursor an important compatibility target for any `ycc` addition that benefits from visual artifacts or team distribution. **Confidence**: High. Sources: [Cursor changelog](https://cursor.com/en/changelog)

- GitHub is becoming a serious background-agent surface rather than just an API provider. Copilot cloud agent, MCP support in Copilot CLI, and the official GitHub MCP Server make GitHub both a platform and an integration substrate. **Confidence**: High. Sources: [GitHub Copilot cloud agent](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-cloud-agent), [Add MCP servers to Copilot CLI](https://docs.github.com/copilot/how-tos/copilot-cli/customize-copilot/add-mcp-servers), [GitHub MCP Server](https://github.com/github/github-mcp-server)

- The MCP steering group has become an important infrastructural player in its own right. The official specification repo, TypeScript SDK, reference servers repo, `ext-apps` repo for embedded UIs, and `mcpb` for one-click local server installation all point to a rapidly professionalizing tool ecosystem. **Confidence**: High. Sources: [MCP org overview](https://github.com/modelcontextprotocol), [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk), [MCP reference servers](https://github.com/modelcontextprotocol/servers)

## Latest Developments

- March 24-25, 2026: OpenAI Apps SDK docs added plugin distribution guidance stating that approved apps are turned into plugins for Codex distribution, and that plugins are only available in Codex for now. This matters because it creates a second plugin lane beyond repo-local skill packaging: app-backed distribution through OpenAI's managed surfaces. **Confidence**: High. Sources: [Apps SDK changelog search result](https://developers.openai.com/apps-sdk/changelog), [App submission and distribution FAQ](https://developers.openai.com/apps-sdk/deploy/submission#publication-and-distribution-faqs)

- April 2026: Cursor stacked several agent-centric releases in quick succession: Cursor 3's agent-first interface on April 2, Bugbot learned rules and MCP support on April 8, upgraded multi-agent UI on April 13, and durable interactive canvases on April 15. This is a meaningful acceleration, not an isolated feature release. **Confidence**: High. Sources: [Cursor changelog](https://cursor.com/en/changelog)

- January 2026: OpenAI's API changelog announced `gpt-5.2-codex` in the Responses API; current model docs now surface `gpt-5.3-codex` as "the most capable agentic coding model to date" with support for `web_search`, `hosted_shell`, and `skills`. **Confidence**: High. Sources: [OpenAI API changelog](https://developers.openai.com/api/docs/changelog), [GPT-5.3-Codex model docs](https://developers.openai.com/api/docs/models/gpt-5.3-codex)

- November 25, 2025: the MCP spec published the current authorization document for HTTP-based transports. That is one of the clearest signals that remote MCP is maturing past ad hoc bearer-token patterns. **Confidence**: High. Sources: [MCP authorization spec](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization)

- Claude Code GitHub Actions has reached GA-era documentation rather than beta-only docs. Anthropic's docs explicitly describe upgrading from beta to `v1.0`, automatic mode detection, and CLI passthrough via `claude_args`, which makes it relevant as a stable automation surface. **Confidence**: High. Sources: [Claude Code GitHub Actions](https://docs.anthropic.com/en/docs/claude-code/github-actions), [anthropics/claude-code-action](https://github.com/anthropics/claude-code-action)

## Emerging Trends

- Repo-local instructions are winning over centralized prompt stores. Claude uses `CLAUDE.md` plus `.claude/*`; Codex scans `.agents/skills` and `AGENTS.md`; Cursor supports project rules, AGENTS.md, and user rules; GitHub Copilot cloud agent also exposes repository instructions, custom agents, hooks, and skills. The common primitive is "context lives with the repo." **Confidence**: High. Sources: [Claude slash commands](https://docs.anthropic.com/en/docs/claude-code/slash-commands), [Codex skills](https://developers.openai.com/codex/skills#where-to-save-skills), [Cursor rules docs search result](https://docs.cursor.com/ja/context/rules), [GitHub Copilot cloud agent](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-cloud-agent)

- Isolated execution is now a default design choice. Cursor explicitly uses worktrees and self-hosted cloud agents; GitHub Copilot cloud agent uses ephemeral GitHub Actions environments; Codex has hosted shell and hosted skills; OpenHands and Roo Code also frame agent work as multi-agent or isolated task execution. **Confidence**: High. Sources: [Cursor changelog](https://cursor.com/en/changelog), [GitHub Copilot cloud agent](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-cloud-agent), [OpenAI `/v1/responses` retention notes](https://developers.openai.com/api/docs/guides/your-data#v1responses), [OpenHands](https://github.com/OpenHands/OpenHands), [Roo Code](https://github.com/RooCodeInc/Roo-Code)

- Review-plus-autofix loops are becoming a product category. Cursor Bugbot now learns rules from review feedback and can use MCP; GitHub positions cloud agent and code review as related but distinct flows; Anthropic's GitHub Action supports `/review` and implementation flows; many repos now package reviewer/fixer agents as first-class workflows. **Confidence**: Medium. Sources: [Cursor changelog](https://cursor.com/en/changelog), [Claude Code GitHub Actions](https://docs.anthropic.com/en/docs/claude-code/github-actions), [GitHub Copilot cloud agent](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-cloud-agent)

- MCP is expanding from "tool calls" into richer UX surfaces. Cursor added MCP Apps and structured content support; the MCP org now hosts `ext-apps`, described as the spec and SDK for UIs embedded in AI chatbots; OpenAI's Apps SDK and Codex plugin docs also point toward app-plus-plugin packaging. **Confidence**: High. Sources: [Cursor changelog](https://cursor.com/en/changelog), [MCP organization overview](https://github.com/modelcontextprotocol), [OpenAI Apps SDK changelog](https://developers.openai.com/apps-sdk/changelog), [Codex build plugins](https://developers.openai.com/codex/plugins/build)

## Contemporary Debates

- The main debate is no longer "local agent vs cloud agent" in the abstract. It is "which work should stay local, and which should move to isolated remote environments?" Claude still leans local-first. Cursor and GitHub are pushing harder into cloud/background execution. Codex is straddling both with local skills plus hosted shell and app-server APIs. **Confidence**: Medium. Sources: [Claude Code SDK](https://docs.anthropic.com/en/docs/claude-code/sdk), [Cursor changelog](https://cursor.com/en/changelog), [GitHub Copilot cloud agent](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-cloud-agent), [OpenAI `/v1/responses` retention notes](https://developers.openai.com/api/docs/guides/your-data#v1responses)

- A second debate is whether plugins should be repo-scoped curation mechanisms or broader app-distribution channels. Codex docs currently support both a local marketplace path and an OpenAI-managed distribution path for approved apps. This is strategically important because `ycc` sits in the repo-scoped lane today. **Confidence**: High. Sources: [Codex build plugins](https://developers.openai.com/codex/plugins/build), [Apps SDK changelog](https://developers.openai.com/apps-sdk/changelog), [App submission and distribution FAQ](https://developers.openai.com/apps-sdk/deploy/submission#publication-and-distribution-faqs)

- A third debate is whether MCP should be treated as a universal integration layer or a lowest-common-denominator layer. The ecosystem is standardizing, but production auth, tool safety, packaging, and install UX are still uneven. This argues for opinionated packaging, not protocol-only abstractions. **Confidence**: Medium. Sources: [MCP authorization spec](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization), [MCP reference servers](https://github.com/modelcontextprotocol/servers), [GitHub Copilot CLI MCP docs](https://docs.github.com/copilot/how-tos/copilot-cli/customize-copilot/add-mcp-servers)

## Recent Events

- 2026-04-15: Cursor announced durable interactive canvases in Cursor 3.1. **Confidence**: High. Source: [Cursor changelog](https://cursor.com/en/changelog)

- 2026-04-08: Cursor announced Bugbot learned rules and Bugbot MCP support. **Confidence**: High. Source: [Cursor changelog](https://cursor.com/en/changelog)

- 2026-04-02: Cursor 3 launched with an Agents Window, `/worktree`, `/best-of-n`, `Await`, structured MCP App content, and tighter browser-tool behavior. **Confidence**: High. Source: [Cursor changelog](https://cursor.com/en/changelog)

- 2026-03-25: Cursor announced self-hosted cloud agents. **Confidence**: High. Source: [Cursor changelog](https://cursor.com/en/changelog)

- 2026-03-25: OpenAI Apps SDK docs documented plugin distribution for Codex and noted that plugins are only available in Codex for now. **Confidence**: High. Sources: [Apps SDK changelog](https://developers.openai.com/apps-sdk/changelog), [App submission and distribution FAQ](https://developers.openai.com/apps-sdk/deploy/submission#publication-and-distribution-faqs)

- 2026-02-12: `codex-mini-latest` was removed, and the legacy local shell tool tied to it was deprecated in favor of the newer shell tool path. **Confidence**: High. Source: [OpenAI deprecations](https://developers.openai.com/api/docs/deprecations#2025-11-17-codex-mini-latest-model-snapshot)

- 2025-11-25: MCP authorization spec published for HTTP transports. **Confidence**: High. Source: [MCP authorization spec](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization)

## Market/Industry Dynamics

- The practical market split now looks like this: Anthropic is strongest in local repo-native automation; Cursor is strongest in productized agent UX and team distribution; OpenAI/Codex is building a structured plugin and app platform; GitHub is strongest in remote/background execution tied to repository workflows. `ycc` sits naturally in the intersection, but that also means every addition needs to decide which surface it is optimizing for. **Confidence**: Medium. Sources: [Claude docs](https://docs.anthropic.com/en/docs/claude-code), [Cursor changelog](https://cursor.com/en/changelog), [Codex build plugins](https://developers.openai.com/codex/plugins/build), [GitHub Copilot cloud agent](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-cloud-agent)

- Open-source developer-agent repos are increasingly adopting "dev team" positioning rather than single-assistant positioning. OpenHands brands itself as AI-driven development, Roo Code positions itself as a "whole dev team," and many tools now package planners, reviewers, fixers, and infra helpers as separate agent roles. This makes `ycc`'s multi-agent orientation more aligned with current practice than it might have been a year earlier. **Confidence**: Medium. Sources: [OpenHands](https://github.com/OpenHands/OpenHands), [Roo Code](https://github.com/RooCodeInc/Roo-Code)

- Distribution is becoming an ecosystem feature, not just a packaging detail. Cursor now has team marketplaces for plugins; Codex supports repo and personal marketplaces; GitHub provides an MCP Registry; MCP itself is investing in install UX with `mcpb`. This suggests install flows and curation surfaces matter more than they used to. **Confidence**: High. Sources: [Cursor changelog](https://cursor.com/en/changelog), [Codex build plugins](https://developers.openai.com/codex/plugins/build), [GitHub MCP docs](https://docs.github.com/copilot/how-tos/copilot-cli/customize-copilot/add-mcp-servers), [MCP organization overview](https://github.com/modelcontextprotocol)

## Regulatory/Policy Landscape

- MCP authorization is now explicitly specified for HTTP-based transports using OAuth 2.1-aligned patterns, PKCE, protected resource metadata, and RFC 8707 resource indicators. That reduces ambiguity for remote MCP deployment, but only for transports that actually implement the current spec. **Confidence**: High. Source: [MCP authorization spec](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization)

- OpenAI's current data docs explicitly note that MCP servers used via the remote MCP server tool are third-party services subject to their own retention policies, and that hosted shell/code interpreter use ephemeral container state. This matters if `ycc` grows more hosted or remote automation. **Confidence**: High. Source: [OpenAI `/v1/responses` retention notes](https://developers.openai.com/api/docs/guides/your-data#v1responses)

- GitHub and Cursor both expose more enterprise controls than older agent tools did, including team/enterprise settings around plugin imports, self-hosting, and MCP access. That raises the importance of policy-aware install and validation flows in `ycc`, especially if it expands beyond solo-repo use. **Confidence**: Medium. Sources: [Cursor changelog](https://cursor.com/en/changelog), [GitHub Copilot docs navigation for MCP and cloud-agent controls](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-cloud-agent)

## Key Insights

- The best new `ycc` additions are likely to be "surface adapters" rather than novel workflows: hook packs, repo-marketplace helpers, MCP packaging defaults, cloud-agent handoff helpers, and richer review/fix/report loops. **Confidence**: Medium. Basis: cross-source synthesis from the platform capability changes above.

- The repo's current Codex and Cursor generation model is strategically well-timed. Both ecosystems now reward curated packaging and installable compatibility layers more than ad hoc prompt files. `ycc` should lean further into generation, validation, and packaging quality. **Confidence**: High. Sources: [README](../../../README.md), [Codex build plugins](https://developers.openai.com/codex/plugins/build), [Cursor changelog](https://cursor.com/en/changelog)

- The biggest "do not add" warning from current ecosystem conditions is: do not add broad, target-specific feature sprawl that cannot be mapped across at least two surfaces or justified by a clear win on one platform. Cursor canvases, MCP Apps UIs, and OpenAI app-backed plugins are promising, but they are not equally portable yet. **Confidence**: Medium. Sources: [Cursor changelog](https://cursor.com/en/changelog), [OpenAI Apps SDK changelog](https://developers.openai.com/apps-sdk/changelog), [Codex build plugins](https://developers.openai.com/codex/plugins/build)

- Another "do not add" warning: avoid building around deprecated or transitional OpenAI assumptions. The Responses API is the future direction, Assistants API is deprecated with an August 26, 2026 sunset, and `codex-mini-latest` plus its legacy local shell tool are already gone. **Confidence**: High. Sources: [Migrate to Responses](https://developers.openai.com/api/docs/guides/migrate-to-responses#assistants-api), [OpenAI deprecations](https://developers.openai.com/api/docs/deprecations#2025-11-17-codex-mini-latest-model-snapshot)

## Evidence Quality

- Overall evidence quality is strong. Most core capability claims in this report come from official docs, official changelogs, official GitHub docs, or official repositories. **Confidence**: High.

- The highest-confidence sections are Codex/OpenAI, Cursor release changes, GitHub Copilot cloud agent, and MCP protocol maturity because they are backed by current official docs or changelog entries with explicit dates. **Confidence**: High.

- The weakest evidence area is comparative interpretation of open-source developer-agent repo "patterns." Those claims are synthesis from repo READMEs and positioning rather than formal documentation or benchmark studies. **Confidence**: Medium.

## Contradictions & Uncertainties

- Codex plugin messaging is internally bifurcated. One set of docs treats plugins as local or curated marketplace packages for repo/team workflows; the Apps SDK changelog and app submission docs also describe approved OpenAI apps becoming Codex plugins. I infer there are effectively two plugin distribution paths today: local/self-curated and OpenAI-managed. That inference is well-supported, but the exact long-term relationship between those paths is still unclear. **Confidence**: Medium. Sources: [Codex build plugins](https://developers.openai.com/codex/plugins/build), [Apps SDK changelog](https://developers.openai.com/apps-sdk/changelog), [App submission and distribution FAQ](https://developers.openai.com/apps-sdk/deploy/submission#publication-and-distribution-faqs)

- Claude, Cursor, Codex, and GitHub now all support some combination of repo instructions, hooks, MCP, and remote execution, but not with equivalent semantics. Cross-target parity is still an illusion at the edge. `ycc` can unify a lot, but it cannot assume one-to-one feature mapping. **Confidence**: High. Sources: [Claude hooks](https://docs.anthropic.com/en/docs/claude-code/hooks), [Cursor changelog](https://cursor.com/en/changelog), [Codex config reference](https://developers.openai.com/codex/config-reference#configtoml), [GitHub Copilot cloud agent](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-cloud-agent)

- The MCP ecosystem is clearly accelerating, but install UX and trust policy are still fragmented across clients. Even with official auth guidance, server discovery, approval semantics, and packaging remain uneven in practice. **Confidence**: Medium. Sources: [MCP authorization spec](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization), [MCP reference servers](https://github.com/modelcontextprotocol/servers), [GitHub Copilot CLI MCP docs](https://docs.github.com/copilot/how-tos/copilot-cli/customize-copilot/add-mcp-servers)

## Search Queries Executed

1. `Claude Code hooks subagents slash commands docs Anthropic 2026 site:docs.anthropic.com/en/docs/claude-code`
2. `Cursor docs background agent rules MCP release notes 2026 site:cursor.com`
3. `Model Context Protocol Streamable HTTP Authorization spec 2025 site:modelcontextprotocol.io`
4. `OpenAI Codex plugins custom agents documentation 2026 site:platform.openai.com OR site:developers.openai.com OR site:openai.com`
5. `site:developers.openai.com codex custom agents plugins docs`
6. `site:docs.anthropic.com/en/docs/claude-code github actions claude code`
7. `site:docs.github.com GitHub Copilot coding agent 2026`
8. `site:github.com developer coding agent repository OpenHands aider Cline Roo Code GitHub 2026`
9. `site:github.com/modelcontextprotocol/typescript-sdk official MCP TypeScript SDK GitHub`
10. `site:github.com/github/github-mcp-server GitHub MCP server repo`
