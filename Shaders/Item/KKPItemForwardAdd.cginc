#ifndef KKP_ITEM_FORWARD_ADD_INC
#define KKP_ITEM_FORWARD_ADD_INC

#include "../KKPForwardAdd.cginc"

#ifdef STUDIO_SHADER
float2 KKPForwardAddPatternUV(Varyings i, float4 texST, float4 patternUV, float rotation, float clampUV)
{
	float2 uv = i.uv0 * patternUV.xy + patternUV.zw;
	float s, c;
	sincos(rotation, s, c);
	uv -= 0.5;
	uv = float2(c * uv.x - s * uv.y, s * uv.x + c * uv.y) + 0.5;
	uv = uv * texST.xy + texST.zw;
	return lerp(uv, saturate(uv), saturate(clampUV));
}
#endif

float3 KKPItemForwardAddDiffuse(Varyings i, float4 mainTex)
{
#ifdef KKP_ITEM_OPAQUE
	float4 colorMask = SAMPLE_TEX2D_SAMPLER(_ColMask, _MainTex, i.uv0 * _ColMask_ST.xy + _ColMask_ST.zw);
	float3 color = _Col0.rgb;
	color = lerp(color, _Col1.rgb, colorMask.r);
	color = lerp(color, _Col2.rgb, colorMask.g);
	color = lerp(color, _Col3.rgb, colorMask.b);
	return mainTex.rgb * color;
#elif defined(STUDIO_SHADER)
	float4 colorMask = SAMPLE_TEX2D(_ColorMask, i.uv0 * _ColorMask_ST.xy + _ColorMask_ST.zw);
	float3 pattern1 = SAMPLE_TEX2D(_PatternMask1, KKPForwardAddPatternUV(i, _PatternMask1_ST, _Patternuv1, _patternrotator1, _patternclamp1)).rgb;
	float3 pattern2 = SAMPLE_TEX2D(_PatternMask2, KKPForwardAddPatternUV(i, _PatternMask2_ST, _Patternuv2, _patternrotator2, _patternclamp2)).rgb;
	float3 pattern3 = SAMPLE_TEX2D(_PatternMask3, KKPForwardAddPatternUV(i, _PatternMask3_ST, _Patternuv3, _patternrotator3, _patternclamp3)).rgb;
	float3 color1 = lerp(_Color1_2.rgb, _Color.rgb, pattern1);
	float3 color2 = lerp(_Color2_2.rgb, _Color2.rgb, pattern2);
	float3 color3 = lerp(_Color3_2.rgb, _Color3.rgb, pattern3);
	float3 color = lerp(1.0, color1, colorMask.r);
	color = lerp(color, color2, colorMask.g);
	color = lerp(color, color3, colorMask.b);
	return mainTex.rgb * color;
#else
	float4 colorMask = SAMPLE_TEX2D(_ColorMask, i.uv0 * _ColorMask_ST.xy + _ColorMask_ST.zw);
	float3 color = lerp(1.0, _Color.rgb, colorMask.r);
	color = lerp(color, _Color2.rgb, colorMask.g);
	color = lerp(color, _Color3.rgb, colorMask.b);
	return mainTex.rgb * color;
#endif
}

float KKPItemForwardAddAlpha(Varyings i, float mainAlpha)
{
#ifdef ALPHA_SHADER
#ifdef STUDIO_SHADER
	float alpha = 1.0 - (1.0 - (mainAlpha - _Cutoff + 0.0001) / (1.0001 - _Cutoff)) * floor(_AlphaOptionCutoff / 2.0) - (1.0 - mainAlpha) * (floor(_AlphaOptionCutoff) % 2);
	return saturate(alpha) * _alpha * _alpha;
#else
	float2 maskUV = i.uv0 * _AlphaMask_ST.xy + _AlphaMask_ST.zw;
	float alphaMask = SAMPLE_TEX2D(_AlphaMask, maskUV).r;
	alphaMask = 1.0 - (1.0 - (alphaMask - _Cutoff + 0.0001) / (1.0001 - _Cutoff)) * floor(_AlphaOptionCutoff / 2.0);
	return saturate(alphaMask) * mainAlpha * _Alpha;
#endif
#else
	return 1.0;
#endif
}

Varyings vert(VertexData v)
{
#ifdef TESS_SHADER
	float4 vertex = v.vertex;
	float3 displacedNormal = v.normal;
	DisplacementValues(v, vertex, displacedNormal);
	v.vertex = vertex;
	v.normal = displacedNormal;
#endif
	Varyings o;
	o.posWS = mul(unity_ObjectToWorld, v.vertex);
	o.posCS = mul(UNITY_MATRIX_VP, o.posWS);
	o.normalWS = UnityObjectToWorldNormal(v.normal);
	o.tanWS = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
	o.bitanWS = normalize(cross(o.tanWS.xyz, o.normalWS) * (v.tangent.w * unity_WorldTransformParams.w));
	o.uv0 = v.uv0;
	#define pos posCS
	TRANSFER_VERTEX_TO_FRAGMENT(o);
	#undef pos
	return o;
}

fixed4 fragAdd(Varyings i, int faceDir : VFACE) : SV_Target
{
	clip(KKPForwardAddEnabled() - 1E-06);
	float4 mainTex = SAMPLE_TEX2D(_MainTex, i.uv0 * _MainTex_ST.xy + _MainTex_ST.zw);
#ifdef STUDIO_SHADER
	clip(mainTex.a - _Cutoff);
#else
	AlphaClip(i.uv0, mainTex.a);
#endif
	float alpha = KKPItemForwardAddAlpha(i, mainTex.a);
	clip(alpha - 1E-06);

	float3 normalWS = NormalAdjust(i, GetNormal(i), faceDir);
	float3 lightDir = normalize(UnityWorldSpaceLightDir(i.posWS.xyz));
	float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);
	float shadowAttenuation = UNITY_SHADOW_ATTENUATION(i, i.posWS.xyz);
	float attenuation = KKPForwardAddAttenuation(i.posWS.xyz, shadowAttenuation);
	float toon = KKPForwardAddToon(dot(normalWS, lightDir), attenuation, shadowAttenuation, _UseRampForLights, _UseRampForShadows);
	float3 diffuse = KKPItemForwardAddDiffuse(i, mainTex);
	float3 color = KKPForwardAddLightColor(diffuse, toon);

	float4 detailMask = SAMPLE_TEX2D(_DetailMask, i.uv0 * _DetailMask_ST.xy + _DetailMask_ST.zw);
	float specularPower = _SpecularPower * lerp(1.0, detailMask.r, saturate(_UseDetailRAsSpecularMap));
	float specular = KKPForwardAddSpecular(normalWS, lightDir, viewDir, specularPower);
	float meshSpecular = saturate(_notusetexspecular) * specular * attenuation * _SpecularColor.a;
	float3 specularColor = lerp(_SpecularColor.rgb, _SpecularColor.rgb * _LightColor0.rgb, saturate(_UseLightColorSpecular));
	color += meshSpecular * specularColor * KKPForwardAddEnabled();
	return float4(color * alpha, 0.0);
}

#endif
