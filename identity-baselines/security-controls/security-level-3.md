# Identity security controls · Level 3 · Zero Trust

Level 3 removes standing privilege completely, treats passwords as a legacy fallback and detects identity attacks in near real time. It is typically part of a formal Zero Trust programme or required in regulated environments.

---

## Zero standing privilege

- No permanent privileged role assignments except the break-glass accounts.
- Short activation windows (for example 1 to 4 hours) with justification and, for critical roles, approval.
- PIM activation requires a Conditional Access **authentication context** that enforces phishing-resistant MFA and a compliant device. This way even an eligible admin with a stolen password cannot activate a role.
- Quarterly access reviews for eligible assignments of privileged roles.

## Passwordless-first

| Scenario | Method |
|---|---|
| Admins | Passkeys (FIDO2) or Windows Hello for Business; certificate-based authentication where a PKI exists |
| Knowledge workers on managed Windows devices | Windows Hello for Business |
| Mobile and frontline workers | Passkeys in Microsoft Authenticator |
| Onboarding and recovery | Temporary Access Pass |

Passwords remain only as a fallback, and the number of users who still sign in with a password is tracked as a KPI.

## Session and token protection

- Continuous access evaluation (CAE) is on by default for supported services. It revokes sessions close to real time when a user is disabled, the password changes or the network location changes.
- Evaluate strict location enforcement for CAE in environments with stable egress IPs.
- Evaluate Token Protection for sign-in sessions on Windows devices to bind tokens to the device they were issued to.

## Detection (SIEM)

Connect Entra ID to a SIEM such as Microsoft Sentinel, enable UEBA and alert on identity-specific attack patterns. Examples:

```kusto
// Changes to Conditional Access policies
AuditLogs
| where OperationName in ("Add conditional access policy", "Update conditional access policy", "Delete conditional access policy")
| project TimeGenerated, OperationName, InitiatedBy, TargetResources
```

```kusto
// New credentials on applications or service principals
AuditLogs
| where OperationName has "credentials" or OperationName has "Certificates and secrets"
| project TimeGenerated, OperationName, InitiatedBy, TargetResources
```

Further detections: role assignments outside PIM, consent to high-privilege permissions, sign-ins of disabled or deleted users, MFA method changes followed by risky sign-ins.

## Workload identities

- Conditional Access for workload identities (baseline CA306) restricts single-tenant service principals to known networks.
- Identity Protection for workload identities detects risky service principals, for example leaked credentials.
- Managed identities for Azure workloads, federated credentials for GitHub Actions and other CI systems. No long-lived secrets.
- AI agents and automation accounts follow the same rules as any other non-human identity: a named owner, least privilege, a defined lifecycle and full logging.

## Break-glass governance

- Documented emergency procedure, stored outside the tenant.
- Test the accounts at least twice a year: sign-in, alert received, keys found.
- Review the membership of the break-glass group after every change.

---

## Checklist

- [ ] No permanent privileged assignments except break-glass
- [ ] PIM activation protected by an authentication context
- [ ] Passwordless methods for all admins and the majority of users
- [ ] SIEM detections for Conditional Access changes, credential additions and role assignments
- [ ] Conditional Access and Identity Protection for workload identities
- [ ] Break-glass accounts tested and documented
