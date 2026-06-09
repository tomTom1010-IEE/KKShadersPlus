#ifndef KKP_ITEM_HEIGHT_CORE_INCLUDED
#define KKP_ITEM_HEIGHT_CORE_INCLUDED

sampler2D _HeightMap;
float4 _HeightMap_ST;
float4 _HeightMap_TexelSize;

float _HeightScale;
float _HeightThreshold;
float _HeightContrast;
float _IsHeightReverse;

float KKPApplyHeightReverse(float height)
{
	return lerp(height, 1.0 - height, saturate(_IsHeightReverse));
}

float2 KKPHeightUV(float2 uv)
{
	return uv * _HeightMap_ST.xy + _HeightMap_ST.zw;
}

float KKPSampleHeightUV(float2 heightUV)
{
	return KKPApplyHeightReverse(tex2D(_HeightMap, heightUV).r);
}

float KKPSampleHeightUVLOD(float2 heightUV)
{
	return KKPApplyHeightReverse(tex2Dlod(_HeightMap, float4(heightUV, 0, 0)).r);
}

float KKPHeightMaskFromValue(float height)
{
	return saturate((height - _HeightThreshold) * max(_HeightContrast, 0.0001));
}

float GetHeightMask(float2 uv)
{
	return KKPHeightMaskFromValue(KKPSampleHeightUV(KKPHeightUV(uv)));
}

float GetHeightMaskLOD(float2 uv)
{
	return KKPHeightMaskFromValue(KKPSampleHeightUVLOD(KKPHeightUV(uv)));
}

float3 KKPHeightNormalTS(float2 uv, float scale)
{
	float2 heightUV = KKPHeightUV(uv);
	float2 texel = max(abs(_HeightMap_TexelSize.xy), 1e-06);
	float hL = KKPSampleHeightUV(heightUV - float2(texel.x, 0));
	float hR = KKPSampleHeightUV(heightUV + float2(texel.x, 0));
	float hD = KKPSampleHeightUV(heightUV - float2(0, texel.y));
	float hU = KKPSampleHeightUV(heightUV + float2(0, texel.y));
	float2 grad = float2(hR - hL, hU - hD) * scale;
	return normalize(float3(-grad.x, -grad.y, 1.0));
}

float3 KKPHeightNormalTSLOD(float2 uv, float scale)
{
	float2 heightUV = KKPHeightUV(uv);
	float2 texel = max(abs(_HeightMap_TexelSize.xy), 1e-06);
	float hL = KKPSampleHeightUVLOD(heightUV - float2(texel.x, 0));
	float hR = KKPSampleHeightUVLOD(heightUV + float2(texel.x, 0));
	float hD = KKPSampleHeightUVLOD(heightUV - float2(0, texel.y));
	float hU = KKPSampleHeightUVLOD(heightUV + float2(0, texel.y));
	float2 grad = float2(hR - hL, hU - hD) * scale;
	return normalize(float3(-grad.x, -grad.y, 1.0));
}

#endif
