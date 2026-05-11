[CmdletBinding()]
param(
    [ValidateSet("Prepare", "Scan", "CommitPush")]
    [string]$Mode = "Prepare",
    [string]$RawArguments = "",
    [string]$RepoRoot = "",
    [string]$LocalRoot = "",
    [string]$CommitMessage = "Sync OpenCode runtime assets",
    [switch]$NoPush,
    [switch]$Json
)

$ErrorActionPreference = "Stop"

$SyncPrefixes = @(
    "AGENTS.md",
    "agent",
    "agents",
    "command",
    "skills",
    "hooks",
    "plugin",
    "plugins",
    "mcp-servers",
    "tool",
    "tools",
    "opencode.json",
    "opencode.jsonc",
    "settings.json"
)

function Get-DefaultRepoRoot {
    if ($env:OPENCODE_SYNC_REPO) { return $env:OPENCODE_SYNC_REPO }
    return "C:\P\my-agents"
}

function Get-DefaultLocalRoot {
    if ($env:OPENCODE_HOME) { return $env:OPENCODE_HOME }
    if ($HOME) { return (Join-Path $HOME ".config\opencode") }
    if ($env:USERPROFILE) { return (Join-Path $env:USERPROFILE ".config\opencode") }
    throw "Unable to resolve the local OpenCode root. Pass local=<path>."
}

function Trim-OuterQuotes {
    param([string]$Value)

    if ($null -eq $Value) { return $Value }
    $result = $Value.Trim()
    if ($result.Length -ge 2) {
        $first = $result.Substring(0, 1)
        $last = $result.Substring($result.Length - 1, 1)
        if (($first -eq '"' -and $last -eq '"') -or ($first -eq "'" -and $last -eq "'")) {
            return $result.Substring(1, $result.Length - 2)
        }
    }
    return $result
}

function Split-RawArguments {
    param([string]$Raw)

    if ([string]::IsNullOrWhiteSpace($Raw)) { return @() }
    $matches = [regex]::Matches($Raw, '"[^"]*"|''[^'']*''|\S+')
    $tokens = New-Object System.Collections.Generic.List[string]
    foreach ($match in $matches) {
        $tokens.Add((Trim-OuterQuotes $match.Value))
    }
    return $tokens.ToArray()
}

function Test-Truthy {
    param([string]$Value)
    return $Value -match '^(1|true|yes|y|on)$'
}

function Test-Falsy {
    param([string]$Value)
    return $Value -match '^(0|false|no|n|off)$'
}

$EffectiveRepoRoot = if ([string]::IsNullOrWhiteSpace($RepoRoot)) { Get-DefaultRepoRoot } else { $RepoRoot }
$EffectiveLocalRoot = if ([string]::IsNullOrWhiteSpace($LocalRoot)) { Get-DefaultLocalRoot } else { $LocalRoot }
$EffectiveCommitMessage = $CommitMessage
$EffectiveNoPush = [bool]$NoPush

foreach ($token in (Split-RawArguments $RawArguments)) {
    if ([string]::IsNullOrWhiteSpace($token)) { continue }

    $equalsIndex = $token.IndexOf('=')
    if ($equalsIndex -lt 0) {
        $lowerToken = $token.ToLowerInvariant()
        if ($lowerToken -eq "no-push") { $EffectiveNoPush = $true }
        elseif ($lowerToken -eq "push") { $EffectiveNoPush = $false }
        continue
    }

    $key = $token.Substring(0, $equalsIndex).Trim().ToLowerInvariant()
    $value = Trim-OuterQuotes ($token.Substring($equalsIndex + 1))

    switch ($key) {
        "repo" { $EffectiveRepoRoot = $value }
        "reporoot" { $EffectiveRepoRoot = $value }
        "repository" { $EffectiveRepoRoot = $value }
        "local" { $EffectiveLocalRoot = $value }
        "localroot" { $EffectiveLocalRoot = $value }
        "opencodehome" { $EffectiveLocalRoot = $value }
        "message" { $EffectiveCommitMessage = $value }
        "commitmessage" { $EffectiveCommitMessage = $value }
        "no-push" {
            if (Test-Falsy $value) { $EffectiveNoPush = $false } else { $EffectiveNoPush = $true }
        }
        "push" {
            if (Test-Falsy $value) { $EffectiveNoPush = $true }
            elseif (Test-Truthy $value) { $EffectiveNoPush = $false }
        }
    }
}

