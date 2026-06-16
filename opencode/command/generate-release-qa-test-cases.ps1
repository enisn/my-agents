param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Trim-OuterQuotes {
    param([string]$Value)

    if ($null -eq $Value) {
        return $Value
    }

    $trimmed = $Value.Trim()
    if ($trimmed.Length -ge 2) {
        $first = $trimmed.Substring(0, 1)
        $last = $trimmed.Substring($trimmed.Length - 1, 1)
        if (($first -eq '"' -and $last -eq '"') -or ($first -eq "'" -and $last -eq "'")) {
            return $trimmed.Substring(1, $trimmed.Length - 2)
        }
    }

    return $trimmed
}

function Split-RawArguments {
    param([string]$Raw)

    if ([string]::IsNullOrWhiteSpace($Raw)) {
        return @()
    }

    $matches = [regex]::Matches($Raw, '"[^"]*"|''[^'']*''|\S+')
    $tokens = New-Object System.Collections.Generic.List[string]
    foreach ($match in $matches) {
        $tokens.Add((Trim-OuterQuotes $match.Value)) | Out-Null
    }

    return $tokens.ToArray()
}

function Set-NormalizedValue {
    param(
        [hashtable]$Target,
        [string]$Key,
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Key)) {
        return
    }

    $normalizedKey = $Key.Trim().ToLowerInvariant().Replace('-', '_')
    $Target[$normalizedKey] = (Trim-OuterQuotes $Value)
}

function Parse-ArgumentMap {
    param([string[]]$Tokens)

    $map = @{}

    for ($index = 0; $index -lt $Tokens.Length; $index++) {
        $token = $Tokens[$index]
        if ([string]::IsNullOrWhiteSpace($token)) {
            continue
        }

        if ($token -match '^(?<key>[^:=]+)=(?<value>.+)$') {
            Set-NormalizedValue -Target $map -Key $Matches['key'] -Value $Matches['value']
            continue
        }

        if ($token -match '^(?<key>[^:=]+):(?<value>.*)$') {
            $value = $Matches['value']
            if ([string]::IsNullOrWhiteSpace($value)) {
                if ($index + 1 -ge $Tokens.Length) {
                    throw "Missing value for '$token'."
                }

                $index++
                $value = $Tokens[$index]
            }

            Set-NormalizedValue -Target $map -Key $Matches['key'] -Value $value
            continue
        }

        throw "Unsupported argument format '$token'. Use key=value, key: value, or JSON."
    }

    return $map
}

function Get-RequiredValue {
    param(
        [hashtable]$Map,
        [string]$Key
    )

    $normalizedKey = $Key.Trim().ToLowerInvariant().Replace('-', '_')
    if (-not $Map.ContainsKey($normalizedKey) -or [string]::IsNullOrWhiteSpace([string]$Map[$normalizedKey])) {
        throw "Missing required argument '$Key'."
    }

    return [string]$Map[$normalizedKey]
}

function Get-OptionalValue {
    param(
        [hashtable]$Map,
        [string]$Key,
        [string]$Default = ''
    )

    $normalizedKey = $Key.Trim().ToLowerInvariant().Replace('-', '_')
    if (-not $Map.ContainsKey($normalizedKey)) {
        return $Default
    }

    $value = [string]$Map[$normalizedKey]
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $Default
    }

    return $value
}

function Get-MajorMinorVersionParts {
    param([string]$VersionText)

    if ([string]::IsNullOrWhiteSpace($VersionText)) {
        throw 'Version text cannot be empty.'
    }

    $parts = $VersionText.Split('.')
    if ($parts.Length -lt 2) {
        throw "Version '$VersionText' must contain major and minor parts."
    }

    $major = 0
    $minor = 0
    if (-not [int]::TryParse($parts[0], [ref]$major)) {
        throw "Version '$VersionText' has an invalid major part."
    }

    if (-not [int]::TryParse($parts[1], [ref]$minor)) {
        throw "Version '$VersionText' has an invalid minor part."
    }

    return [pscustomobject]@{
        Major = $major
        Minor = $minor
    }
}

