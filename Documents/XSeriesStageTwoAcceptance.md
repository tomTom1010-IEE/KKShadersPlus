# X Stage Two: Material Contract and Visual Acceptance

## Accepted Baseline

The user accepted scene and packaged KKS results on 2026-10-02. Stage Two closure
and additional authorized Bridge render checks are recorded in
[XSeriesStageTwoClosure.md](XSeriesStageTwoClosure.md). The matrix below remains
a regression checklist, not a statement that every row was individually certified.

## Delivery Boundary

KKS tom/MainOpaqueX only. This is a Toon-first hybrid, not a strict physical BRDF.
Code and automated structural checks can be accepted separately from appearance.
At the original handoff, only the user performed visual acceptance. At closure the
user additionally authorized Bridge-only rendering and agent inspection. Overall
appearance approval comes from the user's scene and in-game tests, not compilation.

## Composition

1. Sample base color, cutout and combined normal; derive metallic, roughness and F0.
2. Evaluate each pixel light through the same visibility and Toon/GGX model.
3. Base body is indirect diffuse (with main-shadow tint), vertex fill and main diffuse.
4. Multiply MatCap tints diffuse in Base AND each Add pass. Mid-gray is neutral
   because the sampled MatCap color is multiplied by two.
5. Direct specular, environment, additive MatCap, Rim and emission are added.
   Only direct diffuse/specular repeat in Add; diffuse multiplication repeats as a
   material tint, not as an extra emissive contribution.
6. Final-view fog follows composition; outline is a separate shell pass.

At DiffuseEnergyBlend 0, dielectric IOR/Fresnel cannot suppress diffuse.
Metallic still removes diffuse. At 1, Fresnel suppresses diffuse. This optional
physical weight does not make the artistic composite strictly energy conserving.

Direct SpecularToonBlend 0 uses continuous production GGX. At 1 the GGX NDF is
normalized by its peak and shaped by size, threshold, softness and bands before
light radiance is applied. Intermediate values blend these results; no Blinn remains.
Physical Roughness remains meaningful for continuous GGX and probe blur.
SpecularSize controls the Toon endpoint independently; do not expect Roughness to
resize a fully stylized direct highlight.

EnvironmentToonBlend 0 retains continuous HDR response; 1 selects bright environment
regions and caps artistic luminance before Fresnel/tint. ColorWeight acts on the
stylized endpoint. Selection Exposure changes the selection input, not scene ambient.
Uniform environments have no localized bright features to recover.

Procedural Toon transfer is the default. Texture ramps use R, not RGB recoloring.
SecondaryRamp is an alternative transfer mixed by strength times LayerMask R.
Actual shadow visibility remains outside the ramp as well as optionally affecting
its input. Shadow strength overrides are artistic controls, not physically correct
shadow removal. Indirect tone shaping is separate from direct Toon transfer.

Multi-light composition remains additive HDR. It does NOT normalize all lights or
guarantee unchanged brightness as more lights are added. AdditionalLightIntensity
controls their aggregate contribution. Arbitrary per-pass clamps would break light
order/parity and are intentionally absent. Exposure/bloom can still wash out bands.

## Texture and UI Contract

See XSeriesStageTwoProgress.md for the complete packed-channel contract.
98 manifest properties have X-specific tooltips in Tooltips/tom_x_tooltips.xml.
ME must support TooltipCatalog to display them. A bundle rebuild is required for
in-game deployment; Editor import alone does not update an installed zipmod.

ReflectionMode gates environment/MatCap. Direct and environment Fresnel are separate.
Rim is an artistic facing band, not the material Fresnel. EmissionKeepCol multiplies
emission by the evaluated base color. Debug views omit fog and outline.
MatCap debug in Multiply mode shows the multiplier, not the resulting body color.

## Prototype Migration

- GGXSpecularBlend removed: SpecularToonBlend 0 now selects continuous GGX, not Blinn.
- SpecularPower removed: use SpecularSize, Threshold and Softness.
- RimPower removed: use RimWidth and RimSoftness.
- DiffuseEnergyBlend defaults to 0; set 1 only when physical body suppression is wanted.
- Existing prototype materials may retain old serialized values. They are unused;
  no existing user material has been rewritten to remove them.
- No automatic V+ migration, KK backport, new Reflect variant or transparent shader.

## Reference Scenes

Open one scene at a time from Assets/TomXStageTwoAcceptance/Scenes:

- EnvironmentOnly: zero lights, flat ambient and structured synthetic environment.
- SingleLight: one shadowed directional light and an occluder.
- MultiLight: the same layout plus shadowed point and spot lights, forced pixel.

