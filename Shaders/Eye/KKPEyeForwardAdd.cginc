#ifndef KKP_EYE_FORWARD_ADD_INC
#define KKP_EYE_FORWARD_ADD_INC

#include "../KKPForwardAdd.cginc"

float2 KKPForwardAddRotateUV(float2 uv, float2 pivot, float rotation)
{
	float sine;
	float cosine;
	sincos(rotation, sine, cosine);
	uv -= pivot;
	uv = float2(cosine * uv.x - sine * uv.y, sine * uv.x + cosine * uv.y);
	return uv + pivot;
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
	o.uv1 = v.uv1;
	o.uv2 = v.uv2;
	#define pos posCS
	TRANSFER_VERTEX_TO_FRAGMENT(o);
	#undef pos
	return o;
}

float4 KKPEyeForwardAddSurface(Varyings i)
{
#ifdef KKP_EYE_W
	float4 mainTex = SAMPLE_TEX2D(_MainTex, i.uv0 * _MainTex_ST.xy + _MainTex_ST.zw);
	clip(mainTex.a - _Cutoff);
	return float4(mainTex.rgb * _Color.rgb, mainTex.a);
#else
	float2 mainUV = KKPForwardAddRotateUV(i.uv0, float2(0.5, 0.5), -_rotation * 6.28318548);
	mainUV = mainUV * _MainTex_ST.xy + _MainTex_ST.zw;
	float4 iris = SAMPLE_TEX2D(_MainTex, mainUV);
	float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);
	float2 expressionUV = float2(dot(i.tanWS.xyz, viewDir), dot(i.bitanWS, viewDir));
	expressionUV = expressionUV * -0.059999998 * _ExpressionDepth + i.uv0;
	expressionUV = expressionUV * _MainTex_ST.xy + _MainTex_ST.zw;
	expressionUV = (expressionUV - 0.5) / max(0.1, _ExpressionSize) + 0.5;
	float4 expression = SAMPLE_TEX2D(_expression, expressionUV + float2(0, 0.1));
	expression.rgb -= iris.rgb;
	expression.a *= _exppower;
	float3 diffuse = expression.a * expression.rgb + iris.rgb;
	float4 overSample1 = SAMPLE_TEX2D(_overtex1, i.uv1 * _overtex1_ST + _overtex1_ST.zw);
	float4 overSample2 = SAMPLE_TEX2D(_overtex2, i.uv2 * _overtex2_ST + _overtex2_ST.zw);
	float4 over1 = overSample1.a * _overcolor1;
	float4 over2 = overSample2.a * _overcolor2;
	float4 over = 1.0 - (1.0 - over1) * (1.0 - over2);
	over.a = saturate(over.a * _isHighLight);
	diffuse = lerp(diffuse, over.rgb, over.a);
	float alpha = saturate(over.a + expression.a + iris.a);
#ifdef KKP_EYE_ALPHA_CUTOFF
	clip(alpha - _Cutoff);
#else
	clip(alpha - 0.01);
#endif
	return float4(diffuse, alpha);
#endif
}

fixed4 fragAdd(Varyings i) : SV_Target
{
	clip(KKPForwardAddEnabled() - 1E-06);
	float4 surface = KKPEyeForwardAddSurface(i);
	float3 normalWS = normalize(i.normalWS);
	float3 lightDir = normalize(UnityWorldSpaceLightDir(i.posWS.xyz));
	float shadowAttenuation = UNITY_SHADOW_ATTENUATION(i, i.posWS.xyz);
	float attenuation = KKPForwardAddAttenuation(i.posWS.xyz, shadowAttenuation);
	float toon = KKPForwardAddToon(dot(normalWS, lightDir), attenuation, shadowAttenuation, _UseRampForLights, 0.0);
	float3 color = KKPForwardAddLightColor(surface.rgb, toon);
	return float4(color * surface.a, 0.0);
}

#endif
