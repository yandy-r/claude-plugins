# Negative Space Explorer — Findings

**Persona**: Negative Space Explorer
**Subject**: Silences in AI-assistant ecosystems (Claude Code, Cursor, Copilot) around network engineering, K8s day-2 ops, vendor firewall, and virtualization workflows — and what that silence implies for the `ycc` plugin bundle.
**Date**: 2026-04-20
**Method**: 12 web searches + direct inventory audit of `ycc/skills/`, `ycc/agents/`, `ycc/commands/`, and `ycc/skills/_shared/`.

---

## Executive Summary

The AI-assistant plugin ecosystem in 2026 is conspicuously skewed toward application-development workflows. Across Claude Code, Cursor, and Copilot marketplaces, the overwhelming majority of plugins target SWE-bench-shaped tasks: language patterns, PR workflows, frontend generation, planning, testing. Network engineering, firewall policy management, hypervisor lifecycle, K8s day-2 ops, and vendor-device automation are addressed by a small handful of plugins (notably `phaezer/claude-mkt`, `kubestellar/claude-plugins`, `Sagart-cactus/claude-k8s-plugin`, Proxmox MCP servers), but not yet by the owner's `ycc` bundle.

The silences are not random. They track five structural forces:

1. **LLM confabulation risk on vendor CLI syntax is real and measurable** (research-documented 85% accuracy ceiling without retrieval-augmented mitigation). Vendors (Cisco Deep Network Model) are building purpose-built domain LLMs precisely because general-purpose ones aren't trusted here.
2. **Legal/audit liability for AI-authored configs** is unresolved. Every regulated network (SOX, PCI, HIPAA, FedRAMP) wants immutable provenance + reasoning captured for every rule change — Claude plugins have no primitive for this today.
3. **Air-gapped / OT / SCADA environments actively reject** cloud-hosted assistants. Tabnine has built a business around this; every other mainstream assistant (Copilot, Cursor, Codeium, Claude Code in SaaS mode) is disqualified by default.
4. **Junior network engineers — the population that would benefit most — are the one least being designed for.** Senior engineers absorb AI output as a productivity multiplier; juniors lose the error-recognition muscle that comes from making mistakes. The AI-ops tooling ecosystem targets seniors exclusively.
5. **Maintenance-cost asymmetry** means single-maintainer bundles (`ycc`) cannot match vendor-native tooling on coverage. The opportunity is in workflow orchestration, safety rails, and cross-tool glue — not in cloning `kubectl` or PAN-OS XML APIs.

The punch list at the end enumerates 12+ concrete `ycc` artifact proposals grounded in documented workflow absences. The two highest-leverage observations:

- `ycc` has **zero blast-radius / change-window / context-guard** primitives despite the bundle being heavily invoked for git/infra work. Every Claude Code safety plugin I found (`safety-net`, `nah`, `Sagart-cactus` kind-guard) exists because soft rules in `CLAUDE.md` cannot replace `PreToolUse` hard stops. `ycc` ships no equivalent.
- `ycc` has **zero hooks directory at all**. `hooks-workflow` is a skill that talks _about_ hooks, but the bundle itself publishes no installable hooks. This is the clearest complementary absence in the inventory.

---

## Undiscussed Topics

Ranked by "how loud is this silence when you search AI-assistant discourse."

