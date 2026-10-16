<#
.SYNOPSIS
    Compares the Conditional Access policies of a tenant with the baseline
    templates and reports missing policies, changed settings and additional
    exclusions.

.DESCRIPTION
    Read-only. Reads all Conditional Access policies through Microsoft Graph
    v1.0, matches them to the baseline templates by display name and compares
    every setting the template defines.

    Findings per policy:
      Missing                The baseline policy does not exist in the tenant.
      Changed                A setting differs from the template or is not set.
      AddedSetting           The tenant policy sets a condition or control the
                             template does not define.
      ExtraExclusion         The tenant policy excludes users, groups, roles,
                             applications, platforms or locations the template
                             does not exclude. Exclusions are the most common
                             way a policy silently stops protecting.
      BreakGlassNotExcluded  The break-glass group is not excluded, so the
                             policy can lock out the emergency accounts.

    The policy state is reported, not compared: a report-only template that
    is enabled in the tenant is progress, not drift. Tenant policies that are
    not part of the baseline are listed separately.

    Output: Drift.csv with one row per finding and Summary.md with the status
    per policy.

.PARAMETER Level
    Baseline levels to compare against (1, 2, 3). Default: all levels.

.PARAMETER BreakGlassGroupId
    Object ID of the break-glass group that was used when the baseline was
    imported. Replaces the placeholder in the templates.

.PARAMETER NamePrefix
    Display name prefix that was used when the baseline was imported.

.PARAMETER TemplatePath
    Folder that contains the level-1, level-2 and level-3 template folders.

.PARAMETER OutputFolder
    Target folder. Default: .\out\ConditionalAccessDrift-<timestamp>

.EXAMPLE
    .\Compare-ConditionalAccessBaseline.ps1 -BreakGlassGroupId '<group-object-id>'

    Compares the tenant with all three baseline levels.

.EXAMPLE
    .\Compare-ConditionalAccessBaseline.ps1 -Level 1, 2 -BreakGlassGroupId '<group-object-id>' -NamePrefix 'Baseline - '

    Compares with Level 1 and 2 for policies imported with a name prefix.

.NOTES
    Graph permissions (delegated or application): Policy.Read.All
    Directory role (delegated): Security Reader or Global Reader is sufficient.
    Module: Microsoft.Graph.Authentication (Microsoft Graph PowerShell SDK v2)

    The report contains object IDs of your tenant. Do not commit it to a public repository.

    Author : Ramón Lotz
    Version: 1.0.0
#>
#Requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet(1, 2, 3)]
    [int[]]$Level = @(1, 2, 3),

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$')]
    [string]$BreakGlassGroupId,

    [ValidateLength(0, 40)]
    [string]$NamePrefix = '',

    [string]$TemplatePath = (Join-Path -Path $PSScriptRoot -ChildPath '../identity-baselines/conditional-access/policies'),

    [string]$OutputFolder = (Join-Path -Path (Join-Path -Path (Get-Location) -ChildPath 'out') -ChildPath "ConditionalAccessDrift-$(Get-Date -Format 'yyyy-MM-dd_HH-mm')")
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

function ConvertTo-TemplatePolicy {
    <#
    .SYNOPSIS
        Resolves the break-glass placeholder and the name prefix of a template.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TemplateJson,
        [Parameter(Mandatory)][string]$BreakGlassGroupId,
        [string]$NamePrefix = ''
    )

    $json = $TemplateJson.Replace('{{BREAK_GLASS_GROUP_ID}}', $BreakGlassGroupId)
    if ($json -match '\{\{[A-Z_]+\}\}') {
        throw "Unresolved placeholder in template: $($Matches[0])"
    }
    $policy = $json | ConvertFrom-Json
    $policy.displayName = "$NamePrefix$($policy.displayName)"
    $policy
}

