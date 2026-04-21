# Journalist Findings: Current State of AI-Assisted Network/Infra Work in 2026

**Persona**: Journalist (Asymmetric Research Squad)
**Date**: 2026-04-20
**Scope**: Snapshot of the AI-assisted network, Kubernetes, container, virtualization,
network-security, cloud, and vendor-platform automation landscape as of April 2026,
with dates attached to every material claim.

---

## Executive Summary

As of April 2026, the AI-assisted infrastructure landscape has crossed the "hype →
shipping" threshold. **MCP (Model Context Protocol) is the de facto integration
standard** — Anthropic moved MCP under the Linux Foundation's new **Agentic AI
Foundation (AAIF)** in December 2025, with 97 additional members joining in
February 2026 (including OpenAI, Block, and all hyperscalers). Itential's **"Ultimate
MCP Guide for Network Automation"** (March 2026) catalogs **56 production-ready MCP
servers** spanning device automation, cloud, observability, security, and ITSM.

Every major vendor now has AI tooling in production:

- **Cisco AI Assistant** (GA in Meraki + Catalyst Center, 2025→2026)
- **HPE Juniper Marvis AI** (rebranded from Mist AI post-$14B HPE acquisition closed
  July 2025; agentic upgrades throughout 2026)
- **Fortinet FortiAI** (expanded across entire Security Fabric at Accelerate 2026,
  March 10, 2026; FortiOS 8.0 released same day)
- **Palo Alto Precision AI / NGTS Suite** (launched March 26, 2026; XSIAM Autonomous
  SOC operational)
- **Amazon Q Developer** (AWS Cloud Control API MCP server shipped; re:Invent 2025
  major expansion)
- **Azure Copilot agents** (Ignite 2025; migration agent in public preview)
- **Gemini Cloud Assist** (Application Design Center + AI-Powered Investigations in
  public preview through Q1 2026)

On the open-source / community side, **Nautobot 3.1** shipped commercial AI
(**NautobotGPT**, Data Query Agent, MCP server) on **April 14–15, 2026**. The
**Kubernetes AI Conformance Program** launched at KubeCon NA 2025 (Atlanta,
November) and was tightened at KubeCon EU 2026 (Amsterdam, March 23–26, 2026) with
inference-specific requirements and agentic workload support. **llm-d** joined CNCF
as a Sandbox project in March 2026.

The debate has shifted: **not "should I use AI for network/infra ops"** but
**"how fast, with what governance, and how much do I trust the agent to take write
actions?"**

---

## Current State (by Domain)

### 1. Claude Code / Plugin Ecosystem (April 2026)

- Anthropic launched the **official Claude Code plugin directory** in early 2026.
  Official directory ships **55+ curated plugins**; community marketplaces add
  **72+ more**. claudemarketplaces.com tracks **4,200+ skills across 2,500+
  marketplaces** (April 2026).
- The **MCP Registry** (official) has **2,000+ servers** (March 2026);
  cross-registry tracking shows **5,000+ community MCP servers**. SDKs exist for
  TypeScript, Python, Go, Rust, Java, C#, Kotlin, PHP, Ruby, Swift.
- Infrastructure-focused plugins now in circulation:
  - **HashiCorp Agent Skills** (official): Terraform + Packer Skills shipped;
    HashiCorp signaled expansion to other products "soon" (as of announcement blog
    post).
  - **ahmedasmar/devops-claude-skills** community marketplace (iac-terraform,
    k8s-troubleshooter, aws-cost-optimization).
  - **antonbabenko/terraform-skill** — standalone Terraform/OpenTofu best-practices
    skill (community).
  - **Shipyard** — cross-tool IaC validation (Terraform, Ansible, Docker, K8s,
    CloudFormation) with a dedicated auditor agent.
  - **Context7** — live docs MCP (cross-cutting, used heavily in DevOps).
- Noteworthy critique from the ecosystem (composio.dev/self.md, 2026): the best
  Claude Code users run **2–3 plugins max**, some run zero and instead maintain
  a precise `CLAUDE.md`. "~250 Claude Code skill packages exist on GitHub;
  roughly 30 are worth installing."

### 2. Vendor-Side AI Tooling (Per-Platform State, April 2026)

#### Cisco

- **Cisco AI Assistant** is GA in the **Meraki dashboard** (rollout started
  Americas + EMEA, 2025; controlled availability) and **Catalyst Center**. It
  surfaces relevant Meraki API calls/documentation via natural language; also
  integrates with ThousandEyes. Uses the "Cisco Deep Network Model."
- **Cisco Live EMEA 2026** (Feb 9–13, 2026) had dedicated MCP-server sessions:
  "Network Automation Simplified: Building MCP Servers (CISCOU-2320)," "Agentic
  AI Your Way: Build Your Network Automation MCP Servers (IBODEV-2363),"
  "GenAI Your Way: Reimagine Network Troubleshooting (BRKOPS-3822)."
