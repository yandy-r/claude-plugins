# Archaeologist Findings: Past Solutions for Device-Config and Infra Automation (1995–2015)

**Persona**: Archaeologist
**Subject**: Network device configuration management, multi-device change orchestration, config-drift detection, rollback/safety patterns, inventory management, and operational rituals — from the pre-cloud era — informing what an AI-assistant plugin bundle (`ycc`) should offer in 2026.
**Date**: 2026-04-20

---

## Executive Summary

The pre-cloud era (roughly 1995–2015) produced a mature, opinionated set of disciplines for surviving "the wrong command on the wrong device at 3 AM." Most of those disciplines were embedded in tools that are now retired, obscure, or superseded (RANCID, Kiwi CatTools, CiscoWorks RME, Opsware/BladeLogic, ESX Service Console, Xen xend, ScreenOS). The tools went away; the **failure modes they addressed did not**.

Three patterns stand out as strong Claude-native revival candidates:

1. **RANCID's "diff-and-email" loop** — a daily cron that logs in, runs a fixed command menu, sanitizes volatile fields, commits to VCS, and emails unified diffs. This is still the only reliable way to detect "someone changed the config outside of the pipeline." A Claude-native equivalent is a drift-watcher skill + `/ycc:config-drift` command.
2. **The MOP (Method of Procedure) ritual** — a structured pre-change artifact containing objective, scope, prerequisites, tools, safety precautions, step-by-step commands, **rollback commands**, and completion criteria. GitOps replaces _some_ of this (peer review, version control) but not the `cat << EOF` of the exact rollback command an exhausted oncall runs at 3 AM. A Claude-native `/ycc:mop` command generates a real MOP from a diff.
3. **Expect-era "login + cook + diff"** prompt-matching discipline — still relevant because every firewall, load balancer, out-of-band console server, and legacy access switch in 2026 still offers only CLI and no NETCONF.

