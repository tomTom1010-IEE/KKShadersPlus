Shader "Hidden/KKP/LegacyForwardAdd"
{
	SubShader
	{
		CGINCLUDE
		#pragma only_renderers d3d11 glcore gles3 metal xboxone ps4
		#include "UnityCG.cginc"
		#include "UnityStandardUtils.cginc"
		#include "AutoLight.cginc"
		#include "Lighting.cginc"
		#define KKP_FORWARD_ADD_PASS
		ENDCG

		Pass
		{
			Name "ITEM_OPAQUE"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull [_CullOption]
			ColorMask RGB
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vert
			#pragma fragment fragAdd
			#pragma multi_compile_fwdadd_fullshadows
			#define KKP_ITEM_OPAQUE
			#include "Item/KKPItemInput.cginc"
			#include "Item/KKPItemDiffuse.cginc"
			#include "Item/KKPItemNormals.cginc"
			#include "Item/KKPItemForwardAdd.cginc"
			ENDCG
		}

		Pass
		{
			Name "ITEM_OPAQUE_ALPHA"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull [_CullOption]
			ColorMask RGB
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vert
			#pragma fragment fragAdd
			#pragma multi_compile_fwdadd_fullshadows
			#define KKP_ITEM_OPAQUE
			#define ALPHA_SHADER
			#include "Item/KKPItemInput.cginc"
			#include "Item/KKPItemDiffuse.cginc"
			#include "Item/KKPItemNormals.cginc"
			#include "Item/KKPItemForwardAdd.cginc"
			ENDCG
		}

		Pass
		{
			Name "ITEM"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull [_CullOption]
			ColorMask RGB
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vert
			#pragma fragment fragAdd
			#pragma multi_compile_fwdadd_fullshadows
			#include "Item/KKPItemInput.cginc"
			#include "Item/KKPItemDiffuse.cginc"
			#include "Item/KKPItemNormals.cginc"
			#include "Item/KKPItemForwardAdd.cginc"
			ENDCG
		}

		Pass
		{
			Name "ITEM_ALPHA"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull [_CullOption]
			ColorMask RGB
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vert
			#pragma fragment fragAdd
			#pragma multi_compile_fwdadd_fullshadows
			#define ALPHA_SHADER
			#include "Item/KKPItemInput.cginc"
			#include "Item/KKPItemDiffuse.cginc"
			#include "Item/KKPItemNormals.cginc"
			#include "Item/KKPItemForwardAdd.cginc"
			ENDCG
		}

		Pass
		{
			Name "ITEM_STUDIO"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull [_CullOption]
			ColorMask RGB
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vert
			#pragma fragment fragAdd
			#pragma multi_compile_fwdadd_fullshadows
			#define STUDIO_SHADER
			#include "Item/KKPItemInput.cginc"
			#include "Item/KKPItemDiffuse.cginc"
			#include "Item/KKPItemNormals.cginc"
			#include "Item/KKPItemForwardAdd.cginc"
			ENDCG
		}

		Pass
		{
			Name "ITEM_STUDIO_ALPHA"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull [_CullOption]
			ColorMask RGB
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vert
			#pragma fragment fragAdd
			#pragma multi_compile_fwdadd_fullshadows
			#define STUDIO_SHADER
			#define ALPHA_SHADER
			#include "Item/KKPItemInput.cginc"
			#include "Item/KKPItemDiffuse.cginc"
			#include "Item/KKPItemNormals.cginc"
			#include "Item/KKPItemForwardAdd.cginc"
			ENDCG
		}

		Pass
		{
			Name "ITEM_OPAQUE_TESS"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull [_CullOption]
			ColorMask RGB
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex TessVert
			#pragma fragment fragAdd
			#pragma hull hull
			#pragma domain domain
			#pragma multi_compile_fwdadd_fullshadows
			#define KKP_ITEM_OPAQUE
			#define TESS_SHADER
			#include "Item/KKPItemInput.cginc"
			#include "KKPDisplace.cginc"
			#include "Item/KKPItemDiffuse.cginc"
			#include "Item/KKPItemNormals.cginc"
			#include "Item/KKPItemForwardAdd.cginc"
			#include "Item/KKPItemTess.cginc"
			ENDCG
		}

		Pass
		{
			Name "ITEM_OPAQUE_ALPHA_TESS"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull [_CullOption]
			ColorMask RGB
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex TessVert
			#pragma fragment fragAdd
			#pragma hull hull
			#pragma domain domain
			#pragma multi_compile_fwdadd_fullshadows
			#define KKP_ITEM_OPAQUE
			#define ALPHA_SHADER
			#define TESS_SHADER
			#include "Item/KKPItemInput.cginc"
			#include "KKPDisplace.cginc"
			#include "Item/KKPItemDiffuse.cginc"
			#include "Item/KKPItemNormals.cginc"
			#include "Item/KKPItemForwardAdd.cginc"
			#include "Item/KKPItemTess.cginc"
			ENDCG
		}

		Pass
		{
			Name "ITEM_TESS"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull [_CullOption]
			ColorMask RGB
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex TessVert
			#pragma fragment fragAdd
			#pragma hull hull
			#pragma domain domain
			#pragma multi_compile_fwdadd_fullshadows
			#define TESS_SHADER
			#include "Item/KKPItemInput.cginc"
			#include "KKPDisplace.cginc"
			#include "Item/KKPItemDiffuse.cginc"
			#include "Item/KKPItemNormals.cginc"
			#include "Item/KKPItemForwardAdd.cginc"
			#include "Item/KKPItemTess.cginc"
			ENDCG
		}

		Pass
		{
			Name "ITEM_ALPHA_TESS"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull [_CullOption]
			ColorMask RGB
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex TessVert
			#pragma fragment fragAdd
			#pragma hull hull
			#pragma domain domain
			#pragma multi_compile_fwdadd_fullshadows
			#define ALPHA_SHADER
			#define TESS_SHADER
			#include "Item/KKPItemInput.cginc"
			#include "KKPDisplace.cginc"
			#include "Item/KKPItemDiffuse.cginc"
			#include "Item/KKPItemNormals.cginc"
			#include "Item/KKPItemForwardAdd.cginc"
			#include "Item/KKPItemTess.cginc"
			ENDCG
		}

		Pass
		{
			Name "ITEM_STUDIO_TESS"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull [_CullOption]
			ColorMask RGB
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex TessVert
			#pragma fragment fragAdd
			#pragma hull hull
			#pragma domain domain
			#pragma multi_compile_fwdadd_fullshadows
			#define STUDIO_SHADER
			#define TESS_SHADER
			#include "Item/KKPItemInput.cginc"
			#include "KKPDisplace.cginc"
			#include "Item/KKPItemDiffuse.cginc"
			#include "Item/KKPItemNormals.cginc"
			#include "Item/KKPItemForwardAdd.cginc"
			#include "Item/KKPItemTess.cginc"
			ENDCG
		}

		Pass
		{
			Name "ITEM_STUDIO_ALPHA_TESS"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull [_CullOption]
			ColorMask RGB
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex TessVert
			#pragma fragment fragAdd
			#pragma hull hull
			#pragma domain domain
			#pragma multi_compile_fwdadd_fullshadows
			#define STUDIO_SHADER
			#define ALPHA_SHADER
			#define TESS_SHADER
			#include "Item/KKPItemInput.cginc"
			#include "KKPDisplace.cginc"
			#include "Item/KKPItemDiffuse.cginc"
			#include "Item/KKPItemNormals.cginc"
			#include "Item/KKPItemForwardAdd.cginc"
			#include "Item/KKPItemTess.cginc"
			ENDCG
		}

		Pass
		{
			Name "HAIR"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull [_CullOption]
			ColorMask RGB
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vert
			#pragma fragment fragAdd
			#pragma multi_compile_fwdadd_fullshadows
			#include "Hair/KKPHairInput.cginc"
			#include "Hair/KKPHairDiffuse.cginc"
			#include "Hair/KKPHairNormals.cginc"
			#include "Hair/KKPHairForwardAdd.cginc"
			ENDCG
		}

		Pass
		{
			Name "HAIR_TESS"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull [_CullOption]
			ColorMask RGB
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex TessVert
			#pragma fragment fragAdd
			#pragma hull hull
			#pragma domain domain
			#pragma multi_compile_fwdadd_fullshadows
			#define TESS_SHADER
			#include "Hair/KKPHairInput.cginc"
			#include "KKPDisplace.cginc"
			#include "Hair/KKPHairDiffuse.cginc"
			#include "Hair/KKPHairNormals.cginc"
			#include "Hair/KKPHairForwardAdd.cginc"
			#include "Hair/KKPHairTess.cginc"
			ENDCG
		}

		Pass
		{
			Name "HAIR_FRONT_OUTSIDE"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull [_CullOption]
			ColorMask RGB
			Stencil { Ref 2 Comp NotEqual Pass Keep }
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vert
			#pragma fragment fragAdd
			#pragma multi_compile_fwdadd_fullshadows
			#include "Hair/KKPHairInput.cginc"
			#include "Hair/KKPHairDiffuse.cginc"
			#include "Hair/KKPHairNormals.cginc"
			#include "Hair/KKPHairForwardAdd.cginc"
			ENDCG
		}

		Pass
		{
			Name "HAIR_FRONT_INSIDE"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull Back
			ColorMask RGB
			Stencil { Ref 2 Comp Equal Pass Keep }
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vert
			#pragma fragment fragAdd
			#pragma multi_compile_fwdadd_fullshadows
			#define HAIR_FRONT_INSIDE
			#include "Hair/KKPHairInput.cginc"
			#include "Hair/KKPHairDiffuse.cginc"
			#include "Hair/KKPHairNormals.cginc"
			#include "Hair/KKPHairForwardAdd.cginc"
			ENDCG
		}

		Pass
		{
			Name "HAIR_FRONT_OUTSIDE_TESS"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull [_CullOption]
			ColorMask RGB
			Stencil { Ref 2 Comp NotEqual Pass Keep }
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex TessVert
			#pragma fragment fragAdd
			#pragma hull hull
			#pragma domain domain
			#pragma multi_compile_fwdadd_fullshadows
			#define TESS_SHADER
			#include "Hair/KKPHairInput.cginc"
			#include "KKPDisplace.cginc"
			#include "Hair/KKPHairDiffuse.cginc"
			#include "Hair/KKPHairNormals.cginc"
			#include "Hair/KKPHairForwardAdd.cginc"
			#include "Hair/KKPHairTess.cginc"
			ENDCG
		}

		Pass
		{
			Name "HAIR_FRONT_INSIDE_TESS"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull Back
			ColorMask RGB
			Stencil { Ref 2 Comp Equal Pass Keep }
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex TessVert
			#pragma fragment fragAdd
			#pragma hull hull
			#pragma domain domain
			#pragma multi_compile_fwdadd_fullshadows
			#define TESS_SHADER
			#define HAIR_FRONT_INSIDE
			#include "Hair/KKPHairInput.cginc"
			#include "KKPDisplace.cginc"
			#include "Hair/KKPHairDiffuse.cginc"
			#include "Hair/KKPHairNormals.cginc"
			#include "Hair/KKPHairForwardAdd.cginc"
			#include "Hair/KKPHairTess.cginc"
			ENDCG
		}

		Pass
		{
			Name "SKIN"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull Off
			ColorMask RGB
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vert
			#pragma fragment fragAdd
			#pragma multi_compile_fwdadd_fullshadows
			#include "Skin/KKPSkinInput.cginc"
			#include "Skin/KKPDiffuse.cginc"
			#include "Skin/KKPNormals.cginc"
			#include "Skin/KKPSkinForwardAdd.cginc"
			ENDCG
		}

		Pass
		{
			Name "SKIN_ALPHA"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull [_CullOption]
			ColorMask RGB
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vert
			#pragma fragment fragAdd
			#pragma multi_compile_fwdadd_fullshadows
			#define SKIN_MAIN_ALPHA_CLIP
			#define SKIN_ALPHA_BLEND
			#include "Skin/KKPSkinInput.cginc"
			#include "Skin/KKPDiffuse.cginc"
			#include "Skin/KKPNormals.cginc"
			#include "Skin/KKPSkinForwardAdd.cginc"
			ENDCG
		}

		Pass
		{
			Name "SKIN_TESS"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull Off
			ColorMask RGB
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex TessVert
			#pragma fragment fragAdd
			#pragma hull hull
			#pragma domain domain
			#pragma multi_compile_fwdadd_fullshadows
			#define TESS_SHADER
			#include "Skin/KKPSkinInput.cginc"
			#include "KKPDisplace.cginc"
			#include "Skin/KKPDiffuse.cginc"
			#include "Skin/KKPNormals.cginc"
			#include "Skin/KKPSkinForwardAdd.cginc"
			#include "Skin/KKPTess.cginc"
			ENDCG
		}

		Pass
		{
			Name "SKIN_ALPHA_TESS"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull [_CullOption]
			ColorMask RGB
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex TessVert
			#pragma fragment fragAdd
			#pragma hull hull
			#pragma domain domain
			#pragma multi_compile_fwdadd_fullshadows
			#define TESS_SHADER
			#define SKIN_MAIN_ALPHA_CLIP
			#define SKIN_ALPHA_BLEND
			#include "Skin/KKPSkinInput.cginc"
			#include "KKPDisplace.cginc"
			#include "Skin/KKPDiffuse.cginc"
			#include "Skin/KKPNormals.cginc"
			#include "Skin/KKPSkinForwardAdd.cginc"
			#include "Skin/KKPTess.cginc"
			ENDCG
		}

		Pass
		{
			Name "EYE"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull Back
			ColorMask RGB
			Stencil { Ref 2 Comp Equal Pass Keep }
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vert
			#pragma fragment fragAdd
			#pragma multi_compile_fwdadd_fullshadows
			#include "Eye/KKPEyeInput.cginc"
			#include "Eye/KKPEyeDiffuse.cginc"
			#include "Eye/KKPEyeForwardAdd.cginc"
			ENDCG
		}

		Pass
		{
			Name "EYE_ALPHA"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull Back
			ColorMask RGB
			Stencil { Ref 2 Comp Equal Pass Keep }
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vert
			#pragma fragment fragAdd
			#pragma multi_compile_fwdadd_fullshadows
			#define KKP_EYE_ALPHA_CUTOFF
			#include "Eye/KKPEyeInput.cginc"
			#include "Eye/KKPEyeDiffuse.cginc"
			#include "Eye/KKPEyeForwardAdd.cginc"
			ENDCG
		}

		Pass
		{
			Name "EYE_W"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull Back
			ColorMask RGB
			Stencil { Ref 2 Comp Equal Pass Keep }
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vert
			#pragma fragment fragAdd
			#pragma multi_compile_fwdadd_fullshadows
			#define KKP_EYE_W
			#include "Eye/KKPEyeInput.cginc"
			#include "Eye/KKPEyeDiffuse.cginc"
			#include "Eye/KKPEyeForwardAdd.cginc"
			ENDCG
		}

		Pass
		{
			Name "EYE_W_ALPHA"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull Back
			ColorMask RGB
			Stencil { Ref 2 Comp Equal Pass Keep }
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vert
			#pragma fragment fragAdd
			#pragma multi_compile_fwdadd_fullshadows
			#define KKP_EYE_W
			#define KKP_EYE_ALPHA_CUTOFF
			#include "Eye/KKPEyeInput.cginc"
			#include "Eye/KKPEyeDiffuse.cginc"
			#include "Eye/KKPEyeForwardAdd.cginc"
			ENDCG
		}

		Pass
		{
			Name "EYE_TESS"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull Back
			ColorMask RGB
			Stencil { Ref 2 Comp Equal Pass Keep }
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex TessVert
			#pragma fragment fragAdd
			#pragma hull hull
			#pragma domain domain
			#pragma multi_compile_fwdadd_fullshadows
			#define TESS_SHADER
			#include "Eye/KKPEyeInput.cginc"
			#include "KKPDisplace.cginc"
			#include "Eye/KKPEyeDiffuse.cginc"
			#include "Eye/KKPEyeForwardAdd.cginc"
			#include "Eye/KKPEyeTess.cginc"
			ENDCG
		}

		Pass
		{
			Name "EYE_W_TESS"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ZWrite Off
			Cull Back
			ColorMask RGB
			Stencil { Ref 2 Comp Equal Pass Keep }
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex TessVert
			#pragma fragment fragAdd
			#pragma hull hull
			#pragma domain domain
			#pragma multi_compile_fwdadd_fullshadows
			#define KKP_EYE_W
			#define TESS_SHADER
			#include "Eye/KKPEyeInput.cginc"
			#include "KKPDisplace.cginc"
			#include "Eye/KKPEyeDiffuse.cginc"
			#include "Eye/KKPEyeForwardAdd.cginc"
			#include "Eye/KKPEyeTess.cginc"
			ENDCG
		}
	}
	Fallback Off
}