- **Network MCP Docker Suite** (community / Cisco Switzerland blog): 7 MCP servers
  (Meraki, Catalyst Center, IOS XE, NetBox, ISE, ThousandEyes, Splunk);
  `pamosima/network-mcp-docker-suite` variant includes 10 specialized servers.
- **IOS XE 17.5.5** (dashboard-published, 2026) adds expanded Meraki regional
  cloud support (India, China, Canada) and Uplink Auto-Configuration enhancements.

#### Juniper / HPE Juniper

- HPE closed the **$14B Juniper acquisition in July 2025**. First major joint update
  followed (Marvis AI rebrand + agentic conversational interface).
- **February 16, 2026 Mist updates**: Marvis Minis config enhancements,
  Potential Anomalies dashboard, Marvis Actions categories (Layer 1, Wireless,
  WAN, Wired, Connectivity), switch port loop alerts searchable in Marvis,
  NAC Client Insights, and new API for SSR onboarding
  (`PUT /api/v1/orgs/<org_id>/ssr/export_idtokens`).
- **Apstra integration**: Marvis Conversational Interface now integrates with
  Apstra's graph database via API — supports nearly **300 API queries** for
  natural-language data-center operations.
- **Large Experience Model (LEM)** powers predictive user-experience diagnosis.
- **Junos MCP Server** (official, `Juniper/junos-mcp-server` on GitHub) shipped
  with command guardrails (`block.cmd` regex-based blocker for reboot/power/
  zeroize-class commands) — built explicitly to enable Claude Desktop and
  VS Code (streamable-http) interaction with Junos devices.
- Limitation (explicit in Juniper/HPE messaging, 2026): Marvis self-driving
  features only work on Juniper hardware/systems today; third-party authorization
  roadmap is stated future work.

#### Fortinet

- **Accelerate 2026** (March 10, 2026) major announcement: **FortiSOC** (cloud
  unification of FortiAnalyzer, FortiSIEM, FortiSOAR, FortiTIP) plus **FortiAI
  expanded across SecOps** with **agentic workflows** (beyond the earlier
  "interactive copilot" pattern) and **MCP support** for shared context across
  detection/investigation/response.
- **FortiOS 8.0** (March 10, 2026): "Secure AI controls, fabric-based AI agents,
  flexible SASE, simplified SD-WAN," plus FortiView for AI attack surface / shadow
  AI, and **quantum-safe protection** features.
- FortiAI product family in April 2026:
  - **FortiAI-Assist** (ML + GenAI across Security Fabric for SecOps)
  - **FortiAI-SecureAI** (runtime LLM protection, pre-deploy blocking)
  - **FortiAI-Protect** (contextual risk assessment for third-party GenAI apps)
- **FortiGate 700G** launched with AI + quantum protection.
- Positioning: FortiAI blocks AI attacks in **<1 second**, with inline low-latency
  inspection.

#### Palo Alto Networks

- **Next-Generation Trust Security (NGTS) Suite** launched **March 26, 2026** —
  "transition from human-managed security protocols to fully automated, AI-driven
  architectures." Built on **Precision AI** (1,300+ models analyzing millions of
  telemetry objects daily; ~1.6M new attacks detected/day; ~8.6B attacks blocked/day).
- **XSIAM** now operates as an **Autonomous SOC** (detect/investigate/neutralize
  in milliseconds).
- **Koi acquisition** (April 2026) added agentic endpoint security ("proactive hunt"
  before exploitation).
- Security copilots: **Strata Copilot** (network), **Prisma Cloud Copilot** (cloud),
  **Cortex Copilot** (SOC).
- **Cortex MCP Server** (open beta, 2026) — Palo Alto's official MCP offering for
  Claude Desktop / LLM apps; provides Cortex XDL context, case pulls, and IOC
  details.
- **No official Panorama/PAN-OS MCP server yet** (as of April 2026). Community fills
  the gap:
  - `apius-tech/Palo-MCP` (116 tools, 16 modules, OS-keychain key storage)
  - `vlanviking/panos-mcp-server` (PANOS_READONLY flag, candidate-config + explicit
    commit pattern, strict XPath regex validation)
  - `cdot65/pan-os-mcp` (FastMCP/Python)
  - `edoscars/pan-os-mcp` (XML API)
  - `DynamicEndpoints/paloalto-device-server` (REST API; supports HA upgrades via
    Panorama)

#### AWS (Amazon Q Developer)

- AWS named Leader in 2025 Gartner Magic Quadrant for AI Code Assistants
  (second consecutive year).
- **re:Invent 2025** (early Dec 2025) centered on Amazon Q Developer expansion.
- **AWS Cloud Control API (CCAPI) MCP Server** launched — natural-language CRUD over
  AWS resources across all services.
- Capabilities (April 2026): IaC generation (CloudFormation, CDK, Terraform),
  **Console-to-Code** (records console actions → IaC for EC2/VPC/RDS), ChatOps via
  Slack/Teams, `/review` agent for SAST + secrets + IaC misconfig scanning,
  incident runbook automation, CI/CD pipeline generation (CodePipeline).
