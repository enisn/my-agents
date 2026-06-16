[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DocumentPath,

    [string]$RepoFullName = '',

    [string]$ExpectedUrlsCsv = '',

    [string]$ExpectedUrlsPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptRoot 'shared.ps1')

if (-not (Test-Path -LiteralPath $DocumentPath -PathType Leaf)) {
    throw "Document path does not exist: $DocumentPath"
}

$expectedUrls = New-Object System.Collections.Generic.List[string]
foreach ($value in (Split-TokenList -Value $ExpectedUrlsCsv)) {
    $expectedUrls.Add($value) | Out-Null
}

if (-not [string]::IsNullOrWhiteSpace($ExpectedUrlsPath)) {
    if (-not (Test-Path -LiteralPath $ExpectedUrlsPath -PathType Leaf)) {
        throw "Expected URL list path does not exist: $ExpectedUrlsPath"
    }

    foreach ($line in (Get-Content -LiteralPath $ExpectedUrlsPath -Encoding UTF8)) {
        foreach ($value in (Split-TokenList -Value $line)) {
            $expectedUrls.Add($value) | Out-Null
        }
    }
}

$extractScript = Join-Path $scriptRoot 'extract-reference-urls.ps1'
$extractJson = & pwsh -NoProfile -ExecutionPolicy Bypass -File $extractScript -DocumentPath $DocumentPath -RepoFullName $RepoFullName
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to extract reference URLs from the document.'
}

$extractResult = (($extractJson | Out-String).Trim()) | ConvertFrom-Json
$scenarioPrSet = @($extractResult.prUrls | Sort-Object -Unique)
$uiTestableSet = @($expectedUrls.ToArray() | Sort-Object -Unique)

$missing = @($uiTestableSet | Where-Object { $_ -notin $scenarioPrSet })
$extra = @($scenarioPrSet | Where-Object { $_ -notin $uiTestableSet })

[pscustomobject]@{
    documentPath = $DocumentPath
    repoFullName = $RepoFullName
    uiTestableSet = $uiTestableSet
    scenarioPrSet = $scenarioPrSet
    missing = $missing
    extra = $extra
    coverageOk = ($missing.Count -eq 0)
} | ConvertTo-Json -Depth 8