Upper row, left to right: Cloth, Plastic, PaintedMetal, BareMetal, Glossy, SkinLike.
PaintedMetal represents dielectric paint over metal, not an exposed metallic layer.
SkinLike is a generic dielectric color reference, not a subsurface skin shader.
Lower row: Final, Body, Direct Specular, Environment, MatCap, Rim, Emission.
Debug-row materials deliberately enable small amounts of all art layers.
The same material assets are shared across scenes for direct comparison.

The synthetic cubemap has ordinary generated mips, not production GGX convolution.
Use real KKS Reflection Probes for final roughness/IBL acceptance. No probe capture
or bake was performed. No global quality/project settings were changed.

## User Test Matrix

Use fixed exposure, no bloom or tone-changing post effects initially, and record
settings with screenshots. Pixel Light Count must admit the tested pixel lights.
Keep the camera fixed for comparisons except the explicit view-rotation tests.

| ID | Procedure | Expected result |
| --- | --- | --- |
| T01 | EnvironmentOnly, Body debug, Metallic 0, DiffuseEnergyBlend 0; vary IOR 1/1.5/2.5, both Fresnel controls 0/1/2 and Roughness .04/.5/1 | Body does not change from these controls; target difference at most 1/255 in a fixed LDR comparison |
| T02 | Repeat with DiffuseEnergyBlend 1 | Fresnel-dependent body suppression becomes visible; not a default requirement |
| T03 | Environment debug; compare EnvironmentToonBlend 0/1 and sweep threshold/softness/exposure | Continuous versus selected bright regions are distinguishable without changing ambient diffuse |
| T04 | Rotate camera in environment scene; compare Body and Environment views | Material body remains stable under the default diffuse contract; reflection moves with view |
| T05 | SingleLight, Direct Specular view; intensity .25/1/4, fixed position | Unclipped normalized highlight shape stays fixed; brightness scales. Bloom/clipping can change perceived size |
| T06 | Directional/point/spot, move light behind surface and behind occluder; shadow strengths 1 | No back-lit specular leak; real occlusion remains effective |
| T07 | Roughness .04/.1/.5/1 in continuous GGX, then Toon size/softness/bands; views through 89 degrees | Continuous material response and independent Toon shape both usable; no NaN/Inf or full-surface flash |
| T08 | Add a high-frequency imported normal map; compare SpecularAA 0/.5/1 while moving camera | Reduced aliasing without unacceptable loss of shape. Temporal stability remains a visual gate |
| T09 | Procedural/texture ramp, secondary strength 0/1 and LayerMask R 0/1; test in shadow | Optional transfer is region-controlled and cannot inadvertently remove full shadow at strength 1 |
| T10 | SingleLight versus MultiLight with same material; sweep AdditionalLightIntensity | Extra lights add predictable diffuse/specular, not repeated environment/Rim/emission |
| T11 | Diagnostic MatCap, Multiply/Add, normal source 0/1/2; compare Body/Specular/Emission views | Multiply changes diffuse only and is consistent for main/additional lights; Add occurs once |
| T12 | Disable each layer, use black/white mask channels; emission KeepCol 0/1 | Each layer is independently removable; masks own only their documented layers |
| T13 | Outline width mask 0/1; nonuniform and negative scale; optional mesh with valid UV4 normals | Width masking and expansion remain coherent with cutoff. Smooth-normal mode needs correctly authored data |
| T14 | Real reflection probes, cloth/plastic/painted/bare metal comparison; AO black/white | Material differences persist; AO affects indirect layers only; metal diffuse disappears |
| T15 | ME category and Shift-hover tooltips after bundle deployment | All 98 properties appear under correct categories with X-specific hints |

## Performance and Known Boundaries

Use Frame Debugger/profiler, not shader source counts alone, to assess GPU cost.
Packed MaterialMap replaces four separate data reads where applicable. Disabled
reflection/emission paths use uniform branches. The GPU/compiler may flatten branches;
there is no verified timing claim or complete shader-keyword optimization in this pass.
Multiply MatCap intentionally adds conditional texture work to ForwardAdd to keep
all diffuse lights consistent. Stage One's no-MatCap-in-Add cost baseline is historical.
Many shadowed pixel lights remain expensive in Built-in Forward; vertex lights remain
unshadowed diffuse fill. No deferred conversion or replacement shadow pipeline is added.

## Automated Evidence and Remaining Gate

Tests/Test-XStageTwo.ps1 checks XML, 98-property parity, tooltip coverage, layer/pass
contracts and 36 CPU algebra samples. These are NOT executed GPU formula comparisons.
CodexBridge validatexstage2 warms 13 selected variants and reads ShaderUtil messages.
finishxstage2references inspects saved scene light/camera/renderer counts and materials.
These tests do not cover all platform, GI, fog, instancing or runtime feature combinations.
Overall user visual acceptance is complete. Refer to the closure report for scoped
automated render coverage; untested matrix rows and production GPU profiling remain
release-hardening checks, not automatically passed by that overall acceptance.