- Positioned "killer use case" for 2026: **Legacy modernization** (Java 8 → 21,
  Spring Boot 2 → 3 via Transformation Agent).

#### Azure

- **Ignite 2025** announcement set: **Azure Copilot agents** across VMware → Linux
  → IT Ops migrations; **migration agent in public preview**; App Service Managed
  Instance (preview, no refactoring/containers for .NET apps); Azure SQL MI next-gen
  (GA, 5× faster, 2× storage).
- In 3 months, **160,000 organizations created 400,000+ custom agents** via
  Copilot Studio (MS messaging, Q1 FY2026). Phishing triage agent: **6.5× efficiency
  gains**.
- **Foundry IQ** + **Fabric IQ** for agentic AI wiring; **Azure HorizonDB**
  adds built-in vector indexing.
- **Azure Developer CLI (azd), March 2026**: local run-and-debug loop for AI agents,
  GitHub Copilot–powered project setup, Container App Jobs deployment (7 releases
  that month).
- **GitHub Copilot CLI** positioned as the infrastructure-deployment command-line
  assistant for Cloud/DevOps engineers (Azure blog, March 2026).
- Azure DevOps: Azure Boards supports GitHub Copilot custom agents when creating
  a PR from a work item.
- Pricing: Copilot chat + agentic features currently free; agent pricing TBD.

#### Google Cloud (Gemini Cloud Assist)

- Three public-preview features live as of April 2026:
  1. **Application Design Center** (NL → architecture diagrams + templates;
     exportable to Terraform).
  2. **AI-Powered Investigations** (root cause analysis via telemetry, preview).
  3. **Cost Management & Optimization** (top insights in Cloud Hub + FinOps Hub 2.0).
- **Breaking change (effective April 13, 2026)**: Investigations **no longer
  supported within VPC Service Controls perimeters**. Users must query from outside
  the perimeter or lose access.
- Database integration: AI assistance for fleet management + performance +
  cost-reduction workflows, detecting/diagnosing/recommending for complex
  performance issues.
- **Google Cloud Next '26**: April 22–24, 2026 (Las Vegas) — days away at time of
  writing; agentic AI + Gemini Enterprise expansion billed as core theme.
- Currently free (in preview); some features will incur cost at GA.

### 3. NetDevOps / Network-AI Tools 2026

- **NetworkToCode / Nautobot 3.1** (GA **April 14–15, 2026**):
  - **NautobotAI** suite: **NautobotGPT** (expert assistant), **Data Query Agent**
    (operational data retrieval), **MCP Server** (for Claude and other MCP
    clients), **VS Code Integration**.
  - Flagship commercial apps: **OS Upgrades** + **Operational Compliance**
    (pre-release customers saw **80% reduction in upgrade time**).
  - Three commercial bundles: **Nautobot Professional**, **Enterprise**, **Cloud**;
    **Cloud Secure Proxy** for outbound-only connectivity to Nautobot Cloud.
- **NetBox Labs**: SaaS growth; **NetBox Discovery** + **NetBox Assurance** push
  "intended state vs actual state" as the differentiator (AutoCon 4 booth focus).
  No specific NetBox-core AI release found in search.
- **Containerlab** is now the default container-based network simulator (Dec 2025
  → 2026 commentary). Pairs with Batfish (config correctness analysis), Suzieq
  (observability), Drone (CI). Supports Nokia SR Linux, Arista cEOS, Cisco XRd,
  Juniper cRPD, plus VM-based routers.
- **NetPilot** (2026): "first AI-powered network emulator" — NL → multi-vendor
  Containerlab topology; supports cEOS, cRPD, SR Linux, Palo Alto, Fortinet, FRR,
  Cisco IOL; supports **production-config digital-twin** import for pre-change
  validation. Cites "68% of infrastructure outages caused by configuration errors."
- **AutoCon 4** (Austin, Nov 17–21, 2025): Theme was **agents** — keynote "The
  NetDevOps Journey: Manual Firefighting to Agentic Autonomy" (Greg Freeman).
  Talks: "Building AI with AI" (Senad Palislamovic), "From CLI to GPT"
  (John Capobianco), "Battle of the Bots" lightning (Eric Chou).
- **AutoCon 5** (Munich, 2026) and **AutoCon 6** (USA, November 2026) — NAF-run,
  upcoming.

### 4. Kubernetes Tooling 2026

- **K8sGPT** (CNCF, analyzer-first) now ships a **Model Context Protocol server**
  for AI-assistant integration; requires **v0.4.14+**. Kubernetes operator mode
  runs continuous in-cluster diagnostics. Anonymization option masks sensitive
  data before AI-backend calls.
- **kubectl-ai** (Google Cloud, intent-first, CLI): translates NL → kubectl
  commands; confirm-before-execute pattern; enhanced MCP mode bundles filesystem,
  web, DB tools under one endpoint; includes llama.cpp-based local model serving
  (e.g., Gemma on-cluster).