1. **LLM confabulation on vendor CLI syntax as a first-class failure mode in plugin marketplaces.** Research papers document it (GPT-4o 85% on complex Cisco/Arista; Claude Sonnet-3.5 hallucinates interface names). Plugin marketplaces do not surface it. No Claude Code plugin README I found warns: _"this skill will hallucinate Junos `set` statements — verify against a lab device."_ The silence is the marketing, not the evidence.
2. **Provenance/reasoning capture for AI-generated configs.** AWS CloudTrail + Ansible execution logs capture _what happened_ in deterministic pipelines. Nothing in the Claude Code plugin ecosystem captures _why the model chose a particular ACL line, what prompt produced it, what model version, what source snippets influenced the answer_. This is a gating requirement for SOX/HIPAA/PCI/FedRAMP evidence bundling — and absent from every plugin I examined.
3. **Change-window awareness.** Every CAB process in the industry lives on "is this a standard change, normal change, or emergency change, and what's the freeze window?" Claude plugins do not model change windows. Running `/bundle-release` at 4:47pm Friday is indistinguishable from running it at 10am Tuesday to the plugin.
4. **Per-tenant isolation for MSP workflows.** Multi-tenant MSPs (HyprEdge, Xurrent, ManageEngine MSP Central) have solved this in ITSM — every action is scoped to a tenant fence. Claude plugins operate with no concept of "this command is running in tenant-A's context, deny if it would leak tenant-B state." For an MSP netops person, this is a hard blocker.
5. **Air-gapped / offline-first skill execution.** Tabnine sells into this market because Copilot/Cursor/Codex/Claude Code all assume cloud inference. A skill that invokes `WebFetch` or `WebSearch` silently disqualifies the bundle from defense/aerospace/utilities work. No `ycc` skill has a declared "air-gap-safe: true" flag.
6. **Blast-radius classification per command.** Anthropic's own `auto-mode` engineering post flags this: _"the classifier finds approval-shaped evidence and stops short of checking whether it's consent for the blast radius of the action."_ `ycc` has 40 commands and zero blast-radius labels. `/ycc:clean` and `/ycc:bundle-release` and `/ycc:prp-commit` are not tagged P0/P1/P2 or scoped to cwd/repo/remote/global.
7. **OT / SCADA programming languages.** Ladder logic, structured text, Assembly, SPARK/Ada. Plugin marketplaces overwhelmingly target JS/TS/Python/Go/Rust. The owner's stated domain includes industrial-adjacent work (vendor firewalls in OT-touching environments), and no plugin addresses it.
8. **Carrier-grade BGP policy / MPLS / Segment Routing.** Research tooling exists (Batfish, Crosswork), but an AI-plugin-layer "lint this BGP policy for community-tag leak" does not. Vendors ship their own SDKs; plugin marketplaces are silent.
9. **Inventory reconciliation as a first-class workflow.** NetBox Copilot (launched 2026-02) is the first mainstream attempt. Claude Code plugins assume "the codebase is the source of truth" — for network engineers, _the device is_ the source of truth and the code is a derivation. No `ycc` skill inverts this assumption.
10. **Cable plan → config generation.** The "physical layer to logical config" workflow is entirely absent from AI-assistant discourse. It is a core network-engineer activity (site survey → patch panel → interface config). No plugin touches it.
11. **Firewall policy de-duplication.** Cisco's migration tool does it for ASA→FTD; AlgoSec and Titania productize it. No Claude plugin wraps or orchestrates these — and no skill reasons about "these 47 rules can be collapsed to 3 object-groups."
12. **ACL-to-Zero-Trust migration planning.** This is the multi-year transformation project every enterprise is running. The plugin ecosystem is silent; all the work is being done by Zscaler / Cato / Fortinet sales engineers.

---

## Adoption Barriers

### Technical

- **Cloud-inference assumption.** Claude Code's default mode routes prompts to Anthropic. Air-gapped defense/utility/finance deployments cannot use this. Tabnine owns the mindshare for "AI that ships inside a SCIF." Until a plugin declares explicit offline-mode support, 10-20% of the owner's target audience is walled off.
- **No secret-handling primitive in skills.** The `ycc` bundle has no analog to Ansible's credential-plugin interface (HashiCorp Vault, CyberArk, Thycotic). Any skill that needs device credentials must rely on ad-hoc env vars, which violates rotation / lease / audit-trail assumptions.
- **No device-inventory integration.** NetBox is the industry source of truth; NetBox Copilot just launched (2026-02). `ycc` has no skill that queries NetBox, ServiceNow CMDB, or Infoblox for "what interfaces does device X actually have?" before suggesting an ACL.
- **No policy-as-code native format.** Open Policy Agent / Rego is the de facto "policy lint" language; Batfish has its own. `ycc` commits to no policy language, so policy-bearing skills have nowhere to hand off.
- **No rollback primitive.** `ycc` has `/ycc:git-cleanup` and `git-workflow` but no "generate rollback plan before applying change" skill. Every mature NCM (rConfig, ManageEngine NCM, GitOps with Flux) treats rollback as a first-class artifact.

### Legal / Regulatory

- **Provenance + reasoning capture absent.** SOX 7-year retention, HIPAA 6-year, PCI 3-year. A prompt and its response need to be archivable with model version, tool-call trace, and justification. `ycc` has no hook that writes an immutable audit log on config-affecting commands.
- **License-provenance for generated code is unclear.** Tabnine blog flags this as a gating requirement for defense. `ycc` skills do not declare training-data provenance, which is a concern even if the concern is mostly theatre.
- **Vendor-contract prohibition.** Some Cisco Smart Net / Fortinet / Juniper support contracts include clauses on third-party AI training using customer configs. Plugin authors who silently ship `WebFetch` against a device config may be violating a contract they never saw.

### Cultural

- **"AI babysitter" framing.** Cisco's own blog (Sep 2024, still cited in 2026) articulates the engineer concern: humans at the end of the loop become ticket-processors rather than engineers. Any `ycc` skill that places the human _after_ AI output will trigger this.
- **Junior pipeline erosion.** The industry trend (54% of engineering leaders hiring fewer juniors) means the experience pool that catches model errors is shrinking. `ycc` has no skill that is _designed_ to coach a junior rather than just produce output.
- **Trust deficit from billing incidents.** Cursor's June 2025 credit overage and generic agent-billing surprises have created adoption friction. `ycc` piggybacks on Claude Code's billing, so there's nothing to fix, but it is a reason why extensions into high-compute workflows (long-running network scans, multi-device rollouts) face resistance.

