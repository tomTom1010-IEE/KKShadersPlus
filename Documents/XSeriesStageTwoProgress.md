# X Series Stage Two Progress

## Scope and Status

KKS only, Unity 2019.4 Built-in Forward, tom/MainOpaqueX.
Stage Two was accepted by the user and closed on 2026-10-02 after scoped Bridge
render regression. See XSeriesStageTwoClosure.md for the authoritative current status.
No KK synchronization or V+ redesign.
Unity native assets must be created by CodexBridge, not serialized by external tools.

## 2026-09-20 Implementation Checkpoint

- The working shader separates optional physical diffuse suppression from specular style.
- Procedural Toon transfer, secondary tone mask, indirect tone controls, stylized direct GGX,
  environment bright-region selection, layer masks and debug views are implemented provisionally.
- MatCap Multiply affects diffuse in Base and Add; additive MatCap is Base-only.
- Rim width/softness and light influence replace the old power-only interface.
- Outline supports a width mask and optional UV4 object-space smooth normals.
- Shader and manifest expose 98 matching property names. The old SpecularPower,
  GGXSpecularBlend and RimPower declarations were removed from this X prototype.
- MaterialEditor categories distinguish Toon Shading, Material, Direct Specular,
  Environment Reflection, MatCap, Rim, Outline, Emission and Debug.

## Automated Evidence

- manifest.xml XML parsing passed; X asset binding remains a_TomMainOpaqueX.
- CodexBridge refresh succeeded.
- validatexstage2 warmed 13 selected variants: five ForwardBase, six ForwardAdd,
  and two ShadowCaster variants. Shader reports supported.
- Initial compilation reported three potentially-uninitialized-result warnings.
  Explicitly initialized layer results with single returns removed these warnings.
- CodexBridge/Outbox/xstage2-validation-002.result.json reports success with no
  shader messages. This checks selected variants only, not exhaustive coverage.
- Refresh also reports unrelated duplicate AssetBundle Browser package GUIDs and
  legacy Shader Forge binary warnings. These have not been changed or claimed fixed.

## Handoff Acceptance List (Historical, 2026-09-20)

- Execute T01-T15 in XSeriesStageTwoAcceptance.md, including in-game tooltip display.
- Verify GPU cost, temporal anti-aliasing behavior and actual KKS probe appearance.
- Visual and performance acceptance remains pending; no automated visual inspection,
  screenshot rendering or computer-use operation was performed.
- Fix any defects exposed by those tests before freezing the material contract.

## Texture Contracts (Frozen at 2026-10-02 Closure)

- MainTex RGB: base color; A multiplied by AlphaMask R for cutoff.
- MaterialMap, when enabled: R metallic, G roughness, B AO, A direct specular mask.
  Metallic and roughness multiply their scalar controls; roughness also has bias.
- LayerMask: R secondary tone, G Rim, B MatCap, A environment reflection.
- ReflectionMask R: shared reflection-region mask, multiplied by the corresponding
  LayerMask channel.
- RampTex and SecondaryRamp: R transfer value, sampled horizontally at V=0.5.
- OutlineWidthMask R: outline width multiplier.
- Optional smooth outline normals: UV4.xyz, raw object-space vector; zero falls
  back to the mesh normal. Not octahedral or color-encoded.
- Data masks and roughness/metallic textures must be imported as linear data.
  Normal maps follow Unity normal-map import/decode, not raw color sampling.

The property contract below was provisional at handoff and is now frozen with
Tests/MainOpaqueX-StageTwo.properties.txt. This does not supersede Stage One evidence.

## Tooltip and Reference Asset Checkpoint

- Tooltips/tom_x_tooltips.xml contains 98 X-specific property tips; XML property
  coverage matches the manifest. The catalog is referenced by the manifest.
- CodexBridge xstage2-tooltip-002-bind successfully assigned the catalog to
  chara/xukmi/shaders/vanillaplus.unity3d.
- CodexBridge xstage2-scenes-create-001 successfully generated
  Assets/TomXStageTwoAcceptance with EnvironmentOnly, SingleLight and MultiLight
  scenes, six material types and seven debug-view materials.
- A synthetic HDR cubemap supplies structured bright regions without capturing
  or rendering the scene. Its generated mip chain is a diagnostic texture, not
  a substitute for Unity's production GGX-prefiltered reflection-probe bake.
- The creation helper restored the previous active scene and closed generated
  scenes. No camera Render call, screenshot or visual acceptance was performed.
- Reference materials are intentionally outside the mod bundle and are not
  assigned shipping AssetBundle names.
- finishxstage2references supplied nonzero MatCap, Rim and emission inputs and
  inspected all three saved scenes: 0/1/3 lights, 13/14/14 X renderers, one camera
  each and a non-null environment cubemap.

## Final Code Handoff Audit (Historical, 2026-09-20)

| Requirement | Implementation evidence | Automated evidence / remaining boundary |
| --- | --- | --- |
| Body/Fresnel independence | TomDiffuseWeight; DiffuseEnergyBlend defaults to zero | Static contract and CPU algebra checks passed; T01/T02 visual gate |
| Controlled environment layer | TomShapeEnvironment and TomEnvironmentLayer; separate mask, tint, Fresnel and selection | Compiled selected variants; T03/T04/T14 visual gate |
| Material versus artistic controls | Physical Roughness/IOR/Metallic retained; independent SpecularSize and softness | 98-property parity and complete tooltip coverage; controls documented |
| Stylized direct GGX | Normalized GGX NDF; threshold/bands; radiance applied afterward; horizon/shadow guards and AA | CPU normalized-lobe finite/range checks; T05-T08 GPU appearance pending |
| Toon and multi-light body | Procedural/texture/secondary ramp, indirect shaping, shared direct evaluator | Pass ownership assertions; T09/T10 visual accumulation tests pending |
| Art layer composition | Diffuse-only Multiply in Base/Add; additive layers Base-only | Static Add checks and supplied debug materials; T11/T12 pending |
| Outline and interaction | Width mask, UV4 normals, 98 categorized properties and scoped catalog | XML parity, catalog bundle binding; T13/T15 pending |
| Reference acceptance setup | EnvironmentOnly/SingleLight/MultiLight with shared reference and debug materials | Bridge scene inspection passed without rendering |

- Tests/Test-XStageTwo.ps1 passes all current assertions and 36 CPU algebra samples.
- CodexBridge/Outbox/xstage2-final-validate.result.json: 13 requested variants warmed,
  shader supported, no reported shader messages after final source changes.
- Safe direction normalization now handles a zero main-light vector in no-light scenes.
- git diff --check passes (line-ending conversion notices only).
- Shared KKPPBRBRDF and KK parallel project were not edited by this stage.
- No bundle build, in-game deployment, commit or push was performed.
- No claim of exhaustive variant, GPU numerical, timing or visual verification is made.
