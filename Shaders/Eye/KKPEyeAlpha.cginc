#ifndef KKP_EYE_ALPHA
#define KKP_EYE_ALPHA

float _StencilCutoff;

#ifndef ROTATEUV
#define ROTATEUV
float2 rotateUV(float2 uv, float2 pivot, float rotation)
{
	float cosa = cos(rotation);
	float sina = sin(rotation);
	uv -= pivot;
	return float2(
		cosa * uv.x - sina * uv.y,
		cosa * uv.y + sina * uv.x
	) + pivot;
}
#endif

float GetEyePlusCompositeAlpha(Varyings i)
{
	float2 mainUV = rotateUV(i.uv0, float2(0.5, 0.5), -_rotation * 6.28318548);
	mainUV = mainUV * _MainTex_ST.xy + _MainTex_ST.zw;
	float irisAlpha = SAMPLE_TEX2D(_MainTex, mainUV).a;

	float3 viewDir = normalize(_WorldSpaceCameraPos - i.posWS);
	float2 expressionUV = float2(dot(i.tanWS, viewDir), dot(i.bitanWS, viewDir));
	expressionUV = expressionUV * -0.059999998 * _ExpressionDepth + i.uv0;
	expressionUV = expressionUV * _MainTex_ST.xy + _MainTex_ST.zw;
	expressionUV -= 0.5;
	expressionUV /= max(0.1, _ExpressionSize);
	expressionUV += 0.5;
	float expressionAlpha = SAMPLE_TEX2D(_expression, expressionUV + float2(0, 0.1)).a * _exppower;

	float overAlpha1 = SAMPLE_TEX2D(_overtex1, i.uv1 * _overtex1_ST + _overtex1_ST.zw).a * _overcolor1.a;
	float overAlpha2 = SAMPLE_TEX2D(_overtex2, i.uv2 * _overtex2_ST + _overtex2_ST.zw).a * _overcolor2.a;
	float overAlpha = 1 - (1 - overAlpha1) * (1 - overAlpha2);
	overAlpha = saturate(overAlpha * _isHighLight);

	return saturate(overAlpha + expressionAlpha + irisAlpha);
}

float GetEyeWAlpha(Varyings i)
{
	return SAMPLE_TEX2D(_MainTex, i.uv0 * _MainTex_ST.xy + _MainTex_ST.zw).a;
}

#endif