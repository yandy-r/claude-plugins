# Contrarian Research: plugin-additions

## Executive Summary

The strongest disconfirming evidence does not support expanding `ycc` by default with more skills, agents, hooks, connectors, or cross-target automation. The most credible sources converge on a narrower position: maximize a single agent or a small set of clearly differentiated skills first; add specialization only when instruction complexity or tool overload is already proven; and treat every new tool, hook, or automation path as both a security surface and an evaluation burden.

That matters more for this repo than for a greenfield agent project because `ycc` already has a broad operational surface. The local source of truth currently advertises **34 skills** and **50 agents**, plus mirrored Cursor and Codex compatibility layers, install target branching, and multiple generate/validate pipelines across targets ([README](../../../README.md), lines 3-5, 9, 50, 89-193). The repo also has 22 top-level scripts and explicit content-policy validators for generated Cursor and Codex artifacts, which means each additive feature must survive at least three axes of maintenance: Claude-native authoring, cross-target generation, and validation/policy drift.

The evidence does **not** say “never add another skill.” It says the next bad addition is likely to be one of these:

- another overlapping skill or agent that differs mostly in prompt wording, not capability
- another parity layer that exists to mimic platform behavior one platform does not really support
- another default-on hook, MCP integration, or write-capable automation path
- another generator/validator stage that multiplies churn faster than it removes it

**Local context**: `ycc` is already a consolidated single-plugin bundle with a multi-stage workflow pipeline and cross-target generation model ([objective](../objective.md), [README](../../../README.md), [install.sh](../../../install.sh)).

## Disconfirming Evidence

### More specialized skills and agents do **not** automatically improve outcomes

