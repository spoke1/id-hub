# Conditional Access baselines

Staged Conditional Access policies for Microsoft Entra ID, from a secure-by-default foundation to a Zero Trust posture. Every policy exists twice: as documentation in the level files and as a Graph-ready JSON template in [`policies/`](policies).

## Levels

| Level | Goal | Policies | Documentation |
|---|---|---|---|
| **1 · Foundation** | Close the most common attack paths with minimal user impact | CA101-CA105 | [baseline-level-1.md](baseline-level-1.md) |
| **2 · Enhanced** | MFA everywhere, trusted devices for admins, risk-based responses, token theft paths closed | CA201-CA210 | [baseline-level-2.md](baseline-level-2.md) |
| **3 · Zero Trust** | Phishing-resistant admins, managed devices for all members, strict risk and session controls, workload identities | CA301-CA306 | [baseline-level-3.md](baseline-level-3.md) |

Levels are cumulative. Policies of lower levels stay active: Conditional Access requires *all* applicable policies to be satisfied, so the stricter policy of a higher level always wins. The full comparison is in the [policy matrix](policy-matrix.md).

## Design principles

1. **Report-only first.** Every template has the state `enabledForReportingButNotEnforced`. The import script cannot create enabled policies. You switch a policy to *On* after you have seen its impact in the sign-in logs.
2. **Break-glass exclusion everywhere.** Every user-targeted policy excludes one security group that holds the emergency access accounts (`{{BREAK_GLASS_GROUP_ID}}`). A test in CI fails if a template misses the exclusion.
3. **One purpose per policy.** One policy, one control. That makes report-only results readable and lets you roll back a single control without side effects.
4. **Personas, not individuals.** Policies target `All users`, privileged directory roles or workload identities. Exceptions go through groups, never through individual user objects.
5. **Built-in building blocks.** Authentication strengths instead of the plain MFA checkbox, role template IDs instead of tenant-specific groups. The templates contain no tenant-specific IDs.
6. **Current controls only.** No *approved client app* grant (read-only since 30 June 2026), risk policies in Conditional Access instead of the legacy Identity Protection policies (retired on 1 October 2026).

## Naming convention

```text
CA<level><nn>-<Persona>-<Target>-<Control>[-<Condition>]

CA205-AllUsers-AllApps-RequireMFA-MediumHighSignInRisk
│ │   │        │       │          └ Condition that triggers the policy (optional)
│ │   │        │       └ Grant or session control
│ │   │        └ Applications or user action
│ │   └ Persona: AllUsers, Members (without guests), Admins, WorkloadIdentities
│ └ Number within the level
└ Level (1-3)
```

The number is stable. When you adapt a policy to your tenant, keep the number so the policy stays traceable to the baseline.

## Privileged roles

Policies with the persona `Admins` target these 18 built-in directory roles by role template ID:

Global Administrator, Privileged Role Administrator, Privileged Authentication Administrator, Security Administrator, Conditional Access Administrator, Authentication Policy Administrator, Authentication Administrator, Application Administrator, Cloud Application Administrator, Hybrid Identity Administrator, User Administrator, Helpdesk Administrator, Password Administrator, Exchange Administrator, SharePoint Administrator, Teams Administrator, Intune Administrator, Billing Administrator.

Role-based targeting applies to active role assignments, including roles activated through PIM. Add custom or additional built-in roles if you use them for administration.

## Deployment

```powershell
# 1. Back up the current state
.\scripts\Export-ConditionalAccessPolicy.ps1 -OutputFolder .\out\before-baseline

# 2. Preview, then create Level 1 in report-only mode
.\scripts\Import-ConditionalAccessBaseline.ps1 -Level 1 -BreakGlassGroupId '<group-object-id>' -WhatIf
.\scripts\Import-ConditionalAccessBaseline.ps1 -Level 1 -BreakGlassGroupId '<group-object-id>'

# 3. After one to two weeks: measure the impact per policy
#    (Get-ConditionalAccessInsights.ps1 from the hybrid-workplace-automation repository)
.\Get-ConditionalAccessInsights.ps1 -Days 14

# 4. Switch policies to On one by one, starting with the lowest impact
```

Before step 4:

- Two emergency access accounts are members of the break-glass group and can sign in.
- The report-only impact is understood for every policy you enable. *Would block* means real users lose access.
- Users know what changes for them (MFA registration, device compliance, app protection).
- Admins who will fall under CA301 have a phishing-resistant method registered.

## Licensing

| Capability | Required licence |
|---|---|
| Conditional Access, authentication strengths, device filters, authentication flows | Microsoft Entra ID P1 |
| Sign-in risk and user risk conditions (CA105, CA204, CA205, CA303, CA304) | Microsoft Entra ID P2 |
| Conditional Access for workload identities (CA306) | Microsoft Entra Workload ID Premium |
| Device compliance (CA202, CA302) and app protection (CA208) | Microsoft Intune |

The import script creates each policy individually. If a licence is missing, only the affected policies fail.

## Files

```text
conditional-access/
  README.md                 This page
  baseline-level-1.md       Level 1 policies explained
  baseline-level-2.md       Level 2 policies explained
  baseline-level-3.md       Level 3 policies explained
  policy-matrix.md          Comparison across levels
  policies/
    level-1/*.json          Graph v1.0 conditionalAccessPolicy bodies
    level-2/*.json
    level-3/*.json
```
