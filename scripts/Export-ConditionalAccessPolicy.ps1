<#
.SYNOPSIS
    Exports all Conditional Access policies of a tenant to JSON and a Markdown
    overview. Use it as a backup before changes and as living documentation.

.DESCRIPTION
    Read-only. Reads all Conditional Access policies through Microsoft Graph
    v1.0 and writes:
      - one JSON file per policy, without read-only properties (id, timestamps),
        in the same format as the baseline templates of this repository
      - Policies.md, a table with state, users, applications, conditions,
        grant and session controls per policy

    With -ResolveNames, role template IDs and the IDs of users and groups in
    the Markdown overview are replaced with display names.

.PARAMETER OutputFolder
    Target folder. Default: .\out\ConditionalAccess-<timestamp>

.PARAMETER ResolveNames
    Resolves role, user and group IDs to display names in the overview
    (requires Directory.Read.All).

.EXAMPLE
    .\Export-ConditionalAccessPolicy.ps1

    Exports all policies to .\out\ConditionalAccess-<timestamp>.

.EXAMPLE
    .\Export-ConditionalAccessPolicy.ps1 -ResolveNames -OutputFolder .\ca-backup

    Exports all policies with readable names in the overview.

.NOTES
    Graph permissions (delegated or application): Policy.Read.All
    With -ResolveNames additionally: Directory.Read.All
    Module: Microsoft.Graph.Authentication (Microsoft Graph PowerShell SDK v2)

    The export contains object IDs of your tenant. Do not commit it to a public repository.

    Author : Ramón Lotz
    Version: 1.0.0
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$OutputFolder = (Join-Path -Path (Join-Path -Path (Get-Location) -ChildPath 'out') -ChildPath "ConditionalAccess-$(Get-Date -Format 'yyyy-MM-dd_HH-mm')"),

    [switch]$ResolveNames
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
        $missing = @($Scopes | Where-Object {
                $context.Scopes -notcontains $_ -and $context.Scopes -notcontains ($_ -replace '\.Read\.', '.ReadWrite.')
            })
        if ($missing.Count -eq 0) { return }
        Write-Verbose "Existing Graph session lacks scopes: $($missing -join ', '). Signing in again."
    }
    Connect-MgGraph -Scopes $Scopes -NoWelcome -ErrorAction Stop
}

function ConvertTo-PolicyTemplate {
    <#
    .SYNOPSIS
        Removes read-only and empty properties from a policy so it can be re-imported.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Policy)

    $readOnly = 'id', 'createdDateTime', 'modifiedDateTime', 'templateId', '@odata.context', 'deletedDateTime'
    $ordered = [ordered]@{}
    foreach ($property in $Policy.PSObject.Properties) {
        if ($property.Name -in $readOnly) { continue }
        if ($null -eq $property.Value) { continue }
        $ordered[$property.Name] = $property.Value
    }
    [PSCustomObject]$ordered
}

function Get-SafeFileName {
    <#
    .SYNOPSIS
        Replaces characters that are not valid in Windows, macOS or Linux file names.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][string]$Name)

    # Fixed Windows character set, so exports are portable between operating systems.
    ($Name -replace '[\\/:*?"<>|\x00-\x1F]', '_').Trim()
}

function Format-IdList {
    <#
    .SYNOPSIS
        Joins a list of IDs or keywords, replacing IDs with names where a lookup is available.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [AllowNull()][object[]]$Value,
        [hashtable]$Lookup = @{}
    )

    $items = @($Value | Where-Object { $_ })
    if ($items.Count -eq 0) { return '' }
    ($items | ForEach-Object { if ($Lookup.ContainsKey([string]$_)) { $Lookup[[string]$_] } else { [string]$_ } }) -join ', '
}

