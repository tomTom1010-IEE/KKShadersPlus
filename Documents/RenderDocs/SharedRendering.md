# Shared Rendering Knowledge

Reviewed: 2026-10-27. This is portable rendering documentation for agents, not a skill and not a
RenderDoc GPU-capture file. Read the current project's README, Pipeline and MaterialContracts
alongside it. A sibling project or this author's conversation history is not required.

## Keep The Families Separate

| Contract | V+ LTS | TomX | Modern TomBSDF |
| --- | --- | --- | --- |
| Intent | Preserve xukmi/game stylization and compatibility | Toon-first rebuilt lighting with optional physical lobes | Physically based hard-surface materials |
| Names | `xukmi/*Plus*`, retained Blend/overlays | `tom/*X*`, including LiquidX and Tess variants | `tom/BSDF*`; separate legacy `xukmi/TomBSDF*` |
| Packed material data | No universal ORM contract across families | MaterialMap RGBA = metallic, roughness, AO, specular mask | ORM RGB = AO, roughness, metallic |
| Main/detail normal decode | Unity packed routines | Unity packed routines | Selectable UnityPacked/RGB/AG |
| Height | Family-specific legacy bump/displacement | Displacement R around explicit midpoint, world-distance strength | Height-v1 white envelope, inward world metres |
| MatCap | Several family-specific paths and separate Reflect passes | Unified appearance layer with continuous Multiply/Add | No modern MatCap or toon-ramp layer |
| Alpha | Family-specific straight blend/cutoff/depth behavior | Coverage; straight/premultiplied choices and distinct ordering entries | Premultiplied coverage; separate finite glass |
| Color | Retained legacy/artistic conversions | Its own Unity-compatible lighting path | Explicit KKS Linear-host adapter |
| Compatibility target | KKS and a separately maintained KK sibling | KKS/Unity 2019 Built-in | KKS/Unity 2019 runtime; current KK development deferred |

The same property label is not a migration guarantee. Do not copy packed maps, scalar ranges,
height signs, normals, ShadowColor alpha, or transparency settings between these columns unchanged.
TomBSDF's legacy xukmi entries do not inherit every modern BSDF feature.

## Texture Transport Before Material Tuning

A texture file's appearance is not its GPU representation. Distinguish source channels, Unity import
settings, ME runtime conversion, GPU sRGB view and the shader's decoder. In the inspected ME build,
NormalMap/NormalMapDetail/BumpMap are registered normal-conversion slots; other property names must
be checked independently. This is version/configuration/route-specific, not a law of all ME builds.

For a suspect normal: checkpoint, import a neutral map through the same route and property, disable
confounding layers, compare strength zero/one under fixed light and camera, then restore all inputs.
An RGB8 neutral 128 is not exactly 0.5. Normalization cannot repair a wrong channel interpretation.
Never choose a decoder solely because the original PNG is blue-purple or red.

Color maps, scalar data, normal maps, RG flow fields and depth maps require different contracts.
Avoid double gamma restoration. Use an explicit grayscale control for uncertain scalar imports.
Use the family's actual neutral assets: white/black/default gray are not universally neutral.

## Scale And Composition

Matched color/normal/roughness/height/AO sets reduce contradictory detail. Record authors, licenses,
source URLs, resolution and hashes. Check tile size against known dimensions:

```text
0..1 UV over L metres: texture scale = L / tile_size_metres
UV already in metres: texture scale = 1 / tile_size_metres
```

Align the base-map set; give detail normals their own intentional scale. Stronger POM or normals do
not fix repeated giant cracks, unmodeled silhouettes, missing bevels or flat window geometry.
Wet asphalt is a rough dielectric substrate plus a spatially varying water response, not metal
with globally tiny roughness. Preserve a dry baseline before enabling wet layers.

## Know Which Light Or Image Term Is Being Tested

- Native direct light is not SH, Probe IBL, MatCap or emission. A bright highlight does not prove IBL.
- AO attenuates existing indirect contributions; it does not generate GI or native shadow maps.
- MatCap is a view-space appearance texture, not reflection of the current scene.
- Cubemap box projection/blending improves local approximation; it is not SSR, planar reflection,
  ray tracing, exact occlusion or automatically fresh scene content.
- Test environment reflection by changing only its material term, retaining direct lights. Refresh
  owned reflection/SH probes after changing materials, lights or sky; Ready alone may be stale.
- Emission does not automatically illuminate neighbors. Shadow styling is distinct from caster
  geometry and from availability of the engine's shadow resources.

## Transparency And Depth

Cutoff removes fragments; coverage fades surface presence; glass transmits light through an optical
material. Back/Front ordering is not OIT and does not solve arbitrary mesh intersections.
A depth prepass can improve selected overlaps while deliberately hiding other layers. Do not enable
ZWrite globally to make one screenshot look cleaner.

Normal maps and ordinary POM do not add geometry depth or silhouettes. Real displacement must agree
across color, Add, caster and actual depth paths, and requires suitable bounds/UV seams/skinning.
For camera depth, inspect capture metadata: device vs linear depth, reversed Z, row order, projection,
near/far and downsampling. Do not reuse a depth formula across incompatible conventions.
Transparent rain/glass commonly expose background opaque depth; ordinary DOF cannot represent
multiple transparent interfaces at once.

## Context-Free Agent Workflow

1. Identify package GUID/version, exact shader, material renderer/slot and active map branches.
2. Read the local Pipeline, MaterialContracts, manifest and tooltip entry. Do not infer current
   state from an old roadmap or conversation.
3. Inspect source and installed artifact separately. Source support is not proof that the user's
   older installed bundle contains that support.
4. Back up only the task-owned data. Read tool schemas and current scene/session IDs. Use ME-backed
   writes and readback; use the Editor/Bridge for native Unity assets, never serialized text edits.
5. Compare one feature at a time under matched camera, light, postprocessing and animation state.
   Keep failed controls and identify what the comparison does not isolate.
6. Save a native card and reload independently, reacquiring handles. Check maps/ST, values, masks,
   lights/visibility, camera, sky, depth and probe capture completion.
7. Report supported behavior, measured response, remaining hypotheses and limitations separately.
   Still-image RGB difference is not energy conservation, a GPU budget or temporal stability.
8. For delivery, freeze corresponding source/dependencies and audit the actual bundle and final
   archive, not only successful Editor previews. Do not combine unrelated build outputs.

## Safety And Maintenance

Do not modify shared/default materials, game-managed skin masks or another project's independent
include copy inadvertently. Preserve exact public shader/property IDs, supplied GUIDs and explicit
saved values. Never treat an old session's operation authorization as permission to terminate a new
Editor, rebuild everything, delete caches, operate UI, deploy or push.

These docs grant no tool access. Local project rules and the current user request still govern.
Do not publish connection tokens, private scenes, raw logs or diagnostic caches. Keep reproducible
public knowledge separate from machine-local evidence.

Run the project-local `Audit-RenderDocs.ps1` for a read-only source/manifest/carrier inventory check.
It does not invoke Unity or prove compilation, delivery bytecode, material appearance or performance.
Review drift before an explicit catalog refresh; never refresh merely to make a stale check pass.
Catalog schema 2 hashes source text as UTF-8 without a BOM and with LF line endings. This avoids
false drift from Git checkout conversions; it is not a byte-exact build/resource integrity audit.
