# Conditional Access baseline · Level 3 · Zero Trust

Level 3 assumes that passwords and one-time codes can be phished and that any unmanaged device can be compromised. Access depends on phishing-resistant authentication, a managed device and a low risk level. Workload identities are included as well.

Prerequisites: Levels 1 and 2 enabled, phishing-resistant methods rolled out to admins (passkeys/FIDO2, Windows Hello for Business or certificate-based authentication), device compliance for Windows and macOS, Entra ID P2. CA306 needs Microsoft Entra Workload ID Premium.

---

## CA301 · Admins require phishing-resistant MFA

| | |
|---|---|
| Users | 18 privileged directory roles, except break-glass |
| Applications | All |
| Grant | Authentication strength *Phishing-resistant MFA* |
| Template | [`CA301-Admins-AllApps-RequirePhishingResistantMFA.json`](policies/level-3/CA301-Admins-AllApps-RequirePhishingResistantMFA.json) |

Adversary-in-the-middle phishing kits steal session cookies after a successful push or OTP prompt. Passkeys, Windows Hello for Business and certificate-based authentication are bound to the origin and the device, so they cannot be relayed.

## CA302 · Members require a compliant or hybrid-joined device on desktops

| | |
|---|---|
| Users | All members (guests excluded), except break-glass |
| Applications | All |
| Condition | Platforms: Windows, macOS |
| Grant | Compliant device **or** hybrid Entra joined device |
| Template | [`CA302-Members-AllApps-RequireCompliantOrHybridDeviceOnDesktop.json`](policies/level-3/CA302-Members-AllApps-RequireCompliantOrHybridDeviceOnDesktop.json) |

Desktop access to company resources only from devices you manage. Mobile devices are covered by app protection (CA208). Guests are excluded because their devices are managed by their own organisation.

## CA303 · Block high sign-in risk

| | |
|---|---|
| Users | All users, except break-glass |
| Applications | All |
| Condition | Sign-in risk: high |
| Grant | Block |
| Template | [`CA303-AllUsers-AllApps-Block-HighSignInRisk.json`](policies/level-3/CA303-AllUsers-AllApps-Block-HighSignInRisk.json) |
| Licence | Entra ID P2 |

At high risk, MFA is no longer considered sufficient: an attacker may already control the second factor. Medium-risk sign-ins are still remediated with MFA (CA205).

## CA304 · Medium or high user risk requires a secure password change

| | |
|---|---|
| Users | All users, except break-glass |
| Applications | All |
| Condition | User risk: medium, high |
| Grant | MFA **and** password change |
| Session | Sign-in frequency: every time |
| Template | [`CA304-AllUsers-AllApps-RequirePasswordChange-MediumHighUserRisk.json`](policies/level-3/CA304-AllUsers-AllApps-RequirePasswordChange-MediumHighUserRisk.json) |
| Licence | Entra ID P2 |

Extends CA204 to medium user risk. For passwordless users, Microsoft offers risk remediation without a password change; evaluate it once most users no longer use passwords.

## CA305 · Session lifetime of 12 hours on unmanaged devices

| | |
|---|---|
| Users | All users, except break-glass |
| Applications | All |
| Condition | Device filter (include): `device.isCompliant -ne True -and device.trustType -ne "ServerAD"` |
| Session | Sign-in frequency: 12 hours · Persistent browser session: never |
| Template | [`CA305-AllUsers-AllApps-SessionLifetime12h-UnmanagedDevices.json`](policies/level-3/CA305-AllUsers-AllApps-SessionLifetime12h-UnmanagedDevices.json) |

The filter matches devices that are neither compliant nor hybrid joined. Because it uses negative operators, it also applies to unregistered devices. Sessions on such devices expire after 12 hours and are not kept after the browser closes.

## CA306 · Block workload identities outside trusted locations

| | |
|---|---|
| Workload identities | All single-tenant service principals of the tenant |
| Applications | All |
| Condition | All locations, except trusted named locations |
| Grant | Block |
| Template | [`CA306-WorkloadIdentities-AllApps-BlockOutsideTrustedLocations.json`](policies/level-3/CA306-WorkloadIdentities-AllApps-BlockOutsideTrustedLocations.json) |
| Licence | Microsoft Entra Workload ID Premium |

Non-human identities with leaked secrets are a growing attack path. This policy allows service principals to authenticate only from your known networks (for example your datacentre egress or CI runners with fixed IPs). It covers single-tenant service principals only; managed identities are not in scope and do not need it, because they have no exportable credentials. Block is the only available grant control for workload identities.

Before enabling it, define trusted named locations for every environment your service principals run in, and review the report-only results carefully: blocked automation fails silently until someone notices.

---

## Rollout

1. Import in report-only mode.
2. CA301: confirm that every admin has registered a phishing-resistant method. Plan how admins recover a lost key.
3. CA302: check the report-only results for members on unmanaged desktops, for example contractors. Provide managed devices or a virtual desktop.
4. CA306: inventory which service principals authenticate from where. Exclude single service principals only with a documented reason.
5. Enable CA303 and CA304 last, once the risk detections in your tenant are well understood.

See the [policy matrix](policy-matrix.md) for the complete comparison.
