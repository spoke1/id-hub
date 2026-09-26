# Identity security controls · Level 1 · Foundation

The minimum every Entra ID tenant should have. None of these controls needs a premium licence beyond Entra ID P1.

---

## Emergency access (break-glass) accounts

| Setting | Baseline |
|---|---|
| Number | At least two |
| Account type | Cloud-only, on the `*.onmicrosoft.com` domain, not synchronised from AD |
| Role | Global Administrator, permanently active |
| Authentication | Passkey (FIDO2) as the recommended method, or certificate-based authentication if a PKI exists. Use methods that differ from those of the regular admin accounts. Both satisfy Microsoft's mandatory MFA for admin portals. |
| Conditional Access | Members of one security group that every blocking or restricting policy excludes |
| Storage | Keys or certificates stored physically separate, in at least two secure locations |
| Usage | Emergencies only; every sign-in triggers an alert (Level 2) |

A break-glass account with a password only no longer works for the admin portals: Microsoft enforces MFA there regardless of your own policies.

## Privileged role inventory

- List all directory role assignments, including eligible assignments and assignments to groups and service principals.
- Keep the number of Global Administrators small: two break-glass accounts plus as few named admins as operations allow (Microsoft recommends fewer than five).
- Admin accounts are separate, cloud-only accounts, never the daily mail account and never synchronised from on-premises AD.
- Replace Global Administrator with least-privileged roles where possible (for example User Administrator, Exchange Administrator, Security Reader).

## Authentication methods policy

Methods are managed only in the authentication methods policy since the legacy MFA and SSPR method settings were retired on 30 September 2025.

| Method | Setting |
|---|---|
| Microsoft Authenticator (push and passkey) | Enabled for all users |
| Passkeys (FIDO2) | Enabled, at least for admins |
| Temporary Access Pass | Enabled for onboarding and recovery, short lifetime, one-time use |
| SMS and voice call | Disabled, or restricted to a documented exception group |
| Email OTP | Only for guests if required |

Number matching is enforced for all Authenticator push notifications since May 2023; there is nothing to configure for it.

Security defaults must be off once you use Conditional Access; the two are mutually exclusive.

## Application consent

- User consent: only for apps from verified publishers and only for low-risk permissions, or disabled.
- Enable the admin consent workflow, so users can request an app instead of working around the restriction.
- Review existing OAuth grants with high-privilege permissions (for example `Mail.ReadWrite`, `Files.ReadWrite.All`, `Directory.ReadWrite.All`).

Illicit consent grants give attackers persistent access without ever needing the user's password.

## Logging and visibility

- Sign-in and audit logs are retained for 30 days in Entra ID (P1/P2). Export them to a Log Analytics workspace for longer retention and for queries across sources. The [zero-trust-iac](https://github.com/spoke1/zero-trust-iac) repository deploys a suitable workspace.
- Minimum categories: `AuditLogs`, `SignInLogs`, `NonInteractiveUserSignInLogs`, `ServicePrincipalSignInLogs`, `ManagedIdentitySignInLogs`.
- Review risky users and risky sign-ins weekly, even before automated responses are in place.

---

## Checklist

- [ ] Two break-glass accounts with passkey or certificate-based authentication, in the break-glass group
- [ ] Privileged role assignments documented, fewer than five Global Administrators
- [ ] Separate cloud-only admin accounts
- [ ] Authentication methods policy configured, SMS and voice disabled or restricted
- [ ] User consent restricted, admin consent workflow enabled
- [ ] Entra ID logs exported to Log Analytics

Continue with [Level 2](security-level-2.md).
