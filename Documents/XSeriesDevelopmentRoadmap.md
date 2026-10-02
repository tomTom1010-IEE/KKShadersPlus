# X Series Three-Stage Development Roadmap

## Stage Two Accepted (2026-10-02)

The user accepted reference-scene and packaged KKS appearance. Stage Two is now
closed as the versioned Toon material baseline. Follow-up CodexBridge rendering
passed the scoped regression checks without modifying shader appearance.
See [closure evidence and remaining hardening work](XSeriesStageTwoClosure.md).
The 98-property interface and texture-channel contract are frozen. The next
development target is MainAlphaX, not additional opaque material features.
Production GPU profiling and untested edge cases remain explicit Stage Three
release-hardening work; closure does not retroactively pass every Stage One gate.

## Stage Two Working Baseline (2026-09-20)

The KKS MainOpaqueX working implementation now targets stable Toon body color and
independently controllable material highlights. Stage One descriptions below record
the historical foundation and its original acceptance baseline; they are not a claim
that removed prototype controls still exist.

- Optional DiffuseEnergyBlend replaces implicit Fresnel suppression at the default.
- SpecularToonBlend selects continuous GGX or GGX-shaped Toon highlights. The old
  GGXSpecularBlend/Legacy Blinn and SpecularPower controls are removed.
- Environment reflection has separate selection, softness, exposure, hue influence,
  tint and Fresnel controls. Roughness remains part of the material contract.
- Procedural and secondary direct tone transfer, indirect tone shaping, simplified
  Rim, diffuse-only MatCap Multiply and emission base-color tint are implemented.
- MatCap Add remains Base-only. MatCap Multiply now also runs conditionally in Add
  so all diffuse lights receive the same tint; this supersedes the old Add cost rule.
- Outline adds a width mask and optional UV4 object-space smooth normals.
- 98 shader/manifest properties have scoped tooltips. Reference scenes are generated
  through CodexBridge without rendering or changing existing user materials.

See [Stage Two progress](XSeriesStageTwoProgress.md) for implementation evidence and
[material contract and user tests](XSeriesStageTwoAcceptance.md) for composition,
migration, texture ownership, limitations and the pending visual acceptance gate.
Stage Two code does not imply Stage One's manual gates have retrospectively passed.

## 1. Project Definition

The X series is a new shader architecture informed by the practical experience of the xukmi/V+ shaders. It is not intended to reproduce every V+ option or every historical shader variant.

The target is a Toon-first hybrid material system that:

- Preserves the clear light and shadow grouping of the existing Koikatsu toon style.
- Uses modern real-time material principles for specular response, reflections, indirect lighting, and energy handling.
- Responds consistently to directional, point, and spot lights, including real-time shadows.
- Uses the useful capabilities of Unity 2019.4.9f1 Built-in Forward rendering.
- Remains understandable, modular, and economical enough to maintain as a new shader family.

KKS with Unity 2019.4.9f1 is the primary design target. KK/Unity 5.6 compatibility is a best-effort backport target and must not prevent the 2019.4 implementation from using appropriate engine features.

## 2. Core Design Rules

1. Toon shading controls the large-scale light and shadow composition.
2. PBR principles control material response, especially specular, Fresnel, roughness, metallic response, and probe reflections.
3. Physical visibility and artistic shadow shaping must remain separate.
4. MatCap, rim, outline, and similar effects are optional art-direction layers, not substitutes for scene lighting.
5. A new shader variant is created only when its render state or material model is genuinely different.
6. Reflection is a material module. The X series does not need separate `Reflect` variants.
7. Studio lighting must use the same material model. The X series does not need separate `Studio` variants.
8. Tessellation and displacement are special-purpose features, not mandatory variants of every shader.
9. Old behavior may be removed or redesigned when it is difficult to explain, scene-dependent, or incompatible with the new lighting model.
10. Feature count is not a measure of modernity. Predictable behavior and coherent composition take priority.

## 3. Current Baseline

The current prototype is `tom/MainOpaqueX`, supported by:

- `Shaders/Tom/TomToonInput.cginc`
- `Shaders/Tom/TomToonLighting.cginc`

The prototype already demonstrates:

