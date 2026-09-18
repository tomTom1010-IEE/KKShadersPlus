#ifndef TOM_TOON_BRDF_INC
#define TOM_TOON_BRDF_INC

#include "UnityStandardBRDF.cginc"

float TomIorToF0(float ior)
{
	ior = max(ior, 1.0);
	float ratio = (ior - 1.0) / max(ior + 1.0, 0.001);
	return ratio * ratio;
}

float3 TomFresnelSchlick(float cosTheta, float3 f0, float fresnelStrength)
{
	float oneMinusCos = 1.0 - saturate(cosTheta);
	float oneMinusCos2 = oneMinusCos * oneMinusCos;
	float oneMinusCos5 = oneMinusCos2 * oneMinusCos2 * oneMinusCos;
	return saturate(f0 + (1.0 - f0) * oneMinusCos5 * max(fresnelStrength, 0.0));
}

float3 TomEvaluateProductionGGX(
	float nDotV,
	float nDotL,
	float nDotH,
	float vDotH,
	float perceptualRoughness,
	float3 f0,
	float fresnelStrength)
{
	nDotV = saturate(nDotV);
	nDotL = saturate(nDotL);
	if (nDotV <= 0.00001 || nDotL <= 0.00001)
		return 0.0;

	perceptualRoughness = max(saturate(perceptualRoughness), 0.04);
	float roughness = max(PerceptualRoughnessToRoughness(perceptualRoughness), 0.002);
	float visibility = max(SmithJointGGXVisibilityTerm(nDotL, nDotV, roughness), 0.0);
	float distribution = max(GGXTerm(saturate(nDotH), roughness), 0.0);
	float specularTerm = visibility * distribution * UNITY_PI;

#if defined(UNITY_COLORSPACE_GAMMA)
	// Match Unity 2019 Standard BRDF's stable gamma-space response.
	specularTerm = sqrt(max(0.0001, specularTerm));
#endif

	specularTerm = max(specularTerm * nDotL, 0.0);
	return specularTerm * TomFresnelSchlick(vDotH, f0, fresnelStrength);
}

#endif
