# Research Objective: ycc Plugin Ecosystem Enhancements

**Research Date**: 2026-04-20
**Repository**: `yandy-r/claude-plugins` (bundle name: `ycc`)
**Researcher**: Claude Code (Opus 4.7, Asymmetric Research Squad methodology)

---

## Background

The `ycc` plugin bundle for Claude Code ships one Claude Code plugin (plus generated
compatibility bundles for Cursor, Codex, and opencode) comprising ~45 skills, ~45
agents, and ~40 commands. The current inventory is **heavily development-focused**:
language patterns (Go/Rust/Python/TypeScript), frontend design, git/PR workflows,
deep-research, planning, code review, releaser, bundle-author, formatters, Cloudflare,
Terraform, Ansible (one agent), reverse-proxy-architect, and systems-engineering-expert.

The repository owner's work extends well beyond app development into:

- **Network design / architecture** (routing, switching, SD-WAN, overlays)
- **Network configuration** at the device level
- **Kubernetes** (day-2 ops, security, multi-cluster)
- **Containers** (Docker, Podman, image supply chain)
- **Virtualization** (VMware, KVM/libvirt, Proxmox)
- **Network security** (firewalls, IDS/IPS, zero trust, segmentation)
- **Cloud infrastructure** (AWS, Azure, GCP)
- **Vendor platforms**: Cisco, Fortinet, Juniper, Palo Alto Networks

**The current bundle is thin-to-nonexistent in these domains.** Development-adjacent
infrastructure work (Terraform, Ansible, Cloudflare) is partially covered, but
vendor-specific network engineering, K8s cluster operations, hypervisor lifecycle,
and firewall policy work are entirely absent.

## Core Research Questions

1. **What genuine gaps exist** in the current `ycc` bundle versus the owner's stated
   work domains (networking, K8s, containers, virtualization, network security, major
   cloud providers, vendor firewall/routing platforms)?
2. **Where do existing tools already solve these problems well** (Ansible modules,
   Nornir, NetBox, Pulumi, Crossplane, Rancher, vendor CLIs/APIs), such that adding a
   Claude-side skill is net-negative or duplicative?
3. **What is the right abstraction for a Claude plugin in this space** — skill
   (progressive-disclosure guidance), agent (delegated-context reasoner), command
   (slash entry-point workflow), hook (event-driven automation), or script
   (deterministic helper)?
4. **What hooks and validation scripts** would materially prevent mistakes in
   network/infra work (typo-in-ACL, wrong cluster context, uncommitted config-drift,
   secrets in device configs, blast-radius warnings)?
5. **Which additions have the highest value-to-maintenance ratio**, given that the
   owner is a single maintainer shipping cross-target bundles (Claude / Cursor /
   Codex / opencode) and every new artifact multiplies across 4 targets?

## Success Criteria

- [ ] All 8 personas deployed with distinct search strategies.
- [ ] Minimum 8-10 searches per persona executed.
- [ ] Repository's current inventory is grounded against — no recommending what
      already exists (e.g., `terraform-architect` agent, `reverse-proxy-architect`).
- [ ] Each proposed addition has a concrete form (agent / skill / command / hook /
      script) and a justification tied to a real failure mode or workflow.
- [ ] Contradictions between "more tooling helps" and "avoid bloat / stay lean" are
      preserved, not smoothed.
- [ ] Cross-domain analogies explored (Ansible Galaxy, Terraform Registry, VS Code
      network extensions, JetBrains network tools, Backstage plugins).
- [ ] Temporal coverage (past, present, near-future of network/infra tooling).

## Evidence Standards

- **Primary**: vendor documentation (Cisco DevNet, Fortinet Fortigate API, Juniper
  Junos PyEZ, Palo Alto PAN-OS XML/REST API), project docs (k8s, kubectl plugins,
  kubeseal, cert-manager), AWS/Azure/GCP SDK docs.
- **Secondary**: authoritative practitioner writing (NetworkToCode, Packet Pushers,
  Ivan Pepelnjak, CNCF landscape surveys, Kelsey Hightower, Last Week in AWS).
- **Synthetic**: aggregators, trend reports (Gartner/Forrester — flag as synthetic).
- **Speculative**: opinion pieces, predictions — flag explicitly.

## Perspectives to Consider

- **Historical evolution**: how network automation tooling matured (Expect scripts →
  Ansible → Nornir → NetDevOps → AI-assisted ops). What the Claude era adds (or
  doesn't).
- **Current state**: which Claude plugins, VS Code extensions, JetBrains tools, and
  CLI ecosystems already cover each domain; what their weaknesses are.
- **Future possibilities**: AI agents for incident response, diff-then-commit config
  workflows, NL-to-ACL, cluster-aware context switching, cloud cost anomaly surfacing.
- **Alternative viewpoints**: the "don't add to Claude, use existing vendor tooling"
  critique must be taken seriously. When does a Claude-side artifact genuinely help
  versus just duplicate a vendor SDK?
- **What's NOT being discussed**: most AI coding assistants ignore network/infra work
  entirely; why? Is that a gap or a signal that the abstraction doesn't fit?

## Potential Biases to Guard Against

1. **Developer-tooling bias**: treating network engineering like software engineering
   and assuming the same abstractions (language patterns, unit tests, PR workflow)
   map cleanly. They don't — device configs, blast radius, and change windows are
   fundamentally different.
2. **Vendor-product bias**: assuming every major vendor needs its own skill/agent.
   Vendors ship their own MCP servers or CLIs; a Claude-side agent may add little.
3. **Completionist bias**: wanting to fill every cell in a "domain × artifact type"
   matrix. The user explicitly said "I don't want to add just for the sake of adding
   new things."
4. **Recency bias**: over-weighting 2024-2026 hype (AI network ops, GitOps) and
   under-weighting mature patterns (CLI wrappers, Ansible roles, Terraform modules).
5. **Maintenance-cost blindness**: every new artifact is generated into 4 compat
   bundles and must pass validators, formatters, and cross-target audits. Low-value
   additions burn maintainer time disproportionately.

## Scope Boundaries

- **In scope**: concrete proposals for new `ycc` agents, skills, commands, hooks,
  and scripts with strong justification.
- **In scope**: workflow-level additions (e.g., a "network-change-review" skill that
  combines diff + lint + blast-radius + rollback-plan).
- **Out of scope**: non-Claude tooling recommendations (use Ansible / use Nornir) —
  those are context for _whether_ a Claude artifact helps, not the deliverable.
- **Out of scope**: redesigning existing `ycc` artifacts. Only additions and
  extensions are requested.

## Success = High-Signal Punch List

The final report must produce a **ranked, justified punch list** of proposed
additions, each with:

- Form (agent / skill / command / hook / script)
- Domain (networking / k8s / containers / virt / netsec / cloud / vendor)
- One-sentence value prop
- Concrete failure mode it prevents OR workflow it unlocks
- Reason NOT to build it (honest counter-argument)
- Rough effort estimate (S / M / L)
- Priority (P0 / P1 / P2) based on value-to-maintenance ratio

This is not a "survey of the space" — it is a **build decision document**.