- `TomMaterialData`, `TomShadowData`, `TomRawLightData`, `TomSurfaceLightTerms`, and `TomLightingResult` separation.
- ForwardBase, ForwardAdd with full shadows, ShadowCaster, and outline passes.
- Toon diffuse ramp and adjustable shadow shaping.
- Production GGX direct specular with an experimental Legacy Blinn compatibility blend.
- Metallic, roughness, IOR/F0, Fresnel, and specular masks.
- Geometric-normal and shading-normal horizon restrictions.
- SH indirect diffuse, Reflection Probe blending, box projection, roughness mip, and AO.
- Base-pass-only MatCap, probe reflection, rim, and emission.

This is an architecture prototype, not the final material model. Existing implementation is evidence that the pipeline works, but it may be rewritten during Stage One and Stage Two.

---

## Stage One: Modern Built-in Lighting Foundation

### Goal

Complete a correct, efficient, scene-aware lighting foundation for `tom/MainOpaqueX`. At the end of this stage, the shader should be a reliable general opaque/cutout shader even before advanced stylization controls are added.

### Required Work

- Preserve the layered material, raw-light, surface-light, and lighting-result architecture, refining the fields where necessary.
- Separate distance attenuation, cookie attenuation, real-time shadow visibility, NdotL, and artistic shadow shaping.
- Remove attenuation reconstruction based on dividing combined attenuation by shadow attenuation.
- Keep main-light and additional-light evaluation on the same material model.
- Support ForwardAdd full shadows without repeating IBL, MatCap, rim, emission, or indirect lighting for every additional light.
- Build pass-specific material sampling so ForwardAdd only reads textures required for direct diffuse and specular.
- Use GGX as the stable direct-specular foundation.
- Complete energy-conserving diffuse/specular interaction.
- Replace the simplified environment term with an appropriate pre-integrated or Unity-compatible environment BRDF approximation.
- Support SH Light Probes and Light Probe Proxy Volumes where available.
- Support baked lightmaps, directional lightmaps, Mixed Lighting, and Shadowmask variants relevant to Built-in Forward.
- Support Reflection Probe HDR decode, blending, skybox blending, box projection, and roughness mip selection.
- Apply AO to indirect diffuse and indirect specular without incorrectly darkening direct lighting.
- Add Built-in fog support.
- Add GPU instancing support where compatible with the target renderer.
- Define explicit single-sided and double-sided normal policies.
- Keep Forward, Outline, and ShadowCaster alpha cutoff behavior consistent.
- Review ShadowCaster culling and offset behavior for thin and double-sided geometry.

### Current Status

- KKS foundation code for `tom/MainOpaqueX` is implemented. Stage One remains open until the manual scene and performance gates below are accepted.
- The final static audit found no required Stage One source item intentionally left unimplemented inside KKShadersPlus. Further Stage One code changes should be driven by a failed acceptance test; the placeable SH provider remains an external probe-track dependency.
- `TomMaterialData`, `TomShadowData`, `TomRawLightData`, and `TomSurfaceLightTerms` now keep material response, engine shadow visibility, raw light input, and material-dependent surface interpretation separate.
- Distance attenuation and cookie attenuation are sampled independently for directional, point, spot, point-cookie, and directional-cookie variants. The old combined-attenuation division has been removed.
- ForwardAdd uses a direct-only material path and no longer samples AO, reflection mask, emission, MatCap, or Reflection Probes.
- Built-in GI now covers SH, LPPV, static and dynamic lightmaps, directional lightmaps, Mixed Lighting, and Shadowmask variants generated by Unity's Forward pragmas.
- Static Subtractive lightmaps own the baked main-light direct term, so the custom realtime main-light evaluator is disabled for that variant. Realtime, Shadowmask, and Distance Shadowmask paths retain realtime direct lighting and their corresponding shadow visibility.
- Vertex lights are a separate geometry-normal diffuse fill rather than part of SH or indirect GI. They do not use normal maps, Toon Ramp, GGX/specular, cookies, realtime shadows, AO, indirect-light intensity, or main-light shadow tint, and have a dedicated low default intensity.
- Reflection Probe IBL now uses Unity 2019's HDR decode, roughness mip mapping, two-probe blending, box projection, and Unity-compatible environment BRDF response.
- Material AO affects indirect diffuse and indirect specular only. Direct light remains independent of AO.
- `_GGXSpecularBlend = 1` is the production direct-specular path and uses Unity 2019's GGX distribution, Smith joint visibility, Schlick Fresnel, and energy-conserving diffuse suppression. `0` retains Legacy Blinn for experimental compatibility; intermediate values are not guaranteed to conserve energy.
- Built-in fog, GPU instancing, stereo plumbing, and explicit back-face normal/TBN correction are connected to the relevant passes.
- Forward, Outline, and ShadowCaster use the same `_MainTex.a * _AlphaMask.r` cutoff contract and the same front/back-face convention. ShadowCaster uses manual `VFACE` culling so each material keeps its own cull state on Unity 2019.4.
- Single-sided shadow casters use Unity Normal Bias along the rendered side (`+normal` for Cull Back, `-normal` for Cull Front). Cull Off casts both sides without normal offset and relies on Unity depth bias plus optional material raster offset, which defaults to zero.
- Outline expansion uses normalized world-space normals and manual face selection so odd/even negative scale does not introduce a separate outline-facing convention.
- The KKS receiver can optionally consume runtime-captured local L2 SH volumes supplied by a placeable probe provider. `tom/MainOpaqueX` blends this custom diffuse volume at the material level while preserving native lightmaps, direct lights, ForwardAdd shadows, and Reflection Probe specular.
- The placeable probe items are delivered by the independent `tom.lightingprobes` Studio item mod. KKShadersPlus retains only the X-series receiving shader code and MaterialEditor declarations.
- Dated implementation and test results are tracked in [XSeriesStageOneProgress.md](XSeriesStageOneProgress.md).

