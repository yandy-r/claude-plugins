# Analogist Persona Findings — Cross-Domain Parallels for `ycc` Ecosystem Expansion

**Researcher**: analogist
**Date**: 2026-04-20
**Subject**: How a developer-tooling plugin ecosystem (`ycc`) should extend into network engineering, K8s, containers, virtualization, network security, cloud, and vendor platforms.

---

## Executive Summary

The temptation to grow `ycc` into a full-stack operator toolkit is the exact path that burned **Backstage**, the early **JetBrains Big Data Tools** plugin, and countless Ansible Galaxy namespaces. The cross-domain record is remarkably consistent:

1. **Supply-first plugin ecosystems die from quality variance, not supply shortage.** Krew solved kubectl discoverability but explicitly refused to solve security auditing; the Terraform Registry survived by inventing a three-tier badge system; Backstage maintainers wish they had 1 GitHub plugin instead of 15.
2. **Niche partitioning beats niche overlap.** Ansible collections, kubectl plugins, and VS Code extensions that succeeded filled **empty niches** (remote SSH, kubectl-neat, netbox-ansible). The ones that failed duplicated what vendors already shipped.
3. **The "whole product" gap is real and asymmetric.** Early-majority pragmatists (the owner's target user when operating on networks and K8s, not writing toy demos) won't adopt a partial skill. A half-built `cisco-ios` skill is worse than no skill — it implies coverage and delivers surprise failures.
4. **Checklists + adaptive judgment beats either alone.** Gawande's pilot-style runbook model maps directly to the hybrid `skill = progressive disclosure + script = checklist enforcement` pattern. This is the single most transferable mechanism.
5. **Force multipliers belong where the OODA loop is slowest, not where it's fastest.** AI agents add the most value at the **Orient** phase (making sense of cross-vendor state) and the **Decide** phase (blast-radius reasoning), not at **Act** (which vendor tools already automate).

**Bottom-line recommendation to team-lead**: ycc should behave like the Terraform Registry's **Official tier** (tight, owned, maintained) and deliberately _avoid_ becoming a Community tier (volume-optimized). Add skills that fill genuine empty niches — not ones that compete with vendor MCPs, vendor CLIs, or well-maintained FOSS. The right frame is **keystone species, not body count**.

---

## Plugin-Ecosystem Analogies

### VS Code Remote-SSH — the "empty niche, huge asset" case

**Pattern**: Microsoft did not build a generic "network tools" extension. They built _one_ extension (Remote-SSH) that filled a specific empty niche — local-quality editing over SSH without syncing files — and shipped a companion Extension Pack for WSL, containers, and tunnels. It succeeded because it offered **capability that could not be reproduced by duct-taping existing tools**.

**Mechanism**: The extension is trusted because it does one thing unusually well: installs a thin VS Code server on the remote host, forwards ports over SSH tunnels, and delivers full IntelliSense/debugging. Not because it aggregates network features.

**Transfer to ycc**: Do not build a skill called `network-engineering`. Build a skill called `network-change-review` that unambiguously fills a niche: diff + blast-radius + rollback-plan synthesis across vendor configs. That is the Remote-SSH analog.

### JetBrains Big Data Tools — the monolith-to-modular split

**Pattern**: Pre-2023.2, Big Data Tools was a single plugin bundling Zeppelin, Kafka, HDFS, Spark integrations. Starting 2023.2, JetBrains **split it into six independently installable plugins** while keeping the umbrella bundle for convenience.

**Mechanism**: The monolithic version forced every user to carry every integration — large install, unnecessary update churn, hard-to-diagnose conflicts. The split let users install only what they use while still offering the "install everything" escape hatch.

**Transfer to ycc**: The existing bundle-as-single-plugin design (`ycc` with ~45 skills, ~45 agents) is _already_ closer to JetBrains post-split than pre-split, because skills load on demand. **Warning signal**: If a new `vendor-platforms` mega-skill bundles Cisco + Juniper + Fortinet + Palo Alto in one SKILL.md, that's the Big Data Tools pre-2023.2 anti-pattern. Keep vendor-specific content in separate skills if/when they exist.

### Backstage — the "every plugin stands alone" critique

**Pattern**: Backstage plugins are isolated by architecture, which is both its distributed-ownership strength and its data-silo weakness. BackstageCon 2026 maintainers publicly said: _"instead of 15 different GitHub plugins or 20 AWS plugins, maintainers should strive for single, comprehensive plugins that cover broad areas."_

**Mechanism**: Isolation enables InnerSource and parallel teams but fragments use cases. Users want "deploy my service" workflows that cut across plugins; Backstage's architecture rewards the plugin-builder (easy to ship), not the plugin-user (hard to compose). Versioning breakage and React Router migrations have compounded the pain for companies several versions behind.

**Transfer to ycc**: This is a genuine hazard. If `ycc` adds `k8s-debug`, `k8s-security`, `k8s-multi-cluster`, `k8s-policy`, `k8s-gitops` as separate skills, the owner will be in the Backstage trap within 12 months. The synthesis pattern should be **one `k8s-operations` skill with progressive disclosure to specialized sub-references**, not five flat skills.

### Ansible Galaxy — namespace-as-quality-signal

**Pattern**: Fully Qualified Collection Names (`namespace.collection`) plus reserved namespaces (`ansible.builtin`, `community.*`, `local.*`) give users a glance-level quality signal. `cisco.ios` and `cisco.nxos` are vendor-authored; `community.network` is community-maintained; the distinction is explicit in the FQCN.

**Mechanism**: The namespace reserves a reputation lane. Vendors sign their own work, community takes best-effort content, and `local.*` guarantees no Galaxy collision. Users can pick confidence tiers without reading changelogs.

**Transfer to ycc**: The single `ycc:` namespace is fine for a single maintainer. **But**: when adding network/infra content, follow the Ansible mental model — prefer the `community.network` pattern over the `cisco.ios` pattern, because a single maintainer **cannot credibly play Cisco**. A skill named `ycc:cisco-ios` implies vendor-grade coverage; a skill named `ycc:network-change-review` that happens to handle Cisco IOS syntax implies workflow support.

### Terraform Registry — the three-tier quality model

**Pattern**: Terraform Registry uses **Official** (HashiCorp-owned), **Verified/Partner** (vendor-authored, onboarded, maintained), **Community** (everything else). The tiers are badges, not walls — all are installable, but the badge tells users what maintenance they can expect.

**Mechanism**: The tier system preserves diversity at the bottom while creating a **trusted floor at the top**. Verified providers are a quality signal because the vendor has committed to active maintenance. Community providers are fine for early adopters and explorers but wouldn't be chosen for production.

**Transfer to ycc**: ycc cannot become a registry (it's a bundle). But the **tiering concept maps to internal prioritization**: mark skills as P0 (production-quality, actively used by the owner), P1 (solid but less exercised), P2 (experimental). Compat-bundle generators could expose this as metadata so users — or Claude itself — can weight suggestions. This avoids the Backstage "every plugin looks the same" failure mode.

### CNCF Landscape — inclusion criteria that gate by adoption, not architecture

**Pattern**: CNCF's Sandbox → Incubating → Graduated ladder evaluates **committer diversity, adoption, governance** — not technical merit. A project can be architecturally brilliant and stuck in sandbox because it lacks three independent adopters willing to go on record. Maturity corresponds to Crossing-the-Chasm tiers (Innovators → Early Adopters → Early Majority).

**Mechanism**: Inclusion criteria protect the "Graduated" brand. A Graduated project is a safe bet for an SRE committing to production; a Sandbox project is a research-grade bet. Users self-select based on the tier.

**Transfer to ycc**: Single-maintainer projects cannot replicate CNCF governance. But **the "adoption-weighted, not architecture-weighted" evaluation is the right mental model** for deciding what to build. Do not ask "could I build a cisco-ios skill?" — ask "have I used a hypothetical cisco-ios skill ≥3 times in the last 60 days while doing real work?" If no, it belongs in Sandbox (private experiments), not shipped.

### Krew (kubectl plugin manager) — discoverability solved, governance punted

**Pattern**: Krew solved kubectl plugin discoverability explicitly (centralized index → 200+ plugins) but **deliberately refused to solve dependency management or security auditing**. Plugins self-describe in YAML manifests; users trust on install. Current index warns: _"plugins available via the Krew plugin index are not audited for security."_

**Mechanism**: Krew succeeded by doing the one hard thing (uniform install across OS + kubectl conventions) and nothing more. It "is a glorified curl+untar+mv+symlink" and that's a feature, not a bug.

**Transfer to ycc**: The correct discoverability mechanism already exists (marketplace.json + `ycc:` prefix). The right Krew-style move is **explicitly refuse to solve things**: no dependency graphs between skills, no auto-updating references, no vendor SDK pinning. Each skill should be `curl+untar+mv+symlink`-equivalent: one SKILL.md, optional scripts, optional references — all self-contained. This is already the design. **Preserve it**.

---

## Biological Analogies

### Niche partitioning — empty niches vs. competitive exclusion

**Pattern**: MacArthur's warblers forage at different heights in the same spruce. Savanna herbivores eat grass of different lengths at different seasons. Caribbean anoles share diets but occupy different physical perches. **Two species cannot occupy the same exact niche and coexist stably** (competitive exclusion principle).

**Transfer to ycc**: The current `ycc` inventory is rich in niches software engineers already occupy — language patterns, PR workflow, code review. Network/infra work has **wildly different niche topology**:

- **Niche already occupied (competitive exclusion kills new entrants)**: vendor MCPs when they exist (Palo Alto PAN-OS API, Cisco DNA Center, Fortinet FortiManager), Ansible `cisco.ios`/`cisco.nxos` collections, Nornir, Nautobot, NetBox, kubectl + Krew, Pulumi, Crossplane. **Do not build a ycc skill here** — it will be outcompeted by the incumbent.
- **Empty niche (novel approach)**: cross-vendor workflow synthesis (diff + blast-radius + rollback), AI-assisted change narration, natural-language-to-ACL validation, context-switch safety (wrong cluster / wrong site), change-window enforcement. These are **not occupied by any vendor or FOSS tool** because they're meta-workflows, not device drivers.

The clean test: **If an Ansible module or vendor MCP exists, the ycc skill should be the reasoner above it, not a replacement for it.**

### Keystone species — small abundance, disproportionate effect

**Pattern**: Sea otters control urchin populations, which protects kelp forests, which supports hundreds of species. Remove the otter — collapse cascades. The keystone's value is disproportionate to its biomass.

**Transfer to ycc**: Out of 45 current skills, maybe 5–8 are "keystone" — `git-workflow`, `plan-workflow`, `code-review`, `bundle-release`, `deep-research`. These do heavy lifting for many downstream tasks. The rest are specialists.

**Implication**: New additions should be evaluated as _keystone candidates or niche specialists_, not in between. A skill like `network-change-review` could be keystone (touches diff, review, rollback, documentation simultaneously). A skill like `fortinet-vdom-config-dump` is a pure specialist — fine if the niche is empty and the owner's workflow needs it, but not keystone. **Most proposed "vendor" skills are specialists at best, duplicates at worst.**

### Symbiosis / mutualism — who benefits from adding skills?

**Pattern**: Symbiosis requires both parties to gain. When clownfish and anemone both benefit, the relationship stabilizes. When only one side benefits, it's parasitism and collapses.

**Transfer to ycc**: Every new skill creates maintenance cost (formatters, validators, cross-target bundles × 4). Its existence must benefit both the user _and_ the maintainer's time budget. Skills like `go-testing` or `python-patterns` offload cognitive load the owner doesn't want to re-explain — mutualism. A `fortinet-fortios-cli` skill the owner uses twice a year is parasitic (cost > benefit).

---

## Market / Strategic Analogies

### Sharp knives vs. Swiss army knife (Unix philosophy)

**Pattern**: Unix pipelines (`grep | sort | uniq`) succeed because each component is sharp, narrow, inspectable, and composable. Multi-tools win only when composition is unavailable (roadside repair) or portability trumps precision. **McIlroy's rule**: "Make each program do one thing well. To do a new job, build afresh rather than complicate old programs."

**Transfer to ycc**: The existing `ycc:git-workflow`, `ycc:code-review`, `ycc:plan-workflow` pattern is sharp-knife. A hypothetical `ycc:netops-everything` skill is Swiss-army-knife. **Which is ycc closer to?** The commands `/ycc:clean`, `/ycc:code-review PR-123`, `/ycc:git-workflow` are narrow and composable. Maintain that.

**Critical implication**: The one place Swiss-army-knife thinking is justified is **where composition is unavailable** — when the user is deep in an incident with no other tools, wants a single entry point, and needs "just enough" to get unstuck. That could justify a single `/ycc:network-incident` command that orchestrates multiple specialist skills, but the specialists should remain sharp underneath.

### Crossing the Chasm — pragmatists demand the whole product

**Pattern**: Early adopters tolerate incomplete products. Early majority (pragmatists) demand **complete solutions**: core + integration + training + support + ecosystem + references. The chasm is the gap between these two buyer profiles.

**Transfer to ycc**: The owner is a pragmatist when operating networks (blast radius is real, downtime costs real money). A `ycc:cisco-ios` skill that handles 70% of IOS syntax and fails on OSPF edge cases is **exactly the partial product** that frustrates pragmatists. Better to:

- Ship zero vendor-CLI skills and defer to vendor tooling entirely, OR
- Ship a meta-workflow skill (change-review) that assumes vendor tooling exists and orchestrates above it.

The middle ground — half-built vendor skills — is the chasm trap.

### Two-sided marketplace dynamics — supply vs. demand

**Pattern**: Plugin registries succeed by solving supply-first (recruit anchor vendors with incentives), then demand follows. Risks: platform leakage, quality degradation, governance failures.

**Transfer to ycc**: Not directly applicable — `ycc` is single-sided (one producer, many consumers). But the **governance lesson transfers**: as additions accumulate, quality variance matters more than volume. The absence of a tier/badge system means every `ycc:*` skill looks equally endorsed. Consider a **provisional** or **experimental** tag in frontmatter so the user can weight it, paralleling CNCF Sandbox.

---

## Military / Strategic Analogies

### OODA loop — where AI agents amplify the most

**Pattern**: Boyd's OODA (Observe → Orient → Decide → Act) describes any decision cycle. In network/infra incidents, the phases have wildly different bottlenecks:

- **Observe**: mostly automated (SIEM, NetFlow, monitoring, Prometheus).
- **Orient**: the slowest step — making sense of cross-vendor state, correlating signals, understanding blast radius. **Human-bottlenecked.**
- **Decide**: risky but fast if Orient is good.
- **Act**: automated (Ansible, Terraform, vendor APIs).

**Transfer to ycc**: The **highest-leverage skills amplify Orient**, not Act. A skill that helps a human reason about "what will changing this ACL break?" is high-value; a skill that applies the ACL is a duplicate of Ansible/NAPALM/Nornir. Mapping to the ycc surface:

- **High value (Orient-phase)**: `network-change-review` (blast radius + rollback narrative), `cluster-context-guard` (wrong-cluster detection), `config-drift-explain` (why live ≠ SoT), `incident-narrate` (turn alerts into a story).
- **Low value (Act-phase)**: anything that generates vendor CLI — every tool in the NetDevOps stack already does this.

### Choke points and force multipliers

**Pattern**: Asymmetric warfare seeks choke points where a small force has outsized effect. A single cruise missile at a bridge > a thousand bullets.

**Transfer to ycc**: The equivalent choke points in the owner's workflow are likely:

- **Pre-change gate**: the moment before `terraform apply` / `ansible-playbook` / `commit`. One hook here prevents disasters.
- **Cross-cluster boundary**: the moment when `kubectl` is about to run against the wrong cluster.
- **Secret-exposure gate**: the moment a device config is about to include a plaintext secret.
- **Change-window boundary**: the moment an operator is about to push a change during a freeze.

These are where **hooks**, not skills, deliver the most value. A hook that runs 10ms before a dangerous action is worth 10 skills that explain what to do afterwards.

---

## Engineering Analogies

### Linux kernel / firmware / driver / distro split

**Pattern**: Linux separates concerns aggressively: `hardware → firmware (vendor binary) → driver (kernel module) → kernel → userspace`. Distributions split firmware into per-vendor packages (`linux-firmware-intel`, `linux-firmware-amdgpu`) so users install only what their hardware needs. Vendor prefixes in device trees (`compatible = "vendor,model"`) scope naming.

**Transfer to ycc**: This is the cleanest architectural model for the expansion question. The ycc equivalent layering:

- **Hardware** = the vendor device (Cisco IOS router, Palo Alto firewall, EKS cluster).
- **Firmware** = the vendor API / MCP / SDK (PAN-OS API, Junos PyEZ, kubectl, AWS SDK).
- **Driver** = the tooling layer (Ansible module, Terraform provider, Nornir plugin).
- **Kernel/Userspace** = the workflow (apply a policy, review a change, roll back a deployment).

**ycc belongs in the userspace / workflow layer.** It should assume drivers and firmware exist and reason above them. If a driver doesn't exist for a vendor the owner uses, the right response is to install the driver (Ansible collection, vendor MCP), not to bake driver-level knowledge into a ycc skill.

### Monorepo vs. polyrepo — coordination cost

**Pattern**: Monorepos trade high tooling complexity for low coordination cost. Polyrepos trade low tooling complexity for high coordination cost. At scale, monorepos win for shared-library evolution; polyrepos win for independent team ownership.

**Transfer to ycc**: A single maintainer is effectively a one-person team; there is no coordination cost to amortize. The `ycc` bundle is already monorepo-like (single marketplace entry, shared generators, single CI). **Adding network/infra skills should stay in the monorepo** — splitting out `ycc-networking` as a sibling plugin would create coordination overhead (version pinning, cross-bundle references) with zero coordination benefit.

---

## Knowledge-Work Analogies

### Gawande's Checklist Manifesto — checklists + adaptive judgment

**Pattern**: Gawande's central distinction is _errors of ignorance_ (don't know enough) vs. _errors of ineptitude_ (know but forget). Pilot-style checklists handle ineptitude (routine, forgettable, critical steps) so that expert cognitive capacity is freed for the ambiguous, adaptive decisions. Two complementary types: **Task checklists** (minimum necessary steps) and **Communication checklists** (who must talk to whom). The checklist is scaffold for judgment, not a replacement.

**Transfer to ycc — this is the single most transferable mechanism of the entire research**:

- **Skills = adaptive judgment scaffold** (progressive disclosure, references, patterns).
- **Scripts = task checklists** (deterministic, runnable, fail-loud).
- **Hooks = communication checklists** (force a pause + surface information before action).

For network/infra work specifically:

- A `network-change-review` skill provides adaptive judgment (how to evaluate blast radius).
- A `check-config-secrets.sh` script provides the task checklist (did I leak a password?).
- A `pre-apply` hook provides the communication checklist (warn the operator + require confirmation before `terraform apply` to prod).

This pattern directly answers core research question #3 ("what is the right abstraction?"). The answer is **all three, layered**. Skill for reasoning, script for determinism, hook for choke-point enforcement.

### Medical residency — "see one, do one, teach one"

**Pattern**: Halsted's 1890 Johns Hopkins model. Progressive responsibility from observation → autonomy, augmented today by simulators, competency milestones, and mentorship. **The pipeline transfers knowledge across generations**, not just within one career.

**Transfer to ycc**: The owner is the only "senior resident." There is no next generation to teach. But the analogy surfaces a useful diagnostic: **ycc skills should be things the owner would teach a new engineer on day 1, not things they'd explain every time**. If a skill is genuinely "see-one" material — a novice needs to read it once and then pattern-match — it belongs. If it's "do-one-with-supervision" — requires live adaptive judgment every time — a skill alone is insufficient; it needs a hook + script to scaffold the hands-on phase.

**Implication for proposed additions**: Skills that would benefit a hypothetical junior engineer copying the owner's workflow are good candidates. Skills that only make sense when the owner is already present and reasoning are low-value.

---

## Cross-Domain Patterns (the pattern layer)

Synthesizing across analogies, six recurring patterns apply to the ycc expansion decision:

### Pattern 1 — Fill empty niches, avoid competitive exclusion

Terraform Registry's Partner tier + kubectl plugins that survived + warbler niche partitioning. If a vendor MCP, vendor CLI, or mature FOSS tool already does it, **don't duplicate**. Build the workflow layer above it.

### Pattern 2 — Keystone > body count

CNCF Graduated tier + sea-otter effect + JetBrains Big Data split. A smaller number of high-leverage keystone skills beats a larger number of narrow specialists. Evaluate new additions by _how many downstream workflows they enable_, not by domain-coverage.

### Pattern 3 — Tier quality explicitly

Terraform Official/Verified/Community + CNCF Sandbox/Incubating/Graduated + Krew's explicit "not security-audited" disclaimer. **Absence of signal is itself a signal.** If ycc doesn't tier skills, users will assume uniform production-readiness — which is a promise the maintainer can't keep.

### Pattern 4 — Layer checklist + judgment

Gawande + Boyd's OODA + NetDevOps compliance drift detection. The highest-value additions are **not any single artifact type** — they're the stack: hook (force-pause) + script (deterministic check) + skill (adaptive reasoning).

### Pattern 5 — Amplify Orient, not Act

OODA + NAPALM/Ansible already doing Act-phase work + Backstage plugin-isolation critique. The "everything" tools succeed by adding to Observe/Orient; they fail when they try to duplicate vendor Act.

### Pattern 6 — Beware the whole-product chasm

Crossing the Chasm pragmatist requirements + Backstage maintainers' "15 GitHub plugins" regret + Big Data Tools pre-split. Partial coverage is worse than no coverage for operational workloads. **Either commit to a domain fully or stay out.**

---

## Novel Connections

Three connections that emerged from the cross-domain scan and are not individually obvious:

1. **The Linux kernel layering is a governance model, not just an architecture.** It tells maintainers where to stop. A ycc maintainer who adopts this mental model can unambiguously say "I'm in userspace; driver-level work belongs in Ansible/Nornir/Terraform/vendor MCPs." That's a **rejection heuristic**, not just an architecture diagram.

2. **Gawande's communication checklists map directly to hooks.** The research on his work distinguishes task checklists (what to do) from communication checklists (who must talk / confirm). In ycc terms, a hook that says "you're about to push to prod, here's the blast radius, type YES to continue" is the communication checklist — forcing a surface-and-confirm moment. This is meaningfully different from a skill that explains how to review a change.

3. **Krew's deliberate refusal to solve problems is the correct mental model for ycc v2+.** The temptation when expanding a plugin ecosystem is to add features. Krew succeeded by adding _distribution_ and explicitly refusing to add _dependency management, security auditing, or runtime coupling_. ycc should treat each potential new layer of functionality with the same skepticism: **"what's the hard problem we're refusing to solve?"**

---

## Transferable Solutions (ranked)

From highest to lowest transferability:

1. **Gawande's checklist + judgment layering** → map directly to skill (judgment) + script (checklist) + hook (communication checklist). **High transfer.** Applies to every proposed new capability.

2. **Terraform Registry tiering** → internal tiering of skills (P0/P1/P2 or production/provisional/experimental) via frontmatter metadata. **High transfer.** Cheap to implement, high clarity for users.

3. **Linux kernel layering as rejection heuristic** → "ycc is userspace; driver-level work belongs elsewhere." **High transfer** as a decision rule.

4. **OODA-phase value mapping** → build Orient-phase helpers, defer Act-phase to vendor tooling. **High transfer** as a prioritization framework.

5. **Krew's "refuse to solve hard problems"** → explicitly scope what ycc will _not_ do (dependency graphs, vendor-version pinning, live device state). **High transfer** as a documented non-goals section.

6. **Backstage's 15-plugin regret** → prefer one comprehensive `k8s-operations` over five flat `k8s-*` skills. **Medium transfer** — depends on how narrowly scoped domains stay.

7. **CNCF adoption-weighted evaluation** → "have I used this hypothetical skill ≥3 times in the last 60 days?" as a ship/no-ship gate. **Medium transfer** as a personal discipline, not replicable governance.

8. **Crossing the Chasm whole-product requirement** → avoid partial vendor coverage. **Medium transfer** — mostly a warning, not a build directive.

9. **Niche partitioning** → empty-niche test before adding any skill. **Medium transfer** — already implicit but should be explicit.

10. **Ansible namespace model** → not directly transferable (single maintainer), but informs naming conventions: prefer workflow names (`network-change-review`) over vendor names (`cisco-ios`).

---

## Key Insights (the punch)

1. **The single best investment is the checklist-judgment stack**, not any single skill or agent. Any new network/infra capability should ship as a trio: **hook for the choke point + script for determinism + skill for reasoning.** Anything less is partial coverage that falls in the chasm.

2. **Ycc is a userspace tool, not a driver-layer tool.** Vendor CLI coverage belongs to Ansible, Nornir, NAPALM, vendor MCPs. Ycc should explicitly reject driver-level work and own the workflow layer above it. This alone prevents half the proposed additions from surviving contact with reality.

3. **Orient-phase amplification is the highest-leverage addition.** Change-review, blast-radius narration, cross-vendor correlation, cluster-context safety — these are empty niches. CLI-generation, config-templating, device-discovery — these are occupied niches and would duplicate incumbents.

4. **Explicit tiering prevents the Backstage trap.** Without internal tiers (P0/P1/P2), every skill looks production-grade. Adding network/infra content without tiering guarantees the single-maintainer ends up defending half-built skills against user complaints.

5. **Count keystone impact, not domains covered.** A domain × artifact-type matrix looks comprehensive and is a trap. The CNCF, Ansible, and Krew record shows that 5–10 keystone capabilities outperform 50 specialized ones.

6. **"Don't build it" is a valid answer for most vendor-specific asks.** The Linux firmware-splitting pattern, Terraform's explicit Community tier, and the Crossing-the-Chasm whole-product warning all point the same direction: it is _better_ to ship zero skills for a vendor than to ship partial ones.

---

## Evidence Quality

- **High confidence**: Plugin-ecosystem analogies (VS Code, JetBrains, Backstage, Ansible Galaxy, Terraform Registry, CNCF, Krew) — all primary sources and widely-documented ecosystems.
- **High confidence**: Gawande's checklist model, OODA loop, Unix philosophy — well-attested and directly applicable.
- **Medium confidence**: Biological niche partitioning as software analogy — the SaaS/software mapping is already made by multiple sources, but it's an analogy, not a law.
- **Medium confidence**: Crossing-the-Chasm application to plugin ecosystems — Moore's framework is solid, but applying it to single-maintainer ecosystems is extrapolation.
- **Lower confidence**: Two-sided marketplace dynamics as applied to ycc — ycc is single-sided, so most of the marketplace mechanics don't apply; the governance lesson transfers but the supply/demand dynamics don't.

---

## Contradictions & Uncertainties

1. **Sharp knives vs. unified workflow**. Unix philosophy says narrow, composable tools. Crossing the Chasm says pragmatists want whole products. For ycc, the resolution is that the _user interface_ should be unified (one `/ycc:network-change-review` command) while the _internal implementation_ is composed of sharp knives (diff + blast-radius + rollback as separate skills/scripts). But this tension is real and the balance is not obvious.

2. **Tiering vs. hiding**. Terraform registry exposes tiers to users; Krew hides them (every plugin looks equal). The right choice for ycc depends on whether tiering is maintainer-facing (private P0/P1/P2) or user-facing (published badges). The research doesn't resolve this.

3. **"Build the workflow layer" vs. "don't build at all"**. Several analogies support both. Linux-kernel layering says build the userspace workflow. The Krew "refuse to solve hard problems" ethos says refuse more than you think. The CNCF adoption gate says wait until you've used it. These three pull in different directions for any given proposed skill.

4. **Monolith-vs-modular plugin bundling** is unresolved. JetBrains split Big Data Tools; Backstage regrets its isolation; Ansible's FQCN approach balances both. For ycc, the bundle-as-single-plugin is the best of both (shared maintenance, on-demand loading), but if skills grow past ~60–80, the JetBrains split pattern may become necessary.

5. **Vendor MCPs will eat ycc's lunch if vendor-tooling work is pursued**. Every major network/security vendor is shipping or planning MCP servers (Palo Alto, Fortinet Fabric API, Cisco DevNet, etc.). A ycc `cisco-ios` skill built in 2026-Q2 will be a worse Cisco MCP by 2026-Q4. The safe bet is the workflow layer above MCPs — but this assumes vendor MCPs actually ship and stay maintained.

---

## Search Queries Executed

1. "VS Code Remote SSH extension marketplace success network engineering"
2. "JetBrains Big Data Tools Database Navigator plugin pattern adoption"
3. "Backstage plugin architecture lessons learned ecosystem"
4. "Ansible Galaxy collection taxonomy network modules namespace"
5. "Terraform Registry provider quality tiers verified partner"
6. "CNCF landscape sandbox incubating graduated inclusion criteria"
7. "Unix philosophy sharp knives composability vs Swiss army knife tools"
8. "Boyd OODA loop applied network operations incident response"
9. "Atul Gawande checklist manifesto adaptive judgment runbook"
10. "ecological niche partitioning tools software keystone species analogy"
11. "Linux kernel driver firmware vendor hardware model distribution application split"
12. "microservices vs monorepo plugin ecosystem growth maintenance cost"
13. "network automation NetDevOps Nornir Nautobot vendor CLI abstraction failure modes"
14. "IDE plugin marketplace curation quality signals download metrics"
15. "Crossing the Chasm technology adoption plugin ecosystem early majority"
16. "medical residency see one do one teach one apprenticeship pipeline knowledge transfer"
17. "two-sided marketplace dynamics plugin registry supply-side incentives"
18. "kubectl plugin krew ecosystem success failure discoverability"

---

## Sources

- [VS Code Remote-SSH Marketplace](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh)
- [VS Code Remote Development Docs](https://code.visualstudio.com/docs/remote/ssh)
- [JetBrains Big Data Tools plugin](https://plugins.jetbrains.com/plugin/12494-big-data-tools)
- [JetBrains Database Navigator](https://plugins.jetbrains.com/plugin/1800-database-navigator)
- [Big Data Tools IntelliJ docs](https://www.jetbrains.com/help/idea/big-data-tools-support.html)
- [BackstageCon Europe 2026 plugin ecosystem panel](https://tldrecap.tech/posts/2026/backstagecon-europe/backstage-plugin-ecosystem-sustainability/)
- [Everything is a Plugin (Spotify / QCon) - InfoQ](https://www.infoq.com/presentations/backstage-plugin/)
- [Backstage plugin isolation / ETL critique - The New Stack](https://thenewstack.io/how-to-solve-backstage-plugin-isolation-problems-with-etl/)
- [Backstage revealed - bright spots and dark corners - APIscene](https://www.apiscene.io/dx/backstage-revealed-bright-spots-and-dark-corners/)
- [Ansible Collections — dev guide](https://docs.ansible.com/projects/ansible/latest/dev_guide/developing_collections_creating.html)
- [Ansible Galaxy metadata](https://docs.ansible.com/ansible/latest/dev_guide/collections_galaxy_meta.html)
- [Terraform Registry providers overview](https://developer.hashicorp.com/terraform/registry/providers)
- [Terraform Registry partner modules](https://developer.hashicorp.com/terraform/registry/modules/partner)
- [CNCF project lifecycle](https://contribute.cncf.io/projects/lifecycle/)
- [CNCF graduation criteria (GitHub)](https://github.com/cncf/toc/blob/main/process/graduation_criteria.md)
- [CNCF Project Maturity Ladder](https://timderzhavets.com/blog/cncf-project-maturity-ladder-when-to-bet-on-sandbox-vs/)
- [Unix philosophy — Wikipedia](https://en.wikipedia.org/wiki/Unix_philosophy)
- [People like Swiss Army knives — John D. Cook](https://www.johndcook.com/blog/2014/11/05/swiss-army-knives/)
- [Incident Response Methodology: The OODA Loop — LevelBlue](https://levelblue.com/blogs/security-essentials/incident-response-methodology-the-ooda-loop)
- [OODA Loop cybersecurity — SecurityWeek](https://www.securityweek.com/the-ooda-loop-the-military-model-that-speeds-up-cybersecurity-response/)
- [The Checklist Manifesto — Atul Gawande](https://atulgawande.com/book/the-checklist-manifesto/)
- [Checklist Manifesto summary — PMC NIH](https://pmc.ncbi.nlm.nih.gov/articles/PMC3960713/)
- [Niche partitioning — Nature Scitable](https://www.nature.com/scitable/knowledge/library/resource-partitioning-and-why-it-matters-17362658/)
- [Ecological niche — Wikipedia](https://en.wikipedia.org/wiki/Ecological_niche)
- [Linux Kernel Driver Model docs](https://docs.kernel.org/driver-api/driver-model/overview.html)
- [Linux Firmware Guidelines](https://docs.kernel.org/driver-api/firmware/firmware-usage-guidelines.html)
- [Monorepo vs microservices — Aviator](https://www.aviator.co/blog/monorepo-a-hands-on-guide-for-managing-repositories-and-microservices/)
- [Monorepo benefits and challenges — CircleCI](https://circleci.com/blog/monorepo-dev-practices/)
- [Nautobot — Network to Code](https://networktocode.com/nautobot/)
- [Nornir-Nautobot GitHub](https://github.com/nautobot/nornir-nautobot)
- [Awesome network automation](https://github.com/networktocode/awesome-network-automation)
- [Verified Plugins Program — DEV](https://dev.to/jeremy_longshore/verified-plugins-program-building-a-quality-signal-for-the-marketplace-512i)
- [Claude Code Plugin Marketplace](https://claudemarketplaces.com/about)
- [Crossing the Chasm — Wikipedia](https://en.wikipedia.org/wiki/Crossing_the_Chasm)
- [Crossing the Chasm in Technology Adoption — Business-to-You](https://www.business-to-you.com/crossing-the-chasm-technology-adoption-life-cycle/)
- [See One Do One Teach One — NIST](https://www.nist.gov/document/2017-lmih-bp-ojt-sodoto-method-nc)
- [Halsted Surgical Training — PMC NIH](https://pmc.ncbi.nlm.nih.gov/articles/PMC4785880/)
- [Learning Through Apprenticeship — Johns Hopkins Biomedical Odyssey](https://biomedicalodyssey.blogs.hopkinsmedicine.org/2018/10/learning-through-apprenticeship-a-continued-pillar-of-medical-education/)
- [Two-sided marketplace guide — Sharetribe](https://www.sharetribe.com/how-to-build/two-sided-marketplace/)
- [Two-sided marketplace strategy — Stripe](https://stripe.com/resources/more/two-sided-marketplace-strategy)
- [Krew — kubectl plugin manager](https://krew.sigs.k8s.io/)
- [Krew GitHub](https://github.com/kubernetes-sigs/krew)
- [Extend kubectl with plugins — kubernetes.io](https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/)
- [The case for a kubectl plugin manager — Ahmet Alp Balkan](https://ahmet.im/blog/kubectl-plugin-management/)
