# Identity governance · Level 3 · Automated

Level 3 closes the loop: access follows HR data automatically, toxic combinations are prevented, and non-human identities are governed with the same rigour as people.

---

## Attribute-based access

- **Automatic assignment policies** in entitlement management grant birthright access packages based on HR attributes, for example all employees in department *Sales* at location *Cologne*. When the attribute changes, the access follows.
- Requests are needed only for access that cannot be derived from attributes.
- The mover case works without tickets: a department change removes the old packages and assigns the new ones.

## Separation of duties

- Define **incompatible access packages** and groups for toxic combinations, for example *create supplier* and *approve payment*.
- Users who already hold one package cannot request the incompatible one; existing conflicts are reported and resolved.
- Map critical SoD rules from the ERP or GRC system to access packages, so they are enforced at request time and not only detected after the fact.

## Continuous certification

- Reviews are risk-based: privileged and sensitive access more often, low-risk access less often.
- Machine recommendations (inactivity, peer comparison) pre-fill decisions; reviewers focus on the exceptions.
- Every review decision is logged with the reviewer, the justification and the date: evidence for ISO 27001, SOC 2 or regulatory audits.

## Non-human identity governance

Service principals, managed identities, automation accounts and AI agents often outnumber users and hold broad permissions. Govern them as a first-class identity type.

| Control | Baseline |
|---|---|
| Inventory | Every service principal and managed identity is listed with owner, purpose, permissions, credential type and expiry |
| Ownership | At least two named owners; ownerless service principals are escalated |
| Credentials | Managed identities or federated credentials first, certificates second, client secrets only as a documented exception with a short lifetime |
| Permissions | Least privilege; application permissions with tenant-wide write access need an approval and a periodic review |
| Activity | Service principals without sign-ins for a defined period are disabled, then removed |
| Monitoring | Credential additions, permission grants and anomalous sign-ins of service principals are alerted (see security controls Level 3) |

### AI agents

AI agents act with delegated or application permissions and can chain actions faster than any human. Treat them as non-human identities with these additional rules:

- A human sponsor who is accountable for the agent's actions.
- Permissions scoped to the task, time-bound where possible.
- Every action is attributable to the agent's own identity, never to a shared account or a user's token.
- The agent is decommissioned with its purpose; its identity and permissions are removed, not orphaned.

---

## Checklist

- [ ] Birthright access assigned automatically from HR attributes
- [ ] Incompatible packages defined for critical SoD rules
- [ ] Risk-based review cadence with automatic application of results
- [ ] Inventory and owners for all service principals and managed identities
- [ ] Credential policy for non-human identities enforced and monitored
- [ ] Sponsor, scoped permissions and lifecycle for every AI agent