### Economic

- **Every new `ycc` artifact multiplies across 4 compat targets.** The cost of adding one skill is not 1x; it's roughly 4x (claude/cursor/codex/opencode) plus validator + generator + CI time. A low-value skill is net-negative under maintenance pressure.
- **Vendor SDKs are free; Claude inference is not.** Ansible modules for Cisco NX-OS, Juniper PyEZ, and PAN-OS are zero-marginal-cost for the customer. A Claude plugin that wraps them adds latency + cost + new failure modes (hallucination, context limits).
- **MSP economics reward scale; a Claude plugin that cannot scope to tenant breaks the MSP model.** No MSP will run `ycc` against 80 customers if the bundle cannot prove per-tenant isolation.

---

## Missing Features (in `ycc` specifically)

Grounded against the actual inventory.

| Missing                                                                | Evidence                                                                                                                           | Why it matters                                                                                                                            |
| ---------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Installable hooks directory (`ycc/hooks/` or per-skill hook manifests) | `ycc/skills/hooks-workflow` exists, but the repo ships zero actual hook JSON/configs                                               | Every safety plugin I found (`safety-net`, `nah`, `Sagart-cactus`) relies on PreToolUse hooks. `ycc` has the skill but not the artifacts. |
| Blast-radius / change-scope labels on commands                         | All 40 commands inspected — none declare `scope:` or `blast-radius:`                                                               | Anthropic auto-mode explicitly flags this as the failure mode.                                                                            |
| Device-inventory / CMDB integration skill                              | No skill under `ycc/skills/` mentions NetBox, ServiceNow CMDB, Infoblox, Nautobot, or `nornir`                                     | NetBox Copilot shipped 2026-02; `ycc` is on the wrong side of that line.                                                                  |
| Change-window / freeze-window awareness                                | Nothing in `git-workflow`, `bundle-release`, or `releaser` checks for freeze windows                                               | CAB processes require it; freeze-window violations are a common production-outage cause.                                                  |
| Secrets-handling pattern / Vault integration                           | No skill mentions `vault`, `1password`, `akeyless`, `doppler`                                                                      | Ansible has had this since 2015; `ycc` has no opinion.                                                                                    |
| Dry-run / diff-preview-first workflow                                  | `/ycc:clean` has a dry-run mode; `/ycc:bundle-release` has preflight; but there is no _generalized_ "preview before act" primitive | Network-change workflows live on this pattern.                                                                                            |
| Air-gap-safe declaration                                               | No skill declares `requires-network: false` or equivalent                                                                          | Tabnine's entire value prop.                                                                                                              |
| Rollback-plan generation                                               | No skill produces a "how to undo this change" artifact                                                                             | Every NCM has it; `ycc` doesn't.                                                                                                          |
| Per-tenant / per-context scoping                                       | No skill accepts a `--tenant` or `--context` arg that hard-fences state                                                            | MSPs cannot use `ycc` without this.                                                                                                       |
| Validation sandbox / emulator hook                                     | No skill invokes `Batfish`, `Containerlab`, `GNS3`, `EVE-NG`, or `vrnetlab`                                                        | Research shows emulator + LLM = >97% accuracy; LLM alone = 85%.                                                                           |
| Provenance / audit-log emission                                        | No skill writes a structured audit record to disk                                                                                  | SOX/HIPAA/PCI evidence bundling requires it.                                                                                              |
| Compliance-evidence bundling skill                                     | No skill exists to produce an "evidence pack" for a change                                                                         | This is what GRC teams actually need from engineers.                                                                                      |

---

## Knowledge Gaps

What I could not determine from available evidence:

- **Actual adoption rates** of Claude Code plugins in network/infra teams vs. dev teams. claudemarketplaces.com lists plugins but not usage telemetry.
- **Whether `phaezer/claude-mkt` is actively maintained.** It is the closest "infra-first" Claude marketplace, but I did not verify commit recency.
- **Whether any enterprise Claude customer has shipped an air-gapped Claude Code deployment.** Anthropic's own deployment docs talk about Bedrock / Vertex but not about pure on-prem inference.
- **How often `ycc` is actually used by the owner for network work.** The inventory is dev-heavy because the bundle has evolved that way; the owner's stated domains may or may not be current daily drivers.
- **What fraction of network engineers are allowed by their employer to send configs to a third-party LLM.** Anecdotal evidence says "very few in regulated industries" but no survey confirms it.

---

## Friction Points

