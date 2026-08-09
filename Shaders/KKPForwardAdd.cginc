#ifndef KKP_FORWARD_ADD_INC
#define KKP_FORWARD_ADD_INC

float _UseForwardAddFullShadows;

float KKPForwardAddEnabled()
{
	return step(0.5, _UseForwardAddFullShadows) * (1.0 - saturate(_DisablePointLights));
}

float KKPForwardAddToon(float ndotl, float attenuation, float useRampForLights, float useRampForShadows)
{
	ndotl = saturate(ndotl);
	attenuation = saturate(attenuation);
	float rampInput = ndotl * lerp(1.0, attenuation, saturate(useRampForShadows));
	float2 rampUV = saturate(rampInput) * _RampG_ST.xy + _RampG_ST.zw;
	float ramp = SAMPLE_TEX2D(_RampG, rampUV).r;
	float toon = lerp(ndotl, ramp, saturate(useRampForLights));
	return toon * lerp(attenuation, 1.0, saturate(useRampForShadows) * saturate(useRampForLights));
}

float KKPForwardAddSpecular(float3 normalWS, float3 lightDir, float3 viewDir, float power)
{
	float3 halfDir = normalize(lightDir + viewDir);
	float ndoth = saturate(dot(normalWS, halfDir));
	float exponent = max(power * 256.0, 1.0);
	return exp2(log2(max(ndoth, 1E-06)) * exponent) * saturate(power);
}

float3 KKPForwardAddLightColor(float3 diffuse, float toon)
{
	return diffuse * toon * _LightColor0.rgb * 0.6 * KKPForwardAddEnabled();
}

#endif
