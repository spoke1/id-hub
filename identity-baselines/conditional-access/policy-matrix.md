# Conditional Access policy matrix

How each control evolves from Level 1 to Level 3. Use it for stakeholder communication, roadmap planning and maturity assessments.

## Controls by level

| Control | Level 1 · Foundation | Level 2 · Enhanced | Level 3 · Zero Trust |
|---|---|---|---|
| Legacy authentication | Blocked (CA101) | Blocked | Blocked |
| MFA for admins | MFA strength (CA102) | MFA strength | Phishing-resistant (CA301) |
| MFA for users | Microsoft 365 and admin portals (CA103, CA104) | All apps (CA201) | All apps |
| Device requirement, admins | none | Compliant or hybrid joined (CA202) | Compliant or hybrid joined |
| Device requirement, members | none | App protection on mobile (CA208) | + compliant or hybrid joined on desktop (CA302) |
| Unknown device platforms | allowed | Blocked (CA203) | Blocked |
| Sign-in risk | High: MFA (CA105) | Medium and high: MFA (CA205) | High: blocked (CA303), medium: MFA |
| User risk | none | High: password change (CA204) | Medium and high: password change (CA304) |
| Security info registration | unrestricted | MFA outside trusted locations (CA206) | MFA outside trusted locations |
| Admin sessions | default | 12 h, no persistent browser (CA207) | 12 h, no persistent browser |
| Sessions on unmanaged devices | default | default | 12 h, no persistent browser (CA305) |
| Device code flow, authentication transfer | allowed | Blocked (CA209, CA210) | Blocked |
| Workload identities | none | none | Only from trusted locations (CA306) |
| Break-glass accounts | Excluded from every user policy | Excluded, sign-ins alerted | Excluded, sign-ins alerted, tested regularly |

## Licence and dependency overview

| Policy | Licence | Depends on |
|---|---|---|
| CA101, CA102, CA103, CA104, CA201, CA203, CA207, CA209, CA210, CA301, CA305 | Entra ID P1 | CA301: phishing-resistant methods registered |
| CA105, CA205, CA303 | Entra ID P2 | Identity Protection |
| CA204, CA304 | Entra ID P2 | Self-service password reset, password writeback for hybrid users |
| CA202, CA302 | Entra ID P1 + Intune | Compliance policies or hybrid join |
| CA206 | Entra ID P1 | Trusted named locations, Temporary Access Pass |
| CA208 | Entra ID P1 + Intune | App protection policies |
| CA306 | Workload ID Premium | Trusted named locations for workload egress |

## Using the matrix

- **Maturity assessment:** mark each row with the level your tenant has *enabled* (not only in report-only).
- **Roadmap:** each column transition is a work package with its prerequisites from the dependency table.
- **Exceptions:** every deviation from a column gets an owner and a review date.
