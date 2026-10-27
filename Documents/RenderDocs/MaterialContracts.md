# V Plus LTS Material Contracts

Use the exact shader/manifest spelling, including historical names such as SpeclarHeight and
notusetexspecular. Do not normalize names or transplant TomX/BSDF controls during an LTS fix.
Read [Pipeline](Pipeline.md) and the relevant fragment include before assuming a shared behavior.

## Normals, Highlights And Reflections

Main/detail normal maps generally use Unity packed UnpackScaleNormal plus the family's normal
combination. They are not arbitrary RGB XYZ textures or scalar height maps. Verify ME's conversion
for the actual slot. There is no universal BSDF-style encoding selector on V+ materials.

For adapted Item shaders, UseNormalMapForMatCap and UseDetailNormalMapForMatCap default to 1.
They remove only the corresponding normal-map contribution to the integrated reflection direction.
Lighting/specular/rim retain their own normal path; liquid/backface adjustments still apply as coded.
Do not claim those Item controls exist on every Hair/Skin/Eye separate Reflect variant.

AnotherRamp is an artistic response texture, not a uniform surface color map or GI source. Ordinary
Item, Studio Item and Hair use different input coordinates and blend gates. Item AnotherRampFull
and Hair AnotherRampStrength are not equivalent controls. Similar defaults therefore need not
produce matching images. Adapted MatCap blur is also not a new roughness map or real scene reflection.

Legacy mesh highlights commonly map a 0..1 SpecularPower-style control to a much larger exponent
and mix it with authored highlights/ramp logic. notusetexspecular chooses/mixes authored versus mesh
highlight behavior in the relevant family; it is not the modern GGX roughness parameter. Experimental
overlay controls may use different exponents; inspect them rather than assuming one global scale.

Hair Reflect: ReflectMask R mixes the chosen environment toward MatCap where UseMatCapReflection
is active. Black does **not** disable the entire reflection Pass; it leaves the environment side.
ReflectMap R gates reflection value separately. DetailMask and reflection-color/blend controls
also shape the result. In a multiplicative framebuffer mode, a dark environment can darken regions
outside the MatCap mask. That is different from a general on/off coverage mask.

Item integrated reflections use ReflectMapDetail differently: R gates the final reflection/body
blend, G selects environment-to-MatCap mixing. It is neither a normal-detail map nor a universal
Hair ReflectMask alias. Keep these channel contracts separate when moving a material between families.

## ShadowColor Alpha Is Family Specific

| Family/path | Relevant meaning |
| --- | --- |
| Ordinary Item / Skin branches using `lerp(1, RGB, 1-saturate(A))` | A=0 full tint, A=1 suppresses tint |
| MainAlpha / MainItemAlpha | Alpha macros can bypass or reshape parts of ordinary opaque shadow-color behavior |
| Studio non-Alpha | Retains its own ramp/shading computation, with reverse-strength branches |
| Studio Alpha | Normalizes/shapes RGB with A, then replaces A internally; not the ordinary reverse rule |
| Hair | Primarily RGB dark-response remapping, not the same reverse-alpha switch |
| Eye / EyeW | Do not inherit the body/item shadow-color model |

This is shadow **styling**, not whether geometry casts a shadow. White tint, inactive branch,
already-lit response, emission or a reflection layer can hide its visible effect. Inspect the exact
branch and a controlled light/caster scene. The older [Shadow notes](../Shadow.md) provide additional
family context but are not a declaration that every branch shares one formula.

## Alpha And Body Masks

Ordinary Item clipping uses the legacy two-channel clothing-mask helper, alpha_a/alpha_b and cutoff;
it is not simply the soft blended alpha. In MainAlpha-style color paths, the processed mask R
multiplies MainTex.a and Alpha. AlphaOptionCutoff can also select mask remapping. Inspect caster
and outline separately; a matching control label does not prove they use identical alpha formulas.

SkinAlphaPlus and its Reflect/Tess variants retain skin overlays and the existing body AlphaMask.
The latter can be controlled by the game, Body Mask or ME for clothing penetration. Do not replace
that slot with a user's see-through paint mask.

SkinMaskedAlphaTwoPass instead uses a separate TransparencyMask R:

```text
local front alpha = saturate(1 - saturate(TransparencyMask.r) * saturate(MaskedTransparency))
```

Black retains the front surface, white fades it by the slider, and gray gives a smooth intermediate
alpha. The independent mask does not replace the game's clothing-mask clipping. The opaque
backface seal still blocks the outside background where appropriate. Front ZWrite is separately
controlled, default off. There is no generated cut-edge thickness or legacy outline shell.

EyeAlphaPlus/EyeWAlphaPlus use Cutoff for color and StencilCutoff for writing the HairFront avoidance
region. Stencil stores a binary visibility decision, not coverage alpha. Lowering color cutoff
alone does not create fractional stencil blending. Do not relabel these as optical glass shaders.

## Height And Overlay Experiments

MainHeightAlpha reconstructs normals from HeightMap gradients and retains MainAlpha-style shading.
MainHeightAlphaDisplace additionally deforms vertices through the legacy geometry route.
The height core reverses samples before threshold/contrast masks, so IsHeightReverse changes both
relief direction and the region receiving height-derived effects. It is not only a normal flip.

In that Item height-displacement path, displacement is height times its derived mask times
HeightDisplaceStrength along the object normal. HeightScale also controls the gradient-normal
response. These are **not** the world-metre inward envelope semantics of BSDF. TomHeight overlay
experiments must be inspected separately; an additive framebuffer cannot darken the underlying
scene merely because its own MatCap composition is Multiply. Blend state and fragment composition
are different operations.

## Emission And Metadata

EmissionMask is not automatically light emission into scene GI. The legacy CombineEmission helper
has distinct masked/overlay modes; EmissionKeepCol preserves underlying color in its applicable
composition. Ordinary shaders default 0, Eye/EyeW default 1 in the restored contract. Do not remove
it when reordering categories or copying upstream property blocks.

ME Category is presentation metadata. Ordinary non-Blend textures are grouped together; reflection
maps/AnotherRamp belong with Reflection / MatCap, and notusetexspecular with Specular. Eye groups
were intentionally kept simple. Blend keeps its own shared/stylized/PBR split. Never add nonexistent
properties to a shader merely to make category sets uniform.

MainTex, DetailMask, NormalMask, LineMask and game overlays are family-specific art inputs, not ORM.
Preserve their channels until verified from the exact implementation. Keep shader, manifest and
embedded tooltip IDs synchronized without changing render behavior for a documentation-only task.
