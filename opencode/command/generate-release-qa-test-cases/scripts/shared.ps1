Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Split-TokenList {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return @()
    }

    return @(
        $Value -split '[,;\r\n]+'
        | ForEach-Object { $_.Trim() }
        | Where-Object { $_ }
    )
}

function Test-BotAuthorLogin {
    param([string]$Login)

    if ([string]::IsNullOrWhiteSpace($Login)) {
        return $false
    }

    return $Login -in @('github-actions[bot]', 'github-actions')
}

function Test-BotAutoSyncTitle {
    param([string]$Title)

    if ([string]::IsNullOrWhiteSpace($Title)) {
        return $false
    }

    return $Title -match '^Merge branch dev with rel-\d+\.\d+$'
}

function Get-PrNumberFromMergeSubject {
    param([string]$Subject)

    if ([string]::IsNullOrWhiteSpace($Subject)) {
        return $null
    }

    $match = [regex]::Match($Subject, '#(\d+)')
    if ($match.Success) {
        return [int]$match.Groups[1].Value
    }

    return $null
}

function Get-PathBucket {
    param([string]$Path)

    $normalized = ($Path -replace '\\', '/')
    $segments = $normalized -split '/'
    if ($segments.Length -eq 0) {
        return $normalized
    }

    if ($segments[0] -in @('modules', 'framework', 'themes', 'templates', 'apps', 'src', 'host', 'websites', 'abp', 'aspnet-core', 'angular', 'npm', 'html-build')) {
        if ($segments.Length -ge 2) {
            return "$($segments[0])/$($segments[1])"
        }
    }

    return $segments[0]
}

function Get-GroupHint {
    param(
        [string]$Title,
        [string[]]$Files
    )

    $safeTitle = if ($null -ne $Title) { $Title } else { '' }
    $safeFiles = if ($null -ne $Files) { $Files } else { @() }
    $text = (($safeTitle) + ' ' + ($safeFiles -join ' ')).ToLowerInvariant()

    $rules = @(
        @{ Name = 'Theme and UI Components'; Pattern = 'theme|themes/|wwwroot|blazorise|bootstrap|codemirror|component|layout|menu|toolbar|navbar|react-app|designer-ui|assets/css|styles/' },
        @{ Name = 'Identity and Account Flows'; Pattern = 'identity|account|login|register|permission|role|user|token|openiddict' },
        @{ Name = 'SaaS and Tenant Management'; Pattern = 'saas|tenant|edition|subscription' },
        @{ Name = 'CMS and Content Flows'; Pattern = 'cms|cmskit|docs|blog|content|page' },
        @{ Name = 'Low-Code and Admin Console'; Pattern = 'low-code|lowcode|admin-console|dynamicpage|dynamicentity|designer' },
        @{ Name = 'QA and AI Experience'; Pattern = 'qa|prompt|answer suggestion|ai ' },
        @{ Name = 'Payments and Licensing'; Pattern = 'payment|license|licensing|checkout' },
        @{ Name = 'Messaging and Notifications'; Pattern = 'chat|notification|message' }
    )

    foreach ($rule in $rules) {
        if ($text -match $rule.Pattern) {
            return $rule.Name
        }
    }

    return 'General Application Flows'
}

function Get-PathClassification {
    param([string]$Path)

    $normalized = ($Path -replace '\\', '/').ToLowerInvariant()

    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return 'unknown'
    }

    if ($normalized -match '(^|/)(\.github|eng|build|scripts|nupkg)(/|$)') {
        return 'workflow'
    }

    if ($normalized -match '(^|/)(docs)(/|$)' -or
        $normalized -match '\.md$' -or
        $normalized -match 'latest-versions\.json$' -or
        $normalized -match 'package-version-changes\.md$') {
        return 'docs'
    }

    if ($normalized -match '(^|/)(test|tests)(/|$)' -or
        $normalized -match '\.(spec|test)\.(ts|tsx|js|jsx)$' -or
        $normalized -match '\.tests?(/|\\)') {
        return 'tests'
    }

    if ($normalized -match '(^|/)(directory\.packages\.props|common\.props|version\.props)$' -or
        $normalized -match '\.(sln|slnx|csproj|props|targets)$') {
        return 'infrastructure'
    }

    if ($normalized -match 'wwwroot/' -or
        $normalized -match '/pages/' -or
        $normalized -match '/views/' -or
        $normalized -match '/components/' -or
        $normalized -match '/themes/' -or
        $normalized -match 'react-app/' -or
        $normalized -match 'designer-ui/' -or
        $normalized -match 'demo/react/' -or
        $normalized -match 'angular/' -or
        $normalized -match '/assets/' -or
        $normalized -match '/styles?/' -or
        $normalized -match '\.(razor|cshtml|css|scss|js|ts|tsx)$') {
        return 'ui'
    }

    if ($normalized -match 'modules/(account|identity|permission-management|setting-management|tenant-management|cms-kit|docs|blogging|openiddict|feature-management|file-management|audit-logging|client-simulation)' -or
        $normalized -match 'abp/(account|low-code|qa|saas|cms-kit-pro|admin-console|payment|license)' -or
        $normalized -match 'aspnet-core/.+/(navigation|components|themes)/' -or
        $normalized -match '/localization/') {
        return 'ui-backend'
    }

    if ($normalized -match 'package\.json$' -or $normalized -match 'package-lock\.json$' -or $normalized -match 'yarn\.lock$') {
        return 'package'
    }

    return 'backend'
}

