#ifndef KKP_PBR_BRDF_INC
#define KKP_PBR_BRDF_INC

#define KKP_PBR_PI 3.14159265

float KKP_PBR_Square(float x)
{
	return x * x;
}

float KKP_PBR_IorToF0(float ior)
{
	float f0 = (ior - 1.0) / max(ior + 1.0, 0.001);
	return f0 * f0;
}

float3 KKP_PBR_FresnelSchlick(float cosTheta, float3 f0, float fresnelStrength)
{
	float f = pow(1.0 - saturate(cosTheta), 5.0);
	return saturate(f0 + (1.0 - f0) * f * fresnelStrength);
}

float KKP_PBR_DistributionGGX(float nDotH, float roughness)
{
	float a = KKP_PBR_Square(max(roughness, 0.04));
	float a2 = a * a;
	float denom = KKP_PBR_Square(nDotH) * (a2 - 1.0) + 1.0;
	return a2 / max(KKP_PBR_PI * denom * denom, 0.0001);
}

float KKP_PBR_GeometrySchlickGGX(float nDotV, float roughness)
{
	float r = roughness + 1.0;
	float k = (r * r) * 0.125;
	return nDotV / max(nDotV * (1.0 - k) + k, 0.0001);
}

float KKP_PBR_GeometrySmith(float nDotV, float nDotL, float roughness)
{
	return KKP_PBR_GeometrySchlickGGX(nDotV, roughness) * KKP_PBR_GeometrySchlickGGX(nDotL, roughness);
}

float3 KKP_PBR_SampleReflectionProbe(float3 reflectDir, float roughness)
{
	float mip = saturate(roughness) * UNITY_SPECCUBE_LOD_STEPS;
	float4 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectDir, mip);
	return DecodeHDR(envSample, unity_SpecCube0_HDR);
}

float3 KKP_PBR_DirectSpecularGGX(float nDotV, float nDotL, float nDotH, float vDotH, float roughness, float3 f0, float fresnelStrength)
{
	float3 f = KKP_PBR_FresnelSchlick(vDotH, f0, fresnelStrength);
	float d = KKP_PBR_DistributionGGX(nDotH, roughness);
	float g = KKP_PBR_GeometrySmith(nDotV, nDotL, roughness);
	return (d * g * f) / max(4.0 * nDotV * nDotL, 0.0001);
}

#endif
