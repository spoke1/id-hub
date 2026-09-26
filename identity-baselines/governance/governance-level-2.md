# Identity governance · Level 2 · Managed

Level 2 replaces tickets and manual group changes with access packages, connects the HR system to the identity lifecycle and reviews sensitive access regularly.

---

## Entitlement management

- **Catalogs** per business area, owned by the business, not by IT.
- **Access packages** bundle groups, Teams, applications and SharePoint sites for a role or a project, for example *Finance – Accounts Payable* or *Project X – External partners*.
- **Policies** per package define who can request, who approves (manager, resource owner, or both in sequence) and when access expires.
- **Expiry** by default: 6 or 12 months for internal packages, shorter for external users. Users can request an extension; the approver sees the history.
- **External users** request access through connected organisations; their guest account is removed when the last package expires.

## HR-driven provisioning

- Accounts are created from the HR system before the first working day, with attributes such as department, manager, cost centre and employee type.
- Microsoft Entra supports inbound provisioning from Workday and SAP SuccessFactors, and API-driven inbound provisioning for any other HR system (for example SAP HCM or a custom HR database via an integration layer).
- Hybrid: provision to on-premises AD where AD is still the source of authority; otherwise directly to Entra ID.
- The manager attribute is mandatory; approvals and reviews depend on it.

## Lifecycle workflows (Entra ID Governance)

| Trigger | Tasks |
|---|---|
| Joiner, before the start date | Generate a Temporary Access Pass and send it to the manager, add to baseline groups |
| Joiner, on the start date | Enable the account, send the welcome message |
| Mover, department or job change | Remove from groups of the previous role, notify the manager |
| Leaver, last day | Disable the account, remove from all groups and Teams, revoke sessions |
| Leaver, after 30 days | Delete the account |

## Access reviews

| Review | Scope | Reviewer | Frequency |
|---|---|---|---|
| Access packages | Assignments of every package with sensitive resources | Manager or package owner | Semi-annually |
| Groups with sensitive access | Groups that grant access to confidential data or production systems | Group owner | Quarterly |
| Applications | Users of business-critical applications | Application owner | Semi-annually |
| Privileged roles | As in Level 1 | Security team | Quarterly |

Use reviewer recommendations (for example inactive users) and apply the results automatically.

---

## Checklist

- [ ] Catalogs and access packages for the most requested access
- [ ] Every package with approval and expiry
- [ ] HR system connected, accounts created before the start date
- [ ] Lifecycle workflows for joiner, mover and leaver
- [ ] Reviews for packages, sensitive groups and critical applications

Continue with [Level 3](governance-level-3.md).
