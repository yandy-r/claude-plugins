# Historian Findings: Historical Evolution of Network/Infra Automation & Plugin Ecosystems

**Persona**: Historian
**Research Date**: 2026-04-20
**Scope**: 30-year lineage of network/infrastructure automation tooling, with a parallel lens on developer-tool plugin ecosystems expanding into adjacent verticals.
**Decision it informs**: Whether the one-maintainer `ycc` bundle should expand into networking / K8s / virt / netsec / cloud / vendor territory — and, if so, how history says that expansion plays out.

---

## Executive Summary

Thirty years of network automation history shows a single dominant pattern: **every wave of infra-automation tooling succeeded by picking one sharp-edged workflow and attaching to an existing operator habit, and every wave failed by trying to be "the platform."** That pattern is more relevant to `ycc`'s decision than any 2024-2026 AI hype.

Six concrete takeaways for the `ycc` build decision:

1. **Wrappers around existing CLIs outlived every "new platform."** RANCID (1997) — an Expect-and-CVS wrapper — is still running in production networks today. Cisco onePK (2013), TOSCA (2014), and OpenFlow-centric SDN (2011) are not. The durable tools wrapped _what the operator already did_ rather than asking them to adopt a new mental model.
2. **Incumbent-vendor "platform plays" are where tools go to die.** Puppet's network device model, Cisco onePK, Juniper SLAX, HP Opsware Network Automation — all were enterprise-grade and all were superseded or deprecated because the target users preferred simpler, composable tooling (Ansible collections, Python+Netmiko, Nornir).
3. **The 2015-2019 NetDevOps wave was the actual paradigm shift, not SDN or OpenFlow.** Ansible networking (2015, post-Red Hat acquisition), NAPALM (2015), Netmiko, Nornir (2018), NetBox (2016), and Jason Edelman's Network to Code collapsed the "device config" problem into the DevOps idiom of git + CI + declarative templates. That stack is what practitioners actually use in 2026; AI is layered _on top of it_, not replacing it.
4. **Plugin ecosystems are where single maintainers go to fail by overreach.** Atom died of performance, Vim's plugin scene has been in low-grade chaos for 15+ years, and the Tidelift 2020 and 2025 data show 46-58% of maintainers burn out, with "vertical expansion of responsibilities" cited as a top cause. Booklore (2026) is the canonical recent example of a solo maintainer expanding scope and collapsing.
5. **AI-assisted network ops has a ~30-year revival cycle and the same triggers keep killing it.** 1980s expert systems (MYCIN-derived rule engines for network troubleshooting) → 2000s self-healing networks → 2010s SDN → 2020s LLMs. Each revival is triggered by cheaper compute and/or a new modeling abstraction; each one is killed by the same two forces: (a) the real-world device heterogeneity tax and (b) operators' unwillingness to delegate blast-radius decisions to software. The current LLM wave is not exempt.
6. **The single most-copied successful pattern in 30 years is the "diff, review, version, apply" loop.** RANCID did it in 1997. Oxidized did it in 2013. Ansible `--check` + `--diff` did it at scale. Terraform `plan` did it for cloud. A Claude-side artifact that ships _this loop_ in a more legible, review-friendly form for a junior-to-mid engineer is the most historically-grounded bet; a Claude-side artifact that tries to be a "vendor MCP" is not.

**Headline recommendation for `ycc`**: history strongly favors a small number of **workflow-shaped** skills (diff-review-apply, blast-radius-warning, rollback-plan, context-switch-guard) over **vendor-shaped** skills (one-per-Cisco/Fortinet/Juniper/Palo). The vendors are the graveyard. The workflows are the cathedral.

Confidence: **High** on the historical claims and plugin-ecosystem claims (multiple primary and strong secondary sources). **Medium** on the direct mapping to `ycc` (the AI-agent-as-plugin genre is too young to have its own failure history yet, so the mapping is by analogy).

---

## Historical Timeline (by Decade)

### Pre-1990: Stage Set

- **Tcl** (John Ousterhout, UC Berkeley, late 1980s) creates the substrate for almost everything that follows. Expect (Don Libes) is built on top of Tcl to automate any interactive program — and the first real use case is **dial-up modem banks and Unix login automation**, not networking. Networking piggybacked on a general-purpose tool.
- Lesson: the biggest tools in this lineage were not built _for_ networking. They were built for "automate interactive CLI" and networking adopted them.

### 1990s: The Expect Era

