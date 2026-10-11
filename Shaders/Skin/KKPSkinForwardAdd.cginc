#ifndef KKP_SKIN_FORWARD_ADD_INC
#define KKP_SKIN_FORWARD_ADD_INC

#include "../KKPForwardAdd.cginc"

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
	o.color = v.color;
	o.uv0 = v.uv0;
	o.uv1 = v.uv1;
	o.uv2 = v.uv2;
	o.uv3 = v.uv3;
	#define pos posCS
	TRANSFER_VERTEX_TO_FRAGMENT(o);
	#undef pos
	return o;
}

fixed4 fragAdd(Varyings i, int faceDir : VFACE) : SV_Target
{
	clip(KKPForwardAddEnabled() - 1E-06);
	AlphaClip(i.uv0, true);
#ifdef SKIN_BACKFACE_SEAL_PASS
	float alpha = 1.0;
#elif defined(SKIN_MASKED_ALPHA_BLEND)
	float alpha = GetSkinMaskedAlpha(i.uv0);
#else
	float alpha = GetSkinAlpha(i.uv0);
#endif
	clip(alpha - 1E-06);
	float3 diffuse = GetDiffuse(i);
#ifdef SKIN_BACKFACE_SEAL_PASS
	float3 normalWS = -NormalAdjust(i, GetNormal(i), 1);
#else
	float3 normalWS = NormalAdjust(i, GetNormal(i), faceDir);
#endif
	float3 lightDir = normalize(UnityWorldSpaceLightDir(i.posWS.xyz));
	float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);
	float shadowAttenuation = UNITY_SHADOW_ATTENUATION(i, i.posWS.xyz);
	float attenuation = KKPForwardAddAttenuation(i.posWS.xyz, shadowAttenuation);
	float toon = KKPForwardAddToon(dot(normalWS, lightDir), attenuation, shadowAttenuation, _UseRampForLights, _UseRampForShadows);
	float3 color = KKPForwardAddLightColor(diffuse, toon);

	float4 detailMask = SAMPLE_TEX2D(_DetailMask, i.uv0 * _DetailMask_ST.xy + _DetailMask_ST.zw);
	float specularPower = _SpecularPower * lerp(1.0, detailMask.r, saturate(_UseDetailRAsSpecularMap));
	float specular = KKPForwardAddSpecular(normalWS, lightDir, viewDir, specularPower);
	float3 specularColor = lerp(_SpecularColor.rgb, _SpecularColor.rgb * _LightColor0.rgb, saturate(_UseLightColorSpecular));
	color += saturate(_notusetexspecular) * specular * attenuation * specularColor * _SpecularColor.a * KKPForwardAddEnabled();
	return float4(color * alpha, 0.0);
}

#endif