The specific places where a user of `ycc` _today_ would hit a wall if they tried to use it for network/K8s/virt work:

1. **Running `/ycc:prp-commit` while pointed at a production switch config.** No check warns that this is a device-config commit and the PR template does not match.
2. **Using `code-review` on a Cisco-config diff.** The skill assumes a software-diff; ACL changes have a completely different review dimension (shadowed rules, overlapping ranges, blast-radius per interface).
3. **Invoking `/ycc:orchestrate` for a multi-device rollout.** The skill fans out parallel agents without any staggered-rollout / canary-ring concept.
4. **Using `/ycc:plan` for a change-window-constrained task.** Nothing models the window.
5. **Running `ycc:deep-research` on a vendor-specific CLI question.** It will hallucinate plausible-looking syntax; the skill has no "verify against a lab device" step.
6. **Running any skill inside a kind/k3d/minikube context while the user meant staging.** Nothing reads `kubectl config current-context` and gates commands.
7. **Running any skill in a corporate-VPN-only air-gapped shell.** `WebFetch`/`WebSearch` failures will cascade into misleading output because skills do not degrade gracefully.

---

## Silent Stakeholders

Whose workflow is not modeled anywhere in the `ycc` bundle:

- **Junior network engineers.** The inventory assumes competence; no skill is explicitly coaching-shaped with "here's why I suggested this, here are the 3 alternatives I rejected."
- **Solo / small-team ops engineers.** They do what 20 specialists would do at a FAANG; they need one-shot workflows that combine diff + lint + blast-radius + rollback + evidence-bundle. `ycc` has components but no composed workflow.
- **MSP operators.** Per-tenant scoping is absent.
- **Compliance auditors.** They want evidence bundles, not code output.
- **On-call engineers.** `ycc` has no incident-response or runbook-execution primitive. Datadog Bits, incident.io, Relvy AI, ilert all compete for this space; `ycc` is silent.
- **Change approvers (CAB).** The CAB member needs a summary artifact; `ycc` produces plans and PRs, not CAB-ready change records.
- **Security reviewers (firewall policy).** They need de-duplication reports, shadow-rule detection, policy-drift evidence; `ycc` has none.
- **Network engineering students / lab users.** The "study-for-CCIE-in-a-lab" user is invisible; no skill ties `ycc` to GNS3 / EVE-NG / Containerlab.

---

## Conspicuous Absences (Mapped to `ycc` Inventory)

The actual `ycc` inventory sorted against the owner's stated domain list:

### Skills (`ycc/skills/`)

Present: language patterns (go/rust/python/ts), testing patterns (same), frontend (design/patterns/slides), git (workflow/cleanup), planning (plan, plan-workflow, parallel-plan, shared-context), PRP pipeline (prp-\*), research (deep-research, feature-research, research-to-issues), formatters, init, code-review, implement-plan, review-fix, hooks-workflow (meta), bundle-author, bundle-release, compatibility-audit, releaser, save-session, resume-session, karpathy-guidelines.

Absent against stated domains:

- **Network design / arch**: no skill. Closest is `reverse-proxy-architect` agent, which is L7 load-balancer, not L2/L3 design.
- **Device-level config**: no skill. No `cisco-nxos`, `juniper-junos`, `arista-eos`, `fortigate-cli`, `panos-cli`, `sros`.
- **Kubernetes day-2 ops**: no skill. No `k8s-debug`, `k8s-rbac-audit`, `k8s-context-guard`, `k8s-drain`, `k8s-upgrade`, `kubeseal`, `cert-manager`.
- **Containers / image supply chain**: no skill. No `sbom`, `cosign`, `trivy`, `grype`, `distroless-migration`.
- **Virtualization**: no skill. No `proxmox`, `kvm-libvirt`, `vmware-vcenter`, `openstack`.
- **Network security**: no skill. No `acl-review`, `firewall-policy-audit`, `ztna-migration`, `microseg-plan`.
- **Cloud infra** beyond Cloudflare: no skill. No AWS-native, Azure-native, GCP-native (terraform-architect is agent-only and generic).
- **Vendor platforms**: no skill covering Cisco/Fortinet/Juniper/Palo Alto as a first-class actor.

### Agents (`ycc/agents/`)

Present: `ansible-automation-expert`, `terraform-architect`, `terraform-developer`, `cloudflare-architect`, `cloudflare-developer`, `reverse-proxy-architect`, `systems-engineering-expert`, plus many language/architect/researcher roles.

Absent:

- **No network-engineering agent.** `systems-engineering-expert` is the closest but reads as generic "distributed systems" not "BGP + OSPF + ACL."
- **No K8s-ops agent.** Despite the owner listing K8s as a primary domain.
- **No hypervisor / virt agent.**
- **No firewall / netsec agent.**
- **No MSP / multi-tenant agent.**
- **No CAB / change-management agent.**
- **No compliance-evidence / audit agent.**

