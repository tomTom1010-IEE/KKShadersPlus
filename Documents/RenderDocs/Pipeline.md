# V Plus LTS Rendering Pipeline

V+ is a legacy-compatible stylized shader family with targeted LTS repairs. Different variants
retain different main-light ramps, mask meanings and reflection Passes. A declaration in Unity
includes does not mean the fragment uses the same shading algorithm as another family.

## Source Map

Paths below are relative to this package.

| Module | Responsibility |
| --- | --- |
| `Shaders/Item/*Plus*.shader` | Item-family properties, render states, macros and Pass ordering |
| `Shaders/Item/KKPItemFrag.cginc` | Main Opaque/Alpha-style fragment composition |
| `Shaders/Item/KKPItemItemFrag.cginc` | Game-item-specific composition |
| `Shaders/Item/KKPStudioItemFrag.cginc` | Studio-specific ramp/shadow/reflection composition |
| `Shaders/Item/KKPItemNormals.cginc` | Unity-packed normals and independent MatCap normal selection |
| `Shaders/Hair/KKPHair*.cginc` | Hair lighting, normals, coverage, AnotherRamp and separate Reflect |
| `Shaders/Skin/KKPSkin*.cginc`, `KKPDiffuse.cginc`, `KKPNormals.cginc` | Game skin layers, alpha/clipping, normals, reflection and masked shells |
| `Shaders/Eye/KKPEye*.cginc` | Eye/EyeW color, UV transform, coverage, stencil and reflection |
| `Shaders/KKPLegacyForwardAdd.shader`, `KKPForwardAdd.cginc` | Hidden per-family additional pixel-light Passes and shared attenuation |
| `Shaders/KKPVertexLights*.cginc` | Unity four-light arrays and legacy diffuse/specular evaluation |
| `Shaders/KKPReflect.cginc`, `KKPMatcapBlur.cginc` | Item reflection composition and optional MatCap blur |
| `Shaders/KKPEmission.cginc` | Legacy emission modes and restored EmissionKeepCol behavior |
| `manifest.xml`, `Tooltips` | ME names/categories/help and shader carriers |

Shader names, literal Pass names and hidden UsePass references are in [ShaderCatalog](ShaderCatalog.json).
Separate Hair/Skin Reflect variants add their own reflection composition; do not infer that an
Item integrated-reflection fix applies to those Passes automatically.

## Native Lights And LTS Compatibility

Base Passes retain legacy main/four-light behavior. Four-array slots are selected/populated by
Unity, not four arbitrary lamps enumerated by this shader. Additional native pixel lights use
ForwardAdd, including native shadow/cookie/distance paths supported by the active variant.

The 1.7.6 compatibility contract is important:

- Base precedes relevant Add contributions so it does not overwrite them.
- Four-array lighting remains alongside pixel-light contributions; do not disable the arrays simply
  because a shadow switch is enabled.
- UseForwardAddFullShadows is a shadow switch, not permission for extra pixel lights to exist.
  Off retains those lights' range/cookie attenuation; DisablePointLights is a different control.
- Final attenuation is applied after Toon ramp evaluation so a nonblack ramp cannot relight a
  zero-attenuation lamp. Inspect family Add code instead of multiplying all final RGB by one shadow.
- A float switch does not change Unity's light allocation as though no ForwardAdd Pass existed.
  Off is shader-only compatibility, not exact historical light selection or pixel equality.

Shadow-map generation still depends on Unity lights/casters/settings. Four-array data alone does
not contain arbitrary point-light shadow maps. Adding a receiving path is not deferred rendering
or a custom shadow generator. MatCap/rim/emission are artistic terms with family-specific ownership;
do not duplicate complete Base output in every Add Pass.

## Alpha, Depth, Stencil And Tess

MainAlphaPlus uses straight SrcAlpha/OneMinusSrcAlpha composition, selectable Cull and color ZWrite.
Its output alpha and cutoff helper are related but not identical formulas. SkinAlpha preserves
body overlays and game clothing masks. SkinMaskedAlphaTwoPass seals backfaces opaquely first, then
blends selected front regions; it intentionally has no legacy outline shell and is not OIT.

Eye/EyeW write stencil used by HairFront's branches. EyeAlpha/EyeWAlpha separate the color cutoff
from StencilCutoff, but the stencil remains binary. They do not encode partially transparent hair
occlusion in an 8-bit stencil value. HairFront DOF/depth variants have dedicated depth behavior;
ordinary transparent rendering does not imply correct alpha-aware DOF depth.

Tess shaders use their family's existing tess/displacement libraries and must be read across
Forward/outline/caster/Reflect. A height-derived normal is not vertex displacement. V+ height
experiments use their own threshold/contrast/strength semantics, not modern BSDF Height-v1.

## Maintenance Boundaries

The MainOpaqueBlend/overlay BRDF libraries are local compatibility copies. Standalone X and BSDF
are separate projects; their newer algorithms are not automatically present here. Keep V+ public
names, macro routing, existing controls and explicit saved values stable during LTS repair.

The source provides compile/render/test paths but this reference was produced by static review.
Known branch differences are not bugs merely because another variant differs. Reproduce a reported
defect in the correct family, installed package, light allocation and render state before changing it.
Keep native assets and supplied GUIDs; all asset editing belongs in the Editor/Bridge.