### Implementation Audit

| Workstream | Implementation evidence | Current state |
| --- | --- | --- |
| Material and light data separation | `TomMaterialData`, `TomShadowData`, `TomRawLightData`, `TomSurfaceLightTerms`, and `TomLightingResult` | Implemented and import-verified |
| Main and additional direct lights | Shared `TomBuildRawLightData`, `TomBuildSurfaceLightTerms`, and `TomEvaluateDirectLight`; `multi_compile_fwdadd_fullshadows` | Implemented; scene gate open |
| Distance, cookie, and shadow ownership | Independent attenuation fields; no division of combined attenuation by shadow | Implemented; scene gate open |
| ForwardAdd material path | Seven direct material samples plus one ramp sample; no Base-only layers | Static audit passed; GPU gate open |
| Production direct specular | Unity 2019 GGX NDF, Smith joint visibility, Schlick Fresnel, and safe half-vector handling | Implemented; grazing-angle gate open |
| Energy interaction | GGX endpoint suppresses diffuse with Fresnel and metallic response | Implemented; material gate open |
| Indirect diffuse and specular | Unity GI, SH/LPPV receiver, lightmaps, Unity-compatible probe BRDF, and indirect-only AO | Implemented; scene gate open |
| Mixed Lighting ownership | Subtractive baked direct ownership; realtime direct retained for Realtime and Shadowmask paths | Implemented; bake matrix open |
| Vertex lights | Geometry-normal diffuse fill with dedicated intensity and no specular, shadow, cookie, ramp, or AO | Implemented; demotion test open |
| Reflection Probes | HDR decode, roughness mip, blending, box projection, and sky fallback through Unity GI | Implemented; probe scene gate open |
| Fog, instancing, and stereo | Pass pragmas and transfer data connected | Import-verified; Frame Debugger gate open |
| Face, cutoff, outline, and shadow policy | Shared `VFACE` convention, manual ShadowCaster culling, zero double-sided normal offset, common alpha clip | Implemented; thin/negative-scale gate open |
| Placeable SH volume provider | Receiver remains in this shader; authoring and runtime provider live in `tom.lightingprobes` | External probe-track evidence required |

### Automated Verification Status

- Unity 2019.4.9f1 completed a forced AssetDatabase refresh through CodexBridge with no final `tom/MainOpaqueX`, `TomToonLighting`, or `TomToonBRDF` shader error or warning.
- `manifest.xml` parses successfully and all 65 `tom/MainOpaqueX` shader properties match the 65 manifest properties.
- ForwardBase, ForwardAdd, Outline, and ShadowCaster source contracts are present; fixed `Offset 1, 1` is removed.
- Shared `KKPPBRBRDF.cginc` remains unchanged. The production GGX implementation is isolated to the Tom library.
- No visual, bake, Frame Debugger, RenderDoc, or GPU timing acceptance has been recorded yet.

### Controlled Acceptance Setup

