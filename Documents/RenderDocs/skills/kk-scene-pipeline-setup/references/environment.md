# Environment From Zero

Windows workflow, reviewed 2026-10-27. Use the links/revisions in sources.json; recheck upstream
requirements when versions change. Example C:/Modding and C:/Games paths are choices, not required
locations or paths that should be created over existing work.

## Choose A Lane

| Component | KKS lane | KK lane |
| --- | --- | --- |
| Game | User-owned Koikatsu Sunshine / CharaStudio.exe | User-owned Koikatsu / CharaStudio.exe |
| Template | IllusionMods/KoikatsuSunshineModdingTools | IllusionMods/KoikatsuModdingTools |
| Established Editor | Unity 2019.4.9f1 | Unity 5.6.2f1 |
| Editor bridge | tomTom1010-IEE/unity2019.4_bridge | tomTom1010-IEE/unity5.6_bridge |
| Studio bridge DLL | KKS_StudioMCP.dll, .NET Framework 4.6 | KK_StudioMCP.dll, .NET Framework 3.5 |
| External MCP host | StudioMcp.Host, .NET 8 target | Same host, separate game connection file |
| Modern TomX/BSDF | Supported KKS scope | Not qualified by this setup |

Keep two projects and two game installs separate. The words main/master are repository branch names,
not engine compatibility. Do not upgrade the original project to a newer Editor to resolve an import
error. The KKS upstream README still describes a WIP/map-oriented template; test the relevant item
workflow rather than treating every example as fully qualified on every release.

## Install Prerequisites

Obtain Blender from blender.org, Unity from its official archive/Hub, Git and a compatible local
agent client. Install uv by a supported Astral method. For source-building StudioMCP, install a
compatible .NET SDK that can build its net8.0 host and the matching .NET Framework targeting packs
for the game DLL; the .NET 8 SDK alone does not provide legacy Framework reference assemblies.
Prebuilt framework-dependent hosts need their matching .NET runtime, while self-contained host
distributions follow their own instructions. Do not disable antivirus to install an unknown archive.

Install/activate the requested Unity Editor through its supported installer flow and include the
required Windows standalone build support. Read ProjectSettings/ProjectVersion.txt before opening
a downloaded template. Keep original game DLLs, proprietary assets and license files private.

For a fresh workspace, clone or download the chosen template, then open the directory containing
Assets, ProjectSettings and (where present) Packages, not Assets/Mods or a nested ZIP wrapper folder.
Wait for its first import. Fix missing SDK/packages or script errors before installing test assets.
Use the template's examples to learn list/component requirements, not as globally unique mod IDs.

## Install The Editor Bridge

1. Obtain the matching author bridge repository. Use sources.json to select the reviewed commit
   or deliberately review a newer one. Recipient access may require the author's permission.
2. Inspect an existing Assets/Editor/CodexBridge.cs before replacing anything. Back up/merge a
   customized dispatcher; do not delete TomX/BSDF-specific routes in an established development project.
3. For a new matching modding project, copy only Assets/Editor/CodexBridge.cs from the bridge repo
   to the same path in the project. Do not copy its examples directly into a live Inbox as a batch.
4. Let the Editor compile. The 2019 core leaves CODEX_BRIDGE_TOM_PROBE and CODEX_BRIDGE_FACE_WEIGHT
   disabled. Their real authoring dependencies must be installed before enabling either symbol.
5. Verify the file-queue ping in connections.md. No material or prefab needs to be created yet.

Both bridge builds reference the modding template's PreviewShaders and SB3UScript build hooks.
skipPostprocess is a runtime build option, not a way to remove compile-time dependencies in an
empty Unity project. The published 2019 core contains local busy guards but not all private project
diagnostics. Different raw file hashes can therefore be intentional; compare feature scope too.

## Prepare The Game

Use matching game variants of BepInEx 5, KKAPI/KKSAPI, Sideloader, ExtendedSave and MaterialEditor.
Obtain them from their maintainers' releases or the user's already working install. Verify there
is only one DLL per plugin identity; do not overwrite an established mod stack with arbitrary copies.
Install Screencap for MCP color capture. Paired raw depth additionally needs a fork exposing the
OfflineReShade export API; it is not supplied by every ordinary Screencap build.

Install the selected prebuilt TomX or TomBSDF release and matching companions if needed. Ordinary
shading, Probe tools, rectangle service, refractive buffers and bounds providers have different
dependencies. Keep the package's RenderDocs/Installation guide authoritative. A scene card embeds
ME maps/values but does not embed every mesh zipmod or replace required runtime DLLs.

## Install StudioMCP

Prefer the matching reviewed binary distribution if supplied with the scene asset. A Rainline-style
delivery has Install/BepInEx/plugins/StudioMCP plus StudioMCP-Source.zip. Extract the source outside
the game and Unity Assets folders. Otherwise obtain KK_StudioMCP from the author repository with
access permission. Do not redirect to a similarly named unverified MCP implementation.

For a source build, in the StudioMCP repository, after setting actual paths:

```powershell
$GameRoot = 'C:/Games/KKS'
dotnet build ./src/StudioMcp.Host/StudioMcp.Host.csproj -c Release
# Close/save the matching Studio before replacing its plugin DLLs.
./tools/deploy.ps1 -GameRoot $GameRoot -Game KKS
```

Use -Game KK only with the KK root. The deploy helper builds/copies the bridge plus Newtonsoft.Json
and websocket-sharp into BepInEx/plugins/StudioMCP; it does not install the entire game mod stack.
Never install StudioMcp.Host.dll there: it is a separate process. Shared bin/Release output can be
replaced by a build for the other game, so verify DLL filename and hash, not just folder existence.

Launch the saved game normally after deployment. With the bridge enabled, it writes
UserData/StudioMCP/connection.json. The host consumes that file; it is not a public config template.
Keep writes off for the first status query. When scene authoring is requested, explicitly enable
Server.AllowWrites in BepInEx/config/com.tomtom.studiomcp.cfg, or use the documented process-scoped
STUDIOMCP_ALLOW_WRITES mechanism. Do not print or share the token, and do not open a public port.

## Install This Entry Skill

Copy the complete kk-scene-pipeline-setup folder, including references/scripts/assets, into one
active skill directory. Current Codex documentation describes repository .agents/skills or user
~/.agents/skills; some hosts, including the maintained local setup, expose CODEX_HOME/skills or
~/.codex/skills. Use the target host's configured discovery path, not both copies with the same name.
Restart/reload that host if discovery does not refresh. A folder stored under RenderDocs is a
portable distribution, not automatically an installed MCP connector.

Invoke $kk-scene-pipeline-setup and provide the game/project paths. Other agents can read SKILL.md
directly, but MCP configuration/discovery remains client-specific. Installing this skill alone
does not install Blender, Unity, StudioMCP or grant tool access.
