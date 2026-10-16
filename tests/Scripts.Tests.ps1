#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.5.0' }

BeforeDiscovery {
    $scripts = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath '../scripts') -Filter '*.ps1'
}

Describe '<_.Name> (static checks)' -ForEach $scripts {
    BeforeAll {
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$parseErrors)
        $content = Get-Content -Path $_.FullName -Raw
        $help = $ast.GetHelpContent()
    }

    It 'parses without errors' {
        $parseErrors | Should -BeNullOrEmpty
    }

    It 'has comment-based help with synopsis, description and examples' {
        $help.Synopsis | Should -Not -BeNullOrEmpty
        $help.Description | Should -Not -BeNullOrEmpty
        $help.Examples.Count | Should -BeGreaterThan 0
    }

    It 'documents every parameter' {
        $documented = $help.Parameters.Keys | ForEach-Object { $_.ToUpperInvariant() }
        foreach ($parameter in $ast.ParamBlock.Parameters) {
            $parameter.Name.VariablePath.UserPath.ToUpperInvariant() | Should -BeIn $documented
        }
    }

    It 'contains no hard-coded GUIDs (tenant, app or object IDs)' {
        $content | Should -Not -Match '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'
    }

    It 'contains no client secrets or plain-text credentials' {
        $content | Should -Not -Match '(?i)client_?secret|-AsPlainText|password\s*='
    }
}

Describe 'Import-ConditionalAccessBaseline.ps1' {
    BeforeAll {
        $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../scripts/Import-ConditionalAccessBaseline.ps1'
        $templateRoot = Join-Path -Path $PSScriptRoot -ChildPath '../identity-baselines/conditional-access/policies'
        $groupId = [guid]::NewGuid().ToString()
        # Mandatory parameters are bound, then the script returns after loading its functions.
        . $scriptPath -Level 1 -BreakGlassGroupId $groupId
    }

    It 'supports -WhatIf' {
        (Get-Command -Name $scriptPath).Parameters.Keys | Should -Contain 'WhatIf'
    }

    It 'cannot create enabled policies' {
        $allowed = (Get-Command -Name $scriptPath).Parameters['State'].Attributes |
            Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] } |
            ForEach-Object { $_.ValidValues }
        $allowed | Should -Not -Contain 'enabled'
        { ConvertTo-PolicyBody -TemplateJson '{"displayName":"x","state":"x"}' -BreakGlassGroupId $groupId -State 'enabled' } |
            Should -Throw '*not allowed*'
    }

    It 'resolves the break-glass placeholder in every template' {
        foreach ($file in (Get-ChildItem -Path $templateRoot -Recurse -Filter '*.json')) {
            $policy = ConvertTo-PolicyBody -TemplateJson (Get-Content -LiteralPath $file.FullName -Raw) `
                -BreakGlassGroupId $groupId -State 'enabledForReportingButNotEnforced'
            ($policy | ConvertTo-Json -Depth 20) | Should -Not -Match '\{\{'
            if ($policy.conditions.users.excludeGroups) {
                $policy.conditions.users.excludeGroups | Should -Contain $groupId
            }
        }
    }

    It 'rejects templates with unknown placeholders' {
        { ConvertTo-PolicyBody -TemplateJson '{"displayName":"x","state":"x","id":"{{OTHER_ID}}"}' -BreakGlassGroupId $groupId -State 'disabled' } |
            Should -Throw '*Unresolved placeholder*'
    }

    It 'applies the name prefix and the requested state' {
        $policy = ConvertTo-PolicyBody -TemplateJson '{"displayName":"CA101-Test","state":"enabled"}' `
            -BreakGlassGroupId $groupId -State 'disabled' -NamePrefix 'Baseline - '
        $policy.displayName | Should -Be 'Baseline - CA101-Test'
        $policy.state | Should -Be 'disabled'
    }

    It 'returns templates of the requested levels in order' {
        $files = @(Get-BaselineTemplate -Path $templateRoot -Level 2, 1)
        $files[0].BaseName | Should -BeLike 'CA101*'
        $files[-1].BaseName | Should -BeLike 'CA2*'
        @($files | Where-Object { $_.BaseName -like 'CA3*' }).Count | Should -Be 0
    }
}