- Use KKS Unity 2019.4.9f1 Built-in Forward and the project `Fantastic` quality level: Pixel Light Count 4, four cascades, 150 m shadow distance, and realtime Reflection Probes enabled.
- Use a fixed 1920x1080 Game camera, VSync off, fixed exposure, and no post-processing for image or timing comparisons. The project's `Fantastic` quality entry defaults to VSync 1, so explicitly override it to 0 for timing runs.
- For isolated direct-light tests set Ambient and Indirect Intensity to zero, Vertex Light Intensity to zero, Reflection Mode off, Rim/Emission/Outline off, Toon Ramp off, and `_GGXSpecularBlend = 1`.
- Warm up 120 frames, record 300 frames, and report median plus P95 GPU frame time. Record GPU, driver, resolution, quality level, and visible renderer/light counts.
- Use lossless screenshots or HDR captures. An LDR equality tolerance of `1/255`, silhouette tolerance of one display pixel, and shadow tolerance of two shadow-map texels are the default limits.

### Stage One Acceptance Matrix

| ID | Test | Pass metric |
| --- | --- | --- |
| C01 | Import and property contract | No X-series shader error/warning; XML valid; shader and manifest property sets identical |
| L01 | Directional, point, and spot parity | Each light produces diffuse and GGX specular through the same controls; in an unclipped isolated capture, changing its applicable intensity from 1.0 to 0.5 gives an RGB/luminance ratio of `0.50 +/- 0.03` |
| L02 | Additional-light full shadows | A fully occluded sample loses at least 90% of its isolated ForwardAdd direct contribution; enabling MatCap, IBL, rim, emission, or indirect light changes the isolated Add output by at most `1/255` |
| L03 | Distance and cookies | Point/spot intensity decreases monotonically with distance; outside a spot cone or black cookie the isolated direct delta is at most `1/255` |
| L04 | Geometric horizon | With the light behind the geometric surface, isolated direct diffuse and specular deltas are at most `1/255` |
| V01 | Vertex-light demotion | Lights beyond Pixel Light Count add no ForwardAdd draw, GGX, cookie, or realtime shadow; `_VertexLightIntensity = 0` removes their delta within `1/255` |
| G01 | Lightmap and Mixed Lighting | Realtime, Baked Indirect, Subtractive, Shadowmask, and Distance Shadowmask contain one direct-light owner; fade/transition luminance discontinuity stays below 5% |
| G02 | AO ownership | Black AO changes isolated direct light by at most `1/255`; indirect diffuse and probe specular darken monotonically with AO strength |
| G03 | SH/LPPV receiver | Dynamic objects follow spatial probe changes without direct-light duplication; evidence may be imported from the probe-track project |
| R01 | Reflection Probe matrix | No-probe/sky, one probe, two-probe blend, and box projection remain finite; 20 equal movement steps through a blend region have less than 5% adjacent-sample luminance jumps unless crossing a deliberate hard boundary |
| F01 | Fog composition | Base, Add, and Outline converge at the same depth without colored additive halos; visible edge mismatch is at most one pixel |
| I01 | GPU instancing | Repeated identical mesh/material instances form one instanced draw per applicable pass in Frame Debugger and match non-instanced output within `1/255` |
| S01 | Thin and double-sided shadows | Quad, thin shell, and hair card obey Cull Back/Front/Off; Cull Off casts both sides without normal-bias separation or discontinuous gaps |
| S02 | Negative-scale consistency | `(1,1,1)`, `(-1,1,1)`, and `(-1,-1,1)` retain matching body, Outline, cutoff, and cast-shadow face conventions; screen-space Outline width differs by at most one pixel |
| S03 | Cutoff and offset | Body/Outline edge mismatch is at most one display pixel and body/shadow mismatch at most two shadow texels; default material raster Offset is zero |
| B01 | Production GGX stability | Roughness `0.04/0.1/0.5/1`, Metallic `0/1`, IOR `1/1.5/2.5`, and views through 89 degrees produce no NaN, Inf, full-surface flash, or back-lit highlight |
| B02 | GGX response and energy | As roughness rises, peak decreases and highlight width increases; with Metallic 1 and a black Specular Mask, isolated diffuse is at most `1/255` |
| B03 | Legacy compatibility | Blend 1 is the acceptance path, Blend 0 remains finite Legacy Blinn, and intermediate values remain finite but have no energy-conservation requirement |
| P01 | Draw and sample contract | Base has one ForwardBase draw; each pixel additional light adds one ForwardAdd draw per affected renderer; a shadowed point light may add six shadow faces; ForwardAdd keeps 7 material plus 1 ramp sample before light textures |
| P02 | Relative GPU cost | Repeated lights with the same type, screen coverage, cookie state, and shadow state have incremental median costs within 20% of each other; P95/median stays below 1.25; Base-only feature toggles change measured ForwardAdd pass time by no more than 5% |