- **Kubernetes AI Conformance Program** launched at **KubeCon NA 2025** (Atlanta,
  Nov 2025); expanded at **KubeCon EU 2026** (Amsterdam, March 23–26, 2026) with
  inference-specific requirements, agentic workload support, alignment to k8s v1.35.
  Certified platforms **nearly doubled after a 70% surge**.
- **llm-d** (distributed LLM inference, separates prefill/decode) — launched May
  2025 by Red Hat + Google Cloud + IBM Research + CoreWeave + NVIDIA; **joined
  CNCF as Sandbox** at KubeCon EU 2026 (the most consequential KubeCon EU 2026
  announcement).
- Compute trajectory: AI inference jumps from **20.9 GW (2025) → 93.3 GW (2030)**,
  surpassing training as dominant AI-datacenter workload.
- Adoption chasm (called out at KubeCon EU 2026 keynote): **82% of orgs have
  adopted Kubernetes for AI workloads, but only 7% deploy AI daily.**
- Recap commentary (Harness, CNCF): "If KubeCon 2024 was awareness, KubeCon 2025
  was activation."

### 5. Cloud / IaC AI Tools 2026

- **Terraform** (HashiCorp, BSL 1.1 since Aug 2023): 32.8% market share, 4800+
  providers, 26M+ downloads/week — still the market leader.
- **OpenTofu** (Linux Foundation, MPL 2.0): diverging technically — 1.8 shipped
  provider-defined functions + early variable evaluation ahead of Terraform.
- **Pulumi**: 150k+ users, 2000 customers. Pulumi Cloud + **Neo agent** can now
  manage Terraform/OpenTofu state natively (private beta, GA expected **Q1 2026**).
  Pulumi IaC "speaks HCL natively" alongside Python/Go/TS/Java/YAML.
- **Firefly** — agentic multi-IaC control plane across Terraform/Pulumi/OpenTofu/
  CloudFormation/CDK (2026).
- AI drift detection + automatic remediation + policy-as-code generation moved from
  experimental to production-ready across all three; embedded LLM assistants in CLIs.

### 6. Security Tooling (CSPM/CNAPP/Zero-Trust/SIEM)

- **CNAPP mindshare (April 2026)**:
  - **Wiz**: 17.4% (down from 26.2% a year earlier — market diffusing).
  - **Orca Security**: 6.3% (down from 8.1%).
  - **SentinelOne Singularity Cloud Security**: 6.1% (up from 3.0%).
  - **Prisma Cloud** — broadest feature set but confusing credit-based licensing.
- **Wiz**: $50K–$300K+/yr. Security Graph surfaces "toxic combinations"; **AI-SPM**
  (secure AI pipelines) + GenAI remediation added in 2025.
- **Orca**: SideScanning (agentless); Orca Sensor for limited runtime; ~20–30%
  cheaper than Wiz.
- **Prisma Cloud**: $5–$15/workload/yr; broadest CNAPP in the market spanning code
  security, CSPM, CWPP, network security, IAM threat detection.
- **2025–2026 compliance adds**: DORA and NIS2 reporting automation across Wiz,
  Prisma Cloud, Tenable Cloud Security.
- **Microsoft Sentinel** (SIEM):
  - **Copilot Data Connector** (public preview, Feb 2026) — ingests Copilot
    activities; enables detections, workbooks, automation, MCP server hooks.
  - **RSAC 2026 announcements (March 2026)**: **Sentinel Connector Builder Agent**
    (public preview March 31, 2026); **Sentinel Data Federation** (public preview
    April 2026 — KQL over Fabric, ADLS, Databricks); **Sentinel Playbook Generator**
    (NL → Python playbook + flowchart).
  - **Security Copilot Agents** for SecOps (incident summarization, KQL gen,
    Threat Hunting Agent).
  - AI-assisted SIEM migration path **from Splunk and QRadar**.
- **Illumio** (microsegmentation): **Gartner Peer Insights Customers' Choice 2026**.
  **Illumio Virtual Advisor (IVA)** — NL chatbot. AI-powered auto-labeling (cloud
  workloads via traffic, flow logs, metadata). ML policy recommendations for Day-1
  DB workloads. **CISA microsegmentation imperative** (report July 2025) is the
  federal-demand backdrop.
- **Fortinet FortiSOC** enters as a unified-SOC contender with agentic AI at
  Accelerate 2026 (see Fortinet section).

### 7. Key Players & Discourse (April 2026)

- **John Capobianco** — prolific NetDevOps MCP contributor (pyATS, ACI, ISE,
  Markmap, Wikipedia MCP servers); AutoCon 4 "From CLI to GPT" talk.
- **Greg Freeman** — AutoCon 4 closing keynote "The NetDevOps Journey: Manual
  Firefighting to Agentic Autonomy."
- **Eric Chou** — "Battle of the Bots" lightning talk (AutoCon 4).
- **Senad Palislamovic** — "Building AI with AI" (AutoCon 4).
- **Jorge Palma** (Microsoft) — KubeCon EU 2026 "Scaling Platform Ops with AI
  Agents: Troubleshooting to Remediation."
