#ifndef KKP_FORWARD_ADD_INC
#define KKP_FORWARD_ADD_INC

float _UseForwardAddFullShadows;

float KKPForwardAddEnabled()
{
	// A shader with ForwardAdd still receives pixel lights when shadows are off.
	return 1.0 - saturate(_DisablePointLights);
}

float KKPForwardAddShadow(float shadowAttenuation)
{
	return lerp(1.0, saturate(shadowAttenuation), step(0.5, _UseForwardAddFullShadows));
}

float KKPForwardAddAttenuation(float3 worldPos, float shadowAttenuation)
{
	// Keep Unity's distance/cookie attenuation even in the unshadowed legacy mode.
#if defined(POINT)
	float3 lightCoord = mul(unity_WorldToLight, float4(worldPos, 1.0)).xyz;
	float attenuation = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
#elif defined(SPOT)
	float4 lightCoord = mul(unity_WorldToLight, float4(worldPos, 1.0));
	float attenuation = (lightCoord.z > 0.0) * UnitySpotCookie(lightCoord) * UnitySpotAttenuate(lightCoord.xyz);
#elif defined(POINT_COOKIE)
	float3 lightCoord = mul(unity_WorldToLight, float4(worldPos, 1.0)).xyz;
	float attenuation = tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL * texCUBE(_LightTexture0, lightCoord).w;
#elif defined(DIRECTIONAL_COOKIE)
	float2 lightCoord = mul(unity_WorldToLight, float4(worldPos, 1.0)).xy;
	float attenuation = tex2D(_LightTexture0, lightCoord).w;
#else
	float attenuation = 1.0;
#endif
	return saturate(attenuation) * KKPForwardAddShadow(shadowAttenuation);
}

float KKPForwardAddToon(float ndotl, float attenuation, float shadowAttenuation, float useRampForLights, float useRampForShadows)
{
	ndotl = saturate(ndotl);
	attenuation = saturate(attenuation);
	float rampInput = ndotl * lerp(1.0, KKPForwardAddShadow(shadowAttenuation), saturate(useRampForShadows));
	float2 rampUV = saturate(rampInput) * _RampG_ST.xy + _RampG_ST.zw;
	float ramp = SAMPLE_TEX2D(_RampG, rampUV).r;
	float toon = lerp(ndotl, ramp, saturate(useRampForLights));
	return toon * attenuation;
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
