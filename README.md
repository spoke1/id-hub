# Identity Secure Hub

Staged, deployable identity security baselines for Microsoft Entra ID: Conditional Access, identity security controls and identity governance, from secure-by-default to Zero Trust.

[![CI](https://github.com/spoke1/id-hub/actions/workflows/ci.yml/badge.svg)](https://github.com/spoke1/id-hub/actions/workflows/ci.yml)
![Microsoft Entra ID](https://img.shields.io/badge/Microsoft%20Entra%20ID-Conditional%20Access-0078D4)
![Microsoft Graph](https://img.shields.io/badge/Microsoft%20Graph-v1.0-5C2D91)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207.x-5391FE?logo=powershell&logoColor=white)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Why

Most Entra ID tenants do not lack features. They lack a sequence: which control comes first, what it depends on, and how to switch it on without locking people out. This repository gives that sequence in three levels per pillar, with the reasoning behind every control and Conditional Access policies you can deploy.

## What's inside

| Area | Content |
|---|---|
| [**Conditional Access baselines**](identity-baselines/conditional-access/README.md) | 21 policies in three levels, each documented and available as a Graph-ready JSON template. Report-only by default, break-glass exclusion built in, naming convention, [policy matrix](identity-baselines/conditional-access/policy-matrix.md) |
| [**Identity security controls**](identity-baselines/security-controls/README.md) | Break-glass accounts, PIM, authentication methods and passwordless, application consent, credential hygiene, logging and KQL detections |
| [**Identity governance**](identity-baselines/governance/README.md) | Joiner-mover-leaver, access packages, access reviews, separation of duties, governance of non-human identities and AI agents |
| [**Scripts**](scripts) | `Import-ConditionalAccessBaseline.ps1` creates the policies in report-only mode; `Export-ConditionalAccessPolicy.ps1` backs up and documents existing policies |

## Maturity model

| | Level 1 · Foundation | Level 2 · Enhanced | Level 3 · Zero Trust |
|---|---|---|---|
| **Conditional Access** | Legacy auth blocked, MFA for admins and Microsoft 365 | MFA everywhere, trusted devices for admins, risk-based responses, device code flow blocked | Phishing-resistant admins, managed devices for members, workload identities restricted |
| **Security controls** | Break-glass, role inventory, authentication methods, consent | PIM, passkeys, alerting, application credential hygiene | Zero standing privilege, passwordless-first, SIEM detections |
| **Governance** | Ownership, group-based access, guest reviews, leaver process | Access packages, HR-driven provisioning, lifecycle workflows | Attribute-based access, separation of duties, non-human identity governance |

## Quick start

Prerequisites: Microsoft Graph PowerShell SDK v2 (`Microsoft.Graph.Authentication`), a security group containing your two emergency access accounts, and the Conditional Access Administrator role.

```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser

git clone https://github.com/spoke1/id-hub.git
cd id-hub

# 1. Back up and document the current policies
.\scripts\Export-ConditionalAccessPolicy.ps1 -ResolveNames

# 2. Preview Level 1
.\scripts\Import-ConditionalAccessBaseline.ps1 -Level 1 -BreakGlassGroupId '<group-object-id>' -WhatIf

# 3. Create Level 1 in report-only mode
.\scripts\Import-ConditionalAccessBaseline.ps1 -Level 1 -BreakGlassGroupId '<group-object-id>'
```

Then let the policies run in report-only mode for one to two weeks, measure the impact per policy (for example with `Get-ConditionalAccessInsights.ps1` from [hybrid-workplace-automation](https://github.com/spoke1/hybrid-workplace-automation)) and switch them on one by one. The import script cannot enable policies; that step is always deliberate.

## Design principles

- **Report-only first.** Every template is created as `enabledForReportingButNotEnforced`. Enforcement is a manual decision based on evidence.
- **Never lock yourself out.** Every user policy excludes the break-glass group; the import script checks that the group exists and has members.
- **One control per policy.** Readable report-only results, safe rollback of single controls.
- **No tenant data in templates.** Only built-in identifiers such as role template IDs and authentication strength IDs. A CI test rejects any other ID.
- **Current Microsoft guidance.** Authentication strengths instead of the plain MFA control, app protection instead of the retired approved-client-app grant, risk policies in Conditional Access instead of the retired Identity Protection policies.

## Quality gates

Every push runs:

- **Pester tests** that validate each template against the design rules and Graph constraints: naming, report-only state, break-glass exclusion, no tenant-specific IDs, no `approvedApplication`, no authentication strength combined with `mfa`, `passwordChange` only together with `mfa`, *every time* sign-in frequency only for risk policies, persistent browser control only for all apps, the complete privileged role set
- **PSScriptAnalyzer** for the scripts
- **gitleaks** secret scan of the full history

## Licensing

| Capability | Licence |
|---|---|
| Conditional Access, authentication strengths | Microsoft Entra ID P1 |
| Risk-based policies, Identity Protection, PIM, access reviews | Microsoft Entra ID P2 |
| Lifecycle workflows and advanced governance features | Microsoft Entra ID Governance |
| Conditional Access for workload identities | Microsoft Entra Workload ID Premium |
| Device compliance, app protection | Microsoft Intune |

## Repository structure

```text
identity-baselines/
  conditional-access/     Level documents, policy matrix, JSON templates (policies/level-1..3)
  security-controls/      Level documents for identity security controls
  governance/             Level documents for identity governance
scripts/
  Import-ConditionalAccessBaseline.ps1
  Export-ConditionalAccessPolicy.ps1
tests/                    Pester tests for templates and scripts
.github/workflows/ci.yml  Pester, PSScriptAnalyzer, gitleaks
```

## Roadmap

- [x] Conditional Access baselines with deployable templates
- [x] Identity security controls and governance baselines
- [ ] Authentication methods policy as code (export and baseline comparison)
- [ ] PIM role settings baseline as code
- [ ] Drift report: tenant policies compared with the baseline templates

## Related repositories

- [hybrid-workplace-automation](https://github.com/spoke1/hybrid-workplace-automation): read-only PowerShell tooling for AD, Entra ID and Intune, including Conditional Access insights from the sign-in logs
- [zero-trust-iac](https://github.com/spoke1/zero-trust-iac): Bicep foundation for security logging, Defender for Cloud and guardrails in Azure

## Maintainer

Built and maintained by **Ramón Lotz**, IAM & Security Architect (Cloud Security).

[ramonlotz.de](https://ramonlotz.de) · Blog: [Access Insights](https://ramonlotz.de/blog) · [LinkedIn](https://www.linkedin.com/in/ramonlotz)

## Disclaimer

The baselines are a starting point, not a substitute for an assessment of your environment. Import them into a test tenant first, keep them in report-only mode until you understand their impact, and adapt them to your organisation.

## License

[MIT](LICENSE)