### Commands (`ycc/commands/`)

Present: planning/PRP/git/research commands. Mostly software-engineering shaped.

Absent:

- **No `/ycc:netchange` or `/ycc:change-review` command** — despite this being the canonical network workflow.
- **No `/ycc:ctx-guard` or `/ycc:cluster-check`** — despite `kubectl` context errors being a top production-outage cause.
- **No `/ycc:evidence` or `/ycc:cab-pack`** — despite regulated environments requiring it.
- **No `/ycc:rollback-plan`** — despite every NCM shipping one.
- **No `/ycc:device-diff`** — despite config-drift being the #1 reason NCMs exist.
- **No `/ycc:policy-dedup`** — despite this being a multi-billion-dollar product category (AlgoSec, Titania).

### Hooks

**Absent entirely.** The repo has a `hooks-workflow` skill that talks about generating hook configs, but ships no `hooks/` directory and no installable hook manifests. This is the single clearest complementary absence.

### Scripts (shared helpers)

Present under `ycc/skills/_shared/scripts/`: worktree helpers, drift reporters, plan-resolvers, path validators.

Absent:

- No **device-reachability** helper (`ping`/`ssh-check`/`netmiko` probe).
- No **cluster-context** helper (`kubectl config current-context` + kubeconfig fingerprint).
- No **change-window-check** helper.
- No **inventory-lookup** helper (NetBox / ServiceNow).
- No **secret-retrieval** helper (Vault / 1Password / Akeyless).
- No **audit-log-emit** helper (append a structured record for provenance).
- No **blast-radius-compute** helper.

---

## Avoided Topics (+ Likely Reason)

These are topics the AI-plugin discourse has _specifically_ avoided, not just under-covered:

| Topic                                                                                           | Likely reason for avoidance                                                                                                   |
| ----------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| "Our model hallucinates vendor CLI syntax and here's the benchmark"                             | Commercial — vendors selling AI-ops tools cannot lead with accuracy problems. Research papers discuss it; marketing does not. |
| "Regulatory liability for AI-authored network configs"                                          | Legal — plugin authors ship ToS that push liability onto the user. Saying the quiet part loud invites scrutiny.               |
| "Customers' support contracts forbid training on their configs"                                 | Contractual — opening this door forces a reveal of what gets sent where.                                                      |
| "Air-gapped deployment is not supported; buy Tabnine"                                           | Revenue cannibalization — Anthropic/Cursor/GitHub won't recommend competitors.                                                |
| "Juniors lose the error-recognition muscle if they outsource the whole loop"                    | Career-counseling, not a tool-vendor's problem                                                                                |
| "Our plugin doesn't work for MSPs because it can't isolate tenants"                             | Prioritization — MSP market is smaller than dev market.                                                                       |
| "We recommend a human CAB for every AI-generated rule"                                          | Speed — CAB review breaks the "AI productivity 10x" marketing claim.                                                          |
| "The tool does not capture provenance because that's expensive in context"                      | Cost — capturing every chain-of-thought bloats logs.                                                                          |
| "Cisco Deep Network Model exists because general-purpose LLMs aren't good enough at this"       | Positioning — admitting the gap invites customers to wait for the vendor-specific model.                                      |
| "Running `rm -rf` inside an AI loop took out someone's git history" (CVE-disclosed in Feb 2026) | Defensive — vendors minimize, don't amplify, security incidents unless forced                                                 |

---

## Complementary Absences

Paired items where one exists but its natural partner does not:

