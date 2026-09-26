# Identity baselines

Opinionated, staged identity security baselines for Microsoft Entra ID. They describe a path from a weak or legacy configuration to a Zero Trust identity posture, in steps an organisation can actually take.

## Three pillars, three levels

| | Level 1 · Foundation | Level 2 · Enhanced / Hardened / Managed | Level 3 · Zero Trust / Automated |
|---|---|---|---|
| [**Conditional Access**](conditional-access/README.md) | Legacy auth blocked, MFA for admins and Microsoft 365 | MFA everywhere, trusted devices for admins, risk-based responses, token theft paths closed | Phishing-resistant admins, managed devices for members, workload identities |
| [**Security controls**](security-controls/README.md) | Break-glass, role inventory, authentication methods, consent | PIM, passkeys, alerting, application credential hygiene | Zero standing privilege, passwordless-first, SIEM detections |
| [**Governance**](governance/README.md) | Ownership, group-based access, guest reviews, leaver process | Access packages, HR-driven provisioning, lifecycle workflows | Attribute-based access, separation of duties, non-human identity governance |

Each level builds on the previous one. You do not skip levels; you grow into them.

## How to use

1. **Assess:** mark for each pillar which level is *enforced* today, not planned or in report-only.
2. **Plan:** the next level of each pillar is a work package. The level documents list prerequisites and a checklist.
3. **Implement:** Conditional Access policies are available as Graph-ready templates and can be imported in report-only mode with [`scripts/Import-ConditionalAccessBaseline.ps1`](../scripts/Import-ConditionalAccessBaseline.ps1).
4. **Verify:** measure report-only impact and sign-in coverage with `Get-ConditionalAccessInsights.ps1` from [hybrid-workplace-automation](https://github.com/spoke1/hybrid-workplace-automation), then enforce.

## Folder structure

```text
identity-baselines/
  conditional-access/   Policy documentation per level, policy matrix, JSON templates
  security-controls/    Break-glass, PIM, authentication methods, consent, logging, detection
  governance/           Lifecycle, access packages, reviews, non-human identities
```