- **1992-1997**: Expect becomes the de-facto automation layer for Cisco IOS devices. Don Libes documents month-long tasks being compressed to an hour ([Tcler's Wiki, Expect](https://wiki.tcl-lang.org/page/Expect)).
- **Cisco IOS 12.x** (late 1990s) embeds a Tcl interpreter directly in the OS, which eventually becomes **Embedded Event Manager (EEM)** — arguably the first "event-driven network automation" that actually shipped ([Cisco Press, EEM](https://www.ciscopress.com/articles/article.asp?p=3100057&seqNum=4)).
- **1997**: RANCID ("Really Awesome New Cisco confIg Differ") is released by Shrubbery Networks — written in Expect + Perl, stores configs in CVS, diffs on every run, emails ops teams ([Shrubbery Networks, RANCID](https://shrubbery.net/rancid/); [Wikipedia, RANCID](<https://en.wikipedia.org/wiki/RANCID_(software)>)). **Still running in production in 2026.** 29-year-old codebase.
- **Late 1990s**: HP OpenView + Network Node Manager dominate enterprise. SNMP polls + MIB browsers define the "observability" half of the story ([HP Network Management Center, Wikipedia](https://en.wikipedia.org/wiki/HP_Network_Management_Center)).

### 2000s: The Enterprise Platform Decade (Mostly Failed)

- **Loudcloud → Opsware** (1999 → 2002 pivot). Marc Andreessen / Ben Horowitz build enterprise data-center automation. Ships Server Automation System (SAS), Network Automation System (NAS), Process Automation System (PAS). HP acquires for **$1.65B in 2007** ([Opsware, Wikipedia](https://en.wikipedia.org/wiki/Opsware); [Network World, HP's billion-dollar buys](https://www.networkworld.com/article/2239219/hp-s-history-of-billion-dollar-technology-buys.html)).
- **BladeLogic** (parallel track). BMC acquires for **$800M in 2007**, price explicitly driven up by HP+Opsware deal.
- **Kiwi CatTools** (SolarWinds acquires) — a lightweight, Expect-style per-device config archive and bulk-push tool. Still sold in 2026 as the "SMB entry-level" option while SolarWinds tries to funnel customers to Orion NCM ([SolarWinds, Kiwi CatTools](https://www.solarwinds.com/kiwi-cattools)).
- **Cisco/Juniper vendor scripting**: Juniper releases **SLAX** in Junos 8.2 (≈2007) as a C/Perl-style overlay on XSLT for on-box scripting ([Juniper, SLAX Overview](https://www.juniper.net/documentation/us/en/software/junos/automation-scripting/topics/concept/junos-script-automation-slax-overview.html)). Later displaced by Python + PyEZ, but SLAX scripts from 2008 still run in 2026 boxes.
- **Late 2000s**: Puppet (2005) and Chef (2009) emerge for servers. Both later attempt to extend to network devices (Puppet device, proxy-agent model) — and both quietly fail in the network vertical (details in Failed Attempts below).

### 2010s: The SDN Hype → NetDevOps Reality Arc

- **2008-2011**: **OpenFlow** emerges from Stanford (Nick McKeown, Martin Casado). "SDN" as a term arrives a year after the protocol. By 2011, every vendor has an "SDN strategy" slide ([Grotto Networking, SDN Overview](https://www.grotto-networking.com/BBSDNOverview.html); [SDxCentral, Intent-Based Networking](https://www.sdxcentral.com/articles/news/intent-based-networking-whats-real-whats-hype/2017/09/)).
- **2012**: VMware acquires Nicira (Casado's company) for **$1.26B**. This is the _commercial_ crown of the SDN decade and becomes VMware NSX. The "pure OpenFlow commodity-switch" vision largely dies here; network virtualization (overlay) is what actually ships.
- **2013**: Cisco launches **onePK** (One Platform Kit) — C/Java/Python APIs into routers. Documentation stops being generated around August 2014. Quietly displaced by NETCONF/YANG and DNA Center ([Cisco Blog, onePK](https://blogs.cisco.com/security/ciscos-onepk-part-1-introduction)).
- **2014**: Cisco acquires **Tail-f**, which becomes NSO (Network Services Orchestrator). Tail-f had been the co-authors of NETCONF and YANG. NSO is the genuine survivor of the 2010s vendor-orchestration wave because it abstracts devices rather than prescribing a new control plane ([Cisco DevNet, NSO](https://developer.cisco.com/docs/nso-guides-5.7/nso-introduction/); [NIL, Cisco NSO](https://nil.com/en/solutions/networking/network-service-orchestration-nso/)).
- **October 2015**: Red Hat acquires Ansible. This is the single biggest catalytic moment for _actual_ network automation adoption. Ansible's "agentless, run-on-control-node, SSH-native" model fits network devices that couldn't run Python. 60+ network modules emerge; cisco.ios, arista.eos, junos, nxos become collections ([Ansible Docs, Network Automation](https://docs.ansible.com/projects/ansible/latest/network/index.html); [Ipspace.net, Ansible Network Automation 2025](https://blog.ipspace.net/2025/12/ansible-abandoned-network-automation/)).
- **Late 2014**: **Jason Edelman founds Network to Code**. The "NetDevOps" term crystallizes around Ansible + NAPALM + Netmiko + Git + Jenkins. First network-automation-specific training programs start ([Network to Code, Our Journey](https://networktocode.com/company/our-journey/)).
- **2016**: NetBox released (Jeremy Stretch at DigitalOcean), becoming the canonical "source of truth" for network infrastructure. **NetDevOps Survey** starts under Network to Code and Juniper ([Network to Code, NetDevOps Survey 2019](https://networktocode.com/blog/state-network-operations-netdevops-survey-2019/)).
- **2016**: **OpenConfig** starts publishing vendor-neutral YANG models. Google, AT&T, Microsoft driving ([OpenConfig, Models](https://www.openconfig.net/projects/models/)).
- **2017**: **Apstra** launches, coins "Intent-Based Networking." Cisco's CEO says IBN will "redefine networking for the next 30 years." Gartner forecasts 1000+ enterprises by 2020 ([SDxCentral, IBN Hype](https://www.sdxcentral.com/articles/news/intent-based-networking-whats-real-whats-hype/2017/09/)). Juniper acquires Apstra in 2021.
- **2018**: **Nornir** (David Barroso, Mircea Ulinic, Kirk Byers, Dmitry Figol) — a pure-Python network automation framework, positioned as a "library not a framework." By the 2019 NetDevOps Survey, ~10% of respondents use it alongside Ansible.
- **September 2017**: Red Hat open-sources Tower as **AWX**. Upstream/downstream split (like Fedora/RHEL) ([Red Hat, AWX](https://www.redhat.com/en/ansible-collaborative/awx); [GitHub, ansible/awx](https://github.com/ansible/awx)).

### 2020s: GitOps, Crossplane, LLMs

- **2020-2022**: Terraform + Crossplane + Argo CD + Flux define "GitOps for infra." Cloud-first. Devices gradually modeled as Terraform resources (Cloudflare, Cloudamqp, Fortinet providers emerge).
- **2022**: **Atom officially sunset** by GitHub. VS Code + Electron + LSP is the plugin ecosystem that survived ([Crazy Egg, Atom vs. VS Code](https://www.crazyegg.com/blog/atom-vs-visual-studio-code/)).
- **2023-2025**: LLM-based network ops tools emerge (Itential, NetBrain Copilot, etc.). Ansible Core 2.19 (2025) broke most network modules via netcommon changes — the NetDevOps community reacts with "has Ansible abandoned networking?" ([Ipspace.net, Dec 2025](https://blog.ipspace.net/2025/12/ansible-abandoned-network-automation/)).
- **2024-2026**: MCP (Model Context Protocol), Claude/Cursor/Codex/opencode plugin ecosystems emerge. `ycc` sits in this wave.

---

## Failed Attempts (with Root Causes)

### 1. Cisco onePK (2012-2014, quietly end-of-lifed)

**What it was**: Cisco's first real developer-facing SDK into IOS/IOS-XE/NX-OS. Library-based (C, Java, Python roadmap), accessed routing tables, policy, packet datapath.

**Why it died**:

- **API evolutionism**: Cisco Blog Part 1 explicitly warned developers the API would change before GA ([Cisco Blog, onePK Part 1](https://blogs.cisco.com/security/ciscos-onepk-part-1-introduction)). Developers didn't invest.
- **Standards-based alternatives were coming**: NETCONF + YANG (IETF) + OpenConfig were on the near horizon and didn't require Cisco-specific SDK installation.
- **Vendor-lock suspicion**: Multi-vendor shops wouldn't commit to a Cisco-only abstraction.

**Documentation stopped generating August 2014.** Within two years, Cisco's messaging shifted to NETCONF/YANG + DNA Center + NSO.

**Lesson for `ycc`**: Vendor-specific skills that wrap vendor-specific SDKs inherit the SDK's lifecycle risk. Build against standards (NETCONF, gNMI, YANG) or against operator workflows (diff/review), not against ephemeral vendor APIs.

Confidence: **High**. Primary evidence is stale documentation timestamp + ecosystem's silence.

### 2. Puppet's Network Device Model (2012-2019, deprecated)

**What it was**: Puppet agents acted as proxies for devices that couldn't run Puppet. Certificate exchange, fact collection, catalog retrieval for each device ([Puppet Blog, Managing network devices](https://puppet.com/blog/managing-network-devices-in-puppet-enterprise/)).

**Why it died**:

- **Proxy-agent complexity dwarfed the task.** Network ops needed "push config, verify, diff" — Puppet gave them certificate management.
- **Pull-based model is wrong for devices.** Servers can tolerate a 30-minute catalog run; network devices have change windows measured in minutes.
- **Per-vendor module fragmentation** without a unifying abstraction. Puppet Enterprise 2019 explicitly deprecated the network device agent model in favor of tasks + Bolt + Transports ([Puppet, Deprecations](https://puppet.com/docs/pe/2019.0/deprecations_and_removals.html)).

**Lesson for `ycc`**: Don't import a data-center abstraction into the network domain wholesale. The change-window / blast-radius / vendor-heterogeneity profile is fundamentally different.

Confidence: **High**. Puppet itself documented the failure by deprecating the model.

### 3. TOSCA / OASIS Cloud Orchestration (2014-2025, alive-but-marginal)

**What it was**: OASIS standard for cloud-application topology. TOSCA 1.0 (2014), 1.3 (2020), 2.0 (2025) ([OASIS TOSCA TC](https://www.oasis-open.org/committees/tc_home.php?wg_abbrev=tosca); [OASIS TOSCA, Wikipedia](https://en.wikipedia.org/wiki/OASIS_TOSCA)).

**Why it's marginal**:

- **CloudFormation and Terraform shipped first and shipped simpler.** Portability across clouds (TOSCA's pitch) was always less valuable than speed on the one cloud you actually use.
- **Cloud-native (Kubernetes + Helm + Operators) ate the declarative-topology space.** TOSCA's 2.0 charter explicitly lists "align with cloud-native standards" as a goal in 2025 — an implicit admission it didn't in the preceding decade.
- **Committee-designed standard vs. operator-designed tool.** Terraform was "what HashiCorp thought was useful"; TOSCA was "what 20 vendors agreed on." The first wins.

**Lesson for `ycc`**: Standards committees optimize for inclusion; operators optimize for working on Tuesday. A Claude skill designed by committee consensus (every vendor represented) will almost certainly lose to a skill designed around a single sharp workflow.

Confidence: **High** on the market-share claim; **Medium** on attributing it to committee dynamics specifically.

### 4. OpenFlow-Centric SDN (2011-2015, transformed rather than failed)

**What happened**: In 2011, the "commodity switch driven by universal controller" vision hit Gartner's Peak of Inflated Expectations. By 2013, pure-OpenFlow networks were running into flow-setup-time bottlenecks, chipset incompatibilities, no fast-failover mechanism ([Grotto Networking, SDN](https://www.grotto-networking.com/BBSDNOverview.html); [High Scalability, OpenFlow not a silver bullet](https://highscalability.com/openflowsdn-is-not-a-silver-bullet-for-network-scalability/)). The ideas survived — in overlay virtualization (NSX, OVN), hyperscaler internal networks (Google B4), and gNMI/NETCONF — but the original architecture didn't.

**Lesson for `ycc`**: "Revolutionary platform" plays almost always fail _as platforms_ but leave useful primitives. A Claude-side artifact that tries to be an "AI network ops platform" will probably lose; the primitives it ships (diff, review, policy-as-code) will survive.

Confidence: **High**. Well-documented hype cycle.

### 5. Puppet/Chef vs. Ansible (2014-2016, the real NetDevOps winner was decided here)

**What happened**: Puppet and Chef had ~5-7 year lead on Ansible. When Red Hat acquired Ansible in 2015, the market for _network_ automation was still completely open. Ansible won the network vertical because:

- **No agent required** on devices (SSH/NETCONF/REST from control node).
- **YAML playbooks** had a lower learning curve than Puppet's DSL or Chef's Ruby.
- **Network engineers are not developers** (in the 2015 era) — they wanted declarative intent, not a compiled resource graph.

**Lesson for `ycc`**: Network engineers who came from ops (not dev) preferred the _lowest-ceremony_ tool. A Claude skill that imports developer-tool ceremony (git commit hooks, PR templates, complex YAML) into network ops will feel alien. Match the operator mental model.

Confidence: **High**. NetDevOps Survey 2019 shows Ansible at ~60% share vs. Puppet/Chef near-zero in networking.

### 6. HP Opsware + BladeLogic (2007-2017, acquired-and-absorbed)

**What happened**: Both got acquired at peak ($1.65B, $800M). Both got absorbed into big-vendor portfolios (HP Software → Micro Focus → OpenText 2023; BMC BladeLogic → TrueSight). Both are effectively frozen in time ([Keyva, Micro Focus Automation](https://keyvatech.com/2021/01/27/are-there-any-alternatives-to-hp-software-micro-focus-automation-tools/)).

**Lesson for `ycc`**: Even commercially successful infra-automation tools become legacy within ~10 years unless the maintainer community is independent. This is an argument _for_ open, plugin-style ecosystems over platforms — but also a reminder that long-term durability requires a community, not one maintainer.

Confidence: **High**. Public acquisition records and portfolio transitions.

### 7. Booklore (2026, canonical one-maintainer collapse)

**What happened**: Solo maintainer (ACX) started using AI-generated PRs (~20k line diffs), dismissed contributor PRs, banned users in Discord. Community trust collapsed in months ([XDA Developers, 2026](https://www.xda-developers.com/single-maintainer-open-source-ticking-time-bomb/)).

**Lesson for `ycc`**: Plausibly the most important single data point in this report. A one-maintainer plugin ecosystem expanding its scope _with AI-assisted development_ is exactly the archetype that just publicly failed. The failure was not about code quality — it was about community trust when one person holds all decision authority.

Confidence: **High**. Very recent, well-documented in mainstream tech press.

---

## Forgotten Alternatives (with Modern Relevance)

### RANCID's Simplicity — Still the Right Answer

**What it got right**:

- Read-only by default. "Pull config, diff, commit, email" — no push capability. Low blast radius.
- Version control was the storage layer. No database, no schema, no migration pain.
- Vendor heterogeneity handled by per-vendor Expect modules (rancid/bin/\*login) that are short, stable, and easily modifiable.
- Cron-friendly. Runs without a daemon.

**Modern relevance**: Oxidized (2013, Ruby) is a direct successor and acknowledges the lineage. In 2026, small-to-mid operators still use one or the other. **A `ycc` skill modeled on "RANCID-style archive + review" (read-only, diff-centric, git-as-storage) is the historically-validated archetype.**

Confidence: **High**.

### Kiwi CatTools — The "Tactical Tool" Class

**What it got right**: Stay focused on "SMB, ops person at a desk, needs to push a VLAN config to 8 switches before lunch." Reporting, bulk-push, backup — nothing more.

**What modern tooling often misses**: The ops person is not a platform engineer. Most enterprise "Network Automation Platforms" are over-engineered for the 80% of shops that just need scheduled backups and scheduled bulk-changes.

**Modern relevance**: A `ycc` skill targeted at the "5-to-50-device network, single operator" case would be historically underserved and differentiated. The enterprise vendors (NSO, DNA Center, Apstra) are all wrong for this user.

Confidence: **Medium-High**. Market segmentation evidence is strong; transfer to Claude-skill format is inferential.

### HP OpenView / Network Node Manager — Topology-Aware Context

**What it got right**: OpenView's mental model was "the network is a graph and we care about the edges and the root cause." Continuous spiral discovery + root cause analysis at the graph level.

**What modern tooling often misses**: Most NetDevOps is per-device. Topology-level reasoning ("this change on device A cascades to devices B, C, D") is rarely surfaced.

**Modern relevance for `ycc`**: A "blast-radius" skill that reasons about _topology_ before letting a user push a change would differentiate from the CLI-wrapper genre. This is the one place where LLM reasoning plausibly adds real value over 1997-era tooling.

Confidence: **Medium**. LLMs handling topology reasoning is unproven at scale.

### SLAX — The "Compile-Down" Philosophy

**What it got right**: SLAX was a thin syntactic overlay on XSLT. Juniper didn't try to build a new execution engine — they built a human-friendly syntax that compiled to the engine they already had.

**Modern relevance**: A `ycc` skill that _compiles down to Ansible / Terraform / vendor CLI_ rather than inventing a new execution layer would honor this lesson. "Claude generates the YAML, human reviews the YAML, Ansible executes the YAML."

Confidence: **High**.

### Tail-f / Cisco NSO — YANG as Lingua Franca

**What it got right**: NSO abstracts devices via NEDs (Network Element Drivers) that speak whatever the device speaks — NETCONF, REST, CLI, SNMP — and presents a uniform YANG-modeled surface above.

**Modern relevance**: A `ycc` skill that reasons over _YANG-modeled state_ (gNMI subscribe, NETCONF get-config) rather than raw CLI parsing would age much better. The NETCONF/YANG layer is now ~20 years old and still current; raw CLI parsing is the thing people quietly curse forever.

Confidence: **High**. NSO's continued use in Tier-1 SP networks is the proof.

---

## Temporal Patterns: The ~30-Year AI-In-Networking Revival Cycle

| Era            | Trigger                                                                      | Technology                                                                                                             | Why It Receded                                                                                       |
| -------------- | ---------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| **1980s**      | Expert systems + MYCIN-family rule engines. Cheap DEC minicomputers.         | Rule-based fault diagnosis for telecom networks (bell-labs, NYNEX). Deterministic "if X and Y then Z" troubleshooting. | Knowledge base brittleness. Every new device = manual rules. Fell apart as networks diversified.     |
| **Late 1990s** | Second-gen expert systems + Bayesian/probabilistic reasoning. SNMP ubiquity. | "Self-healing networks" first-wave (HP OpenView + vendor plugins).                                                     | Still rule-based underneath. Too expensive to maintain rulesets at enterprise scale.                 |
| **2000s**      | ML (decision trees, SVMs) becomes usable. NetFlow exists.                    | Early anomaly detection (Arbor Networks, etc.).                                                                        | Focused on security/DDoS specifically, not general ops. False-positive rate killed general adoption. |
| **2012-2018**  | SDN + centralized control. Telemetry streaming (gNMI).                       | ML-on-telemetry for closed-loop automation. "Intent-based networking."                                                 | Telemetry pipelines were the hard part, not the ML. Apstra/Forward/Veriflow ended up acquired.       |
| **2023-2026**  | LLMs. Cheap inference. MCP. Agentic frameworks.                              | AI copilots for network ops; LLM-generated configs; NL-to-ACL.                                                         | **TBD.** Currently peaking.                                                                          |

**The pattern**: Each wave is triggered by (cheaper compute OR a new abstraction) and killed by (device heterogeneity AND operator risk-aversion to delegating blast-radius decisions). The LLM wave's weakness will almost certainly be **hallucinated configs at commit time** combined with **operators learning, by one bad change window, that they can't trust the model near prod**.

**What this means for `ycc`**: Don't bet on LLM-as-sole-decision-maker. Bet on LLM-as-reviewer-and-explainer with the final action gated by a human and a diff. That's the pattern that historically survives each revival.

Confidence: **High** on the cycle existing. **Medium** on predicting the specific failure mode of the current LLM wave (it's still unfolding).

Sources: [Pigro.ai, AI History 1980s](https://www.pigro.ai/post/hysory-of-artificial-intelligence-the-1980s); [Medium, Expert Systems to Neural Networks](https://corradoignoti.medium.com/from-expert-systems-to-neural-networks-a-bit-of-history-of-ai-techniques-ca9c799a5e1d); [SDxCentral, Self-Healing Networks](https://www.sdxcentral.com/analysis/the-rise-of-the-self-healing-networks/).

---

## Plugin-Ecosystem Lessons (Atom → VS Code → JetBrains → Vim)

### Why Atom Died and VS Code Won

Three lessons, each directly applicable to `ycc`:

1. **Performance trumps features.** Atom had the better extension DX (Electron + JS), but was slow. VS Code built on the same stack, shipped faster Monaco-based core, and ate the market ([Roben Kleene, Era of VS Code](https://blog.robenkleene.com/2020/09/21/the-era-of-visual-studio-code/)).
2. **Lower authoring barrier compounds.** Sublime's Python plugin API was powerful; Atom/VS Code's JS/TS API had 10x the reachable developer pool. `ycc`'s Markdown-based skill format is the equivalent for the AI-plugin era — low barrier, broad reachable pool.
3. **Cross-product consolidation beats fragmentation.** JetBrains Marketplace took until 2018 to unify across IntelliJ/PyCharm/WebStorm/CLion/ReSharper/etc. Before that, fragmentation held authors back ([JetBrains Blog, Marketplace Celebrates 5 Years](https://blog.jetbrains.com/platform/2023/09/jetbrains-marketplace-celebrates-5-years/)). `ycc`'s cross-target story (Claude / Cursor / Codex / opencode via one source of truth) is doing the JetBrains move early, which is the right move.

### Why Vim's Ecosystem Is Perpetually Chaotic

Vim never had an official plugin system — just a `runtimepath`. 15+ years of plugin managers (Pathogen → Vundle → vim-plug → packer.nvim → lazy.nvim → built-in `vim.pack`) reflect the absence of a blessed path ([evgeni chasnovski, vim.pack guide](https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack/); [Quora, Best Vim Plugin Manager](https://www.quora.com/What-is-the-best-package-manager-for-Vim-plugins)).

**Lesson for `ycc`**: Having _one_ blessed bundle format with a clear source of truth beats a free-for-all. `ycc`'s current architecture (one plugin, generated compat bundles) is historically the winning move.

### Why JetBrains Marketplace Works

- Plugin Verifier tool catches compat issues before publish.
- Analytics for plugin authors (so they know what's working).
- Monetization path — the only major plugin ecosystem where plugin-as-business is real.
- Staff Picks curation — users discover more than they search.
- 7,000 → 8,860 plugins in ~5 years, across 15+ products ([JetBrains Annual Report](https://www.jetbrains.com/lp/annualreport-2022/)).

**Lesson for `ycc`**: Discovery and compatibility verification matter as much as the bundle itself. `ycc`'s compatibility-audit skill is the JetBrains move; a "staff picks" curation surface might be a future one.

### Why Single-Maintainer Plugin Ecosystems Collapse

- Tidelift 2020: 46% of maintainers burned out; 58% of widely-used projects' maintainers burned out.
- 61% of unpaid maintainers fly solo.
- Top two burnout drivers: **issue management** and **documentation maintenance**. Not coding. The administrative load of expanding scope is what kills solo projects ([Open Source Pledge, Burnout](https://opensourcepledge.com/blog/burnout-in-open-source-a-structural-problem-we-can-fix-together/); [RoamingPigs, Open Source Maintainer Burnout](https://roamingpigs.com/field-manual/open-source-maintainer-burnout/); [Socket.dev, Unpaid Backbone](https://socket.dev/blog/the-unpaid-backbone-of-open-source)).
- Canonical recent failure: **Kubernetes Ingress NGINX** — no security patches after March 2026, cited maintainer burnout.
- "Money doesn't fix it." External Secrets Operator had corporate sponsorships, still lost 4/5 maintainers ([Intel, Maintainer Burnout](https://www.intel.com/content/www/us/en/developer/articles/community/maintainer-burnout-a-problem-what-are-we-to-do.html)).

**Lesson for `ycc`**: This is the strongest single argument against scope expansion. If the one maintainer adds 10 more skills across networking / K8s / cloud / vendors, they are adding ~10× the issue-management and doc-maintenance surface area, with no corresponding increase in contributors. The empirical base rate on that move is grim.

---

## Key Insights (the non-obvious ones)

### Insight 1: The "new platform" is always the trap; the "old loop" is always the winner

Every successful network-automation tool in this 30-year history wrapped the diff-review-apply loop that RANCID pioneered in 1997. Every failed tool tried to replace that loop with something "better." SDN wanted to replace it with flow tables. onePK wanted to replace it with APIs. TOSCA wanted to replace it with topology models. None took. The loop is the product.

**Implication for `ycc`**: The highest-value network skills will be workflow-shaped, not vendor-shaped. "Review this config diff before I apply it" is a skill. "Cisco IOS expert" is a catalog of facts that vendor docs cover better.

### Insight 2: Network engineers are not developers and the abstractions don't cleanly map

Puppet died in networking because network engineers want push, not pull. Chef died because they want declarative, not procedural. Ansible won because it had almost no developer ceremony. This is the single biggest landmine for a dev-tool plugin expanding into networking: _the developer-tool assumptions are wrong_. PR workflows, unit tests, commit discipline — not the network operator's native idiom.

**Implication for `ycc`**: `ycc` is a dev-tool plugin ecosystem. Skills that graft dev-tool workflow onto network ops will feel alien. Skills that match the operator's actual flow (change window → diff → review → apply → rollback) will feel native.

### Insight 3: Vendor-specific tooling is where careers and codebases go to die

Juniper SLAX (2007-present): still supported, but nobody writes new scripts in it. Cisco onePK (2013-2014): dead. Puppet's Cisco module: superseded. Vendor tooling has a 5-10 year half-life because vendors rebrand product lines. Open standards (NETCONF, YANG, OpenConfig) have 20+ year lives.

**Implication for `ycc`**: Skills organized per-vendor ("cisco-expert", "fortinet-expert") will decay as vendors rebrand. Skills organized per-standard ("netconf-workflow", "yang-modeling") and per-workflow ("network-change-review") will age better.

### Insight 4: Single maintainers who expand verticals fail by administrative overload, not by coding failure

The empirical failure mode is boring: too many issues, too many PRs, too much documentation to keep current. It is _not_ "the code got bad." This means the right check before adding a skill is "can I maintain its docs and answer its issues for the next 3 years?" — not "can I write it?"

**Implication for `ycc`**: For each proposed new skill, the right question is: how many github issues does this domain generate? Cisco+Juniper+Fortinet+PA vendor skills plausibly generate 10x the issues of "network-change-review" because they're tied to shifting vendor behaviors. Choose low-issue-volume skills.

### Insight 5: AI-in-networking has always failed at the "trust at commit time" gate

Expert systems (1980s), self-healing networks (2000s), IBN (2017), LLMs (2024): every wave hit the same wall. Operators will use AI to _reason_ about a change; they will not let it _commit_ the change unsupervised. The successful pattern is "AI generates, human reviews, tool applies."

**Implication for `ycc`**: `ycc` skills should structurally preserve human-in-the-loop at the commit boundary. "Generate the change, write the diff to disk, print the blast-radius summary, wait for the human" — not "execute directly."

### Insight 6: The RANCID simplicity budget is the right budget

A single skill that does one thing well and doesn't try to be a platform is the winning archetype. RANCID is ~3k lines of Perl + Expect and has been in production for 29 years. The analog for `ycc` is a skill that is 1 `SKILL.md` + 1-3 helper scripts, focused on one workflow, with zero dependencies on vendor SDKs.

---

## Evidence Quality

**Primary sources**: 12

- Vendor documentation: Cisco DevNet onePK, Juniper Junos automation docs, Puppet docs, OASIS TOSCA spec, OpenConfig website, Cisco DevNet NSO guide, Ansible network docs, JetBrains Platform Blog posts, SolarWinds Kiwi CatTools docs, Red Hat AWX docs, Shrubbery RANCID site, Ansible/awx GitHub.

**Secondary sources** (authoritative practitioner writing): 14

- Ipspace.net (Ivan Pepelnjak's blog, 2017+2025), SDxCentral (SDN/IBN retrospectives), High Scalability (OpenFlow critique), Network World (HP acquisitions), Network to Code (NetDevOps Survey), Tcl-lang Wiki (Expect history), Jeff Geerling (Ansible + maintainer burden), JetBrains blog, Hacker News threads (Cisco internal Tcl tooling), O'Reilly (Tcl Scripting for Cisco IOS), Grotto Networking (SDN overview), Roben Kleene blog (Era of VS Code), DEV Community, MakeUseOf.

**Synthetic / speculative**: 6

- TechTarget, TechTarget, Medium posts on AI history, CBT Nuggets, Mindful Chase (Puppet troubleshooting). Treated as confirming rather than load-bearing.

**Overall confidence**: **High** on the historical claims (1990-2023). **Medium-High** on the plugin-ecosystem claims (well-documented). **Medium** on the direct `ycc` mapping (the Claude-plugin-as-genre is too young to have real failure data, so recommendations lean on analogical reasoning to Vim/Atom/JetBrains).

---

## Contradictions & Uncertainties

1. **"Ansible won networking" vs. "Ansible is abandoning networking."** The 2015-2019 data clearly shows Ansible winning. The 2025 breakage of network modules in Ansible Core 2.19 and the January 2028 deprecation of templated configs is cause for concern. _If_ Ansible Core pulls back from network modules, the NetDevOps stack has a successor problem and Nornir/raw-Python would fill it. This is actively unresolved in April 2026.

2. **"IBN is dead" vs. "IBN is table stakes."** In 2017, IBN was pitched as revolutionary. In 2026, Juniper Apstra's blog argues it's "no longer optional" — while Doyle Associates and others still characterize it as partly hype. Both claims are simultaneously true: the _concept_ is embedded in modern data-center products but the _marketing term_ is dead. What actually survived is declarative-with-continuous-reconciliation, which is just "GitOps for network fabric."

3. **"Vendor MCPs will replace vendor skills" — genuinely unknown.** If every network vendor ships an MCP server in 2026-2027 (Cisco, Fortinet, PA, Juniper), then Claude-side vendor skills are redundant. If vendors are slow (historically they have been — see onePK, see OpenConfig uptake), then Claude-side skills have a window. No primary evidence either way yet.

4. **"One-maintainer ecosystems always fail" — survivorship bias check.** Jeremy Stretch maintained NetBox solo for years and it flourished. Some one-maintainer projects do succeed. The failure mode is _vertical expansion under solo maintenance_, not solo maintenance itself. `ycc` at its current scope is sustainable; `ycc` + 10 vertical domains may not be.

5. **"LLM configs at commit time" — the current wave's specific failure mode is not yet observed at scale.** Might be hallucinated ACLs that pass lint and brick a prod firewall. Might be drift from intended state because the LLM reads outdated device state. The specific failure mode will matter but is not yet documented.

---

## Search Queries Executed

1. `history of network automation tooling Expect Tcl Cisco IOS 1990s origins`
2. `RANCID Oxidized network config archive history origins Shrubbery Networks`
3. `Ansible networking modules history 2015 origins network device automation timeline`
4. `Puppet network device modules failure why didn't take off history`
5. `Cisco onePK failed retrospective API history abandoned`
6. `OpenConfig adoption history YANG model vendor uptake challenges`
7. `NetDevOps origin history Jason Edelman Network to Code Nornir`
8. `Opsware BladeLogic HP Network Node Manager history datacenter automation`
9. `VS Code extension marketplace growth lessons history Atom migration Sublime`
10. `"software defined networking" SDN history OpenFlow failure hype cycle retrospective`
11. `expert systems network troubleshooting history 1990s AI self-healing networks`
12. `Juniper SLAX script automation history Junos PyEZ retrospective`
13. `Ansible Tower AWX fork drama community history Red Hat split`
14. `TOSCA OASIS orchestration standard adoption failure cloud native`
15. `Vim plugin ecosystem chaos fragmentation package manager history`
16. `JetBrains plugin marketplace history growth ecosystem lessons`
17. `single maintainer open source plugin project burnout failure patterns vertical expansion`
18. `ChatOps history Hubot GitHub network operations incident response origin`
19. `intent based networking history Apstra Forward Networks NEC hype cycle`
20. `Kiwi CatTools SolarWinds network configuration management history legacy`
21. `dev tool plugin ecosystem expand vertical DBA networking lessons cautionary`
22. `"Cisco NSO" "Tail-f" history NETCONF adoption service orchestration acquisition`

---

## Sources (Consolidated)

**Primary sources**:

- [Shrubbery Networks, RANCID](https://shrubbery.net/rancid/)
- [Cisco DevNet, NSO Introduction](https://developer.cisco.com/docs/nso-guides-5.7/nso-introduction/)
- [Juniper, SLAX Overview](https://www.juniper.net/documentation/us/en/software/junos/automation-scripting/topics/concept/junos-script-automation-slax-overview.html)
- [Juniper, Python automation scripts](https://www.juniper.net/documentation/us/en/software/junos/automation-scripting/topics/concept/junos-script-automation-python-scripts-overview.html)
- [Ansible Docs, Network Automation](https://docs.ansible.com/projects/ansible/latest/network/index.html)
- [Ansible Docs, How Network Automation is Different](https://docs.ansible.com/ansible/latest/network/getting_started/network_differences.html)
- [Red Hat, AWX project](https://www.redhat.com/en/ansible-collaborative/awx)
- [GitHub, ansible/awx](https://github.com/ansible/awx)
- [Puppet, Managing network devices in PE](https://puppet.com/blog/managing-network-devices-in-puppet-enterprise/)
- [Puppet, 2019.0 Deprecations](https://puppet.com/docs/pe/2019.0/deprecations_and_removals.html)
- [OASIS TOSCA TC](https://www.oasis-open.org/committees/tc_home.php?wg_abbrev=tosca)
- [OpenConfig, Data Models](https://www.openconfig.net/projects/models/)
- [Cisco Blog, onePK Part 1](https://blogs.cisco.com/security/ciscos-onepk-part-1-introduction)
- [SolarWinds, Kiwi CatTools](https://www.solarwinds.com/kiwi-cattools)

**Secondary sources**:

- [RANCID, Wikipedia](<https://en.wikipedia.org/wiki/RANCID_(software)>)
- [Opsware, Wikipedia](https://en.wikipedia.org/wiki/Opsware)
- [HP Network Management Center, Wikipedia](https://en.wikipedia.org/wiki/HP_Network_Management_Center)
- [OASIS TOSCA, Wikipedia](https://en.wikipedia.org/wiki/OASIS_TOSCA)
- [Tcler's Wiki, Expect](https://wiki.tcl-lang.org/page/Expect)
- [O'Reilly, Tcl Scripting for Cisco IOS](https://www.oreilly.com/library/view/tcl-scripting-for/9781587059551/ch01.html)
- [Network to Code, Our Journey](https://networktocode.com/company/our-journey/)
- [Network to Code, NetDevOps Survey 2019](https://networktocode.com/blog/state-network-operations-netdevops-survey-2019/)
- [Ipspace.net, Ansible Abandoned Network Automation (Dec 2025)](https://blog.ipspace.net/2025/12/ansible-abandoned-network-automation/)
- [Ipspace.net, Intent-Based Hype (2017)](https://blog.ipspace.net/2017/09/intent-based-hype/)
- [SDxCentral, Intent-Based Networking Hype](https://www.sdxcentral.com/articles/news/intent-based-networking-whats-real-whats-hype/2017/09/)
- [SDxCentral, Self-Healing Networks](https://www.sdxcentral.com/analysis/the-rise-of-the-self-healing-networks/)
- [Network World, HP's billion-dollar technology buys](https://www.networkworld.com/article/2239219/hp-s-history-of-billion-dollar-technology-buys.html)
- [Grotto Networking, SDN Overview](https://www.grotto-networking.com/BBSDNOverview.html)
- [High Scalability, OpenFlow not a silver bullet](https://highscalability.com/openflowsdn-is-not-a-silver-bullet-for-network-scalability/)
- [Roben Kleene, Era of VS Code](https://blog.robenkleene.com/2020/09/21/the-era-of-visual-studio-code/)
- [JetBrains Blog, Marketplace 5 Years](https://blog.jetbrains.com/platform/2023/09/jetbrains-marketplace-celebrates-5-years/)
- [JetBrains Marketplace Highlights 2023](https://blog.jetbrains.com/platform/2024/01/jetbrains-marketplace-highlights-of-2023-major-updates-community-news/)
- [Crazy Egg, Atom vs VS Code](https://www.crazyegg.com/blog/atom-vs-visual-studio-code/)
- [evgeni chasnovski, vim.pack guide](https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack/)
- [GitHub Blog, ChatOps at GitHub](https://github.blog/engineering/infrastructure/using-chatops-to-help-actions-on-call-engineers/)
- [Open Source Pledge, Burnout](https://opensourcepledge.com/blog/burnout-in-open-source-a-structural-problem-we-can-fix-together/)
- [RoamingPigs, Open Source Maintainer Burnout](https://roamingpigs.com/field-manual/open-source-maintainer-burnout/)
- [XDA Developers, Single-Maintainer Open Source (Booklore, 2026)](https://www.xda-developers.com/single-maintainer-open-source-ticking-time-bomb/)
- [Socket.dev, Unpaid Backbone of Open Source](https://socket.dev/blog/the-unpaid-backbone-of-open-source)
- [Intel Developer, Maintainer Burnout](https://www.intel.com/content/www/us/en/developer/articles/community/maintainer-burnout-a-problem-what-are-we-to-do.html)
- [Pigro.ai, AI History 1980s](https://www.pigro.ai/post/hysory-of-artificial-intelligence-the-1980s)
- [Medium, From Expert Systems to Neural Networks](https://corradoignoti.medium.com/from-expert-systems-to-neural-networks-a-bit-of-history-of-ai-techniques-ca9c799a5e1d)
- [Medium, 5 Dev Tools for Network Engineers (Oswalt)](https://oswalt.dev/2014/10/5-dev-tools-for-network-engineers/)
- [NIL, Cisco NSO](https://nil.com/en/solutions/networking/network-service-orchestration-nso/)
- [WWT, IBN No Longer Optional](https://www.wwt.com/blog/intent-based-networking-is-no-longer-optional-why-juniper-apstra-is-winning-in-the-modern-data-center)
- [Cisco Press, EEM](https://www.ciscopress.com/articles/article.asp?p=3100057&seqNum=4)
- [Oxidized GitHub](https://github.com/ytti/oxidized)