1. **`hooks-workflow` skill exists → no `hooks/` directory ships.** The skill documents a workflow with no artifacts to install.
2. **`code-review` skill exists → no `code-review` hook** that auto-runs on write. Review is a command, not a guardrail.
3. **`git-workflow` skill exists → no pre-commit guard** that blocks `.env` or device-credentials commits.
4. **`compatibility-audit` skill exists → no auto-run on PR** (there's a CI check but no Claude-side hook).
5. **`releaser` / `bundle-release` skill exists → no rollback-plan artifact** is produced alongside the release notes.
6. **`formatters` skill exists → no "format on stop"** hook is installed by default.
7. **`orchestrate` skill exists → no per-agent scoping / credentials isolation** primitive.
8. **`deep-research` / `feature-research` skills exist → no "fact-verification against vendor docs" step** using an MCP like context7.
9. **`plan-workflow` / `parallel-plan` exist → no `change-window-plan`** variant that respects CAB windows.
10. **`ansible-automation-expert` agent exists → no `ansible-vault` / credential-plugin** pattern ships.
11. **`terraform-architect` agent exists → no drift-detection / state-reconcile** skill.
12. **`systems-engineering-expert` agent exists → no `kernel-sysctl` / `ebpf` / `systemd-unit`** skill to hand work off to.
13. **`reverse-proxy-architect` agent exists → no TLS-cert / cert-manager / certbot skill.**
14. **`init` command exists → no `init --netops`** profile that emits netops-specific CLAUDE.md guidance.

---

## Barriers by Category

| Category  | Barrier                                                   | Blocking for                                    |
| --------- | --------------------------------------------------------- | ----------------------------------------------- |
| Technical | Cloud inference                                           | Defense, utilities, finance, healthcare         |
| Technical | No secret-handling primitive                              | Every regulated team                            |
| Technical | No device inventory integration                           | Any network team with NetBox/ServiceNow         |
| Technical | No rollback primitive                                     | Every change-managed environment                |
| Technical | No validation sandbox                                     | Any vendor-config work (85% → 97% accuracy gap) |
| Legal     | No provenance / reasoning capture                         | SOX/PCI/HIPAA/FedRAMP                           |
| Legal     | Vendor support contracts prohibit LLM training on configs | Enterprise support customers                    |
| Legal     | License provenance unclear                                | Defense / DO-178C / ISO 26262                   |
| Cultural  | "AI babysitter" concern                                   | Senior network engineers                        |
| Cultural  | Junior pipeline erosion                                   | Teams with juniors                              |
| Cultural  | Trust deficit from billing incidents                      | Cost-conscious teams                            |
| Economic  | 4x compat-bundle multiplier per artifact                  | Single maintainer of `ycc`                      |
| Economic  | Vendor SDKs are free; inference is not                    | Cost-sensitive adopters                         |
| Economic  | MSP per-tenant isolation gap                              | MSP operators                                   |

---

## Key Insights

1. **The single biggest gap is not a missing domain skill — it is the absence of safety and audit primitives.** A `ycc:netops-blast-radius-guard` hook has more value than five vendor-specific CLI skills because it catches errors across _every_ skill that follows.
2. **The `hooks-workflow` skill without a shipping `hooks/` directory is the most visible complementary absence.** Fixing this single gap unlocks a class of safety features.
3. **`ycc` is on the wrong side of the NetBox Copilot inflection.** The industry is converging on "inventory-integrated AI." `ycc` has no opinion on inventory.
4. **The owner's single-maintainer constraint argues against vendor-specific skills (Cisco vs. Juniper vs. Arista) and in favor of workflow skills (change-review, evidence-bundling) that are vendor-agnostic.** A `network-change-review` skill outperforms `cisco-config-review` + `juniper-config-review` + `arista-config-review` at 1/3 the maintenance cost.
5. **The most credible path to `ycc` netops expansion is: safety primitives first, workflow orchestration second, vendor-specific content last (if at all).** Vendor specifics age badly; safety and workflow do not.
6. **Every plugin that _has_ succeeded in netops (`phaezer/claude-mkt`, `kubestellar`, `Sagart-cactus`) ships with opinionated guardrails — kind-cluster guards, RBAC analysis, drift detection.** Success correlates with safety features, not breadth of coverage.
7. **Junior engineers are a large, un-served audience.** A `coach-mode: true` flag on existing skills (deep-research, plan, code-review) that injects "here's why" rationale would cost very little and address the experience-paradox directly.
8. **The `ycc` bundle is implicitly positioned for senior software engineers.** The domain-expansion opportunity is to explicitly position for senior networking / infra engineers — a different audience with different expectations.

---

## Contradictions & Uncertainties

- **"Add more skills" vs. "stay lean."** The project CLAUDE.md explicitly warns against completionism. Every proposed skill must justify its 4x compat cost.
- **"Vendor skills hallucinate" vs. "Claude + RAG + verification can hit 97%."** Research says both. The skill-author's job is to engineer the verification path — but that is a heavy lift for a single maintainer.
- **"AI replaces juniors" vs. "AI coaches juniors."** Both outcomes are happening in different teams. `ycc` can aim at either; it cannot aim at both with the same skill.
- **"MCP / context7 is the future of doc-grounding" vs. "air-gapped customers cannot use MCP calls outside the perimeter."** A skill that depends on external MCP is useless to air-gapped users.
- **"Workflow skills > vendor skills"** (my claim) vs. **"vendor-specific skills are what practitioners actually Google for"** (the counter). Marketplace analytics I could not see would decide this.
- **"Hooks prevent mistakes" vs. "hooks are the attack vector" (CVE-2026-21852).** Hooks help but need their own hygiene.

---

## Specific Punch List of Proposed `ycc` Additions

Minimum 10 concrete artifacts, with evidence that the workflow is real and the absence is real. Not all should be built — this is the raw candidate set. Effort estimates are S/M/L.

1. **`ycc/hooks/` directory + installable hook manifests (S, P0).** Fill the biggest complementary gap. Start with: pre-commit `.env`/secret-scan hook, PreToolUse blast-radius warn-then-block for `rm -rf`, post-edit formatter trigger. Evidence: every safety plugin reviewed is a PreToolUse hook. Why NOT: hooks are an attack vector; shipping them requires hygiene discipline.

2. **`ycc:context-guard` skill + `context-guard.sh` hook (M, P0).** Read `kubectl config current-context` / `KUBECONFIG` fingerprint / AWS profile / git remote-url before running mutation commands. Block if env is tagged `prod-*`. Evidence: Kubesafe, KubeContext Safety, `Sagart-cactus` all productize this. Why NOT: if the user's context naming isn't consistent, the check is noise.

3. **`ycc:blast-radius` tag on commands + `/ycc:blast-radius` command (S, P1).** Add a `scope:` / `blast-radius:` frontmatter field to every command; write a command that summarizes any proposed action's blast radius before it runs. Evidence: Anthropic auto-mode article explicitly calls this out. Why NOT: labels are cosmetic unless enforced by a hook.

4. **`ycc:netchange-review` skill (M, P1).** Composed workflow: config-diff + lint + blast-radius + rollback-plan + evidence-bundle for a proposed network change. Vendor-agnostic (feed it any diff). Evidence: CAB processes require exactly this artifact; no plugin produces it. Why NOT: vendor-specific linters (Batfish, Containerlab) are the real value-add and this skill doesn't ship them.

5. **`ycc:evidence-bundle` skill (M, P1).** Produce a SOX/HIPAA/PCI-ready evidence bundle for a change: prompt, response, model version, tool-call trace, approver, timestamp, diff, rollback-plan. Write to `docs/evidence/YYYY-MM-DD/`. Evidence: every GRC tool reviewed (Delve, Drata, Secureframe) has this shape. Why NOT: bundles rot; unless integrated with a real GRC system they're write-only.

6. **`ycc:cmdb-lookup` skill + `netbox-client.sh` helper (M, P2).** Query NetBox / ServiceNow CMDB / Infoblox for device or IP facts before suggesting a config. Evidence: NetBox Copilot launched 2026-02; inventory-grounded AI is the trajectory. Why NOT: adds a dependency on an external system that most `ycc` users don't have.

7. **`ycc:rollback-plan` skill + command (S, P1).** Every change-producing skill can invoke this to append a "how to undo" section to its output. Evidence: every NCM (rConfig, ManageEngine, Cisco Smart Net) ships one. Why NOT: for code changes, `git revert` is already the answer; for device configs, it's non-trivial.

8. **`ycc:change-window` skill + `change-window-check.sh` hook (S, P2).** Read a project-local `change-windows.yml`; block or warn on commands that would commit outside the window. Evidence: CAB processes live on this. Why NOT: scheduling config is project-specific and brittle.

9. **`ycc:secrets-broker` pattern + docs (S, P2).** Not a full skill — a documented pattern for `ycc` skills that need credentials: use `1password run` / `vault read` / `akeyless get-secret` as a shell wrapper, never hardcode. Evidence: Ansible has had this since 2015; `agent-secrets` repo shows the modern shape. Why NOT: if users ignore the pattern it helps nothing.

10. **`ycc:cab-pack` command (S, P2).** One-shot: take a branch/PR, emit a CAB-ready markdown: summary, risk, blast-radius, backout-plan, tested-in, approvers. Evidence: every CAB template surveyed asks for these fields. Why NOT: CAB formats vary by org; a generic pack may not fit.

11. **`ycc:coach-mode` flag on existing skills (S, P2).** Add a `--coach` flag to `deep-research`, `plan`, `code-review`, `orchestrate`. Injects "here are the 3 alternatives I considered and why I rejected them" into output. Evidence: junior-pipeline erosion is the loudest silent-stakeholder signal. Why NOT: adds token cost; seniors find it noise.

12. **`ycc:k8s-context-audit` skill (M, P2).** Walk kubeconfig contexts, rank by blast radius, emit a report: "You have 14 contexts; 3 are production; 2 are identically named across kubeconfig files (collision risk)." Evidence: every context-management blog post in the dataset says this is where mistakes originate. Why NOT: kubectl plugins already do this; a Claude skill adds narration and little else.

13. **`ycc:policy-dedup` skill (L, P2).** Read ACLs / firewall policies, detect shadowed / duplicate / overlapping rules, emit a dedup plan. Evidence: AlgoSec/Titania/Cisco FMT all ship this as a product feature. Why NOT: correctness is hard; vendor tools have decades of corner-case handling. A naive Claude implementation will be wrong often.

14. **`ycc:runbook` skill (M, P2).** On-call / incident runbook: take a paging alert, retrieve context, propose first three triage steps. Evidence: Datadog Bits, Relvy, Incident Copilot all target this. Why NOT: direct competition with mature products; `ycc` has no telemetry integration.

15. **`ycc:lab-verify` skill (M, P2).** Take a proposed config, run it through a lab (Containerlab / GNS3 / EVE-NG / Batfish) via local shell before declaring "done." Evidence: research papers show lab+LLM hits 97% vs. LLM-alone 85%. Why NOT: requires the user to have a lab; out of scope for most users.

**Recommended stop line: items 1-6 are the credible P0/P1 set.** Items 7-15 are candidates dependent on owner validation against actual daily workflow.

---

## Evidence Quality

| Source type                                                                | Count         | Notes                                                                                          |
| -------------------------------------------------------------------------- | ------------- | ---------------------------------------------------------------------------------------------- |
| Primary (vendor docs, Anthropic eng blog, Cisco/Nokia/Arista product docs) | ~10           | Strong. Includes Anthropic auto-mode post explicitly flagging blast-radius.                    |
| Research papers (arXiv, IETF)                                              | 3             | Strong on LLM-hallucinates-CLI-syntax — direct benchmarks, multiple vendors.                   |
| Practitioner blogs (Cisco blogs, Layer8Packet, Tabnine, ilert, paddo.dev)  | ~12           | Medium — well-argued but represent individual viewpoints.                                      |
| Marketing / vendor sites (AlgoSec, Zscaler, Fortinet, Akeyless)            | ~10           | Weak for neutral claims; strong as evidence that "this product category exists and is funded." |
| Direct inventory read of `ycc/`                                            | 4 directories | Authoritative for what ycc ships/does not ship.                                                |

**Contradictions I preserved:**

- "More skills help" (completionist) vs. "4x maintenance cost per artifact" (project CLAUDE.md policy).
- "AI replaces juniors" (LeadDev survey, 54%) vs. "AI should coach juniors" (Cisco career-trajectory argument).
- "Cloud inference is required for modern LLMs" (Anthropic, Cursor, Copilot) vs. "Air-gap is a gating requirement for regulated work" (Tabnine, defense).
- "Workflow skills > vendor-specific skills" (my synthesis) vs. "Practitioners search for vendor specifics" (uncontested counter).

---

## Search Queries Executed

1. `Claude Code plugin marketplace network automation kubectl netops`
2. `GitHub Copilot Cursor AI assistant network engineering criticism gap 2026`
3. `LLM hallucinates Cisco Juniper vendor CLI syntax accuracy network config`
4. `AI generated ACL firewall config liability compliance audit trail`
5. `junior network engineer AI assistant adoption barrier`
6. `air-gapped environment AI coding assistant constraints SCADA OT`
7. `MSP managed service provider multi-tenant network AI automation tool`
8. `compliance evidence bundling SOX PCI HIPAA FedRAMP network change workflow`
9. `change advisory board CAB prep AI automation network infrastructure`
10. `network config drift detection tool rollback staged deployment 2026`
11. `kubectl context aware plugin prevent wrong cluster production accident`
12. `Claude Code plugin blast radius warning dry-run safety hook`
13. `MPLS segment routing BGP policy lint validation AI tooling`
14. `firewall policy deduplication ACL zero trust migration AI tool`
15. `NetBox CMDB device inventory integration AI assistant workflow 2026`
16. `VMware Proxmox KVM hypervisor lifecycle AI automation Claude Cursor`
17. `on-call oncall runbook AI assistant incident response network`
18. `secrets management device credentials network automation AI plugin`

Plus direct reads of `ycc/skills/`, `ycc/agents/`, `ycc/commands/`, `ycc/skills/_shared/scripts/`, and `docs/research/ycc-ecosystem-enhancements/objective.md`.

---

## Bottom Line

The silences around netops / K8s day-2 / virt / vendor-firewall AI tooling are real, structural, and rooted in five forces: vendor CLI confabulation, audit/regulatory liability, air-gap constraints, junior pipeline erosion, and maintenance-cost asymmetry.

For the `ycc` single-maintainer constraint, the highest-leverage additions are **safety primitives (hooks, context-guard, blast-radius labels) before domain content**. The biggest complementary absence — a `hooks-workflow` skill with no shipping `hooks/` directory — should be closed before any vendor-specific expansion.

The next most valuable additions are **workflow skills that are vendor-agnostic** (`netchange-review`, `evidence-bundle`, `rollback-plan`, `change-window`) because they multiply value across domains without multiplying vendor-version maintenance.

Vendor-specific skills (Cisco/Juniper/Arista/PAN-OS) are a P2 at best; they age poorly and duplicate vendor-native tooling. If built, they must ship with lab-verification (Batfish/Containerlab) or they will ship with the 85% confabulation problem research documents.
