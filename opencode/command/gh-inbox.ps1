param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Parse-NullableBool {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    switch ($Value.Trim().ToLowerInvariant()) {
        'true' { return $true }
        'false' { return $false }
        default { throw "Invalid boolean value '$Value'. Expected true or false." }
    }
}

function Convert-SubjectApiUrlToHtmlUrl {
    param(
        [string]$ApiUrl,
        [string]$RepositoryFullName,
        [string]$SubjectType
    )

    if ([string]::IsNullOrWhiteSpace($ApiUrl)) {
        if ($SubjectType -eq 'CheckSuite' -and -not [string]::IsNullOrWhiteSpace($RepositoryFullName)) {
            return "https://github.com/$RepositoryFullName/actions"
        }

        return $null
    }

    if ($ApiUrl -match '^https://api\.github\.com/repos/([^/]+/[^/]+)/issues/(\d+)$') {
        return "https://github.com/$($Matches[1])/issues/$($Matches[2])"
    }

    if ($ApiUrl -match '^https://api\.github\.com/repos/([^/]+/[^/]+)/pulls/(\d+)$') {
        return "https://github.com/$($Matches[1])/pull/$($Matches[2])"
    }

    return $ApiUrl
}

function Get-SubjectNumber {
    param([string]$ApiUrl)

    if ([string]::IsNullOrWhiteSpace($ApiUrl)) {
        return $null
    }

    if ($ApiUrl -match '/(\d+)$') {
        return [int]$Matches[1]
    }

    return $null
}

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

$query = [ordered]@{
    mode = 'window'
    windowDays = 3
    since = (Get-Date).ToUniversalTime().AddDays(-3).ToString('o')
    limit = 10
    reasons = @()
    repos = @()
    participating = $null
    unreadOnly = $null
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
            'reasons' {
                $query.reasons = @($value -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
            }
            'repos' {
                $query.repos = @($value -split ',' | ForEach-Object { $_.Trim().ToLowerInvariant() } | Where-Object { $_ })
            }
            'participating' {
                $query.participating = Parse-NullableBool -Value $value
            }
            'unread-only' {
                $query.unreadOnly = Parse-NullableBool -Value $value
            }
            default {
                $warnings.Add("Unknown option ignored: $arg") | Out-Null
            }
        }

        continue
    }

    $normalizedArg = $arg.Trim().ToLowerInvariant()
    switch -Regex ($normalizedArg) {
        '^unread$' {
            $query.mode = 'unread'
            $query.windowDays = $null
            $query.since = $null
        }
        '^(?<days>\d+)d$' {
            $windowDays = [int]$Matches['days']
            if ($windowDays -lt 1) {
                throw "Invalid window '$arg'. Expected a positive day count like 1d or 3d."
            }

            $query.mode = 'window'
            $query.windowDays = $windowDays
            $query.since = (Get-Date).ToUniversalTime().AddDays(-$windowDays).ToString('o')
        }
        default {
            $warnings.Add("Unknown argument ignored: $arg") | Out-Null
        }
    }
}

$effectiveUnreadOnly = if ($query.mode -eq 'unread') {
    $true
}
elseif ($null -eq $query.unreadOnly) {
    $false
}
else {
    [bool]$query.unreadOnly
}

$endpoint = 'notifications'
$queryParams = New-Object System.Collections.Generic.List[string]

if ($query.mode -eq 'window') {
    $queryParams.Add('all=true') | Out-Null
    $queryParams.Add('since=' + [System.Uri]::EscapeDataString([string]$query.since)) | Out-Null
}

if ($null -ne $query.participating) {
    $queryParams.Add('participating=' + ([string]$query.participating).ToLowerInvariant()) | Out-Null
}

if ($queryParams.Count -gt 0) {
    $endpoint = $endpoint + '?' + ($queryParams -join '&')
}

$rawOutput = & gh api $endpoint --paginate --slurp 2>&1
$exitCode = $LASTEXITCODE
$rawText = ($rawOutput | Out-String).Trim()

if ($exitCode -ne 0) {
    throw "gh api failed: $rawText"
}

$pages = if ([string]::IsNullOrWhiteSpace($rawText)) {
    @()
}
else {
    $rawText | ConvertFrom-Json
}

$allItems = New-Object System.Collections.Generic.List[object]
foreach ($page in @($pages)) {
    if ($null -eq $page) {
        continue
    }

    if ($page -is [System.Collections.IEnumerable] -and -not ($page -is [string])) {
        foreach ($item in $page) {
            if ($null -ne $item) {
                $allItems.Add($item) | Out-Null
            }
        }
    }
    else {
        $allItems.Add($page) | Out-Null
    }
}

$filteredItems = @($allItems.ToArray())

if ($effectiveUnreadOnly) {
    $filteredItems = @($filteredItems | Where-Object { $_.unread })
}

if ($query.reasons.Count -gt 0) {
    $allowedReasons = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($reason in $query.reasons) {
        $allowedReasons.Add($reason) | Out-Null
    }

    $filteredItems = @($filteredItems | Where-Object { $allowedReasons.Contains([string]$_.reason) })
}

if ($query.repos.Count -gt 0) {
    $allowedRepos = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($repo in $query.repos) {
        $allowedRepos.Add($repo) | Out-Null
    }

    $filteredItems = @($filteredItems | Where-Object { $allowedRepos.Contains(([string]$_.repository.full_name).ToLowerInvariant()) })
}

$filteredItems = @(
    $filteredItems |
        Sort-Object -Property @{ Expression = { [DateTimeOffset]::Parse($_.updated_at) }; Descending = $true }
)

$limitedItems = @($filteredItems | Select-Object -First $query.limit)

$normalizedItems = foreach ($item in $limitedItems) {
    $repositoryFullName = [string]$item.repository.full_name
    $apiUrl = if ($null -ne $item.subject.url) { [string]$item.subject.url } else { $null }
    $latestCommentApiUrl = if ($null -ne $item.subject.latest_comment_url) { [string]$item.subject.latest_comment_url } else { $null }

    [pscustomobject]@{
        id = [string]$item.id
        unread = [bool]$item.unread
        reason = [string]$item.reason
        updatedAt = Convert-ToIsoString -Value $item.updated_at
        lastReadAt = Convert-ToIsoString -Value $item.last_read_at
        repository = $repositoryFullName
        repositoryUrl = [string]$item.repository.html_url
        title = [string]$item.subject.title
        subjectType = [string]$item.subject.type
        url = Convert-SubjectApiUrlToHtmlUrl -ApiUrl $apiUrl -RepositoryFullName $repositoryFullName -SubjectType ([string]$item.subject.type)
        apiUrl = $apiUrl
        latestCommentApiUrl = $latestCommentApiUrl
        number = Get-SubjectNumber -ApiUrl $apiUrl
    }
}

$result = [pscustomobject]@{
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    query = [pscustomobject]@{
        mode = [string]$query.mode
        windowDays = $query.windowDays
        since = $query.since
        limit = $query.limit
        reasons = @($query.reasons)
        repos = @($query.repos)
        participating = $query.participating
        unreadOnly = $effectiveUnreadOnly
        endpoint = $endpoint
    }
    totalFetched = $allItems.Count
    totalMatched = $filteredItems.Count
    warnings = @($warnings)
    items = @($normalizedItems)
}

$result | ConvertTo-Json -Depth 6
