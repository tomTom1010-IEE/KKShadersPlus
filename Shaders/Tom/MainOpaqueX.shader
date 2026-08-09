Shader "tom/MainOpaqueX"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_NormalMap ("Normal Map", 2D) = "bump" {}
		_NormalMapDetail ("Detail Normal Map", 2D) = "bump" {}
		_AlphaMask ("Alpha Mask", 2D) = "white" {}
		_RampTex ("Toon Ramp", 2D) = "white" {}
		_SpecularMask ("Specular Mask", 2D) = "white" {}
		_MetallicMap ("Metallic Map", 2D) = "white" {}
		_RoughnessMap ("Roughness Map", 2D) = "white" {}
		_OcclusionMap ("Occlusion Map", 2D) = "white" {}
		_ReflectionMask ("Reflection Mask", 2D) = "white" {}
		_MatCap ("MatCap", 2D) = "black" {}
		_EmissionMask ("Emission Mask", 2D) = "black" {}

		[Gamma] _BaseColor ("Base Color", Color) = (1,1,1,1)
		_Cutoff ("Alpha Cutoff", Range(0,1)) = 0.5
		[Enum(Off,0,Front,1,Back,2)] _CullOption ("Cull", Float) = 2
		_NormalMapScale ("Normal Scale", Range(0,2)) = 1
		_DetailNormalMapScale ("Detail Normal Scale", Range(0,2)) = 1

		[Gamma] _AmbientColor ("Ambient Color", Color) = (0.35,0.35,0.35,1)
		[Gamma] _ShadowColor ("Shadow Color", Color) = (0.65,0.65,0.7,1)
		_ShadowStrength ("Shadow Strength", Range(0,1)) = 1
		[MaterialToggle] _UseRamp ("Use Toon Ramp", Float) = 1
		[MaterialToggle] _UseRampForShadows ("Put Shadows Into Ramp", Float) = 1
		_ShadowRemapStrength ("Shadow Remap Strength", Range(0,1)) = 0
		_ShadowThreshold ("Shadow Threshold", Range(0,1)) = 0.5
		_ShadowSoftness ("Shadow Softness", Range(0.001,1)) = 0.2
		_MainLightIntensity ("Main Light Intensity", Range(0,4)) = 1
		_AdditionalLightIntensity ("Additional Light Intensity", Range(0,4)) = 1
		_LightProbeBlend ("Light Probe Blend", Range(0,1)) = 1
		_IndirectDiffuseIntensity ("Indirect Diffuse Intensity", Range(0,4)) = 1

		[Gamma] _SpecularColor ("Specular Color", Color) = (1,1,1,1)
		_SpecularStrength ("Specular Strength", Range(0,4)) = 0.5
		_SpecularPower ("Specular Power", Range(1,256)) = 64
		_SpecularShadowStrength ("Specular Shadow Strength", Range(0,1)) = 1
		_GGXSpecularBlend ("GGX Specular Blend", Range(0,1)) = 1
		_Metallic ("Metallic", Range(0,1)) = 0
		_Roughness ("Roughness", Range(0.04,1)) = 0.5
		_RoughnessBias ("Roughness Bias", Range(-1,1)) = 0
		_SpecularIOR ("Specular IOR", Range(1,2.5)) = 1.5
		_FresnelStrength ("Fresnel Strength", Range(0,2)) = 1
		_NormalHorizonFade ("Normal Horizon Fade", Range(0.001,0.25)) = 0.05
		_OcclusionStrength ("Occlusion Strength", Range(0,1)) = 1
		_SpecularOcclusionStrength ("Specular Occlusion Strength", Range(0,1)) = 1

		[Gamma] _RimColor ("Rim Color", Color) = (1,1,1,1)
		_RimStrength ("Rim Strength", Range(0,4)) = 0
		_RimPower ("Rim Power", Range(0.1,16)) = 4
		_RimShadowStrength ("Rim Shadow Strength", Range(0,1)) = 0

		[Enum(Off,0,MatCap,1,Environment,2,MatCapAndEnvironment,3)] _ReflectionMode ("Reflection Mode", Float) = 0
		[Enum(Multiply,0,Add,1)] _MatCapBlendMode ("MatCap Blend", Float) = 1
		_MatCapIntensity ("MatCap Intensity", Range(0,2)) = 1
		_MatCapMip ("MatCap Mip", Range(0,8)) = 0
		_EnvironmentIntensity ("Environment Intensity", Range(0,4)) = 1
		_EnvironmentRoughness ("Environment Roughness", Range(0,1)) = 0.5
		[MaterialToggle] _UseMaterialRoughnessForEnvironment ("Use Material Roughness For Environment", Float) = 1
		_ReflectionShadowStrength ("Reflection Shadow Strength", Range(0,1)) = 0

		[MaterialToggle] _OutlineOn ("Outline", Float) = 0
		[Gamma] _OutlineColor ("Outline Color", Color) = (0,0,0,1)
		_OutlineWidth ("Outline Width", Range(0,8)) = 1
		[MaterialToggle] _OutlineScreenSpace ("Screen Space Outline", Float) = 1
		_OutlineDepthOffset ("Outline Depth Offset", Range(-1,1)) = 0

		[Gamma] _EmissionColor ("Emission Color", Color) = (1,1,1,1)
		_EmissionIntensity ("Emission Intensity", Range(0,10)) = 0
	}

	SubShader
	{
		LOD 600
		Tags { "Queue" = "AlphaTest" "RenderType" = "TransparentCutout" }

		Pass
		{
			Name "OUTLINE"
			Tags { "LightMode" = "Always" }
			Cull Front
			ZWrite On
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vertOutline
			#pragma fragment fragOutline
			#pragma only_renderers d3d11 glcore gles3 metal xboxone ps4
			#include "UnityCG.cginc"
			sampler2D _MainTex;
			sampler2D _AlphaMask;
			float4 _MainTex_ST;
			float4 _AlphaMask_ST;
			float _Cutoff;
			float _OutlineOn;
			float _OutlineWidth;
			float _OutlineScreenSpace;
			float _OutlineDepthOffset;
			float4 _OutlineColor;
			struct appdata { float4 vertex : POSITION; float3 normal : NORMAL; float2 uv : TEXCOORD0; };
			struct v2f { float4 pos : SV_POSITION; float2 uv : TEXCOORD0; };
			v2f vertOutline(appdata v)
			{
				v2f o;
				float4 basePositionCS = UnityObjectToClipPos(v.vertex);
				float4 expandedVertex = v.vertex;
				expandedVertex.xyz += v.normal * (_OutlineWidth * 0.01);
				float4 objectSpacePositionCS = UnityObjectToClipPos(expandedVertex);

				float3 normalVS = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
				float2 projectedNormal = mul((float2x2)UNITY_MATRIX_P, normalVS.xy);
				projectedNormal /= max(length(projectedNormal), 0.0001);
				float2 pixelSizeCS = 2.0 / _ScreenParams.xy;
				float4 screenSpacePositionCS = basePositionCS;
				screenSpacePositionCS.xy += projectedNormal * pixelSizeCS * _OutlineWidth * basePositionCS.w;
				o.pos = lerp(objectSpacePositionCS, screenSpacePositionCS, saturate(_OutlineScreenSpace));
				o.pos.z += _OutlineDepthOffset * 0.001 * o.pos.w;
				o.uv = v.uv;
				return o;
			}
			fixed4 fragOutline(v2f i) : SV_Target
			{
				clip(_OutlineOn - 0.5);
				float mainAlpha = tex2D(_MainTex, i.uv * _MainTex_ST.xy + _MainTex_ST.zw).a;
				float mask = tex2D(_AlphaMask, i.uv * _AlphaMask_ST.xy + _AlphaMask_ST.zw).r;
				clip(mainAlpha * mask - _Cutoff);
				return _OutlineColor;
			}
			ENDCG
		}

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }
			Cull [_CullOption]
			ZWrite On
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex TomVert
			#pragma fragment TomFragBase
			#pragma multi_compile_fwdbase
			#pragma multi_compile __ UNITY_SPECCUBE_BOX_PROJECTION
			#pragma multi_compile __ UNITY_SPECCUBE_BLENDING
			#pragma only_renderers d3d11 glcore gles3 metal xboxone ps4
			#include "UnityCG.cginc"
			#include "UnityStandardUtils.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#include "TomToonInput.cginc"
			#include "TomToonLighting.cginc"
			ENDCG
		}

		Pass
		{
			Name "FORWARDADD"
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			ColorMask RGB
			Cull [_CullOption]
			ZWrite Off
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex TomVert
			#pragma fragment TomFragAdd
			#pragma multi_compile_fwdadd_fullshadows
			#pragma only_renderers d3d11 glcore gles3 metal xboxone ps4
			#include "UnityCG.cginc"
			#include "UnityStandardUtils.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#include "TomToonInput.cginc"
			#include "TomToonLighting.cginc"
			ENDCG
		}

		Pass
		{
			Name "SHADOWCASTER"
			Tags { "LightMode" = "ShadowCaster" }
			Cull [_CullOption]
			Offset 1, 1
			CGPROGRAM
			#pragma vertex vertShadow
			#pragma fragment fragShadow
			#pragma multi_compile_shadowcaster
			#pragma only_renderers d3d11 glcore gles3 metal xboxone ps4
			#include "UnityCG.cginc"
			sampler2D _MainTex;
			sampler2D _AlphaMask;
			float4 _MainTex_ST;
			float4 _AlphaMask_ST;
			float _Cutoff;
			struct v2f { float2 uv : TEXCOORD1; V2F_SHADOW_CASTER; };
			v2f vertShadow(appdata_base v)
			{
				v2f o;
				o.uv = v.texcoord.xy;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}
			float4 fragShadow(v2f i) : SV_Target
			{
				float mainAlpha = tex2D(_MainTex, i.uv * _MainTex_ST.xy + _MainTex_ST.zw).a;
				float mask = tex2D(_AlphaMask, i.uv * _AlphaMask_ST.xy + _AlphaMask_ST.zw).r;
				clip(mainAlpha * mask - _Cutoff);
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
}