function ConvertTo-FlatPolicy {
    <#
    .SYNOPSIS
        Flattens a policy into setting paths (conditions.users.excludeGroups) with sorted string values.
    .DESCRIPTION
        Identity, state and timestamps are skipped. Null values and empty
        arrays or objects are dropped, so a template and the same policy read
        from Graph (which returns every property, mostly null) flatten to the
        same set of paths. Arrays are compared as sets.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Policy)

    $skip = 'id', 'displayName', 'state', 'createdDateTime', 'modifiedDateTime', 'templateId', 'deletedDateTime', 'partialEnablementStrategy'
    $flat = [ordered]@{}
    $queue = [System.Collections.Generic.Queue[object]]::new()
    foreach ($property in $Policy.PSObject.Properties) {
        if ($property.Name -in $skip -or $property.Name -like '@odata*') { continue }
        $queue.Enqueue(@($property.Name, $property.Value))
    }

    while ($queue.Count -gt 0) {
        $item = $queue.Dequeue()
        $path = $item[0]
        $value = $item[1]
        if ($null -eq $value) { continue }

        if ($value -is [System.Management.Automation.PSCustomObject]) {
            foreach ($property in $value.PSObject.Properties) {
                if ($property.Name -like '@odata*') { continue }
                $queue.Enqueue(@("$path.$($property.Name)", $property.Value))
            }
            continue
        }

        if ($value -is [System.Collections.IEnumerable] -and $value -isnot [string]) {
            $items = @(foreach ($element in $value) {
                    if ($null -eq $element) { continue }
                    if ($element -is [System.Management.Automation.PSCustomObject]) { $element | ConvertTo-Json -Depth 10 -Compress }
                    else { [string]$element }
                })
            if ($items.Count -eq 0) { continue }
            $flat[$path] = [string[]]@($items | Sort-Object -Unique)
            continue
        }

        $text = if ($value -is [bool]) { $value.ToString().ToLowerInvariant() } else { [string]$value }
        $flat[$path] = [string[]]@($text)
    }
    $flat
}

function Test-ExclusionPath {
    <#
    .SYNOPSIS
        Returns $true for settings that exclude users, applications, platforms or locations from a policy.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param([Parameter(Mandatory)][string]$Path)

    $Path -match '^conditions\.(users|applications|platforms|locations|clientApplications)\.exclude'
}

function Compare-PolicyToTemplate {
    <#
    .SYNOPSIS
        Compares a flattened tenant policy with a flattened template and returns the findings.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Template,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Tenant,
        [Parameter(Mandatory)][string]$BreakGlassGroupId
    )

    # Graph expands the authentication strength (name, combinations, timestamps); only its ID is a setting.
    $expandedSubtree = '^grantControls\.authenticationStrength\.(?!id$)'
    # Values Graph fills in when a policy does not set them.
    $serverDefault = @{
        'conditions.clientAppTypes'                         = 'all'
        'sessionControls.signInFrequency.authenticationType' = 'primaryAndSecondaryAuthentication'
        'sessionControls.signInFrequency.frequencyInterval'  = 'timeBased'
    }

    foreach ($path in $Template.Keys) {
        $expected = @($Template[$path])
        $actual = @(if ($Tenant.Contains($path)) { $Tenant[$path] })

        if (Test-ExclusionPath -Path $path) {
            foreach ($value in $expected) {
                if ($actual -contains $value) { continue }
                $finding = if ($value -eq $BreakGlassGroupId) { 'BreakGlassNotExcluded' } else { 'Changed' }
                [PSCustomObject]@{ Finding = $finding; Path = $path; Expected = $value; Actual = '(not excluded)' }
            }
            foreach ($value in $actual) {
                if ($expected -contains $value) { continue }
                [PSCustomObject]@{ Finding = 'ExtraExclusion'; Path = $path; Expected = ''; Actual = $value }
            }
            continue
        }

        if ($actual.Count -eq 0) {
            [PSCustomObject]@{ Finding = 'Changed'; Path = $path; Expected = ($expected -join ', '); Actual = '(not set)' }
        }
        elseif (($expected -join '|') -ne ($actual -join '|')) {
            [PSCustomObject]@{ Finding = 'Changed'; Path = $path; Expected = ($expected -join ', '); Actual = ($actual -join ', ') }
        }
    }

    foreach ($path in $Tenant.Keys) {
        if ($Template.Contains($path)) { continue }
        if ($path -match $expandedSubtree) { continue }
        $actual = @($Tenant[$path])
        if (Test-ExclusionPath -Path $path) {
            foreach ($value in $actual) {
                [PSCustomObject]@{ Finding = 'ExtraExclusion'; Path = $path; Expected = ''; Actual = $value }
            }
            continue
        }
        # Graph returns disabled switches as false and fills in defaults; neither is a setting.
        if ($actual.Count -eq 1 -and $actual[0] -eq 'false') { continue }
        if ($actual.Count -eq 1 -and $serverDefault.ContainsKey($path) -and $serverDefault[$path] -eq $actual[0]) { continue }
        [PSCustomObject]@{ Finding = 'AddedSetting'; Path = $path; Expected = ''; Actual = ($actual -join ', ') }
    }
}

