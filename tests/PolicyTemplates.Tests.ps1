#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.5.0' }

# Validates every Conditional Access template against the design rules of this
# repository and against constraints of the Microsoft Graph API.

BeforeDiscovery {
    $root = Join-Path -Path $PSScriptRoot -ChildPath '../identity-baselines/conditional-access/policies'
    $templates = foreach ($file in (Get-ChildItem -Path $root -Recurse -Filter '*.json' | Sort-Object -Property Name)) {
        @{
            Name  = $file.BaseName
            Path  = $file.FullName
            Level = [int]($file.Directory.Name -replace '^level-', '')
        }
    }
}

BeforeAll {
    # Privileged directory roles (role template IDs are identical in every tenant).
    $privilegedRoles = @(
        '62e90394-69f5-4237-9190-012177145e10' # Global Administrator
        'e8611ab8-c189-46e8-94e1-60213ab1f814' # Privileged Role Administrator
        '7be44c8a-adaf-4e2a-84d6-ab2649e08a13' # Privileged Authentication Administrator
        '194ae4cb-b126-40b2-bd5b-6091b380977d' # Security Administrator
        'b1be1c3e-b65d-4f19-8427-f6fa0d97feb9' # Conditional Access Administrator
        '0526716b-113d-4c15-b2c8-68e3c22b9f80' # Authentication Policy Administrator
        'c4e39bd9-1100-46d3-8c65-fb160da0071f' # Authentication Administrator
        '9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3' # Application Administrator
        '158c047a-c907-4556-b7ef-446551a6b5f7' # Cloud Application Administrator
        '8ac3fc64-6eca-42ea-9e69-59f4c7b60eb2' # Hybrid Identity Administrator
        'fe930be7-5e62-47db-91af-98c3a49a38b1' # User Administrator
        '729827e3-9c14-49f7-bb1b-9608f156bbb8' # Helpdesk Administrator
        '966707d0-3269-4727-9be2-8c3a10f19b9d' # Password Administrator
        '29232cdf-9323-42fd-ade2-1d097af3e4de' # Exchange Administrator
        'f28a1f50-f6e7-4571-818b-6a12f2af6b6c' # SharePoint Administrator
        '69091246-20e8-4a56-aa4d-066075b2a7a8' # Teams Administrator
        '3a2c62db-5318-420d-8d74-23affee5d9d5' # Intune Administrator
        'b0f54661-2d74-4c50-afa3-1ec803f12efe' # Billing Administrator
    )
    # Built-in authentication strengths: Multifactor authentication, Phishing-resistant MFA.
    $builtInStrengths = @('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000004')
    $allowedIds = $privilegedRoles + $builtInStrengths
}

Describe '<Name>' -ForEach $templates {
    BeforeAll {
        $raw = Get-Content -LiteralPath $Path -Raw
        $policy = $raw | ConvertFrom-Json
        $conditions = $policy.conditions
        $grant = $policy.grantControls
        $session = $policy.sessionControls
        $isWorkloadIdentityPolicy = [bool]$conditions.clientApplications.includeServicePrincipals
    }

    It 'has a displayName equal to the file name' {
        $policy.displayName | Should -Be $Name
    }

    It 'follows the naming convention CA<level><nn>-<Persona>-<Target>-<Control>[-<Condition>]' {
        $Name | Should -Match '^CA[1-3]\d{2}(-[A-Za-z0-9]+){3,4}$'
    }

    It 'is stored in the folder of its level' {
        [int]$Name.Substring(2, 1) | Should -Be $Level
    }

    It 'is created in report-only state' {
        $policy.state | Should -Be 'enabledForReportingButNotEnforced'
    }

    It 'excludes the break-glass group' {
        if ($isWorkloadIdentityPolicy) {
            Set-ItResult -Skipped -Because 'workload identity policies do not target users'
            return
        }
        $conditions.users.excludeGroups | Should -Contain '{{BREAK_GLASS_GROUP_ID}}'
    }

    It 'contains no tenant-specific IDs' {
        $ids = [regex]::Matches($raw, '[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}') | ForEach-Object { $_.Value }
        foreach ($id in $ids) { $id | Should -BeIn $allowedIds }
    }

    It 'uses no placeholder other than {{BREAK_GLASS_GROUP_ID}}' {
        $placeholders = [regex]::Matches($raw, '\{\{[A-Z_]+\}\}') | ForEach-Object { $_.Value } | Sort-Object -Unique
        foreach ($p in $placeholders) { $p | Should -Be '{{BREAK_GLASS_GROUP_ID}}' }
    }

    It 'has at least one grant or session control' {
        ($grant -or $session) | Should -BeTrue
    }

    It 'does not use the retired approvedApplication control' {
        $raw | Should -Not -Match 'approvedApplication'
    }

    It 'does not combine an authentication strength with the mfa control' {
        if ($grant.authenticationStrength) {
            $grant.builtInControls | Should -Not -Contain 'mfa'
        }
    }

    It 'combines passwordChange with mfa using AND' {
        if ($grant.builtInControls -contains 'passwordChange') {
            $grant.operator | Should -Be 'AND'
            $grant.builtInControls | Should -Contain 'mfa'
        }
    }

    It 'uses sign-in frequency "every time" only for risk-based policies' {
        if ($session.signInFrequency.frequencyInterval -eq 'everyTime') {
            ($conditions.signInRiskLevels -or $conditions.userRiskLevels) | Should -BeTrue
        }
    }

    It 'uses the persistent browser control only together with all cloud apps' {
        if ($session.persistentBrowser) {
            $conditions.applications.includeApplications | Should -Be @('All')
        }
    }

    It 'targets the complete privileged role set when it targets roles' {
        if ($conditions.users.includeRoles) {
            @($conditions.users.includeRoles | Sort-Object) | Should -Be @($privilegedRoles | Sort-Object)
        }
    }

    It 'only allows block for workload identities' {
        if ($isWorkloadIdentityPolicy) {
            $grant.builtInControls | Should -Be @('block')
        }
    }
}

Describe 'Template set' {
    BeforeAll {
        $root = Join-Path -Path $PSScriptRoot -ChildPath '../identity-baselines/conditional-access/policies'
        $names = Get-ChildItem -Path $root -Recurse -Filter '*.json' | ForEach-Object { $_.BaseName }
    }

    It 'has unique policy numbers' {
        $numbers = $names | ForEach-Object { $_.Substring(0, 5) }
        @($numbers | Sort-Object -Unique).Count | Should -Be @($numbers).Count
    }

    It 'contains templates for all three levels' {
        foreach ($level in 1..3) {
            @($names | Where-Object { $_ -like "CA$level*" }).Count | Should -BeGreaterThan 0
        }
    }
}