- **Common belief**: More specialized skills/agents make the system more capable and easier to reason about.
- **Contradictory evidence**: OpenAI’s practical guide recommends maximizing a single agent first, warning that more agents add complexity and overhead; it also says tool overlap, not just tool count, is what breaks agent performance. Anthropic’s Agent Skills article argues for packaging expertise into composable skills instead of building fragmented, custom-designed agents for every use case. Thoughtworks’ autonomy experiment found that even with multiple agents and many control strategies, behavior became unreliable as complexity increased.  
  Sources: [OpenAI practical guide](https://openai.com/business/guides-and-resources/a-practical-guide-to-building-ai-agents/), [Anthropic Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills), [Thoughtworks autonomy experiment](https://martinfowler.com/articles/pushing-ai-autonomy.html)
- **Source quality**: Primary for OpenAI and Anthropic; expert practitioner source for Thoughtworks.
- **Strength**: Strong.
- **Confidence**: High. Multiple high-authority sources align on “specialize only after simpler structures fail.”
- **Repo implication**: Do **not** add more micro-skills or agent variants for `ycc` when they only reframe existing behavior. In this repo, that means avoiding prompt-shape clones of `ask`, `plan`, `orchestrate`, `parallel-plan`, language-pattern skills, or reviewer/fixer variants unless they add a distinct tool surface, artifact contract, or workflow stage that cannot be modeled by an existing skill.

### Cross-platform parity is **not** automatically worth implementing

- **Common belief**: If Claude, Cursor, and Codex all exist in the repo, every useful affordance should be mirrored across all of them.
- **Contradictory evidence**: Cursor’s docs explicitly note that `AGENTS.md` is currently root-level only, globally scoped, and single-file, which makes rich hierarchical instruction schemes a poor fit there. OpenAI’s Codex config reference shows `features.codex_hooks` is still under development and off by default, while Codex also enforces bounded multi-agent depth and thread counts. The repo’s own README already documents a hard asymmetry: Codex does not support this repo’s custom slash-command layer as installable artifacts.  
  Sources: [Cursor context docs](https://docs.cursor.com/en/context), [OpenAI Codex config reference](https://developers.openai.com/codex/config-reference#configtoml), [README](../../../README.md)
- **Source quality**: Primary plus local repo evidence.
- **Strength**: Strong.
- **Confidence**: High. The limitation is explicit in platform docs and in the repo’s own install notes.
- **Repo implication**: Do **not** add new “parity theater” features that require synthetic mirrors for unsupported surfaces. Specifically, avoid:
  - Codex slash-command emulation layers
  - Codex hook-heavy features that depend on a still-under-development feature flag
  - deeper rule-scoping abstractions that assume Cursor can natively model nested instruction trees like Claude skills can

### More hooks, connectors, and tool exposure increase security and approval burden

- **Common belief**: New hooks and connectors are mostly upside because approvals and tool prompts keep things safe.
- **Contradictory evidence**: Anthropic’s subagent docs state that subagents inherit all tools from the main conversation, including MCP tools, unless they are explicitly restricted. Anthropic’s hooks reference shows hooks can run at many lifecycle points, including every tool call in the agentic loop, making them powerful but broad. Anthropic’s remote MCP guidance warns that custom connectors are beta, unverified, can modify or delete data, may contain hidden instructions, and should have irrelevant tools disabled. OpenAI and the UK NCSC both argue prompt injection is not a solved filtering problem and must be mitigated by limiting impact, not by assuming detection will work. Simon Willison’s MCP critique documents tool shadowing, rug pulls, and exfiltration patterns that become easier when you combine untrusted inputs with powerful tools.  
  Sources: [Claude Code subagents](https://docs.anthropic.com/en/docs/claude-code/sub-agents), [Claude Code hooks](https://code.claude.com/docs/en/hooks), [Claude custom connectors help](https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp), [OpenAI prompt injection guidance](https://openai.com/index/designing-agents-to-resist-prompt-injection/), [NCSC warning](https://www.ncsc.gov.uk/news/mistaking-ai-vulnerability-could-lead-to-large-scale-breaches), [Simon Willison on MCP](https://simonwillison.net/2025/Apr/9/mcp-prompt-injection/)
- **Source quality**: Primary for Anthropic/OpenAI/NCSC; strong expert critique for Simon Willison.
- **Strength**: Strong.
- **Confidence**: High. The sources are recent, mutually reinforcing, and focused on real tool-using agent systems.
- **Repo implication**: Do **not** add default-on write-capable hooks, always-enabled MCP servers, or broad tool inheritance paths to `ycc`. Also avoid installing connectors that users do not explicitly need, and avoid any addition that auto-enables write actions inside research-style flows.

### More generator and automation layers are **not** free once you account for evaluation and debugging

- **Common belief**: If generation and validation are scripted, more automation stages just reduce manual work.
- **Contradictory evidence**: Anthropic’s eval guidance says agent capabilities make systems materially harder to evaluate, and teams without evals end up flying blind and debugging reactively. Thoughtworks’ autonomy write-up reports long feedback loops, inconsistent prompts, hard-to-define success, and difficult traceability in more autonomous workflows. GitHub’s workflow docs add a separate cautionary signal: reusable workflows have explicit limits and propagation caveats, while workflow-triggered workflows can silently not fire under `GITHUB_TOKEN`, which creates unintuitive behavior in chained automations.  
  Sources: [Anthropic evals for agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents), [Thoughtworks autonomy experiment](https://martinfowler.com/articles/pushing-ai-autonomy.html), [GitHub reusable workflow limits](https://docs.github.com/en/enterprise-cloud@latest/actions/reference/workflows-and-actions/reusing-workflow-configurations), [GitHub trigger behavior](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow)
- **Source quality**: Primary plus strong practitioner evidence.
- **Strength**: Strong.
- **Confidence**: High.
- **Repo implication**: Do **not** add another generator target, another mirrored artifact family, or another hook-triggered generation/validation chain unless it removes an existing stage. In `ycc`, the burden is already visible in the generate/validate/install matrix for Cursor and Codex plus content-policy validators in `scripts/`.

## Expert Critiques

### OpenAI

- **Credentials**: Platform vendor documenting production agent patterns.
- **Main argument**: Start by maximizing a single agent with well-defined tools. Add more agents only when instruction complexity or tool confusion is clearly the bottleneck.
- **Evidence provided**: OpenAI states that more agents add complexity and overhead, and that some systems handle 15+ distinct tools while others fail with fewer than 10 overlapping tools.
- **Counterarguments**: OpenAI does endorse multi-agent systems when prompts become too conditional or tool sets remain confusing after better naming and descriptions.
- **Assessment**: Valid and directly applicable. The critique is not anti-agent; it is anti-overlap and anti-premature decomposition.
- **Confidence**: High.
- **Source**: [A practical guide to building AI agents](https://openai.com/business/guides-and-resources/a-practical-guide-to-building-ai-agents/)

### Anthropic

- **Credentials**: Claude/Claude Code vendor and originator of MCP and Claude skills patterns.
- **Main argument**: Prefer general-purpose agents equipped with composable skills over fragmented, custom-designed agents. Also, agent systems become harder to evaluate as they gain autonomy, tool use, and flexibility.
- **Evidence provided**: Anthropic’s skills article argues for dynamic loading and progressive disclosure; its evals article says teams otherwise end up in reactive loops and “flying blind.”
- **Counterarguments**: Anthropic is explicitly pro-skill and pro-agent when the skill packages real expertise and loads only when relevant.
- **Assessment**: Strong critique of fragmentation, not of capability packaging itself.
- **Confidence**: High.
- **Source**: [Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills), [Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)

### Thoughtworks / Birgitta Böckeler

- **Credentials**: Distinguished Engineer and AI-assisted delivery expert at Thoughtworks.
- **Main argument**: Pushing autonomous code generation harder currently creates a “whac-a-mole” pattern of failures even with many control strategies layered in.
- **Evidence provided**: Their experiment reports unrequested features, shifting assumptions, brute-force fixes, lingering static-analysis issues, long feedback loops, and the model declaring success despite failing tests.
- **Counterarguments**: The same article says reusable prompts, reference applications, static analysis, and deterministic scripts are still valuable in human-in-the-loop workflows.
- **Assessment**: Strong warning against translating “possible with enough scaffolding” into “good repository default.”
- **Confidence**: High.
- **Source**: [How far can we push AI autonomy in code generation?](https://martinfowler.com/articles/pushing-ai-autonomy.html)

### Simon Willison / NCSC

- **Credentials**: Simon Willison is a widely cited independent expert on LLM tooling and prompt injection; the NCSC is the UK’s official cybersecurity authority.
- **Main argument**: Mixing powerful tools with untrusted instructions is inherently dangerous, and prompt injection is better treated as an “inherently confusable” security problem than a simple filterable bug class.
- **Evidence provided**: Tool shadowing, rug pulls, tool poisoning, WhatsApp message exfiltration demos, and NCSC’s warning that prompt injection may never be mitigated like SQL injection.
- **Counterarguments**: Both still support tool usage in principle, but only with human-in-the-loop safeguards and constrained blast radius.
- **Assessment**: Highly relevant for any proposal to add more hooks, connectors, or automatic tool access to `ycc`.
- **Confidence**: High.
- **Source**: [Simon Willison on MCP](https://simonwillison.net/2025/Apr/9/mcp-prompt-injection/), [NCSC warning](https://www.ncsc.gov.uk/news/mistaking-ai-vulnerability-could-lead-to-large-scale-breaches)

## Documented Failures

### Thoughtworks autonomous code-generation workflow

- **What happened**: A multi-agent workflow could generate simple applications, but reliability degraded as complexity increased.
- **Root causes**: Long prompt chains, inconsistent instructions, weak traceability, model over-eagerness, and insufficiently trustworthy success criteria.
- **Scale/impact**: Broad enough for Thoughtworks to conclude that maintainable business software still requires human oversight even after adding many strategies and tools.
- **Lessons**: More scaffolding is not the same as more robustness. Validation burden compounds as autonomy rises.
- **Confidence**: High.
- **Source**: [Thoughtworks experiment](https://martinfowler.com/articles/pushing-ai-autonomy.html)

### Prompt injection against OpenAI Deep Research / agentic browsing

- **What happened**: OpenAI cites a 2025 example reported by external researchers that succeeded 50% of the time in testing under a realistic research prompt.
- **Root causes**: External untrusted content influencing an action-taking agent; filtering alone was insufficient.
- **Scale/impact**: Important because it affected an agent that browses and synthesizes external sources, directly analogous to research-oriented automation.
- **Lessons**: Every new research connector, browsing tool, or auto-action path widens the opportunity for manipulation unless the blast radius is constrained.
- **Confidence**: High.
- **Source**: [OpenAI prompt injection guidance](https://openai.com/index/designing-agents-to-resist-prompt-injection/)

### MCP tool poisoning / rug pull / exfiltration cases

- **What happened**: Simon Willison documents MCP attack classes including tool shadowing, silent definition changes, tool poisoning, and WhatsApp history exfiltration via malicious instructions.
- **Root causes**: Trusting tool descriptions, insufficient user visibility into changes, and combining private data with tools that can transmit it.
- **Scale/impact**: Significant because these are not just hypothetical protocol issues; they are concrete attack shapes against real MCP-style tool ecosystems.
- **Lessons**: `ycc` should not normalize “just add another MCP server/hook” as a default engineering move.
- **Confidence**: Medium-High. The attack descriptions are detailed and technically plausible, but the article synthesizes demos from multiple parties rather than being a single official vendor incident report.
- **Source**: [Simon Willison on MCP](https://simonwillison.net/2025/Apr/9/mcp-prompt-injection/)

## Questionable Assumptions

1. **Assumption**: Every repeated request deserves its own skill or agent.  
   **Why questionable**: OpenAI and Anthropic both point to composability, prompt templating, and progressive disclosure before proliferating agents.  
   **Evidence status**: Strong.  
   **Alternative view**: A new skill should exist only when it packages durable procedural knowledge, distinct scripts/references, or a different artifact contract.

2. **Assumption**: Cross-target parity is a feature, not a cost center.  
   **Why questionable**: Cursor and Codex expose different primitives and limitations, and the repo already carries generator and validator drift costs.  
   **Evidence status**: Strong.  
   **Alternative view**: Preserve `ycc` as a single conceptual plugin, but tolerate platform-specific omissions when parity would be fake or fragile.

3. **Assumption**: Hooks and connectors can be added safely if approvals exist.  
   **Why questionable**: The strongest security sources argue that approvals help only if the system constrains impact and keeps tools narrow, visible, and human-reviewable.  
   **Evidence status**: Strong.  
   **Alternative view**: Default to least privilege, explicit opt-in, and conversation-scoped enablement.

4. **Assumption**: Validators neutralize automation complexity.  
   **Why questionable**: Validators catch policy violations and sync drift, but they do not remove feedback-loop length, ambiguity in success criteria, or cross-target semantic mismatch.  
   **Evidence status**: Strong.  
   **Alternative view**: Add automation only if it clearly deletes manual steps or collapses existing branches of complexity.

## Conflicts of Interest

- Platform vendors have incentives to promote extensibility, but the same vendors also document guardrails, approvals, betas, and experimental flags that reveal the real operating cost of those extensions.
- Maintainers of a plugin repo like `ycc` are naturally exposed to novelty bias and ecosystem-comparison pressure: it is easy to overvalue “we should support X like tool Y does” even when the repo already has broad coverage.
- Users experience the downside first: discovery friction, tool-selection ambiguity, approval fatigue, install complexity, and regressions across targets. Maintainers experience the upside first: conceptual completeness and roadmap satisfaction.

## Unintended Consequences

- **Selection ambiguity**: More overlapping skills make the “right” entrypoint less obvious, which can degrade both human discoverability and model tool/skill choice.  
  **Evidence**: OpenAI explicitly calls out tool similarity/overlap as a problem.  
  **Severity**: High.

- **Approval fatigue**: More hooks, connectors, and tools means more prompts and more cases where users normalize approving actions they should inspect.  
  **Evidence**: Anthropic and OpenAI security guidance both emphasize constrained actions and careful approval review.  
  **Severity**: High.

- **Cross-target drift**: Every new feature added to `ycc/` must be translated or consciously omitted for Cursor/Codex. The repo already enforces target-specific content policies.  
  **Evidence**: local validators in `scripts/validate-cursor-skills.sh` and `scripts/validate-codex-skills.sh`.  
  **Severity**: High.

- **Evaluation debt**: More autonomous flows create more states to test, more regressions to triage, and more hidden failure modes that only surface after users complain.  
  **Evidence**: Anthropic eval guidance and Thoughtworks’ autonomy experiment.  
  **Severity**: High.

- **Install and maintenance friction**: The current install matrix already branches by `claude`, `cursor`, `codex`, `all`, with additive/exclusive steps and per-target semantics.  
  **Evidence**: [install.sh](../../../install.sh), [README](../../../README.md).  
  **Severity**: Medium-High.

## Critical Analysis

The repo-specific conclusion is not “stop evolving `ycc`.” It is “the next addition should probably be a consolidation, restriction, or deletion before it is a net-new surface.”

### What `ycc` should **not** add next

1. **Do not add more overlapping prompt wrappers** around existing planning, orchestration, review, or language-guidance skills unless they introduce a distinct artifact, tool access pattern, or validation contract.  
   **Confidence**: High.

2. **Do not add platform-parity shims** for features that Claude supports natively but Cursor or Codex only support awkwardly or experimentally.  
   Examples: Codex slash-command emulation, Codex hook parity, deeply nested rule-graph abstractions for Cursor.  
   **Confidence**: High.

3. **Do not add default-on hooks or connectors** that can write, mutate, or fan out requests without tight scoping and explicit enablement.  
   **Confidence**: High.

4. **Do not add another generator/validator family** unless it removes an existing family or meaningfully collapses repo complexity.  
   In practice: no new top-level compatibility target, no new mirrored artifact tree, no “generator for the generator.”  
   **Confidence**: High.

5. **Do not add specialized agents whose only difference is persona or stack flavor** when an existing generalist agent plus a skill/reference would cover the use case.  
   **Confidence**: Medium-High.

### Contradiction worth preserving

Anthropic’s skills work is the best argument **for** carefully chosen additions. It says skills are valuable when they load progressively and package real expertise. OpenAI similarly says multiple agents are justified when instruction complexity or tool overload is genuinely the problem. So the evidence does **not** justify a blanket freeze. It just raises the bar:

- add only what reduces net cognitive load
- add only what has a distinct boundary
- add only what can be evaluated across the targets that must support it
- add only what can be disabled, scoped, or permissions-limited safely

## Key Insights

1. The main risk for `ycc` is no longer missing capability; it is **capability fragmentation**.
2. The strongest external evidence argues against **overlap, parity theater, and default autonomy**, not against reusable expertise itself.
3. The next mature step for this repo is likely **consolidation and sharper boundaries**, not a bigger surface.

## Evidence Quality

- **Strong contradictions**: 4
- **Credible critiques**: 8+
- **Confidence rating**: High

Rationale: the central claims are supported by multiple primary sources from Anthropic, OpenAI, GitHub, and the NCSC, plus strong practitioner evidence from Thoughtworks and Simon Willison. The main uncertainty is not whether bloat/fragility exist; it is which specific current `ycc` surfaces are underused in practice because this research did not include user telemetry.

## Contradictions & Uncertainties

- **Contradiction**: Anthropic’s Agent Skills article is a strong argument for adding well-scoped skills, which cuts against a simplistic “no more skills” stance.
- **Contradiction**: OpenAI explicitly allows multi-agent decomposition when prompts become too conditional or tools remain confusing after refinement.
- **Uncertainty**: This report does not include usage telemetry, issue frequency, or install-failure rates for existing `ycc` skills/agents. That data would sharpen the “what to remove or consolidate first” recommendation.
- **Uncertainty**: Some platform limitations are changing quickly. In particular, Codex hooks are under development and Anthropic remote connectors are beta, so fit judgments here should be revisited if those surfaces stabilize materially.

## Search Queries Executed

1. `site:anthropic.com "Equipping agents for the real world with Agent Skills" official`
2. `site:docs.anthropic.com Claude Code subagents tools inherit MCP official`
3. `site:docs.anthropic.com Claude Code hooks lifecycle security official`
4. `site:docs.cursor.com "Current limitations" AGENTS root level only single file official`
5. `site:openai.com "A practical guide to building AI agents" tools overlap multi-agent official`
6. `site:openai.com "Designing AI agents to resist prompt injection" official`
7. `site:simonwillison.net MCP prompt injection tool shadowing exfiltration`
8. `site:ncsc.gov.uk prompt injection inherently confusable official`
9. `site:martinfowler.com "How far can we push AI autonomy in code generation?"`
10. `site:docs.github.com reusable workflows limitations GITHUB_ENV unique reusable workflows official`

## Sources

- Local repo context:
  - [objective.md](../objective.md)
  - [README.md](../../../README.md)
  - [install.sh](../../../install.sh)
  - [scripts/validate-codex-skills.sh](../../../scripts/validate-codex-skills.sh)
  - [scripts/validate-cursor-skills.sh](../../../scripts/validate-cursor-skills.sh)

- External primary / high-quality sources:
  - Anthropic, “Equipping agents for the real world with Agent Skills,” Oct. 16, 2025.  
    https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
  - Anthropic, “Demystifying evals for AI agents,” Jan. 9, 2026.  
    https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents
  - Anthropic docs, “Create custom subagents,” accessed Apr. 16, 2026.  
    https://docs.anthropic.com/en/docs/claude-code/sub-agents
  - Anthropic docs, “Hooks reference,” accessed Apr. 16, 2026.  
    https://code.claude.com/docs/en/hooks
  - Claude Help Center, “Get started with custom connectors using remote MCP,” updated over 2 weeks ago, accessed Apr. 16, 2026.  
    https://support.claude.com/en/articles/11175166-get-started-with-custom-connectors-using-remote-mcp
  - OpenAI, “A practical guide to building AI agents,” accessed Apr. 16, 2026.  
    https://openai.com/business/guides-and-resources/a-practical-guide-to-building-ai-agents/
  - OpenAI, “Designing AI agents to resist prompt injection,” Mar. 11, 2026.  
    https://openai.com/index/designing-agents-to-resist-prompt-injection/
  - OpenAI Codex docs, “Configuration Reference,” accessed Apr. 16, 2026.  
    https://developers.openai.com/codex/config-reference#configtoml
  - Cursor docs, “Context / AGENTS / Rules,” accessed via search snippet Apr. 16, 2026.  
    https://docs.cursor.com/en/context
  - GitHub Docs, “Reusing workflow configurations,” accessed Apr. 16, 2026.  
    https://docs.github.com/en/enterprise-cloud@latest/actions/reference/workflows-and-actions/reusing-workflow-configurations
  - GitHub Docs, “Triggering a workflow,” accessed Apr. 16, 2026.  
    https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow
  - National Cyber Security Centre, “Mistaking AI vulnerability could lead to large-scale breaches, NCSC warns,” Dec. 4, 2025.  
    https://www.ncsc.gov.uk/news/mistaking-ai-vulnerability-could-lead-to-large-scale-breaches
  - Simon Willison, “Model Context Protocol has prompt injection security problems,” Apr. 9, 2025.  
    https://simonwillison.net/2025/Apr/9/mcp-prompt-injection/
  - Thoughtworks / Martin Fowler, “How far can we push AI autonomy in code generation?,” Aug. 5, 2025.  
    https://martinfowler.com/articles/pushing-ai-autonomy.html
