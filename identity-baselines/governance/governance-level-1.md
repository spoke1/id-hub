# Identity governance · Level 1 · Foundation

Level 1 creates the preconditions for any governance: everything has an owner, access is granted through groups, guests are controlled and leavers lose access reliably.

---

## Ownership

- Every group, Team, app registration and enterprise application with permissions has at least two named owners.
- Owners are people in active employment. An owner who leaves is replaced as part of the leaver process.
- Resources without an owner are reported monthly and assigned or removed.

## Group-based access

- Applications, licences and SharePoint sites are assigned to groups, not to individual users.
- Dynamic groups based on HR attributes (department, location, employee type) for broad access; assigned groups with an owner for specific access.
- Role-assignable groups only for privileged access, and only with PIM (see security controls Level 2).

## Guests and external users

| Setting | Baseline |
|---|---|
| Guest user access | Restricted to properties and memberships of their own directory objects |
| Who can invite | Admins and users in the Guest Inviter role, or members with a documented business reason |
| Collaboration restrictions | Allow list or deny list of domains where the business requires it |
| Cross-tenant access settings | Defaults reviewed; trust MFA and device claims only from known partner tenants |
| Inactive guests | Reviewed and removed (see access reviews) |

## Access reviews (Entra ID P2 or Entra ID Governance)

| Review | Scope | Reviewer | Frequency |
|---|---|---|---|
| Guests | All guests in groups and Teams | Group owners, fallback: sponsor | Quarterly |
| Privileged roles | Eligible and active assignments of privileged directory roles | Security team or role owner | Quarterly |

Configure reviews to remove access automatically when the reviewer denies it or does not respond.

## Leaver process

- HR communicates the last working day in advance; the account is disabled at the end of that day.
- Disable first, delete later (for example after 30 days), so mailbox and files can be handed over.
- Revoke sessions and refresh tokens when disabling the account.
- Remove the leaver as owner of groups and applications, and as sponsor of guests.
- Hybrid: disable in AD (source of authority) and verify the state in Entra ID. The `StateMismatch` finding of `Get-HybridADHealth.ps1` in [hybrid-workplace-automation](https://github.com/spoke1/hybrid-workplace-automation) catches accounts that are disabled in one directory only.

---

## Checklist

- [ ] Two owners for every group and every application with permissions
- [ ] Access to apps and licences only through groups
- [ ] Guest settings restricted, cross-tenant access reviewed
- [ ] Quarterly reviews for guests and privileged roles with automatic removal
- [ ] Documented leaver process with session revocation

Continue with [Level 2](governance-level-2.md).
