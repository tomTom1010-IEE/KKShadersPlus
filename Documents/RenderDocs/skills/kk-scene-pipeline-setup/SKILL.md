---
name: kk-scene-pipeline-setup
description: Set up or diagnose a Windows Koikatsu or Koikatsu Sunshine scene-authoring environment from Blender MCP through the matching Unity modding template and Codex Bridge to StudioMCP, then verify a saved Studio scene and render. Use for first-time installation and cross-application connectivity, not ordinary shader parameter tuning.
---

# KK Scene Pipeline Setup

Create a usable local authoring chain, not merely a list of installed tools. Default to KKS for
modern TomX/TomBSDF work; KK is a separate Unity 5.6 lane and does not inherit their KKS qualification.

## Establish The Target

Determine game edition, legal existing game/Studio path, selected Unity project, authoring checkout,
Blender executable and agent host. Preserve an existing working environment. For documentation or
skill creation, write/validate the instructions only; do not install applications or change the game.
For an actual setup request, resolve missing paths before dependent writes and verify each boundary.

Read [environment](references/environment.md) for prerequisites and installation, then
[connections](references/connections.md) for the two MCP transports and the file-based Editor bridge.
Use [round trip](references/roundtrip.md) to prove the complete asset/scene path.
[Sources](references/sources.json) records upstream links, reviewed revisions and access limitations.

## Non-obvious Invariants

- The referenced Blender integration is the community project ahujasid/mcp-for-blender, formerly
  blender-mcp. It explicitly is not Blender Foundation software. If a user means another Blender
  integration, identify that project instead of substituting a similarly named package.
- Blender MCP controls Blender; Codex Bridge runs in Unity Editor; StudioMCP controls the game.
  The Editor bridge is a local file queue, not an MCP network endpoint.
- Match Unity 2019.4.9f1/KKS with unity2019.4_bridge, and Unity 5.6.2f1/KK with unity5.6_bridge.
  Both define CodexBridge and must never coexist in one Editor. The bridge expects modding-template
  build classes; an arbitrary empty Unity project is not equivalent.
- Preserve customized Editor dispatchers. The portable bridge intentionally omits local TomX/BSDF
  diagnostics. Probe/face-weight authoring modules in the 2019 bridge are optional compile defines,
  not prerequisites for the first cube/material smoke test.
- A generic prefab is not a registered Studio item. The template's item components, lists, unique
  mod identity, bundle path and final zipmod all have to agree.
- Author native Unity assets through Editor APIs/Bridge. Never generate serialized materials,
  prefabs, scenes, resources or .meta text by hand. Preserve supplied GUIDs.
- Keep MCP listeners local. StudioMCP connection.json contains a secret; never publish its contents.
  Do not install the .NET 8 host DLL into BepInEx or a game-only DLL into the Editor indiscriminately.

## Readiness Gates

1. Inventory prerequisites with scripts/Test-ScenePipeline.ps1. File presence is not connectivity.
2. Blender: a read-only scene query succeeds against the intended Blender document.
3. Unity: a fresh uniquely named ping returns success and pong from the intended project's Outbox.
4. Studio: studio_status and a scene snapshot succeed against the correct game; writes are explicit.
5. Asset: one asymmetric metre-scale mesh travels through FBX, the Editor, a registered zipmod and
   the actual Studio catalog. Inspect normals, UVs, dimensions and material-name scope.
6. Persistence: change one ME value/map, save a native scene PNG, reload independently, reacquire
   handles and verify the change and required plugin-controlled state.
7. Output: capture a small actual Studio render and inspect it. If depth is requested, require a
   supported depth exporter, inspect metadata and verify ordered finite geometry depth.

Do not mark the whole chain ready until its relevant live gates pass. Report untested/blocked gates
and the smallest missing dependency. Reinspect after timeout; do not replay an uncertain asset
write, bundle build or scene replacement. Large bundle builds, Force Rebuild and 4K captures are
not connection tests. Missing shader/light services are not permission to change pipelines or ZWrite.

## Transition To Real Scene Work

After the smoke loop works, load the chosen shader package's Documents/RenderDocs/README.md and
its exact manifest/tooltip contract. Retain basic native rendering while isolating material inputs.
Use prebuilt matching shader packages when only geometry/ME values change; do not recompile all
TomBSDF programs just to register a new prop. Save dependency versions, source revisions, scope of
verification, final scene/card paths and render/depth results without tokens or unrelated user data.
