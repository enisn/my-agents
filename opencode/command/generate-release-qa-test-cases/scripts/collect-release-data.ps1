[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RepoPath,

    [Parameter(Mandatory = $true)]
    [string]$RepoFullName,

    [Parameter(Mandatory = $true)]
    [string]$FromBranch,

    [Parameter(Mandatory = $true)]
    [string]$ToBranch,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptRoot 'shared.ps1')

function Invoke-CommandCapture {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        [string]$FailureMessage
    )

    $output = & $ScriptBlock 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        $text = ($output | Out-String).Trim()
        throw "$FailureMessage`n$text"
    }

    return @($output)
}

if (-not (Test-Path -LiteralPath $RepoPath -PathType Container)) {
    throw "Repository path does not exist: $RepoPath"
}

Set-Location $RepoPath

[void](Invoke-CommandCapture -ScriptBlock { git ls-remote --heads origin $FromBranch } -FailureMessage "Source branch '$FromBranch' was not found on origin.")
[void](Invoke-CommandCapture -ScriptBlock { git ls-remote --heads origin $ToBranch } -FailureMessage "Target branch '$ToBranch' was not found on origin.")
[void](Invoke-CommandCapture -ScriptBlock { git fetch origin $FromBranch $ToBranch --no-tags } -FailureMessage 'Failed to fetch release branches.')

$range = "origin/$FromBranch..origin/$ToBranch"
$mergeLines = @(Invoke-CommandCapture -ScriptBlock { git log $range --first-parent --merges --pretty=format:'%H%x09%s' } -FailureMessage 'Failed to read merge history for the branch range.')

$mergeRecords = New-Object System.Collections.Generic.List[object]
foreach ($line in $mergeLines) {
    if ([string]::IsNullOrWhiteSpace($line)) {
        continue
    }

    $parts = $line -split "`t", 2
    $sha = $parts[0]
    $subject = if ($parts.Length -gt 1) { $parts[1] } else { '' }
    $mergeRecords.Add([pscustomobject]@{
        sha = $sha
        subject = $subject
        prNumber = Get-PrNumberFromMergeSubject -Subject $subject
    }) | Out-Null
}

$prNumbers = @(
    $mergeRecords
    | Where-Object { $null -ne $_.prNumber }
    | Select-Object -ExpandProperty prNumber -Unique
)

$prRecords = New-Object System.Collections.Generic.List[object]
foreach ($prNumber in $prNumbers) {
    $rawPr = Invoke-CommandCapture -ScriptBlock { gh pr view $prNumber --repo $RepoFullName --json number,title,url,author,files,mergedAt,baseRefName,headRefName } -FailureMessage "Failed to load PR #$prNumber from $RepoFullName."
    $pr = (($rawPr | Out-String).Trim()) | ConvertFrom-Json
    $files = @($pr.files | ForEach-Object { $_.path })
    $fileCount = @($files).Count
    $assessment = Get-UiAssessment -Title $pr.title -Files $files
    $authorLogin = if ($null -ne $pr.author) { [string]$pr.author.login } else { '' }

    $prRecords.Add([pscustomobject]@{
        number = $pr.number
        title = $pr.title
        url = $pr.url
        authorLogin = $authorLogin
        mergedAt = $pr.mergedAt
        baseRefName = $pr.baseRefName
        headRefName = $pr.headRefName
        fileCount = $fileCount
        files = $files
        topBuckets = @(Get-TopBuckets -Files $files)
        groupHint = Get-GroupHint -Title $pr.title -Files $files
        classCounts = $assessment.classCounts
        suggestedUiTestable = $assessment.suggestedUiTestable
        assessmentReason = $assessment.assessmentReason
        isBotAuthor = Test-BotAuthorLogin -Login $authorLogin
        isBotAutoSync = ((Test-BotAuthorLogin -Login $authorLogin) -and (Test-BotAutoSyncTitle -Title $pr.title))
    }) | Out-Null
}

$directCommits = New-Object System.Collections.Generic.List[object]
foreach ($merge in ($mergeRecords | Where-Object { $null -eq $_.prNumber })) {
    $files = @(Invoke-CommandCapture -ScriptBlock { git diff-tree --no-commit-id --name-only -r -m $merge.sha } -FailureMessage "Failed to load changed files for commit $($merge.sha).")
    $files = @($files | Sort-Object -Unique)
    $fileCount = @($files).Count
    $assessment = Get-UiAssessment -Title $merge.subject -Files $files
    $authorLine = @(Invoke-CommandCapture -ScriptBlock { git show -s --format='%an|%ae' $merge.sha } -FailureMessage "Failed to read commit metadata for $($merge.sha).") | Select-Object -First 1
    $authorParts = ([string]$authorLine) -split '\|', 2

    $directCommits.Add([pscustomobject]@{
        sha = $merge.sha
        subject = $merge.subject
        url = "https://github.com/$RepoFullName/commit/$($merge.sha)"
        authorName = $authorParts[0]
        authorEmail = if ($authorParts.Length -gt 1) { $authorParts[1] } else { '' }
        fileCount = $fileCount
        files = $files
        topBuckets = @(Get-TopBuckets -Files $files)
        groupHint = Get-GroupHint -Title $merge.subject -Files $files
        classCounts = $assessment.classCounts
        suggestedUiTestable = $assessment.suggestedUiTestable
        assessmentReason = $assessment.assessmentReason
    }) | Out-Null
}

$result = [pscustomobject]@{
    collectedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
    repoPath = $RepoPath
    repoFullName = $RepoFullName
    fromBranch = $FromBranch
    toBranch = $ToBranch
    range = $range
    mergeCommitCount = $mergeRecords.Count
    prCount = $prRecords.Count
    prs = @($prRecords.ToArray())
    directCommits = @($directCommits.ToArray())
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory) -and -not (Test-Path -LiteralPath $outputDirectory)) {
    [void](New-Item -ItemType Directory -Path $outputDirectory -Force)
}

$result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
$result | ConvertTo-Json -Depth 10
