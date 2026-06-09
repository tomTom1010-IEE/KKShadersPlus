#ifndef KKP_ITEM_HEIGHT_NORMALS_INCLUDED
#define KKP_ITEM_HEIGHT_NORMALS_INCLUDED

#include "KKPItemHeightCore.cginc"

float3 GetNormal(Varyings i)
{
	return KKPHeightNormalTS(i.uv0, _HeightScale * _NormalMapScale);
}

float3 GetMatCapNormal(Varyings i)
{
	float useHeightNormal = saturate(max(_UseNormalMapForMatCap, _UseDetailNormalMapForMatCap));
	return lerp(float3(0, 0, 1), KKPHeightNormalTS(i.uv0, _HeightScale * _NormalMapScale), useHeightNormal);
}

float3 CreateBinormal(float3 normal, float4 tangent, float binormalSign)
{
	return cross(normal, tangent.xyz) * (binormalSign * unity_WorldTransformParams.w);
}

float3 NormalAdjust(Varyings i, float3 finalCombinedNormal, int faceDir)
{
	float3 tangent = normalize(i.tangent);
	float3 binormal = CreateBinormal(i.normalDir, float4(tangent, 1), i.binormalSign);
	float3 worldSpaceNormal = mul(finalCombinedNormal, float3x3(tangent, binormal, i.normalDir));
	worldSpaceNormal = normalize(worldSpaceNormal);
	float3 adjustedNormal = worldSpaceNormal * faceDir;
	worldSpaceNormal = _AdjustBackfaceNormals ? adjustedNormal : worldSpaceNormal;
	return worldSpaceNormal;
}

#endif
