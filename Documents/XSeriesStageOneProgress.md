# X Series Stage One Progress Record

Last updated: 2026-08-24

## Status Summary

- Scope: KKS, Unity 2019.4.9f1, Built-in Forward, `tom/MainOpaqueX` only.
- Source scope: KKS X-series Stage One implementation and its manifest declarations; Skin-series work is tracked separately.
- Overall state: implementation complete; manual scene, bake, and performance acceptance pending.
- Code gate: PASS.
- Manual lighting/material gate: NOT RUN.
- Manual geometry/shadow gate: NOT RUN.
- GI/probe integration gate: NOT RUN; placeable SH provider evidence is owned by the independent probe track.
- Performance gate: NOT RUN.
- Stage decision: Stage One is not yet accepted, and Stage Two production semantics should not be frozen until the open gates are recorded.
- Static audit decision: no known Stage One code item remains deliberately unimplemented in this repository. A failed gate may reopen implementation work.

## Completed Implementation

| Area | Recorded result |
| --- | --- |
| Direct-light architecture | Shared material/raw-light/surface-term/result data; ForwardBase and ForwardAdd both use `TomBuildRawLightData`, `TomBuildSurfaceLightTerms`, and the common direct evaluator |
| Additional lights | Full-shadow ForwardAdd; Base-only IBL, MatCap, rim, emission, and indirect lighting excluded |
| Light visibility | Distance, cookie, sampled shadow, mixed physical shadow, and artistic shadow shaping kept separate |
| Production specular | `_GGXSpecularBlend = 1` uses Unity-compatible GGX, Smith joint visibility, Schlick Fresnel, F0/IOR, roughness, metallic, and diffuse energy suppression |
| Compatibility specular | Blend 0 retains Legacy Blinn; intermediate blend is explicitly experimental and not energy-conserving |
| Indirect lighting | Native SH/LPPV receiver, static/dynamic and directional lightmaps, Mixed Lighting ownership, Reflection Probe IBL, and indirect-only AO |
| Vertex lights | Separate geometry-normal diffuse fill with default intensity 0.5 and no shadow/specular/ramp/cookie path |
| Geometry policy | Explicit Cull Back/Front/Off body and shadow behavior, double-sided normal-bias disable, manual ShadowCaster face culling, and negative-scale-aware TBN/Outline handling |
| Platform plumbing | Fog, GPU instancing, stereo transfer, alpha cutoff parity, and material-controlled shadow raster Offset |

## Automated Evidence

| Check | Result | Evidence |
| --- | --- | --- |
| Unity import | PASS | Final forced CodexBridge refresh produced no `tom/MainOpaqueX`, `TomToonLighting`, or `TomToonBRDF` shader error/warning |
| Manifest XML | PASS | XML parser accepted `manifest.xml` |
| Property contract | PASS | 65 shader properties match 65 manifest properties |
| Shadow policy source | PASS | ShadowCaster uses `Cull Off`, manual `VFACE`, single-sided Normal Bias, double-sided legacy/no-normal-offset transfer, and default raster Offset 0 |
| GGX isolation | PASS | Production implementation is in `TomToonBRDF.cginc`; shared `KKPPBRBRDF.cginc` is unchanged |
| ForwardAdd ownership | PASS, static | Direct path samples seven material textures plus the ramp and contains no Base-only layer composition |
| Raw/surface light separation | PASS | Raw light construction has no material dependency; Base and Add derive their own `TomSurfaceLightTerms`; Unity refresh produced no relevant shader error/warning |
| Acceptance specification | PASS | Roadmap defines 20 test IDs, a controlled capture setup, numeric tolerances, and explicit exit gates |
| Project baseline | PASS | Project uses Built-in Forward; `Fantastic` has Pixel Light Count 4, four cascades, 150 m shadow distance, and realtime Reflection Probes enabled |

Existing AssetBundleBrowser package GUID conflicts and legacy binary-shader warnings remain unrelated project noise and are not X-series failures.

## Open Acceptance Results

Use the setup, IDs, and pass metrics in `XSeriesDevelopmentRoadmap.md`.

| Gate | Test IDs | Current result | Tester notes |
| --- | --- | --- | --- |
| Compile and contract | C01 | PASS | Automated on 2026-08-24 |
| Direct and additional lights | L01-L04 | NOT RUN | |
| Vertex-light positioning | V01 | NOT RUN | |
| Lightmap, Mixed Lighting, AO, and SH/LPPV | G01-G03 | NOT RUN | G03 may attach probe-track evidence |
| Reflection Probes | R01 | NOT RUN | |
| Fog | F01 | NOT RUN | |
| GPU instancing | I01 | NOT RUN | |
| Thin geometry, culling, negative scale, and cutoff | S01-S03 | NOT RUN | |
| Production GGX and compatibility | B01-B03 | NOT RUN | |
| Draw/sample and GPU cost | P01-P02 | NOT RUN | |

## Test Run Template

- Date:
- Tester:
- KKS build/mod set:
- GPU and driver:
- Resolution and quality level:
- Pixel Light Count, shadow distance/resolution/cascades:
- Post-processing/exposure state:
- Scene/material revision:
- Light type, Render Mode, cookie state, and shadow state:
- Lightmap/Mixed Lighting/probe configuration:
- Failed test IDs:
- Screenshots, Frame Debugger captures, or profiler evidence:
- Warm-up/sample count and median/P95 GPU frame time:
- Decision: PASS / FAIL / RETEST
- Notes:

## Recommended Test Order

1. Run C01, L01-L04, and B01-B03 first. These validate the shared direct-light and BRDF contract before scene integration adds more variables.
2. Run S01-S03 with the same direct-light scene, then repeat with negative scale and thin cards.
3. Run V01, G01-G03, R01, F01, and I01 with their required project and bake configurations.
4. Run P01-P02 last on the accepted visual configuration, because failed lighting tests can invalidate performance captures.

## Closure Rule

Stage One can be marked accepted after all non-external test IDs pass, G03 evidence is linked from the probe track, and no unresolved defect changes the shared material/light contract. A documented engine limitation may be accepted only when its reproduction, impact, and workaround are recorded here.
