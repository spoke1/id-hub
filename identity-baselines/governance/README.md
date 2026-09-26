# Identity governance baselines

Conditional Access and security controls protect sign-ins. Governance answers the questions an auditor asks next: *Who has access to what, why, since when, and who confirmed it is still needed?* This section covers the identity lifecycle (joiner, mover, leaver), access requests, access reviews and the governance of non-human identities.

## Levels

| Level | Focus | Document |
|---|---|---|
| **1 · Foundation** | Ownership, group-based access, guest settings, reviews for guests and privileged roles, a reliable leaver process | [governance-level-1.md](governance-level-1.md) |
| **2 · Managed** | Access packages with approval and expiry, HR-driven provisioning, lifecycle workflows, regular reviews of sensitive access | [governance-level-2.md](governance-level-2.md) |
| **3 · Automated** | End-to-end JML from the HR system, attribute-based assignment, separation of duties, full governance of non-human identities | [governance-level-3.md](governance-level-3.md) |

## Principles

1. **HR is the source of truth.** Identities are created, changed and disabled because an HR record changed, not because someone opened a ticket.
2. **Access through packages or groups, never direct.** Direct assignments to apps and resources cannot be reviewed or expired at scale.
3. **Every access has an owner and an end date.** Open-ended access is the exception and is documented.
4. **Reviews by people who can judge.** Managers and resource owners review access, not the IT department.
5. **Non-human identities are identities.** Service principals, managed identities, automation accounts and AI agents get owners, least privilege and a lifecycle, just like people.

## Licensing

Access reviews, entitlement management and PIM require Microsoft Entra ID P2 or Microsoft Entra ID Governance; lifecycle workflows and several advanced governance features require Microsoft Entra ID Governance. Check Microsoft's current licensing guidance for the features you plan to use.