- **Anton Babenko** — AWS Hero; `terraform-skill` for Claude Code (community).
- **Anthropic + OpenAI + Block + hyperscalers** — co-founded **Agentic AI
  Foundation** (AAIF, Dec 2025) under Linux Foundation; 97 additional members
  joined Feb 2026.

### 8. Recent Announcements & Events (Q1–Q2 2026, Chronological)

| Date               | Event/Announcement                                                     |
| ------------------ | ---------------------------------------------------------------------- |
| Dec 2025           | Agentic AI Foundation (AAIF) formed under Linux Foundation             |
| Jan 2026           | Last Month in Nautobot (NTC blog) — pre-release activity for 3.1       |
| Feb 9–13, 2026     | Cisco Live EMEA 2026 (Amsterdam) — dozens of MCP/agent sessions        |
| Feb 16, 2026       | Juniper Mist February updates (Marvis Minis, SSR onboarding API, etc.) |
| Feb 19, 2026       | Juniper Mist MSP Guide published                                       |
| Feb 2026           | Microsoft Sentinel Copilot Data Connector public preview               |
| Feb 2026           | Agentic AI Foundation adds 97 members                                  |
| March 10, 2026     | Fortinet Accelerate 2026 — FortiSOC, FortiAI agentic, FortiOS 8.0      |
| March 23–26, 2026  | KubeCon + CloudNativeCon Europe 2026 (Amsterdam) — llm-d joins CNCF    |
| March 26, 2026     | Palo Alto Networks NGTS Suite launch                                   |
| March 31, 2026     | Sentinel Connector Builder Agent public preview                        |
| March 2026         | Azure Developer CLI (azd) March releases (7)                           |
| April 13, 2026     | Gemini Cloud Assist Investigations dropped from VPC Service Controls   |
| April 14–15, 2026  | Nautobot 3.1 GA + NautobotAI + commercial bundles                      |
| April 2026         | Palo Alto Networks acquires Koi (agentic endpoint security)            |
| April 21–22, 2026  | Fortinet 2026 AI Cybersecurity Summit (Americas/EMEA+APAC)             |
| April 22–24, 2026  | Google Cloud Next '26 (Las Vegas)                                      |
| Nov 2026 (planned) | AutoCon 6 (USA); AutoCon 5 (Munich) earlier in 2026                    |

---

## Key Players (by Domain, one-line roles)

### Vendors

- **Cisco** — AI Assistant (Meraki + Catalyst Center + ThousandEyes); MCP Docker
  Suite reference architecture; Cisco Live EMEA 2026 MCP-heavy agenda.
