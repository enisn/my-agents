param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Convert-ToIsoString {
    param($Value)

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [DateTimeOffset]) {
        return $Value.ToUniversalTime().ToString('o')
    }

    if ($Value -is [DateTime]) {
        return ([DateTimeOffset]$Value).ToUniversalTime().ToString('o')
    }

    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }

    $parsed = [DateTimeOffset]::MinValue
    if ([DateTimeOffset]::TryParse($text, [ref]$parsed)) {
        return $parsed.ToUniversalTime().ToString('o')
    }

    return $text
}

function Invoke-GhJsonArray {
    param([string[]]$Arguments)

    $rawOutput = & gh @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $rawText = ($rawOutput | Out-String).Trim()

    if ($exitCode -ne 0) {
        throw "gh $($Arguments -join ' ') failed: $rawText"
    }

    if ([string]::IsNullOrWhiteSpace($rawText)) {
        return @()
    }

    $parsed = $rawText | ConvertFrom-Json
    if ($parsed -is [System.Collections.IEnumerable] -and -not ($parsed -is [string])) {
        return @($parsed)
    }

    return @($parsed)
}

function Add-RepoArgs {
    param(
        [System.Collections.Generic.List[string]]$Args,
        [string[]]$Repos
    )

    foreach ($repo in $Repos) {
        $Args.Add('-R') | Out-Null
        $Args.Add($repo) | Out-Null
    }
}

function Convert-IssueSearchItem {
    param($Item)

    [pscustomobject]@{
        repository = [string]$Item.repository.nameWithOwner
        title = [string]$Item.title
        number = [int]$Item.number
        state = [string]$Item.state
        updatedAt = Convert-ToIsoString -Value $Item.updatedAt
        url = [string]$Item.url
        authorLogin = if ($null -ne $Item.author) { [string]$Item.author.login } else { $null }
        assignees = @($Item.assignees | ForEach-Object { [string]$_.login })
        labels = @($Item.labels | ForEach-Object { [string]$_.name })
    }
}

function Convert-PrSearchItem {
    param($Item)

    [pscustomobject]@{
        repository = [string]$Item.repository.nameWithOwner
        title = [string]$Item.title
        number = [int]$Item.number
        state = [string]$Item.state
        isDraft = [bool]$Item.isDraft
        updatedAt = Convert-ToIsoString -Value $Item.updatedAt
        url = [string]$Item.url
        authorLogin = if ($null -ne $Item.author) { [string]$Item.author.login } else { $null }
        labels = @($Item.labels | ForEach-Object { [string]$_.name })
    }
}

function Convert-InboxItem {
    param($Item)

    [pscustomobject]@{
        id = [string]$Item.id
        unread = [bool]$Item.unread
        reason = [string]$Item.reason
        updatedAt = Convert-ToIsoString -Value $Item.updatedAt
        lastReadAt = Convert-ToIsoString -Value $Item.lastReadAt
        repository = [string]$Item.repository
        repositoryUrl = [string]$Item.repositoryUrl
        title = [string]$Item.title
        subjectType = [string]$Item.subjectType
        url = [string]$Item.url
        apiUrl = if ($null -ne $Item.apiUrl) { [string]$Item.apiUrl } else { $null }
        latestCommentApiUrl = if ($null -ne $Item.latestCommentApiUrl) { [string]$Item.latestCommentApiUrl } else { $null }
        number = if ($null -ne $Item.number) { [int]$Item.number } else { $null }
    }
}

$query = [ordered]@{
    windowDays = 3
    since = (Get-Date).ToUniversalTime().AddDays(-3).ToString('o')
    limit = 20
    repos = @()
}

$warnings = New-Object System.Collections.Generic.List[string]

