#ifndef TOM_TOON_INPUT_INC
#define TOM_TOON_INPUT_INC

#include "../KKPDeclarations.cginc"

struct TomVertexData
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float2 uv0 : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
	float2 uv2 : TEXCOORD2;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct TomVaryings
{
	float4 posCS : SV_POSITION;
	float2 uv0 : TEXCOORD0;
	float3 posWS : TEXCOORD1;
	float3 normalWS : TEXCOORD2;
	float4 tangentWS : TEXCOORD3;
	float3 bitangentWS : TEXCOORD4;
	half4 ambientOrLightmapUV : TEXCOORD5;
	UNITY_LIGHTING_COORDS(6, 7)
	UNITY_FOG_COORDS(8)
	half3 vertexLightDiffuse : TEXCOORD9;
	UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};

DECLARE_TEX2D(_MainTex);
DECLARE_TEX2D(_AlphaMask);
DECLARE_TEX2D(_NormalMap);
DECLARE_TEX2D_NOSAMPLER(_NormalMapDetail);
DECLARE_TEX2D(_RampTex);
DECLARE_TEX2D(_SpecularMask);
DECLARE_TEX2D(_MetallicMap);
DECLARE_TEX2D(_RoughnessMap);
DECLARE_TEX2D(_OcclusionMap);
DECLARE_TEX2D(_ReflectionMask);
DECLARE_TEX2D(_MatCap);
DECLARE_TEX2D(_EmissionMask);

float4 _MainTex_ST;
float4 _AlphaMask_ST;
float4 _NormalMap_ST;
float4 _NormalMapDetail_ST;
float4 _RampTex_ST;
float4 _SpecularMask_ST;
float4 _MetallicMap_ST;
float4 _RoughnessMap_ST;
float4 _OcclusionMap_ST;
float4 _ReflectionMask_ST;
float4 _MatCap_ST;
float4 _EmissionMask_ST;

float4 _BaseColor;
float _Cutoff;
float _CullOption;
float _NormalMapScale;
float _DetailNormalMapScale;

float4 _AmbientColor;
float4 _ShadowColor;
float _ShadowStrength;
float _UseRamp;
float _UseRampForShadows;
float _ShadowRemapStrength;
float _ShadowThreshold;
float _ShadowSoftness;
float _MainLightIntensity;
float _AdditionalLightIntensity;
float _VertexLightIntensity;
float _LightProbeBlend;
float _CustomSHVolumeBlend;
float _IndirectDiffuseIntensity;

sampler3D _TomSHVolumeTex;
float4x4 _TomSHWorldToLocal;
float4 _TomSHBoundsMin;
float4 _TomSHBoundsInvSize;
float4 _TomSHVolumeGrid;
float4 _TomSHVolumeParams;

float4 _SpecularColor;
float _SpecularStrength;
float _SpecularPower;
float _SpecularShadowStrength;
float _GGXSpecularBlend;
float _Metallic;
float _Roughness;
float _RoughnessBias;
float _SpecularIOR;
float _FresnelStrength;
float _NormalHorizonFade;
float _OcclusionStrength;
float _SpecularOcclusionStrength;

float4 _RimColor;
float _RimStrength;
float _RimPower;
float _RimShadowStrength;

float _ReflectionMode;
float _MatCapBlendMode;
float _MatCapIntensity;
float _MatCapMip;
float _EnvironmentIntensity;
float _EnvironmentRoughness;
float _UseMaterialRoughnessForEnvironment;
float _ReflectionShadowStrength;

float4 _EmissionColor;
float _EmissionIntensity;

float _OutlineOn;
float4 _OutlineColor;
float _OutlineWidth;
float _OutlineScreenSpace;
float _OutlineDepthOffset;

#endif
