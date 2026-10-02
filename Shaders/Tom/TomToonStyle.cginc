#ifndef TOM_TOON_STYLE_INC
#define TOM_TOON_STYLE_INC

float TomLuminance(float3 color)
{
	return dot(max(color, 0.0), float3(0.2126, 0.7152, 0.0722));
}

float TomSoftBand(float value, float threshold, float softness)
{
	float halfWidth = max(softness, 0.001) * 0.5;
	return smoothstep(threshold - halfWidth, threshold + halfWidth, value);
}

float3 TomDiffuseWeight(float3 fresnel, float metallic)
{
	// Metallic owns diffuse removal; the optional Fresnel suppression is independent of lobe style.
	return (1.0 - metallic) * lerp(1.0.xxx, 1.0 - fresnel, saturate(_DiffuseEnergyBlend));
}

float TomFilteredRoughness(float roughness, float normalVariance)
{
	float alpha = roughness * roughness;
	return pow(saturate(alpha * alpha + min(normalVariance * _SpecularAA, 0.25)), 0.25);
}

float TomStylizedGGXLobe(float nDotH, float normalVariance)
{
	float roughness = TomFilteredRoughness(lerp(0.08, 1.0, saturate(_SpecularSize)), normalVariance);
	float alpha2 = max(pow(roughness, 4.0), 0.00001);
	float denominator = nDotH * nDotH * (alpha2 - 1.0) + 1.0;
	// GGX distribution divided by its peak. Light intensity cannot move the band boundary.
	float normalizedDistribution = alpha2 * alpha2 / max(denominator * denominator, 1e-10);
	float aaWidth = max(_SpecularSoftness, fwidth(normalizedDistribution) * _SpecularAA);
	float band = TomSoftBand(normalizedDistribution, _SpecularThreshold, aaWidth);
	int levels = (int)clamp(floor(_SpecularBands + 0.5), 1.0, 4.0);
	if (levels > 1)
	{
		float quantized = 0.0;
		for (int index = 1; index < 4; index++)
		{
			if (index < levels)
				quantized += TomSoftBand(band, (float)index / levels, max(fwidth(band), 0.01));
		}
		band = quantized / (levels - 1);
	}
	return band;
}

float3 TomShapeEnvironment(float3 environment)
{
	float luminance = TomLuminance(environment);
	float selection = TomSoftBand(luminance * _EnvironmentExposure,
		_EnvironmentThreshold, _EnvironmentSoftness);
	// Remove broad low-frequency fill; bound only the artistic path, never the continuous HDR path.
	float3 normalizedColor = environment / max(luminance, 0.0001);
	float3 tone = lerp(1.0.xxx, normalizedColor, saturate(_EnvironmentColorWeight));
	return tone * selection * saturate(luminance);
}

#endif
