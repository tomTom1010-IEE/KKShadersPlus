param([Parameter(Mandatory=$true)][string]$UnityProject)
$ErrorActionPreference = 'Stop'
$path = Join-Path $UnityProject 'Assets/Editor/CodexBridge.cs'
$source = [IO.File]::ReadAllText($path)
$commands = [ordered]@{
    validatexstage2 = 'TomXStageTwoValidation.Validate()'
    preparexstage2 = 'TomXStageTwoReferences.Create()'
    finishxstage2references = 'TomXStageTwoReferences.FinishAndInspect()'
    renderxstage2closure = 'TomXStageTwoClosure.Run()'
    archivexstage2references = 'TomXStageTwoClosure.ArchiveReferences()'
}
$anchor = '                case "ping":'
if (-not $source.Contains($anchor)) { throw 'Expected CodexBridge dispatcher not found; do not modify automatically.' }
$added = 0
foreach ($entry in $commands.GetEnumerator()) {
    if ($source.Contains('case "' + $entry.Key + '":')) { continue }
    $block = '                case "' + $entry.Key + '":' + "`r`n" +
        '                    message = ' + $entry.Value + ';' + "`r`n" +
        '                    break;' + "`r`n`r`n"
    $source = $source.Replace($anchor, $block + $anchor)
    $added++
}
if ($added -gt 0) {
    [IO.File]::WriteAllText($path, $source, (New-Object Text.UTF8Encoding($false)))
}
Write-Output "Added $added X regression commands. Refresh Unity to compile before sending commands."