### ForwardAdd Cost Baseline

- Base material path: 10 common material samples (`MainTex`, `AlphaMask`, two normals, metallic, roughness, specular mask, AO, reflection mask, and emission mask) plus one ramp sample. MatCap and one/two Reflection Probe samples are conditional Base-only work.
- Direct material path: 7 material samples (`MainTex`, `AlphaMask`, main normal, detail normal, metallic, roughness, and specular mask).
- Toon transfer: 1 ramp sample.
- Light visibility: Unity shadow sampling plus zero or more attenuation/cookie samples according to light type.
- Explicitly absent from ForwardAdd: occlusion map, reflection mask, emission mask, MatCap, Reflection Probe IBL, rim, indirect diffuse, and emission composition.
- Static sample ownership is verified. Compiled instruction counts and GPU timings remain part of P01/P02; compile-time feature variants and optional texture packing remain Stage Two optimization work.

### Non-Goals

- Do not restore V+ color masks, liquid, KKP rim, or specialized character behavior during this stage.
- Do not add transparent rendering during this stage.
- Do not create Reflect, Studio, or Tess combinations.
- Do not implement a custom render pipeline or replace Unity's shadow-map system.

### Exit Criteria

- Code gate: passed when C01 remains green.
- Lighting and material gate: L01-L04, V01, B01-B03 pass.
- GI and integration gate: G01-G03, R01, F01, and I01 pass. G03 may use evidence produced by the independent probe track.
- Geometry and shadow gate: S01-S03 pass.
- Performance gate: P01 and P02 are recorded with reproducible environment details and pass.
- Stage One is accepted only after every gate above passes or an explicit exception is documented in the progress record. Compilation alone does not close the stage.

### Stage Deliverable

A stable `tom/MainOpaqueX` lighting reference that can serve as the shared foundation for later X-series shaders.

---

## Stage Two: Toon Art Direction and Hybrid Material Model

### Goal

Define the final X-series visual identity: xukmi-inspired toon composition with modern, physically coherent material response. This stage decides which artistic controls are worth keeping and how they interact.

### Required Work

- Redesign the primary toon ramp as a documented light-transfer function.
- Keep real-time shadow visibility separate from ramp evaluation, with an explicit option to feed shadow visibility into the toon shaping stage.
- Replace the current Blinn/GGX blend with GGX-based stylized specular shaping.
- Add specular threshold, softness, banding, and intensity controls after GGX evaluation rather than maintaining two unrelated BRDFs.
- Define stable metallic, roughness, IOR, Fresnel, and energy-conservation semantics.
- Redesign `Another Ramp` as an optional Secondary Tone Ramp or regional ramp blend.
- Give the secondary ramp a clear strength and mask; do not preserve unexplained Fresnel coupling from old shaders.
- Replace KKP Rim with a compact Fresnel-based stylized rim.
- Give rim an explicit mask, shadow influence, and optional light-direction influence.
- Keep MatCap as an optional Base Pass art layer.
- Support clear MatCap Add, Multiply, and optionally Overlay semantics.
- Allow MatCap to choose geometric normal, main normal, or combined detail normal where artistically useful.
- Avoid MatCap and environment texture sampling when those features are disabled, using suitable shader variants or keywords.
- Improve the inverted-hull outline with stable screen/object-space width, depth offset, width mask, and optional smoothed-normal input.
- Finalize emission behavior, including whether a simple Keep Base Color mode is useful in the new composition.
- Define the production texture layout and channel packing.
- Define defaults that produce a usable toon material without assigning optional textures.
- Organize MaterialEditor categories and tooltips around the new semantics rather than V+ terminology.

### Feature Decisions

- `KKP Rim`: remove.
- Old `Another Ramp`: replace with a documented secondary tone system.
- Separate `Reflect` shaders: remove.
- Separate `Studio` shaders: remove.
- Legacy liquid and overtex controls: exclude from the common material model.
- MatCap: retain as a deliberately non-physical art layer.
- Outline: retain and modernize.
- Clear coat: defer unless a concrete material case demonstrates the need.

### Exit Criteria

