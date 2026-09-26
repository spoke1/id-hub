# Conditional Access baseline · Level 2 · Enhanced

Level 2 makes MFA universal, ties admin access to trusted devices, responds to identity risk automatically and closes token theft paths such as device code phishing. It is the right target for most organisations.

Prerequisites: Level 1 enabled, Entra ID P1 and P2, devices managed by Intune or hybrid joined, app protection policies for iOS and Android.

---

## CA201 · MFA for all users and all apps

| | |
|---|---|
| Users | All users (including guests), except break-glass |
| Applications | All |
| Grant | Authentication strength *Multifactor authentication* |
| Template | [`CA201-AllUsers-AllApps-RequireMFA.json`](policies/level-2/CA201-AllUsers-AllApps-RequireMFA.json) |

Supersedes CA104. Guests authenticate with MFA as well; configure cross-tenant access settings if you want to trust MFA from partner tenants.

## CA202 · Admins require a compliant or hybrid-joined device

| | |
|---|---|
| Users | 18 privileged directory roles, except break-glass |
| Applications | All |
| Grant | Compliant device **or** hybrid Entra joined device |
| Template | [`CA202-Admins-AllApps-RequireCompliantOrHybridDevice.json`](policies/level-2/CA202-Admins-AllApps-RequireCompliantOrHybridDevice.json) |

Stolen admin credentials or tokens are useless on an attacker's device. Ideally admins use dedicated privileged access workstations.

## CA203 · Block unknown device platforms

| | |
|---|---|
| Users | All users, except break-glass |
| Applications | All |
| Condition | Platforms: all, except Android, iOS, Windows, macOS, Linux |
| Grant | Block |
| Template | [`CA203-AllUsers-AllApps-BlockUnknownPlatforms.json`](policies/level-2/CA203-AllUsers-AllApps-BlockUnknownPlatforms.json) |

Attack tools often send user agents that do not map to a known platform. Legitimate users rarely do.

## CA204 · High user risk requires a secure password change

| | |
|---|---|
| Users | All users, except break-glass |
| Applications | All |
| Condition | User risk: high |
| Grant | MFA **and** password change |
| Session | Sign-in frequency: every time |
| Template | [`CA204-AllUsers-AllApps-RequirePasswordChange-HighUserRisk.json`](policies/level-2/CA204-AllUsers-AllApps-RequirePasswordChange-HighUserRisk.json) |
| Licence | Entra ID P2 |

High user risk means the credentials are probably known to someone else, for example from a leak. A password change after MFA remediates the risk. Requires self-service password reset and, for hybrid users, password writeback. This replaces the legacy user risk policy in Identity Protection, which is retired on 1 October 2026.

## CA205 · Medium or high sign-in risk requires MFA

| | |
|---|---|
| Users | All users, except break-glass |
| Applications | All |
| Condition | Sign-in risk: medium, high |
| Grant | Authentication strength *Multifactor authentication* |
| Session | Sign-in frequency: every time |
| Template | [`CA205-AllUsers-AllApps-RequireMFA-MediumHighSignInRisk.json`](policies/level-2/CA205-AllUsers-AllApps-RequireMFA-MediumHighSignInRisk.json) |
| Licence | Entra ID P2 |

Extends CA105 to medium risk. Replaces the legacy sign-in risk policy in Identity Protection.

## CA206 · Security info registration requires MFA outside trusted locations

| | |
|---|---|
| Users | All members (guests excluded), except break-glass |
| User action | Register security information |
| Condition | All locations, except trusted named locations |
| Grant | Authentication strength *Multifactor authentication* |
| Template | [`CA206-Members-SecurityInfoRegistration-RequireMFAOutsideTrustedLocations.json`](policies/level-2/CA206-Members-SecurityInfoRegistration-RequireMFAOutsideTrustedLocations.json) |

An attacker with a password must not be able to register their own MFA method. New employees receive a Temporary Access Pass, which satisfies the MFA authentication strength, to register their first method. Mark your office networks as trusted named locations before you enable this policy.

## CA207 · Admin session lifetime of 12 hours

| | |
|---|---|
| Users | 18 privileged directory roles, except break-glass |
| Applications | All |
| Session | Sign-in frequency: 12 hours · Persistent browser session: never |
| Template | [`CA207-Admins-AllApps-SessionLifetime12h.json`](policies/level-2/CA207-Admins-AllApps-SessionLifetime12h.json) |

Limits how long a stolen admin session token stays useful. The persistent browser control requires *All resources* as the target, which this policy uses.

## CA208 · App protection on iOS and Android for Microsoft 365

| | |
|---|---|
| Users | All users, except break-glass |
| Applications | Office 365 |
| Condition | Platforms: Android, iOS |
| Grant | Require app protection policy |
| Template | [`CA208-AllUsers-Office365-RequireAppProtectionOnMobile.json`](policies/level-2/CA208-AllUsers-Office365-RequireAppProtectionOnMobile.json) |

Company data on mobile devices stays inside apps with an Intune app protection policy (for example Outlook, Teams, OneDrive), with or without device enrolment. The older *require approved client app* grant is read-only since 30 June 2026 and must not be used in new policies.

## CA209 · Block device code flow

| | |
|---|---|
| Users | All users, except break-glass |
| Applications | All |
| Condition | Authentication flows: device code flow |
| Grant | Block |
| Template | [`CA209-AllUsers-AllApps-BlockDeviceCodeFlow.json`](policies/level-2/CA209-AllUsers-AllApps-BlockDeviceCodeFlow.json) |

Device code phishing tricks users into signing in on the attacker's behalf. Few legitimate scenarios need this flow (some meeting room devices, CLI tools). Put these users or devices into a documented exclusion group.

## CA210 · Block authentication transfer

| | |
|---|---|
| Users | All users, except break-glass |
| Applications | All |
| Condition | Authentication flows: authentication transfer |
| Grant | Block |
| Template | [`CA210-AllUsers-AllApps-BlockAuthenticationTransfer.json`](policies/level-2/CA210-AllUsers-AllApps-BlockAuthenticationTransfer.json) |

Authentication transfer moves a session from a PC to a mobile device, for example via a QR code in Outlook. Blocking it prevents a session from being carried to an unmanaged device.

---

## Rollout

1. Import in report-only mode and wait one to two weeks.
2. Before CA202, make sure every admin has a compliant or hybrid-joined device.
3. Before CA204, check self-service password reset and password writeback.
4. Before CA206, define trusted named locations and a Temporary Access Pass process for onboarding.
5. Enable in this order: CA203, CA209, CA210 (low impact), then CA201, CA205, CA204, CA206, CA207, CA208, CA202.

Continue with [Level 3](baseline-level-3.md).