function Format-PolicySummary {
    <#
    .SYNOPSIS
        Renders a one-line Markdown summary per policy.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Policy,
        [hashtable]$Lookup = @{}
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('| Policy | State | Users | Applications | Conditions | Grant | Session |')
    $lines.Add('|---|---|---|---|---|---|---|')

    foreach ($p in ($Policy | Sort-Object -Property displayName)) {
        $c = $p.conditions
        $u = $c.users

        $users = @()
        $include = Format-IdList -Value (@($u.includeUsers) + @($u.includeGroups) + @($u.includeRoles)) -Lookup $Lookup
        $exclude = Format-IdList -Value (@($u.excludeUsers) + @($u.excludeGroups) + @($u.excludeRoles)) -Lookup $Lookup
        if ($include) { $users += "Include: $include" }
        if ($exclude) { $users += "Exclude: $exclude" }
        if ($c.clientApplications.includeServicePrincipals) {
            $users += "Workload identities: $(Format-IdList -Value $c.clientApplications.includeServicePrincipals)"
        }

        $applications = @()
        if ($c.applications.includeApplications) { $applications += Format-IdList -Value $c.applications.includeApplications }
        if ($c.applications.includeUserActions) { $applications += Format-IdList -Value $c.applications.includeUserActions }
        if ($c.applications.excludeApplications) { $applications += "Exclude: $(Format-IdList -Value $c.applications.excludeApplications)" }

        $conditions = @()
        if ($c.clientAppTypes -and ($c.clientAppTypes -join ',') -ne 'all') { $conditions += "Client apps: $($c.clientAppTypes -join ', ')" }
        if ($c.platforms.includePlatforms) {
            $platform = "Platforms: $($c.platforms.includePlatforms -join ', ')"
            if ($c.platforms.excludePlatforms) { $platform += " (except $($c.platforms.excludePlatforms -join ', '))" }
            $conditions += $platform
        }
        if ($c.locations.includeLocations) {
            $location = "Locations: $($c.locations.includeLocations -join ', ')"
            if ($c.locations.excludeLocations) { $location += " (except $($c.locations.excludeLocations -join ', '))" }
            $conditions += $location
        }
        if ($c.signInRiskLevels) { $conditions += "Sign-in risk: $($c.signInRiskLevels -join ', ')" }
        if ($c.userRiskLevels) { $conditions += "User risk: $($c.userRiskLevels -join ', ')" }
        if ($c.devices.deviceFilter.rule) { $conditions += "Device filter ($($c.devices.deviceFilter.mode)): ``$($c.devices.deviceFilter.rule)``" }
        if ($c.authenticationFlows.transferMethods) { $conditions += "Auth flows: $($c.authenticationFlows.transferMethods)" }

        $grant = @()
        $g = $p.grantControls
        if ($g) {
            $controls = @($g.builtInControls | Where-Object { $_ })
            if ($g.authenticationStrength) {
                $strengthName = if ($g.authenticationStrength.displayName) { $g.authenticationStrength.displayName } else { $g.authenticationStrength.id }
                $controls += "authStrength: $strengthName"
            }
            if ($controls.Count -gt 0) { $grant += ($controls -join " $($g.operator) ") }
        }

        $session = @()
        $s = $p.sessionControls
        if ($s.signInFrequency.isEnabled) {
            $session += if ($s.signInFrequency.frequencyInterval -eq 'everyTime') { 'Sign-in frequency: every time' }
            else { "Sign-in frequency: $($s.signInFrequency.value) $($s.signInFrequency.type)" }
        }
        if ($s.persistentBrowser.isEnabled) { $session += "Persistent browser: $($s.persistentBrowser.mode)" }

        $cells = @($p.displayName, $p.state, ($users -join '<br>'), ($applications -join '<br>'),
            ($conditions -join '<br>'), ($grant -join '<br>'), ($session -join '<br>')) |
            ForEach-Object { ([string]$_).Replace('|', '\|') }
        $lines.Add("| $($cells -join ' | ') |")
    }

    $lines -join [Environment]::NewLine
}

#endregion Functions

# When the script is dot-sourced (for example by the Pester tests), only load the functions.
if ($MyInvocation.InvocationName -eq '.') { return }

$ErrorActionPreference = 'Stop'

Import-Module Microsoft.Graph.Authentication
$scopes = @('Policy.Read.All')
if ($ResolveNames) { $scopes += 'Directory.Read.All' }
Connect-GraphIfNeeded -Scopes $scopes

Write-Host 'Reading Conditional Access policies ...' -ForegroundColor Cyan
$policies = [System.Collections.Generic.List[object]]::new()
$uri = 'v1.0/identity/conditionalAccess/policies'
while ($uri) {
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject
    foreach ($p in $page.value) { $policies.Add($p) }
    $uri = $page.'@odata.nextLink'
}

$lookup = @{}
if ($ResolveNames) {
    foreach ($template in (Invoke-MgGraphRequest -Method GET -Uri 'v1.0/directoryRoleTemplates?$select=id,displayName' -OutputType PSObject).value) {
        $lookup[$template.id] = "$($template.displayName) (role)"
    }
    $ids = @($policies | ForEach-Object {
            $u = $_.conditions.users
            @($u.includeUsers) + @($u.excludeUsers) + @($u.includeGroups) + @($u.excludeGroups)
        } | Where-Object { $_ -match '^[0-9a-fA-F-]{36}$' } | Sort-Object -Unique)
    for ($i = 0; $i -lt $ids.Count; $i += 1000) {
        $batch = $ids[$i..([Math]::Min($i + 999, $ids.Count - 1))]
        $body = @{ ids = $batch; types = @('user', 'group') } | ConvertTo-Json
        # getByIds is a read operation that uses POST for the ID list.
        $objects = Invoke-MgGraphRequest -Method POST -Uri 'v1.0/directoryObjects/getByIds' -Body $body -ContentType 'application/json' -OutputType PSObject
        foreach ($o in $objects.value) {
            $lookup[$o.id] = if ($o.userPrincipalName) { $o.userPrincipalName } else { "$($o.displayName) (group)" }
        }
    }
}

$policyFolder = Join-Path -Path $OutputFolder -ChildPath 'policies'
New-Item -ItemType Directory -Path $policyFolder -Force | Out-Null

foreach ($p in $policies) {
    $file = Join-Path -Path $policyFolder -ChildPath "$(Get-SafeFileName -Name $p.displayName).json"
    ConvertTo-PolicyTemplate -Policy $p | ConvertTo-Json -Depth 20 | Out-File -FilePath $file -Encoding UTF8
}

$overview = @(
    '# Conditional Access policies'
    ''
    "- Exported: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    "- Policies: $($policies.Count) (on: $(@($policies | Where-Object state -EQ 'enabled').Count), report-only: $(@($policies | Where-Object state -EQ 'enabledForReportingButNotEnforced').Count), off: $(@($policies | Where-Object state -EQ 'disabled').Count))"
    ''
    (Format-PolicySummary -Policy $policies.ToArray() -Lookup $lookup)
) -join [Environment]::NewLine
$overview | Out-File -FilePath (Join-Path -Path $OutputFolder -ChildPath 'Policies.md') -Encoding UTF8

Write-Host ''
Write-Host "Exported $($policies.Count) policies to $OutputFolder" -ForegroundColor Green