function Resolve-ExistingPath {
    param([string]$Path, [string]$Name)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Name does not exist: $Path"
    }
    return (Resolve-Path -LiteralPath $Path).Path
}

$EffectiveRepoRoot = Resolve-ExistingPath $EffectiveRepoRoot "Repository root"
$EffectiveLocalRoot = Resolve-ExistingPath $EffectiveLocalRoot "Local OpenCode root"
$RepoRuntimeRoot = Join-Path $EffectiveRepoRoot "opencode"
$RepoRuntimeRoot = Resolve-ExistingPath $RepoRuntimeRoot "Repository OpenCode runtime root"

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [switch]$AllowNonZero
    )

    & git @Arguments
    $exitCode = $LASTEXITCODE
    if (-not $AllowNonZero -and $exitCode -ne 0) {
        throw "git $($Arguments -join ' ') failed with exit code $exitCode"
    }
    return $exitCode
}

function Get-GitStatus {
    $status = & git -C $EffectiveRepoRoot status --short
    if ($LASTEXITCODE -ne 0) {
        throw "git status failed with exit code $LASTEXITCODE"
    }
    return @($status)
}

function Normalize-RelativePath {
    param([string]$Path)
    return (($Path -replace '\\', '/') -replace '^/+', '')
}

function ConvertTo-RelativePath {
    param([string]$Root, [string]$Path)
    $relative = [System.IO.Path]::GetRelativePath($Root, $Path)
    return Normalize-RelativePath $relative
}

function Test-ExcludedPath {
    param([string]$RelativePath)

    $relative = Normalize-RelativePath $RelativePath
    if ([string]::IsNullOrWhiteSpace($relative)) { return $true }

    $parts = $relative -split '/'
    foreach ($part in $parts) {
        if ($part -like "gsd-*") { return $true }
        if ($part -in @(".git", "node_modules", "logs", "get-shit-done", "__pycache__", "captures", ".venv", "venv", "dist", "build")) { return $true }
    }

    $name = $parts[$parts.Length - 1]
    if ($name -eq "gsd-file-manifest.json") { return $true }
    if ($name -like ".lock-*") { return $true }
    if ($name -like "*.pyc") { return $true }
    if ($name -match '\.bak\.') { return $true }

    return $false
}

function Test-SecretSensitivePath {
    param([string]$RelativePath)

    $relative = Normalize-RelativePath $RelativePath
    return ($relative -match '(^|/)(opencode\.jsonc?|settings\.json)$' -or
        $relative -match '^(mcp-servers|hooks|plugin|plugins|tool|tools)/')
}

function Get-SyncFiles {
    param([string]$Root)

    $rootPath = (Resolve-Path -LiteralPath $Root).Path
    $files = New-Object System.Collections.Generic.List[string]

    foreach ($prefix in $SyncPrefixes) {
        $path = Join-Path $rootPath $prefix
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $relative = Normalize-RelativePath $prefix
            if (-not (Test-ExcludedPath $relative)) { $files.Add($relative) }
            continue
        }

        if (Test-Path -LiteralPath $path -PathType Container) {
            Get-ChildItem -LiteralPath $path -Recurse -File -Force | ForEach-Object {
                $relative = ConvertTo-RelativePath $rootPath $_.FullName
                if (-not (Test-ExcludedPath $relative)) { $files.Add($relative) }
            }
        }
    }

    return ($files.ToArray() | Sort-Object -Unique)
}

