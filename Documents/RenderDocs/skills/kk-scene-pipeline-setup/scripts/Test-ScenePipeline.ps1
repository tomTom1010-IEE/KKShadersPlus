[CmdletBinding()]
param(
    [ValidateSet('KKS','KK')][string]$Game = 'KKS',
    [string]$UnityProject = '',
    [string]$GameRoot = '',
    [string]$StudioMcpRoot = '',
    [string]$BlenderExe = '',
    [string]$UvExecutable = '',
    [switch]$FailOnMissing
)
$ErrorActionPreference = 'Stop'
$checks = [System.Collections.Generic.List[object]]::new()
function AddCheck([string]$name, [bool]$passed, [bool]$required, [string]$detail) {
    $checks.Add([ordered]@{name=$name;passed=$passed;required=$required;detail=$detail})
}
function HasFile([string]$root, [string]$relative) {
    return -not [string]::IsNullOrWhiteSpace($root) -and (Test-Path -LiteralPath (Join-Path $root $relative) -PathType Leaf)
}
foreach($name in @('git','dotnet')) {
    $found = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    AddCheck $name ($null -ne $found) $true $(if($found){$found.Source}else{'Not found in this shell PATH; another host may have a different PATH.'})
}
if(-not $UvExecutable) {
    $command = Get-Command uvx -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if($command){$UvExecutable=$command.Source}
}
AddCheck 'uvx' ([bool]($UvExecutable -and (Test-Path -LiteralPath $UvExecutable -PathType Leaf))) $true $(if($UvExecutable){$UvExecutable}else{'Not found in this shell PATH; pass -UvExecutable for the agent host configured absolute path.'})
if(-not $BlenderExe) {
    $command = Get-Command blender -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if($command){$BlenderExe=$command.Source}
}
AddCheck 'Blender executable' ([bool]($BlenderExe -and (Test-Path -LiteralPath $BlenderExe -PathType Leaf))) $true $BlenderExe
$expectedEditor = if($Game -eq 'KKS'){'2019.4.9f1'}else{'5.6.2f1'}
$versionPath = if($UnityProject){Join-Path $UnityProject 'ProjectSettings/ProjectVersion.txt'}else{''}
$editorVersion = ''
if($versionPath -and (Test-Path -LiteralPath $versionPath)) {
    $text = [IO.File]::ReadAllText($versionPath)
    $match = [regex]::Match($text,'(?m)^m_EditorVersion:\s*(\S+)')
    if($match.Success){$editorVersion=$match.Groups[1].Value}
}
AddCheck 'Template Editor version' ($editorVersion -ceq $expectedEditor) $true ('Found '+$editorVersion+'; expected '+$expectedEditor+'. This does not launch the Editor.')
AddCheck 'Editor bridge source' (HasFile $UnityProject 'Assets/Editor/CodexBridge.cs') $true 'Source presence only; no compilation or queue request.'
AddCheck 'Studio executable' (HasFile $GameRoot 'CharaStudio.exe') $true $GameRoot
AddCheck 'BepInEx core' (HasFile $GameRoot 'BepInEx/core/BepInEx.dll') $true 'Verify compatible game/runtime build separately.'
AddCheck 'Game Managed assemblies' (HasFile $GameRoot 'CharaStudio_Data/Managed/Assembly-CSharp.dll') $true 'Never publish or copy these blindly into a Unity project.'
$pluginRoot = if($GameRoot){Join-Path $GameRoot 'BepInEx/plugins'}else{''}
$dlls = @()
if($pluginRoot -and (Test-Path -LiteralPath $pluginRoot)) {
    $dlls = @(Get-ChildItem -LiteralPath $pluginRoot -Recurse -File -Filter '*.dll')
}
$apiName = if($Game -eq 'KKS'){'KKSAPI.dll'}else{'KKAPI.dll'}
$expected = [ordered]@{
    'Game API' = ('^'+[regex]::Escape($apiName)+'$')
    'Sideloader' = 'Sideloader\.dll$'
    'ExtendedSave' = 'ExtensibleSaveFormat\.dll$'
    'MaterialEditor' = ('^'+$Game+'_MaterialEditor\.dll$')
    'Color capture' = '(Screencap|ScreenshotManager).*\.dll$'
    'Studio bridge' = ('^'+$Game+'_StudioMCP\.dll$')
}
foreach($entry in $expected.GetEnumerator()) {
    $hits = @($dlls | Where-Object Name -Match $entry.Value)
    AddCheck $entry.Key ($hits.Count -ge 1) $true ('File matches: '+$hits.Count+'. Presence is not version/load/identity validation.')
}
foreach($name in @('Newtonsoft.Json.dll','websocket-sharp.dll')) {
    AddCheck ('Studio dependency '+$name) (HasFile $GameRoot ('BepInEx/plugins/StudioMCP/'+$name)) $true 'Expected side-by-side with the matching StudioMCP bridge.'
}
AddCheck 'MCP host build' (HasFile $StudioMcpRoot 'src/StudioMcp.Host/bin/Release/net8.0/StudioMcp.Host.dll') $true 'Checks the reviewed source-build layout; inspect a custom binary distribution separately.'
AddCheck 'Studio connection descriptor' (HasFile $GameRoot 'UserData/StudioMCP/connection.json') $false 'Presence only. Contents/tokens are deliberately not read; descriptor may be stale.'
$missing = @($checks | Where-Object { $_.required -and -not $_.passed })
$report = [ordered]@{
    schemaVersion=1
    profile='Reviewed Windows source-build layout'
    game=$Game
    expectedEditor=$expectedEditor
    status=$(if($missing.Count){'needs-setup'}else{'inventory-ready'})
    checks=$checks.ToArray()
    missingRequired=$missing.Count
    endToEndValidated=$false
    liveGates=[ordered]@{blenderQuery='not-run';unityPing='not-run';studioStatus='not-run';assetRoundTrip='not-run';sceneReload='not-run';render='not-run';depth='not-run'}
    mutationsPerformed=$false
    credentialsRead=$false
    note='Read-only file/PATH inventory, not installation, compatibility, process reachability, rendering or a universal prebuilt-package audit.'
}
$report | ConvertTo-Json -Depth 7
if($FailOnMissing -and $missing.Count){exit 2}
