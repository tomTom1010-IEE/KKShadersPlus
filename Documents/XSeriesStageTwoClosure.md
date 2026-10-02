# Stage Two Closure - 2026-10-02

## Decision

Stage Two is closed as the accepted KKS Toon material baseline. The user explicitly
accepted both reference-scene appearance and packaged in-game appearance on 2026-10-02.
This is not a claim that every historical Stage One performance/bake gate passed.
No additional material features or shader formula changes were required for closure.

The follow-up permission explicitly authorized CodexBridge rendering and inspection.
No computer-use tools were used. Previous documents saying visual inspection was
user-only describe the 2026-09-20 handoff, not this closure regression.

## Frozen Interface

The 98 property names, types, ranges, labels and defaults are captured in
Tests/MainOpaqueX-StageTwo.properties.txt and checked by Test-XStageTwo.ps1.
Packed texture channels and layer composition in XSeriesStageTwoAcceptance.md are
the Stage Two contract. Later incompatible changes require a documented migration
and explicit contract version change. Do not silently repurpose a texture channel.

Default body diffuse remains independent of IOR/Fresnel; Metallic still removes
diffuse. Continuous GGX and artistic GGX shape remain separate controls.
No new Reflect/Studio variants are planned for this shared material.

## Bridge Regression Evidence

Editor/TomXStageTwoClosure.cs renders a transient isolated scene via Camera.Render,
reads float HDR pixels and exports PNG previews. It restores the active scene,
light culling masks, quality settings and render target in a finally block.
Existing materials and scenes are not saved or edited.

Environment: Unity 2019.4.9f1, D3D11, Gamma, RTX 4070 Ti SUPER, 384x384,
8 pixel lights, High shadow resolution. Four warmup renders precede nine timed
renders per case. Timing is CPU Camera.Render wall time, not GPU frame time.

Evidence: [report](Evidence/StageTwo-20261002/report.json) and
[contact sheet](Evidence/StageTwo-20261002/contact-sheet.png).
The sheet is row-major: captures 01-21, four columns; final unused cells are blank.
Raw individual PNGs also remain in the project CodexBridge/Reports folder.

| Check | Result |
| --- | --- |
| 01/02 default body under changed IOR/Fresnel/roughness | Maximum HDR RGB difference 0 |
| 05/06 light intensity doubled | Difference from exactly doubled direct specular 0 |
| 07/08 MatCap Multiply, main plus four shadowed point lights | Difference from expected half-intensity body 0 |
| 15/16 point shadow receiver | Mean red-channel difference 0.00772055; occluder shadow clearly visible |
| 17-21 front/back card culling | Culled front view has zero lit pixels; visible front/back cases have 75,076 each |
| All 21 captures | No NaN/Inf reported in RGB readback |

Visual inspection of Bridge PNGs found:

- Environment bright-region selection removes broad low-level reflection while
  retaining local features in the diagnostic environment.
- Thin card receives a coherent point-light shadow, absent when shadows are off.
- Cyan diagnostic Outline stays continuous on nonuniform scales with zero, one
  and two negative axes. Mirrored mesh triangulation can change interior shading
  slightly; identical per-pixel interior color is not claimed.
- Low roughness/high-frequency normals remain finite. Strong AA broadens highlights
  and visibly increases coverage; it trades sharpness for filtering. Two nearby
  views were inspected, not an exhaustive temporal sequence.
- The stylized multi-light pattern remains additive rather than normalized. This
  is expected material behavior, not proof of unlimited-light brightness stability.

## Limits and Follow-Up

- This small render smoke test does not certify production GPU cost. Its CPU
  timings are diagnostic only; full GPU profiling belongs to Stage Three hardening.
- Extreme grazing angles, complex production hair/skin meshes, temporal motion,
  all bake modes, all shader variants and platforms are not exhaustively tested.
- The synthetic cube has ordinary mips. Real KKS probe appearance is supported by
  the user's in-game acceptance, not by claiming it was GGX-prefiltered here.
- ME tooltip display was not separately confirmed by the user; XML coverage and
  bundle binding are checked. Keep UI verification in the release checklist.
- Existing AssetBundle Browser duplicate-GUID project warnings are unrelated.

These are recorded release-hardening tasks, not hidden claims of passing tests.

## Reproduction and Asset Archive

Tests/XStageTwoReferences.unitypackage is exported by Unity AssetDatabase and
contains the three scenes, materials, textures and GUID metadata originally
outside this Git repository. Import it alongside this repository in KKS Unity 2019.
It restores Assets/TomXStageTwoAcceptance; existing same-GUID assets may be updated
by import, so use a clean project for reproduction. The shader dependency is in
this repository, not duplicated in the package.

For a fresh project with CodexBridge already installed:

1. Run Tests/Install-XStageTwoBridge.ps1 with -UnityProject pointing at that project.
2. Refresh Unity and wait for its compiler to finish.
3. Send {"operation":"validatexstage2"} through CodexBridge/Inbox.
4. Send {"operation":"renderxstage2closure"} and read the returned report location.

The archive command is {"operation":"archivexstage2references"}. It is separate
from rendering. No shipping AssetBundle was rebuilt during closure.

## Next Stage

Begin MainAlphaX after preserving this baseline. Reuse the material/light modules
without changing opaque appearance. Design alpha blending, depth, cutoff, shadow
and reflection opacity together; do not reduce transparency to a Blend-state edit.
HairX, SkinX and EyeX follow only after that shared foundation is stable.
