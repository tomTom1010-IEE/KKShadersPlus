#ifndef TOM_TOON_INPUT_INC
#define TOM_TOON_INPUT_INC

#include "../KKPDeclarations.cginc"

struct TomVertexData
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float2 uv0 : TEXCOORD0;
};

struct TomVaryings
{
	float4 posCS : SV_POSITION;
	float2 uv0 : TEXCOORD0;
	float3 posWS : TEXCOORD1;
	float3 normalWS : TEXCOORD2;
	float4 tangentWS : TEXCOORD3;
	float3 bitangentWS : TEXCOORD4;
	LIGHTING_COORDS(5, 6)
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
float _LightProbeBlend;
float _IndirectDiffuseIntensity;

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
