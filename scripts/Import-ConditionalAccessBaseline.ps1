<#
.SYNOPSIS
    Creates the Conditional Access baseline policies of one or more levels in
    Microsoft Entra ID, always in report-only (or disabled) state.

.DESCRIPTION
    Reads the JSON templates from identity-baselines/conditional-access/policies,
    replaces the placeholder for the break-glass group and creates each policy
    through Microsoft Graph v1.0.

    Safety rules built into the script:
      - Policies are created in report-only mode (enabledForReportingButNotEnforced)
        or disabled. The script cannot enable a policy. Switching to "On" is a
        deliberate, manual step after reviewing the report-only results.
      - The break-glass group must exist and should have members. Every user
        policy excludes it.
      - Existing policies with the same display name are never modified or
        overwritten; they are skipped.
      - -WhatIf shows what would be created without changing anything.

.PARAMETER Level
    Baseline levels to import (1, 2, 3). Levels are cumulative; import lower
    levels first.

.PARAMETER BreakGlassGroupId
    Object ID of the security group that contains the emergency access
    accounts. Excluded from every user-targeted policy.

.PARAMETER State
    State of the created policies: enabledForReportingButNotEnforced (default)
    or disabled.

.PARAMETER NamePrefix
    Optional prefix for the display names, for example 'Baseline - '.

.PARAMETER TemplatePath
    Folder that contains the level-1, level-2 and level-3 template folders.

.EXAMPLE
    .\Import-ConditionalAccessBaseline.ps1 -Level 1 -BreakGlassGroupId '<group-object-id>' -WhatIf

    Shows which Level 1 policies would be created.

.EXAMPLE
    .\Import-ConditionalAccessBaseline.ps1 -Level 1, 2 -BreakGlassGroupId '<group-object-id>'

    Creates the Level 1 and Level 2 policies in report-only mode.

.NOTES
    Graph permissions (delegated): Policy.ReadWrite.ConditionalAccess, Policy.Read.All,
    GroupMember.Read.All. Directory role: Conditional Access Administrator or
    Security Administrator.
    Module: Microsoft.Graph.Authentication (Microsoft Graph PowerShell SDK v2)

    Licensing: Conditional Access requires Entra ID P1. Risk-based policies
    (CA105, CA204, CA205, CA303, CA304) require Entra ID P2. CA306 requires
    Microsoft Entra Workload ID Premium. Policies the tenant is not licensed for
    fail individually; the others are still created.

    Author : Ramón Lotz
    Version: 1.0.0
#>
#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateSet(1, 2, 3)]
    [int[]]$Level,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$')]
    [string]$BreakGlassGroupId,

    [ValidateSet('enabledForReportingButNotEnforced', 'disabled')]
    [string]$State = 'enabledForReportingButNotEnforced',

    [ValidateLength(0, 40)]
    [string]$NamePrefix = '',

    [string]$TemplatePath = (Join-Path -Path $PSScriptRoot -ChildPath '../identity-baselines/conditional-access/policies')
)

#region Functions

function Connect-GraphIfNeeded {
    <#
    .SYNOPSIS
        Reuses an existing Microsoft Graph session or signs in with the given delegated scopes.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string[]]$Scopes)

    $context = Get-MgContext
    if ($context -and $context.AuthType -eq 'AppOnly') {
        Write-Verbose "Using existing app-only Graph session for app '$($context.AppName)'."
        return
    }
    if ($context) {
        $missing = @($Scopes | Where-Object { $context.Scopes -notcontains $_ })
        if ($missing.Count -eq 0) { return }
        Write-Verbose "Existing Graph session lacks scopes: $($missing -join ', '). Signing in again."
    }
    Connect-MgGraph -Scopes $Scopes -NoWelcome -ErrorAction Stop
}

function Get-BaselineTemplate {
    <#
    .SYNOPSIS
        Returns the template files of the given levels, sorted by policy number.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][int[]]$Level
    )

    foreach ($l in ($Level | Sort-Object -Unique)) {
        $folder = Join-Path -Path $Path -ChildPath "level-$l"
        if (-not (Test-Path -LiteralPath $folder)) { throw "Template folder not found: $folder" }
        Get-ChildItem -LiteralPath $folder -Filter '*.json' | Sort-Object -Property Name
    }
}

