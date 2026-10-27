# V Plus LTS Rendering Documentation

Portable reference for users and agents without prior chat context. Reviewed 2026-10-27 against
**V+ LTS 1.7.6**, GUID `xukmi.Shaders.VanillaPlus`, the local **KKS** manifest. This folder documents
shader rendering; it is not a RenderDoc GPU-capture archive. A separate setup skill is included.

## Read First

Starting with a new machine or an unconnected toolchain? Follow [Environment setup](EnvironmentSetup.md)
and its portable [entry skill](skills/kk-scene-pipeline-setup/SKILL.md) before material authoring.
The skill covers Blender MCP, the matching Unity template/bridge, StudioMCP and a saved-scene round trip.

1. [Shared rendering knowledge](SharedRendering.md): concepts and input/scene verification.
2. [Pipeline](Pipeline.md): family includes, Passes, lighting and compatibility limits.
3. [Material contracts](MaterialContracts.md): alpha, masks, normal maps, MatCap and exceptions.
4. [Shader catalog](ShaderCatalog.json): exact registrations, source/carrier paths, categories,
   literal Pass names, UsePass references and source fingerprints.

This LTS tree preserves legacy xukmi behavior. It is not the modern TomX or TomBSDF project. Existing
MainOpaqueBlend and experimental overlays remain here; standalone `tom/*X*` and `xukmi/TomBSDF*`
materials require the independent packages. Do not reintroduce cross-project include dependencies.

## Select A Family

| Need | Entry/family |
| --- | --- |
| General opaque / optional clipping | MainOpaquePlus |
| Conventional soft transparency | MainAlphaPlus |
| Game item or Studio-specific artistic lighting | MainItemPlus / MainItemStudioPlus and their Alpha variants |
| Hair, front-hair eye interaction | HairPlus / HairFrontPlus; Reflect/Tess variants have separate paths |
| Eye-area stencil surfaces | EyePlus / EyeWPlus; AlphaPlus variants add independent cutoffs |
| Game body/face and overlays | SkinPlus; SkinAlphaPlus variants enable main-texture alpha |
| Independent local see-through mask with a sealed back shell | SkinMaskedAlphaTwoPass |
| Legacy toon/PBR layered experiment | MainOpaqueBlend, not modern BSDF |
| Height-driven normal/geometry and coverage | MainHeightAlpha / MainHeightAlphaDisplace |
| Specialized depth or overlay experiments | Read the exact catalog/source entry before using |

All exact names and the current registration count come from the catalog. Bundle:
`chara/xukmi/shaders/vanillaplus.unity3d`. The hidden LegacyForwardAdd shader supplies referenced
Passes; it is not an extra user-facing surface registration.

## First Agent Prompt

```text
Read Documents/RenderDocs/README.md, Pipeline.md and MaterialContracts.md, then inspect the exact
shader source, its fragment includes, manifest and tooltip. Identify family macros and separate
Forward/Reflect/ShadowCaster/depth behavior. Do not assume all Plus shaders share alpha, ShadowColor,
MatCap or texture-channel semantics. Preserve saved controls and independent game-managed masks.
State source facts separately from runtime evidence; do not change Unity assets or build/deploy/push
without the current task's authority.
```

## Maintain And Check

PowerShell 7, from the package root:

```powershell
./Documents/RenderDocs/Audit-RenderDocs.ps1
# After reviewing changed inputs and updating the documents:
./Documents/RenderDocs/Audit-RenderDocs.ps1 -RefreshCatalog -ReviewDate YYYY-MM-DD
```

The default audit is read-only and does not invoke Unity. UsePass names are literal references,
not a flattened Pass execution model. Current source/catalog alignment is not game acceptance,
complete compiled-bytecode coverage or proof that an older installed bundle was replaced.
This documentation task does not synchronize the KK sibling; preserve each edition's game tag
and verify the actual Unity version before any separately requested port.
