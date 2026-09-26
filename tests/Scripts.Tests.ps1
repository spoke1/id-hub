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
