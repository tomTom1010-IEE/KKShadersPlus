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

float3 CreateBinormal(float3 normal, float3 tangent, float binormalSign)
{
	return cross(normal, tangent) * (binormalSign * unity_WorldTransformParams.w);
}

float3 NormalAdjust(Varyings i, float3 finalCombinedNormal, int faceDir)
{
	float3 binormal = CreateBinormal(i.normalWS, i.tanWS.xyz, i.tanWS.w);
	float3 worldSpaceNormal = normalize(
		finalCombinedNormal.x * i.tanWS.xyz +
		finalCombinedNormal.y * binormal +
		finalCombinedNormal.z * i.normalWS
	);
	return _AdjustBackfaceNormals ? worldSpaceNormal * (faceDir <= 0 ? -1 : 1) : worldSpaceNormal;
}

#endif
