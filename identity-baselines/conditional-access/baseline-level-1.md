# Conditional Access baseline · Level 1 · Foundation

Level 1 closes the attack paths that cause most identity compromises: legacy protocols that bypass MFA, unprotected admin accounts and password-only access to email and files. User impact is low, so this level fits every tenant as a starting point.

Prerequisites: Entra ID P1 (CA105: P2), two emergency access accounts in the break-glass group, users registered for MFA.

---

## CA101 · Block legacy authentication

| | |
|---|---|
| Users | All users, except break-glass |
| Applications | All |
| Condition | Client apps: Exchange ActiveSync clients, other clients |
| Grant | Block |
| Template | [`CA101-AllUsers-AllApps-BlockLegacyAuthentication.json`](policies/level-1/CA101-AllUsers-AllApps-BlockLegacyAuthentication.json) |

Legacy protocols (POP, IMAP, SMTP AUTH, older Office clients, basic-auth ActiveSync) cannot perform MFA. Password spray attacks target them for exactly that reason. Check the report-only results for devices such as printers or scanners that still send mail with SMTP AUTH; move them to a connector or a dedicated relay instead of excluding users.

## CA102 · Admins require MFA

| | |
|---|---|
| Users | 18 privileged directory roles, except break-glass |
| Applications | All |
| Grant | Authentication strength *Multifactor authentication* |
| Template | [`CA102-Admins-AllApps-RequireMFA.json`](policies/level-1/CA102-Admins-AllApps-RequireMFA.json) |

Every sign-in of an active admin role requires MFA, for every application. Level 3 (CA301) tightens this to phishing-resistant methods.

## CA103 · Admin portals require MFA

| | |
|---|---|
| Users | All users, except break-glass |
| Applications | Microsoft Admin Portals |
| Grant | Authentication strength *Multifactor authentication* |
| Template | [`CA103-AllUsers-AdminPortals-RequireMFA.json`](policies/level-1/CA103-AllUsers-AdminPortals-RequireMFA.json) |

Covers users who have delegated admin rights without a directory role, for example through Azure RBAC, Exchange or Intune RBAC. Microsoft enforces MFA for the Azure and admin portals on its side as well; this policy makes the requirement explicit and visible in your own policy set.

## CA104 · Microsoft 365 requires MFA

| | |
|---|---|
| Users | All users, except break-glass |
| Applications | Office 365 (Exchange Online, SharePoint Online, Teams and related services) |
| Grant | Authentication strength *Multifactor authentication* |
| Template | [`CA104-AllUsers-Office365-RequireMFA.json`](policies/level-1/CA104-AllUsers-Office365-RequireMFA.json) |

Protects mail, files and chat, where most business data lives. Level 2 (CA201) extends MFA to all applications.

## CA105 · High sign-in risk requires MFA

| | |
|---|---|
| Users | All users, except break-glass |
| Applications | All |
| Condition | Sign-in risk: high |
| Grant | Authentication strength *Multifactor authentication* |
| Session | Sign-in frequency: every time |
| Template | [`CA105-AllUsers-AllApps-RequireMFA-HighSignInRisk.json`](policies/level-1/CA105-AllUsers-AllApps-RequireMFA-HighSignInRisk.json) |
| Licence | Entra ID P2 |

A successful MFA challenge remediates the sign-in risk. *Every time* ensures the user is challenged for each risky sign-in, not only once per session. Level 3 (CA303) blocks high-risk sign-ins instead.

---

## Rollout

1. Import in report-only mode and wait one to two weeks.
2. Analyse the report-only impact per policy. Start with CA102 and CA103 (admins, low volume), then CA101, CA104 and CA105.
3. Enable one policy at a time and watch the sign-in logs for failures (`conditionalAccessStatus = failure`).
4. Document every exclusion with owner, reason and review date.

Continue with [Level 2](baseline-level-2.md).
