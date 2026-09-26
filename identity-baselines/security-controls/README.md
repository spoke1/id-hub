# Identity security controls

Conditional Access decides *whether* a sign-in is allowed. The controls in this section make sure the identities behind those sign-ins are protected: emergency access, privileged access, authentication methods, application consent, detection and logging.

## Levels

| Level | Focus | Document |
|---|---|---|
| **1 · Foundation** | Emergency access, privileged role inventory, authentication methods policy, consent settings, log retention | [security-level-1.md](security-level-1.md) |
| **2 · Hardened** | PIM for all privileged roles, risk policies in Conditional Access, passkey rollout, alerting on break-glass use, application credential hygiene | [security-level-2.md](security-level-2.md) |
| **3 · Zero Trust** | Zero standing privilege, passwordless-first, SIEM detections for identity attacks, governance of workload identities | [security-level-3.md](security-level-3.md) |

Align the levels with the [Conditional Access baselines](../conditional-access/README.md): security controls Level 2 is a prerequisite for Conditional Access Level 3 (phishing-resistant admins need registered methods and PIM).

## Scope

Included:

- Emergency access (break-glass) accounts
- Privileged Identity Management (PIM) and role hygiene
- Authentication methods policy and passwordless adoption
- User and admin consent for applications
- Credentials of applications and service principals
- Logging, alerting and detection

Not included:

- Conditional Access policies: [conditional-access/](../conditional-access/README.md)
- Identity lifecycle and access governance: [governance/](../governance/README.md)