function Get-FileHashValue {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Get-ComparisonItems {
    $localFiles = @(Get-SyncFiles $EffectiveLocalRoot)
    $repoFiles = @(Get-SyncFiles $RepoRuntimeRoot)
    $allFiles = @($localFiles + $repoFiles | Sort-Object -Unique)
    $items = New-Object System.Collections.Generic.List[object]

    foreach ($relative in $allFiles) {
        $platformRelative = $relative -replace '/', [System.IO.Path]::DirectorySeparatorChar
        $localPath = Join-Path $EffectiveLocalRoot $platformRelative
        $repoPath = Join-Path $RepoRuntimeRoot $platformRelative
        $hasLocal = Test-Path -LiteralPath $localPath -PathType Leaf
        $hasRepo = Test-Path -LiteralPath $repoPath -PathType Leaf
        $status = "unknown"
        $localHash = if ($hasLocal) { Get-FileHashValue $localPath } else { $null }
        $repoHash = if ($hasRepo) { Get-FileHashValue $repoPath } else { $null }

        if ($hasLocal -and $hasRepo) {
            if ($localHash -eq $repoHash) { $status = "same" } else { $status = "content-diff" }
        }
        elseif ($hasLocal) { $status = "only-in-local" }
        elseif ($hasRepo) { $status = "only-in-repo" }

        if ($status -ne "same") {
            $items.Add([pscustomobject]@{
                status = $status
                path = $relative
                secretSensitive = Test-SecretSensitivePath $relative
                repoPath = if ($hasRepo) { $repoPath } else { $null }
                localPath = if ($hasLocal) { $localPath } else { $null }
                repoSha256 = $repoHash
                localSha256 = $localHash
            })
        }
    }

    return $items.ToArray()
}

function Write-PrepareHuman {
    param([object[]]$Items, [string[]]$Status)

    Write-Host "OpenCode sync prepare"
    Write-Host "Repository root: $EffectiveRepoRoot"
    Write-Host "Repository runtime root: $RepoRuntimeRoot"
    Write-Host "Local runtime root: $EffectiveLocalRoot"
    Write-Host ""
    Write-Host "Git status before merge:"
    if ($Status.Count -eq 0) { Write-Host "  clean" } else { $Status | ForEach-Object { Write-Host "  $_" } }
    Write-Host ""
    Write-Host "Candidate differences: $($Items.Count)"

    foreach ($item in $Items) {
        $marker = if ($item.secretSensitive) { " secret-sensitive" } else { "" }
        Write-Host "  [$($item.status)]$marker $($item.path)"
        if ($item.status -eq "content-diff") {
            Write-Host "    diff: git diff --no-index -- `"$($item.repoPath)`" `"$($item.localPath)`""
        }
        elseif ($item.status -eq "only-in-local") {
            Write-Host "    local: $($item.localPath)"
        }
        elseif ($item.status -eq "only-in-repo") {
            Write-Host "    repo: $($item.repoPath)"
        }
    }
}

function Invoke-Prepare {
    if (-not (Test-Path -LiteralPath (Join-Path $EffectiveRepoRoot ".git") -PathType Container)) {
        throw "Repository root is not a Git repository: $EffectiveRepoRoot"
    }

    [void](Invoke-Git @("-C", $EffectiveRepoRoot, "fetch", "--all", "--prune"))
    [void](Invoke-Git @("-C", $EffectiveRepoRoot, "pull", "--ff-only"))

    $status = @(Get-GitStatus)
    $items = @(Get-ComparisonItems)

    if ($Json) {
        [pscustomobject]@{
            repoRoot = $EffectiveRepoRoot
            repoRuntimeRoot = $RepoRuntimeRoot
            localRoot = $EffectiveLocalRoot
            gitStatus = $status
            differences = $items
        } | ConvertTo-Json -Depth 6
        return
    }

    Write-PrepareHuman $items $status
}

function Test-PlaceholderValue {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) { return $true }
    $trimmed = $Value.Trim().Trim('"').Trim("'")
    if ([string]::IsNullOrWhiteSpace($trimmed)) { return $true }
    if ($trimmed -match '^(null|true|false)$') { return $true }
    if ($trimmed -match '^<[^>]+>$') { return $true }
    if ($trimmed -match '^\$\{[^}]+\}$') { return $true }
    if ($trimmed -match '^\$env:') { return $true }
    if ($trimmed -match '^(REDACTED|PLACEHOLDER|CHANGE_ME|TODO|EXAMPLE|YOUR_|your-|xxx|\*\*\*)') { return $true }
    return $false
}