function ConvertTo-PolicyBody {
    <#
    .SYNOPSIS
        Resolves the placeholders of a template and returns the policy object ready for Graph.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TemplateJson,
        [Parameter(Mandatory)][string]$BreakGlassGroupId,
        [Parameter(Mandatory)][string]$State,
        [string]$NamePrefix = ''
    )

    $json = $TemplateJson.Replace('{{BREAK_GLASS_GROUP_ID}}', $BreakGlassGroupId)
    if ($json -match '\{\{[A-Z_]+\}\}') {
        throw "Unresolved placeholder in template: $($Matches[0])"
    }

    $policy = $json | ConvertFrom-Json
    if ($State -notin 'enabledForReportingButNotEnforced', 'disabled') {
        throw "State '$State' is not allowed. Policies are created in report-only or disabled state only."
    }
    $policy.state = $State
    $policy.displayName = "$NamePrefix$($policy.displayName)"
    $policy
}

#endregion Functions

# When the script is dot-sourced (for example by the Pester tests), only load the functions.
if ($MyInvocation.InvocationName -eq '.') { return }

$ErrorActionPreference = 'Stop'

Import-Module Microsoft.Graph.Authentication
Connect-GraphIfNeeded -Scopes 'Policy.ReadWrite.ConditionalAccess', 'Policy.Read.All', 'GroupMember.Read.All'

# 1. Break-glass group must exist, otherwise every policy would exclude nothing.
$group = Invoke-MgGraphRequest -Method GET -Uri "v1.0/groups/$($BreakGlassGroupId)?`$select=id,displayName" -OutputType PSObject
$members = Invoke-MgGraphRequest -Method GET -Uri "v1.0/groups/$($BreakGlassGroupId)/members?`$select=id&`$top=10" -OutputType PSObject
if (@($members.value).Count -eq 0) {
    Write-Warning "The break-glass group '$($group.displayName)' has no members. Add the emergency access accounts before enabling any policy."
}
Write-Host "Break-glass group: $($group.displayName)" -ForegroundColor Cyan

# 2. Existing policies, to skip names that already exist.
$existing = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$uri = 'v1.0/identity/conditionalAccess/policies?$select=displayName'
while ($uri) {
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject
    foreach ($p in $page.value) { [void]$existing.Add($p.displayName) }
    $uri = $page.'@odata.nextLink'
}

# 3. Create the policies.
$results = foreach ($file in (Get-BaselineTemplate -Path $TemplatePath -Level $Level)) {
    $policy = ConvertTo-PolicyBody -TemplateJson (Get-Content -LiteralPath $file.FullName -Raw) `
        -BreakGlassGroupId $BreakGlassGroupId -State $State -NamePrefix $NamePrefix
    $name = $policy.displayName

    if ($existing.Contains($name)) {
        [PSCustomObject]@{ Policy = $name; Result = 'Skipped'; Detail = 'A policy with this name already exists.' }
        continue
    }

    if (-not $PSCmdlet.ShouldProcess($name, "Create Conditional Access policy ($State)")) {
        [PSCustomObject]@{ Policy = $name; Result = 'WhatIf'; Detail = '' }
        continue
    }

    try {
        $body = $policy | ConvertTo-Json -Depth 20
        $created = Invoke-MgGraphRequest -Method POST -Uri 'v1.0/identity/conditionalAccess/policies' `
            -Body $body -ContentType 'application/json' -OutputType PSObject
        [PSCustomObject]@{ Policy = $name; Result = 'Created'; Detail = $created.id }
    }
    catch {
        [PSCustomObject]@{ Policy = $name; Result = 'Failed'; Detail = $_.Exception.Message }
    }
}

$results | Format-Table -AutoSize -Wrap
$failed = @($results | Where-Object Result -EQ 'Failed').Count
if ($failed -gt 0) {
    Write-Warning "$failed policies could not be created. Missing licences (P2, Workload ID Premium) are the most common cause."
}
Write-Host 'Next step: review the report-only results in the sign-in logs before switching any policy to On.' -ForegroundColor Green
