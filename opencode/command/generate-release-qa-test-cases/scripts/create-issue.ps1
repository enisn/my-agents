[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$IssueRepoPath,

    [Parameter(Mandatory = $true)]
    [string]$Title,

    [Parameter(Mandatory = $true)]
    [string]$BodyFile,

    [string]$Assignee = '',

    [int]$IssueNumber = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $IssueRepoPath -PathType Container)) {
    throw "Issue repository path does not exist: $IssueRepoPath"
}

if (-not (Test-Path -LiteralPath $BodyFile -PathType Leaf)) {
    throw "Issue body file does not exist: $BodyFile"
}

Set-Location $IssueRepoPath

function Invoke-GhCapture {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [string]$FailureMessage
    )

    $output = & gh @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        $text = ($output | Out-String).Trim()
        throw "$FailureMessage`n$text"
    }

    return @($output)
}

if ($IssueNumber -gt 0) {
    $arguments = @('issue', 'edit', $IssueNumber.ToString(), '--title', $Title, '--body-file', $BodyFile)
    if (-not [string]::IsNullOrWhiteSpace($Assignee)) {
        $arguments += @('--assignee', $Assignee)
    }

    [void](Invoke-GhCapture -Arguments $arguments -FailureMessage "Failed to update issue #$IssueNumber.")
}
else {
    $arguments = @('issue', 'create', '--title', $Title, '--body-file', $BodyFile)
    if (-not [string]::IsNullOrWhiteSpace($Assignee)) {
        $arguments += @('--assignee', $Assignee)
    }

    $createOutput = Invoke-GhCapture -Arguments $arguments -FailureMessage 'Failed to create issue.'
    $createdUrl = ($createOutput | Select-Object -Last 1).ToString().Trim()
    if ($createdUrl -match '/issues/(\d+)$') {
        $IssueNumber = [int]$Matches[1]
    }
}

if ($IssueNumber -le 0) {
    throw 'Issue number could not be resolved after create/edit.'
}

$viewOutput = Invoke-GhCapture -Arguments @('issue', 'view', $IssueNumber.ToString(), '--json', 'number,title,url,assignees') -FailureMessage "Failed to verify issue #$IssueNumber."
(($viewOutput | Out-String).Trim())