function Find-SecretFindings {
    $hardPatterns = @(
        @{ name = "private-key"; pattern = '-----BEGIN [A-Z ]*PRIVATE KEY-----' },
        @{ name = "github-token"; pattern = '(?i)\b(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9_]{20,}\b' },
        @{ name = "github-pat"; pattern = '(?i)\bgithub_pat_[A-Za-z0-9_]{20,}\b' },
        @{ name = "openai-style-key"; pattern = '(?i)\bsk-[A-Za-z0-9]{20,}\b' },
        @{ name = "aws-access-key"; pattern = '\bAKIA[0-9A-Z]{16}\b' },
        @{ name = "slack-token"; pattern = '(?i)\bxox[baprs]-[A-Za-z0-9-]{10,}\b' },
        @{ name = "connection-string-secret"; pattern = '(?i)(AccountKey|SharedAccessKey|Password|Pwd)\s*=\s*[^;\s]{8,}' }
    )

    $keyValuePattern = '^\s*["'']?(api[_-]?key|token|secret|password|passwd|pwd|client[_-]?secret|connection[_-]?string|access[_-]?key|refresh[_-]?token)["'']?\s*[:=]\s*["'']?([^"'',;#}\s]+)'
    $findings = New-Object System.Collections.Generic.List[object]

    foreach ($relative in (Get-SyncFiles $RepoRuntimeRoot)) {
        $platformRelative = $relative -replace '/', [System.IO.Path]::DirectorySeparatorChar
        $path = Join-Path $RepoRuntimeRoot $platformRelative
        $lineNumber = 0

        try {
            foreach ($line in (Get-Content -LiteralPath $path -Encoding UTF8)) {
                $lineNumber++

                foreach ($pattern in $hardPatterns) {
                    if ($line -match $pattern.pattern) {
                        $findings.Add([pscustomobject]@{
                            path = $relative
                            line = $lineNumber
                            type = $pattern.name
                        })
                    }
                }

                $match = [regex]::Match($line, $keyValuePattern)
                if ($match.Success) {
                    $value = $match.Groups[2].Value
                    if (-not (Test-PlaceholderValue $value)) {
                        $findings.Add([pscustomobject]@{
                            path = $relative
                            line = $lineNumber
                            type = "secret-like-assignment"
                        })
                    }
                }
            }
        }
        catch {
            Write-Warning "Skipping unreadable file during secret scan: $relative"
        }
    }

    return $findings.ToArray()
}

function Invoke-Scan {
    $findings = @(Find-SecretFindings)

    if ($Json) {
        [pscustomobject]@{
            repoRuntimeRoot = $RepoRuntimeRoot
            findingCount = $findings.Count
            findings = $findings
        } | ConvertTo-Json -Depth 5
    }
    elseif ($findings.Count -eq 0) {
        Write-Host "Secret scan passed for repository runtime files."
    }
    else {
        Write-Host "Potential secret exposure blocked. Values are intentionally not printed."
        foreach ($finding in $findings) {
            Write-Host "  $($finding.path):$($finding.line) [$($finding.type)]"
        }
    }

    if ($findings.Count -gt 0) { exit 2 }
}

function Invoke-CommitPush {
    Invoke-Scan

    Write-Host "Staging repository runtime changes under opencode/."
    [void](Invoke-Git @("-C", $EffectiveRepoRoot, "add", "--", "opencode"))

    [void](Invoke-Git @("-C", $EffectiveRepoRoot, "diff", "--cached", "--quiet", "--", "opencode") -AllowNonZero)
    $diffExit = $LASTEXITCODE
    if ($diffExit -eq 0) {
        Write-Host "No staged repository runtime changes to commit."
        return
    }
    if ($diffExit -ne 1) {
        throw "git diff --cached failed with exit code $diffExit"
    }

    [void](Invoke-Git @("-C", $EffectiveRepoRoot, "commit", "-m", $EffectiveCommitMessage))

    if ($EffectiveNoPush) {
        Write-Host "Push skipped because no-push was requested."
        return
    }

    [void](Invoke-Git @("-C", $EffectiveRepoRoot, "push"))
}

switch ($Mode) {
    "Prepare" { Invoke-Prepare }
    "Scan" { Invoke-Scan }
    "CommitPush" { Invoke-CommitPush }
}