function Compare-ConditionalAccessPolicySet {
    <#
    .SYNOPSIS
        Matches tenant policies to templates by display name and returns status and findings per template.
    .OUTPUTS
        PSCustomObject with Results (one per template) and NotInBaseline (tenant policies without template).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$TemplatePolicy,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$TenantPolicy,
        [Parameter(Mandatory)][string]$BreakGlassGroupId
    )

    $byName = @{}
    foreach ($p in $TenantPolicy) {
        $key = ([string]$p.displayName).ToLowerInvariant()
        if (-not $byName.ContainsKey($key)) { $byName[$key] = $p }
    }

    $results = foreach ($t in $TemplatePolicy) {
        $tenant = $byName[([string]$t.displayName).ToLowerInvariant()]
        if (-not $tenant) {
            [PSCustomObject]@{ Policy = $t.displayName; Status = 'Missing'; State = ''; Findings = @() }
            continue
        }
        $findings = @(Compare-PolicyToTemplate -Template (ConvertTo-FlatPolicy -Policy $t) `
                -Tenant (ConvertTo-FlatPolicy -Policy $tenant) -BreakGlassGroupId $BreakGlassGroupId)
        [PSCustomObject]@{
            Policy   = $t.displayName
            Status   = if ($findings.Count -eq 0) { 'Match' } else { 'Drift' }
            State    = $tenant.state
            Findings = $findings
        }
    }

    $templateNames = @($TemplatePolicy | ForEach-Object { ([string]$_.displayName).ToLowerInvariant() })
    $notInBaseline = @($TenantPolicy | Where-Object { $templateNames -notcontains ([string]$_.displayName).ToLowerInvariant() } |
            Sort-Object -Property displayName | Select-Object -Property displayName, state)

    [PSCustomObject]@{
        Results       = @($results)
        NotInBaseline = $notInBaseline
    }
}

function Format-DriftSummary {
    <#
    .SYNOPSIS
        Renders the Markdown summary of a comparison.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][object]$Comparison,
        [string[]]$Header = @()
    )

    $stateLabel = @{ enabled = 'On'; enabledForReportingButNotEnforced = 'Report-only'; disabled = 'Off' }
    $results = @($Comparison.Results)
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('# Conditional Access drift report')
    $lines.Add('')
    foreach ($h in $Header) { $lines.Add("- $h") }
    $lines.Add('')
    $lines.Add("**Baseline policies:** $($results.Count) · match $(@($results | Where-Object Status -EQ 'Match').Count) · drift $(@($results | Where-Object Status -EQ 'Drift').Count) · missing $(@($results | Where-Object Status -EQ 'Missing').Count)")
    $lines.Add('')
    $lines.Add('| Policy | Status | State | Findings |')
    $lines.Add('|---|---|---|---|')
    foreach ($r in $results) {
        $summary = @($r.Findings | Group-Object -Property Finding | ForEach-Object { "$($_.Name) ($($_.Count))" }) -join ', '
        $state = if ($r.State) { $stateLabel[[string]$r.State] } else { '' }
        $lines.Add("| $($r.Policy) | $($r.Status) | $state | $summary |")
    }

    $details = @($results | ForEach-Object { $policy = $_.Policy; $_.Findings | ForEach-Object { $_ | Add-Member -NotePropertyName Policy -NotePropertyValue $policy -Force -PassThru } })
    if ($details.Count -gt 0) {
        $lines.Add('')
        $lines.Add('## Findings')
        $lines.Add('')
        $lines.Add('| Policy | Finding | Setting | Expected | Actual |')
        $lines.Add('|---|---|---|---|---|')
        foreach ($d in $details) {
            $cells = @($d.Policy, $d.Finding, "``$($d.Path)``", $d.Expected, $d.Actual) | ForEach-Object { ([string]$_).Replace('|', '\|') }
            $lines.Add("| $($cells -join ' | ') |")
        }
    }

    $extra = @($Comparison.NotInBaseline)
    if ($extra.Count -gt 0) {
        $lines.Add('')
        $lines.Add('## Tenant policies not in the baseline')
        $lines.Add('')
        $lines.Add('| Policy | State |')
        $lines.Add('|---|---|')
        foreach ($p in $extra) { $lines.Add("| $(([string]$p.displayName).Replace('|', '\|')) | $($stateLabel[[string]$p.state]) |") }
    }

    $lines -join [Environment]::NewLine
}

#endregion Functions

# When the script is dot-sourced (for example by the Pester tests), only load the functions.
if ($MyInvocation.InvocationName -eq '.') { return }

$ErrorActionPreference = 'Stop'

$templates = @(foreach ($file in (Get-BaselineTemplate -Path $TemplatePath -Level $Level)) {
        ConvertTo-TemplatePolicy -TemplateJson (Get-Content -LiteralPath $file.FullName -Raw) -BreakGlassGroupId $BreakGlassGroupId -NamePrefix $NamePrefix
    })

Import-Module Microsoft.Graph.Authentication
Connect-GraphIfNeeded -Scopes 'Policy.Read.All'

Write-Host 'Reading Conditional Access policies ...' -ForegroundColor Cyan
$policies = [System.Collections.Generic.List[object]]::new()
$uri = 'v1.0/identity/conditionalAccess/policies'
while ($uri) {
    $page = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject
    foreach ($p in $page.value) { $policies.Add($p) }
    $uri = $page.'@odata.nextLink'
}

$comparison = Compare-ConditionalAccessPolicySet -TemplatePolicy $templates -TenantPolicy $policies.ToArray() -BreakGlassGroupId $BreakGlassGroupId

New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
$rows = foreach ($r in $comparison.Results) {
    if ($r.Status -eq 'Missing') {
        [PSCustomObject]@{ Policy = $r.Policy; Status = 'Missing'; State = ''; Finding = 'Missing'; Path = ''; Expected = ''; Actual = '' }
        continue
    }
    foreach ($f in $r.Findings) {
        [PSCustomObject]@{ Policy = $r.Policy; Status = $r.Status; State = $r.State; Finding = $f.Finding; Path = $f.Path; Expected = $f.Expected; Actual = $f.Actual }
    }
}
@($rows) | Export-Csv -Path (Join-Path -Path $OutputFolder -ChildPath 'Drift.csv') -NoTypeInformation -Encoding UTF8

$header = @(
    "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    "Levels: $(($Level | Sort-Object -Unique) -join ', ')"
    "Tenant policies: $($policies.Count)"
    "Name prefix: $(if ($NamePrefix) { "'$NamePrefix'" } else { 'none' })"
)
Format-DriftSummary -Comparison $comparison -Header $header |
    Out-File -FilePath (Join-Path -Path $OutputFolder -ChildPath 'Summary.md') -Encoding UTF8

$drift = @($comparison.Results | Where-Object Status -NE 'Match').Count
Write-Host ''
Write-Host "Compared $($templates.Count) baseline policies: $drift with drift or missing. Results: $OutputFolder" -ForegroundColor Green
