# Futurist Persona: Speculative Futures for AI Agents in Network/Infra Work (2027-2030+)

**Research Date**: 2026-04-20
**Persona**: Futurist (FUT)
**Repository**: `yandy-r/claude-plugins` (`ycc` bundle)
**Mandate**: Evidence-based 2-5 year forecasting for the `ycc` plugin bundle —
what should it be architected to absorb in 2027-2028 without a ground-up redesign?

> Epistemic stance: predictions are labeled **[PLAUSIBLE]**, **[SPECULATIVE]**,
> or **[WILD]** throughout. Evidence classes (primary/secondary/synthetic/opinion)
> are tagged at the end of each claim. This is not a hype document; contradictions
> are preserved, not smoothed.

---

## Executive Summary

Between 2027 and 2030, network, Kubernetes, container, virtualization,
network-security, and cloud operations will converge on a single pattern:
**declarative intent expressed in natural language, compiled to a typed
intermediate representation (IR), validated against a digital twin or
simulation, and reconciled by a control plane with closed-loop assurance**.
Autonomy will advance stage-by-stage (Juniper's Stage 4 → Stage 5 model), not
as a single leap. Humans remain in the loop for irreversible operations; the
question is not "does Claude replace tools?" but "does Claude sit upstream of
the IR?"

The top five implications for `ycc`:

1. **MCP is the substrate, not a feature.** By 2027, every major vendor will
   ship an MCP server (Cisco Cortex-equivalent already exists, Palo Alto has
   Cortex MCP in open beta). `ycc` should anticipate a world where it invokes
   vendor MCPs, not wraps their CLIs.
2. **A2A becomes the horizontal layer.** `ycc` agents that today are
   monolithic may need to expose Agent Cards for peer discovery by 2027-2028.
3. **The "intent → IR → validate → deploy → verify" workflow is the universal
   spine** across netops, k8s, cloud, and firewall. One command/skill shape
   serves all seven domains.
4. **Blast-radius guardrails move from best-practice to contractual.** Amazon's
   90-day code safety reset (March 2026) and Meta's SEV1 agent incident make
   HITL gates, deterministic policy engines, and egress controls table-stakes
   for any infra-touching agent.
5. **Harness is the differentiator.** As models converge, value accrues to the
   _scaffolding around the model_ — permissions, compaction, hooks, subagent
   delegation. `ycc`'s core value in 2027 is the reusable harness, not the
   prompts.

**Build verdict**: the `ycc` bundle should add a small number of _shape-defining_
primitives (a `network-change-review` skill, a Batfish-style IR validation
hook, an `agent-aware-zero-trust` skill) rather than per-vendor wrappers. Bet
on workflows; skip the vendor SDK skins.

---

## 1. Patents & IP Trends (2023-2026)

### Cisco

- **25,000th US patent granted September 2025**; patent velocity in network
  automation remains high. (secondary)
- **Orchestration service agent** patent: self-configuring observability
  agents that register with central management. Implication: Cisco is patenting
  the _agent lifecycle_, not the AI itself. (primary)
- **Workload protection enforcement readiness** patent: pre-enforcement
  validation that evaluates configuration/attribute settings and surfaces
  errors via GUI. Implication: "readiness gate" pattern is patented; `ycc`
  should not re-invent it but can wrap it. (primary)
- IEEE surveys funded by **Cisco University Research Program** describe a
  five-component closed-loop IBN architecture (Profiling, Translation,
  Resolution, Activation, Assurance). This is Cisco's de facto reference
  model. (secondary)

### Juniper / HPE

- Post-HPE acquisition, Juniper is staking claim on **"Self-Driving Network"**
  as a product category. Marvis Actions + Minis (digital twins) + LEM (Large
  Experience Model) + Apstra as the multi-vendor IBN reference. (primary)
- Stage 4 (assisted) → Stage 5 (fully autonomous) as a **publicly stated**
  roadmap. Agentic AI is "the catalyst." (primary)

### Palo Alto Networks

- **Prisma AIRS 3.0** (March 2026) secures the agentic AI lifecycle; **Cortex
  AgentiX** embeds graduated-autonomy agents; **Koi acquisition** (April 2026)
  creates "Agentic Endpoint Security" category. (primary)
- **Cortex MCP Server** in open beta — the first major security-vendor MCP
  server with real production use. SOC analyst asks Claude for high-severity
  cases; Claude queries the MCP server; case context is returned in seconds.
  (primary)
- Unit 42 research shows **MCP sampling** can be abused for resource theft,
  conversation hijacking, and covert tool invocation. This is a **concrete
  attack surface** that every MCP server (including `ycc`'s targets) must
  defend against. (primary)

### Pattern across vendors

Every major vendor is filing patents on **agent lifecycle primitives**
(registration, policy validation, enforcement readiness, remediation scoring)
rather than the underlying LLMs. The open surface for a third-party plugin
like `ycc` is therefore **workflow composition over these primitives**, not
reimplementing them.

---

## 2. Speculative Research Frontier

### Agentic workflows for infrastructure (ReAct + reflection)

- **"Optimizing Agentic Workflows using Meta-tools"** (arXiv:2601.22037, Feb 2026) shows AWO reduces LLM calls by up to 11.9% and increases task success
  by 4.2pp by discovering recurring ReAct patterns and crystallizing them
  into deterministic meta-tools. **[PLAUSIBLE → PROBABLE]** — `ycc` will want
  to emit meta-tools from successful workflow traces by 2028. (primary)
- **"A Practical Guide for Designing, Developing, and Deploying Production-
  Grade Agentic AI Workflows"** (arXiv:2512.08769, Dec 2025) recommends
  tool-first design **over MCP**, single-responsibility agents, externalized
  prompt management, clean separation between workflow logic and MCP
  servers, containerized deployment. `ycc` already honors most of these.
  (primary)
- **AFLOW** (ICLR 2025) uses MCTS to search the space of agentic workflows
  and self-optimize them. **[SPECULATIVE]** — auto-generated skills emitted
  from observed traces become plausible by 2027-2028. (primary)

### Natural-language → ACL / config (four independent research tracks converged in 2025)

- **Xumi** (arXiv:2508.17990, Aug 2025): NL intents → ACL rules with conflict
  detection and a Semantics-Network Mapping Table (SNMT) for hallucination
  mitigation. **10× faster than manual**. (primary)
- **Clarify** (HotNets 2025): Disambiguator module for ambiguous intents;
  incremental synthesis producing one stanza at a time. (primary)
- **NYU Natural Language Firewall** (Jan 2026): NL → structured rules with
  deterministic validation/enforcement. (primary, secondary)
- **Natural Language Interface for Firewall Configuration** (arXiv:2512.10789,
  Dec 2025): NL → **typed IR** → vendor compile (PA / FortiGate / Firepower) →
  Batfish validation. **Converged pattern**. (primary)
- **PeeringLLM-Bench** (AINTEC, Nov 2025): benchmark for LLM BGP config
  tasks. Benchmarks exist; evaluation is real. (primary)

**The pattern is converged**: NL → IR → validate → compile → deploy → verify.
This is **the** 2027 shape for network-change-as-code. `ycc` should adopt this
shape for any network-touching skill.

### Digital twins + closed loop

- **NVIDIA AODT** (Aerial Omniverse Digital Twin): physics-accurate 6G
  simulation; "Train → Simulate → Deploy" recursive data foundation. (primary)
- **"When Digital Twin Meets Generative AI"** (arXiv:2404.03025): GDT (GAI-
  driven Digital Twin) with explicit external and internal closed loops.
  (primary)
- 2026 Springer survey: 5-stage lifecycle (create → sync → predict → decide →
  feedback) as iterative closed loop for AI-enabled Digital Twin Networks.
  (primary)

### AIOps red-team research

- **AIOpsDoom** (arXiv:2508.06394) — **critical**. Adversaries manipulate
  system telemetry (error-inducing requests that steer agent decisions) to
  break state-of-the-art open-source AIOps solutions. Defense: **AIOpsShield**
  sanitization of telemetry. **[PLAUSIBLE → PROBABLE]** This becomes a design
  constraint for `ycc`: any skill that consumes telemetry must assume the
  telemetry may be adversarial. (primary)

---

## 3. Expert Predictions with Timelines

### Gartner (primary-source synthetic)

| Year | Prediction                                                                          |
| ---- | ----------------------------------------------------------------------------------- |
| 2027 | **25% of initial network configurations** done by GenAI (up from <3% in 2024)       |
| 2027 | **70% of enterprises** on multicloud networking platforms (up from 10% in 2024)     |
| 2027 | **Nearly all** network vendors embed AI/GenAI in management platforms               |
| 2027 | **65% of new SD-WAN** purchases are single-vendor SASE                              |
| 2028 | **15% of enterprises** adopt on-prem NaaS                                           |
| 2028 | **33% of business software** includes agentic AI capabilities (up from <1% in 2024) |

### IDC

- **By 2027, 50% of CIOs** will restructure identity/data access management
  because of AI agent growth — as part of zero-trust architectures. (synthetic)

### DoD / Federal

- **FY2027**: DoD Zero Trust target-level implementation objective across 45
  capabilities, 152 activities, 7 pillars. **Federal funding gravity around
  2027 is real** and not speculative. (primary)

### CNCF / Platform Engineering (2026 forecast)

- **Intent-to-Infrastructure** becomes default by 2027 — devs input high-
  level intent; agents provision compliant infra on golden paths. (secondary)
- **Janitor agents** decommission zombie infra automatically by 2027. (secondary)
- **AIOps 2.0**: full auto-remediation replaces suggestion-only. (secondary)
- **"Agent golden paths"** — platform teams define agent golden paths the
  same way they define developer golden paths today. (secondary)

### Practitioner voices (balanced against the hype)

- **Ivan Pepelnjak** (Packet Pushers, Aug 2025): automation projects fail
  because the _network design_ is wrong, not because the tooling is wrong.
  AI layered on top of bad design amplifies the problem. (opinion, but
  highly credentialed)
- **John Kindervag** (Illumio): "AI doesn't change the zero-trust paradigm
  — it reinforces it." AI models themselves become liabilities if not
  governed by zero-trust. (opinion)

---

## 4. Emerging Technologies (watchlist for `ycc`)

| Technology                                     | Status (2026-04)                                                                                         | 2027-2028 Trajectory                                                                    | `ycc` implication                                                                                        |
| ---------------------------------------------- | -------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| **MCP** (Anthropic, Linux Foundation governed) | 10,000+ public servers, 97M+ monthly SDK downloads, OAuth 2.1 shipped April 2026                         | Streamable HTTP v2 (stateless, multi-instance), Tasks primitive lifecycle, Server Cards | `ycc` should plan for MCP Server Cards (.well-known/) exposure and Tasks primitives for long-running ops |
| **A2A** (Google, now Linux Foundation)         | 150+ orgs, v1.0 Signed Agent Cards, 22k GitHub stars, production on Azure AI Foundry + Bedrock AgentCore | Horizontal agent bus; ACP merged in                                                     | `ycc` agents may need Agent Cards by 2028 if they're to be delegated to                                  |
| **Crossplane**                                 | v2, CNCF pre-graduation, OCI Provider at 100+ services                                                   | Graduation; "AI-native control plane"; declarative substrate for agents                 | `ycc` skill for Crossplane XRD authoring; declarative intent replaces imperative IaC                     |
| **llm-d**                                      | CNCF Sandbox (March 2026); Red Hat, Google, IBM, CoreWeave, NVIDIA                                       | Standard inference substrate on k8s; replaces ad hoc vLLM setups                        | `ycc` k8s skill should know llm-d topology (disaggregated prefill/decode)                                |
| **Kubernetes AI Conformance (KARs)**           | v1.35 codified March 2026                                                                                | Sovereign AI standards, automated validation                                            | `ycc` k8s skill should lint against KARs                                                                 |
| **Gateway API Inference Extension**            | GA Feb 2026 (v1.3.1)                                                                                     | Model-aware routing, KV-cache-aware scheduling                                          | `ycc` skill should know inference-aware ingress                                                          |
| **Kyverno**                                    | CNCF Graduated March 2026                                                                                | Admission-time policy layer                                                             | `ycc` should pair with ArgoCD+Kyverno pattern                                                            |
| **Dragonfly**                                  | CNCF Graduated Jan 2026                                                                                  | Image distribution for AI (5-min pulls → seconds)                                       | Nice-to-know; low urgency for `ycc`                                                                      |
| **OpenTelemetry gen_ai semconv**               | stable early 2026                                                                                        | Unified LLM + infra observability                                                       | `ycc` telemetry hooks should emit gen_ai attrs                                                           |
| **Batfish**                                    | Mature; Itential integration for "governed change management" (human or AI-initiated rollback)           | LLM-for-BGP benchmarks (PeeringLLM-Bench)                                               | `ycc` `network-change-review` skill should call Batfish as a validation gate                             |
| **NVIDIA AODT / network digital twin**         | 6G physics-accurate simulation                                                                           | Pre-deployment validation mainstream                                                    | `ycc` skill for twin-validated changes (2028+)                                                           |

---

## 5. Future Scenarios

### Plausible (base case) — 2027 state of the world

- Every major network/security vendor ships an **official MCP server**.
- **25% of new network configs** emitted by GenAI, typically via the intent →
  IR → validate → deploy → verify pattern. Manual CLI editing survives in
  legacy / air-gapped environments.
- Claude, ChatGPT, Gemini, Copilot **all speak MCP**. Tool-use fragmentation
  is gone.
- `ycc`'s value prop is **workflow composition + harness hygiene** — not
  reimplementing vendor tools.
- Platform teams ship **"agent golden paths"**; `ycc` skills become the
  templates used inside enterprise IDPs (Backstage, Port, Humanitec).
- Auto-rollback with Batfish-style validation is **table stakes** for any
  infrastructure-touching agent.

### Contrarian (pessimistic) — 2027 disappointment case

- **Gartner predictions miss by ~50%.** GenAI-generated configs plateau at
  ~10%, not 25%. Reason: hallucination in long-tail vendor features is
  unresolved; enterprises refuse to delegate.
- **MCP adoption bifurcates.** Public web-tools/SaaS standardizes on MCP.
  Enterprise / regulated industries require proprietary, air-gapped agent
  protocols. `ycc` serves the former; the latter remains unaddressed.
- **Agent incidents dominate the news cycle.** After 3-5 high-profile
  incidents like the 2026 Amazon Q and Meta SEV1 outages, enterprise policy
  requires human approval for every infra-touching agent action.
  `ycc`'s autonomy levels regress.
- **Ivan Pepelnjak's warning comes true**: AI automation piled on top of
  badly-designed networks amplifies failure. Network automation remains a
  discipline where AI helps _diagnose_ but not _remediate_.

### Wild (low-probability, high-impact) — 2028-2030

- **[WILD]** A single foundation model (Claude Opus 5.x or GPT-Next) is
  trained specifically on vendor configs + RFC corpus + change-management
  logs. The "network engineer LLM" replaces most Stage-4 assisted workflows.
  `ycc` becomes a harness / personality / permission layer around this.
- **[WILD]** Network digital twins reach commodity pricing. Every production
  network has a running twin; AI agents test every proposed change in the
  twin before deployment. `ycc` skill surface shifts from "generate config"
  to "describe desired twin state."
- **[WILD]** Sovereign AI / regulatory fragmentation. EU AI Act, US agentic-
  AI rules, China's own regime force per-region MCP server variants. A
  cross-target plugin bundle like `ycc` gains _new value_ as an abstraction
  over regional compliance profiles.
- **[WILD]** Agentic self-improvement via AFLOW / AWO becomes real at the
  plugin level. `ycc` emits new skills automatically from observed workflow
  traces. Maintainer's role shifts from authoring skills to reviewing AI-
  generated skill PRs.

---

## 6. Breakthrough Dependencies

For the plausible base case to materialize, these have to break through:

1. **Context window + retrieval economics.** Long-running multi-turn ops
   still drown in token cost. MCP's **reference-based results** and better
   streaming (2026 roadmap) are the bridge. If these slip, agentic ops
   stays toys-only.
2. **IR stability across vendors.** Xumi-style SNMT, Batfish's vendor-
   neutral model — all work, but there's no single adopted standard. If
   vendors fragment (Cisco YANG vs Juniper OpenConfig vs Arista EOS API vs
   Palo Alto XML), the IR layer gets Balkanized.
3. **Trust trajectory validation.** Claude Code's own data shows auto-
   approve rises from 20% (<50 sessions) to 40%+ (750 sessions). If this
   _reverses_ after high-profile incidents, autonomy plateaus.
4. **Telemetry-integrity defenses.** AIOpsDoom demonstrated telemetry
   poisoning is feasible. Without AIOpsShield-style sanitization becoming
   default, auto-remediation is unsafe in adversarial environments.

---

## 7. Wild Cards

- **Anthropic ships first-party "infra agent" bundles.** If Claude itself
  ships an official k8s / networking plugin, `ycc` overlap becomes a
  liability. Probability: meaningful by 2028.
- **A single vendor cartel (Cisco + Palo Alto + HPE-Juniper) fragments
  MCP.** Each ships its own agentic extension that doesn't interoperate.
  Probability: low but historically plausible (think SNMP MIB variants).
- **AI-generated vulnerabilities in vendor configs become a CVE category.**
  `ycc` skills that emit production configs become a liability vector.
- **Regulatory forcing function on "autonomy levels."** An EU-style regime
  classifies infra-agent autonomy on a 1-5 scale; `ycc` skills need explicit
  declared levels.
- **The "vibe coding" backlash.** Enterprises mandate that all AI-generated
  IaC be reviewed by senior engineers (already happening at Amazon post-
  March 2026). `ycc` skills must emit review-ready artifacts, not auto-
  applied changes.

---

## 8. Timeline Predictions

### 2027 (high confidence)

- MCP + A2A are the two universal agent protocols; no viable alternatives.
- 25%+ of new network configs GenAI-emitted (Gartner base case).
- DoD Zero Trust FY2027 milestone drives federal contractors into policy-
  as-code + agent-aware ZT frameworks.
- Crossplane graduates CNCF; becomes the declarative substrate for AI-
  agent infra ops.
- ArgoCD + Kyverno + AI auto-remediation becomes standard GitOps pattern.
- Gateway API Inference Extension is the default for k8s LLM ingress.
- Every major network/security vendor ships an MCP server.

### 2028 (medium confidence)

- **Stage 5 autonomy** (fully autonomous with HITL only on irreversible
  ops) is in limited production for campus/branch networks (HPE-Juniper's
  timeline).
- **Agent-Aware Zero Trust** frameworks become reference architectures.
- Self-improving agentic workflows (AFLOW / AWO-style) start appearing as
  features in enterprise platforms.
- Network digital twins used for pre-deployment validation of AI-generated
  configs in regulated industries.
- `ycc` (or equivalent) bundles start being _consumed_ by enterprise IDPs
  rather than used standalone.

### 2029-2030 (lower confidence, higher variance)

- Natural-language device config is the default interface for network
  engineers; CLI persists as a specialist/debug tool.
- LLM-native configuration language (beyond YAML/JSON) emerges.
- Per-region sovereign agent protocols fragment the global MCP ecosystem.
- First-party Anthropic / OpenAI infra bundles ship; third-party bundles
  like `ycc` compete on _opinions_ rather than _coverage_.

---

## 9. Exponential Trends

| Trend                         | Historical doubling                      | Projection to 2028                                                               |
| ----------------------------- | ---------------------------------------- | -------------------------------------------------------------------------------- |
| MCP SDK downloads (monthly)   | ~3x year-over-year since Nov 2024 launch | ~500M+ monthly by 2028 **[SPECULATIVE]**                                         |
| Public MCP servers            | 10,000+ as of 2026; growing 2-3x/yr      | 50,000-100,000 by 2028 **[PLAUSIBLE]**                                           |
| GenAI share of network config | <3% (2024) → 25% (2027) target           | ~40% by 2028 **[PLAUSIBLE]** if Gartner prediction holds                         |
| Agent auto-approve rate       | 20% (<50 sessions) → 40%+ (750+) in 2026 | 50-60% by 2028 **[PLAUSIBLE]** if no major incidents                             |
| K8s clusters per enterprise   | 10-100 (2024) → 100-1000 (2026)          | 1000-10000 (2028) **[SPECULATIVE]** → auto-remediation becomes survival-critical |

---

## 10. Key Insights — What Should `ycc` Absorb Without Ground-Up Redesign?

These are the architectural bets that must hold.

### 10.1 The universal workflow spine

**Bet**: Every infrastructure-touching skill in `ycc` should conform to the
universal shape:

```
NL intent
  → typed intermediate representation (IR)
    → validate (Batfish, opa/rego, kubeval, cfn-lint, etc.)
      → plan (show diff, estimate blast radius)
        → confirm (HITL gate on irreversible ops)
          → deploy
            → verify (re-run validators against live state)
              → rollback-ready
```

This shape maps onto: network configs, firewall ACLs, k8s manifests,
Terraform plans, Crossplane XRDs, cloud IAM policies, SASE/ZTNA policies.
**One reusable skill template fits all seven domains.**

**Concrete `ycc` action**: ship a `network-change-review` _meta-skill_ that
implements this spine and can be specialized per-domain. Do NOT ship
`fortigate-acl-skill`, `panos-acl-skill`, `cisco-asa-acl-skill` as separate
skills — they all collapse into the spine + vendor adapter.

### 10.2 MCP is substrate, not feature

**Bet**: By 2027, `ycc` skills will predominantly _consume_ vendor MCP
servers, not wrap vendor CLIs.

**Concrete `ycc` action**: the `ycc` bundle should add first-class
documentation/conventions for _composing with_ external MCP servers
(Cortex MCP, Terraform MCP, AWS MCP, Apstra MCP-if-released). The
bundle-author skill should scaffold MCP-consuming skills, not just
CLI-wrapping skills.

### 10.3 A2A is optional, but prepare for it

**Bet**: `ycc` subagents may need Agent Cards by 2028 so other tools can
delegate to them.

**Concrete `ycc` action**: structure subagents so their frontmatter can
generate an Agent Card. Do not ship A2A now; architect for it.

### 10.4 Blast-radius guardrails are non-negotiable

**Bet**: Post-Amazon-Q-incident and post-Meta-SEV1, any infra-touching skill
that doesn't emit a blast-radius warning is a liability.

**Concrete `ycc` action**: a cross-cutting hook (PreToolUse / PostToolUse
analog) that, for any tool call touching production-adjacent resources,
emits a blast-radius estimate (number of resources, reversibility, HITL
requirement). Make it a reusable primitive.

### 10.5 Telemetry is adversarial

**Bet**: AIOpsDoom-class attacks become a real concern in production ops
by 2027. `ycc` skills consuming telemetry (Prometheus, OTel, syslog) must
assume content may be attacker-controlled.

**Concrete `ycc` action**: a `telemetry-sanitizer` helper in
`ycc/skills/_shared/scripts/` — strip HTML/script, validate schema, cap
token counts on unstructured user-generated fields. Skills consuming
telemetry should always route through it.

### 10.6 Digital twin awareness (but don't implement)

**Bet**: By 2028, validation in a digital twin (Batfish, NVIDIA AODT,
Juniper Marvis Minis) precedes any production change.

**Concrete `ycc` action**: the `network-change-review` skill should have a
pluggable "validate in twin" step. Ship with Batfish as reference; leave
hooks for AODT / Marvis / Apstra.

### 10.7 Don't build per-vendor skins

**Bet**: Every major vendor ships an MCP server by 2027 → vendor-CLI
wrappers in `ycc` become technical debt.

**Concrete `ycc` action**: **reject** "cisco-ios-skill", "fortigate-skill",
"panos-skill", "junos-skill" as separate skills. Ship one
`vendor-config-review` skill that delegates to vendor MCPs when available
and falls back to CLI/SSH only when necessary. This is the opposite of
what a naive completionist roadmap would suggest.

### 10.8 The IR layer is the integration point

**Bet**: Xumi / Clarify / NYU firewall research converge on a typed IR as
the common substrate.

**Concrete `ycc` action**: skill templates should emit an IR (JSON,
typed), not vendor syntax. Compile to vendor syntax via adapters. This
survives the MCP transition: the IR is compiled either by `ycc` or by
the vendor MCP server.

### 10.9 Zero-trust / agent-aware ZT as a first-class skill

**Bet**: By 2027, every agent acting on infrastructure must declare its
autonomy level, scoped credentials, and HITL gates.

**Concrete `ycc` action**: an `agent-aware-zero-trust` skill that scaffolds
an agent declaration (autonomy level, credentials scope, HITL gates, audit
log shape). Useful for `ycc` internally and exportable to user projects.

### 10.10 Harness is the differentiator

**Bet**: Claude Code's own architecture shows "98.4% infrastructure, 1.6%
AI" — permission system, compaction, hooks, subagent delegation. As models
converge, value accrues to the harness.

**Concrete `ycc` action**: invest in the harness primitives (hooks,
subagent patterns, compaction-friendly skill structure, permission
patterns) _before_ inventing domain skills. A great harness is more
durable than a great prompt.

---

## 11. Evidence Quality & Source Labels

| Source class  | Examples                                                                                                                                                                                                                                                       | Treated as                                         |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| **Primary**   | arXiv papers (Xumi, AFLOW, AWO, AIOpsDoom, Clarify, NYU firewall, GDT, network digital twin survey); CNCF announcements; USPTO patent filings; MCP roadmap post; A2A v1.0 release notes; vendor press releases (Palo Alto Prisma AIRS 3.0, HPE-Juniper Marvis) | Load-bearing; cited by timeline                    |
| **Secondary** | Network to Code (Gartner synthesis), Packet Pushers (Ivan Pepelnjak), New Stack, CNCF blog, Juniper engineering blog, SiliconANGLE, ChannelInsider, Platform Engineering community posts                                                                       | Directional; cited as "industry reads this as ..." |
| **Synthetic** | Gartner forecasts, IDC forecasts, MarketsandMarkets projections                                                                                                                                                                                                | Directional; explicitly labeled as synthetic       |
| **Opinion**   | Ivan Pepelnjak's "reality check", Kindervag's ZT framing, Medium/DEV posts                                                                                                                                                                                     | Directional; cited for color                       |

**Speculation labels used in this document**:

- **[PLAUSIBLE]** = >60% likely by the stated timeline, based on convergent
  evidence from primary + secondary sources
- **[SPECULATIVE]** = 20-60% likely; single source or small N of sources
- **[WILD]** = <20% likely; included for tail-risk awareness

---

## 12. Contradictions & Uncertainties (Preserved, Not Smoothed)

1. **Gartner's 25%-by-2027 vs Ivan Pepelnjak's "design first"**: optimistic
   adoption vs skeptical on whether AI can compensate for bad network design.
   Both are true; they're talking about different populations (greenfield
   vs legacy brownfield).
2. **"MCP is the future"** (vendor + Anthropic consensus) **vs MCP security
   research** (Palo Alto Unit 42: sampling-abuse attack vectors). Both are
   true; the spec is maturing but is **not** yet safe-by-default.
3. **"Don't wrap vendor tools"** (my recommendation) **vs reality that
   vendor MCPs are open-beta or non-existent** as of 2026-04. There's a
   2027 bridging period where some vendors lag. `ycc` may need temporary
   wrappers that are explicitly marked "sunset when vendor MCP ships."
4. **"Auto-approve rises with familiarity"** (Claude Code longitudinal
   data) **vs "incidents force regression"** (Amazon Q, Meta SEV1). Autonomy
   will be a stair-step function, not a smooth curve.
5. **"Agents everywhere"** (industry marketing) **vs Gartner's own 33% by
   2028 prediction** — the majority of software will _not_ have agentic
   AI by 2028. This space is growing fast but from a low base.
6. **"Crossplane becomes the substrate"** (CNCF blog) **vs enterprise
   reality that Terraform + Ansible still dominate**. Crossplane is
   architecturally attractive but adoption is concentrated in cloud-native
   shops. `ycc`'s skill mix should reflect the long tail.
7. **"AI replaces the CLI"** (marketing) **vs the fact that every serious
   netops person still needs CLI access for debugging**. `ycc` should not
   assume the CLI is dead.

---

## 13. What Should `ycc` Build vs Not Build (Futurist Ranking)

Ranked by 2027-2028 durability × value-to-maintenance ratio.

| #   | Proposal                                                                                                                     | Form                 | Domain                         | Priority             | Why NOT                                                                                  |
| --- | ---------------------------------------------------------------------------------------------------------------------------- | -------------------- | ------------------------------ | -------------------- | ---------------------------------------------------------------------------------------- |
| 1   | `network-change-review` (the universal spine: NL intent → IR → validate → plan → confirm → deploy → verify → rollback-ready) | Skill + command      | Cross-domain (net, k8s, cloud) | **P0**               | Scope creep if not disciplined; needs Batfish/opa/kubeval orchestration                  |
| 2   | `blast-radius` hook (PreToolUse analog that estimates blast radius on infra-touching tool calls)                             | Hook + script        | Cross-domain                   | **P0**               | Hard to define "blast radius" generically; start with per-tool heuristics                |
| 3   | `telemetry-sanitizer` shared helper (AIOpsDoom defense)                                                                      | Script in `_shared/` | Cross-domain                   | **P0**               | Needed for any obs/AIOps skill to be production-safe                                     |
| 4   | `vendor-config-review` (delegates to vendor MCP if available, SSH/CLI fallback)                                              | Skill                | Net / NetSec                   | **P1**               | Depends on vendor MCP availability; ship minimal scaffold, expand as MCPs arrive         |
| 5   | `agent-aware-zero-trust` (declarative agent manifest: autonomy level, scope, HITL gates)                                     | Skill                | Security                       | **P1**               | Overlaps with vendor frameworks; value is the _Claude-side_ scaffold                     |
| 6   | `k8s-ai-workload-lint` (KARs + Gateway API Inference Extension awareness)                                                    | Skill                | K8s/AI                         | **P1**               | Fast-moving target; KARs v1.35 already needs refresh                                     |
| 7   | `crossplane-xrd-author` (declarative intent for multi-cloud)                                                                 | Skill                | Cloud / IaC                    | **P2**               | Low adoption outside cloud-native shops; re-evaluate post-graduation                     |
| 8   | `gitops-drift-remediate` (ArgoCD + Kyverno + HITL rollback)                                                                  | Skill + agent        | K8s / GitOps                   | **P2**               | Akuity and others ship commercial agents; Claude-side value is the workflow              |
| 9   | `mcp-composer` (scaffold for composing `ycc` skills with external MCP servers)                                               | Meta-skill           | Cross                          | **P2**               | Depends on `plugin-dev:mcp-integration` existing already; may be a doc rather than skill |
| 10  | Per-vendor skill (Cisco, Fortinet, Juniper, Palo Alto, Arista)                                                               | Skill                | NetSec                         | **AVOID**            | Every vendor ships MCP by 2027; per-vendor skin becomes dead weight                      |
| 11  | `digital-twin-validate` (AODT / Apstra / Marvis Minis wrapper)                                                               | Skill                | NetOps                         | **DEFER to 2027-28** | Vendor tooling not yet ready for open integration                                        |
| 12  | `llm-d-deploy` / `inference-stack-bootstrap`                                                                                 | Skill                | K8s/AI                         | **P2**               | Fast-moving; llm-d is Sandbox, may iterate rapidly                                       |
| 13  | `a2a-agent-card` (expose `ycc` subagents as A2A agents)                                                                      | Meta-primitive       | Cross                          | **DEFER**            | Don't ship A2A until v1.x settles; architect frontmatter to support it                   |

**The top 3 (P0) are the load-bearing bets.** Everything else is replaceable
or deferrable. The anti-pattern to avoid is **per-vendor proliferation**.

---

## 14. Search Queries Executed

1. `intent based networking patent Cisco 2025 closed loop automation`
2. `agentic workflow infrastructure operations research paper ReAct 2025 2026`
3. `MCP Model Context Protocol roadmap 2026 resources sampling roots`
4. `CNCF 2026 graduation pipeline AI ML working group platform engineering`
5. `intent based networking 2027 prediction Gartner forecast timeline`
6. `AIOps incident response LLM 2026 Prometheus OpenTelemetry narrative`
7. `Crossplane future direction 2026 multi-cloud abstraction AI`
8. `zero trust policy as code AI authoring SASE 2027`
9. `Palo Alto Precision AI network security autonomous agent roadmap`
10. `natural language ACL firewall rule generation research paper 2025`
11. `network digital twin AI simulation closed loop 2026`
12. `Kubernetes AI operator LLM cluster troubleshooting 2026 research`
13. `Anthropic MCP ecosystem vendor MCP server Cisco Juniper Palo Alto 2026`
14. `A2A Google agent to agent protocol vs MCP 2026 adoption function calling`
15. `network automation 2027 prediction expert Ivan Pepelnjak NetworkToCode`
16. `ArgoCD GitOps future 2027 multi-cluster AI policy drift remediation`
17. `Cisco patent AI agent network configuration USPTO 2025`
18. `Juniper Mist Marvis AI 2026 roadmap autonomous operations predictions`
19. `AI agent safety blast radius infrastructure changes 2026 guardrails`
20. `Claude Code plugins architecture future 2027 extensibility vendor ecosystem`
21. `AI agent network config rollback verification Batfish intermediate representation 2026`
22. `platform engineering AI agent self service 2027 golden path IDP prediction`

---

## 15. Key Primary-Source Citations

- MCP 2026 roadmap — <https://blog.modelcontextprotocol.io/posts/2026-mcp-roadmap/>
- Xumi (NL → ACL with conflict detection) — <https://arxiv.org/html/2508.17990v1>
- Natural Language Interface for Firewall Configuration — <https://arxiv.org/html/2512.10789v1>
- Clarify (Disambiguator for NL intents) — <https://conferences.sigcomm.org/hotnets/2025/papers/hotnets25-final189.pdf>
- AWO / meta-tools — <https://arxiv.org/html/2601.22037v2>
- AFLOW — <https://arxiv.org/pdf/2410.10762>
- AIOpsDoom / AIOpsShield — <https://arxiv.org/abs/2508.06394>
- GDT (GAI-driven Digital Twin) — <https://arxiv.org/html/2404.03025v2>
- AI-driven Digital Twin Networks survey — <https://link.springer.com/article/10.1007/s44443-026-00522-y>
- A2A protocol — <https://github.com/a2aproject/A2A>
- llm-d CNCF Sandbox — <https://www.cncf.io/blog/2026/03/24/welcome-llm-d-to-the-cncf-evolving-kubernetes-into-sota-ai-infrastructure/>
- Crossplane + AI — <https://blog.crossplane.io/crossplane-ai-the-case-for-api-first-infrastructure/>
- Palo Alto Prisma AIRS 3.0 — <https://www.paloaltonetworks.com/company/press/2026/palo-alto-networks-secures-agentic-ai-with-prisma-airs-3-0>
- Palo Alto Cortex MCP Server — <https://www.paloaltonetworks.com/blog/security-operations/introducing-the-cortex-mcp-server/>
- HPE/Juniper Mist self-driving roadmap — <https://www.hpe.com/us/en/newsroom/press-release/2025/08/hpe-accelerates-self-driving-network-operations-with-new-mist-agentic-ai-native-innovations.html>
- CNCF Kyverno graduation — <https://www.cncf.io/announcements/2026/03/24/cloud-native-computing-foundation-announces-kyvernos-graduation/>
- Claude Code architecture deep dive — <https://www.penligent.ai/hackinglabs/inside-claude-code-the-architecture-behind-tools-memory-hooks-and-mcp/>
- Platform Engineering CNCF 2026 forecast — <https://www.cncf.io/blog/2026/01/23/the-autonomous-enterprise-and-the-four-pillars-of-platform-control-2026-forecast/>
- Batfish (SIGCOMM 2023 evolution paper) — <https://dl.acm.org/doi/10.1145/3603269.3604866>

---

## 16. One-Paragraph Conclusion

By 2027-2028, the infrastructure-operations world runs on a universal
pattern: **natural-language intent → typed intermediate representation →
multi-layer validation (syntactic, semantic, policy, digital-twin) → plan
with blast-radius disclosure → human confirmation on irreversible
operations → deploy → verify against live state → rollback-ready**. This
pattern is the same whether the target is a Cisco ACL, a Kubernetes
manifest, a Palo Alto SASE policy, a Crossplane XRD, or an AWS IAM role.
MCP is the plumbing; A2A is the horizontal bus; every major vendor ships
an MCP server; blast-radius guardrails are table stakes; telemetry is
assumed adversarial. The `ycc` bundle's durable bet is the _harness_ — the
reusable workflow spine, the blast-radius hook, the telemetry sanitizer,
the agent-aware-zero-trust scaffold — not per-vendor skins. If `ycc` ships
those three-to-four P0 primitives well, it survives 2027-2028 without a
ground-up redesign. If it sprints into per-vendor wrappers, every MCP
server release invalidates another skill. **Build the harness, not the
vendor skins.**