Describe 'Export-ConditionalAccessPolicy.ps1' {
    BeforeAll {
        . (Join-Path -Path $PSScriptRoot -ChildPath '../scripts/Export-ConditionalAccessPolicy.ps1')
        $templateRoot = Join-Path -Path $PSScriptRoot -ChildPath '../identity-baselines/conditional-access/policies'
        $templates = @(Get-ChildItem -Path $templateRoot -Recurse -Filter '*.json' | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json })
    }

    It 'removes read-only properties' {
        $policy = '{"id":"1","createdDateTime":"x","modifiedDateTime":"y","templateId":null,"displayName":"CA101","state":"enabled"}' | ConvertFrom-Json
        $clean = ConvertTo-PolicyTemplate -Policy $policy
        $clean.PSObject.Properties.Name | Should -Be @('displayName', 'state')
    }

    It 'renders one table row per policy' {
        $summary = Format-PolicySummary -Policy $templates
        ($summary -split [Environment]::NewLine).Count | Should -Be ($templates.Count + 2)
    }

    It 'describes grant and session controls' {
        $summary = Format-PolicySummary -Policy $templates
        $summary | Should -Match 'mfa AND passwordChange'
        $summary | Should -Match 'Sign-in frequency: every time'
        $summary | Should -Match 'Persistent browser: never'
        $summary | Should -Match 'Workload identities: ServicePrincipalsInMyTenant'
    }

    It 'replaces IDs with names from the lookup' {
        $summary = Format-PolicySummary -Policy $templates -Lookup @{ '{{BREAK_GLASS_GROUP_ID}}' = 'Emergency access (group)' }
        $summary | Should -Match 'Exclude: Emergency access \(group\)'
    }

    It 'creates safe file names' {
        Get-SafeFileName -Name 'CA101: Block/legacy' | Should -Not -Match '[/:]'
    }
}