- The shader remains recognizably toon at default settings.
- Metallic, roughness, and probe reflections add material character without washing out the toon light bands.
- Toon diffuse, stylized GGX, rim, MatCap, reflection, and emission have a documented and deterministic composition order.
- Each visible control has a clear purpose and produces a measurable visual change.
- Disabled features do not continue paying their full texture-sampling cost.
- A small reference material set demonstrates cloth, plastic, skin-like dielectric, painted metal, bare metal, and glossy stylized surfaces.
- The final property names and packed-map channel definitions are frozen for downstream variants.

### Stage Deliverable

The production visual and material specification for the X series, implemented in `tom/MainOpaqueX` and documented with reference materials and test scenes.

---

## Stage Three: Specialized Materials, Integration, and Release Hardening

### Goal

Extend the shared X-series core only where a different render state or material model is genuinely required, then validate the family for practical KKS use.

### Planned Shader Family

- `tom/MainOpaqueX`: general opaque and cutout materials.
- `tom/MainAlphaX`: semi-transparent materials with an explicitly designed depth, blending, cutoff, fog, and shadow policy.
- `tom/HairX`: two-sided hair cards, anisotropic specular, stable self-shadow behavior, and optional HairFront compatibility.
- `tom/SkinX`: skin-oriented diffuse wrap or lightweight subsurface approximation, while sharing the common light and probe systems.
- `tom/EyeX`: iris/cornea lighting and the minimum stencil compatibility needed by the game.
- Special displacement or overlay shaders only when a concrete effect requires them.

### Required Work

- Extract stable common libraries from the completed MainOpaqueX implementation.
- Keep game-specific stencil, render queue, and depth behavior in small adapter modules.
- Design transparent lighting separately rather than enabling transparency with a single blend toggle.
- Give HairX an explicit two-sided normal and two-sided shadow strategy.
- Use anisotropic GGX or another documented hair lobe instead of copying legacy Hair Gloss behavior.
- Give SkinX a restrained skin response rather than copying every SkinPlus body option.
- Keep EyeX focused on eye material behavior and required hair-front interaction.
- Add quality tiers or compile-time feature sets where they provide meaningful performance savings.
- Audit shader variant count and remove unused combinations.
- Profile Base, Add, ShadowCaster, Outline, and transparent passes on representative character scenes.
- Test directional, point, and spot lights with hard and soft shadows.
- Test no-probe, Light Probe, LPPV, Reflection Probe, lightmapped, and mixed-lighting scenes.
- Test alpha cards, mirrored meshes, negative scale, thin geometry, and overlapping hair cards.
- Build visual regression scenes and record expected screenshots/settings.
- Complete MaterialEditor categories, tooltips, example materials, asset bindings, and migration documentation.
- Backport compatible functionality to KK/Unity 5.6 after the KKS implementation is stable.

### Optional Research, Not Release Requirements

- Clear coat for wet or painted surfaces.
- Sheen for cloth.
- Improved skin scattering.
- Transmission or refraction.
- Iridescence.
- Parallax or tessellated displacement.
- Command-buffer-based contact shadows or other pipeline extensions.

These features require a demonstrated use case, acceptable performance, and a composition rule that does not destabilize the core shader.

### Exit Criteria

- Specialized shaders share the same material/light architecture and do not duplicate the full lighting implementation.
- No Reflect, Studio, TessReflect, or similar combinatorial shader explosion is introduced.
- KKS reference assets compile and render without missing properties or invalid passes.
- Performance targets and variant budgets are documented.
- Known Unity Built-in limitations are documented separately from shader defects.
- The X series has a stable public property contract and can begin normal feature maintenance rather than architectural experimentation.

### Stage Deliverable

A release-ready KKS X-series shader family, with KK-compatible subsets where practical, reference assets, documentation, and repeatable validation scenes.

---

## 4. Decision Gate Between Stages

Do not begin the next stage merely because the previous shader compiles.

- Stage One to Stage Two requires correct lighting data flow and acceptable ForwardAdd cost.
- Stage Two to Stage Three requires frozen material semantics and a stable composition order.
- New specialized shaders must consume the shared core instead of forking an unfinished prototype.
- Optional advanced effects must not delay completion of the common opaque, transparent, hair, skin, and eye use cases.

## 5. Definition of Success

The X series succeeds when it provides a recognizable Koikatsu-style toon image while behaving predictably under modern scene lighting. It should be easier to understand than V+, more consistent across light types and environments, and more selective about non-physical features.

Success is not measured by reproducing every historical xukmi option. It is measured by coherent lighting, useful art direction, maintainable code, stable performance, and material behavior that remains understandable across different scenes.
