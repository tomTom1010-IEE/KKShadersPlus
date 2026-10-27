# Scene Pipeline Entry Skill

This package includes a portable entry skill for first-time Blender -> Unity -> Studio setup.
It does not require a previous conversation, a private scene, or the central knowledge directory.
The packaged skill is [kk-scene-pipeline-setup](skills/kk-scene-pipeline-setup/SKILL.md).

## Start From Zero

1. Select KKS or KK. For modern TomX/BSDF, use KKS/Unity 2019.4.9f1. The KK lane uses its separate
   modding template, Unity 5.6.2f1, bridge and game DLLs; it is not a modern-shader compatibility promise.
2. Follow the skill's [environment guide](skills/kk-scene-pipeline-setup/references/environment.md):
   official applications, matching template, Editor bridge, game plugin prerequisites and StudioMCP.
3. Follow [connections](skills/kk-scene-pipeline-setup/references/connections.md) for Blender MCP,
   the Editor's JSON queue and the Studio host. These are three different transports.
4. Follow the [round-trip guide](skills/kk-scene-pipeline-setup/references/roundtrip.md) to export a
   metre-scale FBX, create a real Studio prop, build its zipmod, change ME data, reload a native card
   and inspect an actual game render/depth export.
5. Only then use the current shader's Pipeline/MaterialContracts for a larger scene.

The Blender integration named in this guide is the community ahujasid/mcp-for-blender upstream,
not Blender Foundation software. Some author bridge/StudioMCP repositories require recipient
access permission; the source registry records that boundary instead of promising anonymous downloads.
Use a matching source/binary package supplied by the author when available.

## Install The Skill

Copy the complete folder, not just SKILL.md, into one discovery location supported by the user's
agent host. Current Codex documentation describes repository .agents/skills and user ~/.agents/skills.
Hosts configured for CODEX_HOME/skills or ~/.codex/skills should use their configured location.
Do not install duplicate copies with the same skill name in multiple active roots.

Example for a new repository-scoped install, from the shader package root:

~~~powershell
$source = Join-Path (Get-Location) 'Documents/RenderDocs/skills/kk-scene-pipeline-setup'
$parent = Join-Path (Get-Location) '.agents/skills'
$target = Join-Path $parent 'kk-scene-pipeline-setup'
if (Test-Path -LiteralPath $target) { throw 'Review the existing skill instead of overwriting it.' }
New-Item -ItemType Directory -Path $parent -Force | Out-Null
Copy-Item -LiteralPath $source -Destination $target -Recurse
~~~

Reload/restart the host if needed, then invoke $kk-scene-pipeline-setup with the game and project paths.
A different agent can read the portable SKILL.md directly; automatic skill discovery and MCP client
configuration are host-specific. Installing a skill does not itself configure applications/connectors.

## Read-only Inventory

From the package root, PowerShell 7:

~~~powershell
$paths = @{
    Game = 'KKS'
    UnityProject = 'C:/Modding/KKS'
    GameRoot = 'C:/Games/KKS'
    StudioMcpRoot = 'C:/Modding/StudioMCP'
    BlenderExe = 'C:/Program Files/Blender Foundation/Blender/blender.exe'
}
./Documents/RenderDocs/skills/kk-scene-pipeline-setup/scripts/Test-ScenePipeline.ps1 @paths
~~~

Use -UvExecutable for an existing absolute uvx path if the agent host and shell PATH differ.
The helper reads paths only, never opens connection secrets, launches applications, writes Inbox
requests, installs software or modifies the game. inventory-ready is not end-to-end acceptance:
live Blender query, Unity ping, Studio status, item load, scene reload and actual capture remain required.

## Scope Of This Addition

Instructions and helper tests were checked; no fresh-machine application install or new scene
render is claimed. The two bridge sources were separately compared with the maintainer's local
projects and reviewed updates pushed; revisions and caveats are in the packaged sources.json.
Do not assume all maintainer-local BSDF/TomX diagnostic commands exist in the portable bridge.
