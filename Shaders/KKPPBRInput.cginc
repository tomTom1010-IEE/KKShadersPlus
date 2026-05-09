#ifndef KKP_PBR_INPUT_INC
#define KKP_PBR_INPUT_INC

sampler2D _MainTex;
float4 _MainTex_ST;
float4 _PBRBaseColor;

sampler2D _NormalMap;
float4 _NormalMap_ST;
float _NormalMapScale;

sampler2D _PBRMetallicMap;
float4 _PBRMetallicMap_ST;
sampler2D _PBRRoughnessMap;
float4 _PBRRoughnessMap_ST;
sampler2D _PBROcclusionMap;
float4 _PBROcclusionMap_ST;
float _PBRMetallic;
float _PBRRoughness;
float _PBRRoughnessBias;
float _PBROcclusion;
float _PBROcclusionStrength;

float _PBRIOR;
float _PBRSpecular;
float _PBRFresnelStrength;
float _PBRDirectIntensity;
float _PBREnvIntensity;

sampler2D _PBRCoatMask;
float4 _PBRCoatMask_ST;
sampler2D _PBRCoatRoughnessMap;
float4 _PBRCoatRoughnessMap_ST;
sampler2D _PBRCoatNormalMap;
float4 _PBRCoatNormalMap_ST;
float _PBRCoatWeight;
float _PBRCoatRoughness;
float _PBRCoatIOR;
float _PBRCoatNormalScale;

sampler2D _EmissionMask;
float4 _EmissionMask_ST;
float4 _EmissionColor;
float _EmissionIntensity;

sampler2D _PBRDiffuseBlendMask;
float4 _PBRDiffuseBlendMask_ST;
sampler2D _PBRSpecularBlendMask;
float4 _PBRSpecularBlendMask_ST;
sampler2D _PBRReflectionBlendMask;
float4 _PBRReflectionBlendMask_ST;
sampler2D _PBRCoatBlendMask;
float4 _PBRCoatBlendMask_ST;
float _PBRMasterBlend;
float _PBRDiffuseBlend;
float _PBRSpecularBlend;
float _PBRReflectionBlend;
float _PBRCoatBlend;

struct KKPPBRSurface
{
	float3 albedo;
	float metallic;
	float roughness;
	float occlusion;
	float3 normalWS;
	float3 emission;
	float coatWeight;
	float coatRoughness;
	float3 coatNormalWS;
	float diffuseBlend;
	float specularBlend;
	float reflectionBlend;
	float coatBlend;
};

float3 KKP_PBR_SampleNormalWS(sampler2D normalMap, float2 uv, float scale, float3 normalWS, float3 tangentWS, float3 bitangentWS)
{
	float3 normalTS = UnpackScaleNormal(tex2D(normalMap, uv), scale);
	float3x3 tbn = float3x3(normalize(tangentWS), normalize(bitangentWS), normalize(normalWS));
	return normalize(mul(normalTS, tbn));
}

KKPPBRSurface KKP_PBR_SampleSurface(float2 uv, float3 normalWS, float3 tangentWS, float3 bitangentWS)
{
	KKPPBRSurface s;
	s.albedo = tex2D(_MainTex, uv * _MainTex_ST.xy + _MainTex_ST.zw).rgb * _PBRBaseColor.rgb;

	s.metallic = saturate(_PBRMetallic * tex2D(_PBRMetallicMap, uv * _PBRMetallicMap_ST.xy + _PBRMetallicMap_ST.zw).r);
	s.roughness = saturate(_PBRRoughness * tex2D(_PBRRoughnessMap, uv * _PBRRoughnessMap_ST.xy + _PBRRoughnessMap_ST.zw).r + _PBRRoughnessBias);
	s.roughness = max(s.roughness, 0.04);

	float occlusionRaw = saturate(_PBROcclusion * tex2D(_PBROcclusionMap, uv * _PBROcclusionMap_ST.xy + _PBROcclusionMap_ST.zw).r);
	s.occlusion = lerp(1.0, occlusionRaw, _PBROcclusionStrength);

	s.normalWS = KKP_PBR_SampleNormalWS(_NormalMap, uv * _NormalMap_ST.xy + _NormalMap_ST.zw, _NormalMapScale, normalWS, tangentWS, bitangentWS);
	s.emission = tex2D(_EmissionMask, uv * _EmissionMask_ST.xy + _EmissionMask_ST.zw).rgb * _EmissionColor.rgb * _EmissionIntensity;

	s.coatWeight = saturate(_PBRCoatWeight * tex2D(_PBRCoatMask, uv * _PBRCoatMask_ST.xy + _PBRCoatMask_ST.zw).r);
	s.coatRoughness = saturate(_PBRCoatRoughness * tex2D(_PBRCoatRoughnessMap, uv * _PBRCoatRoughnessMap_ST.xy + _PBRCoatRoughnessMap_ST.zw).r);
	s.coatRoughness = max(s.coatRoughness, 0.04);
	s.coatNormalWS = KKP_PBR_SampleNormalWS(_PBRCoatNormalMap, uv * _PBRCoatNormalMap_ST.xy + _PBRCoatNormalMap_ST.zw, _PBRCoatNormalScale, normalWS, tangentWS, bitangentWS);

	s.diffuseBlend = saturate(_PBRMasterBlend * _PBRDiffuseBlend * tex2D(_PBRDiffuseBlendMask, uv * _PBRDiffuseBlendMask_ST.xy + _PBRDiffuseBlendMask_ST.zw).r);
	s.specularBlend = saturate(_PBRMasterBlend * _PBRSpecularBlend * tex2D(_PBRSpecularBlendMask, uv * _PBRSpecularBlendMask_ST.xy + _PBRSpecularBlendMask_ST.zw).r);
	s.reflectionBlend = saturate(_PBRMasterBlend * _PBRReflectionBlend * tex2D(_PBRReflectionBlendMask, uv * _PBRReflectionBlendMask_ST.xy + _PBRReflectionBlendMask_ST.zw).r);
	s.coatBlend = saturate(_PBRMasterBlend * _PBRCoatBlend * tex2D(_PBRCoatBlendMask, uv * _PBRCoatBlendMask_ST.xy + _PBRCoatBlendMask_ST.zw).r);

	return s;
}

#endif
