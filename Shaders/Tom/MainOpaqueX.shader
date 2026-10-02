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
		_ShadowOffsetFactor ("Shadow Offset Factor", Range(-4,4)) = 0
		_ShadowOffsetUnits ("Shadow Offset Units", Range(-4,4)) = 0
		_MainLightIntensity ("Main Light Intensity", Range(0,4)) = 1
		_AdditionalLightIntensity ("Additional Light Intensity", Range(0,4)) = 1
		_VertexLightIntensity ("Vertex Light Fill Intensity", Range(0,1)) = 0.5
		_LightProbeBlend ("Light Probe Blend", Range(0,1)) = 1
		_CustomSHVolumeBlend ("Custom SH Volume Blend", Range(0,1)) = 1
		_IndirectDiffuseIntensity ("Indirect Diffuse Intensity", Range(0,4)) = 1

		[Gamma] _SpecularColor ("Direct Specular Color", Color) = (1,1,1,1)
		_SpecularStrength ("Direct Specular Strength", Range(0,4)) = 0.5
		_SpecularShadowStrength ("Specular Shadow Strength", Range(0,1)) = 1
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

		[MaterialToggle] _UsePackedMaterialMap ("Use Packed Material Map", Float) = 0
		_MaterialMap ("Material Map (Metal/Rough/AO/Spec)", 2D) = "white" {}
		_LayerMask ("Layer Mask (Tone/Rim/MatCap/Environment)", 2D) = "white" {}
		_SecondaryRamp ("Secondary Tone Ramp", 2D) = "white" {}
		_OutlineWidthMask ("Outline Width Mask", 2D) = "white" {}
		_DiffuseEnergyBlend ("Physical Diffuse Suppression", Range(0,1)) = 0
		[Enum(Procedural,0,Texture,1)] _RampMode ("Toon Ramp Source", Float) = 0
		_ToonThreshold ("Toon Threshold", Range(0,1)) = 0.5
		_ToonSoftness ("Toon Softness", Range(0.001,1)) = 0.1
		_ToonShadeLevel ("Toon Shade Level", Range(0,1)) = 0.15
		_SecondaryToneStrength ("Secondary Tone Strength", Range(0,1)) = 0
		_IndirectToonBlend ("Indirect Tone Blend", Range(0,1)) = 0
		_IndirectToonThreshold ("Indirect Tone Threshold", Range(0,2)) = 0.4
		_IndirectToonSoftness ("Indirect Tone Softness", Range(0.001,1)) = 0.2
		_IndirectShadeLevel ("Indirect Shade Level", Range(0,1)) = 0.3
		_SpecularToonBlend ("Direct Specular Toon Blend", Range(0,1)) = 1
		_SpecularSize ("Direct Highlight Size", Range(0,1)) = 0.5
		_SpecularThreshold ("Direct Highlight Threshold", Range(0,1)) = 0.5
		_SpecularSoftness ("Direct Highlight Softness", Range(0.001,1)) = 0.15
		[IntRange] _SpecularBands ("Direct Highlight Bands (1 = Smooth)", Range(1,4)) = 1
		_SpecularAA ("Specular Anti Aliasing", Range(0,1)) = 0.5
		_EnvironmentToonBlend ("Environment Toon Blend", Range(0,1)) = 1
		_EnvironmentThreshold ("Environment Highlight Threshold", Range(0,1)) = 0.6
		_EnvironmentSoftness ("Environment Highlight Softness", Range(0.001,1)) = 0.2
		_EnvironmentExposure ("Environment Selection Exposure", Range(0.01,8)) = 1
		_EnvironmentColorWeight ("Environment Color Weight", Range(0,1)) = 0.5
		_EnvironmentBaseColorTint ("Environment Base Color Tint", Range(0,1)) = 0
		_EnvironmentFresnelStrength ("Environment Fresnel Strength", Range(0,2)) = 1
		[Gamma] _EnvironmentColor ("Environment Tint", Color) = (1,1,1,1)
		_RimWidth ("Rim Width", Range(0,1)) = 0.3
		_RimSoftness ("Rim Softness", Range(0.001,1)) = 0.2
		_RimLightInfluence ("Rim Main Light Influence", Range(0,1)) = 0
		[Enum(Geometry,0,MainNormal,1,CombinedNormal,2)] _MatCapNormalSource ("MatCap Normal Source", Float) = 2
		[MaterialToggle] _EmissionKeepCol ("Emission Keep Base Color", Float) = 0
		[Enum(MeshNormal,0,UV4ObjectSpace,1)] _OutlineNormalSource ("Outline Normal Source", Float) = 0
		[Enum(Final,0,Body,1,DirectSpecular,2,Environment,3,MatCap,4,Rim,5,Emission,6)] _DebugView ("Lighting Debug View", Float) = 0
	}

	SubShader
	{
		LOD 600
		Tags { "Queue" = "AlphaTest" "RenderType" = "TransparentCutout" }

		Pass
		{
			Name "OUTLINE"
			Tags { "LightMode" = "Always" }
			Cull Off
			ZWrite On
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vertOutline
			#pragma fragment fragOutline
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			#pragma only_renderers d3d11 glcore gles3 metal xboxone ps4
			#include "UnityCG.cginc"
			sampler2D _MainTex;
			sampler2D _AlphaMask;
			sampler2D _OutlineWidthMask;
			float4 _MainTex_ST;
			float4 _AlphaMask_ST;
			float4 _OutlineWidthMask_ST;
			float _Cutoff;
			float _CullOption;
			float _OutlineOn;
			float _OutlineWidth;
			float _OutlineScreenSpace;
			float _OutlineDepthOffset;
			float _OutlineNormalSource;
			float _DebugView;
			float4 _OutlineColor;
			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				float3 smoothNormalOS : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vertOutline(appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				float4 basePositionCS = UnityObjectToClipPos(v.vertex);
				float3 positionWS = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 normalOS = v.normal;
				if (_OutlineNormalSource > 0.5 && dot(v.smoothNormalOS, v.smoothNormalOS) > 0.0001)
					normalOS = normalize(v.smoothNormalOS);
				float3 normalWS = normalize(UnityObjectToWorldNormal(normalOS));
				float2 widthUV = v.uv * _OutlineWidthMask_ST.xy + _OutlineWidthMask_ST.zw;
				float width = _OutlineWidth * tex2Dlod(_OutlineWidthMask, float4(widthUV, 0, 0)).r;
				float3 expandedPositionWS = positionWS + normalWS * (width * 0.01);
				float4 worldSpacePositionCS = UnityWorldToClipPos(expandedPositionWS);

				float3 normalVS = mul((float3x3)UNITY_MATRIX_V, normalWS);
				float2 projectedNormal = mul((float2x2)UNITY_MATRIX_P, normalVS.xy);
				projectedNormal /= max(length(projectedNormal), 0.0001);
				float2 pixelSizeCS = 2.0 / _ScreenParams.xy;
				float4 screenSpacePositionCS = basePositionCS;
				screenSpacePositionCS.xy += projectedNormal * pixelSizeCS * width * basePositionCS.w;
				o.pos = lerp(worldSpacePositionCS, screenSpacePositionCS, saturate(_OutlineScreenSpace));
				#if defined(UNITY_REVERSED_Z)
				o.pos.z -= _OutlineDepthOffset * 0.001 * o.pos.w;
				#else
				o.pos.z += _OutlineDepthOffset * 0.001 * o.pos.w;
				#endif
				o.uv = v.uv;
				UNITY_TRANSFER_FOG(o, o.pos);
				return o;
			}
			fixed4 fragOutline(v2f i, fixed faceSign : VFACE) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				clip(_OutlineOn - 0.5);
				clip(0.5 - _DebugView);
				if (_CullOption > 0.5 && _CullOption < 1.5)
					clip(faceSign);
				else
					clip(-faceSign);
				float mainAlpha = tex2D(_MainTex, i.uv * _MainTex_ST.xy + _MainTex_ST.zw).a;
				float mask = tex2D(_AlphaMask, i.uv * _AlphaMask_ST.xy + _AlphaMask_ST.zw).r;
				clip(mainAlpha * mask - _Cutoff);
				fixed4 color = _OutlineColor;
				UNITY_APPLY_FOG(i.fogCoord, color);
				return color;
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
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
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
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
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
			Cull Off
			Offset [_ShadowOffsetFactor], [_ShadowOffsetUnits]
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vertShadow
			#pragma fragment fragShadow
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing
			#pragma only_renderers d3d11 glcore gles3 metal xboxone ps4
			#include "UnityCG.cginc"
			sampler2D _MainTex;
			sampler2D _AlphaMask;
			float4 _MainTex_ST;
			float4 _AlphaMask_ST;
			float _Cutoff;
			float _CullOption;
			struct v2f { float2 uv : TEXCOORD1; V2F_SHADOW_CASTER; };
			v2f vertShadow(appdata_base v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				o.uv = v.texcoord.xy;
				UNITY_BRANCH
				if (_CullOption < 0.5)
				{
					TRANSFER_SHADOW_CASTER_NOPOS_LEGACY(o, o.pos)
				}
				else
				{
					if (_CullOption < 1.5)
						v.normal = -v.normal;
					TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				}
				return o;
			}
			float4 fragShadow(v2f i, fixed faceSign : VFACE) : SV_Target
			{
				if (_CullOption > 1.5)
					clip(faceSign);
				else if (_CullOption > 0.5)
					clip(-faceSign);
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
