# Identity security controls · Level 2 · Hardened

Level 2 removes most standing privilege, responds to identity risk automatically and makes misuse of emergency access and application credentials visible. It requires Entra ID P2.

---

## Privileged Identity Management (PIM)

| Setting | Baseline |
|---|---|
| Scope | All privileged directory roles and privileged Azure RBAC roles (Owner, User Access Administrator, Contributor on production) |
| Assignment type | Eligible, not active. Only the break-glass accounts keep a permanent active Global Administrator assignment |
| Activation | MFA required, justification required, maximum duration 8 hours or less |
| Approval | Required for Global Administrator, Privileged Role Administrator and Privileged Authentication Administrator |
| Notifications | Role activations of critical roles notify the security team |
| Groups | Use PIM for Groups for role-assignable groups that grant privileged access |

## Risk policies in Conditional Access

Configure the user risk and sign-in risk responses as Conditional Access policies (baseline CA204 and CA205). The legacy user risk and sign-in risk policies in Identity Protection are retired on 1 October 2026 and must not be used anymore.

- Self-service password reset is enabled for all users; password writeback is enabled for hybrid users.
- Review and dismiss or confirm risky users regularly, so the risk state stays meaningful.

## Passwordless rollout

- Admins first: passkeys (FIDO2 security keys or passkeys in Microsoft Authenticator) or Windows Hello for Business.
- Use registration campaigns to move users from weaker methods to Authenticator or passkeys.
- Temporary Access Pass for onboarding, so new employees never have to set a password before registering a strong method.

## Alerting on break-glass use

Every sign-in of an emergency access account is an event. Alert on it, for example with a Log Analytics alert rule:

```kusto
SigninLogs
| where UserPrincipalName in~ ("bg-admin-01@<tenant>.onmicrosoft.com", "bg-admin-02@<tenant>.onmicrosoft.com")
| project TimeGenerated, UserPrincipalName, AppDisplayName, IPAddress, ResultType, ConditionalAccessStatus
```

Send the alert to a group or a SOC queue, not to the break-glass account itself.

## Application and service principal credentials

Non-human identities often hold more privileges than users and are rarely reviewed.

- Every app registration and enterprise application with permissions has at least two named owners.
- Prefer certificates and federated credentials (workload identity federation) over client secrets. Where secrets remain, keep their lifetime short.
- Review application permissions with tenant-wide impact, for example `RoleManagement.ReadWrite.Directory`, `AppRoleAssignment.ReadWrite.All`, `Application.ReadWrite.All`, `Directory.ReadWrite.All`.
- Remove service principals that have not signed in for a long time (service principal sign-in activity report).

## Logging and alerting

In addition to Level 1, export `RiskyUsers`, `UserRiskEvents` and `MicrosoftGraphActivityLogs` and alert on:

- risky sign-ins and users with high risk
- activation of critical PIM roles
- changes to Conditional Access policies
- new credentials added to applications or service principals

---

## Checklist

- [ ] All privileged roles eligible in PIM, activation with MFA and justification
- [ ] Approval for the most critical roles
- [ ] Risk responses as Conditional Access policies, legacy Identity Protection policies removed
- [ ] Passkeys or Windows Hello for Business for all admins
- [ ] Alert on every break-glass sign-in
- [ ] Owners and credential hygiene for applications

Continue with [Level 3](security-level-3.md).
