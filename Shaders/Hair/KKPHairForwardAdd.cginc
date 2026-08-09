#ifndef KKP_HAIR_FORWARD_ADD_INC
#define KKP_HAIR_FORWARD_ADD_INC

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
	o.uv0 = v.uv0;
	o.uv1 = v.uv1;
	#define pos posCS
	TRANSFER_VERTEX_TO_FRAGMENT(o);
	#undef pos
	return o;
}

fixed4 fragAdd(Varyings i, int faceDir : VFACE) : SV_Target
{
	clip(KKPForwardAddEnabled() - 0.5);
	float4 mainTex = SAMPLE_TEX2D(_MainTex, i.uv0 * _MainTex_ST.xy + _MainTex_ST.zw);
	float alpha = AlphaClip(i.uv0, mainTex.a);
#ifdef HAIR_FRONT_INSIDE
	alpha *= 1.0 - _transparency;
#endif
	float3 diffuse = GetDiffuse(i.uv0) * mainTex.rgb;
	float3 normalWS = NormalAdjust(i, GetNormal(i), faceDir);
	float3 lightDir = normalize(UnityWorldSpaceLightDir(i.posWS.xyz));
	float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);
	UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWS.xyz);
	float toon = KKPForwardAddToon(dot(normalWS, lightDir), attenuation, _UseRampForLights, _UseRampForShadows);
	float3 color = KKPForwardAddLightColor(diffuse, toon);

	float4 detailMask = SAMPLE_TEX2D(_DetailMask, i.uv0 * _DetailMask_ST.xy + _DetailMask_ST.zw);
	float specularPower = _SpecularHairPower * lerp(1.0, detailMask.r, saturate(_UseDetailRAsSpecularMap));
	float specular = KKPForwardAddSpecular(normalWS, lightDir, viewDir, specularPower);
	float3 specularColor = lerp(_SpecularColor.rgb, _LightColor0.rgb, saturate(_UseLightColorSpecular));
	color += specular * attenuation * specularColor * _SpecularColor.a * _UseMeshSpecular * KKPForwardAddEnabled();
	return float4(color * alpha, 0.0);
}

#endif