foreach ($arg in $CliArgs) {
    if ([string]::IsNullOrWhiteSpace($arg)) {
        continue
    }

    if ($arg -match '^(?<key>[^=]+)=(?<value>.*)$') {
        $key = $Matches['key'].Trim().ToLowerInvariant()
        $value = $Matches['value'].Trim()

        switch ($key) {
            'limit' {
                $parsedLimit = 0
                if (-not [int]::TryParse($value, [ref]$parsedLimit)) {
                    throw "Invalid limit '$value'. Expected an integer."
                }

                if ($parsedLimit -lt 1) {
                    throw "Invalid limit '$value'. Expected a positive integer."
                }

                $query.limit = $parsedLimit
            }
            'repos' {
                $query.repos = @($value -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
            }
            default {
                $warnings.Add("Unknown option ignored: $arg") | Out-Null
            }
        }

        continue
    }

    $normalizedArg = $arg.Trim().ToLowerInvariant()
    switch -Regex ($normalizedArg) {
        '^(?<days>\d+)d$' {
            $windowDays = [int]$Matches['days']
            if ($windowDays -lt 1) {
                throw "Invalid window '$arg'. Expected a positive day count like 1d or 3d."
            }

            $query.windowDays = $windowDays
            $query.since = (Get-Date).ToUniversalTime().AddDays(-$windowDays).ToString('o')
        }
        default {
            $warnings.Add("Unknown argument ignored: $arg") | Out-Null
        }
    }
}

$issueArgs = [System.Collections.Generic.List[string]]::new()
$issueArgs.AddRange([string[]]@(
    'search',
    'issues',
    '--assignee=@me',
    '--state=open',
    '--sort=updated',
    '--order=desc',
    '--json',
    'assignees,author,labels,number,repository,state,title,updatedAt,url',
    '--limit',
    [string]$query.limit
))
Add-RepoArgs -Args $issueArgs -Repos $query.repos

$reviewArgs = [System.Collections.Generic.List[string]]::new()
$reviewArgs.AddRange([string[]]@(
    'search',
    'prs',
    '--review-requested=@me',
    '--state=open',
    '--sort=updated',
    '--order=desc',
    '--json',
    'author,isDraft,labels,number,repository,state,title,updatedAt,url',
    '--limit',
    [string]$query.limit
))
Add-RepoArgs -Args $reviewArgs -Repos $query.repos

$authoredPrArgs = [System.Collections.Generic.List[string]]::new()
$authoredPrArgs.AddRange([string[]]@(
    'search',
    'prs',
    '--author=@me',
    '--state=open',
    '--sort=updated',
    '--order=desc',
    '--json',
    'author,isDraft,labels,number,repository,state,title,updatedAt,url',
    '--limit',
    [string]$query.limit
))
Add-RepoArgs -Args $authoredPrArgs -Repos $query.repos

$assignedIssues = @(
    Invoke-GhJsonArray -Arguments $issueArgs.ToArray() |
        ForEach-Object { Convert-IssueSearchItem -Item $_ }
)

$reviewRequests = @(
    Invoke-GhJsonArray -Arguments $reviewArgs.ToArray() |
        ForEach-Object { Convert-PrSearchItem -Item $_ }
)

$authoredOpenPrs = @(
    Invoke-GhJsonArray -Arguments $authoredPrArgs.ToArray() |
        ForEach-Object { Convert-PrSearchItem -Item $_ }
)

$notificationLimit = [Math]::Min([Math]::Max($query.limit * 2, 20), 60)
$inboxScriptPath = Join-Path $PSScriptRoot 'gh-inbox.ps1'
$inboxArgs = @("$($query.windowDays)d", "limit=$notificationLimit")
if ($query.repos.Count -gt 0) {
    $inboxArgs += 'repos=' + ($query.repos -join ',')
}

$inboxRawOutput = & $inboxScriptPath @inboxArgs 2>&1
$inboxExitCode = $LASTEXITCODE
$inboxRawText = ($inboxRawOutput | Out-String).Trim()

if ($inboxExitCode -ne 0) {
    throw "gh-inbox collector failed: $inboxRawText"
}

$inboxData = if ([string]::IsNullOrWhiteSpace($inboxRawText)) {
    $null
}
else {
    $inboxRawText | ConvertFrom-Json
}

$recentNotifications = if ($null -eq $inboxData -or $null -eq $inboxData.items) {
    @()
}
else {
    @($inboxData.items | ForEach-Object { Convert-InboxItem -Item $_ })
}

$recentActionableNotifications = @(
    $recentNotifications |
        Where-Object {
            $_.reason -in @('assign', 'review_requested', 'ci_activity', 'author')
        }
)

$recentCiActivities = @(
    $recentActionableNotifications |
        Where-Object { $_.reason -eq 'ci_activity' }
)

$result = [pscustomobject]@{
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    query = [pscustomobject]@{
        windowDays = $query.windowDays
        since = $query.since
        limit = $query.limit
        repos = @($query.repos)
        notificationLimit = $notificationLimit
    }
    summary = [pscustomobject]@{
        assignedIssueCount = $assignedIssues.Count
        reviewRequestCount = $reviewRequests.Count
        authoredOpenPrCount = $authoredOpenPrs.Count
        recentActionableNotificationCount = $recentActionableNotifications.Count
        recentCiActivityCount = $recentCiActivities.Count
    }
    warnings = @($warnings)
    assignedIssues = @($assignedIssues)
    reviewRequests = @($reviewRequests)
    authoredOpenPrs = @($authoredOpenPrs)
    recentActionableNotifications = @($recentActionableNotifications)
    recentCiActivities = @($recentCiActivities)
}

$result | ConvertTo-Json -Depth 6
