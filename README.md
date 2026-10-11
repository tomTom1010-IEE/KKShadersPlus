# KKShadersPlus
Recreated Koikatsu shaders with more features 

## V+ LTS 1.7.6

- Fix ForwardAdd pass ordering so base passes no longer overwrite added lights.
- Keep four-light array lighting alongside per-pixel lights.
- Treat UseForwardAddFullShadows as a shadow toggle; additional pixel lights
  remain active when it is off, with distance/cookie attenuation preserved.
- Apply final attenuation after toon ramp evaluation to prevent light leakage.
- Add SkinMaskedAlphaTwoPass with an independent TransparencyMask and smooth
  MaskedTransparency control; retain the existing body/clothing AlphaMask.
- Extract standalone X and TomBSDF shaders into independent sibling projects.
  Existing Blend and overlay shaders remain in V+.

Turning off additional-light shadows is a shader-only compatibility mode, not
an exact reproduction of old Unity light allocation. Upgrade by replacing the
old V+ zipmod, not by installing both versions. Materials using standalone X or
TomBSDF shaders require their separate packages, which are not bundled here.

## V+ LTS and X Series

This repository retains the xukmi/V+ LTS shaders and existing experimental Blend
and overlay shaders. TomBSDFBase, TomBSDF and TomBSDFAlpha have moved to the
independent TomShadersBSDF sibling project, with their own manifest and bundle.
The tom/MainOpaqueX, tom/MainAlphaX and tom/MainAlphaX2Pass family is maintained
in the independent TomShadersX sibling project.

V+ keeps manifest GUID xukmi.Shaders.VanillaPlus and bundle
chara/xukmi/shaders/vanillaplus.unity3d. Its KKPDeclarations.cginc stays local and
unchanged; X has a separate copy. Do not add an include dependency between them.
The BRDF and four-light libraries used by MainOpaqueBlend and overlays also
stay local; BSDF has independent copies. Build the projects separately.
Previously built combined bundles are not updated by this source migration.
Replace those builds before co-installing standalone X or BSDF packages.

# KKShadersPlus Tom's fork
Recreated KKShadersPlus with additional features and small fix

## Features 

- Additional Front hair shader with forced depth calculation: HairFrontPlusDOF
   - HairFrontPlusDepthOnly shader if you use hair shader other than Xukmi's
- Improved matcap, with blur feature similar to KKUTS
  
## FAQs
- About shadows
   - Issues concerning shadow color
