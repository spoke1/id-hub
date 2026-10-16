# Threat coverage

Which attacks each baseline policy stops or makes harder, mapped to [MITRE ATT&CK](https://attack.mitre.org/), and which detection in [identity-threat-detections](https://github.com/spoke1/identity-threat-detections) watches for what gets past it.

Use it to explain a policy to stakeholders ("what does this protect us from?"), to prioritise the rollout by threat, and to check that every preventive control has a detective counterpart.

## Policies and the attacks they address

| Policy | Stops or limits | ATT&CK | Watch for gaps with |
|---|---|---|---|
| CA101 Block legacy authentication | Password spraying and credential stuffing over protocols that cannot do MFA (IMAP, POP, SMTP AUTH, Exchange ActiveSync with basic authentication) | [T1110.003](https://attack.mitre.org/techniques/T1110/003/), [T1078.004](https://attack.mitre.org/techniques/T1078/004/) | ITD-E010 legacy authentication success, ITD-E007 password spray |
| CA102 Admins require MFA | Admin sign-in with a stolen or guessed password | T1078.004 | ITD-E007, ITD-E004 |
| CA103 Admin portals require MFA | A stolen password used on the Azure, Entra and Microsoft 365 admin portals | T1078.004 | ITD-E001 |
| CA104 Office 365 requires MFA | A stolen password used for mail, files and Teams | T1078.004, T1110.003 | ITD-E007 |
| CA105 High sign-in risk requires MFA | Sign-ins that Identity Protection rates as high risk, for example from known attacker infrastructure | T1078.004 | ITD-E006 |
| CA201 All apps require MFA | Password-only access to any application | T1078.004, T1110.003 | ITD-E007, ITD-E006 |
| CA202 Admins require a compliant or hybrid-joined device | Admin sign-ins from attacker devices, including adversary-in-the-middle phishing, where the proxy cannot present the device's compliance | [T1557](https://attack.mitre.org/techniques/T1557/), [T1539](https://attack.mitre.org/techniques/T1539/) | ITD-E001 |
| CA203 Block unknown platforms | Sign-ins from scripted tools that send no or unusual device platform information | T1110.003 | ITD-E007 |
| CA204 High user risk requires a password change | Continued use of an account whose credentials Identity Protection considers compromised | T1078.004 | ITD-E006 |
| CA205 Medium and high sign-in risk require MFA | Risky sign-ins below the high threshold | T1078.004 | ITD-E006 |
| CA206 Security info registration requires MFA outside trusted locations | An attacker with a stolen password registering their own authenticator app or phone number | [T1098.005](https://attack.mitre.org/techniques/T1098/005/) | ITD-E006 |
| CA207 Admin sessions 12 hours, no persistent browser | Long-lived admin sessions; shortens the time a stolen admin session cookie stays useful | T1539, [T1550.004](https://attack.mitre.org/techniques/T1550/004/) | ITD-E001, ITD-E004 |
| CA208 App protection on mobile | Corporate data leaving through unmanaged mobile apps. A data protection control rather than a defence against an identity attack | n/a | n/a |
| CA209 Block device code flow | Device code phishing: the victim completes MFA for a code the attacker generated, and the attacker's device receives the tokens | [T1528](https://attack.mitre.org/techniques/T1528/) | ITD-E005 |
| CA210 Block authentication transfer | Moving an authenticated session from a desktop app to a device the attacker controls. No specific ATT&CK technique | n/a | ITD-E005 (related flow) |
| CA301 Admins require phishing-resistant MFA | Phishing of admin MFA: adversary-in-the-middle proxies, MFA fatigue (push bombing), SIM swap and one-time code interception | T1557, [T1621](https://attack.mitre.org/techniques/T1621/), [T1111](https://attack.mitre.org/techniques/T1111/) | ITD-E001, ITD-E004 |
| CA302 Members require a compliant or hybrid-joined device on desktop | User sign-ins from attacker devices, including adversary-in-the-middle phishing | T1557, T1539 | ITD-E006 |
| CA303 Block high sign-in risk | High-risk sign-ins, blocked instead of challenged | T1078.004 | ITD-E006 |
| CA304 Medium and high user risk require a password change | Accounts with likely compromised credentials, from medium risk upwards | T1078.004 | ITD-E006 |
| CA305 Sessions on unmanaged devices 12 hours, no persistent browser | Long sessions on devices where session cookies are easiest to steal | T1539, T1550.004 | n/a |
| CA306 Workload identities only from trusted locations | Use of stolen service principal credentials from outside known networks | T1078.004 | ITD-E002 |

## Attacks Conditional Access does not stop

Conditional Access evaluates sign-ins. These attacks either do not involve a sign-in that a user policy sees, or they change the rules themselves. Each needs another preventive control and a detection.

| Attack | ATT&CK | Why Conditional Access does not help | Prevent with | Detect with |
|---|---|---|---|---|
| Weakening Conditional Access itself | [T1556.009](https://attack.mitre.org/techniques/T1556/009/) | An account with the Conditional Access Administrator role can change any policy | [Security controls Level 3](../security-controls/security-level-3.md): zero standing privilege, CA301 | ITD-E001 |
| Consent phishing | T1528 | The malicious application acts with its own token; user policies do not apply to its API calls | [Security controls Level 1](../security-controls/security-level-1.md): application consent | ITD-E003 |
| Credentials added to an application or service principal | [T1098.001](https://attack.mitre.org/techniques/T1098/001/) | App-only sign-ins bypass user policies. Conditional Access for workload identities covers single-tenant service principals only, with Workload ID Premium | [Security controls Level 2](../security-controls/security-level-2.md): application credentials, CA306 | ITD-E002 |
| Directory role assigned outside PIM | [T1098.003](https://attack.mitre.org/techniques/T1098/003/) | A role assignment is not a sign-in | Security controls Level 2: PIM | ITD-E004 |
| Federation backdoor | [T1484.002](https://attack.mitre.org/techniques/T1484/002/) | Tokens issued by an attacker-controlled identity provider can carry MFA claims | Security controls Level 3: zero standing privilege for Global and Hybrid Identity Administrator | ITD-E009 |
| Misuse of break-glass accounts | T1078.004 | The accounts are excluded from every policy by design | Security controls Level 1: break-glass accounts | ITD-E008 |
| Attacks on Active Directory: DCSync, Kerberoasting, Tier-0 credential exposure | [T1003.006](https://attack.mitre.org/techniques/T1003/006/), [T1558.003](https://attack.mitre.org/techniques/T1558/003/), [T1078.002](https://attack.mitre.org/techniques/T1078/002/) | Kerberos and NTLM inside the network never reach Entra ID | `Get-ADTier0Exposure.ps1` in [hybrid-workplace-automation](https://github.com/spoke1/hybrid-workplace-automation) | ITD-A001, ITD-A004, ITD-A007 |

## How to read the mapping

- **Stops or limits** describes the attack path the policy closes when it is *enabled*. In report-only mode it only tells you how often the path is used.
- A policy reduces risk; it rarely removes it. Exclusions, unlicensed users and clients outside the policy scope are the usual gaps. The drift report (`scripts/Compare-ConditionalAccessBaseline.ps1`) finds exclusions that were added later.
- The detection IDs refer to the rules in [identity-threat-detections](https://github.com/spoke1/identity-threat-detections#detections). Their [coverage page](https://github.com/spoke1/identity-threat-detections/blob/main/docs/coverage.md) shows the mapping from the detection side.
