[CmdletBinding()]
param(
    [switch]$RefreshCatalog,
    [string]$ReviewDate = ''
)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$catalogPath = Join-Path $PSScriptRoot 'ShaderCatalog.json'
$excludedSourcePaths = @()
function Relative([string]$path) {
    return [IO.Path]::GetRelativePath($root, $path).Replace('\', '/')
}
function Hash([string]$path) {
    $text = [IO.File]::ReadAllText($path).Replace("`r`n", "`n").Replace("`r", "`n")
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($algorithm.ComputeHash([Text.Encoding]::UTF8.GetBytes($text)))).Replace('-', '').ToLowerInvariant()
    } finally { $algorithm.Dispose() }
}
[xml]$manifest = Get-Content -Raw -LiteralPath (Join-Path $root 'manifest.xml')
$shaderFiles = @(Get-ChildItem -LiteralPath (Join-Path $root 'Shaders') -Recurse -File -Filter '*.shader')
$declarations = @{}
foreach ($file in $shaderFiles) {
    $source = [IO.File]::ReadAllText($file.FullName)
    $match = [regex]::Match($source, '(?m)^\s*Shader\s+"([^"]+)"')
    if (-not $match.Success) { continue }
    $name = $match.Groups[1].Value
    if ($declarations.ContainsKey($name)) { throw "Duplicate declaration: $name" }
    $declarations[$name] = [ordered]@{
        source = Relative $file.FullName
        sourceSha256 = Hash $file.FullName
        declaredPassNames = @([regex]::Matches($source, '(?m)^\s*Name\s+"([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
        usePass = @([regex]::Matches($source, '(?m)^\s*UsePass\s+"([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
    }
}
$prefabs = @(Get-ChildItem -LiteralPath (Join-Path $root 'Prefab') -Recurse -File -Filter '*.prefab')
$entries = @()
$names = @{}
foreach ($shader in $manifest.manifest.MaterialEditor.Shader) {
    $name = $shader.GetAttribute('Name')
    if ($names.ContainsKey($name)) { throw "Duplicate manifest identity: $name" }
    $names[$name] = $true
    if (-not $declarations.ContainsKey($name)) { throw "Missing shader source: $name" }
    $asset = $shader.GetAttribute('Asset')
    $carriers = @($prefabs | Where-Object BaseName -CEQ $asset)
    if ($carriers.Count -ne 1) { throw "Expected one carrier for $name / $asset; found $($carriers.Count)" }
    $properties = @($shader.SelectNodes('Property'))
    $entries += [ordered]@{
        name = $name
        source = $declarations[$name].source
        sourceSha256 = $declarations[$name].sourceSha256
        assetBundle = $shader.GetAttribute('AssetBundle')
        asset = $asset
        carrier = Relative $carriers[0].FullName
        propertyCount = $properties.Count
        hiddenPropertyCount = @($properties | Where-Object { $_.GetAttribute('Hidden') -eq 'true' }).Count
        categories = @($properties | ForEach-Object { $_.GetAttribute('Category') } | Where-Object { $_ } | Select-Object -Unique)
        declaredPassNames = $declarations[$name].declaredPassNames
        usePass = $declarations[$name].usePass
    }
}
$inputs = @((Join-Path $root 'manifest.xml'))
foreach ($folder in @('Shaders','Tooltips','Runtime')) {
    $path = Join-Path $root $folder
    if (Test-Path -LiteralPath $path) {
        $inputs += @(Get-ChildItem -LiteralPath $path -Recurse -File |
            Where-Object Extension -In @('.shader','.cginc','.xml','.cs') |
            ForEach-Object FullName)
    }
}
$fingerprints = @($inputs | Sort-Object -Unique | ForEach-Object {
    [ordered]@{ path = Relative $_; sha256 = Hash $_ }
})
if ($RefreshCatalog) {
    if ($ReviewDate -notmatch '^\d{4}-\d{2}-\d{2}$') {
        throw 'Refresh requires an explicit -ReviewDate YYYY-MM-DD after reviewing the changed inputs.'
    }
} else {
    if (-not (Test-Path -LiteralPath $catalogPath)) { throw 'No catalog. Review inputs before generating one.' }
    $saved = Get-Content -Raw -LiteralPath $catalogPath | ConvertFrom-Json -AsHashtable
    $ReviewDate = $saved.reviewDate
}
$actual = [ordered]@{
    schemaVersion = 2
    hashContract = 'sha256-utf8-lf-no-bom'
    excludedSourcePaths = $excludedSourcePaths
    reviewDate = $ReviewDate
    scope = 'Static source/manifest/carrier inventory; not compilation, runtime acceptance or delivered-bytecode audit.'
    packageGuid = [string]$manifest.manifest.guid
    packageVersion = [string]$manifest.manifest.version
    game = [string]$manifest.manifest.game
    registeredShaderCount = $entries.Count
    registeredPropertyCount = $manifest.SelectNodes('/manifest/MaterialEditor/Shader/Property').Count
    entries = $entries
    inputs = $fingerprints
}
$json = $actual | ConvertTo-Json -Depth 12
if ($RefreshCatalog) {
    [IO.File]::WriteAllText($catalogPath, $json.Replace("`r`n", "`n") + "`n", [Text.UTF8Encoding]::new($false))
} else {
    $expected = Get-Content -Raw -LiteralPath $catalogPath | ConvertFrom-Json -AsHashtable
    if (($expected | ConvertTo-Json -Depth 12 -Compress) -cne ($actual | ConvertTo-Json -Depth 12 -Compress)) {
        throw 'Catalog drift: review source, manifest, carriers and documentation. Do not refresh merely to hide a mismatch.'
    }
}
[pscustomobject]@{
    status = 'passed'
    mode = $(if ($RefreshCatalog) { 'reviewed-catalog-refresh' } else { 'read-only-static-check' })
    project = $root
    registeredShaders = $entries.Count
    registeredProperties = $actual.registeredPropertyCount
    fingerprintedInputs = $fingerprints.Count
    unityInvoked = $false
    sceneModified = $false
} | ConvertTo-Json
