Shader "xukmi/SkinMaskedAlphaTwoPass"
{
	Properties
	{
		_ColMask ("Color Mask", 2D) = "black" {}
		[Gamma]_Col0 ("Color 0", Color) = (1, 1, 1, 1)
		[Gamma]_Col1 ("Color 1", Color) = (1, 1, 1, 1)
		[Gamma]_Col2 ("Color 2", Color) = (1, 1, 1, 1)
		[Gamma]_Col3 ("Color 3", Color) = (1, 1, 1, 1)

		_MainTex ("MainTex", 2D) = "white" {}
		[Gamma]_overcolor1 ("Over Color1", Vector) = (1,1,1,1)
		_overtex1 ("Over Tex1", 2D) = "black" {}
		[Gamma]_overcolor2 ("Over Color2", Vector) = (1,1,1,1)
		_overtex2 ("Over Tex2", 2D) = "black" {}
		[Gamma]_overcolor3 ("Over Color3", Vector) = (1,1,1,1)
		_overtex3 ("Over Tex3", 2D) = "black" {}
		_NormalMap ("Normal Map", 2D) = "bump" {}
		_NormalMapDetail ("Normal Map Detail", 2D) = "bump" {}
		_DetailMask ("Detail Mask", 2D) = "black" {}
		_LineMask ("Line Mask", 2D) = "black" {}
		_AlphaMask ("Alpha Mask", 2D) = "white" {}
		_TransparencyMask ("Independent Transparency Mask", 2D) = "black" {}
		_EmissionMask ("Emission Mask", 2D) = "black" {}
		[Gamma]_EmissionColor("Emission Color", Color) = (1, 1, 1, 1)
		_EmissionIntensity("Emission Intensity", Float) = 1
		_EmissionMaskMode("Emission Mask Mode", Float) = 0
		_EmissionKeepCol("Emission Keep Base Color", Float) = 0
		[Gamma]_ShadowColor ("Shadow Color", Color) = (0.628,0.628,0.628,1)
		_ShadowHSV ("Shadow HSV", Vector) = (0, 0, 0, 0)
		[Gamma]_SpecularColor ("Specular Color", Vector) = (1,1,1,0)
		_DetailNormalMapScale ("DetailNormalMapScale", Range(0, 1)) = 1
		_NormalMapScale ("NormalMapScale", Float) = 1
		_SpeclarHeight ("Speclar Height", Range(0, 1)) = 0.98
		_SpecularPower ("Specular Power", Range(0, 1)) = 0
		_SpecularPowerNail ("Specular Power Nail", Range(0, 1)) = 0
		_ShadowExtend ("Shadow Extend", Range(0, 1)) = 1
		_rimpower ("Rim Width", Range(0, 1)) = 0.5
		_rimV ("Rim Strength", Range(0, 1)) = 0
		_nipsize ("nipsize", Range(0, 1)) = 0.5
		[MaterialToggle] _alpha_a ("alpha_a", Float) = 1
		[MaterialToggle] _alpha_b ("alpha_b", Float) = 1
		[MaterialToggle] _linetexon ("Line Tex On", Float) = 1
		[MaterialToggle] _notusetexspecular ("not use tex specular", Float) = 0
		[MaterialToggle] _nip ("nip?", Float) = 0
		_liquidmask ("Liquid Mask", 2D) = "black" {}
		_Texture2 ("Liquid Tex", 2D) = "black" {}
		_Texture3 ("Liquid Normal", 2D) = "bump" {}
		_LiquidTiling ("Liquid Tiling (u/v/us/vs)", Vector) = (0,0,2,2)
		_liquidftop ("liquidftop", Range(0, 2)) = 0
		_liquidfbot ("liquidfbot", Range(0, 2)) = 0
		_liquidbtop ("liquidbtop", Range(0, 2)) = 0
		_liquidbbot ("liquidbbot", Range(0, 2)) = 0
		_liquidface ("liquidface", Range(0, 2)) = 0
		_nip_specular ("nip_specular", Range(0, 1)) = 0.5
		_tex1mask ("tex1 mask(1=yes)", Float) = 0
		_NormalMask ("NormalMask(G)", 2D) = "black" {}
		_Cutoff ("Alpha cutoff", Range(0, 1)) = 0.5
		_MaskedTransparency ("Masked Transparency", Range(0, 1)) = 0
		[Enum(Off,0,On,1)]_AlphaOptionZWrite ("Front ZWrite", Float) = 0.0
		[Gamma]_CustomAmbient("Custom Ambient", Color) = (0.666666666, 0.666666666, 0.666666666, 1)
		[MaterialToggle] _UseRampForLights ("Use Ramp For Light", Float) = 1
		[MaterialToggle] _UseRampForSpecular ("Use Ramp For Specular", Float) = 0
		[MaterialToggle] _UseRampForShadows ("Use Ramp For Shadows", Float) = 0
		[MaterialToggle] _UseLightColorSpecular ("Use Light Color Specular", Float) = 1
		[MaterialToggle] _UseDetailRAsSpecularMap ("Use DetailR as Specular Map", Float) = 0
		_UseKKPRim ("Use KKP Rim", Range(0 ,1)) = 0
		[Gamma]_KKPRimColor ("Body Rim Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_KKPRimSoft ("Body Rim Softness", Float) = 1.5
		_KKPRimIntensity ("Body Rim Intensity", Float) = 0.75
		_KKPRimAsDiffuse ("Body Rim As Diffuse", Range(0, 1)) = 0.0
		_KKPRimRotateX("Body Rim Rotate X", Float) = 0.0
		_KKPRimRotateY("Body Rim Rotate Y", Float) = 0.0

		_DisablePointLights ("Disable Point Lights", Float) = 0.0
		[MaterialToggle] _UseForwardAddFullShadows ("Use ForwardAdd Full Shadows", Float) = 0
		[MaterialToggle] _AdjustBackfaceNormals ("Adjust Backface Normals", Float) = 0.0
		_rimReflectMode ("Rimlight Placement", Float) = 0.0

		_SpecularNormalScale ("Specular Normal Map Relative Scale", Float) = 1
		_SpecularDetailNormalScale ("Specular Detail Normal Map Relative Scale", Float) = 1
		_Saturation ("Saturation", Float) = 1
	}

	SubShader
	{
		LOD 600
		Tags { "Queue" = "Transparent+40" "RenderType" = "Transparent" }

		// Opaque backfaces seal the single-layer body mesh without creating thickness.
		Pass
		{
			Name "BackfaceSeal"
			Tags { "LightMode" = "ForwardBase" "Queue" = "Transparent+40" "RenderType" = "Opaque" "ShadowSupport" = "true" }
			Blend Off
			Cull Front
			ZWrite On

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex SkinMaskedAlphaVert
			#pragma fragment frag
			#pragma only_renderers d3d11 glcore gles gles3 metal d3d11_9x xboxone ps4 psp2 n3ds wiiu
			#pragma multi_compile _ VERTEXLIGHT_ON
			#pragma multi_compile _ SHADOWS_SCREEN

			#define KKP_EXPENSIVE_RAMP
			#define SKIN_BACKFACE_SEAL_PASS

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#include "KKPSkinInput.cginc"
			#include "KKPDiffuse.cginc"
			#include "KKPNormals.cginc"
			#include "../KKPVertexLights.cginc"
			#include "../KKPVertexLightsSpecular.cginc"
			#include "../KKPLighting.cginc"
			#include "../KKPEmission.cginc"
			#include "../KKPCoom.cginc"
			#include "KKPSkinMaskedAlphaPass.cginc"
			#include "KKPSkinFrag.cginc"
			ENDCG
		}

		UsePass "Hidden/KKP/LegacyForwardAdd/SKIN_MASKED_ALPHA_BACK"

		// The independent transparency mask affects only the camera-facing surface.
		// A future third depth pass can be inserted here and reuse SkinMaskedAlphaVert.
		Pass
		{
			Name "FrontTransparent"
			Tags { "LightMode" = "ForwardBase" "Queue" = "Transparent+40" "RenderType" = "Transparent" "ShadowSupport" = "true" }
			Blend SrcAlpha OneMinusSrcAlpha, SrcAlpha OneMinusSrcAlpha
			Cull Back
			ZWrite [_AlphaOptionZWrite]

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex SkinMaskedAlphaVert
			#pragma fragment frag
			#pragma only_renderers d3d11 glcore gles gles3 metal d3d11_9x xboxone ps4 psp2 n3ds wiiu
			#pragma multi_compile _ VERTEXLIGHT_ON
			#pragma multi_compile _ SHADOWS_SCREEN

			#define KKP_EXPENSIVE_RAMP
			#define SKIN_MASKED_ALPHA_BLEND

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#include "KKPSkinInput.cginc"
			#include "KKPDiffuse.cginc"
			#include "KKPNormals.cginc"
			#include "../KKPVertexLights.cginc"
			#include "../KKPVertexLightsSpecular.cginc"
			#include "../KKPLighting.cginc"
			#include "../KKPEmission.cginc"
			#include "../KKPCoom.cginc"
			#include "KKPSkinMaskedAlphaPass.cginc"
			#include "KKPSkinFrag.cginc"
			ENDCG
		}

		UsePass "Hidden/KKP/LegacyForwardAdd/SKIN_MASKED_ALPHA_FRONT"


		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" "Queue" = "Transparent+40" "RenderType" = "TransparentCutout" "ShadowSupport" = "true" }
			Offset 1, 1
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma only_renderers d3d11 glcore gles gles3 metal d3d11_9x xboxone ps4 psp2 n3ds wiiu
			#pragma multi_compile_shadowcaster

			#include "UnityCG.cginc"
			#include "KKPSkinInput.cginc"

			struct v2f
			{
				float2 uv0 : TEXCOORD1;
				V2F_SHADOW_CASTER;
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				o.uv0 = v.texcoord;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				float2 alphaUV = i.uv0 * _AlphaMask_ST.xy + _AlphaMask_ST.zw;
				float4 alphaMask = SAMPLE_TEX2D(_AlphaMask, alphaUV);
				float2 alphaVal = -float2(_alpha_a, _alpha_b) + float2(1.0f, 1.0f);
				alphaVal = max(alphaVal, alphaMask.xy);
				alphaVal = min(alphaVal.y, alphaVal.x) - 0.5f;
				if (alphaVal.x < 0.0f)
					discard;

				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
	Fallback "Unlit/Texture"
}