Describe 'Compare-ConditionalAccessBaseline.ps1' {
    BeforeAll {
        $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath '../scripts/Compare-ConditionalAccessBaseline.ps1'
        $templateRoot = Join-Path -Path $PSScriptRoot -ChildPath '../identity-baselines/conditional-access/policies'
        $groupId = [guid]::NewGuid().ToString()
        # Mandatory parameters are bound, then the script returns after loading its functions.
        . $scriptPath -BreakGlassGroupId $groupId

        $templates = @(Get-BaselineTemplate -Path $templateRoot -Level 1, 2, 3 | ForEach-Object {
                ConvertTo-TemplatePolicy -TemplateJson (Get-Content -LiteralPath $_.FullName -Raw) -BreakGlassGroupId $groupId
            })

        # Simulates a policy as Graph returns it: same settings plus id, timestamps, nulls and defaults.
        function ConvertTo-GraphPolicy {
            param([object]$Template, [string]$State = 'enabled')
            $policy = $Template | ConvertTo-Json -Depth 20 | ConvertFrom-Json
            $policy.state = $State
            $policy | Add-Member -NotePropertyName id -NotePropertyValue ([guid]::NewGuid().ToString())
            $policy | Add-Member -NotePropertyName createdDateTime -NotePropertyValue '2026-01-01T00:00:00Z'
            $policy | Add-Member -NotePropertyName templateId -NotePropertyValue $null
            # Graph returns unset properties as null or empty arrays.
            foreach ($name in 'signInRiskLevels', 'userRiskLevels', 'platforms', 'locations', 'devices') {
                if (-not $policy.conditions.PSObject.Properties[$name]) {
                    $empty = if ($name -like '*RiskLevels') { @() } else { $null }
                    $policy.conditions | Add-Member -NotePropertyName $name -NotePropertyValue $empty
                }
            }
            if (-not $policy.conditions.users.PSObject.Properties['includeGroups']) {
                $policy.conditions.users | Add-Member -NotePropertyName includeGroups -NotePropertyValue @()
            }
            if ($policy.grantControls) {
                $policy.grantControls | Add-Member -NotePropertyName termsOfUse -NotePropertyValue @() -Force
                if ($policy.grantControls.authenticationStrength) {
                    $policy.grantControls.authenticationStrength | Add-Member -NotePropertyName displayName -NotePropertyValue 'Multifactor authentication' -Force
                    $policy.grantControls.authenticationStrength | Add-Member -NotePropertyName allowedCombinations -NotePropertyValue @('password,microsoftAuthenticatorPush') -Force
                }
            }
            if ($policy.sessionControls) {
                $policy.sessionControls | Add-Member -NotePropertyName disableResilienceDefaults -NotePropertyValue $false -Force
                if ($policy.sessionControls.signInFrequency -and -not $policy.sessionControls.signInFrequency.authenticationType) {
                    $policy.sessionControls.signInFrequency | Add-Member -NotePropertyName authenticationType -NotePropertyValue 'primaryAndSecondaryAuthentication'
                }
            }
            $policy
        }
    }

    It 'reports every template as matching when the tenant equals the baseline' {
        $tenant = @($templates | ForEach-Object { ConvertTo-GraphPolicy -Template $_ })
        $result = Compare-ConditionalAccessPolicySet -TemplatePolicy $templates -TenantPolicy $tenant -BreakGlassGroupId $groupId
        @($result.Results | Where-Object Status -NE 'Match').Policy | Should -BeNullOrEmpty
        $result.NotInBaseline | Should -BeNullOrEmpty
    }

    It 'reports the policy state without treating it as drift' {
        $tenant = @(ConvertTo-GraphPolicy -Template $templates[0] -State 'enabledForReportingButNotEnforced')
        $result = Compare-ConditionalAccessPolicySet -TemplatePolicy @($templates[0]) -TenantPolicy $tenant -BreakGlassGroupId $groupId
        $result.Results[0].Status | Should -Be 'Match'
        $result.Results[0].State | Should -Be 'enabledForReportingButNotEnforced'
    }

    It 'reports missing policies and tenant policies outside the baseline' {
        $other = [PSCustomObject]@{ displayName = 'Custom - Block country'; state = 'enabled'; conditions = [PSCustomObject]@{} }
        $result = Compare-ConditionalAccessPolicySet -TemplatePolicy @($templates[0]) -TenantPolicy @($other) -BreakGlassGroupId $groupId
        $result.Results[0].Status | Should -Be 'Missing'
        $result.NotInBaseline.displayName | Should -Be 'Custom - Block country'
    }

    It 'matches display names case-insensitively' {
        $tenant = ConvertTo-GraphPolicy -Template $templates[0]
        $tenant.displayName = $tenant.displayName.ToUpperInvariant()
        (Compare-ConditionalAccessPolicySet -TemplatePolicy @($templates[0]) -TenantPolicy @($tenant) -BreakGlassGroupId $groupId).Results[0].Status | Should -Be 'Match'
    }

    It 'reports additional exclusions per excluded object' {
        $tenant = ConvertTo-GraphPolicy -Template $templates[0]
        $tenant.conditions.users | Add-Member -NotePropertyName excludeUsers -NotePropertyValue @('user-1', 'user-2') -Force
        $tenant.conditions.users.excludeGroups = @($groupId, 'group-3')
        $result = Compare-ConditionalAccessPolicySet -TemplatePolicy @($templates[0]) -TenantPolicy @($tenant) -BreakGlassGroupId $groupId
        $findings = $result.Results[0].Findings
        $result.Results[0].Status | Should -Be 'Drift'
        @($findings | Where-Object Finding -EQ 'ExtraExclusion').Actual | Sort-Object | Should -Be @('group-3', 'user-1', 'user-2')
    }

    It 'reports a missing break-glass exclusion' {
        $tenant = ConvertTo-GraphPolicy -Template $templates[0]
        $tenant.conditions.users.excludeGroups = @()
        $findings = (Compare-ConditionalAccessPolicySet -TemplatePolicy @($templates[0]) -TenantPolicy @($tenant) -BreakGlassGroupId $groupId).Results[0].Findings
        $findings.Finding | Should -Contain 'BreakGlassNotExcluded'
    }

    It 'reports changed and removed settings' {
        $template = $templates | Where-Object displayName -Like 'CA207*'
        $tenant = ConvertTo-GraphPolicy -Template $template
        $tenant.sessionControls.signInFrequency.value = 24
        $tenant.sessionControls.persistentBrowser = $null
        $findings = (Compare-ConditionalAccessPolicySet -TemplatePolicy @($template) -TenantPolicy @($tenant) -BreakGlassGroupId $groupId).Results[0].Findings
        $changed = @($findings | Where-Object Finding -EQ 'Changed')
        ($changed | Where-Object Path -EQ 'sessionControls.signInFrequency.value').Actual | Should -Be '24'
        ($changed | Where-Object Path -EQ 'sessionControls.persistentBrowser.mode').Actual | Should -Be '(not set)'
    }

    It 'reports added conditions but ignores false switches and Graph defaults' {
        $template = $templates | Where-Object displayName -Like 'CA101*'
        $tenant = ConvertTo-GraphPolicy -Template $template
        $tenant.conditions | Add-Member -NotePropertyName locations -NotePropertyValue ([PSCustomObject]@{ includeLocations = @('AllTrusted') }) -Force
        $findings = @((Compare-ConditionalAccessPolicySet -TemplatePolicy @($template) -TenantPolicy @($tenant) -BreakGlassGroupId $groupId).Results[0].Findings)
        $findings | Should -HaveCount 1
        $findings[0].Finding | Should -Be 'AddedSetting'
        $findings[0].Path | Should -Be 'conditions.locations.includeLocations'
    }

    It 'compares arrays as sets' {
        $flatA = ConvertTo-FlatPolicy -Policy ([PSCustomObject]@{ conditions = [PSCustomObject]@{ clientAppTypes = @('exchangeActiveSync', 'other') } })
        $flatB = ConvertTo-FlatPolicy -Policy ([PSCustomObject]@{ conditions = [PSCustomObject]@{ clientAppTypes = @('other', 'exchangeActiveSync') } })
        @(Compare-PolicyToTemplate -Template $flatA -Tenant $flatB -BreakGlassGroupId $groupId) | Should -HaveCount 0
    }

    It 'renders a summary with status counts and findings' {
        $tenant = ConvertTo-GraphPolicy -Template $templates[0]
        $tenant.conditions.users | Add-Member -NotePropertyName excludeUsers -NotePropertyValue @('user-1') -Force
        $result = Compare-ConditionalAccessPolicySet -TemplatePolicy @($templates[0], $templates[1]) -TenantPolicy @($tenant) -BreakGlassGroupId $groupId
        $summary = Format-DriftSummary -Comparison $result
        $summary | Should -Match 'match 0 · drift 1 · missing 1'
        $summary | Should -Match 'ExtraExclusion \(1\)'
        $summary | Should -Match '`conditions.users.excludeUsers`'
    }
}
