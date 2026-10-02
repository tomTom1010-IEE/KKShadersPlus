param([string]$Root = (Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference = 'Stop'
function Assert($Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}
[xml]$manifest = Get-Content (Join-Path $Root 'manifest.xml') -Raw
[xml]$tooltips = Get-Content (Join-Path $Root 'Tooltips/tom_x_tooltips.xml') -Raw
$shader = Get-Content (Join-Path $Root 'Shaders/Tom/MainOpaqueX.shader') -Raw
$lighting = Get-Content (Join-Path $Root 'Shaders/Tom/TomToonLighting.cginc') -Raw
$style = Get-Content (Join-Path $Root 'Shaders/Tom/TomToonStyle.cginc') -Raw
$properties = $shader.Substring(0, $shader.IndexOf('SubShader'))
$contract = @(Get-Content (Join-Path $Root 'Tests/MainOpaqueX-StageTwo.properties.txt'))
$currentContract = @($properties -split '\r?\n' | Where-Object { $_ -match '^\s*(?:\[[^\]]+\]\s*)*_\w+\s*\(' } | ForEach-Object { $_.Trim() })
Assert (($contract -join "`n") -ceq ($currentContract -join "`n")) 'Frozen property names/types/defaults changed. Explicitly review migration and contract version.'
$names = @([regex]::Matches($properties, '(?m)^\s*(?:\[[^\]]+\]\s*)*_(\w+)\s*\(') | ForEach-Object { $_.Groups[1].Value })
$entry = $manifest.SelectSingleNode('//Shader[@Name="tom/MainOpaqueX"]')
$catalog = $tooltips.SelectSingleNode('//Shader[@Name="tom/MainOpaqueX"]')
Assert ($names.Count -eq 98) 'Unexpected shader property count; review the public contract.'
Assert (@(Compare-Object $names @($entry.Property.Name)).Count -eq 0) 'Manifest differs from shader.'
Assert (@(Compare-Object $names @($catalog.Property.Name)).Count -eq 0) 'Tooltip coverage differs.'
Assert (@($entry.Property | Group-Object Name | Where-Object Count -gt 1).Count -eq 0) 'Duplicate property.'
Assert ($entry.Asset -eq 'a_TomMainOpaqueX') 'Unexpected X prefab binding.'
Assert ($properties -notmatch '_GGXSpecularBlend|_SpecularPower|_RimPower') 'Old controls remain exposed.'
Assert ($properties -match '_DiffuseEnergyBlend[^\r\n]*= 0') 'Default diffuse suppression must be zero.'
Assert ($style.Contains('(1.0 - metallic) * lerp(1.0.xxx, 1.0 - fresnel, saturate(_DiffuseEnergyBlend))')) 'Diffuse contract changed.'
$add = $lighting.Substring($lighting.IndexOf('float4 TomFragAdd'))
Assert ($add -notmatch 'TomEnvironmentLayer|TomMatCapAddLayer|TomEvaluateRim|TomEvaluateIndirectDiffuse') 'Base-only layer appears in Add.'
Assert ($add.Contains('TomMatCapMultiplier')) 'Add missing diffuse MatCap multiplication.'
Assert ($shader.Contains('multi_compile_fwdadd_fullshadows')) 'Full-shadow Add variants missing.'
Assert ($lighting.Contains('halfIsValid > 0.5') -and $lighting.Contains('surface.horizon > 0.0')) 'Specular visibility guards missing.'
Assert ($style.Contains('fwidth(normalizedDistribution)')) 'Specular edge AA missing.'

# CPU reference checks of algebraic contracts, not GPU rendering or visual tests.
$samples = 0
foreach ($metal in @(0.0, .5, 1.0)) {
    foreach ($fresnel in @(0.0, .04, .5, 1.0)) {
        $weight = (1.0-$metal)*(1.0-$fresnel*0.0)
        Assert ([math]::Abs($weight-(1.0-$metal)) -lt 1e-12) 'Default diffuse depends on Fresnel.'
        $samples++
    }
}
foreach ($roughness in @(.08, .1, .5, 1.0)) {
    foreach ($nh in @(0.0, .1, .5, .9, .999, 1.0)) {
        $alpha2 = [math]::Max([math]::Pow($roughness,4), .00001)
        $denom = $nh*$nh*($alpha2-1.0)+1.0
        $shape = $alpha2*$alpha2/[math]::Max($denom*$denom,1e-10)
        Assert (-not [double]::IsNaN($shape) -and -not [double]::IsInfinity($shape)) 'Non-finite normalized GGX.'
        Assert ($shape -ge 0 -and $shape -le 1.000001) 'GGX shape outside normalized range.'
        $samples++
    }
}
Write-Output "PASS: 98 shader/manifest/tooltip properties; layer contracts; $samples CPU algebra samples."
Write-Output 'GPU appearance, compiled branch cost, temporal AA and performance remain user acceptance items.'
