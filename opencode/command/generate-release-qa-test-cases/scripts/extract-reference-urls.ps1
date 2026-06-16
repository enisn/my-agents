[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DocumentPath,

    [string]$RepoFullName = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $DocumentPath -PathType Leaf)) {
    throw "Document path does not exist: $DocumentPath"
}

$content = Get-Content -LiteralPath $DocumentPath -Raw -Encoding UTF8
$repoPattern = if ([string]::IsNullOrWhiteSpace($RepoFullName)) { '[^/\s]+/[^/\s]+' } else { [regex]::Escape($RepoFullName) }

$prUrls = @(
    [regex]::Matches($content, "https://github\.com/$repoPattern/pull/\d+")
    | ForEach-Object { $_.Value }
    | Sort-Object -Unique
)

$commitUrls = @(
    [regex]::Matches($content, "https://github\.com/$repoPattern/commit/[0-9a-fA-F]+")
    | ForEach-Object { $_.Value }
    | Sort-Object -Unique
)

$allUrls = @($prUrls + $commitUrls | Sort-Object -Unique)

[pscustomobject]@{
    documentPath = $DocumentPath
    repoFullName = $RepoFullName
    prUrls = $prUrls
    commitUrls = $commitUrls
    allUrls = $allUrls
} | ConvertTo-Json -Depth 6