function Get-UiAssessment {
    param(
        [string]$Title,
        [string[]]$Files
    )

    $safeTitle = if ($null -ne $Title) { $Title } else { '' }
    $safeFiles = if ($null -ne $Files) { $Files } else { @() }
    $titleLower = $safeTitle.ToLowerInvariant()

    $counts = [ordered]@{
        ui = 0
        uiBackend = 0
        backend = 0
        package = 0
        docs = 0
        tests = 0
        infrastructure = 0
        workflow = 0
        unknown = 0
    }

    foreach ($file in $safeFiles) {
        switch (Get-PathClassification -Path $file) {
            'ui' { $counts.ui++ }
            'ui-backend' { $counts.uiBackend++ }
            'backend' { $counts.backend++ }
            'package' { $counts.package++ }
            'docs' { $counts.docs++ }
            'tests' { $counts.tests++ }
            'infrastructure' { $counts.infrastructure++ }
            'workflow' { $counts.workflow++ }
            default { $counts.unknown++ }
        }
    }

    $titleUiSignal = ($titleLower -match 'theme|ui|account|identity|permission|tenant|cms|docs|blog|codemirror|blazorise|low-code|lowcode|designer|qa|upload|prompt|ai|license|payment|menu|toolbar|layout|localization|message')
    $titleInfraSignal = ($titleLower -match '^update workflow' -or
        $titleLower -match '^update version' -or
        $titleLower -match '^merge branch rel-' -or
        $titleLower -match '^merge branch dev with rel-' -or
        $titleLower -match '^upgrade mongodb\.driver' -or
        $titleLower -match '^documentation' -or
        $titleLower -match '^docs:' -or
        $titleLower -match 'release announcement')

    $allNonUi = ($counts.ui -eq 0 -and $counts.uiBackend -eq 0 -and $counts.backend -eq 0 -and $counts.package -eq 0)
    $docsOnly = ($counts.docs -gt 0 -and ($counts.ui + $counts.uiBackend + $counts.backend + $counts.package + $counts.infrastructure + $counts.workflow) -eq 0)
    $workflowOnly = ($counts.workflow -gt 0 -and ($counts.ui + $counts.uiBackend + $counts.backend + $counts.package + $counts.docs + $counts.infrastructure) -eq 0)
    $infraOnly = (($counts.infrastructure + $counts.workflow + $counts.docs + $counts.tests) -gt 0 -and ($counts.ui + $counts.uiBackend + $counts.backend + $counts.package) -eq 0)

    $suggestedUiTestable = $false
    $assessmentReason = 'No clear UI verification path detected.'

    if ($counts.ui -gt 0) {
        $suggestedUiTestable = $true
        $assessmentReason = 'Contains UI-facing files.'
    }
    elseif ($counts.uiBackend -gt 0) {
        $suggestedUiTestable = $true
        $assessmentReason = 'Contains backend/module changes that are commonly verified through UI flows.'
    }
    elseif ($counts.package -gt 0 -and $titleUiSignal) {
        $suggestedUiTestable = $true
        $assessmentReason = 'Package changes appear tied to UI modules or demos.'
    }
    elseif ($counts.backend -gt 0 -and $titleUiSignal) {
        $suggestedUiTestable = $true
        $assessmentReason = 'Backend change title suggests a user-visible or UI-verifiable effect.'
    }
    elseif ($docsOnly) {
        $assessmentReason = 'Docs-only change.'
    }
    elseif ($workflowOnly) {
        $assessmentReason = 'Workflow-only change.'
    }
    elseif ($infraOnly -or $titleInfraSignal -or $allNonUi) {
        $assessmentReason = 'Infrastructure/version/technical change without a direct UI path.'
    }

    [pscustomobject]@{
        suggestedUiTestable = $suggestedUiTestable
        assessmentReason = $assessmentReason
        classCounts = [pscustomobject]$counts
    }
}

function Get-TopBuckets {
    param([string[]]$Files)

    $safeFiles = @()
    if ($null -ne $Files) {
        $safeFiles = @($Files)
    }

    if ($safeFiles.Count -eq 0) {
        return @()
    }

    return @(
        $safeFiles
        | Group-Object { Get-PathBucket $_ }
        | Sort-Object Count -Descending
        | Select-Object -First 8
        | ForEach-Object { $_.Name }
    )
}
