#ifndef KKP_PBR_ALPHA_INC
#define KKP_PBR_ALPHA_INC

sampler2D _MainTex;
float4 _MainTex_ST;
sampler2D _AlphaMask;
float4 _AlphaMask_ST;
float _Cutoff;
float _Alpha;
float _AlphaOptionCutoff;
float _alpha_a;
float _alpha_b;

float KKP_PBR_GetMainAlpha(float2 uv)
{
	return tex2D(_MainTex, uv * _MainTex_ST.xy + _MainTex_ST.zw).a;
}

float KKP_PBR_GetAlphaMask(float2 uv)
{
	float4 alphaMask = tex2D(_AlphaMask, uv * _AlphaMask_ST.xy + _AlphaMask_ST.zw);
	float2 alphaVal = -float2(_alpha_a, _alpha_b) + float2(1.0, 1.0);
	alphaVal = max(alphaVal, alphaMask.xy);
	return min(alphaVal.y, alphaVal.x);
}

float KKP_PBR_GetCutoffAlpha(float2 uv)
{
	return min(KKP_PBR_GetAlphaMask(uv), KKP_PBR_GetMainAlpha(uv));
}

void KKP_PBR_AlphaClip(float2 uv)
{
	float alphaVal = KKP_PBR_GetCutoffAlpha(uv) - _Cutoff;
	if (alphaVal < 0.0 && _AlphaOptionCutoff)
		discard;
}

float KKP_PBR_GetOutputAlpha(float2 uv)
{
	float alphaMaskVal = KKP_PBR_GetAlphaMask(uv);
	alphaMaskVal = 1 - (1 - (alphaMaskVal - _Cutoff + 0.0001) / (1.0001 - _Cutoff)) * floor(_AlphaOptionCutoff / 2.0);
	return saturate(alphaMaskVal) * KKP_PBR_GetMainAlpha(uv) * _Alpha;
}

#endif