- **HPE Juniper** — Marvis AI (post-$14B acquisition); Junos MCP Server (official,
  safety-guardrail'd); Apstra graph DB exposed via Marvis.
- **Fortinet** — FortiAI-Assist / SecureAI / Protect; FortiSOC; MCP support in
  SecOps; FortiOS 8.0.
- **Palo Alto Networks** — Precision AI; NGTS Suite; XSIAM Autonomous SOC;
  Cortex MCP Server (official beta); no first-party PAN-OS/Panorama MCP yet.
- **AWS** — Amazon Q Developer; Cloud Control API MCP Server; Console-to-Code.
- **Microsoft Azure** — Azure Copilot agents; migration agent (preview); Copilot
  Studio for custom agents; Security Copilot Agents.
- **Google Cloud** — Gemini Cloud Assist (Application Design Center, Investigations,
  Cost Optimization); Gemini Enterprise.

### Open Source / Community

- **Network to Code** — Nautobot + NautobotAI + NautobotGPT.
- **NetBox Labs** — NetBox Discovery + NetBox Assurance.
- **Containerlab** (upstream) — default container NOS topology tool.
- **Batfish** — config correctness analysis, pairs with Containerlab.
- **K8sGPT** (CNCF, Sandbox) — analyzer-first K8s AI.
- **kubectl-ai** (Google Cloud) — intent-first K8s AI CLI.
- **llm-d** (CNCF Sandbox, March 2026) — distributed LLM inference on K8s.
- **Itential** — commercial enterprise automation + MCP control layer.
- **HashiCorp** — Agent Skills (Terraform, Packer) for Claude Code.

### Key Conferences / Forums

- **KubeCon + CloudNativeCon** (NA 2025 Nov, EU 2026 March, Amsterdam 23–26 March)
- **AutoCon** (NAF; AutoCon 4 Austin Nov 2025; AutoCon 5 Munich 2026; AutoCon 6 USA
  Nov 2026)
- **Cisco Live EMEA 2026** (Feb 9–13)
- **AWS re:Invent 2025**
- **Microsoft Ignite 2025**
- **Google Cloud Next '26** (April 22–24, 2026)
- **Fortinet Accelerate 2026** (March 10, 2026)
- **RSAC 2026** (March 2026)

### Marketplace Aggregators

- **claude.com/plugins** (official Anthropic marketplace)
- **anthropics/claude-plugins-official** GitHub
- **claudemarketplaces.com** (4,200+ skills, 2,500+ marketplaces)
- **aitmpl.com/plugins**

---

## Latest Developments (Q1–Q2 2026)

1. **MCP formalized as industry standard** (Dec 2025 → Feb 2026): Anthropic moves
   MCP to Linux Foundation AAIF; 97 members added in Feb 2026 — every hyperscaler,
   OpenAI, Block, Anthropic, Block all participating.
2. **Nautobot 3.1 commercial launch** (April 14–15, 2026): NautobotAI becomes the
   open-source / commercial bridge for network-automation AI — **80% upgrade-time
   reduction** is the headline stat.
3. **Fortinet FortiSOC + agentic SecOps** (March 10, 2026): moves beyond
   interactive copilots to full agentic workflows with MCP for shared context
   across detection → investigation → response.
4. **Palo Alto NGTS Suite + Koi acquisition** (March 26 / April 2026): Cortex
   XSIAM becomes Autonomous SOC; XSIAM's "no human required" millisecond
   neutralization is the new aspirational bar.
5. **Kubernetes AI Conformance tightened** (March 2026): inference-specific
   requirements + agentic workload support + alignment to v1.35; certified platforms
   nearly doubled.
6. **llm-d joins CNCF Sandbox** (March 2026): signals K8s is becoming the AI
   inference control plane.
7. **Microsoft Sentinel Playbook Generator + Data Federation + Connector Builder
   Agent** (March/April 2026): generative playbook creation from NL; KQL across
   Fabric/ADLS/Databricks without copy-in.
8. **Marvis → Apstra integration** (Feb 2026): data-center NL operations via graph
   DB, ~300 API queries supported.
9. **Gemini Cloud Assist loses VPC Service Controls support** (April 13, 2026):
   rare public-facing "feature removal" that forces customer architecture rework.

---

## Emerging Trends (observed, not forecast)

1. **MCP as the "USB-C for AI"** — this metaphor is now canonical across
   documentation.
2. **Agentic (vs copilot) framing** — every major vendor has flipped messaging from
   "assistant" to "agent" in 2026 announcements (Fortinet, Palo Alto, Microsoft,
   HPE Juniper, Cisco).
3. **Safety guardrails in MCP servers** — `block.cmd` regex patterns (Juniper),
   `PANOS_READONLY` flags, candidate-config + commit gates, OS keychain token
   storage, strict XPath validation. The **write-path** is where everyone is
   deliberately slow.
4. **"VibeOps"** — Itential's term for NL-driven ops, now in common use.
5. **Convergence of IaC tools under AI control planes** — Firefly, Pulumi Neo,
   Crossplane all trying to be the single AI pane across TF/OpenTofu/CFN/CDK.
6. **AI-assisted SIEM migration** — Microsoft explicitly targeting Splunk and
   QRadar customers.
7. **Digital twins for network change validation** — NetPilot, NetBox Assurance,
   Apstra all selling "test before prod."

---

## Contemporary Debates (Preserve Contradictions)

1. **"More plugins" vs "2–3 max"**: Community writers (composio.dev,
   self.md, dev.to) argue ~30/250 skills are worth installing and many power
   users run zero. HashiCorp + community marketplaces push "richer ecosystem =
   better."
2. **Official vendor MCP vs community MCP**: Juniper and Fortinet ship official
   MCP with guardrails; Palo Alto ships official Cortex MCP only (not PAN-OS);
   community fills the gap with 5+ PAN-OS MCPs of varying safety. Debate: is a
   community MCP without vendor safety review acceptable in production?
3. **Closed vendor AI (Marvis, Cisco AI Assistant) vs open agent-in-IDE
   (Claude/Cursor + MCP)**: Marvis only automates on Juniper hardware; Claude
   - Junos MCP automates anything. Which is the right seat for "the agent"?
4. **Agentic speed vs change-control discipline**: Palo Alto pushing
   millisecond autonomous response; Juniper Junos MCP putting explicit reboot
   blocklists in code. Same industry, opposite philosophies.
5. **Inference in Kubernetes**: 82% adoption, 7% daily-deploy — the ecosystem is
   split on whether K8s is ready or whether llm-d / AI Conformance solve the
   right problems.
6. **Proxmox/KVM vs VMware post-Broadcom**: VCF 9.0 ships vDefend (AI-driven
   quarantine); Proxmox community ships MCP servers + n8n + Terraform — both sides
   claim to be "the AI-ready hypervisor," neither has first-party parity.
7. **CNAPP market diffusion**: Wiz mindshare **down from 26.2% → 17.4%** in 12
   months; SentinelOne doubled. Is this Wiz losing, or the market growing? No
   consensus in search sources.

---

## Recent Events (Condensed Timeline)

See "Recent Announcements & Events" table above — reproduced here as a reminder
that **every major vendor ships meaningful AI/agent updates every 4–6 weeks as of
April 2026**. The calendar is saturated.

---

## Market Dynamics

- **Network automation market projection**: **$12.38 billion by 2030** at **18%+
  CAGR** (Itential-cited, 2026).
- **CNAPP pricing spread**: Wiz $50K–$300K+ / Orca $30K–$200K / Prisma Cloud
  $5–$15/workload/yr (credit-based). Pricing clarity is an active differentiator.
- **VMware → Proxmox migration**: $45K+/yr vSphere Foundation vs ~$1,000/yr
  Proxmox for 10-host datacenter. Broadcom-era pricing is the primary migration
  driver.
- **Veeam added Proxmox support in 2024** — the enterprise-readiness watershed.
- **Azure custom agents**: 400,000 built in 3 months (Copilot Studio, Q1 FY2026),
  160,000 orgs participating.

---

## Regulatory Landscape

- **EU DORA (Digital Operational Resilience Act)** and **NIS2** — Wiz, Prisma
  Cloud, Tenable Cloud Security shipped dedicated compliance-reporting automation
  for these in 2025–2026.
- **CISA microsegmentation imperative** — _The Journey to Zero Trust:
  Microsegmentation in Zero Trust — Part One_ (CISA, July 2025) is the federal
  driver Illumio and others cite.
- **Unit 42 Global Incident Response Report 2026**: attackers now exfiltrating in
  **as little as 72 minutes** (down from days/weeks two years ago) — the regulatory
  backdrop for Palo Alto's NGTS push.
- **47-day certificate cycle** — new industry baseline driving machine-identity
  automation sales (NGTS pitch).

---

## Key Insights

1. **MCP is the organizing primitive of 2026.** Every serious infrastructure AI
   story runs through it. A Claude-side plugin/skill for network/infra is
   essentially "how do I wire my workflow around one or more MCPs" — the raw API
   glue problem is solved upstream.
2. **Every major vendor has at least one MCP server (official or first-party
   community).** Cisco, Juniper (official), Fortinet, Palo Alto (Cortex official,
   PAN-OS community), HashiCorp (Terraform), Nautobot, K8sGPT, kubectl-ai,
   Itential — this is not a gap to fill with new MCPs; it's a gap to fill with
   **Claude-side orchestration, safety, and context**.
3. **The write-path is the safety frontier.** Juniper's `block.cmd` regex,
   vlanviking's `PANOS_READONLY`, candidate-config + explicit commit gates — these
   are the patterns. A ycc-side "network change review" skill/hook could lean
   into this precedent.
4. **Vendor AI is siloed.** Marvis only drives Juniper; Cisco AI Assistant only
   drives Cisco. The multi-vendor brownfield world (which is almost every real
   enterprise) is exactly where **Claude + MCP glue outcompetes closed vendor AI**.
5. **Tool fatigue is real.** Community consensus ("30 of 250 skills are worth
   installing") suggests the ycc bundle's "lean, lower-maintenance" posture is
   validated — not fighting against the market.
6. **Agentic AI is the brand new default.** "Copilot" was 2024; "agent" is 2026.
   Any ycc addition framed as passive guidance will feel dated relative to vendor
   messaging.
7. **Digital twins before prod deploy** (NetPilot, NetBox Assurance, Batfish +
   Containerlab) is an emerging workflow pattern worth examining for a "network
   change validation" artifact.

---

## Evidence Quality

### Primary Sources (vendor docs + authoritative)

- Cisco documentation (Meraki AI Assistant docs, Cisco Blogs April 2026)
- Juniper Networks documentation (Mist Feb 16 2026 updates; Marvis API reference;
  Junos MCP Server GitHub README)
- Fortinet press releases (Accelerate 2026 announcements, FortiOS 8.0 release)
- Palo Alto Networks blog + press (Precision AI, NGTS Suite, Cortex MCP Server)
- AWS documentation (Amazon Q Developer docs, AWS DevOps Blog)
- Microsoft Azure Blog + Microsoft Learn (Ignite 2025, Copilot Data Connector,
  Sentinel release notes)
- Google Cloud docs (Gemini Cloud Assist overview, release notes)
- Nautobot release pages + Network to Code blog + press release (April 14–15, 2026)
- CNCF blog posts (KubeCon announcements)
- K8sGPT GitHub + k8sgpt.ai docs
- kubectl-ai GitHub (GoogleCloudPlatform)
- Itential MCP Guide (March 2026, comprehensive catalog)
- Linux Foundation / AAIF announcements
- HashiCorp blog (Agent Skills)
- Juniper/GitHub community MCP repos (Junos, PAN-OS variants)

### Secondary Sources (practitioner / analysis)

- Packet Pushers (HPE Marvis coverage)
- NetworkComputing (Juniper Marvis)
- Harness blog (KubeCon NA 2025 recap)
- Sokube (KubeCon London 2025)
- RobustCloud (KubeCon EU 2026)
- Ryburn.org + CodiLime + Roger Perkin blogs (AutoCon 4 coverage)
- SiliconANGLE (Juniper May 2025)
- ChannelInsider (HPE Juniper Mist AI autonomous IT ops)
- Cloud Wars (Palo Alto Precision AI)
- composio.dev, dev.to, self.md (Claude Code plugin reviews)
- FinancialContent (PANW NGTS coverage)

### Synthetic / Aggregator

- AccuKnox CNAPP rankings 2026
- PeerSpot vendor comparisons
- Wiz pricing estimate aggregators
- Gartner Peer Insights (Illumio 2026 Customers' Choice)

### Speculative / Opinion

- Tech-insider.org Microsoft 2026 spending
- Windows News / monovm.com Proxmox vs VMware takes
- ServerSpan "Beyond Proxmox" speculation
- CloudDon "Is Kubernetes the AI OS?"

**All synthetic and speculative sources are flagged above and used only for
context, not for load-bearing claims.**

---

## Contradictions & Uncertainties

1. **Wiz mindshare loss** (26.2% → 17.4%): sources disagree on whether this is
   market diffusion vs a competitive loss; no single authoritative read.
2. **Wiz $50K–$300K+ range** is widely cited but is a third-party estimate;
   Wiz does not publish pricing.
3. **Nautobot 3.1 "80% upgrade-time reduction"** is a Network to Code press-release
   number from pre-release customer deployments — limited external verification.
4. **Community Claude Code skill counts** ("250+ on GitHub, ~30 worth installing")
   come from self.md/composio commentary — impressionistic, not systematic.
5. **Palo Alto's "millisecond autonomous response"** and **Illumio's "in days, not
   months"** segmentation claims are marketing; practitioners report slower real
   deployments but exact figures vary.
6. **Cisco AI Assistant in Meraki**: explicitly "controlled availability" and
   rolling out — not every customer has it as of April 2026. Geographic rollout is
   explicit (Americas + EMEA started).
7. **Post-Broadcom VMware vs Proxmox migration share** is heavily vendor-side
   rhetoric; independent migration numbers are limited.
8. **Google Cloud Next '26** (April 22–24, 2026) — at the time of writing, two
   days away. Additional Gemini Cloud Assist / Gemini Enterprise announcements are
   expected but unconfirmed.

---

## Search Queries Executed

1. `Claude Code plugin marketplace 2026 network automation MCP`
2. `MCP server network automation Cisco Juniper 2026`
3. `Cisco AI Assistant IOS XE Meraki 2026 API`
4. `Juniper Mist Marvis API 2026 update`
5. `Fortinet FortiAI FortiGuard 2026 release generative AI`
6. `Palo Alto Precision AI 2026 security automation`
7. `kubectl-ai k8sgpt Kubernetes AI 2026 state`
8. `AWS Amazon Q Developer DevOps 2026 infrastructure`
9. `Azure Copilot for Azure infrastructure 2026 update`
10. `Google Cloud Gemini Cloud Assist 2026 features`
11. `Terraform Pulumi AI 2026 OpenTofu generative infrastructure`
12. `NetworkToCode Nautobot NetBox 2026 AI integration release`
13. `KubeCon 2025 2026 AI ops themes announcements`
14. `AutoCon NetDevOps conference 2025 2026 AI network automation`
15. `Containerlab cEOS Batfish 2026 AI network simulation`
16. `Wiz Orca Prisma Cloud CNAPP 2026 AI CSPM`
17. `Itential 56 MCP servers network automation 2026 guide`
18. `Proxmox VMware KVM AI automation 2026 generative`
19. `Microsoft Sentinel SIEM AI copilot 2026 Panther`
20. `"Palo Alto" MCP server Panorama PAN-OS 2026 Claude`
21. `Illumio zero trust segmentation AI 2026 policy automation`
22. `"claude code" plugins DevOps Kubernetes Terraform community 2026`

---

## Implications for ycc Bundle (Journalism Lens — not recommendations)

Journalism hands over the landscape; recommendations are other personas' work.
However, the journalist notes:

- **Duplicating vendor MCP servers is net-negative.** Cisco, Juniper, Fortinet,
  Palo Alto (Cortex), HashiCorp all ship MCP. A ycc "cisco-ios-mcp" is not the
  missing piece.
- **What's genuinely missing from the market**: cross-vendor **workflow skills** —
  "change-review + diff + blast-radius + rollback-plan" patterns that wrap
  existing MCPs with Claude-native reasoning. No vendor ships this. Community
  doesn't either.
- **Write-path safety patterns** (block.cmd, candidate+commit, read-only flags)
  are visible in code but not in a consolidated skill/agent anywhere. A
  "network-change-safety" skill with these patterns would sit in a genuinely
  empty space.
- **The "2–3 plugins max" consensus validates ycc's "lean, high-value"
  philosophy.** The risk isn't "ycc too small"; it's "ycc too big to maintain
  across 4 target bundles."
- **Nautobot / NetBox is the open-source source-of-truth layer.** Any ycc
  network-adjacent artifact should _integrate with_ a source-of-truth rather than
  **be** one.

---

_End of journalist findings._
