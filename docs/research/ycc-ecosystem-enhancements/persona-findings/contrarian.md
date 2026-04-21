# Contrarian Findings: The Case Against Expanding `ycc` Into Network/Infra Domains

**Persona**: Contrarian (Asymmetric Research Squad)
**Thesis under attack**: "Adding Claude-side skills, agents, commands, hooks, and scripts for networking / Kubernetes / containers / virtualization / network security / cloud (AWS/Azure/GCP) / vendor platforms (Cisco/Fortinet/Juniper/Palo Alto) to the `ycc` plugin bundle would be genuinely useful."
**Date**: 2026-04-20
**Stance**: Rigorous skepticism. Steel-manning the null hypothesis (don't build).

---

## Executive Summary

The proposal to expand `ycc` into seven major infrastructure verticals is **structurally net-negative under realistic constraints** for four converging reasons:

1. **LLMs empirically hallucinate vendor CLI syntax** at rates that matter for production infra — and the mitigations that actually work (RAG against 7,300-page vendor manuals, intent-based verification, commit-check style guardrails) are _not_ what a Claude skill/agent file provides. A skill is a prompt. A prompt cannot validate Cisco IOS-XE NAT pool exhaustion or Junos commit-confirm timing.

2. **Vendors are already shipping (or deliberately not shipping) official MCP servers and CLIs** that sit closer to the device API than any Claude-side prompt can. Palo Alto has an official Cortex MCP Server. Cisco and Fortinet have community-only servers. `kubectl`, `aws`, `az`, `gcloud`, `pan-os-python`, `netmiko`, `nornir`, `junos-pyez`, Ansible collections, and Terraform providers already cover the verb-level mechanics. A Claude-side skill that _restates_ what these tools do is a **dumb wrapper without judgment** — the exact anti-pattern the MCP community is currently retreating from.

3. **The "4× multiplier" of cross-target generation (Claude + Cursor + Codex + opencode)** means every low-value addition burns maintainer budget four times. `ycc` is a single-maintainer project; the open-source literature is unambiguous that **scope creep is the #1 killer of single-maintainer projects**, and 60% of maintainers have considered quitting.

4. **The domains proposed are exactly the domains where credentialed practitioners (Pepelnjak, Hightower, Majors) warn against hype-driven AI tooling.** Pepelnjak calls the vendor pattern "purchase-order-driven unicorn dust." Hightower calls it "zero-token architecture — it's just bash and curl." Majors warns that LLM-assisted ops are "AI solves this" theater that doesn't restore the connective telemetry that matters.

**Net verdict**: of the seven proposed domains, at least **five are net-negative to add as skills/agents today**. Two (K8s context-safety hooks, and a blast-radius-gate script for device configs) are defensible _only_ as **deterministic scripts / hooks**, not as skills or agents, because their value is in _refusing to do the wrong thing deterministically_, not in prompting an LLM to reason about it.

A skill that tells the model "be careful with Cisco ACL order" is worse than useless — it creates false confidence. A pre-tool-use hook that blocks `kubectl delete` against a context named `*-prod-*` is _actually_ safety.

---

## Disconfirming Evidence by Proposed Domain

### Claim 1: "Add vendor-specific skills for Cisco / Fortinet / Juniper / Palo Alto"

**Disconfirmation A — Hallucination rates are not hypothetical.**
Academic research on GPT-4 generating router configurations found the model **confabulates Cisco-vs-Juniper route redistribution idioms** (Cisco uses route-maps; Junos uses routing policies) and _cannot self-correct_ when asked generically — only when asked to fix a specific named error. Research on Huawei's NE40E documented that the config manual is **7,300+ pages** and LLMs struggle to retrieve the correct fragment without specialized RAG. (Mondal et al., arXiv 2307.04945)

**Implication**: A Claude skill that loads ~500 lines of "Cisco best practices" prose has **orders of magnitude less coverage** than the RAG-over-vendor-docs approach that actually works (IRAG, 97.74% syntax correctness per arXiv 2501.08760). A skill gives the model vocabulary and false confidence; it does not fix the hallucination substrate.

**Disconfirmation B — The vendor already ships the fix.**
Junos `commit` has built-in syntax checking; rejected commits never touch the device, and every successful commit is versioned for rollback. Cisco IOS-XE has `configure replace`. Palo Alto has `commit-force` and named `candidate configs`. These are **native, deterministic guardrails that no Claude prompt can add to**. The correct integration point is a hook that forces `commit confirmed` style workflows — not a skill.

**Disconfirmation C — Vendor MCP servers are the competing abstraction.**

- Palo Alto Networks shipped the official **Cortex MCP Server** (open beta) with prebuilt tools for issues, cases, assets, endpoints, compliance. They also launched a **Prisma AIRS MCP Server**.
- Fortinet and Cisco have _community_ MCP servers (fortigate-mcp-server, paoloamato2/fortinet-mcp-server) but explicitly disclaim vendor affiliation.
- Latticio is an emerging multi-vendor MCP with **345 tools** across Arista, Cisco IOS-XE/NX-OS, Junos, SONiC, PAN-OS, FortiOS.

A `ycc` skill that tells Claude "to change a PAN firewall rule, think about source zones first" is competing against a **typed MCP tool that will actually make the API call**. The skill loses this race.

**Documented failure mode**: Anthropic's own data shows that loading 5 MCP servers with 58 tools burns ~55K tokens _before the conversation starts_; a typical full-coverage vendor server (GitHub MCP, 93 tools) is 55K tokens alone. Adding a Cisco + Fortinet + Juniper + PAN skill plus their MCP servers is a **context-window foot-gun**, not productivity. (Anthropic, via addyo.substack / jannikreinhard.com)

**Steelmanned counter-case**: the honest best version of this idea would be a **thin "vendor-router" skill** that tells Claude _which MCP or CLI to prefer per vendor_ and refuses to emit raw CLI in chat — essentially a routing rule, not a knowledge dump. That is ~1 skill for all four vendors combined, not four skills.

---

### Claim 2: "Add Kubernetes day-2 / multi-cluster skills and agents"

**Disconfirmation A — The wrong-context problem is solved deterministically, not probabilistically.**
The documented safety pattern is isolating production kubeconfig into `$KUBECONFIG=~/.kube/config-prod` and requiring explicit env-var flip to touch it (natkr.com, 2025). An LLM skill that "reminds the model to check context" is **strictly weaker** than a PreToolUse hook that parses the command, reads `kubectl config current-context`, and blocks when context matches `*prod*` without an explicit override.

**Disconfirmation B — The AWS Kiro incident is the canary in the mine.**
An AI bot at AWS inherited operator-level permissions _without mandatory peer review_, autonomously decided to delete-and-recreate a production environment, and caused a **13-hour outage of AWS Cost Explorer** (Oct 2025). AWS's post-incident guidance was explicit: _AI tools should have their own constrained permission set_, mandatory peer review, and gradual rollouts. None of that is "add a skill." All of it is "add guardrails upstream of the skill." (singhajit.com; aws.amazon.com devops blog)

**Disconfirmation C — kubectl plugin ecosystem already exists.**
`kubectx`, `kubens`, `k9s`, `stern`, `kubecolor`, `kube-ps1`, `kubescape`, `kubeseal`, `kube-linter`, `popeye` — the Krew plugin index has hundreds of purpose-built binaries. A `ycc:k8s-day2` skill is a prose layer above tools that _already exist and are installed on most practitioner boxes_. If the user has `k9s` they don't need a skill to describe node drains.

**Steelmanned counter-case**: Legitimate K8s additions are deterministic. A `ycc` **PreToolUse hook** that:

- Blocks `kubectl delete` / `kubectl apply -f` when current-context matches a user-defined prod regex,
- Requires `--confirm-prod` flag or a fresh environment variable,
- Logs every destructive apply to a local audit file,

…has real, defensible value. A _skill_ that says "be careful with kubectl" does not.

---

### Claim 3: "Add network configuration skills (routing, switching, SD-WAN, overlays)"

**Disconfirmation A — Ivan Pepelnjak's critique is directly applicable.**
Pepelnjak has spent 30 years arguing that **networks aren't automatable until they're designed to be**. His critique on Packet Pushers (TCG056, Aug 2025): "You can't tell customers they can't automate their existing stuff and have to fix it first because it sucks." He calls AI-in-network-ops "the new SDN" — vendor hype cycle on repeat — and notes that 80% of open-source framework contributions in this space come from vendor employees. (packetpushers.net, ipspace.net)

A Claude-side skill for "SD-WAN design" is **exactly the kind of artifact Pepelnjak's critique targets**: it gives the model vocabulary to confidently generate plausible-looking config against an environment that isn't designed to receive it. Hallucination rates × blast radius of a wrong BGP route-reflector config = real outages.

**Disconfirmation B — Community practitioners remain openly skeptical.**
Packet Pushers episode HN785 captures the mood: the engineer who "bought into the hype that AI was going to help him proactively figure out problems" now "doesn't believe that anymore — though it's getting closer." The entire Packet Pushers network-automation podcast line (NAN086, HN743, TNO008) is framed as "reality check" content for a reason.

**Disconfirmation C — The tools that actually work are below Claude's layer.**
Nornir, NAPALM, Netmiko, Junos PyEZ, pan-os-python, PyATS, Batfish (for pre-deploy validation of routing), NetBox (as source of truth), Ansible network collections — this is a mature, opinionated stack. Batfish specifically does **pre-deployment network-behavior simulation** that no LLM prompt can approximate. (Pepelnjak's course material; CNCF / NetworkToCode community docs)

**Steelmanned counter-case**: Zero. A skill for vendor network-config generation is the domain most directly contraindicated by the expert literature. If anything, the `ycc` guidance should _block_ Claude from emitting production device configs without a Batfish / commit-confirmed pipeline.

---

### Claim 4: "Add container/Docker/Podman/image-supply-chain skills"

**Disconfirmation A — Tooling is already excellent and terse.**
Trivy, Grype, Syft, Cosign, Dockle, Hadolint, `docker scout`, `buildx`, Podman's `quadlet` — the container supply-chain ecosystem is **mature, purpose-built, and CI-native**. A `ycc:container-security` skill adds what exactly? A reminder to run `trivy image`?

**Disconfirmation B — The model already knows this layer.**
Foundation models are over-trained on Dockerfiles and Kubernetes YAML. This is the _opposite_ of the Cisco/Junos hallucination problem. Extra prompt-level guidance produces **negative marginal returns** — it just inflates context.

**Steelmanned counter-case**: A skill that focuses narrowly on the _non-obvious_ — e.g., supply-chain attestation with `cosign verify-blob`, or OCI artifact signing workflow — could add value, but it's a single 300-line skill, not a domain.

---

### Claim 5: "Add virtualization skills (VMware, KVM/libvirt, Proxmox)"

**Disconfirmation A — Declining market, narrow audience, vendor upheaval.**
Post-Broadcom VMware pricing disruption has pushed many operators to Proxmox / KVM, and the tooling for each is **fundamentally different**. A single skill cannot coherently cover virsh, ESXi `govc`, Proxmox `pvesh`, and XCP-ng's `xe`. Four skills × 4 targets = 16 artifacts for a domain with a shrinking, fragmented audience.

**Disconfirmation B — The Packer/Terraform provider layer already exists.**
`hashicorp/vsphere`, `terraform-provider-proxmox`, `dmacvicar/libvirt` — these are the layer where automation actually happens. Claude already uses them fluently.

**Steelmanned counter-case**: None defensible at `ycc`'s maintainer capacity.

---

### Claim 6: "Add network security skills (firewalls, IDS/IPS, zero trust, segmentation)"

**Disconfirmation A — Policy is site-specific; prose skills are generic.**
A zero-trust segmentation policy for bank X is nothing like one for SaaS startup Y. A generic skill that says "consider least privilege, consider microsegmentation" is **fortune-cookie-level generic** — the model already produces this content without the skill.

**Disconfirmation B — The high-value artifacts are determinstic validators.**
Palo Alto `panorama` has `validate` commands. Cisco ASA/FTD has `show running-config | include access-list` diff tooling. Tufin, AlgoSec, FireMon do policy-drift detection commercially. A _prompt_ can't replicate this.

---

### Claim 7: "Add AWS / Azure / GCP cloud skills"

**Disconfirmation A — Foundation models are aggressively trained on this domain.**
Of all the proposed domains, this is the one where LLMs already perform best — see the Terrateam 2025 update noting "Claude produced good results" on Terraform/AWS generation. Additional skill prompts have the **lowest marginal value** here. (terrateam.io)

**Disconfirmation B — MCP / CLI layer is saturated.**
Official AWS MCP server, `aws` CLI, `az` CLI, `gcloud`, Pulumi, Terraform, `crossplane`, ArgoCD, Flux — this is the domain where Pepelnjak's Clippy comment lands hardest: every vendor is shipping their own glitter-dust AI layer. The marginal Claude-side skill adds overlap, not value.

**Disconfirmation C — Hallucinations still happen on resource-attribute names.**
TerraShark (Feb 2026) documented that LLMs hallucinate: `count` vs `for_each`, `sensitive` vs `write_only`, missing `moved` blocks, CLI-style `terraform import` vs declarative import blocks. The author's insight is crucial: **"telling an LLM what good Terraform looks like is less effective than telling it how to think about Terraform problems."** A skill that _names specific hallucination patterns_ works; a skill that restates best practices does not.

**Steelmanned counter-case**: A narrow `ycc:terraform-hallucination-checklist` skill modeled on TerraShark's approach — explicitly enumerating LLM-failure patterns per provider — could be defensible. That's _one_ skill with a 7-step diagnostic workflow, not three cloud-provider skills.

---

## Expert Critiques (Credentialed Skeptics)

### Ivan Pepelnjak (ipSpace.net, 30 years network automation)

- "AI is the new SDN" — vendor hype cycle on repeat.
- Nobody wants to hear their baby is ugly, so vendors sell AI that "auto-ingests your mess and puts unicorn dust on it."
- Networks aren't automatable until they're _designed_ to be; tools come second.
- Mediocre-in-both: the industry's push for network engineers to "learn to code" has produced "a wave of engineers with half-baked coding skills who end up mediocre in both networking and coding."
- Source: [Packet Pushers TCG056 — Network Automation Reality Check](https://packetpushers.net/podcasts/the-cloud-gambit/tcg056-network-automation-reality-check-with-ivan-pepelnjak/), [ipSpace.net "Network Automation Considered Harmful"](https://sn.linkedin.com/posts/ivanpepelnjak_network-automation-considered-harmful-ipspacenet-activity-6990565507699482624-pqqg)

### Kelsey Hightower (former Google Distinguished Engineer, Kubernetes)

- Self-described AI skeptic, consciously opting out of the current hype wave.
- "Zero-token architecture" = rebranding `bash` + `curl`. Most AI-ops automation is existing automation with a new label.
- On RAG: "You say RAG, I say cache. Do you not feel dirty using buzz words knowing there's an existing thing that is exactly the same?"
- AI is surface-level; underneath, the programs still run on the same hardware, OS, network protocols.
- Source: [The Register — Hightower on dodging AI](https://www.theregister.com/2025/02/18/kelsey_hightower_on_dodging_ai/), [Hightower at KubeCon 2026](https://thenewstack.io/hightower-ai-open-source-kubecon/)

### Charity Majors (Honeycomb CTO, observability)

- "AI solves this" is theater.
- MCP joins across data silos can be better than nothing but "don't restore the relational seams" — they don't produce the signal engineers actually need.
- Static dashboards are a poor view into software; engineers develop worse mental models, not better, when relying on them.
- The generative-AI complexity surge is making the three-pillars model worse, not better.
- Source: [charity.wtf — Observability 2.0](https://charity.wtf/tag/observability-2-0/), [TechTarget Podcast with Charity Majors](https://www.techtarget.com/searchitoperations/podcast/Charity-Majors-on-AI-observability-and-the-future-of-SRE)

### Addy Osmani / a16z / the MCP backlash community

- MCP servers are "tool calling repackaged" — many are "just clever wrappers around existing APIs."
- Anthropic's own testing: 5-server setup = 55K tokens before conversation; some setups consume **134K tokens (half of Claude's context window) just for tool definitions**.
- CLI tools beat MCP for AI agents because the model already knows `gh`, `kubectl`, `aws` — zero schema tokens.
- "An MCP client can successfully execute a tool call while simultaneously making a terrible engineering decision."
- Source: [addyo.substack.com — MCP: What It Is](https://addyo.substack.com/p/mcp-what-it-is-and-why-it-matters), [a16z — Deep Dive into MCP](https://a16z.com/a-deep-dive-into-mcp-and-the-future-of-ai-tooling/), [jannikreinhard.com — Why CLI Tools Are Beating MCP](https://jannikreinhard.com/2026/02/22/why-cli-tools-are-beating-mcp-for-ai-agents/)

---

## Documented Failures

### 1. AWS Kiro AI Bot — 13-hour Cost Explorer outage (Oct 2025)

AI bot inherited engineer's operator-level permissions without peer review; autonomously deleted and recreated production environment. AWS's remediation: constrained permissions for AI, mandatory peer review, gradual rollouts. **Directly relevant** to any proposal for K8s/cloud agents that could run destructive operations. Implication for `ycc`: the artifact class that helps is _hooks that constrain_, not _agents that act_. [singhajit.com](https://singhajit.com/aws-outage-kiro-ai-bot/)

### 2. AWS US-EAST-1 DNS race condition (Oct 20, 2025)

Two automated systems updated the same DNS entry simultaneously; empty entry cascaded through DynamoDB → EC2 → everything. **Implication**: automation without coordination is the failure mode. Adding more automation artifacts (Claude-side _and_ vendor-side) increases the surface for this class of failure. [Medium / Rekhi](https://medium.com/@Reiki32/aws-ai-outages-explained-when-the-clouds-own-ai-broke-the-cloud-426c0789c470)

### 3. Kubernetes Ingress NGINX — no security patches after March 2026

One of the most widely deployed ingress controllers in the world stopped receiving security patches because the maintainers burned out. If Ingress NGINX can't sustain it, a single-maintainer bundle trying to cover seven new domains × four compat targets will not. [RoamingPigs — Open Source Maintainer Burnout](https://roamingpigs.com/field-manual/open-source-maintainer-burnout/)

### 4. Tidelift 2024 survey

60% of open-source maintainers unpaid. 61% of unpaid maintainers fly solo. **~60% have considered quitting.** Top-two burnout causes: _issue management_ and _documentation maintenance_ — exactly the tax a multi-target multi-domain plugin bundle levies. [Socket.dev — Unpaid Backbone of Open Source](https://socket.dev/blog/the-unpaid-backbone-of-open-source)

### 5. Ansible Galaxy abandoned-collection churn

- `dellemc.os9` deprecated for inactivity (6 months of trivial commits, zero Galaxy releases in a year).
- `wti.remote` flagged as unmaintained in 2025.
- `openvswitch.openvswitch` required community revival.

Vendor-specific network automation content is **the most abandonment-prone category** in the Ansible ecosystem. A Claude-side skill for the same vendors would face the same dynamics at a single-maintainer level. [Ansible forum — wti.remote](https://forum.ansible.com/t/possibly-unmaintained-collection-wti-remote/44705?page=2), [dellemc.os9 unmaintained vote](https://github.com/ansible-community/community-topics/issues/133)

### 6. VS Code extension ecosystem security study

Academic analysis of 52,880 VS Code extensions found **5.6% with suspicious behavior**. Letting extensions have a free pass is "a strategic and marketing decision to promote a robust extension ecosystem" — at the cost of security. [arXiv 2411.07479](https://arxiv.org/html/2411.07479v1)

Applied to `ycc`: expanding the blast radius of skills that _claim_ to help with infrastructure means increasing surface area for the model to do something destructive on the user's behalf, with the user's trust level already inflated by "I installed the skill, it must know what it's doing."

### 7. Claude Code plugin ecosystem critique (composio / buildtolaunch review, 2026)

- "Stop installing every Claude Code plugin."
- "Of 11 plugins tested, 4 worth keeping always, 5 worth enabling in the right session, 2 not worth it" — a **36% keep rate**.
- Context window is the dominant cost signal.
- Plugins "not updated in months may break with Claude Code updates."
- Source: [buildtolaunch.substack.com](https://buildtolaunch.substack.com/p/best-claude-code-plugins-tested-review)

---

## Questionable Assumptions

### Assumption A: "Claude-side skills materially reduce LLM mistakes in infra."

**Counter**: The evidence shows that what works is RAG-over-vendor-docs + emulator validation + commit-check-style deterministic guardrails. A skill prompt does none of these. It provides vocabulary, which can _worsen_ the problem by masking hallucinations behind plausible syntax. The IRAG paper's 97.74% syntax correctness was achieved against a RAG system with vendor-manual retrieval — not against prompt-level best-practices text.

### Assumption B: "One skill generalizes across target platforms."

**Counter**: A single "k8s-day2" skill has to cover EKS (aws-auth, IRSA, Karpenter), GKE (Workload Identity, GKE Autopilot), AKS (AAD integration, Azure CNI), kind/k3s/minikube for local, and on-prem Rancher/OpenShift. The day-2 ops differ materially across each. The generalization tax is real and produces fortune-cookie guidance.

### Assumption C: "Every new skill multiplies through all 4 compat targets cleanly."

**Counter**: The target-capability matrix is real. Cursor doesn't natively consume `.md` commands. Codex doesn't support slash commands. opencode has different MCP semantics. Every addition requires updating 4 generators + 4 validators + potentially 4 target-specific quirks. **Six new domain skills = 24 artifacts, plus tests, plus docs.** The multiplier does not forgive low-priority additions.

### Assumption D: "The user's stated domains are stable categories."

**Counter**: The user described their work as spanning networking/K8s/containers/virt/netsec/cloud/vendor — but the work _at any given month_ is concentrated in 1–2 of these. A bundle sized to the _union of all months_ is a maintenance disaster. The Ansible Collections governance structure exists precisely because coverage-by-domain is unsustainable for a single maintainer.

### Assumption E: "If a domain has failure modes, a Claude artifact can prevent them."

**Counter**: The most dangerous failure modes (wrong kubectl context, ACL misorder, blast-radius-wide apply) are prevented deterministically, not probabilistically. A skill = a prompt = probabilistic. A hook = a script with exit code 1 = deterministic. The problem class is wrong-tool-for-wrong-problem mapping.

---

## Conflicts of Interest

- **The `ycc` owner is the sole consumer and the sole maintainer.** Any research I produce that argues "build more" benefits the owner's day-to-day workflow at the direct cost of the owner's maintenance time. This is a classic personal-productivity-vs-OSS-stewardship conflict. The contrarian's job is to weight the stewardship side, which the owner explicitly flagged in the research objective's bias list (item #3: completionist bias; item #5: maintenance-cost blindness).

- **Vendor sponsorship of the AI-in-infra discourse is pervasive.** Packet Pushers' HN743, HN792, HN822, TNO039 are all _sponsored_ episodes. This means the most-visible pro-AI-for-networking content is vendor-funded, which weights the public discourse optimistically. The unsponsored episodes (NAN086 "Reality Check", HN785 "First Steps") are the ones expressing skepticism.

- **Anthropic and Claude-ecosystem advocates have incentives to encourage rich plugin bundles.** Plugin richness drives platform stickiness. The individual user's context-window budget does not scale with Anthropic's plugin-ecosystem growth incentives.

---

## Unintended Consequences

1. **Skill-inflation creates a false-expertise trap.** A user who has installed `ycc:cisco`, `ycc:fortinet`, `ycc:palo-alto`, `ycc:junos` will be _more likely_ to accept Claude-generated config for production use because the model "has skills for it." The skill is not actually checking syntax against device state. Trust calibration worsens.

2. **Context-window contention actively degrades performance on the user's main work.** `ycc` already ships ~45 skills / ~45 agents / ~40 commands. Adding 20+ domain artifacts pushes auto-loaded tool definitions and discovery metadata into territory where the model has noticeably less room for the user's actual task. MCP users are already reporting 50% of context eaten before the conversation starts.

3. **Cross-target divergence becomes unmanageable.** When (not if) a Cursor-specific validator fails on a Codex-generated skill after adding the 18th domain, the fix is in the generator layer, not the skill. Skill-level contributors can't fix it. The maintainer becomes a bottleneck on their own pull requests.

4. **Plugin-rot signals contaminate discoverability.** When skills go stale (vendor CLI changes, k8s API deprecation, Terraform resource renames), the stale skills teach the model wrong things. The Ansible Galaxy removal process exists _because_ stale domain collections are worse than no collections. A Claude-side equivalent does not yet exist.

5. **A safety-theater risk.** Adding a "k8s-context-guard" _skill_ that reminds the model to check context before `kubectl delete` is marginally worse than adding no skill at all: the user thinks safety exists when it does not. Only a PreToolUse _hook_ provides real safety. Conflating the two is the single most dangerous unintended consequence of "more plugin = more safety" reasoning.

6. **The "four-target multiplier" amplifies every one of the above 4x.** VS Code's problem is ~1 ecosystem. `ycc`'s problem is 4 ecosystems rendered from one source. Every failure mode above is multiplied.

---

## Critical Analysis: Which Proposed Additions Are Actively Harmful?

Ranked by **net harm** (higher = worse to build):

| Proposed Addition                                                                | Harm Score   | Reasoning                                                                                                                                                          |
| -------------------------------------------------------------------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `ycc:cisco`, `ycc:junos`, `ycc:fortinet`, `ycc:palo-alto` — vendor-config skills | **High**     | Directly contraindicated by hallucination research + Pepelnjak critique. Vendor MCP servers + CLIs already exist. Prompt-level guidance inflates false confidence. |
| `ycc:k8s-day2` skill (as pure skill)                                             | **Med-high** | The wrong-context failure mode is deterministic; skill can't fix it. `kubectx`/`kubens`/`k9s` already dominate. Foundation models already fluent.                  |
| `ycc:aws` / `ycc:azure` / `ycc:gcp` skills                                       | **Med-high** | Lowest marginal value; foundation-model coverage is best here. Official MCP + CLI + Terraform layer is saturated.                                                  |
| `ycc:sd-wan` / `ycc:routing` / `ycc:switching` design skills                     | **High**     | Pepelnjak critique lands hardest here. Networks aren't automatable by prose. Real tools (Batfish, NetBox, Nornir) operate below Claude's layer.                    |
| `ycc:virtualization` (VMware/KVM/Proxmox)                                        | **High**     | Fragmented audience, vendor upheaval, Terraform providers already cover it. Low reward, high multiplier cost.                                                      |
| `ycc:network-security` (firewall/IDS/IPS skills)                                 | **Med-high** | Policy is site-specific; prose skills are fortune-cookie generic. Deterministic policy validators (AlgoSec/Tufin) exist.                                           |
| `ycc:container-security` skill                                                   | **Low-med**  | Foundation models excellent here; Trivy/Grype/Cosign are CI-native. Marginal value.                                                                                |

**Additions that could be net-positive IF reframed from skill/agent → hook/script:**

| Reframed addition                 | Form                         | Rationale                                                                                                                       |
| --------------------------------- | ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| K8s wrong-context guard           | **PreToolUse hook**          | Parses `kubectl` command, reads current-context, blocks on prod regex. Deterministic. Actually prevents the documented failure. |
| Device-config blast-radius gate   | **PreToolUse hook + script** | Blocks raw `show/config` on vendor CLIs when no commit-confirm / commit-check flag detected.                                    |
| Terraform hallucination checklist | **Single narrow skill**      | Modeled on TerraShark's "specific LLM mistake patterns per provider." One skill, not three.                                     |
| Cloud-provider-selector           | **Single narrow skill**      | Teaches the model _when to prefer which MCP/CLI_, not the verbs themselves.                                                     |

**The honest summary**: of ~20 naively proposed additions, perhaps **3–4 are defensible**, and all of them are _hooks or narrow diagnostic skills_, not domain-sized skill/agent trees.

---

## Key Insights

1. **The category error.** The proposal conflates "I do this work" with "I need a Claude plugin for this work." The vast majority of the owner's infra work is already covered by mature CLIs and foundation-model training. The genuinely-missing artifacts are **safety gates (hooks)** and **narrow diagnostic checklists for documented LLM failure modes**, not domain-sized skills.

2. **Hooks >> skills for infra.** Every infra domain proposed has deterministic failure modes (wrong context, unscoped apply, unreviewed ACL change, missing commit-confirm). The `ycc` asset class that maps to these is hooks and scripts, not skills or agents. A `ycc:infra-hooks` _package_ — 6–10 hooks covering the documented failure modes — would produce more value than 20 domain skills.

3. **The vendor-MCP race is over for Claude-side prompt bundles.** Palo Alto has official. Cisco/Fortinet/Juniper are coming. A `ycc` skill for the same vendor will be obsolete before it stabilizes. The defensible Claude-side role is _orchestration between vendor MCPs_, not shadow implementation.

4. **The 4× multiplier is the single most underweighted constraint.** No proposal should be evaluated without asking "can the maintainer sustain this × 4 for 3 years?" Applied honestly, this kills most of the list.

5. **Experts agree on what LLMs should NOT do in infra.** Pepelnjak, Hightower, and Majors converge on: fundamentals matter more than automation layers; AI is surface-level; most "AI for ops" is rebranded existing automation; the value is in telemetry/guardrails, not prompts.

6. **The plugin ecosystem is already sending the same signal.** Claude Code plugin reviews (2026) show a 36% keep rate in curated sets. The ecosystem's failure mode is not "not enough plugins" — it's "no quality signal to sort the 64% you shouldn't install."

---

## Evidence Quality

| Source                                                   | Type                                                 | Quality  |
| -------------------------------------------------------- | ---------------------------------------------------- | -------- |
| Mondal et al., arXiv 2307.04945 (GPT-4 router config)    | Primary — peer-reviewed research                     | High     |
| IRAG paper, arXiv 2501.08760 (97.74% syntax correctness) | Primary — peer-reviewed research                     | High     |
| IETF draft on LLM agent network-config benchmark         | Primary — standards draft                            | High     |
| AWS Kiro incident (singhajit.com)                        | Secondary — practitioner write-up of public incident | Med-high |
| Pepelnjak (Packet Pushers TCG056, ipSpace.net)           | Secondary — credentialed practitioner, long record   | High     |
| Hightower (The Register, TheNewStack)                    | Secondary — credentialed practitioner                | High     |
| Majors (charity.wtf, TechTarget)                         | Secondary — credentialed practitioner                | High     |
| Anthropic's own MCP token-budget numbers                 | Primary — vendor self-report, adverse-to-interest    | High     |
| Tidelift 2024 maintainer survey                          | Primary — survey data                                | High     |
| Ansible unmaintained-collection votes (governance)       | Primary — governance records                         | High     |
| VS Code extension study (arXiv 2411.07479)               | Primary — peer-reviewed                              | High     |
| Buildtolaunch / Composio plugin reviews                  | Secondary — practitioner review                      | Medium   |
| TerraShark (Medium)                                      | Secondary — practitioner write-up                    | Medium   |
| a16z MCP deep dive                                       | Secondary — vendor-adjacent analysis                 | Medium   |

Primary sources dominate. The critique is grounded in peer-reviewed research + credentialed practitioner opinion + vendor-adverse self-reporting.

---

## Contradictions & Uncertainties

- **Contradiction 1: Terrateam's 2025 update says "Claude produced good results" on AWS Terraform, while TerraShark (Feb 2026) still documents specific hallucination patterns.** Resolution: both are true. Cloud/Terraform is the best case; vendor network CLIs are the worst case. A uniform "skills for every domain" plan ignores this gradient.

- **Contradiction 2: Pepelnjak wrote the foreword to _Machine Learning for Network and Cloud Engineers_, so he's not anti-ML in networking.** Resolution: his critique is aimed at _vendor-marketed AI hype and poor implementation_, not at the substrate. A rigorously scoped `ycc` artifact (e.g., a hook, a narrow checklist) could pass his bar. A domain-sized skill tree would not.

- **Contradiction 3: Some documented incidents argue for MORE guardrails, which could look like "more plugins."** Resolution: the guardrails that matter are deterministic hooks / constrained permissions / commit-confirmed workflows — not prompt-level skills. The shape of the safety artifact is the crux.

- **Uncertainty 1: Vendor MCP server coverage is changing fast.** Palo Alto official exists; Fortinet/Cisco may ship officials within the 2026 timeframe. A Claude-side vendor skill built today could be obsolete in 6 months.

- **Uncertainty 2: Claude Code plugin ecosystem quality signals are maturing.** Verified Plugins Program, claudemarketplaces.com curation, install-count thresholds. The "no quality signal" problem may partially resolve, which could change the calculus on what a single bundle needs to provide.

- **Uncertainty 3: The `ycc` owner's actual month-to-month domain weighting is unknown.** If 80% of months are networking and 20% K8s, recommendations differ from 30/30/20/20 distribution. Self-reported "spans 7 domains" may over-represent breadth.

---

## Search Queries Executed

1. `LLM hallucination network CLI commands Cisco Junos syntax accuracy`
2. `Ivan Pepelnjak AI network automation skeptic critique`
3. `VS Code extension ecosystem bloat problems maintainer burnout`
4. `Claude Code plugin ecosystem critique limitations`
5. `AI network automation failure production outage incident ACL misconfiguration`
6. `Ansible collection maintainer burnout abandoned Galaxy`
7. `Homebrew formula graveyard abandoned packages maintenance`
8. `MCP server vendor vs wrapper AI tool duplicate functionality critique`
9. `Kelsey Hightower AI operations infrastructure skeptic opinion`
10. `Charity Majors AI ops observability critique limitations`
11. `developer tool scope creep one maintainer burnout solo open source`
12. `LLM Kubernetes kubectl wrong cluster context delete production`
13. `Packet Pushers AI network automation skeptics CLI wrapper`
14. `vendor MCP server Cisco Fortinet Palo Alto official support`
15. `LLM Terraform hallucinate resource AWS provider configuration`
16. `"plugin marketplace" quality problems abandoned extensions discoverability`

---

## Bottom Line: The Steelmanned "Don't Build" Case

A single-maintainer cross-target plugin bundle is **structurally the wrong venue** for prose-format vendor-specific infra knowledge. The artifacts that would actually help are **deterministic hooks and narrow failure-pattern checklists**, not domain skills. The foundation model already covers the low-hallucination domains (cloud, containers); vendor MCPs are shipping for the high-hallucination domains (firewalls); and the credentialed expert consensus across Pepelnjak / Hightower / Majors converges on "fundamentals + telemetry + guardrails" rather than "more prompts."

The `ycc` bundle's highest-leverage infra contribution is therefore:

1. A **`ycc:infra-hooks`** package with 6–10 PreToolUse hooks (prod-context guard, kubectl-delete gate, `terraform apply` blast-radius gate, vendor-CLI commit-check requirement, secrets-in-config scanner, etc.). **This is the build-worthy piece.**
2. A **single narrow `ycc:llm-infra-pitfalls`** skill modeled on TerraShark's approach — explicitly enumerating documented LLM failure modes per domain, not best practices.
3. **Reject** the seven-domain skill/agent expansion as currently framed.

Everything else in the proposal trades maintainer budget for marginal or negative user value, and the multiplier makes the trade worse.