function Get-DerivedLeptonVersion {
    param([string]$FrameworkVersion)

    $parts = Get-MajorMinorVersionParts -VersionText $FrameworkVersion
    $derivedMajor = $parts.Major - 5
    if ($derivedMajor -lt 0) {
        throw "Cannot derive Lepton version from framework version '$FrameworkVersion'."
    }

    return "$derivedMajor.$($parts.Minor)"
}

$rawInput = ($CliArgs -join ' ').Trim()
$argumentMap = $null

if ($rawInput.StartsWith('{') -and $rawInput.EndsWith('}')) {
    $jsonObject = $rawInput | ConvertFrom-Json
    $argumentMap = @{}
    foreach ($property in $jsonObject.PSObject.Properties) {
        Set-NormalizedValue -Target $argumentMap -Key $property.Name -Value ([string]$property.Value)
    }
}
else {
    $argumentMap = Parse-ArgumentMap -Tokens (Split-RawArguments -Raw $rawInput)
}

$frameworkFrom = Get-RequiredValue -Map $argumentMap -Key 'framework_from'
$frameworkTo = Get-RequiredValue -Map $argumentMap -Key 'framework_to'
$leptonFrom = Get-OptionalValue -Map $argumentMap -Key 'lepton_from'
$leptonTo = Get-OptionalValue -Map $argumentMap -Key 'lepton_to'
$assignee = Get-OptionalValue -Map $argumentMap -Key 'assignee' -Default 'gizemmutukurt'

if ([string]::IsNullOrWhiteSpace($leptonFrom)) {
    $leptonFrom = Get-DerivedLeptonVersion -FrameworkVersion $frameworkFrom
}

if ([string]::IsNullOrWhiteSpace($leptonTo)) {
    $leptonTo = Get-DerivedLeptonVersion -FrameworkVersion $frameworkTo
}

$tempRoot = [System.IO.Path]::GetTempPath()

$contexts = @(
    [pscustomobject]@{
        key = 'abp'
        displayName = 'ABP'
        repoPath = 'C:\P\abp'
        repoFullName = 'abpframework/abp'
        fromVersion = $frameworkFrom
        toVersion = $frameworkTo
        fromBranch = "rel-$frameworkFrom"
        toBranch = "rel-$frameworkTo"
        markdownPath = "C:\P\abp\rel-$frameworkFrom-to-rel-$frameworkTo-changelog-and-testing-scenarios.md"
        collectorOutputPath = (Join-Path $tempRoot "opencode-release-qa-abp-$frameworkFrom-to-$frameworkTo.json")
    }
    [pscustomobject]@{
        key = 'volo'
        displayName = 'VOLO'
        repoPath = 'C:\P\volo'
        repoFullName = 'volosoft/volo'
        fromVersion = $frameworkFrom
        toVersion = $frameworkTo
        fromBranch = "rel-$frameworkFrom"
        toBranch = "rel-$frameworkTo"
        markdownPath = "C:\P\volo\rel-$frameworkFrom-to-rel-$frameworkTo-changelog-and-testing-scenarios.md"
        collectorOutputPath = (Join-Path $tempRoot "opencode-release-qa-volo-$frameworkFrom-to-$frameworkTo.json")
    }
    [pscustomobject]@{
        key = 'lepton'
        displayName = 'Lepton'
        repoPath = 'C:\P\lepton'
        repoFullName = 'volosoft/lepton'
        fromVersion = $leptonFrom
        toVersion = $leptonTo
        fromBranch = "rel-$leptonFrom"
        toBranch = "rel-$leptonTo"
        markdownPath = "C:\P\lepton\rel-$leptonFrom-to-rel-$leptonTo-changelog-and-testing-scenarios.md"
        collectorOutputPath = (Join-Path $tempRoot "opencode-release-qa-lepton-$leptonFrom-to-$leptonTo.json")
    }
)

$result = [pscustomobject]@{
    frameworkFrom = $frameworkFrom
    frameworkTo = $frameworkTo
    leptonFrom = $leptonFrom
    leptonTo = $leptonTo
    assignee = $assignee
    issueRepoPath = 'C:\P\vs-internal'
    issueRepoFullName = 'volosoft/vs-internal'
    contexts = $contexts
}

$result | ConvertTo-Json -Depth 8