Three older patterns explicitly **should not** be revived: stateful monolithic toolstacks (xend, nat-control, COS service consoles), plaintext credential files (RANCID's `.cloginrc`), and vendor-lock monolithic NMS suites (CiscoWorks LMS, HP OpenView). Their replacements (GitOps, vault-backed secrets, best-of-breed composable tools) are strictly better.

The heart of the finding: **modern tools assume APIs and declarative state; real-world 2026 networks still contain 20–40% screen-scrape territory.** A Claude plugin bundle that pretends otherwise will miss the wildest, most error-prone half of the work.

---

## Old Solutions (Per Decade)

### 1995–2000: The Expect/TCL + CVS era

- **RANCID (1997, Shrubbery Networks)**: Expect-script login to a device list (`router.db`), fixed command sequence per platform, output "cooking" (stripping volatile lines like chassis temperature, re-ordered MACs, session-nonce values), commit to CVS, email unified diff to operators. Multi-vendor from day one (Cisco, Juniper, HP, Foundry, F5, NetScreen, Fortinet). Still maintained. ([Wikipedia](<https://en.wikipedia.org/wiki/RANCID_(software)>); [Shrubbery](https://shrubbery.net/rancid/))
- **Expect (Don Libes, O'Reilly 1994 book "Exploring Expect")**: The underlying TCL extension that made all of this possible. Pattern: `expect "Username:" { send "$user\r" }` + `expect "#" { send "terminal length 0\r" }` + loop over command list. Everyone's scripts still carry the "slow and random typing rate" assumption from Expect's original design.
- **Cisco IOS native "alias" command**: short mnemonic → long command. Used by operators to build "`alias exec wr sh run`" and "`alias exec err sh log | inc %`" style shortcuts on the device itself.

### 2000–2005: Big iron NMS + the birth of Smart Policy

- **CiscoWorks Resource Manager Essentials (RME) and LAN Management Solution (LMS)** — browser-based, database-backed multi-device mgmt. Offered a _Configuration Archive_, _Change Audit_ (timestamped diff trail with "who/what/when/through which channel"), and _exception reporting_ for changes outside approved windows. All versions are now retired. ([Cisco retirement notice](https://www.cisco.com/c/en/us/obsolete/cloud-systems-management/ciscoworks-resource-manager-essentials.html); [RME 4.3 datasheet](https://www.cisco.com/c/en/us/products/collateral/cloud-systems-management/ciscoworks-resource-manager-essentials-4-3/data_sheet_c78-533419.html))
- **HP OpenView / NNM** — SNMP-based topology + fault correlation + MIB browser. Massive, Tcl/Jovial scriptable, universally hated, universally deployed.
- **Cisco PIX + "conduit" command → ACL migration (PIX 5.3)**: the historical moment ACLs replaced conduits on PIX. Left a decade-long trail of "backward-compatible but discouraged" configs. ([eTutorials PIX ACLs](https://etutorials.org/Networking/Cisco+Certified+Security+Professional+Certification/Part+IV+PIX+Firewalls/Chapter+19+Access+Through+the+PIX+Firewall/Access+Control+Lists+ACLs/))
- **NetScreen ScreenOS** (pre-Juniper acquisition era) — zone-based firewall with its own CLI idioms (`set policy id N from "Trust" to "Untrust" "src" "dst" "svc" permit`). Now End-of-Everything but many `.screenos` configs still live on in museum racks. ([Weberblog ScreenOS CLI](https://weberblog.net/cli-commands-for-troubleshooting-juniper-screenos-firewalls/))
- **Check Point smart policy (SmartCenter)** — object-oriented rule base, NAT policy as a separate ordered table, policy compilation & install model. One of the first "change = package + push" paradigms in firewalls.

### 2005–2010: Server automation + service console era

- **Opsware (pivoted from Loudcloud 2002, acquired by HP July 2007 for $1.65B)** — agent-based server lifecycle management, via strategic acquisitions: Rendition Networks (2005) for network CM, CreekPath (2006) for storage, iConclude (2007) for runbook automation. Marc Andreessen / Ben Horowitz. Downstream odyssey: HP → HPE → Micro Focus → OpenText (2023). ([Wikipedia: Opsware](https://en.wikipedia.org/wiki/Opsware); [Acquired.fm](https://www.acquired.fm/episodes/episode-42-opsware-with-special-guest-michel-feaster))
- **BladeLogic (acquired by BMC 2008)** — three-tier agent-based SA. Claimed enterprises with 150,000+ servers under one instance. Rebranded to TrueSight. ([BMC docs](https://docs.bmc.com/xwiki/bin/view/Automation-DevSecOps/Server-Automation/Server-Automation/bsadoc/Getting-started/Getting-started-with-automation/How-does-BSA-work/))
- **VMware ESX Service Console (COS)** — vestigial Linux VM as management plane. Ran `esxcfg-*` tools, hosted vendor agents (Symantec backup, Dell OpenManage, etc.). Deprecated with ESX 4.1 (2010), removed from ESXi 5.0 (2011). ([vMiss](https://vmiss.net/esx-vs-esxi/); [VirtualG.uk](https://virtualg.uk/the-history-of-vmware-esxi-2001-to-2025/))
- **Kiwi CatTools (SolarWinds, ~2005 onward)** — Windows desktop app. Scheduled backup, side-by-side diff with color highlighting, bulk config push, email alerts on unauthorized change, built-in TFTP server, 5-device free tier. Entry-level small-shop companion to the enterprise RANCID / RME / NCM split. ([SolarWinds](https://www.solarwinds.com/kiwi-cattools))
- **Cisco IOS Embedded Event Manager (EEM)**: on-box Tcl scripting reacting to syslog events, counter thresholds, CLI patterns. Used for self-healing scripts like "if BGP neighbor flap > 3/min, shut interface and email NOC."

### 2010–2015: Pre-GitOps transition

- **Oxidized (Ruby, ytti)** — RANCID replacement. Modular sources (CSV, SQLite, MySQL, HTTP) ↔ outputs (File, GIT, git-crypt, HTTP), built-in web UI, native Git, no plaintext `.cloginrc`. ([Oxidized GitHub](https://github.com/ytti/oxidized); [rConfig comparison](https://www.rconfig.com/blog/oxidized-vs-rancid-a-feature-comparison))
- **Xen transition xend → xl/libxl** — stateful xend (Xen 2.x–4.4) replaced by stateless libxl/xl (default Xen 4.2, xend removed 4.5). Triggered mass migration of management tooling. ([Xen wiki](https://wiki.xenproject.org/wiki/XL_in_Xen_4.2); [SUSE virt guide](https://documentation.suse.com/sles/15-SP7/html/SLES-all/cha-xmtoxl.html))
- **Proxmox VE origins (2008)** — Dietmar & Martin Maurer built the Debian-based GUI + backup layer OpenVZ lacked, later merging KVM. The "we built the management UI the upstream project refused to ship" pattern. ([ServerMania](https://www.servermania.com/kb/articles/xen-vs-proxmox))
- **PIX/ASA 8.3 breaking change (2010)** — ACLs flipped from matching post-NAT (translated) addresses to pre-NAT (real) addresses. `nat-control` went away, `object-group` became mandatory. Single biggest real-world "rollback plan or die" migration in firewall history. ([PeteNetLive](https://www.petenetlive.com/KB/Article/0000247))
- **NETCONF (RFC 6241, 2011) + YANG (RFC 6020, 2010)** — model-driven network management arrives. OpenConfig consortium (2014) tries for vendor-neutral YANG models.

---

## Obsolete Approaches (With Honest Reason for Discontinuation)

| Approach                                                           | Why It Died                                                                       | Still Applies?                                                       |
| ------------------------------------------------------------------ | --------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| Stateful monolithic toolstacks (xend, CiscoWorks LMS, HP OpenView) | Fragile state recovery, vendor lock-in, huge ops surface                          | No — replaced by stateless composable tools                          |
| Plaintext credential files (`.cloginrc`)                           | Manifestly unsafe; vault solutions now table stakes                               | No — always use vaulted secrets                                      |
| Service console as mgmt plane (ESX COS)                            | Patching surface, Linux attack surface, hypervisor should be minimal              | No — API-first management won                                        |
| Vendor "NMS" for everything (CiscoWorks, HP NNM)                   | Expensive, single-vendor assumptions, couldn't scale to multi-vendor/multi-cloud  | No — best-of-breed composable won                                    |
| Conduit-based firewall rules (PIX pre-5.3)                         | Too permissive; ACL granularity needed                                            | No — ACLs won                                                        |
| Post-NAT ACL matching (PIX pre-8.3)                                | Counter-intuitive; huge source of real-world firewall errors                      | Partial — legacy configs still exist in 2026                         |
| Running-config only (no startup save)                              | `copy run start` forgetting = config gone on reboot. Classic new-engineer mistake | **Still happens.** A Claude-native pre-commit check would catch it   |
| Human-rate screen scraping (RANCID's deliberate slow typing)       | CPUs got fast; no longer needed                                                   | Mostly no — but some old devices still drop input if pushed too fast |
| Tcl EEM on-box scripting                                           | Model-driven telemetry + off-box orchestration replaced it                        | No — but event-driven triggers are back with Claude hooks            |
| SNMP as configuration protocol                                     | Designed for monitoring, abused for config; SET was always broken                 | No — NETCONF/gNMI won for config                                     |

---

## Discontinued Methods Worth Reviving

### 1. RANCID's "cook the output" discipline

**What it is**: before diffing, strip volatile fields (chassis temp, reorder-happy MAC tables, sessionids, last-seen-timestamps, crypto-nonces) so diffs surface _real_ config changes only.
**Why it matters in 2026**: modern config-drift tools produce massive noisy diffs because they don't know what fields oscillate. Every practitioner re-learns this.
**Revival form**: `ycc/skills/config-diff-cooking/` + `_shared/scripts/cook-diff.sh` — a library of per-vendor regex filters applied before surfacing a diff to the user/PR.

### 2. MOP as an artifact, not a slide

**What it is**: a structured pre-change document. Objective, scope, prerequisites, tools, safety precautions, step-by-step commands, **exact rollback commands**, completion criteria, sign-off roles. Military origin. ([Tempo MOP glossary](https://www.tempo.io/glossary/method-of-procedure); [DataBank MOP article](https://www.databank.com/resources/blogs/method-of-procedure-mop-what-it-is-why-it-matters-and-how-databank-manages-it/))
**Why it matters in 2026**: PR descriptions aren't MOPs. A reviewer can't reconstruct rollback from a diff alone — especially for multi-device orchestrated changes.
**Revival form**: `/ycc:mop` command that takes a feature spec or diff and produces `docs/mops/<date>-<change>.md` with the full structure, including a dry-run plan, blast-radius estimate, and the literal command to revert.

### 3. Pre/Post check discipline

**What it is**: capture `show bgp summary | include Idle|Active`, `show ip route summary`, `show ip int br | ex una`, etc. **before** change; re-capture **after**; diff. Anything that wasn't already broken but now is is your bug.
**Why it matters in 2026**: even with NETCONF, operators skip this. The "service console reboot for unrelated reason during change window" story is older than GitOps and still common.
**Revival form**: `/ycc:pre-check` and `/ycc:post-check` commands, or a `network-change` skill that prompts for pre-check commands, stores them, and auto-diffs post-change.

### 4. The `copy run start` / `write memory` guard

**What it is**: Cisco IOS has two configs — running and startup. Commit to running ≠ persisted. A reboot wipes it. Every network engineer has lost a config this way.
**Why it matters in 2026**: still happens with NX-OS, IOS-XE; Arista EOS auto-saves, which ironically **is worse** because it means config-drift persists silently.
**Revival form**: a `/ycc:commit-config` command that, after any change, runs `copy run start` or equivalent for each vendor, captures the checksum, and records the commit in the device inventory.

### 5. Trigger-on-syslog change detection

**What it is**: RANCID/CatTools polled; Cisco EEM could react to the specific syslog line `%SYS-5-CONFIG_I` (user-initiated config change) and immediately snapshot. Near-real-time drift detection.
**Why it matters in 2026**: polling-based drift detection has a blind window. Event-driven is strictly better for security (who typed what when, outside the pipeline).
**Revival form**: a Claude hook + skill combo — `ycc:drift-watcher` that listens to a syslog stream (or SNMP trap, or NETCONF notification) and triggers a `/ycc:config-drift` workflow, which runs a RANCID-style cook + diff + commit + alert.

### 6. Change window discipline

**What it is**: define the narrow time band when changes are allowed; changes outside that window are "exceptions" that require extra sign-off. CiscoWorks RME's "Change Audit" flagged these automatically.
**Why it matters in 2026**: many orgs have regressed to "deploy whenever." For regulated industries (telecom, banking, healthcare), change windows are non-negotiable and undermined by unrestricted CI/CD.
**Revival form**: optional `change-window.yaml` repo policy consumed by `/ycc:mop` and `/ycc:code-review` — warns if a PR targets production outside the window.

### 7. `router.db` — the simplest device inventory that works

**What it is**: a flat file, one line per device: `name;vendor;state`. No schema, no DB, no YAML indentation hell. RANCID's inventory format. Version-controllable. Readable by `awk`. 20 years later, NetBox users still re-invent it poorly.
**Why it matters in 2026**: YAML/JSON inventories in Ansible/Nornir have genuine operational drawbacks (diff noise, parser errors on subtle indentation). A simple `.tsv` inventory is often _better_ for small-to-medium fleets.
**Revival form**: `ycc/skills/network-inventory/` that defaults to a RANCID-compatible flat file and transparently parses YAML/JSON/NetBox for bigger shops.

### 8. Looking-glass pattern

**What it is**: read-only web interface that runs `show ...` commands without giving users SSH. RANCID ships one. Everyone in BGP/peering operations ran one.
**Why it matters in 2026**: still the safest way to give junior engineers, customers, or auditors "just enough" visibility without shell access.
**Revival form**: `/ycc:show <device> <command>` skill that enforces read-only verbs, logs every invocation, and returns cooked output.

---

## Historical Constraints (And Whether They Still Apply)

| Constraint                                | 1995–2015               | 2026                                                                                                                                                                                                                                                                                                                                                             |
| ----------------------------------------- | ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Many devices have only CLI, no API        | True for ~100%          | True for ~20–40% (firewalls, legacy, OOB consoles, IoT, SD-WAN edge) — **still load-bearing**                                                                                                                                                                                                                                                                    |
| Slow serial/OOB console links             | Common                  | Rare in datacenter, **universal in OOB/fallback paths**                                                                                                                                                                                                                                                                                                          |
| Credentials in plaintext config files     | Standard practice       | Gross malpractice — vault or die                                                                                                                                                                                                                                                                                                                                 |
| Weekly/monthly change windows             | Universal               | Common in telco/banking, rare in SaaS — **context matters**                                                                                                                                                                                                                                                                                                      |
| Configs are snowflakes with no templating | Common                  | Rare (templates won) — except for the 20% that are hand-tuned around vendor bugs                                                                                                                                                                                                                                                                                 |
| Multi-vendor abstraction is impossible    | Largely true            | Partly solved by OpenConfig/YANG but **still requires vendor-specific fallback**. OpenConfig coverage is incomplete; Cisco IOS-XR vs IOS-XE vs NX-OS still diverge in YANG structure. ([karneliuk.com](https://karneliuk.com/2022/07/automation-15-the-good-the-bad-and-the-ugly-of-model-driven-network-automation-featuring-cisco-nokia-and-openconfig-yang/)) |
| "Copy run start" as a separate step       | Universal Cisco pattern | Still Cisco, still forgotten, still breaks things                                                                                                                                                                                                                                                                                                                |
| Diff is the only ground truth for change  | True                    | Still true — every tool that abandoned diff regretted it                                                                                                                                                                                                                                                                                                         |

---

## Forgotten Wisdom

- **"Cook the output before diffing."** The single most overlooked detail in modern drift detection tooling.
- **"The rollback is the plan."** RANCID's archive **is** the rollback — grep for the last known-good, paste it. A MOP without rollback commands is not a MOP.
- **"One line per device in a flat file."** `router.db`'s simplicity is a feature, not a limitation.
- **"Email is a UX."** RANCID's `rancid-admin-<group>` distribution list is a better operator surface than any dashboard: pushes to you, threaded, searchable, auditable, works on mobile.
- **"Screen-scrape is forever."** Every vendor promised API-first; every one ships at least one device that doesn't have it. The CLI-automation muscle is still core engineering skill.
- **"Prompt match is fragile."** An extra space between "v3" and "privacy" in a firmware upgrade breaks the regex and the script silently does the wrong thing. ([Lindsay Hill, "Why Screen Scraping Sucks"](https://lkhill.com/why-screen-scraping-sucks/))
- **"Change windows save lives."** They weren't bureaucracy; they were the only moment on-call staffing matched risk exposure.
- **"The state of the network is what the network says it is."** Trust the device's own running-config; your source-of-truth DB lies. RANCID was built on this axiom.

---

## Revival Candidates (Ranked)

Each entry: **old idea + modern Claude-native twist + failure mode prevented + form in ycc**.

### P0 — High-value, low-maintenance

1. **Cook-and-diff config drift watcher**
   _Old_: RANCID's daily cron with output cooking.
   _Modern twist_: a `ycc:config-drift` skill + optional `/ycc:config-drift` command that takes a device, pulls current config via SSH/NETCONF/gNMI, cooks it with vendor-specific regex, diffs against the last committed version in a repo, and opens a PR or alert. Can be scheduled by `cron` skill.
   _Failure prevented_: "someone changed the firewall last Tuesday and we've been chasing phantom packet loss for 3 days."
   _Form_: skill + command + `_shared/scripts/cook-diff.sh`. Effort: M. Value: High.

2. **`/ycc:mop` — MOP generator from a diff**
   _Old_: Method of Procedure discipline.
   _Modern twist_: takes a proposed diff or PR, generates a full MOP with objective, prerequisites, pre-check commands, step-by-step apply commands, **exact rollback commands**, post-check commands, completion criteria, and blast-radius estimate. Writes to `docs/mops/<date>-<feature>.md`.
   _Failure prevented_: "the PR was approved but nobody wrote down how to undo it; now we're restoring from 36-hour-old snapshots."
   _Form_: command + skill. Effort: S–M. Value: High.

3. **Pre/post-check capture**
   _Old_: network engineering discipline of snapshotting state before and after.
   _Modern twist_: `/ycc:pre-check` captures a named bundle of `show ...` (or `get policy`, or `iptables -L -n -v`, etc.) command outputs into `docs/mops/<change>/pre.json`; `/ycc:post-check` captures them again after and diffs. Flags "things that were up before your change and are down now."
   _Failure prevented_: "BGP neighbor count went from 42 to 39 during my change and I didn't notice until the NOC called."
   _Form_: two commands + skill. Effort: M. Value: High.

### P1 — Useful, moderate effort

4. **`/ycc:show` looking-glass wrapper**
   _Old_: RANCID looking-glass.
   _Modern twist_: read-only runner with explicit allowlist of `show`-class verbs per vendor, audit log of every invocation, and automatic output cooking.
   _Failure prevented_: "junior engineer was given read SSH and accidentally typed `conf t`."
   _Form_: command + skill. Effort: M. Value: Medium-High.

5. **Flat-file network inventory skill**
   _Old_: `router.db`.
   _Modern twist_: skill that defaults to a `network.tsv` (or `router.db` for direct RANCID compatibility) with optional passthroughs to NetBox, Nornir inventory, Ansible hosts. Small shops stay small; big shops don't get forced into one format.
   _Failure prevented_: "we spent 3 weeks building YAML inventory for 12 devices."
   _Form_: skill. Effort: S. Value: Medium.

6. **`copy run start` guard / commit-aware change skill**
   _Old_: "did you save to startup?"
   _Modern twist_: after a device push, explicitly persist and verify (`write memory`, `commit`, `save config` per vendor), capture checksum, record in inventory.
   _Failure prevented_: "we made a change, it worked, device rebooted overnight for unrelated reason, change was lost."
   _Form_: script or skill helper. Effort: S. Value: Medium.

### P2 — Context-dependent, ship later

7. **Change-window policy check**
   _Old_: CiscoWorks RME change-audit exception reports.
   _Modern twist_: optional `change-window.yaml` in repo read by `/ycc:code-review` and `/ycc:mop`; warns on non-emergency PRs targeting prod outside the window.
   _Failure prevented_: "deploy was shipped Friday 4:55 PM, ops team ghosted for the weekend."
   _Form_: skill extension + config schema. Effort: S. Value: Medium (context-dependent).

8. **Trigger-on-syslog drift detection**
   _Old_: Cisco EEM responding to `%SYS-5-CONFIG_I`.
   _Modern twist_: Claude hook reading a syslog feed (or an MCP server) that fires `/ycc:config-drift` on any config-change event. Near-real-time.
   _Failure prevented_: "the polling interval is 24h; attacker had a 23h59m window."
   _Form_: hook + skill. Effort: L (needs a transport). Value: High but niche.

9. **Expect-era login helpers library**
   _Old_: RANCID's `clogin`, `jlogin`, `hlogin`, `fnlogin`, etc.
   _Modern twist_: a `_shared/scripts/` library of per-vendor SSH prompt-match + paging-disable + privilege-escalation scripts, callable from any skill. Netmiko/Scrapli exist, but the point is a **Claude-runnable, bash-invokable, no-Python-env-assumed** helper.
   _Failure prevented_: "every new skill re-implements SSH login handling."
   _Form_: shared scripts. Effort: M. Value: Medium (only if ycc gets more net-device skills).

---

## Comparative Analysis: Old vs. Modern Equivalents

| Old pattern                 | Modern replacement                      | Gap that remains                                                                               |
| --------------------------- | --------------------------------------- | ---------------------------------------------------------------------------------------------- |
| RANCID + CVS                | Oxidized + Git, or NetBox Golden Config | Output cooking is still often ad-hoc; vendor-specific volatile fields not catalogued centrally |
| CiscoWorks RME Change Audit | Splunk + change-tracking dashboards     | No exception reporting against change windows out of the box                                   |
| BladeLogic / Opsware        | Ansible + Terraform + Puppet            | Agent-based lifecycle dropped; agentless SSH trades accuracy for simplicity                    |
| ESX Service Console         | ESXi API + PowerCLI / vSphere REST      | Emergency access via DCUI is more limited; "install an agent" workflows lost                   |
| Cisco EEM on-box Tcl        | External orchestrators + webhooks       | On-box event response latency is better than off-box round trips                               |
| MOP Word document           | PR description + runbook.md             | Runbook structure isn't enforced; rollback commands often absent                               |
| `router.db` flat file       | YAML inventories / NetBox / Nautobot    | Schema complexity for small fleets; poor diff UX on YAML                                       |
| Expect scripts              | Netmiko / Scrapli / NAPALM              | Still CLI at the bottom; prompt-match fragility unchanged                                      |
| ScreenOS zone policy        | Junos SRX / PANW / Fortinet policy      | Cognitive overhead of zone-based policy is now under-taught; juniors don't learn it            |
| PIX `conduit` / nat-control | ASA modular policy framework / FTD      | Legacy pre-8.3 configs still in production, poorly understood                                  |

---

## Technology Evolution Impact

The pre-cloud era ended when three conditions simultaneously became true around 2013–2015:

1. **Cheap, fast CPUs and SSDs** — made previously-impossible daily full-config pulls from hundreds of devices trivial.
2. **Git winning over CVS/SVN** — made version-controlled config diffing pleasant instead of painful.
3. **Vendor API maturation** (NX-API, JunOS PyEZ, PAN-OS REST, F5 iControl-REST) — made deterministic config reads possible without Expect.

But **none of these killed the old failure modes**. A Claude-native bundle should assume:

- CLI-only devices still exist (firewalls, load balancers, OOB, legacy switches).
- Drift still happens — most configs are touched by humans, not pipelines.
- Rollback is still the main thing engineers forget to plan.
- Change windows and MOPs still matter in regulated shops.

Technology moved; operational gravity didn't.

---

## Key Insights

1. **The simplest RANCID feature is the most valuable one: unified diff in email.** Modern dashboards are worse than this. A Claude-native skill should default to producing a diff artifact and a plain summary, not a web UI.
2. **"Cook the output" is a lost art.** Nobody teaches it. Every new drift tool produces noisy diffs and users give up.
3. **Expect scripts are not dead; they are subterranean.** Netmiko and Scrapli are Expect with better ergonomics. Anything with a CLI has an Expect layer underneath in 2026 just as in 1996.
4. **The MOP discipline survives but its artifact has been dispersed** — split across PR description, runbook.md, terraform plan output, Jira ticket, and Slack thread. Consolidation is valuable.
5. **Vendor-neutral abstraction is an asymptote, not a destination.** OpenConfig has been "almost ready" for a decade. A Claude plugin should embrace hybrid: OpenConfig where available, vendor-native YANG where necessary, Expect/Netmiko where neither works. ([Karneliuk, 2022](https://karneliuk.com/2022/07/automation-15-the-good-the-bad-and-the-ugly-of-model-driven-network-automation-featuring-cisco-nokia-and-openconfig-yang/))
6. **Retired products left operational gaps, not just tool gaps.** ESX COS being removed meant no agent-based hardware monitoring; CiskoWorks retirement meant no integrated change-audit + config-archive in one box. Users patched the gap with 5 tools; the pattern — "one tool that just does this" — is still absent.
7. **Small teams were better served by flat-file tools.** RANCID's `router.db`, CatTools' activity table, Oxidized's CSV source. The YAML-first big-ops assumption in modern tooling hurts 2–3-person shops.
8. **The worst firewall bug in 10 years is the PIX 8.3 ACL semantic flip.** Real-world impact: if ycc ever ships a firewall change skill, a "which ACL semantic are you on?" warning is P0.

---

## Evidence Quality

- **High confidence**: RANCID mechanism, Oxidized comparison, MOP discipline, Opsware/BladeLogic history, VMware ESX→ESXi transition, Xen toolstack lineage, ScreenOS CLI, CiscoWorks retirement. All corroborated by multiple primary-adjacent sources including vendor docs, Wikipedia, practitioner blogs (ipSpace.net, Karneliuk, Lindsay Hill, Weberblog.net, PeteNetLive).
- **Medium confidence**: pre-Jinja native IOS features (aliases, SmartPort macros, template service) — search returned little direct coverage, inferred from general practitioner knowledge. Worth a direct cisco.com lookup if a skill is built on these.
- **Lower confidence**: exact adoption curves of each tool at peak (how many RANCID instances ran in 2005? unknown). Not load-bearing for the revival recommendations.

---

## Contradictions & Uncertainties

- **"RANCID is obsolete" vs. "RANCID is still running everywhere."** rConfig says RANCID is in the "lost arts" alongside AWK and Perl, but GitHub shows active forks and Shrubbery maintains it. The truth: old installs don't die, new installs don't happen. ([rConfig](https://www.rconfig.com/blog/oxidized-vs-rancid-a-feature-comparison))
- **"Screen scraping sucks" vs. "Screen scraping is unavoidable."** Both are true. Lindsay Hill's "Why Screen Scraping Sucks" enumerates the failure modes; ipSpace.net counters that "many devices don't offer alternatives." ([Lindsay Hill](https://lkhill.com/why-screen-scraping-sucks/); [ipSpace.net](https://blog.ipspace.net/kb/CiscoAutomation/050-scraping/))
- **"OpenConfig solved multi-vendor" vs. "OpenConfig coverage is incomplete."** Depends entirely on which YANG modules your vendor ships. Transport/optical is well-covered; BGP-LS is not; ISIS is divergent even within Cisco's own platforms.
- **"Change windows are bureaucratic" vs. "Change windows saved lives."** The right answer depends on blast radius and regulatory context. Not universal.

---

## Search Queries Executed

1. "RANCID Really Awesome New Cisco confIG Differ network configuration archive mechanism how it works"
2. "Kiwi CatTools features network device configuration management history"
3. "Expect scripts network device automation Cisco IOS screen scraping patterns"
4. "Cisco IOS macro alias template service configuration automation pre-Jinja"
5. "BladeLogic Opsware history server automation BSA datacenter automation pre-cloud"
6. "network change management MOP Method of Procedure runbook rollback pre-GitOps discipline"
7. "RANCID vs Oxidized feature comparison network config management"
8. "Juniper ScreenOS history firewall policy management configuration"
9. "VMware ESX Service Console history COS discontinued ESXi transition"
10. "Xen toolstack xend xl lineage Proxmox OpenVZ origins history"
11. "NETCONF YANG OpenConfig multi-vendor network abstraction failure challenges lessons"
12. "Cisco PIX ASA access-list legacy history Check Point smart policy NAT"
13. "Opsware history Loudcloud Marc Andreessen HP acquisition server automation 2007"
14. "CiscoWorks Resource Manager Essentials CRWS compliance configuration history deprecated"

---

## Bottom Line for ycc

Three P0 additions stand out from the past that modern tools still don't address well:

- **`/ycc:config-drift`** (RANCID's core loop, reimagined Claude-native)
- **`/ycc:mop`** (MOP discipline as a generated artifact tied to a diff)
- **`/ycc:pre-check` / `/ycc:post-check`** (the oldest operations discipline in the book, still absent from AI tooling)

These are **low-maintenance, high-recurrence value**, and each prevents a specific failure mode that existing AI assistants and vendor SDKs miss entirely. They're the forgotten pieces of 30 years of network-ops muscle memory, and a plugin bundle for a senior networking-infra practitioner is exactly the right home for them.
